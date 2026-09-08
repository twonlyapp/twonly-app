/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Rust-owned media upload lifecycle.
//!
//! Everything that decides *what* happens to an outgoing media file lives here:
//! key generation, message fan-out rows, upload-state transitions, retry and
//! reupload policy, orphan cleanup, and handing the prepared transfer to the
//! platform background uploader.

use crate::api::proto::client::EncryptedContent;
use crate::context::Context;
use crate::database::app::tables::{Group, MediaFile};
use crate::error::{Result, TwonlyError};
use crate::native::gallery;
use crate::native::prepare;
use crate::native::video;
use crate::services::direct_media_upload::DirectMediaUploadService;
use crate::services::media_codec;
use crate::services::media_exif;
use crate::services::mediafiles::MediaFileService;
use crate::services::messages::MessageService;
use crate::user_config::UserConfig;
use crate::utils::new_uuid_v7;
use prost::Message as _;
use rand::RngCore;
use sqlx::FromRow;
use std::collections::HashMap;
use std::path::Path;
use std::sync::{Arc, LazyLock, Mutex as SyncMutex};
use tokio::sync::{Mutex, Semaphore};

/// A media file with no source bytes and no referencing message is only deleted
/// once it is old enough that no in-flight editor can still be holding it.
const ORPHAN_GRACE_SECONDS: i64 = 60 * 60;
/// Matches the Dart retransmission window: a media file that already failed
/// twice is not retried more than once every six hours.
const RETRANSMISSION_BACKOFF_SECONDS: i64 = 6 * 60 * 60;
/// The server needs a moment to hand queued messages to the recipient before a
/// marked receipt is worth retrying.
const RETRY_MARK_GRACE_SECONDS: i64 = 20;

static MEDIA_LOCKS: LazyLock<SyncMutex<HashMap<String, Arc<Mutex<()>>>>> =
    LazyLock::new(|| SyncMutex::new(HashMap::new()));

/// Backfilling a missing preview decodes a full-resolution photo, so only one
/// runs at a time: a gallery screen asking for every tile it shows would
/// otherwise decode that many photos in parallel. Re-checking the file after
/// the wait also keeps two tiles from writing the same thumbnail. The send path
/// does not take this permit — a capture must not queue behind a backfill.
static THUMBNAIL_BACKFILL: Semaphore = Semaphore::const_new(1);

/// One media file is only ever prepared by one task. Preparation reserves a
/// slot, encrypts, and writes request files, so a second concurrent run would
/// burn a slot and leave orphaned jobs behind.
fn media_lock(media_id: &str) -> Arc<Mutex<()>> {
    let mut locks = MEDIA_LOCKS
        .lock()
        .unwrap_or_else(|error| error.into_inner());
    locks.entry(media_id.to_owned()).or_default().clone()
}

#[derive(FromRow, Clone)]
struct MediaRow {
    media_id: String,
    media_type: String,
    upload_state: Option<String>,
    requires_authentication: i64,
    is_draft_media: i64,
    is_widget_media: i64,
    display_limit_in_milliseconds: Option<i64>,
    reupload_requested_by: Option<String>,
    remove_audio: Option<i64>,
    trim_start_ms: Option<i64>,
    trim_end_ms: Option<i64>,
    created_at: i64,
}

/// Why a media send stopped at `fileLimitReached`, for the chat entry to show.
pub struct MediaSizeReport {
    /// The encoded media as it sits on disk, while it is still there.
    pub media_bytes: Option<i64>,
    /// The largest single object the user's plan accepts.
    pub limit_bytes: Option<i64>,
}

#[derive(FromRow)]
struct RetransmissionReceipt {
    receipt_id: String,
    contact_id: i64,
    message_id: Option<String>,
    message: Vec<u8>,
    mark_for_retry_after_accepted: Option<i64>,
    ack_by_server_at: Option<i64>,
    retry_count: i64,
    last_retry: Option<i64>,
}

pub struct MediaUploadService {
    ctx: Arc<Context>,
}

impl MediaUploadService {
    pub fn new(ctx: &Arc<Context>) -> Self {
        Self { ctx: ctx.clone() }
    }

    /// Creates the media row and its content-encryption material. The row is
    /// the only durable handle the UI needs; every later step is addressed by
    /// its media id.
    pub async fn initialize(
        &self,
        media_type: String,
        display_limit_in_milliseconds: Option<i64>,
        is_draft_media: bool,
    ) -> Result<String> {
        // The UI historically passed seconds in some places and milliseconds in
        // others; anything below a second can only have meant seconds.
        let display_limit =
            display_limit_in_milliseconds
                .map(|limit| if limit < 1_000 { limit * 1_000 } else { limit });
        let mut encryption_key = vec![0_u8; 32];
        rand::rng().fill_bytes(&mut encryption_key);
        let mut encryption_nonce = vec![0_u8; 12];
        rand::rng().fill_bytes(&mut encryption_nonce);
        let media_id = new_uuid_v7();

        let database = self.ctx.app_db.read().await.clone();
        let mut transaction = database.pool.begin().await?;
        sqlx::query("UPDATE media_files SET is_draft_media = 0 WHERE is_draft_media = 1")
            .execute(&mut *transaction)
            .await?;
        sqlx::query(
            r#"INSERT INTO media_files
               (media_id, type, upload_state, display_limit_in_milliseconds,
                encryption_key, encryption_nonce, is_draft_media)
               VALUES (?, ?, 'initialized', ?, ?, ?, ?)"#,
        )
        .bind(&media_id)
        .bind(&media_type)
        .bind(display_limit)
        .bind(&encryption_key)
        .bind(&encryption_nonce)
        .bind(i64::from(is_draft_media))
        .execute(&mut *transaction)
        .await?;
        transaction.commit().await?;
        Ok(media_id)
    }

