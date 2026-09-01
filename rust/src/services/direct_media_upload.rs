use crate::api::messages::outgoing::send_c2c_message_to_contact;
use crate::api::proto::client::{encrypted_content, EncryptedContent};
use crate::api::proto::http_requests::{
    AttachmentDispatch, AttachmentManifest, AttachmentState, AttachmentStatus, RequestUploadSlots,
    UploadSlots,
};
use crate::bridge::api::RustApi;
use crate::context::Context;
use crate::database::app::{tables::MediaFile, AppDatabase};
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
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::Arc;
use std::time::Duration;

const REFRESH_BEFORE_SECONDS: i64 = 24 * 60 * 60;
/// When to top the slot cache up, until the server has said otherwise.
///
/// A slot is the one part of preparing a send that needs the network, so the
/// cache decides whether a message composed offline can still be handed to the
/// OS — which then waits for connectivity by itself — or has to sit in the
/// database until the app is opened again. The server caps how many a client
/// may hold and advertises where it refills; this is only the value used before
/// the first answer has arrived.
const DEFAULT_SLOT_REFILL_THRESHOLD: i64 = 5;
/// Where the server's advertised refill threshold is remembered between runs.
const REFILL_THRESHOLD_KEY: &str = "direct_media_refill_threshold";
/// Upload slots and attachment capabilities belong to exactly one API
/// deployment. Debug and profile builds share the `.testing` application data,
/// so this marker prevents a build switch from reusing the other server's
/// durable jobs.
const API_NAMESPACE_KEY: &str = "direct_media_api_namespace";
const WATCH_FIRST_DELAY: Duration = Duration::from_secs(2);
const WATCH_MAX_DELAY: Duration = Duration::from_secs(120);

static WATCHING: AtomicBool = AtomicBool::new(false);
static API_NAMESPACE_LOCK: tokio::sync::Mutex<()> = tokio::sync::Mutex::const_new(());

/// Bumped every time something asks to be watched. A watcher already in flight
/// reads this as "new work arrived" and drops back to the short poll interval.
/// Without it a send made while an earlier watch had already backed off would
/// wait out that watch's two-minute cadence before its first look, long after
/// the recipient has the file.
static WATCH_REQUESTS: AtomicU64 = AtomicU64::new(0);

/// Clears the process-wide watcher claim even when the runtime carrying the
/// task is shut down. Background platform entry points own short-lived Tokio
/// runtimes, so ordinary code after an `.await` is not guaranteed to run.
struct WatchingGuard;

impl Drop for WatchingGuard {
    fn drop(&mut self) {
        WATCHING.store(false, Ordering::SeqCst);
    }
}

