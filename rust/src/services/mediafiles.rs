/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::messages::outgoing::send_c2c_message_to_contact;
use crate::api::proto::client::{encrypted_content, EncryptedContent};
use crate::api::runtime::API_EVENTS;
use crate::bridge::api::{ApiEvent, ApiEventKind, RustApi};
use crate::context::Context;
use crate::error::{Result, TwonlyError};
use crate::services::media_upload::MediaUploadService;
use chacha20poly1305::aead::{AeadInOut, KeyInit};
use chacha20poly1305::{ChaCha20Poly1305, Nonce, Tag};
use prost::Message as _;
use sha2::{Digest, Sha256};
use sqlx::{Sqlite, Transaction};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::{Arc, LazyLock, Mutex as StdMutex};
use std::time::Duration;
use tokio::sync::Mutex;

static DOWNLOAD_LOCKS: LazyLock<StdMutex<HashMap<String, Arc<Mutex<()>>>>> =
    LazyLock::new(|| StdMutex::new(HashMap::new()));

/// One media file is only ever downloaded by one task. Two of them share the
/// ciphertext and plaintext paths, so a second concurrent run reads what the
/// first is still writing and fails the authentication tag on whole bytes.

fn download_lock(media_id: &str) -> Arc<Mutex<()>> {
    let mut locks = DOWNLOAD_LOCKS
        .lock()
        .unwrap_or_else(|error| error.into_inner());

    locks.entry(media_id.to_owned()).or_default().clone()
}

fn download_url(token: &[u8]) -> String {
    format!(
        "{}download/{}",
        RustApi::api_base_url("https".into()),
        hex::encode(token)
    )
}

/// What the server says about a download token without transferring its
/// object.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]

pub(crate) enum DownloadAvailability {
    Available,
    /// The server does not know the token, or its object is gone, so the
    /// download can only end in a reupload request.
    Gone,
    /// No answer either way: a network failure, a storage outage, or a server
    /// that predates the check and refuses the method.
    Unknown,
}

impl DownloadAvailability {
    fn from_status(status: reqwest::StatusCode) -> Self {
        match status.as_u16() {
            200..=299 => Self::Available,
            403 | 410 => Self::Gone,
            _ => Self::Unknown,
        }
    }
}

struct DownloadMedia {
    media_id: String,
    media_type: String,
    download_token: Option<Vec<u8>>,
    encryption_key: Option<Vec<u8>>,
    encryption_mac: Option<Vec<u8>>,
    encryption_nonce: Option<Vec<u8>>,
}

struct ReuploadTarget {
    message_id: String,
    sender_id: i64,
}

/// Filesystem and download operations for media files. Upload preparation and
/// platform-specific media processing intentionally remain in Flutter.

pub struct MediaFileService {
    ctx: Arc<Context>,
}

impl MediaFileService {
    pub fn new(ctx: &Arc<Context>) -> Self {
        Self { ctx: ctx.clone() }
    }

    /// A terminated process leaves its transfer claimed, so `downloading` is
    /// picked up here as well. The reset happens per media file under its
    /// download lock rather than as one table-wide sweep: a sweep also
    /// un-claims the transfers that are still running, and the second
    /// downloader it lets in then races the first over the same files.

    pub async fn download_pending(&self) -> Result<()> {
        let database = self.ctx.app_db.read().await.clone();

        // The background wake-up runs this on a budget of a few seconds, so the
        // order decides what actually gets through: widget media is the whole
        // reason that wake-up happened, and newer media is what the user is
        // about to look at.
        let media_ids = sqlx::query_scalar!(
            r#"SELECT media_id FROM media_files
               WHERE download_state IN ('pending', 'downloading')
               ORDER BY is_widget_media DESC, created_at DESC"#
        )
        .fetch_all(&database.pool)
        .await?;

        drop(database);

        for media_id in media_ids {
            if let Err(error) = self.download(&media_id).await {
                tracing::warn!(media_id, %error, "media download failed");
            }
        }

        Ok(())
    }

    pub async fn download(&self, media_id: &str) -> Result<()> {
        self.download_with(media_id, || self.download_claimed(media_id))
            .await
    }

