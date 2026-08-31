use crate::api::messages::outgoing::send_c2c_message_to_contact;
use crate::api::proto::client::{encrypted_content, EncryptedContent};
use crate::api::proto::http_requests::{
    AttachmentDispatch, AttachmentManifest, AttachmentState, AttachmentStatus, RequestUploadSlots,
    UploadSlots,
};
use crate::bridge::api::RustApi;
use crate::context::Context;
use crate::database::app::tables::MediaFile;
use crate::error::{Result, TwonlyError};
use crate::native::transfer;
use chacha20poly1305::aead::{AeadInPlace, KeyInit};
use chacha20poly1305::{ChaCha20Poly1305, Nonce};
use prost::Message;
use rand::RngCore;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use std::collections::HashMap;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;

const REFRESH_BEFORE_SECONDS: i64 = 24 * 60 * 60;
/// How long a running app keeps asking the server about transfers the OS is
/// carrying for it. Anything still unfinished after this is picked up by the
/// reconciliation pass on the next launch.
const WATCH_BUDGET: Duration = Duration::from_secs(10 * 60);
const WATCH_FIRST_DELAY: Duration = Duration::from_secs(2);
const WATCH_MAX_DELAY: Duration = Duration::from_secs(120);

static WATCHING: AtomicBool = AtomicBool::new(false);

/// The OS finishes a transfer without telling this process, so a send would keep
/// showing as "sending" until the app is restarted. While the app is alive, poll
/// the server for the attachments it is still waiting on, backing off as the
/// wait grows, and stop as soon as everything has settled.
pub fn watch_pending_uploads(ctx: &Arc<Context>) {
    if WATCHING.swap(true, Ordering::SeqCst) {
        return;
    }
    let ctx = ctx.clone();
    tokio::spawn(async move {
        let service = DirectMediaUploadService::new(&ctx);
        let deadline = tokio::time::Instant::now() + WATCH_BUDGET;
        let mut delay = WATCH_FIRST_DELAY;
        while tokio::time::Instant::now() < deadline {
            tokio::time::sleep(delay).await;
            if let Err(error) = service.reconcile().await {
                tracing::warn!(%error, "could not reconcile direct-media uploads");
            }
            match service.pending_job_count().await {
                Ok(0) => break,
                Ok(_) => {}
                Err(error) => {
                    tracing::warn!(%error, "could not count pending direct-media uploads");
                    break;
                }
            }
            delay = (delay * 2).min(WATCH_MAX_DELAY);
        }
        WATCHING.store(false, Ordering::SeqCst);
    });
}

#[derive(FromRow)]
struct CachedSlot {
    attachment_id: String,
    expires_at: i64,
    maximum_object_bytes: i64,
    upload_url: String,
    upload_fields_json: String,
    capability: Vec<u8>,
}

#[derive(FromRow)]
struct MediaRow {
    media_type: String,
    requires_authentication: i64,
    display_limit_in_milliseconds: Option<i64>,
    encryption_key: Option<Vec<u8>>,
    encryption_nonce: Option<Vec<u8>>,
}

#[derive(FromRow)]
struct MessageRow {
    group_id: String,
    message_id: String,
    created_at: i64,
    quotes_message_id: Option<String>,
    additional_message_data: Option<Vec<u8>>,
}

#[derive(FromRow)]
struct PendingJob {
    attachment_id: String,
    media_id: String,
    multipart_path: String,
    manifest_path: String,
    complete_body_path: String,
    capability: Vec<u8>,
    expires_at: i64,
}