    /// Turns an edited media file into one outgoing message per selected group
    /// and hands the send to the background uploader.
    pub async fn insert_into_messages(
        &self,
        media_id: String,
        group_ids: Vec<String>,
        additional_message_data: Option<Vec<u8>>,
        widget_only: bool,
    ) -> Result<()> {
        let database = self.ctx.app_db.read().await.clone();
        let now = chrono::Utc::now().timestamp();

        let mut transaction = database.pool.begin().await?;
        if widget_only {
            let media = sqlx::query_as::<_, (String, Option<i64>)>(
                "SELECT type, display_limit_in_milliseconds FROM media_files WHERE media_id = ?",
            )
            .bind(&media_id)
            .fetch_optional(&mut *transaction)
            .await?
            .ok_or_else(|| TwonlyError::Generic(format!("media {media_id} does not exist")))?;
            if media.0 != "image" || media.1.is_some() {
                return Err(TwonlyError::Generic(
                    "widget sends require an unlimited image".into(),
                ));
            }
            sqlx::query("UPDATE media_files SET is_widget_media = 1 WHERE media_id = ?")
                .bind(&media_id)
                .execute(&mut *transaction)
                .await?;
        }
        sqlx::query("UPDATE media_files SET is_draft_media = 0 WHERE is_draft_media = 1")
            .execute(&mut *transaction)
            .await?;
        for group_id in &group_ids {
            let members = sqlx::query_as::<_, (i64, i64)>(
                r#"SELECT gm.contact_id, c.account_deleted
                   FROM group_members gm
                   JOIN contacts c ON c.user_id = gm.contact_id
                   WHERE gm.group_id = ?"#,
            )
            .bind(group_id)
            .fetch_all(&mut *transaction)
            .await?;
            if widget_only
                && (members.len() != 1
                    || sqlx::query_scalar::<_, i64>(
                        "SELECT widget_sharing_allowed FROM contacts WHERE user_id = ?",
                    )
                    .bind(members.first().map(|member| member.0).unwrap_or_default())
                    .fetch_optional(&mut *transaction)
                    .await?
                    .unwrap_or(0)
                        == 0)
            {
                return Err(TwonlyError::Generic(
                    "recipient has not granted widget sharing".into(),
                ));
            }
            // A direct chat whose only peer deleted their account has nobody
            // left to receive the media.
            if members.len() == 1 && members[0].1 != 0 {
                tracing::warn!(group_id, "skipping media send to a deleted account");
                continue;
            }

            let message_id = new_uuid_v7();
            sqlx::query(
                r#"INSERT INTO messages
                   (group_id, message_id, type, media_id, additional_message_data,
                    is_widget_media, created_at)
                   VALUES (?, ?, 'media', ?, ?, ?, ?)"#,
            )
            .bind(group_id)
            .bind(&message_id)
            .bind(&media_id)
            .bind(additional_message_data.as_deref())
            .bind(widget_only)
            .bind(now)
            .execute(&mut *transaction)
            .await?;
            if !widget_only {
                sqlx::query(
                    r#"UPDATE groups SET archived = 0, deleted_content = 0,
                           last_message_exchange = MAX(last_message_exchange, ?)
                       WHERE group_id = ?"#,
                )
                .bind(now)
                .bind(group_id)
                .execute(&mut *transaction)
                .await?;
                Group::record_media_exchange(&mut transaction, group_id, false, now).await?;
            }
        }
        transaction.commit().await?;
        drop(database);

        // Preparation compresses and encrypts, which is far too slow to keep the
        // send button blocked; the media row is already durable at this point.
        // It is also the only part of a send that no OS transfer is carrying
        // yet, so it is handed to the platform rather than left in a bare task
        // that dies with the process.
        self.spawn_preparation(media_id);
        Ok(())
    }

    /// Runs `start_upload` under whatever protection the platform offers. On
    /// Android the work itself moves into a `WorkManager` job and nothing is
    /// started here.
    fn spawn_preparation(&self, media_id: String) {
        match prepare::begin(&media_id) {
            prepare::Preparation::Scheduled => {
                tracing::info!(media_id, "handed media preparation to the OS");
            }
            prepare::Preparation::InProcess(guard) => {
                let ctx = self.ctx.clone();
                tokio::spawn(async move {
                    // Held for the whole preparation: dropping it tells the
                    // platform this process no longer needs to keep running.
                    let _guard = guard;
                    match MediaUploadService::new(&ctx).start_upload(&media_id).await {
                        Ok(()) => {
                            // This branch runs on the application's long-lived
                            // runtime (iOS and desktop). Android preparation is
                            // scheduled through WorkManager and reconciles
                            // durably there instead.
                            crate::services::direct_media_upload::watch_pending_uploads(&ctx);
                        }
                        Err(error) => {
                            tracing::warn!(media_id, %error, "starting the media upload failed");
                        }
                    }
                });
            }
        }
    }

    /// Transcodes a captured video before the user has chosen recipients.
    ///
    /// A hardware transcode is by far the longest thing between the send button
    /// and the point where the OS owns the transfer, and it does not depend on
    /// anything the editor produces. Doing it up front leaves the send with
    /// nothing but an encryption pass, which is short enough to finish inside
    /// the grace period a closing app gets.
    ///
    /// The result is only used when the editor's final state agrees with it,
    /// so a user who does draw on the clip pays for a wasted render rather than
    /// getting a second encoding pass over an already encoded file.
    pub async fn prerender(&self, media_id: &str) -> Result<()> {
        let lock = media_lock(media_id);
        let _guard = lock.lock().await;

        let Some(media) = self.load(media_id).await? else {
            return Ok(());
        };
        // Anything past `initialized` is either being sent or already sent, and
        // a pre-render would race the send for the same output file.
        if media.media_type != "video" || media.upload_state.as_deref() != Some("initialized") {
            return Ok(());
        }
        let files = MediaFileService::new(&self.ctx);
        let fingerprint = render_fingerprint(&media);
        if files.prerender_matches(media_id, &fingerprint) {
            return Ok(());
        }
        let original = files.original_path(media_id, &media.media_type);
        if !original.exists() {
            return Ok(());
        }
        // A marker from earlier settings would otherwise outlive its clip.
        files.discard_prerender(media_id);

        let output = files.prerendered_path(media_id);
        MediaFileService::ensure_parent(&output)?;
        let (trim_start_ms, trim_end_ms) = trim_bounds(&media);
        let request = video::RenderRequest {
            media_id: media_id.to_owned(),
            input: original,
            overlay: None,
            output: output.clone(),
            remove_audio: media.remove_audio.unwrap_or(0) != 0,
            trim_start_ms,
            trim_end_ms,
        };
        if let Err(error) = blocking(move || video::render(&request)).await {
            // The send path renders from the original, so this costs nothing
            // beyond the time already spent.
            tracing::info!(media_id, %error, "pre-rendering the video failed");
            remove_file(&output);
            return Ok(());
        }
        files.write_prerender_marker(media_id, &fingerprint)?;
        tracing::info!(media_id, "pre-rendered the captured video");
        Ok(())
    }

    /// Advances one media file as far towards "scheduled" as it can get right
    /// now. Safe to call repeatedly and from maintenance passes.
    pub async fn start_upload(&self, media_id: &str) -> Result<()> {
        let lock = media_lock(media_id);
        let _guard = lock.lock().await;
        self.start_upload_locked(media_id).await
    }