    async fn download_with<F, Fut>(&self, media_id: &str, transfer: F) -> Result<()>
    where
        F: FnOnce() -> Fut,
        Fut: std::future::Future<Output = Result<()>>,
    {
        let lock = download_lock(media_id);

        let _guard = lock.lock().await;

        let database = self.ctx.app_db.read().await.clone();

        // Nothing in this process holds the transfer any more, so a claim left
        // over from a process the OS reclaimed mid-download is recoverable.
        sqlx::query!(
            r#"UPDATE media_files SET download_state = 'pending'
               WHERE media_id = ? AND download_state = 'downloading'"#,
            media_id,
        )
        .execute(&database.pool)
        .await?;

        let claimed = sqlx::query!(
            r#"UPDATE media_files SET download_state = 'downloading'
               WHERE media_id = ? AND download_state = 'pending'"#,
            media_id,
        )
        .execute(&database.pool)
        .await?
        .rows_affected();

        if claimed == 0 {
            return Ok(());
        }

        let result = transfer().await;

        if result.is_err() {
            sqlx::query!(
                r#"UPDATE media_files SET download_state = 'pending'
                   WHERE media_id = ? AND download_state = 'downloading'"#,
                media_id,
            )
            .execute(&database.pool)
            .await?;
        }

        match result {
            Err(TwonlyError::MediaDownloadUnavailable(error)) => {
                tracing::warn!(media_id, %error, "media download deferred until a retry");
                Ok(())
            }
            result => result,
        }
    }

    /// Asks the server, with an `OPTIONS` request, whether a download token
    /// still leads to an object. Cheap enough for the notification path, which
    /// must not download whole files before it shows anything.

    pub(crate) async fn download_availability(token: &[u8]) -> DownloadAvailability {
        let Ok(client) = crate::api::http::client_builder().build() else {
            return DownloadAvailability::Unknown;
        };

        match client
            .request(reqwest::Method::OPTIONS, download_url(token))
            .timeout(Duration::from_secs(3))
            .send()
            .await
        {
            Ok(response) => DownloadAvailability::from_status(response.status()),
            Err(_) => DownloadAvailability::Unknown,
        }
    }

    /// Incoming media is inserted inside a transaction owned by the message
    /// handler. Wait until that transaction becomes visible before claiming it.

    pub async fn download_when_available(&self, media_id: &str) -> Result<()> {
        crate::performance::measure("media.download", "http.client", async {
            for _ in 0..40 {
                let database = self.ctx.app_db.read().await.clone();

                let state = sqlx::query_scalar!(
                    "SELECT download_state FROM media_files WHERE media_id = ?",
                    media_id,
                )
                .fetch_optional(&database.pool)
                .await?
                .flatten();

                match state.as_deref() {
                    Some("pending") => return self.download(media_id).await,
                    Some(_) => return Ok(()),
                    None => tokio::time::sleep(Duration::from_millis(50)).await,
                }
            }

            Err(TwonlyError::Generic(format!(
                "media {media_id} was not committed in time"
            )))
        })
        .await
    }