#[derive(FromRow)]
struct RecipientRow {
    contact_id: i64,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct NativeRequest {
    role: String,
    url: String,
    method: String,
    headers: HashMap<String, String>,
    body_path: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct NativeUploadDescriptor {
    attachment_id: String,
    expires_at: i64,
    media: NativeRequest,
    manifest: NativeRequest,
    complete: NativeRequest,
}

#[derive(Clone, Copy)]
enum Outcome {
    Uploaded,
    Rejected,
    Retry,
}

pub struct DirectMediaUploadService {
    ctx: Arc<Context>,
}

impl DirectMediaUploadService {
    pub fn new(ctx: &Arc<Context>) -> Self {
        Self { ctx: ctx.clone() }
    }

    fn api_url(path: &str) -> String {
        format!("{}{}", RustApi::api_base_url("https".into()), path)
    }

    async fn authenticated_request(
        &self,
        request: reqwest::RequestBuilder,
    ) -> Result<reqwest::RequestBuilder> {
        let user_id = self.ctx.user_id().await?;
        let login_token = self.ctx.key_manager.lock().await.main_key.get_login_token();
        Ok(request
            .header("x-twonly-user-id", hex::encode(user_id.to_be_bytes()))
            .header("x-twonly-login-token", hex::encode(login_token)))
    }

    pub async fn preload_slots(&self) -> Result<usize> {
        let database = self.ctx.app_db.read().await.clone();
        let known = sqlx::query_scalar::<_, String>(
            "SELECT attachment_id FROM direct_media_upload_slots WHERE state IN ('cached', 'reserved') AND expires_at > CAST(strftime('%s','now') AS INTEGER)",
        )
        .fetch_all(&database.pool)
        .await?;
        let request = RequestUploadSlots {
            locally_known_slot_ids: known,
        };
        let request_body = request.encode_to_vec();
        let client = reqwest::Client::new();
        let response = self
            .authenticated_request(
                client
                    .post(Self::api_url("v2/media/upload-slots"))
                    .header("content-type", "application/x-protobuf")
                    // Warp's bounded-body filter requires an explicit length even
                    // when the protobuf is the valid zero-byte default message.
                    .header("content-length", request_body.len())
                    .body(request_body),
            )
            .await?
            .send()
            .await
            .map_err(|error| TwonlyError::Generic(error.to_string()))?;
        if !response.status().is_success() {
            return Err(TwonlyError::Generic(format!(
                "upload slot preload returned HTTP {}",
                response.status()
            )));
        }
        let slots = UploadSlots::decode(
            response
                .bytes()
                .await
                .map_err(|error| TwonlyError::Generic(error.to_string()))?,
        )?;
        let count = slots.slots.len();
        let mut transaction = database.pool.begin().await?;
        for slot in slots.slots {
            let upload = slot.media_upload.ok_or_else(|| {
                TwonlyError::Generic("server returned an upload slot without a POST".into())
            })?;
            sqlx::query(
                r#"INSERT INTO direct_media_upload_slots
                   (attachment_id, expires_at, maximum_object_bytes, upload_url,
                    upload_fields_json, capability, state)
                   VALUES (?, ?, ?, ?, ?, ?, 'cached')
                   ON CONFLICT(attachment_id) DO NOTHING"#,
            )
            .bind(slot.attachment_id)
            .bind(slot.expires_at_unix_seconds)
            .bind(slot.maximum_object_bytes)
            .bind(upload.url)
            .bind(serde_json::to_string(&upload.fields)?)
            .bind(slot.background_capability)
            .execute(&mut *transaction)
            .await?;
        }
        transaction.commit().await?;
        Ok(count)
    }

    async fn usable_slot_count(&self) -> Result<i64> {
        let database = self.ctx.app_db.read().await.clone();
        Ok(sqlx::query_scalar(
            r#"SELECT COUNT(*) FROM direct_media_upload_slots
               WHERE state = 'cached' AND expires_at > CAST(strftime('%s','now') AS INTEGER) + ?"#,
        )
        .bind(REFRESH_BEFORE_SECONDS)
        .fetch_one(&database.pool)
        .await?)
    }

    async fn ensure_slots(&self) -> Result<()> {
        let usable = self.usable_slot_count().await?;
        if usable > 5 {
            return Ok(());
        }
        match self.preload_slots().await {
            Ok(_) => Ok(()),
            Err(error) if usable > 0 => {
                tracing::warn!(%error, usable, "slot refill failed; using cached direct-media slot");
                Ok(())
            }
            Err(error) => Err(error),
        }
    }

    async fn reserve_slot(&self) -> Result<CachedSlot> {
        self.ensure_slots().await?;
        let database = self.ctx.app_db.read().await.clone();
        let mut transaction = database.pool.begin().await?;
        let slot = sqlx::query_as::<_, CachedSlot>(
            r#"UPDATE direct_media_upload_slots SET state = 'reserved'
               WHERE attachment_id = (
                 SELECT attachment_id FROM direct_media_upload_slots
                 WHERE state = 'cached'
                   AND expires_at > CAST(strftime('%s','now') AS INTEGER) + ?
                 ORDER BY expires_at ASC LIMIT 1
               )
               RETURNING attachment_id, expires_at, maximum_object_bytes, upload_url,
                         upload_fields_json, capability"#,
        )
        .bind(REFRESH_BEFORE_SECONDS)
        .fetch_optional(&mut *transaction)
        .await?
        .ok_or_else(|| TwonlyError::Generic("no usable direct-media upload slot".into()))?;
        transaction.commit().await?;
        Ok(slot)
    }

    pub async fn pending_job_count(&self) -> Result<i64> {
        let database = self.ctx.app_db.read().await.clone();
        Ok(sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM direct_media_upload_jobs WHERE state IN ('scheduled', 'waiting_for_server')",
        )
        .fetch_one(&database.pool)
        .await?)
    }

    /// Native background transfers cannot report back into a process that may
    /// not be running, so the server's attachment state is the authority. Every
    /// launch settles the jobs the device believes are still in flight.
    pub async fn reconcile(&self) -> Result<()> {
        let database = self.ctx.app_db.read().await.clone();
        let jobs = sqlx::query_as::<_, PendingJob>(
            r#"SELECT j.attachment_id, j.media_id, j.multipart_path, j.manifest_path,
                      j.complete_body_path, s.capability, j.expires_at
               FROM direct_media_upload_jobs j
               JOIN direct_media_upload_slots s ON s.attachment_id = j.attachment_id
               WHERE j.state IN ('scheduled', 'waiting_for_server')"#,
        )
        .fetch_all(&database.pool)
        .await?;
        drop(database);

        let now = chrono::Utc::now().timestamp();
        for job in jobs {
            let state = match self.fetch_status(&job).await {
                Ok(status) => {
                    AttachmentState::try_from(status.state).unwrap_or(AttachmentState::Unknown)
                }
                Err(error) => {
                    tracing::warn!(
                        attachment_id = job.attachment_id,
                        %error,
                        "could not read direct-media attachment status"
                    );
                    continue;
                }
            };
            match state {
                AttachmentState::Ready => self.settle(&job, Outcome::Uploaded).await?,
                AttachmentState::Rejected => self.settle(&job, Outcome::Rejected).await?,
                AttachmentState::Expired | AttachmentState::Abandoned => {
                    self.settle(&job, Outcome::Retry).await?;
                }
                // Still reserved or uploading. Only give up once the slot's own
                // capability has expired, because the native task stops then too.
                _ if job.expires_at <= now => self.settle(&job, Outcome::Retry).await?,
                _ => {}
            }
        }
        Ok(())
    }

    async fn fetch_status(&self, job: &PendingJob) -> Result<AttachmentStatus> {
        let response = reqwest::Client::new()
            .get(Self::api_url(&format!(
                "v2/attachments/{}/status",
                job.attachment_id
            )))
            .header("x-twonly-upload-capability", hex::encode(&job.capability))
            .timeout(std::time::Duration::from_secs(30))
            .send()
            .await
            .map_err(|error| TwonlyError::Generic(error.to_string()))?;
        if !response.status().is_success() {
            return Err(TwonlyError::Generic(format!(
                "attachment status returned HTTP {}",
                response.status()
            )));
        }
        Ok(AttachmentStatus::decode(response.bytes().await.map_err(
            |error| TwonlyError::Generic(error.to_string()),
        )?)?)
    }

    /// Releases the request files and the slot, then applies the outcome to the
    /// media file. Safe to run twice: the job row is the claim.
    async fn settle(&self, job: &PendingJob, outcome: Outcome) -> Result<()> {
        let database = self.ctx.app_db.read().await.clone();
        let claimed = sqlx::query(
            "DELETE FROM direct_media_upload_jobs WHERE attachment_id = ? AND state IN ('scheduled', 'waiting_for_server')",
        )
        .bind(&job.attachment_id)
        .execute(&database.pool)
        .await?
        .rows_affected();
        if claimed == 0 {
            return Ok(());
        }

        for path in [
            &job.multipart_path,
            &job.manifest_path,
            &job.complete_body_path,
        ] {
            match std::fs::remove_file(path) {
                Ok(()) => {}
                Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
                Err(error) => tracing::warn!(path, %error, "could not remove upload request file"),
            }
        }
        let job_dir = PathBuf::from(&self.ctx.config.data_dir)
            .join("direct-media-upload")
            .join(&job.attachment_id);
        let _ = std::fs::remove_dir(&job_dir);

        let slot_state = if matches!(outcome, Outcome::Uploaded) {
            "consumed"
        } else {
            "abandoned"
        };
        sqlx::query("UPDATE direct_media_upload_slots SET state = ? WHERE attachment_id = ?")
            .bind(slot_state)
            .bind(&job.attachment_id)
            .execute(&database.pool)
            .await?;

        match outcome {
            Outcome::Uploaded => {
                let mut transaction = database.pool.begin().await?;
                MediaFile::mark_uploaded(&mut transaction, &job.media_id).await?;
                transaction.commit().await?;
                self.remove_encrypted_copy(&job.media_id).await;
            }
            // A rejection is a policy decision (quota, size, plan). Retrying it
            // with the same bytes would fail the same way.
            Outcome::Rejected => {
                sqlx::query(
                    "UPDATE media_files SET upload_state = 'uploadLimitReached' WHERE media_id = ?",
                )
                .bind(&job.media_id)
                .execute(&database.pool)
                .await?;
            }
            Outcome::Retry => {
                sqlx::query(
                    r#"UPDATE media_files SET upload_state = 'preprocessing'
                       WHERE media_id = ? AND upload_state != 'uploaded'"#,
                )
                .bind(&job.media_id)
                .execute(&database.pool)
                .await?;
            }
        }
        Ok(())
    }

    async fn remove_encrypted_copy(&self, media_id: &str) {
        let database = self.ctx.app_db.read().await.clone();
        let media_type =
            sqlx::query_scalar::<_, String>("SELECT type FROM media_files WHERE media_id = ?")
                .bind(media_id)
                .fetch_optional(&database.pool)
                .await;
        if let Ok(Some(media_type)) = media_type {
            let path = PathBuf::from(&self.ctx.config.data_dir)
                .join("mediafiles/tmp")
                .join(format!(
                    "{media_id}.encrypted.{}",
                    media_extension(&media_type)
                ));
            let _ = std::fs::remove_file(path);
        }
    }

    pub async fn prepare_and_schedule(&self, media_id: &str) -> Result<String> {
        let slot = self.reserve_slot().await?;
        match self.prepare_reserved(media_id, &slot).await {
            Ok(()) => Ok(slot.attachment_id),
            Err(error) => {
                self.release_reservation(&slot.attachment_id).await;
                Err(error)
            }
        }
    }

    /// Preparation failed somewhere between writing the job row and handing it
    /// to the native uploader. Nothing was scheduled, so the half-built job and
    /// its files are removed and the slot goes back into the cache unused.
    async fn release_reservation(&self, attachment_id: &str) {
        let database = self.ctx.app_db.read().await.clone();
        let paths = sqlx::query_as::<_, (String, String, String)>(
            r#"DELETE FROM direct_media_upload_jobs WHERE attachment_id = ? AND state = 'prepared'
               RETURNING multipart_path, manifest_path, complete_body_path"#,
        )
        .bind(attachment_id)
        .fetch_optional(&database.pool)
        .await;
        if let Ok(Some((multipart, manifest, complete))) = paths {
            for path in [multipart, manifest, complete] {
                let _ = std::fs::remove_file(path);
            }
        }
        let _ = std::fs::remove_dir(
            PathBuf::from(&self.ctx.config.data_dir)
                .join("direct-media-upload")
                .join(attachment_id),
        );
        let _ = sqlx::query(
            "UPDATE direct_media_upload_slots SET state = 'cached' WHERE attachment_id = ? AND state = 'reserved'",
        )
        .bind(attachment_id)
        .execute(&database.pool)
        .await;
    }

    async fn prepare_reserved(&self, media_id: &str, slot: &CachedSlot) -> Result<()> {
        let (encrypted_path, encrypted_size, manifest) = self.prepare_media(media_id).await?;
        // The server rejects an oversized object anyway, but only once the whole
        // upload has been spent: the manifest is refused outright, and an object
        // that slips past it is deleted at finalize with `single_object_limit`.
        // Catching it here costs the user nothing and is the only point at which
        // a reason can still be shown next to the message.
        if encrypted_size > slot.maximum_object_bytes {
            return Err(TwonlyError::MediaTooLarge {
                bytes: encrypted_size,
                limit: slot.maximum_object_bytes,
            });
        }
        let fields: HashMap<String, String> = serde_json::from_str(&slot.upload_fields_json)?;
        let job_dir = PathBuf::from(&self.ctx.config.data_dir)
            .join("direct-media-upload")
            .join(&slot.attachment_id);
        std::fs::create_dir_all(&job_dir)?;
        let multipart_path = job_dir.join("media.multipart");
        let manifest_path = job_dir.join("manifest.pb");
        let complete_body_path = job_dir.join("complete.pb");
        let boundary = format!("twonly-{}", uuid::Uuid::new_v4().simple());
        write_multipart_body(&multipart_path, &boundary, &fields, &encrypted_path)?;
        std::fs::write(&manifest_path, manifest.encode_to_vec())?;
        std::fs::write(&complete_body_path, [])?;

        let capability = hex::encode(&slot.capability);
        let mut capability_headers = HashMap::new();
        capability_headers.insert("x-twonly-upload-capability".into(), capability);
        capability_headers.insert("content-type".into(), "application/x-protobuf".into());
        let descriptor = NativeUploadDescriptor {
            attachment_id: slot.attachment_id.clone(),
            expires_at: slot.expires_at,
            media: NativeRequest {
                role: "media".into(),
                url: slot.upload_url.clone(),
                method: "POST".into(),
                headers: HashMap::from([(
                    "content-type".into(),
                    format!("multipart/form-data; boundary={boundary}"),
                )]),
                body_path: multipart_path.to_string_lossy().into_owned(),
            },
            manifest: NativeRequest {
                role: "manifest".into(),
                url: Self::api_url(&format!("v2/attachments/{}/manifest", slot.attachment_id)),
                method: "POST".into(),
                headers: capability_headers.clone(),
                body_path: manifest_path.to_string_lossy().into_owned(),
            },
            complete: NativeRequest {
                role: "complete".into(),
                url: Self::api_url(&format!("v2/attachments/{}/complete", slot.attachment_id)),
                method: "POST".into(),
                headers: capability_headers,
                body_path: complete_body_path.to_string_lossy().into_owned(),
            },
        };
        let descriptor_json = serde_json::to_string(&descriptor)?;
        let database = self.ctx.app_db.read().await.clone();
        sqlx::query(
            r#"INSERT INTO direct_media_upload_jobs
               (attachment_id, media_id, multipart_path, manifest_path,
                complete_body_path, native_descriptor_json, state, expires_at)
               VALUES (?, ?, ?, ?, ?, ?, 'prepared', ?)"#,
        )
        .bind(&slot.attachment_id)
        .bind(media_id)
        .bind(multipart_path.to_string_lossy().as_ref())
        .bind(manifest_path.to_string_lossy().as_ref())
        .bind(complete_body_path.to_string_lossy().as_ref())
        .bind(&descriptor_json)
        .bind(slot.expires_at)
        .execute(&database.pool)
        .await?;

        transfer::schedule(&descriptor_json)?;
        sqlx::query(
            "UPDATE direct_media_upload_jobs SET state = 'scheduled', updated_at = CAST(strftime('%s','now') AS INTEGER) WHERE attachment_id = ?",
        )
        .bind(&slot.attachment_id)
        .execute(&database.pool)
        .await?;
        watch_pending_uploads(&self.ctx);
        Ok(())
    }

    async fn prepare_media(&self, media_id: &str) -> Result<(PathBuf, i64, AttachmentManifest)> {
        let database = self.ctx.app_db.read().await.clone();
        let media = sqlx::query_as::<_, MediaRow>(
            r#"SELECT type AS media_type, requires_authentication,
                      display_limit_in_milliseconds, encryption_key, encryption_nonce
               FROM media_files WHERE media_id = ?"#,
        )
        .bind(media_id)
        .fetch_optional(&database.pool)
        .await?
        .ok_or_else(|| TwonlyError::Generic(format!("media {media_id} does not exist")))?;
        let extension = media_extension(&media.media_type);
        let temp_path = PathBuf::from(&self.ctx.config.data_dir)
            .join("mediafiles/tmp")
            .join(format!("{media_id}.{extension}"));
        let encrypted_path = PathBuf::from(&self.ctx.config.data_dir)
            .join("mediafiles/tmp")
            .join(format!("{media_id}.encrypted.{extension}"));
        let key = media
            .encryption_key
            .as_deref()
            .ok_or_else(|| TwonlyError::Generic("media encryption key is missing".into()))?;
        let nonce = media
            .encryption_nonce
            .as_deref()
            .ok_or_else(|| TwonlyError::Generic("media encryption nonce is missing".into()))?;
        if nonce.len() != 12 {
            return Err(TwonlyError::Generic(
                "invalid media encryption nonce".into(),
            ));
        }
        let mut encrypted = std::fs::read(&temp_path)?;
        let cipher = ChaCha20Poly1305::new_from_slice(key)
            .map_err(|_| TwonlyError::Generic("invalid media encryption key".into()))?;
        let tag = cipher
            .encrypt_in_place_detached(Nonce::from_slice(nonce), b"", &mut encrypted)
            .map_err(|_| TwonlyError::Generic("media encryption failed".into()))?;
        if let Some(parent) = encrypted_path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        std::fs::write(&encrypted_path, &encrypted)?;
        sqlx::query("UPDATE media_files SET encryption_mac = ? WHERE media_id = ?")
            .bind(tag.as_slice())
            .bind(media_id)
            .execute(&database.pool)
            .await?;

        let messages = sqlx::query_as::<_, MessageRow>(
            r#"SELECT group_id, message_id, created_at, quotes_message_id,
                      additional_message_data
               FROM messages WHERE media_id = ?"#,
        )
        .bind(media_id)
        .fetch_all(&database.pool)
        .await?;
        if messages.is_empty() {
            return Err(TwonlyError::Generic(
                "media has no recipient messages".into(),
            ));
        }
        let media_type = match media.media_type.as_str() {
            "video" => encrypted_content::media::Type::Video,
            "gif" => encrypted_content::media::Type::Gif,
            "audio" => encrypted_content::media::Type::Audio,
            _ => encrypted_content::media::Type::Image,
        };
        let mut dispatches = Vec::new();
        for message in messages {
            let recipients = sqlx::query_as::<_, RecipientRow>(
                r#"SELECT gm.contact_id
                   FROM group_members gm
                   JOIN contacts c ON c.user_id = gm.contact_id
                   WHERE gm.group_id = ?
                     AND (gm.member_state IS NULL OR gm.member_state != 'leftGroup')
                     AND c.account_deleted = 0"#,
            )
            .bind(&message.group_id)
            .fetch_all(&database.pool)
            .await?;
            for recipient in recipients {
                let mut download_token = vec![0_u8; 32];
                rand::rng().fill_bytes(&mut download_token);
                let content = EncryptedContent {
                    group_id: Some(message.group_id.clone()),
                    media: Some(encrypted_content::Media {
                        sender_message_id: message.message_id.clone(),
                        r#type: media_type as i32,
                        display_limit_in_milliseconds: media.display_limit_in_milliseconds,
                        requires_authentication: media.requires_authentication != 0,
                        timestamp: message.created_at.saturating_mul(1_000),
                        quote_message_id: message.quotes_message_id.clone(),
                        download_token: Some(download_token.clone()),
                        encryption_key: Some(key.to_vec()),
                        encryption_mac: Some(tag.to_vec()),
                        encryption_nonce: Some(nonce.to_vec()),
                        additional_message_data: message.additional_message_data.clone(),
                    }),
                    ..Default::default()
                };
                let encrypted_body = send_c2c_message_to_contact()
                    .ctx(&self.ctx)
                    .contact_id(recipient.contact_id)
                    .encrypted_content(content.encode_to_vec())
                    .message_id(message.message_id.clone())
                    .only_return_encrypted_data(true)
                    .blocking(true)
                    .call()
                    .await?
                    .ok_or_else(|| {
                        TwonlyError::Generic("Signal engine returned no encrypted envelope".into())
                    })?;
                dispatches.push(AttachmentDispatch {
                    recipient_user_id: recipient.contact_id,
                    encrypted_body,
                    push_data: Some(vec![1]),
                    download_token,
                });
            }
        }
        if dispatches.is_empty() || dispatches.len() > 300 {
            return Err(TwonlyError::Generic(format!(
                "direct-media fan-out has {} dispatches",
                dispatches.len()
            )));
        }
        Ok((
            encrypted_path,
            encrypted.len() as i64,
            AttachmentManifest {
                encrypted_object_size: encrypted.len() as i64,
                dispatches,
            },
        ))
    }
}

fn media_extension(media_type: &str) -> &'static str {
    match media_type {
        "video" => "mp4",
        "gif" => "gif",
        "audio" => "m4a",
        _ => "webp",
    }
}