    async fn start_upload_locked(&self, media_id: &str) -> Result<()> {
        let Some(media) = self.load(media_id).await? else {
            return Ok(());
        };
        // `uploading` and `uploadLimitReached` are legacy states from the
        // Dart-driven upload; both simply restart preparation now.
        if !matches!(
            media.upload_state.as_deref(),
            Some("initialized" | "preprocessing" | "uploading" | "uploadLimitReached")
        ) {
            return Ok(());
        }
        self.set_upload_state(media_id, "preprocessing").await?;

        let files = MediaFileService::new(&self.ctx);
        let temp_path = files.temp_path(media_id, &media.media_type);
        let stored_path = files.stored_path(media_id, &media.media_type);
        if !temp_path.exists() {
            if stored_path.exists() {
                MediaFileService::ensure_parent(&temp_path)?;
                std::fs::copy(&stored_path, &temp_path)?;
            } else {
                self.compress(&media).await?;
            }
        }
        if !temp_path.exists() {
            return self.retire_media(&media).await;
        }
        // What the recipient ends up with is this plaintext, so its size is
        // recorded while the file is still here: the temporary copy is dropped
        // once the upload is scheduled, and the message info still shows it.
        if let Err(error) = self.record_plaintext_size(media_id, &temp_path).await {
            tracing::warn!(media_id, %error, "could not record the media size");
        }

        // Auto-storing has to happen before the plaintext is consumed, and only
        // for media the recipient could have kept anyway.
        let config = UserConfig::load_required_from(&self.ctx)?;
        if config.auto_store_all_send_unlimited_media_files
            && media.requires_authentication == 0
            && media.display_limit_in_milliseconds.is_none()
            && !stored_path.exists()
        {
            self.store(media_id).await?;
        }

        match DirectMediaUploadService::new(&self.ctx)
            .prepare_and_schedule(media_id)
            .await
        {
            Ok(attachment_id) => {
                self.set_upload_state(media_id, "backgroundUploadTaskStarted")
                    .await?;
                // Both native tasks now own durable request files, so the
                // uncompressed original is no longer needed.
                remove_file(&files.original_path(media_id, &media.media_type));
                tracing::info!(media_id, attachment_id, "scheduled native media upload");
                Ok(())
            }
            // No amount of retrying shrinks the file, so this is where the
            // send stops. `fileLimitReached` is outside the set this method
            // restarts from, which is what keeps the maintenance pass from
            // picking it up again, and the chat entry renders it as a warning.
            Err(TwonlyError::MediaTooLarge { bytes, limit }) => {
                tracing::warn!(
                    media_id,
                    bytes,
                    limit,
                    "media exceeds the plan's single-object limit"
                );
                self.set_upload_state(media_id, "fileLimitReached").await
            }
            Err(error) => {
                // Staying in `preprocessing` lets the next maintenance pass or
                // reconnect retry without any extra bookkeeping.
                tracing::warn!(media_id, %error, "direct media upload scheduling failed");
                Ok(())
            }
        }
    }

    /// Recovers every upload that a terminated process left mid-flight, and
    /// settles the transfers the server has meanwhile accepted or rejected.
    pub async fn finish_started_uploads(&self) -> Result<()> {
        let _guard = self.ctx.media_preprocessing.lock().await;
        let direct = DirectMediaUploadService::new(&self.ctx);
        if let Err(error) = direct.reconcile().await {
            tracing::warn!(%error, "direct media reconciliation failed");
        }
        // Transfers the OS is still carrying settle without notifying this
        // process, so keep asking while the app is up.
        if direct.pending_job_count().await.unwrap_or(0) > 0 {
            crate::services::direct_media_upload::watch_pending_uploads(&self.ctx);
        }

        let database = self.ctx.app_db.read().await.clone();
        let pending = sqlx::query_as::<_, MediaRow>(
            r#"SELECT media_id, type AS media_type, upload_state, requires_authentication,
                      is_draft_media, is_widget_media, display_limit_in_milliseconds, reupload_requested_by,
                      remove_audio, trim_start_ms, trim_end_ms, created_at
               FROM media_files
               WHERE upload_state IN
                     ('initialized', 'preprocessing', 'uploading', 'uploadLimitReached')"#,
        )
        .fetch_all(&database.pool)
        .await?;
        drop(database);

        for media in pending {
            if media.is_draft_media != 0 {
                continue;
            }
            if self.message_count(&media.media_id).await? == 0 {
                self.retire_media(&media).await?;
                continue;
            }
            if let Err(error) = self.start_upload(&media.media_id).await {
                tracing::warn!(media_id = media.media_id, %error, "could not resume media upload");
            }
        }
        Ok(())
    }

    /// A recipient could not decrypt the media, so it has to be encrypted and
    /// uploaded again — but only for the contacts that asked for it.
    pub async fn reupload(&self, contact_id: i64, media_id: &str, message_id: &str) -> Result<()> {
        let lock = media_lock(media_id);
        let _guard = lock.lock().await;

        let database = self.ctx.app_db.read().await.clone();
        sqlx::query(
            r#"UPDATE receipts SET mark_for_retry = NULL, mark_for_retry_after_accepted = NULL
               WHERE contact_id = ? AND message_id = ?"#,
        )
        .bind(contact_id)
        .bind(message_id)
        .execute(&database.pool)
        .await?;

        let Some(media) = self.load(media_id).await? else {
            return Ok(());
        };
        let mut requested_by = parse_reupload_requested_by(media.reupload_requested_by.as_deref());
        if !requested_by.contains(&contact_id) {
            requested_by.push(contact_id);
        }
        sqlx::query(
            r#"UPDATE media_files SET upload_state = 'preprocessing', reupload_requested_by = ?
               WHERE media_id = ?"#,
        )
        .bind(serde_json::to_string(&requested_by)?)
        .bind(media_id)
        .execute(&database.pool)
        .await?;
        drop(database);

        // The legacy pre-built upload request would pin the old recipient set.
        remove_file(
            &MediaFileService::new(&self.ctx).upload_request_path(media_id, &media.media_type),
        );
        self.start_upload_locked(media_id).await
    }

    /// Periodic maintenance over receipts whose media send never completed.
    pub async fn reupload_pending(&self) -> Result<()> {
        let _guard = self.ctx.media_retransmission.lock().await;
        let now = chrono::Utc::now().timestamp();
        let database = self.ctx.app_db.read().await.clone();
        let receipts = sqlx::query_as::<_, RetransmissionReceipt>(
            r#"SELECT receipt_id, contact_id, message_id, message,
                      mark_for_retry_after_accepted, ack_by_server_at, retry_count, last_retry
               FROM receipts
               WHERE will_be_retried_by_media_upload = 1
                 AND (mark_for_retry < ? OR mark_for_retry_after_accepted < ?)"#,
        )
        .bind(now - RETRY_MARK_GRACE_SECONDS)
        .bind(now - RETRY_MARK_GRACE_SECONDS)
        .fetch_all(&database.pool)
        .await?;
        drop(database);

        if receipts.is_empty() {
            return Ok(());
        }
        tracing::info!(count = receipts.len(), "reuploading media files");

        for receipt in receipts {
            if let Err(error) = self.retransmit_receipt(receipt, now).await {
                tracing::warn!(%error, "media retransmission failed");
            }
        }
        Ok(())
    }