    async fn download_claimed(&self, media_id: &str) -> Result<()> {
        let database = self.ctx.app_db.read().await.clone();

        let messages = sqlx::query!(
            r#"SELECT m.message_id, m.sender_id, c.account_deleted
               FROM messages m
               LEFT JOIN contacts c ON c.user_id = m.sender_id
               WHERE m.media_id = ?"#,
            media_id,
        )
        .fetch_all(&database.pool)
        .await?;

        if messages.is_empty() {
            let media_type =
                sqlx::query_scalar!("SELECT type FROM media_files WHERE media_id = ?", media_id,)
                    .fetch_optional(&database.pool)
                    .await?;

            sqlx::query!("DELETE FROM media_files WHERE media_id = ?", media_id)
                .execute(&database.pool)
                .await?;

            if let Some(media_type) = media_type {
                self.remove_files(media_id, &media_type)?;
            }

            return Ok(());
        }

        if messages.len() != 1 {
            return Err(TwonlyError::Generic(format!(
                "media {media_id} has {} original messages",
                messages.len()
            )));
        }

        let message = &messages[0];

        if message.sender_id.is_none() {
            return Err(TwonlyError::Generic(format!(
                "media {media_id} has no sender"
            )));
        }

        if message.account_deleted.unwrap_or(1) != 0 {
            let media_type =
                sqlx::query_scalar!("SELECT type FROM media_files WHERE media_id = ?", media_id,)
                    .fetch_optional(&database.pool)
                    .await?;

            sqlx::query!("DELETE FROM media_files WHERE media_id = ?", media_id)
                .execute(&database.pool)
                .await?;

            sqlx::query!(
                "DELETE FROM messages WHERE message_id = ?",
                message.message_id
            )
            .execute(&database.pool)
            .await?;

            if let Some(media_type) = media_type {
                self.remove_files(media_id, &media_type)?;
            }

            return Ok(());
        }

        let media = sqlx::query_as!(
            DownloadMedia,
            r#"SELECT media_id, type AS media_type, download_token,
                      encryption_key, encryption_mac, encryption_nonce
               FROM media_files WHERE media_id = ?"#,
            media_id,
        )
        .fetch_optional(&database.pool)
        .await?
        .ok_or_else(|| TwonlyError::Generic(format!("media {media_id} not found")))?;

        let encrypted_path = self.encrypted_path(&media.media_id, &media.media_type);

        if !encrypted_path.exists() && !self.fetch_encrypted(&media, &encrypted_path).await? {
            return Ok(());
        }

        if let Err(error) = self.decrypt(&media, &encrypted_path).await {
            // The ciphertext on disk cannot be authenticated. Dropping it and
            // fetching it again is what separates a transfer that was cut short
            // from a key that genuinely does not match: without this, one
            // truncated download poisons every later attempt at the same file.
            tracing::warn!(media_id, %error, "media decryption failed; downloading it again");

            let _ = std::fs::remove_file(&encrypted_path);

            if !self.fetch_encrypted(&media, &encrypted_path).await? {
                return Ok(());
            }

            if let Err(error) = self.decrypt(&media, &encrypted_path).await {
                tracing::warn!(media_id, %error, "media decryption failed; requesting reupload");

                let _ = std::fs::remove_file(&encrypted_path);

                self.request_reupload(media_id).await?;

                return Ok(());
            }
        }

        if let Err(error) = MediaUploadService::new(&self.ctx)
            .create_story_thumbnail(media_id)
            .await
        {
            tracing::warn!(media_id, %error, "could not create the story thumbnail");
        }

        let is_widget = sqlx::query_scalar::<_, i64>(
            "SELECT is_widget_media FROM media_files WHERE media_id = ?",
        )
        .bind(media_id)
        .fetch_optional(&database.pool)
        .await?
        .unwrap_or(0)
            != 0;

        if is_widget {
            crate::services::home_widget::refresh_manifest(&self.ctx).await?;

            // Rewriting the manifest changes nothing on the home screen by
            // itself: both platforms keep drawing what they built earlier. The
            // widgets are native, so only Flutter can ask them to redraw, and
            // the notification worker refreshes them on its own path.
            let _ = API_EVENTS.send(ApiEvent {
                kind: ApiEventKind::WidgetMediaReceived,
                state: None,
                message: None,
            });
        }

        Ok(())
    }

    /// Fetches the ciphertext and puts it in place as one step.
    ///
    /// The bytes land under a partial name and are renamed once the whole body
    /// is on disk, because the presence of `encrypted_path` is what every later
    /// attempt reads as "already downloaded". A process the OS reclaims
    /// mid-transfer must therefore leave nothing behind under that name.
    ///
    /// Returns `false` when the object is gone from the server and a reupload
    /// has been requested instead.

    async fn fetch_encrypted(&self, media: &DownloadMedia, encrypted_path: &Path) -> Result<bool> {
        let media_id = &media.media_id;

        let token = media
            .download_token
            .as_deref()
            .ok_or_else(|| TwonlyError::Generic("media has no download token".into()))?;

        let response = crate::api::http::client_builder()
            .build()
            .map_err(|error| TwonlyError::Generic(error.to_string()))?
            .get(download_url(token))
            .timeout(Duration::from_secs(30))
            .send()
            .await
            // reqwest includes the URL in Display, including the secret token.
            .map_err(|error| {
                TwonlyError::MediaDownloadUnavailable(error.without_url().to_string())
            })?;

        let status = response.status();

        if status == reqwest::StatusCode::NOT_FOUND || status == reqwest::StatusCode::FORBIDDEN {
            // 403 is a token the server does not know, 404 an object that is
            // gone. Which one it was is the first question about a reupload.
            tracing::warn!(
                media_id,
                status = status.as_u16(),
                "media download was refused; requesting a reupload"
            );

            self.request_reupload(media_id).await?;

            return Ok(false);
        }

        if !status.is_success() {
            let reason = format!("media download returned HTTP {status}");
            return Err(
                if status.is_server_error() || status == reqwest::StatusCode::TOO_MANY_REQUESTS {
                    TwonlyError::MediaDownloadUnavailable(reason)
                } else {
                    TwonlyError::Generic(reason)
                },
            );
        }

        let bytes = response.bytes().await.map_err(|error| {
            TwonlyError::MediaDownloadUnavailable(error.without_url().to_string())
        })?;

        let partial_path = self.partial_download_path(media_id, &media.media_type);

        Self::ensure_parent(&partial_path)?;

        std::fs::write(&partial_path, bytes)?;

        std::fs::rename(&partial_path, encrypted_path)?;

        Ok(true)
    }