fn quoted(value: &str) -> String {
    value.replace('\\', "\\\\").replace('"', "\\\"")
}

fn write_multipart_body(
    output_path: &Path,
    boundary: &str,
    fields: &HashMap<String, String>,
    media_path: &Path,
) -> Result<()> {
    let mut entries: Vec<_> = fields.iter().collect();
    entries.sort_unstable_by(|left, right| left.0.cmp(right.0));
    let mut output = std::fs::File::create(output_path)?;
    for (name, value) in entries {
        write!(
            output,
            "--{boundary}\r\nContent-Disposition: form-data; name=\"{}\"\r\n\r\n{}\r\n",
            quoted(name),
            value
        )?;
    }
    write!(
        output,
        "--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"encrypted-media\"\r\nContent-Type: application/octet-stream\r\n\r\n"
    )?;
    let mut media = std::fs::File::open(media_path)?;
    std::io::copy(&mut media, &mut output)?;
    write!(output, "\r\n--{boundary}--\r\n")?;
    output.sync_all()?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn multipart_body_is_deterministic_and_keeps_exact_media_bytes() {
        let directory = tempfile::tempdir().unwrap();
        let media = directory.path().join("media");
        let body = directory.path().join("body");
        let media_bytes = [0_u8, 1, b'\r', b'\n', 255];
        std::fs::write(&media, media_bytes).unwrap();
        let fields = HashMap::from([
            ("z-field".to_owned(), "last".to_owned()),
            ("key".to_owned(), "object/path".to_owned()),
        ]);
        write_multipart_body(&body, "boundary", &fields, &media).unwrap();
        let bytes = std::fs::read(body).unwrap();
        let key = b"name=\"key\"\r\n\r\nobject/path";
        let z = b"name=\"z-field\"\r\n\r\nlast";
        assert!(bytes.windows(key.len()).any(|window| window == key));
        let key_position = bytes
            .windows(key.len())
            .position(|window| window == key)
            .unwrap();
        let z_position = bytes
            .windows(z.len())
            .position(|window| window == z)
            .unwrap();
        assert!(key_position < z_position);
        let marker = b"Content-Type: application/octet-stream\r\n\r\n";
        let media_start = bytes
            .windows(marker.len())
            .position(|window| window == marker)
            .unwrap()
            + marker.len();
        assert_eq!(
            &bytes[media_start..media_start + media_bytes.len()],
            &media_bytes
        );
        assert!(bytes.ends_with(b"\r\n--boundary--\r\n"));
    }
}