    async fn retransmit_receipt(&self, receipt: RetransmissionReceipt, now: i64) -> Result<()> {
        if receipt.retry_count > 1
            && receipt
                .last_retry
                .is_some_and(|last| last > now - RETRANSMISSION_BACKOFF_SECONDS)
        {
            return Ok(());
        }

        let database = self.ctx.app_db.read().await.clone();
        let message_id = match receipt.message_id.clone() {
            Some(message_id) => message_id,
            // Older receipts stored the message only inside their ciphertext.
            None => {
                let Some(message_id) = EncryptedContent::decode(receipt.message.as_slice())
                    .ok()
                    .and_then(|content| content.media)
                    .map(|media| media.sender_message_id)
                else {
                    tracing::warn!(receipt.receipt_id, "receipt has no recoverable message id");
                    return Ok(());
                };
                let exists = sqlx::query_scalar::<_, i64>(
                    "SELECT EXISTS(SELECT 1 FROM messages WHERE message_id = ?)",
                )
                .bind(&message_id)
                .fetch_one(&database.pool)
                .await?
                    != 0;
                if !exists {
                    sqlx::query("DELETE FROM receipts WHERE receipt_id = ?")
                        .bind(&receipt.receipt_id)
                        .execute(&database.pool)
                        .await?;
                    return Ok(());
                }
                sqlx::query("UPDATE receipts SET message_id = ? WHERE receipt_id = ?")
                    .bind(&message_id)
                    .bind(&receipt.receipt_id)
                    .execute(&database.pool)
                    .await?;
                message_id
            }
        };

        // Nothing can be delivered to a contact who has not accepted yet.
        if receipt.mark_for_retry_after_accepted.is_some() {
            let accepted = sqlx::query_scalar::<_, Option<i64>>(
                "SELECT accepted FROM contacts WHERE user_id = ?",
            )
            .bind(receipt.contact_id)
            .fetch_optional(&database.pool)
            .await?
            .flatten();
            if accepted.unwrap_or(0) == 0 {
                return Ok(());
            }
        }

        if receipt.ack_by_server_at.is_some() {
            // The object should still be on the server, so resending the
            // envelope with its download token is enough.
            drop(database);
            return MessageService::new(&self.ctx)
                .send_receipt(receipt.receipt_id)
                .await;
        }

        let media_id = sqlx::query_scalar::<_, Option<String>>(
            "SELECT media_id FROM messages WHERE message_id = ?",
        )
        .bind(&message_id)
        .fetch_optional(&database.pool)
        .await?
        .flatten();
        let Some(media_id) = media_id else {
            // Neither the message nor its media exist any more.
            sqlx::query("DELETE FROM messages WHERE message_id = ?")
                .bind(&message_id)
                .execute(&database.pool)
                .await?;
            sqlx::query("DELETE FROM receipts WHERE receipt_id = ?")
                .bind(&receipt.receipt_id)
                .execute(&database.pool)
                .await?;
            return Ok(());
        };
        drop(database);

        self.reupload(receipt.contact_id, &media_id, &message_id)
            .await
    }

    /// Keeps the local copy of a media file and derives everything the gallery
    /// and chat list need from it.
    pub async fn store(&self, media_id: &str) -> Result<()> {
        let Some(media) = self.load(media_id).await? else {
            return Ok(());
        };
        let database = self.ctx.app_db.read().await.clone();
        sqlx::query("UPDATE media_files SET stored = 1 WHERE media_id = ?")
            .bind(media_id)
            .execute(&database.pool)
            .await?;
        drop(database);

        let files = MediaFileService::new(&self.ctx);
        let temp_path = files.temp_path(media_id, &media.media_type);
        let stored_path = files.stored_path(media_id, &media.media_type);
        if !temp_path.exists() && files.original_path(media_id, &media.media_type).exists() {
            self.compress(&media).await?;
        }
        if !temp_path.exists() {
            tracing::warn!(media_id, "cannot store media without its plaintext");
            return Ok(());
        }
        MediaFileService::ensure_parent(&stored_path)?;
        std::fs::copy(&temp_path, &stored_path)?;

        let config = UserConfig::load_required_from(&self.ctx)?;
        if config.store_media_files_in_gallery {
            if let Err(error) = self.save_to_gallery(media_id).await {
                tracing::warn!(media_id, %error, "could not export the media to the gallery");
            }
        }
        self.create_thumbnail(&media).await?;
        // Trust the filesystem rather than what the encoder reported: a
        // thumbnail that was not written must not be advertised to the UI.
        if files.thumbnail_path(media_id).exists() {
            self.update_media(
                "UPDATE media_files SET has_thumbnail = ? WHERE media_id = ?",
                1_i64,
                media_id,
            )
            .await?;
        }
        self.refresh_stored_metadata(media_id, &stored_path).await
    }

    /// Size and content hash are read back from the file that was actually
    /// written, never from the value the caller believed it wrote. Videos can
    /// be tens of megabytes, so the hash streams instead of buffering.
    async fn refresh_stored_metadata(&self, media_id: &str, stored_path: &Path) -> Result<()> {
        let mut file = std::fs::File::open(stored_path)?;
        let mut hasher = <sha2::Sha256 as sha2::Digest>::new();
        let size = std::io::copy(&mut file, &mut hasher)? as i64;
        let hash = <sha2::Sha256 as sha2::Digest>::finalize(hasher).to_vec();
        let database = self.ctx.app_db.read().await.clone();
        sqlx::query(
            "UPDATE media_files SET size_in_bytes = ?, stored_file_hash = ? WHERE media_id = ?",
        )
        .bind(size)
        .bind(hash)
        .bind(media_id)
        .execute(&database.pool)
        .await?;
        Ok(())
    }

    /// The size the user is shown for a media file is the plaintext one, not
    /// what the encrypted upload weighs, and it is kept even after the file
    /// itself is gone.
    async fn record_plaintext_size(&self, media_id: &str, path: &Path) -> Result<()> {
        let size = std::fs::metadata(path)?.len() as i64;
        self.update_media(
            "UPDATE media_files SET size_in_bytes = ? WHERE media_id = ?",
            size,
            media_id,
        )
        .await
    }