    async fn decrypt(&self, media: &DownloadMedia, encrypted_path: &Path) -> Result<()> {
        let key = media.encryption_key.as_deref().ok_or_else(|| {
            TwonlyError::Generic(format!("media {} has no encryption key", media.media_id))
        })?;

        let nonce = media.encryption_nonce.as_deref().ok_or_else(|| {
            TwonlyError::Generic(format!("media {} has no encryption nonce", media.media_id))
        })?;

        let mac = media.encryption_mac.as_deref().ok_or_else(|| {
            TwonlyError::Generic(format!("media {} has no encryption MAC", media.media_id))
        })?;

        let cipher = ChaCha20Poly1305::new_from_slice(key)?;

        if nonce.len() != 12 {
            return Err(TwonlyError::Generic(
                "invalid media encryption nonce".into(),
            ));
        }

        if mac.len() != 16 {
            return Err(TwonlyError::Generic("invalid media encryption MAC".into()));
        }

        let nonce = Nonce::try_from(nonce).expect("nonce length was checked");

        let tag = Tag::try_from(mac).expect("tag length was checked");

        let mut bytes = std::fs::read(encrypted_path)?;

        cipher.decrypt_inout_detached(&nonce, b"", bytes.as_mut_slice().into(), &tag)?;

        let temp_path = self.temp_path(&media.media_id, &media.media_type);

        Self::ensure_parent(&temp_path)?;

        std::fs::write(&temp_path, &bytes)?;

        let hash = Sha256::digest(&bytes).to_vec();

        let size = bytes.len() as i64;

        // Keep the file update and state transition ordered: ready is only
        // visible after the plaintext has been written successfully.
        let database = self.ctx.app_db.read().await.clone();

        sqlx::query!(
            r#"UPDATE media_files SET download_state = 'ready', stored_file_hash = ?,
                      size_in_bytes = ?
               WHERE media_id = ?"#,
            hash,
            size,
            media.media_id,
        )
        .execute(&database.pool)
        .await?;

        std::fs::remove_file(encrypted_path)?;

        Ok(())
    }

    pub async fn request_reupload(&self, media_id: &str) -> Result<()> {
        let database = self.ctx.app_db.read().await.clone();

        // Widget media is marked opened the moment it arrives, since nobody
        // ever opens it in a chat. Asking only for what has not been opened
        // would therefore never ask for it at all, and the state set below
        // hides the message for good. A story replays after it was opened, so
        // the same holds for it.
        let targets = sqlx::query_as!(
            ReuploadTarget,
            r#"SELECT message_id, sender_id AS "sender_id!: i64" FROM messages
               WHERE media_id = ? AND sender_id IS NOT NULL
                 AND (opened_at IS NULL OR is_widget_media = 1 OR is_story = 1)"#,
            media_id,
        )
        .fetch_all(&database.pool)
        .await?;

        // A concurrent attempt that already produced the plaintext outranks
        // this one; overwriting `ready` would hide a message that is fine.
        sqlx::query!(
            r#"UPDATE media_files SET download_state = 'reuploadRequested'
               WHERE media_id = ? AND download_state IS NOT 'ready'"#,
            media_id,
        )
        .execute(&database.pool)
        .await?;

        drop(database);

        for target in targets {
            let content = EncryptedContent {
                media_update: Some(encrypted_content::MediaUpdate {
                    r#type: encrypted_content::media_update::Type::DecryptionError.into(),
                    target_message_id: target.message_id,
                }),
                ..Default::default()
            };

            send_c2c_message_to_contact()
                .ctx(&self.ctx)
                .contact_id(target.sender_id)
                .encrypted_content(content.encode_to_vec())
                .call()
                .await?;
        }

        Ok(())
    }

    pub async fn retry_pending_reuploads(&self) -> Result<()> {
        let database = self.ctx.app_db.read().await.clone();

        let media_ids = sqlx::query_scalar!(
            "SELECT media_id FROM media_files WHERE download_state = 'reuploadRequested'"
        )
        .fetch_all(&database.pool)
        .await?;

        drop(database);

        for media_id in media_ids {
            self.request_reupload(&media_id).await?;
        }

        Ok(())
    }