/// The OS finishes a transfer without telling this process, so a send would keep
/// showing as "sending" until the app is restarted. While the app is alive, poll
/// the server for the attachments it is still waiting on, backing off as the
/// wait grows, and stop as soon as everything has settled.
pub fn watch_pending_uploads(ctx: &Arc<Context>) {
    let Some(runtime) = ctx.foreground_runtime() else {
        // A killed-app worker has no long-lived runtime. Its native scheduler
        // uses the `pending_uploads` result from background::run instead.
        return;
    };
    let requested = WATCH_REQUESTS.fetch_add(1, Ordering::SeqCst) + 1;
    if WATCHING.swap(true, Ordering::SeqCst) {
        // A watcher is already running and will pick the request up on its next
        // pass, so this does not start a second poller against the same jobs.
        return;
    }
    let ctx = ctx.clone();
    runtime.spawn(async move {
        let guard = WatchingGuard;
        let service = DirectMediaUploadService::new(&ctx);
        let mut seen = requested;
        let mut delay = WATCH_FIRST_DELAY;
        loop {
            tokio::time::sleep(delay).await;
            if let Err(error) = service.reconcile().await {
                tracing::warn!(%error, "could not reconcile direct-media uploads");
            }
            // The jobs themselves bound this loop: `reconcile` settles one whose
            // slot has expired, so a server that never answers still ends the
            // watch rather than leaving it running for the life of the app.
            match service.pending_job_count().await {
                Ok(0) => break,
                Ok(_) => {}
                Err(error) => {
                    tracing::warn!(%error, "could not count pending direct-media uploads");
                    break;
                }
            }
            let requests = WATCH_REQUESTS.load(Ordering::SeqCst);
            if requests == seen {
                delay = (delay * 2).min(WATCH_MAX_DELAY);
            } else {
                // Something was handed to the OS since the last pass, so look
                // again soon instead of on the interval an older wait grew to.
                seen = requests;
                delay = WATCH_FIRST_DELAY;
            }
        }
        // Release the claim before checking for a request that raced the last
        // pass. `WatchingGuard` also performs this release if this future is
        // cancelled because its runtime is being destroyed.
        drop(guard);
        // A request that arrived between the loop stopping and the flag being
        // cleared found `WATCHING` still set and returned without starting a
        // watcher. Nothing else would poll for it, so pick it up here.
        if WATCH_REQUESTS.load(Ordering::SeqCst) != seen {
            watch_pending_uploads(&ctx);
        }
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

async fn reset_upload_namespace(
    database: &AppDatabase,
    data_dir: &Path,
    namespace: &str,
) -> Result<(Option<String>, usize)> {
    let stored = sqlx::query_scalar::<_, String>("SELECT value FROM app_metadata WHERE key = ?")
        .bind(API_NAMESPACE_KEY)
        .fetch_optional(&database.pool)
        .await?;
    if stored.as_deref() == Some(namespace) {
        return Ok((stored, 0));
    }

    let stale_files = sqlx::query_as::<_, (String, String, String, String)>(
        r#"SELECT attachment_id, multipart_path, manifest_path, complete_body_path
           FROM direct_media_upload_jobs"#,
    )
    .fetch_all(&database.pool)
    .await?;

    let mut transaction = database.pool.begin().await?;
    sqlx::query(
        r#"UPDATE media_files
           SET upload_state = 'preprocessing', pre_progressing_process = NULL
           WHERE upload_state != 'uploaded'
             AND media_id IN (SELECT media_id FROM direct_media_upload_jobs)"#,
    )
    .execute(&mut *transaction)
    .await?;
    sqlx::query("DELETE FROM direct_media_upload_jobs WHERE 1")
        .execute(&mut *transaction)
        .await?;
    sqlx::query("DELETE FROM direct_media_upload_slots WHERE 1")
        .execute(&mut *transaction)
        .await?;
    sqlx::query(
        r#"INSERT INTO app_metadata(key, value) VALUES(?, ?)
           ON CONFLICT(key) DO UPDATE SET value = excluded.value"#,
    )
    .bind(API_NAMESPACE_KEY)
    .bind(namespace)
    .execute(&mut *transaction)
    .await?;
    transaction.commit().await?;

    for (attachment_id, multipart, manifest, complete) in &stale_files {
        for path in [multipart, manifest, complete] {
            match std::fs::remove_file(path) {
                Ok(()) => {}
                Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
                Err(error) => {
                    tracing::warn!(path, %error, "could not remove stale upload request file");
                }
            }
        }
        let job_dir = data_dir.join("direct-media-upload").join(attachment_id);
        let _ = std::fs::remove_dir(job_dir);
    }

    Ok((stored, stale_files.len()))
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

    /// Invalidates durable upload state created for another API deployment.
    ///
    /// Attachment ids, capabilities, pre-signed object-store requests, and the
    /// manifest/complete URLs are all server-specific. Keeping them when a
    /// profile build (production API) is replaced by a debug build (development
    /// API), or vice versa, leaves the media in `backgroundUploadTaskStarted`
    /// until the old slot expires. Returning the media to `preprocessing` lets
    /// the ordinary startup sweep reserve a fresh slot and really retry it.
    async fn ensure_api_namespace(&self) -> Result<()> {
        let _guard = API_NAMESPACE_LOCK.lock().await;
        let namespace = RustApi::api_base_url("https".into());
        let database = self.ctx.app_db.read().await.clone();
        let (stored, restarted) =
            reset_upload_namespace(&database, Path::new(&self.ctx.config.data_dir), &namespace)
                .await?;
        if stored.as_deref() == Some(namespace.as_str()) {
            return Ok(());
        }

        tracing::info!(
            previous = stored.as_deref().unwrap_or("unset"),
            current = namespace,
            restarted,
            "reset direct-media uploads after API deployment changed"
        );
        Ok(())
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

    /// Tops the slot cache up without blocking the caller. Failures are
    /// expected — this runs exactly when the network may be gone — and the next
    /// reconnect preloads again.
    fn spawn_slot_refill(&self) {
        let ctx = self.ctx.clone();
        tokio::spawn(async move {
            let service = DirectMediaUploadService::new(&ctx);
            if let Ok(usable) = service.usable_slot_count().await {
                if usable > service.refill_threshold().await {
                    return;
                }
            }
            if let Err(error) = service.preload_slots().await {
                tracing::info!(%error, "could not top up the direct-media slot cache");
            }
        });
    }

    pub async fn preload_slots(&self) -> Result<usize> {
        self.ensure_api_namespace().await?;
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
        // The server decides how deep this cache may be. Remembering the number
        // keeps an offline launch from refilling against a stale guess.
        if slots.refill_threshold > 0 {
            sqlx::query(
                r#"INSERT INTO app_metadata(key, value) VALUES(?, ?)
                   ON CONFLICT(key) DO UPDATE SET value = excluded.value"#,
            )
            .bind(REFILL_THRESHOLD_KEY)
            .bind(slots.refill_threshold.to_string())
            .execute(&mut *transaction)
            .await?;
        }
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

    /// The refill point the server last advertised. Asking for slots the server
    /// will not issue costs a request per send, so its number wins over ours.
    async fn refill_threshold(&self) -> i64 {
        let database = self.ctx.app_db.read().await.clone();
        sqlx::query_scalar::<_, String>("SELECT value FROM app_metadata WHERE key = ?")
            .bind(REFILL_THRESHOLD_KEY)
            .fetch_optional(&database.pool)
            .await
            .ok()
            .flatten()
            .and_then(|value| value.parse::<i64>().ok())
            .filter(|threshold| *threshold > 0)
            .unwrap_or(DEFAULT_SLOT_REFILL_THRESHOLD)
    }

    async fn ensure_slots(&self) -> Result<()> {
        self.ensure_api_namespace().await?;
        let usable = self.usable_slot_count().await?;
        if usable > self.refill_threshold().await {
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

    /// The server's attachment state is the authority on what happened to a
    /// transfer the OS carried.
    ///
    /// Not because the native side cannot say - both uploaders finish in this
    /// process holding the HTTP status - but because that word can be lost: iOS
    /// does not relaunch after a force quit, `WorkManager` records its `Result`
    /// nowhere durable, and either can complete while this library is loaded
    /// but uninitialised. A status the server still holds survives all three.
    ///
    /// A 2xx would not settle it anyway: the upload is accepted with a 202
    /// while the manifest is still being reconciled, so only the attachment's
    /// own state says whether the recipients were dispatched.
    pub async fn reconcile(&self) -> Result<()> {
        self.ensure_api_namespace().await?;
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
            tracing::info!(
                attachment_id = job.attachment_id,
                media_id = job.media_id,
                ?state,
                "read direct-media attachment status"
            );
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
        // The cache has just lost one; refill in the background so the next
        // send does not have to be online to reserve one.
        self.spawn_slot_refill();
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
        // If Flutter is alive this lands on its long-lived Rust runtime even
        // when preparation itself was called by WorkManager. Otherwise it is a
        // no-op and the durable native retry owns reconciliation.
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
    fn cancelled_watcher_releases_process_claim() {
        WATCHING.store(true, Ordering::SeqCst);
        drop(WatchingGuard);
        assert!(!WATCHING.load(Ordering::SeqCst));
    }

    #[tokio::test]
    async fn api_namespace_change_restarts_durable_uploads() {
        let directory = tempfile::tempdir().unwrap();
        let database_path = directory.path().join("app.sqlite");
        let database = AppDatabase::new(database_path.to_str().unwrap(), None, false)
            .await
            .unwrap();
        database.run_migrations().await.unwrap();

        let job_dir = directory.path().join("direct-media-upload/attachment-1");
        std::fs::create_dir_all(&job_dir).unwrap();
        let multipart = job_dir.join("media.multipart");
        let manifest = job_dir.join("manifest.pb");
        let complete = job_dir.join("complete.pb");
        for path in [&multipart, &manifest, &complete] {
            std::fs::write(path, b"request").unwrap();
        }

        sqlx::query("INSERT INTO app_metadata(key, value) VALUES(?, 'https://api.example/api/')")
            .bind(API_NAMESPACE_KEY)
            .execute(&database.pool)
            .await
            .unwrap();
        sqlx::query(
            "INSERT INTO media_files(media_id, type, upload_state, pre_progressing_process) VALUES('media-1', 'image', 'backgroundUploadTaskStarted', 73)",
        )
        .execute(&database.pool)
        .await
        .unwrap();
        sqlx::query(
            r#"INSERT INTO direct_media_upload_slots
               (attachment_id, expires_at, maximum_object_bytes, upload_url,
                upload_fields_json, capability, state)
               VALUES('attachment-1', 9999999999, 1000000, 'https://objects.example',
                      '{}', x'01', 'reserved')"#,
        )
        .execute(&database.pool)
        .await
        .unwrap();
        sqlx::query(
            r#"INSERT INTO direct_media_upload_jobs
               (attachment_id, media_id, multipart_path, manifest_path,
                complete_body_path, native_descriptor_json, state, expires_at)
               VALUES('attachment-1', 'media-1', ?, ?, ?, '{}', 'scheduled', 9999999999)"#,
        )
        .bind(multipart.to_string_lossy().as_ref())
        .bind(manifest.to_string_lossy().as_ref())
        .bind(complete.to_string_lossy().as_ref())
        .execute(&database.pool)
        .await
        .unwrap();

        let (previous, restarted) =
            reset_upload_namespace(&database, directory.path(), "https://dev-api.example/api/")
                .await
                .unwrap();

        assert_eq!(previous.as_deref(), Some("https://api.example/api/"));
        assert_eq!(restarted, 1);
        let state = sqlx::query_as::<_, (Option<String>, Option<i64>)>(
            "SELECT upload_state, pre_progressing_process FROM media_files WHERE media_id = 'media-1'",
        )
        .fetch_one(&database.pool)
        .await
        .unwrap();
        assert_eq!(state, (Some("preprocessing".into()), None));
        assert_eq!(
            sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM direct_media_upload_jobs")
                .fetch_one(&database.pool)
                .await
                .unwrap(),
            0
        );
        assert_eq!(
            sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM direct_media_upload_slots")
                .fetch_one(&database.pool)
                .await
                .unwrap(),
            0
        );
        assert!(!multipart.exists());
        assert!(!manifest.exists());
        assert!(!complete.exists());
    }

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