    /// Called by Flutter after a plugin step rewrote a media file on disk, so
    /// the derived state Rust owns is recomputed from what was actually written.
    pub async fn media_step_finished(&self, media_id: &str, kind: &str) -> Result<()> {
        let files = MediaFileService::new(&self.ctx);
        match kind {
            "thumbnail" => {
                // The caller asks for a thumbnail, not just for the flag to be
                // refreshed: a UI that only ever recorded "still missing" would
                // ask again on every rebuild and never get a preview.
                if !files.thumbnail_path(media_id).exists() {
                    let permit = THUMBNAIL_BACKFILL.acquire().await;
                    if !files.thumbnail_path(media_id).exists() {
                        let Some(media) = self.load(media_id).await? else {
                            return Ok(());
                        };
                        self.create_thumbnail(&media).await?;
                    }
                    drop(permit);
                }
                self.update_media(
                    "UPDATE media_files SET has_thumbnail = ? WHERE media_id = ?",
                    i64::from(files.thumbnail_path(media_id).exists()),
                    media_id,
                )
                .await
            }
            "stored" => {
                let Some(media) = self.load(media_id).await? else {
                    return Ok(());
                };
                let stored_path = files.stored_path(media_id, &media.media_type);
                if stored_path.exists() {
                    return self.refresh_stored_metadata(media_id, &stored_path).await;
                }
                // A file the user chose to keep, that no cloud copy backs, and
                // that has been gone long enough to not be a transient state,
                // is not coming back.
                let database = self.ctx.app_db.read().await.clone();
                let removable = sqlx::query_scalar::<_, i64>(
                    r#"SELECT EXISTS(
                           SELECT 1 FROM media_files
                           WHERE media_id = ? AND stored = 1 AND cloud_state = 'none'
                             AND created_at < ?
                       )"#,
                )
                .bind(media_id)
                .bind(chrono::Utc::now().timestamp() - 30 * 24 * 60 * 60)
                .fetch_one(&database.pool)
                .await?
                    != 0;
                if removable {
                    self.delete(media_id).await?;
                }
                Ok(())
            }
            "crop" => {
                self.update_media(
                    "UPDATE media_files SET has_crop_analyzed = ? WHERE media_id = ?",
                    1_i64,
                    media_id,
                )
                .await?;
                let Some(media) = self.load(media_id).await? else {
                    return Ok(());
                };
                let stored_path = files.stored_path(media_id, &media.media_type);
                if stored_path.exists() {
                    self.refresh_stored_metadata(media_id, &stored_path).await?;
                }
                Ok(())
            }
            _ => Ok(()),
        }
    }

    /// Drops every file of a media item while keeping its row, so a message
    /// that still references it keeps rendering as an expired media message.
    pub async fn remove_files(&self, media_id: &str) -> Result<()> {
        let Some(media) = self.load(media_id).await? else {
            return Ok(());
        };
        MediaFileService::new(&self.ctx).remove_files(media_id, &media.media_type)
    }

    /// Drops the files and the row. Only for media nothing references any more.
    async fn delete(&self, media_id: &str) -> Result<()> {
        self.remove_files(media_id).await?;
        let database = self.ctx.app_db.read().await.clone();
        sqlx::query("DELETE FROM media_files WHERE media_id = ?")
            .bind(media_id)
            .execute(&database.pool)
            .await?;
        Ok(())
    }

    /// The media can never be sent — its source could not be produced at all.
    /// The recipients' messages become "deleted by the sender" and the upload
    /// loop stops instead of retrying something that cannot succeed.
    pub async fn abandon(&self, media_id: &str) -> Result<()> {
        let Some(media) = self.load(media_id).await? else {
            return Ok(());
        };
        let database = self.ctx.app_db.read().await.clone();
        sqlx::query("UPDATE messages SET is_deleted_from_sender = 1 WHERE media_id = ?")
            .bind(media_id)
            .execute(&database.pool)
            .await?;
        sqlx::query("UPDATE media_files SET upload_state = 'uploaded' WHERE media_id = ?")
            .bind(media_id)
            .execute(&database.pool)
            .await?;
        MediaFileService::new(&self.ctx).remove_files(media_id, &media.media_type)?;
        tracing::warn!(
            media_id,
            "abandoned a media file that could not be prepared"
        );
        Ok(())
    }

    /// Deletes temporary media whose message is finished with it. Everything
    /// that decides "finished" is a policy question, so it lives here rather
    /// than in the view layer that happens to trigger the sweep.
    pub async fn purge_temp_folder(&self) -> Result<()> {
        let temp_directory = std::path::PathBuf::from(&self.ctx.config.data_dir)
            .join("mediafiles")
            .join("tmp");
        let Ok(entries) = std::fs::read_dir(&temp_directory) else {
            return Ok(());
        };

        let mut files_by_media: HashMap<String, Vec<std::path::PathBuf>> = HashMap::new();
        for entry in entries.flatten() {
            let path = entry.path();
            let Some(media_id) = path
                .file_name()
                .and_then(|name| name.to_str())
                .and_then(|name| name.split('.').next())
            else {
                continue;
            };
            files_by_media
                .entry(media_id.to_owned())
                .or_default()
                .push(path);
        }

        for (media_id, paths) in files_by_media {
            if !self.temp_files_are_purgeable(&media_id).await? {
                continue;
            }
            tracing::info!(media_id, "purging temporary media files");
            for path in paths {
                remove_file(&path);
            }
        }
        Ok(())
    }

    /// What the chat entry needs to explain a `fileLimitReached` send: how big
    /// the media turned out and the largest single object the plan accepts.
    ///
    /// The limit is read back from the most recent upload slot rather than
    /// tracked separately, because the slot is where the server states it. The
    /// size is whatever is still on disk, so it goes missing once the temporary
    /// files are purged — the limit alone is what the user can act on.
    pub async fn size_limit_report(&self, media_id: &str) -> Result<MediaSizeReport> {
        let database = self.ctx.app_db.read().await.clone();
        let limit_bytes = sqlx::query_scalar::<_, i64>(
            "SELECT maximum_object_bytes FROM direct_media_upload_slots ORDER BY created_at DESC LIMIT 1",
        )
        .fetch_optional(&database.pool)
        .await?;
        let media_bytes = match self.load(media_id).await? {
            Some(media) => {
                let files = MediaFileService::new(&self.ctx);
                [
                    files.temp_path(media_id, &media.media_type),
                    files.stored_path(media_id, &media.media_type),
                ]
                .iter()
                .find_map(|path| std::fs::metadata(path).ok())
                .map(|metadata| metadata.len() as i64)
            }
            None => None,
        };
        Ok(MediaSizeReport {
            media_bytes,
            limit_bytes,
        })
    }

    async fn temp_files_are_purgeable(&self, media_id: &str) -> Result<bool> {
        let database = self.ctx.app_db.read().await.clone();
        let Some(media) = self.load(media_id).await? else {
            // Nothing in the database refers to these bytes any more.
            return Ok(true);
        };
        if media.is_draft_media != 0 || media.is_widget_media != 0 {
            return Ok(false);
        }
        // The plaintext is the upload's input, so it must outlive the transfer.
        if !matches!(
            media.upload_state.as_deref(),
            Some("uploaded" | "fileLimitReached")
        ) {
            return Ok(false);
        }
        // Voice messages stay playable.
        if media.media_type == "audio" {
            let has_message = sqlx::query_scalar::<_, i64>(
                "SELECT EXISTS(SELECT 1 FROM messages WHERE media_id = ?)",
            )
            .bind(media_id)
            .fetch_one(&database.pool)
            .await?
                != 0;
            if has_message {
                return Ok(false);
            }
        }

        let now = chrono::Utc::now().timestamp();
        let keepers = sqlx::query_scalar::<_, i64>(
            r#"SELECT COUNT(*) FROM messages m
               JOIN media_files f ON f.media_id = m.media_id
               JOIN groups g ON g.group_id = m.group_id
               WHERE m.media_id = ?
                 AND (
                   m.opened_at IS NULL
                   -- Opening a message races this sweep; give the viewer a
                   -- moment before its source disappears underneath it.
                   OR m.opened_at > ?
                   OR (
                     f.requires_authentication = 0
                     AND f.display_limit_in_milliseconds IS NULL
                     AND m.opened_at > ?
                     -- A group member may still store it, and the sender may
                     -- still reopen their own copy.
                     AND (m.sender_id IS NULL OR g.is_direct_chat = 0)
                   )
                 )"#,
        )
        .bind(media_id)
        .bind(now - 3 * 60)
        .bind(now - 2 * 24 * 60 * 60)
        .fetch_one(&database.pool)
        .await?;
        Ok(keepers == 0)
    }

    pub async fn set_display_limit(
        &self,
        media_id: &str,
        display_limit_in_milliseconds: Option<i64>,
    ) -> Result<()> {
        self.update_media(
            "UPDATE media_files SET display_limit_in_milliseconds = ? WHERE media_id = ?",
            display_limit_in_milliseconds,
            media_id,
        )
        .await
    }

    pub async fn set_requires_authentication(
        &self,
        media_id: &str,
        requires_authentication: bool,
    ) -> Result<()> {
        let database = self.ctx.app_db.read().await.clone();
        // Authenticated media is always time limited; the UI has no control
        // that could set both independently.
        if requires_authentication {
            sqlx::query(
                r#"UPDATE media_files
                   SET requires_authentication = 1, display_limit_in_milliseconds = 12000
                   WHERE media_id = ?"#,
            )
            .bind(media_id)
            .execute(&database.pool)
            .await?;
        } else {
            sqlx::query("UPDATE media_files SET requires_authentication = 0 WHERE media_id = ?")
                .bind(media_id)
                .execute(&database.pool)
                .await?;
        }
        Ok(())
    }

    /// Stores where the editor's cutter placed the two ends of a video.
    ///
    /// Both bounds are milliseconds into the recording; `None` means the clip
    /// keeps that end. The recording itself is never rewritten - the transcode
    /// every send performs applies the cut - so this stays reversible for as
    /// long as the editor is open.
    pub async fn set_trim(
        &self,
        media_id: &str,
        trim_start_ms: Option<i64>,
        trim_end_ms: Option<i64>,
    ) -> Result<()> {
        let database = self.ctx.app_db.read().await.clone();
        sqlx::query("UPDATE media_files SET trim_start_ms = ?, trim_end_ms = ? WHERE media_id = ?")
            .bind(trim_start_ms)
            .bind(trim_end_ms)
            .bind(media_id)
            .execute(&database.pool)
            .await?;
        Ok(())
    }

    pub async fn toggle_remove_audio(&self, media_id: &str) -> Result<()> {
        let database = self.ctx.app_db.read().await.clone();
        sqlx::query(
            "UPDATE media_files SET remove_audio = 1 - COALESCE(remove_audio, 0) WHERE media_id = ?",
        )
        .bind(media_id)
        .execute(&database.pool)
        .await?;
        drop(database);
        // The pre-rendered clip carries the old audio decision, and
        // `prerender_matches` would reject it anyway; dropping it now frees the
        // space and lets a fresh pre-render start.
        MediaFileService::new(&self.ctx).discard_prerender(media_id);
        Ok(())
    }

    async fn update_media<T>(&self, query: &'static str, value: T, media_id: &str) -> Result<()>
    where
        T: for<'q> sqlx::Encode<'q, sqlx::Sqlite> + sqlx::Type<sqlx::Sqlite> + Send + 'static,
    {
        let database = self.ctx.app_db.read().await.clone();
        sqlx::query(query)
            .bind(value)
            .bind(media_id)
            .execute(&database.pool)
            .await?;
        Ok(())
    }

    async fn set_upload_state(&self, media_id: &str, state: &str) -> Result<()> {
        self.update_media(
            "UPDATE media_files SET upload_state = ? WHERE media_id = ?",
            state.to_owned(),
            media_id,
        )
        .await
    }

    /// The media cannot be sent as it stands: either its plaintext is gone or
    /// nothing references it any more. What that means depends entirely on who
    /// is still waiting for it.
    async fn retire_media(&self, media: &MediaRow) -> Result<()> {
        let media_id = &media.media_id;
        let database = self.ctx.app_db.read().await.clone();

        if media.reupload_requested_by.is_some() {
            tracing::warn!(media_id, "reupload requested but the source is gone");
            sqlx::query(
                r#"UPDATE media_files SET upload_state = 'uploaded', reupload_requested_by = NULL
                   WHERE media_id = ?"#,
            )
            .bind(media_id)
            .execute(&database.pool)
            .await?;
            return Ok(());
        }

        if self.message_count(media_id).await? > 0 {
            // Deleting the row would break the chat history, so only stop the
            // retry loop.
            tracing::warn!(
                media_id,
                "media source is gone but messages still reference it"
            );
            sqlx::query("UPDATE media_files SET upload_state = 'uploaded' WHERE media_id = ?")
                .bind(media_id)
                .execute(&database.pool)
                .await?;
            return Ok(());
        }

        if media.created_at > chrono::Utc::now().timestamp() - ORPHAN_GRACE_SECONDS {
            // Still inside the editing window: the user may not have picked
            // recipients yet.
            return Ok(());
        }
        tracing::info!(media_id, "deleting orphaned media file");
        MediaFileService::new(&self.ctx).remove_files(media_id, &media.media_type)?;
        sqlx::query("DELETE FROM media_files WHERE media_id = ?")
            .bind(media_id)
            .execute(&database.pool)
            .await?;
        Ok(())
    }

    /// Marks an upload as delivered when a receiver's response proves the media
    /// arrived, even though the transfer callback never reached this device.
    pub async fn mark_uploaded(&self, media_id: &str) -> Result<()> {
        let database = self.ctx.app_db.read().await.clone();
        let mut transaction = database.pool.begin().await?;
        MediaFile::mark_uploaded(&mut transaction, media_id).await?;
        transaction.commit().await?;
        Ok(())
    }

    async fn load(&self, media_id: &str) -> Result<Option<MediaRow>> {
        let database = self.ctx.app_db.read().await.clone();
        Ok(sqlx::query_as::<_, MediaRow>(
            r#"SELECT media_id, type AS media_type, upload_state, requires_authentication,
                      is_draft_media, is_widget_media, display_limit_in_milliseconds, reupload_requested_by,
                      remove_audio, trim_start_ms, trim_end_ms, created_at
               FROM media_files WHERE media_id = ?"#,
        )
        .bind(media_id)
        .fetch_optional(&database.pool)
        .await?)
    }

    async fn message_count(&self, media_id: &str) -> Result<i64> {
        let database = self.ctx.app_db.read().await.clone();
        Ok(
            sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM messages WHERE media_id = ?")
                .bind(media_id)
                .fetch_one(&database.pool)
                .await?,
        )
    }

    /// Produces the plaintext that actually gets encrypted and sent. Stills are
    /// encoded here with libwebp; only video still needs the Flutter editor,
    /// and GIF and audio are sent in their original container.
    async fn compress(&self, media: &MediaRow) -> Result<()> {
        let files = MediaFileService::new(&self.ctx);
        let original = files.original_path(&media.media_id, &media.media_type);
        let temp = files.temp_path(&media.media_id, &media.media_type);
        if !original.exists() {
            tracing::warn!(media_id = media.media_id, "no original media to compress");
            return Ok(());
        }
        match media.media_type.as_str() {
            "video" => self.render_video(media, &original, &temp).await,
            "image" => {
                let (source, destination) = (original.clone(), temp.clone());
                let started = std::time::Instant::now();
                let mut used_uncompressed_fallback = false;
                match blocking(move || media_codec::compress_for_send(&source, &destination)).await
                {
                    Ok(()) => {}
                    Err(error) => {
                        // Sending the original beats not sending at all, which is
                        // what the Flutter implementation did on a codec failure.
                        tracing::warn!(media_id = media.media_id, %error, "sending the uncompressed image");
                        MediaFileService::ensure_parent(&temp)?;
                        std::fs::copy(&original, &temp)?;
                        used_uncompressed_fallback = true;
                    }
                }
                tracing::info!(
                    media_id = media.media_id,
                    source_bytes = file_size_or_zero(&original),
                    output_bytes = file_size_or_zero(&temp),
                    used_uncompressed_fallback,
                    total_ms = started.elapsed().as_millis() as u64,
                    "image compression phase finished"
                );
                Ok(())
            }
            // GIF keeps its animation and audio is already in its delivery
            // container, so both are sent byte for byte.
            _ => {
                MediaFileService::ensure_parent(&temp)?;
                std::fs::copy(&original, &temp)?;
                Ok(())
            }
        }
    }

    /// Composites the editor's overlay and transcodes, in one hardware pass on
    /// the platform's own encoder. Flutter is not involved, so this also works
    /// from a background task.
    async fn render_video(&self, media: &MediaRow, original: &Path, temp: &Path) -> Result<()> {
        let files = MediaFileService::new(&self.ctx);
        let overlay = files.overlay_image_path(&media.media_id);
        // The editor writes an overlay for every video, including one nobody
        // drew on. Compositing a fully transparent layer produces the same
        // frames, and recognising that is what lets a pre-rendered clip be sent
        // without touching an encoder. A file that cannot be read is treated as
        // meaningful, so an unreadable overlay never silently drops artwork.
        let overlay = if overlay.exists() {
            let path = overlay.clone();
            let visible = blocking(move || media_codec::has_visible_content(&path))
                .await
                .unwrap_or_else(|error| {
                    tracing::warn!(media_id = media.media_id, %error, "could not inspect the overlay");
                    true
                });
            visible.then_some(overlay)
        } else {
            None
        };

        let remove_audio = media.remove_audio.unwrap_or(0) != 0;
        if overlay.is_none() && files.prerender_matches(&media.media_id, &render_fingerprint(media))
        {
            // The clip the editor was opened on is the clip that gets sent.
            MediaFileService::ensure_parent(temp)?;
            match std::fs::rename(files.prerendered_path(&media.media_id), temp) {
                Ok(()) => {
                    tracing::info!(media_id = media.media_id, "sending the pre-rendered video");
                    files.discard_prerender(&media.media_id);
                    return Ok(());
                }
                Err(error) => {
                    tracing::warn!(media_id = media.media_id, %error, "could not use the pre-rendered video");
                }
            }
        }
        files.discard_prerender(&media.media_id);

        // Every clip is rendered, including small ones with no overlay. What a
        // camera produces varies by device and is not guaranteed to play on the
        // other platform; the render is what makes the output predictable.
        let (trim_start_ms, trim_end_ms) = trim_bounds(media);
        let request = video::RenderRequest {
            media_id: media.media_id.clone(),
            input: original.to_path_buf(),
            overlay,
            output: temp.to_path_buf(),
            remove_audio,
            trim_start_ms,
            trim_end_ms,
        };
        let media_id = media.media_id.clone();
        if let Err(error) = blocking(move || video::render(&request)).await {
            // Last resort: the camera file is the only remaining way to deliver
            // the moment, but it carries no overlay and the recipient's platform
            // may not decode it, so this is worth seeing in the logs.
            tracing::error!(media_id, %error, "sending the unrendered camera file");
            MediaFileService::ensure_parent(temp)?;
            std::fs::copy(original, temp)?;
        }
        Ok(())
    }

    /// Renders the preview shown in chat lists and the gallery.    /// Renders the preview shown in chat lists and the gallery.
    async fn create_thumbnail(&self, media: &MediaRow) -> Result<()> {
        let files = MediaFileService::new(&self.ctx);
        let stored = files.stored_path(&media.media_id, &media.media_type);
        let thumbnail = files.thumbnail_path(&media.media_id);
        if media.media_type == "audio" || !stored.exists() {
            return Ok(());
        }
        let media_id = media.media_id.clone();
        let is_video = media.media_type == "video";
        if let Err(error) = blocking(move || {
            if is_video {
                // Only the frame grab needs the platform's video decoder; the
                // scaling and encoding is the same code stills use.
                let frame = thumbnail.with_extension("frame.png");
                video::extract_frame(&stored, &frame)?;
                let result = media_codec::create_image_thumbnail(&frame, &thumbnail);
                let _ = std::fs::remove_file(&frame);
                result
            } else {
                media_codec::create_image_thumbnail(&stored, &thumbnail)
            }
        })
        .await
        {
            tracing::warn!(media_id, %error, "could not create a thumbnail");
        }
        Ok(())
    }

    /// Exports a stored media file to the user's photo library, stamping the
    /// capture time into the file so it survives being copied elsewhere.
    pub async fn save_to_gallery(&self, media_id: &str) -> Result<()> {
        let Some(media) = self.load(media_id).await? else {
            return Ok(());
        };
        let files = MediaFileService::new(&self.ctx);
        let stored = files.stored_path(media_id, &media.media_type);
        if !stored.exists() {
            return Err(TwonlyError::Generic(format!(
                "media {media_id} has no stored file to export"
            )));
        }
        let created_at_millis = media.created_at.saturating_mul(1_000);
        let is_video = media.media_type == "video";
        let media_id = media_id.to_owned();
        blocking(move || {
            // Video containers carry their own metadata, and the photo library
            // is told the capture time either way; only stills are rewritten.
            let exported = if is_video {
                stored.clone()
            } else {
                let metadata = media_exif::ExifMetadata {
                    created_at: chrono::DateTime::from_timestamp_millis(created_at_millis),
                };
                let bytes = std::fs::read(&stored)?;
                match media_exif::with_exif(&bytes, &metadata) {
                    Ok(stamped) => {
                        let path = stored.with_extension("export.webp");
                        std::fs::write(&path, stamped)?;
                        path
                    }
                    Err(error) => {
                        tracing::warn!(%error, "exporting without EXIF metadata");
                        stored.clone()
                    }
                }
            };
            let result = gallery::save(&exported, is_video, &media_id, created_at_millis);
            if exported != stored {
                let _ = std::fs::remove_file(&exported);
            }
            result
        })
        .await
    }

    /// Trims fully transparent borders the editor left around a stored image.
    pub async fn crop_transparent_borders(&self, media_id: &str) -> Result<()> {
        let Some(media) = self.load(media_id).await? else {
            return Ok(());
        };
        let files = MediaFileService::new(&self.ctx);
        let stored = files.stored_path(media_id, &media.media_type);
        if media.media_type == "image" && stored.exists() {
            match blocking(move || media_codec::crop_transparent_borders(&stored)).await {
                Ok(true) => {
                    // The pixels changed, so the preview and the content hash
                    // derived from them are stale.
                    remove_file(&files.thumbnail_path(media_id));
                    self.create_thumbnail(&media).await?;
                }
                Ok(false) => {}
                Err(error) => {
                    tracing::warn!(media_id, %error, "could not crop transparent borders");
                }
            }
        }
        self.media_step_finished(media_id, "crop").await
    }
}