    pub fn remove_files(&self, media_id: &str, media_type: &str) -> Result<()> {
        for path in self.paths(media_id, media_type) {
            match std::fs::remove_file(path) {
                Ok(()) => {}
                Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
                Err(error) => return Err(error.into()),
            }
        }

        Ok(())
    }

    pub async fn remove_files_if_deleted(
        &self, t: &mut Transaction<'_, Sqlite>, media_id: &str, media_type: &str,
    ) -> Result<()> {
        let still_exists = sqlx::query_scalar!(
            "SELECT EXISTS(SELECT 1 FROM media_files WHERE media_id = ?)",
            media_id,
        )
        .fetch_one(&mut **t)
        .await?
            != 0;

        if !still_exists {
            self.remove_files(media_id, media_type)?;
        }

        Ok(())
    }

    fn paths(&self, media_id: &str, media_type: &str) -> Vec<PathBuf> {
        let extension = Self::extension(media_type);

        let base = PathBuf::from(&self.ctx.config.data_dir).join("mediafiles");

        vec![
            base.join("tmp").join(format!("{media_id}.{extension}")),
            base.join("tmp")
                .join(format!("{media_id}.encrypted.{extension}")),
            base.join("tmp")
                .join(format!("{media_id}.download.{extension}")),
            base.join("tmp")
                .join(format!("{media_id}.original.{extension}")),
            base.join("tmp")
                .join(format!("{media_id}.upload.{extension}")),
            base.join("tmp")
                .join(format!("{media_id}.ffmpeg.{extension}")),
            base.join("tmp").join(format!("{media_id}.overlay.png")),
            base.join("tmp").join(format!("{media_id}.prerendered.mp4")),
            base.join("tmp")
                .join(format!("{media_id}.prerendered.json")),
            base.join("stored").join(format!("{media_id}.{extension}")),
            base.join("stored")
                .join(format!("{media_id}.thumbnail.webp")),
        ]
    }

    /// Media lives under one directory per lifecycle stage. Both Rust and the
    /// Flutter view layer derive these names from the media id, so they must
    /// stay in sync with `MediaFileService` on the Dart side.

    fn media_path(
        &self, directory: &str, media_id: &str, suffix: &str, extension: &str,
    ) -> PathBuf {
        PathBuf::from(&self.ctx.config.data_dir)
            .join("mediafiles")
            .join(directory)
            .join(format!("{media_id}{suffix}.{extension}"))
    }

    pub(crate) fn stored_path(&self, media_id: &str, media_type: &str) -> PathBuf {
        self.media_path("stored", media_id, "", Self::extension(media_type))
    }

    pub(crate) fn thumbnail_path(&self, media_id: &str) -> PathBuf {
        self.media_path("stored", media_id, ".thumbnail", "webp")
    }

    pub(crate) fn original_path(&self, media_id: &str, media_type: &str) -> PathBuf {
        self.media_path("tmp", media_id, ".original", Self::extension(media_type))
    }

    pub(crate) fn overlay_image_path(&self, media_id: &str) -> PathBuf {
        self.media_path("tmp", media_id, ".overlay", "png")
    }

    pub(crate) fn upload_request_path(&self, media_id: &str, media_type: &str) -> PathBuf {
        self.media_path("tmp", media_id, ".upload", Self::extension(media_type))
    }

    /// The transcode produced before the user picked recipients. It is only a
    /// candidate: `prerender_matches` decides whether the editor's final
    /// settings are still the ones it was produced with.

    pub(crate) fn prerendered_path(&self, media_id: &str) -> PathBuf {
        self.media_path("tmp", media_id, ".prerendered", "mp4")
    }

    fn prerender_marker_path(&self, media_id: &str) -> PathBuf {
        self.media_path("tmp", media_id, ".prerendered", "json")
    }

    /// Records the render inputs the pre-rendered clip was produced with.
    /// Written only after the render finished, so a marker on disk also proves
    /// the clip is whole.

    pub(crate) fn write_prerender_marker(&self, media_id: &str, fingerprint: &str) -> Result<()> {
        let marker = self.prerender_marker_path(media_id);

        Self::ensure_parent(&marker)?;

        std::fs::write(&marker, fingerprint.as_bytes())?;

        Ok(())
    }

    /// Whether the pre-rendered clip can be sent as it stands, which is true
    /// only while the editor still asks for exactly what it was produced with.