/// Everything the video transcode reads off the media row.
///
/// A clip pre-rendered while the user was still editing may only be sent when
/// the editor's final state asks for exactly the same render, so this is the
/// one description both sides compare. **Any new input the render starts to
/// honour — a trim, a speed change, a filter — has to be added here in the same
/// change, or a pre-rendered clip will be sent ignoring it.**
fn render_fingerprint(media: &MediaRow) -> String {
    // A plain string rather than a struct: it is only ever compared, never
    // read back, and a stable textual form makes a stale marker obvious in a
    // temp directory listing.
    let (start, end) = trim_bounds(media);
    format!(
        "v2;remove_audio={};trim={}..{}",
        media.remove_audio.unwrap_or(0) != 0,
        start.map_or_else(|| "-".to_owned(), |value| value.to_string()),
        end.map_or_else(|| "-".to_owned(), |value| value.to_string()),
    )
}

/// The cut the editor asked for, as milliseconds into the recording.
///
/// A bound is dropped when it cannot describe a cut: a negative offset, or an
/// end at or before the start. The renderers are handed the raw numbers, so a
/// nonsensical pair here would produce an empty clip rather than a whole one.
fn trim_bounds(media: &MediaRow) -> (Option<i64>, Option<i64>) {
    let start = media.trim_start_ms.filter(|value| *value > 0);
    let end = media
        .trim_end_ms
        .filter(|value| *value > start.unwrap_or(0));
    (start, end)
}

/// Image codecs are CPU-bound: a full-resolution photo takes long enough to
/// encode that it must not run on an async worker.
async fn blocking<F, T>(task: F) -> Result<T>
where
    F: FnOnce() -> Result<T> + Send + 'static,
    T: Send + 'static,
{
    tokio::task::spawn_blocking(task)
        .await
        .map_err(|error| TwonlyError::Generic(error.to_string()))?
}

fn remove_file(path: &Path) {
    match std::fs::remove_file(path) {
        Ok(()) => {}
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
        Err(error) => tracing::warn!(path = %path.display(), %error, "could not remove file"),
    }
}

fn file_size_or_zero(path: &Path) -> u64 {
    std::fs::metadata(path)
        .map(|metadata| metadata.len())
        .unwrap_or(0)
}

/// Drift persists this column as a JSON array of contact ids. Tolerate the
/// single-scalar form that an earlier Rust write produced.
fn parse_reupload_requested_by(value: Option<&str>) -> Vec<i64> {
    let Some(value) = value else {
        return Vec::new();
    };
    if let Ok(ids) = serde_json::from_str::<Vec<i64>>(value) {
        return ids;
    }
    value.parse::<i64>().map(|id| vec![id]).unwrap_or_default()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_both_reupload_requested_by_encodings() {
        assert!(parse_reupload_requested_by(None).is_empty());
        assert_eq!(parse_reupload_requested_by(Some("[3,7]")), vec![3, 7]);
        assert_eq!(parse_reupload_requested_by(Some("5")), vec![5]);
        assert!(parse_reupload_requested_by(Some("nonsense")).is_empty());
    }

    /// The gallery asks for a preview through this call and shows a blurhash
    /// until the file appears. When it only recorded that the file was still
    /// missing, every tile without a preview asked again forever.
    #[tokio::test]
    async fn a_missing_thumbnail_is_rendered_rather_than_only_recorded() -> anyhow::Result<()> {
        let temp = tempfile::tempdir()?;
        let data_dir = temp.path().join("data");
        std::fs::create_dir_all(data_dir.join("keyvalue"))?;
        std::fs::write(
            data_dir.join("keyvalue/user.json"),
            serde_json::to_vec(&UserConfig::default())?,
        )?;
        let ctx = Context::init_for_testing(temp.path().join("database"), data_dir).await?;

        let media_id = "media-thumbnail";
        let database = ctx.app_db.read().await.clone();
        sqlx::query("INSERT INTO media_files(media_id, type, stored) VALUES (?, 'image', 1)")
            .bind(media_id)
            .execute(&database.pool)
            .await?;
        drop(database);

        let files = MediaFileService::new(&ctx);
        let stored = files.stored_path(media_id, "image");
        MediaFileService::ensure_parent(&stored)?;
        image::DynamicImage::ImageRgb8(image::RgbImage::new(900, 1600)).save(&stored)?;

        let service = MediaUploadService::new(&ctx);
        service.media_step_finished(media_id, "thumbnail").await?;

        assert!(files.thumbnail_path(media_id).exists());
        let database = ctx.app_db.read().await.clone();
        let has_thumbnail: i64 =
            sqlx::query_scalar("SELECT has_thumbnail FROM media_files WHERE media_id = ?")
                .bind(media_id)
                .fetch_one(&database.pool)
                .await?;
        assert_eq!(has_thumbnail, 1);
        Ok(())
    }

    #[test]
    fn media_lock_is_shared_per_media_id() {
        let first = media_lock("media-a");
        let second = media_lock("media-a");
        let other = media_lock("media-b");
        assert!(Arc::ptr_eq(&first, &second));
        assert!(!Arc::ptr_eq(&first, &other));
    }
}