    pub(crate) fn prerender_matches(&self, media_id: &str, fingerprint: &str) -> bool {
        if !self.prerendered_path(media_id).exists() {
            return false;
        }

        std::fs::read_to_string(self.prerender_marker_path(media_id))
            .is_ok_and(|marker| marker == fingerprint)
    }

    pub(crate) fn discard_prerender(&self, media_id: &str) {
        let _ = std::fs::remove_file(self.prerendered_path(media_id));

        let _ = std::fs::remove_file(self.prerender_marker_path(media_id));
    }

    pub(crate) fn temp_path(&self, media_id: &str, media_type: &str) -> PathBuf {
        PathBuf::from(&self.ctx.config.data_dir)
            .join("mediafiles/tmp")
            .join(format!("{media_id}.{}", Self::extension(media_type)))
    }

    pub(crate) fn encrypted_path(&self, media_id: &str, media_type: &str) -> PathBuf {
        PathBuf::from(&self.ctx.config.data_dir)
            .join("mediafiles/tmp")
            .join(format!(
                "{media_id}.encrypted.{}",
                Self::extension(media_type)
            ))
    }

    /// Where an in-flight download accumulates before it is renamed onto
    /// [`Self::encrypted_path`].

    fn partial_download_path(&self, media_id: &str, media_type: &str) -> PathBuf {
        PathBuf::from(&self.ctx.config.data_dir)
            .join("mediafiles/tmp")
            .join(format!(
                "{media_id}.download.{}",
                Self::extension(media_type)
            ))
    }

    pub(crate) fn extension(media_type: &str) -> &'static str {
        match media_type {
            "video" => "mp4",
            "gif" => "gif",
            "audio" => "m4a",
            _ => "webp",
        }
    }

    pub(crate) fn ensure_parent(path: &Path) -> Result<()> {
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)?;
        }

        Ok(())
    }
}

/// Retry committed removals without deleting files for rolled-back commands.

pub(crate) async fn cleanup_pending_file_removals(ctx: &Arc<Context>) -> Result<()> {
    let database = ctx.app_db.read().await.clone();

    let service = MediaFileService::new(ctx);

    crate::database::app::messages::writes::drain_file_removals(&database, |id, kind| {
        service.remove_files(id, kind)
    })
    .await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn a_transport_failure_keeps_the_download_pending_and_a_later_retry_completes(
    ) -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        let database = ctx.app_db.read().await.clone();
        sqlx::query(
            "INSERT INTO media_files(media_id, type, download_state) VALUES ('retry', 'image', \
             'pending')",
        )
        .execute(&database.pool)
        .await?;
        let service = MediaFileService::new(&ctx);

        service
            .download_with("retry", || async {
                Err(TwonlyError::MediaDownloadUnavailable(
                    "connection reset by peer".into(),
                ))
            })
            .await?;
        let state: String =
            sqlx::query_scalar("SELECT download_state FROM media_files WHERE media_id = 'retry'")
                .fetch_one(&database.pool)
                .await?;
        assert_eq!(state, "pending");

        service
            .download_with("retry", || async {
                sqlx::query(
                    "UPDATE media_files SET download_state = 'ready' WHERE media_id = 'retry'",
                )
                .execute(&database.pool)
                .await?;
                Ok(())
            })
            .await?;
        let state: String =
            sqlx::query_scalar("SELECT download_state FROM media_files WHERE media_id = 'retry'")
                .fetch_one(&database.pool)
                .await?;
        assert_eq!(state, "ready");
        service
            .download_with("retry", || async {
                panic!("a ready download must not be transferred twice")
            })
            .await?;
        Ok(())
    }

    #[tokio::test]
    async fn a_non_transport_failure_remains_an_error_and_does_not_strand_the_claim() -> Result<()>
    {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        let database = ctx.app_db.read().await.clone();
        sqlx::query(
            "INSERT INTO media_files(media_id, type, download_state) VALUES ('broken', 'image', \
             'pending')",
        )
        .execute(&database.pool)
        .await?;
        let error = MediaFileService::new(&ctx)
            .download_with("broken", || async {
                Err(TwonlyError::Generic(
                    "invalid media encryption nonce".into(),
                ))
            })
            .await
            .unwrap_err();
        assert!(matches!(error, TwonlyError::Generic(_)));
        let state: String =
            sqlx::query_scalar("SELECT download_state FROM media_files WHERE media_id = 'broken'")
                .fetch_one(&database.pool)
                .await?;
        assert_eq!(state, "pending");
        Ok(())
    }
}
