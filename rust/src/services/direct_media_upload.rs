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
use crate::services::media_upload::{media_lock, parse_reupload_requested_by, MediaReuploadTarget};
use crate::services::stories::{STORY_ANNOUNCE_RECENT_EXCHANGE_SECONDS, STORY_LIFETIME_SECONDS};
use chacha20poly1305::aead::{AeadInPlace, KeyInit};
use chacha20poly1305::{ChaCha20Poly1305, Nonce};
use futures_util::{stream, StreamExt};
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
use tokio::sync::Notify;
use tokio::time::Instant;

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
const WATCH_FIRST_DELAY: Duration = Duration::from_secs(1);
const WATCH_FAST_PERIOD: Duration = Duration::from_secs(15);
/// The server accepts at most this many recipients for one uploaded attachment.
pub(crate) const MAX_ATTACHMENT_DISPATCHES: usize = 300;
const WATCH_MAX_DELAY: Duration = Duration::from_secs(120);
const NATIVE_RECOVERY_INTERVAL_SECONDS: i64 = 60;
const STATUS_CONCURRENCY: usize = 4;

static UPLOAD_WATCH: UploadWatch = UploadWatch::new();
static API_NAMESPACE_LOCK: tokio::sync::Mutex<()> = tokio::sync::Mutex::const_new(());
/// One slot request at a time.
///
/// The server reads the known-slot list of a request as the whole truth for the
/// account and abandons every reserved slot missing from it. Two requests in
/// flight at once therefore destroy each other's slots: the second was prepared
/// before the first's answer was stored, so it asks the server to give up
/// exactly the slots the first had just been handed. The client then holds a
/// cache of slots that are already dead, and every send that reserves one of
/// them fails.
static PRELOAD_LOCK: tokio::sync::Mutex<()> = tokio::sync::Mutex::const_new(());

/// Coalesces requests into one watcher. The notification interrupts its sleep;
/// the generation also catches requests racing with the watcher's last pass.
struct UploadWatch {
    watching: AtomicBool,
    requests: AtomicU64,
    wake: Notify,
}

impl UploadWatch {
    const fn new() -> Self {
        Self {
            watching: AtomicBool::new(false),
            requests: AtomicU64::new(0),
            wake: Notify::const_new(),
        }
    }

    fn request(&self) -> u64 {
        let generation = self.requests.fetch_add(1, Ordering::SeqCst) + 1;
        // notify_one retains a permit if the watcher is reconciling or has not
        // started waiting yet. A generation counter alone cannot wake a sleep.
        self.wake.notify_one();
        generation
    }

    async fn wait(&self, delay: Duration) -> bool {
        tokio::select! {
            _ = self.wake.notified() => true,
            _ = tokio::time::sleep(delay) => false,
        }
    }
}

struct WatchCadence {
    fast_until: Instant,
    delay: Duration,
}

impl WatchCadence {
    fn new() -> Self {
        Self {
            fast_until: Instant::now() + WATCH_FAST_PERIOD,
            delay: WATCH_FIRST_DELAY,
        }
    }

    fn advance(&mut self) {
        if Instant::now() >= self.fast_until {
            self.delay = (self.delay * 2).min(WATCH_MAX_DELAY);
        }
    }
}

/// Clears the process-wide watcher claim even when the runtime carrying the
/// task is shut down. Background platform entry points own short-lived Tokio
/// runtimes, so ordinary code after an `.await` is not guaranteed to run.
struct WatchingGuard<'a>(&'a UploadWatch);

impl Drop for WatchingGuard<'_> {
    fn drop(&mut self) {
        self.0.watching.store(false, Ordering::SeqCst);
    }
}
/// Poll while the app is alive, and wake immediately for newly scheduled work
/// or native completion callbacks. Polling remains the fallback when callbacks
/// are lost or an accepted request still needs server-side finalization.
pub fn watch_pending_uploads(ctx: &Arc<Context>) {
    let Some(runtime) = ctx.foreground_runtime() else {
        // A killed-app worker has no long-lived runtime. Its native scheduler
        // uses the `pending_uploads` result from background::run instead.
        return;
    };
    let requested = UPLOAD_WATCH.request();
    if UPLOAD_WATCH.watching.swap(true, Ordering::SeqCst) {
        // A watcher is already running and will pick the request up on its next
        // pass, so this does not start a second poller against the same jobs.
        return;
    }
    let ctx = ctx.clone();
    // Capture before spawning so cancellation before the first poll also
    // releases the claim.
    let guard = WatchingGuard(&UPLOAD_WATCH);
    runtime.spawn(async move {
        let service = DirectMediaUploadService::new(&ctx);
        let mut seen = requested;
        let mut cadence = WatchCadence::new();
        loop {
            let woken = UPLOAD_WATCH.wait(cadence.delay).await;
            let requests = UPLOAD_WATCH.requests.load(Ordering::SeqCst);
            if woken || requests != seen {
                seen = requests;
                cadence = WatchCadence::new();
            }
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
            cadence.advance();
        }
        // Release the claim before checking for a request that raced the last
        // pass. `WatchingGuard` also performs this release if this future is
        // cancelled because its runtime is being destroyed.
        drop(guard);
        // A request that arrived between the loop stopping and the flag being
        // cleared found `WATCHING` still set and returned without starting a
        // watcher. Nothing else would poll for it, so pick it up here.
        if UPLOAD_WATCH.requests.load(Ordering::SeqCst) != seen {
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
    reupload_requested_by: Option<String>,
    reupload_targets: Option<String>,
}

#[derive(FromRow)]
struct MessageRow {
    group_id: String,
    message_id: String,
    created_at: i64,
    quotes_message_id: Option<String>,
    additional_message_data: Option<Vec<u8>>,
    is_widget_media: i64,
    is_story: i64,
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
    reupload_requested_by: Option<String>,
    reupload_targets: Option<String>,
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
    if stored.is_none() {
        sqlx::query(
            r#"INSERT INTO app_metadata(key, value) VALUES(?, ?)
               ON CONFLICT(key) DO UPDATE SET value = excluded.value"#,
        )
        .bind(API_NAMESPACE_KEY)
        .bind(namespace)
        .execute(&database.pool)
        .await?;
        return Ok((None, 0));
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
           WHERE (upload_state != 'uploaded' OR reupload_requested_by IS NOT NULL OR reupload_targets IS NOT NULL)
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
    // A watcher keeps this service for its lifetime, reusing the same pool
    // across status checks. Native workers keep their own runtime-local pool.
    client: reqwest::Client,
}

impl DirectMediaUploadService {
    pub fn new(ctx: &Arc<Context>) -> Self {
        Self {
            ctx: ctx.clone(),
            client: reqwest::Client::new(),
        }
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

    /// Every slot this client still holds: cached and in flight alike.
    ///
    /// The server abandons each reserved slot of this account that is missing
    /// from the list, so an omission is not merely a lost cache entry - a slot
    /// the OS is still uploading against dies with `not_in_client_cache`, and
    /// the send has to start over. Reserved slots are exactly the ones a
    /// refill can race, because a refill runs on every reconnect and after
    /// every settled transfer, both of which happen while a send is in flight.
    async fn locally_known_slot_ids(&self) -> Result<Vec<String>> {
        let database = self.ctx.app_db.read().await.clone();
        Ok(sqlx::query_scalar::<_, String>(
            r#"SELECT attachment_id FROM direct_media_upload_slots
               WHERE state IN ('cached', 'reserved')
                 AND expires_at > CAST(strftime('%s','now') AS INTEGER)"#,
        )
        .fetch_all(&database.pool)
        .await?)
    }

    pub async fn preload_slots(&self) -> Result<usize> {
        self.ensure_api_namespace().await?;
        // Held across the whole exchange: the list below is only true while no
        // other request can be answered, and stays true until the answer has
        // been stored.
        let _guard = PRELOAD_LOCK.lock().await;
        let known = self.locally_known_slot_ids().await?;
        let database = self.ctx.app_db.read().await.clone();
        let request = RequestUploadSlots {
            locally_known_slot_ids: known,
        };
        let request_body = request.encode_to_vec();
        let response = self
            .authenticated_request(
                self.client
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
        tracing::info!(
            known_sent = request.locally_known_slot_ids.len(),
            slots_received = count,
            max_active = slots.maximum_active_slots,
            refill_threshold = slots.refill_threshold,
            "direct-media upload slots response from server"
        );
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
                   ON CONFLICT(attachment_id) DO UPDATE SET
                       expires_at = excluded.expires_at,
                       maximum_object_bytes = excluded.maximum_object_bytes,
                       upload_url = excluded.upload_url,
                       upload_fields_json = excluded.upload_fields_json,
                       capability = excluded.capability,
                       state = 'cached'"#,
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
               WHERE state = 'cached' AND expires_at > CAST(strftime('%s','now') AS INTEGER)"#,
        )
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
        if usable > 0 {
            if usable <= self.refill_threshold().await {
                self.spawn_slot_refill();
            }
            return Ok(());
        }
        let preload_result = self.preload_slots().await;
        let usable_after = self.usable_slot_count().await?;
        if usable_after > 0 {
            if let Err(error) = preload_result {
                tracing::warn!(%error, usable_after, "slot refill failed; using cached direct-media slot");
            }
            Ok(())
        } else {
            preload_result.and_then(|_| {
                Err(TwonlyError::Generic(
                    "no direct-media upload slots available from server".into(),
                ))
            })
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
                   AND expires_at > CAST(strftime('%s','now') AS INTEGER)
                 ORDER BY expires_at ASC LIMIT 1
               )
               RETURNING attachment_id, expires_at, maximum_object_bytes, upload_url,
                         upload_fields_json, capability"#,
        )
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

        // Release any orphaned reserved slots (slots marked reserved with no associated job)
        let _ = sqlx::query(
            r#"UPDATE direct_media_upload_slots SET state = 'cached'
               WHERE state = 'reserved'
                 AND attachment_id NOT IN (SELECT attachment_id FROM direct_media_upload_jobs)"#,
        )
        .execute(&database.pool)
        .await;

        let jobs = sqlx::query_as::<_, PendingJob>(
            r#"SELECT j.attachment_id, j.media_id, j.multipart_path, j.manifest_path,
                      j.complete_body_path, s.capability, j.expires_at,
                      j.reupload_requested_by, j.reupload_targets
               FROM direct_media_upload_jobs j
               JOIN direct_media_upload_slots s ON s.attachment_id = j.attachment_id
               WHERE j.state IN ('scheduled', 'waiting_for_server')"#,
        )
        .fetch_all(&database.pool)
        .await?;
        drop(database);

        let mut checks = stream::iter(jobs)
            .map(|job| async move { self.reconcile_job(&job).await })
            .buffer_unordered(STATUS_CONCURRENCY);
        let mut first_error = None;
        while let Some(result) = checks.next().await {
            if let Err(error) = result {
                // Finish other jobs even when one fails; cancelling a settling
                // job midway could leave its durable state incomplete.
                first_error.get_or_insert(error);
            }
        }
        match first_error {
            Some(error) => Err(error),
            None => Ok(()),
        }
    }

    async fn reconcile_job(&self, job: &PendingJob) -> Result<()> {
        let status = match self.fetch_status(job).await {
            Ok(status) => status,
            Err(error) => {
                tracing::warn!(
                    attachment_id = job.attachment_id,
                    %error,
                    "could not read direct-media attachment status"
                );
                return Ok(());
            }
        };
        self.apply_status(job, status).await
    }

    async fn apply_status(&self, job: &PendingJob, status: AttachmentStatus) -> Result<()> {
        let now = chrono::Utc::now().timestamp();
        let state = AttachmentState::try_from(status.state).unwrap_or(AttachmentState::Unknown);
        tracing::info!(
            attachment_id = job.attachment_id,
            media_id = job.media_id,
            ?state,
            // The server's word on why a transfer was given up on, which is
            // the only place a cause such as `not_in_client_cache` appears.
            reason = status.rejection_reason,
            "read direct-media attachment status"
        );
        match state {
            AttachmentState::Ready => self.settle(job, Outcome::Uploaded).await?,
            AttachmentState::Rejected => self.settle(job, Outcome::Rejected).await?,
            AttachmentState::Expired | AttachmentState::Abandoned => {
                self.settle(job, Outcome::Retry).await?;
                if status.rejection_reason == "not_in_client_cache" {
                    self.purge_cached_slots().await;
                }
            }
            // Still reserved or uploading. Only give up once the slot's own
            // capability has expired, because the native task stops then too.
            _ if job.expires_at <= now => self.settle(job, Outcome::Retry).await?,
            AttachmentState::Reserved | AttachmentState::Uploading => {
                if let Err(error) = self.recover_native_transfer(job).await {
                    tracing::warn!(attachment_id = job.attachment_id, %error,
                            "could not recover native media transfer");
                }
            }
            _ => {}
        }
        Ok(())
    }

    /// Reuse the same immutable requests and attachment. The native scheduler
    /// keeps live work, repairs missing/failed work, and retries completion for
    /// an object already uploaded. No replacement recipient envelopes are made.
    async fn recover_native_transfer(&self, job: &PendingJob) -> Result<()> {
        if !cfg!(any(target_os = "android", test)) {
            return Ok(());
        }
        let lock = media_lock(&job.media_id);
        let _guard = lock.lock().await;
        let database = self.ctx.app_db.read().await.clone();
        let now = chrono::Utc::now().timestamp();
        // Claim a recovery interval across foreground/background reconcilers.
        // Holding the media lock also keeps settle from removing request files.
        let descriptor = sqlx::query_as::<_, (String, i64)>(
            r#"UPDATE direct_media_upload_jobs SET updated_at = ?
               WHERE attachment_id = ? AND state IN ('scheduled', 'waiting_for_server')
                 AND updated_at <= ?
               RETURNING native_descriptor_json, created_at"#,
        )
        .bind(now)
        .bind(&job.attachment_id)
        .bind(now - NATIVE_RECOVERY_INTERVAL_SECONDS)
        .fetch_optional(&database.pool)
        .await?;
        if let Some((descriptor, created_at)) = descriptor {
            tokio::task::spawn_blocking(move || transfer::recover(&descriptor, created_at))
                .await
                .map_err(|error| TwonlyError::Generic(error.to_string()))??;
        }
        Ok(())
    }

    /// The server gave this account's reserved slots up while this client was
    /// still holding them, so the cache it holds is a generation the server has
    /// swept: the other slots in it are just as dead, and each would cost a
    /// failed send to discover. Dropping them costs one refill instead.
    async fn purge_cached_slots(&self) {
        let database = self.ctx.app_db.read().await.clone();
        let purged = sqlx::query("DELETE FROM direct_media_upload_slots WHERE state = 'cached'")
            .execute(&database.pool)
            .await
            .map(|result| result.rows_affected())
            .unwrap_or_default();
        drop(database);
        if purged > 0 {
            tracing::warn!(
                purged,
                "dropped cached direct-media slots the server had already abandoned"
            );
            self.spawn_slot_refill();
        }
    }

    async fn fetch_status(&self, job: &PendingJob) -> Result<AttachmentStatus> {
        let started = Instant::now();
        let response = self
            .client
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
        let status = AttachmentStatus::decode(
            response
                .bytes()
                .await
                .map_err(|error| TwonlyError::Generic(error.to_string()))?,
        )?;
        tracing::info!(
            attachment_id = job.attachment_id,
            elapsed_ms = started.elapsed().as_millis() as u64,
            "received direct-media status response"
        );
        Ok(status)
    }

    /// Caller holds the media lock. Abandoning on the server prevents even a
    /// native transfer already in flight from dispatching its old manifest.
    /// Returns true if dispatch won the race and recipients need a deletion.
    pub(crate) async fn cancel_pending_upload(&self, media_id: &str) -> Result<bool> {
        let database = self.ctx.app_db.read().await.clone();
        let jobs = sqlx::query_as::<_, PendingJob>(
            r#"SELECT j.attachment_id, j.media_id, j.multipart_path, j.manifest_path,
                      j.complete_body_path, s.capability, j.expires_at,
                      j.reupload_requested_by, j.reupload_targets
               FROM direct_media_upload_jobs j
               JOIN direct_media_upload_slots s ON s.attachment_id = j.attachment_id
               WHERE j.media_id = ?"#,
        )
        .bind(media_id)
        .fetch_all(&database.pool)
        .await?;
        let mut dispatched = false;
        for job in jobs {
            let response = self
                .client
                .post(Self::api_url(&format!(
                    "v2/attachments/{}/abandon",
                    job.attachment_id
                )))
                .header("x-twonly-upload-capability", hex::encode(&job.capability))
                .timeout(Duration::from_secs(30))
                .send()
                .await
                .map_err(|error| TwonlyError::Generic(error.to_string()))?;
            let status = if response.status() == reqwest::StatusCode::CONFLICT {
                self.fetch_status(&job).await?
            } else if response.status().is_success() {
                AttachmentStatus::decode(
                    response
                        .bytes()
                        .await
                        .map_err(|error| TwonlyError::Generic(error.to_string()))?,
                )?
            } else {
                return Err(TwonlyError::Generic(format!(
                    "attachment cancellation returned HTTP {}",
                    response.status()
                )));
            };
            dispatched |= self.finish_cancellation(&job, status).await?;
        }
        Ok(dispatched)
    }

    async fn finish_cancellation(
        &self,
        job: &PendingJob,
        status: AttachmentStatus,
    ) -> Result<bool> {
        let dispatched = match AttachmentState::try_from(status.state) {
            Ok(AttachmentState::Ready) => true,
            Ok(
                AttachmentState::Abandoned | AttachmentState::Expired | AttachmentState::Rejected,
            ) => false,
            _ => {
                return Err(TwonlyError::Generic(
                    "attachment cancellation is not confirmed".into(),
                ))
            }
        };
        let database = self.ctx.app_db.read().await.clone();
        let mut transaction = database.pool.begin().await?;
        sqlx::query("DELETE FROM direct_media_upload_jobs WHERE attachment_id = ?")
            .bind(&job.attachment_id)
            .execute(&mut *transaction)
            .await?;
        sqlx::query("UPDATE direct_media_upload_slots SET state = ? WHERE attachment_id = ?")
            .bind(if dispatched { "consumed" } else { "abandoned" })
            .bind(&job.attachment_id)
            .execute(&mut *transaction)
            .await?;
        if dispatched {
            MediaFile::mark_uploaded(&mut transaction, &job.media_id).await?;
        }
        transaction.commit().await?;
        for path in [
            &job.multipart_path,
            &job.manifest_path,
            &job.complete_body_path,
        ] {
            let _ = std::fs::remove_file(path);
        }
        let _ = std::fs::remove_dir(
            PathBuf::from(&self.ctx.config.data_dir)
                .join("direct-media-upload")
                .join(&job.attachment_id),
        );
        self.remove_encrypted_copy(&job.media_id).await;
        Ok(dispatched)
    }

    /// Releases the request files and the slot, then applies the outcome to the
    /// media file. Safe to run twice: the job row is the claim.
    async fn settle(&self, job: &PendingJob, outcome: Outcome) -> Result<()> {
        let lock = media_lock(&job.media_id);
        let _guard = lock.lock().await;
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
        // The cache has just lost one; refill in the background so the next
        // send does not have to be online to reserve one. Only once this slot
        // has left `reserved`, so the refill does not report it as still held.
        self.spawn_slot_refill();

        match outcome {
            Outcome::Uploaded => {
                let mut transaction = database.pool.begin().await?;
                MediaFile::mark_uploaded(&mut transaction, &job.media_id).await?;
                // A newer request may have arrived while the OS transferred
                // this job. Only clear the request set this job carried.
                sqlx::query(
                    r#"UPDATE media_files SET reupload_requested_by = NULL, reupload_targets = NULL
                       WHERE media_id = ? AND reupload_requested_by IS ? AND reupload_targets IS ?"#,
                )
                .bind(&job.media_id)
                .bind(&job.reupload_requested_by)
                .bind(&job.reupload_targets)
                .execute(&mut *transaction)
                .await?;
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
                       WHERE media_id = ?
                         AND (upload_state != 'uploaded' OR reupload_requested_by IS NOT NULL OR reupload_targets IS NOT NULL)"#,
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
        self.cleanup_stale_media_jobs(media_id).await;
        let slot = self.reserve_slot().await?;
        match self.prepare_reserved(media_id, &slot).await {
            Ok(()) => Ok(slot.attachment_id),
            Err(error) => {
                self.release_reservation(&slot.attachment_id).await;
                Err(error)
            }
        }
    }

    async fn cleanup_stale_media_jobs(&self, media_id: &str) {
        let database = self.ctx.app_db.read().await.clone();
        let jobs = sqlx::query_as::<_, (String, String, String, String)>(
            r#"DELETE FROM direct_media_upload_jobs WHERE media_id = ?
               RETURNING attachment_id, multipart_path, manifest_path, complete_body_path"#,
        )
        .bind(media_id)
        .fetch_all(&database.pool)
        .await
        .unwrap_or_default();

        for (attachment_id, multipart, manifest, complete) in jobs {
            for path in [&multipart, &manifest, &complete] {
                let _ = std::fs::remove_file(path);
            }
            let job_dir = PathBuf::from(&self.ctx.config.data_dir)
                .join("direct-media-upload")
                .join(&attachment_id);
            let _ = std::fs::remove_dir(job_dir);
            let _ = sqlx::query(
                "UPDATE direct_media_upload_slots SET state = 'cached' WHERE attachment_id = ?",
            )
            .bind(&attachment_id)
            .execute(&database.pool)
            .await;
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
                complete_body_path, native_descriptor_json, state, expires_at,
                reupload_requested_by, reupload_targets)
               SELECT ?, media_id, ?, ?, ?, ?, 'prepared', ?,
                      reupload_requested_by, reupload_targets
               FROM media_files WHERE media_id = ?"#,
        )
        .bind(&slot.attachment_id)
        .bind(multipart_path.to_string_lossy().as_ref())
        .bind(manifest_path.to_string_lossy().as_ref())
        .bind(complete_body_path.to_string_lossy().as_ref())
        .bind(&descriptor_json)
        .bind(slot.expires_at)
        .bind(media_id)
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
                      display_limit_in_milliseconds, encryption_key, encryption_nonce,
                      reupload_requested_by, reupload_targets
               FROM media_files WHERE media_id = ?"#,
        )
        .bind(media_id)
        .fetch_optional(&database.pool)
        .await?
        .ok_or_else(|| TwonlyError::Generic(format!("media {media_id} does not exist")))?;
        let reupload_targets: Option<Vec<MediaReuploadTarget>> = media
            .reupload_targets
            .as_deref()
            .map(serde_json::from_str)
            .transpose()?;
        // Older queued reuploads only saved contact ids. An empty or invalid
        // saved list must never fall back to broadcasting the image.
        let legacy_requesters = media
            .reupload_requested_by
            .as_deref()
            .map(|value| parse_reupload_requested_by(Some(value)));
        let is_reupload = reupload_targets.is_some() || legacy_requesters.is_some();
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

        let now = chrono::Utc::now().timestamp();
        let messages = sqlx::query_as::<_, MessageRow>(
            r#"SELECT group_id, message_id, created_at, quotes_message_id,
                      additional_message_data, is_widget_media, is_story
               FROM messages WHERE media_id = ?"#,
        )
        .bind(media_id)
        .fetch_all(&database.pool)
        .await?
        .into_iter()
        // An upload that took longer than a story lives would deliver an item
        // its recipients ignore on arrival.
        .filter(|message| {
            message.is_story == 0 || message.created_at + STORY_LIFETIME_SECONDS > now
        })
        .collect::<Vec<_>>();
        if messages.is_empty() {
            return Err(TwonlyError::MediaHasNoRecipients);
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
                     AND c.account_deleted = 0
                     AND NOT EXISTS (
                         SELECT 1 FROM message_actions a
                         WHERE a.message_id = ? AND a.contact_id = gm.contact_id
                           AND a.type = 'sendFailed'
                     )"#,
            )
            .bind(&message.group_id)
            .bind(&message.message_id)
            .fetch_all(&database.pool)
            .await?;
            for recipient in recipients {
                if let Some(targets) = &reupload_targets {
                    if !targets.iter().any(|target| {
                        target.contact_id == recipient.contact_id
                            && target.message_id == message.message_id
                    }) {
                        continue;
                    }
                } else if let Some(requesters) = &legacy_requesters {
                    if !requesters.contains(&recipient.contact_id) {
                        continue;
                    }
                }
                let mut download_token = vec![0_u8; 32];
                rand::rng().fill_bytes(&mut download_token);
                let mut wake = !is_reupload && message.is_widget_media == 0;
                let content = if message.is_story != 0 {
                    wake = story_wakes_recipient(
                        &database,
                        &message,
                        media_id,
                        recipient.contact_id,
                        now,
                    )
                    .await?;
                    EncryptedContent {
                        story: Some(encrypted_content::Story {
                            media: Some(encrypted_content::Media {
                                sender_message_id: message.message_id.clone(),
                                r#type: media_type as i32,
                                display_limit_in_milliseconds: None,
                                requires_authentication: false,
                                timestamp: message.created_at.saturating_mul(1_000),
                                quote_message_id: None,
                                download_token: Some(download_token.clone()),
                                encryption_key: Some(key.to_vec()),
                                encryption_mac: Some(tag.to_vec()),
                                encryption_nonce: Some(nonce.to_vec()),
                                additional_message_data: message.additional_message_data.clone(),
                                widget_only: None,
                            }),
                            notify: wake,
                        }),
                        ..Default::default()
                    }
                } else {
                    EncryptedContent {
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
                            widget_only: Some(message.is_widget_media != 0),
                        }),
                        ..Default::default()
                    }
                };
                let envelope = send_c2c_message_to_contact()
                    .ctx(&self.ctx)
                    .contact_id(recipient.contact_id)
                    .encrypted_content(content.encode_to_vec())
                    .message_id(message.message_id.clone())
                    .only_return_encrypted_data(true)
                    .blocking(true)
                    .call()
                    .await;
                let Some(encrypted_body) = self
                    .recipient_envelope(&message, recipient.contact_id, envelope)
                    .await?
                else {
                    continue;
                };
                dispatches.push(AttachmentDispatch {
                    recipient_user_id: recipient.contact_id,
                    encrypted_body,
                    // Widget media arrives already opened and raises no
                    // notification, so a push for it only buys the recipient
                    // an alert with nothing behind it. A story wakes only for
                    // the first item in a day, see `story_wakes_recipient`.
                    push_data: wake.then(|| vec![1]),
                    download_token,
                });
            }
        }
        if dispatches.is_empty() {
            return Err(TwonlyError::MediaHasNoRecipients);
        }
        if dispatches.len() > MAX_ATTACHMENT_DISPATCHES {
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

    /// A peer without keys or a usable session cannot receive this send. Keep
    /// that failure per recipient so a later preparation of the shared media
    /// cannot retry it or prevent the other recipients from receiving it.
    /// Transient errors still retry; stories retain their retirement policy.
    async fn recipient_envelope(
        &self,
        message: &MessageRow,
        contact_id: i64,
        envelope: Result<Option<Vec<u8>>>,
    ) -> Result<Option<Vec<u8>>> {
        match envelope {
            Err(TwonlyError::PeerHasNoPrekeyBundle(_)) if message.is_story != 0 => {
                let database = self.ctx.app_db.read().await.clone();
                let mut transaction = database.pool.begin().await?;
                sqlx::query("DELETE FROM receipts WHERE message_id = ? AND contact_id = ?")
                    .bind(&message.message_id)
                    .bind(contact_id)
                    .execute(&mut *transaction)
                    .await?;
                // Keep previously delivered rows when this is a reupload.
                let unsent = sqlx::query_scalar::<_, i64>(
                    "SELECT EXISTS(SELECT 1 FROM messages WHERE message_id = ? AND ack_by_server IS NULL AND ack_by_user IS NULL AND opened_at IS NULL)",
                ).bind(&message.message_id).fetch_one(&mut *transaction).await? != 0;
                if unsent {
                    crate::services::stories::retire_rows(
                        &mut transaction,
                        std::slice::from_ref(&message.message_id),
                        chrono::Utc::now().timestamp(),
                    )
                    .await?;
                }
                transaction.commit().await?;
                tracing::info!(
                    contact_id,
                    message_id = message.message_id,
                    "skipping story recipient without a prekey bundle or usable session"
                );
                Ok(None)
            }
            Err(TwonlyError::PeerHasNoPrekeyBundle(_)) => {
                let database = self.ctx.app_db.read().await.clone();
                let mut transaction = database.pool.begin().await?;
                sqlx::query(
                    r#"INSERT INTO message_actions(message_id, contact_id, type)
                       VALUES (?, ?, 'sendFailed')
                       ON CONFLICT(message_id, contact_id, type) DO NOTHING"#,
                )
                .bind(&message.message_id)
                .bind(contact_id)
                .execute(&mut *transaction)
                .await?;
                sqlx::query("DELETE FROM receipts WHERE message_id = ? AND contact_id = ?")
                    .bind(&message.message_id)
                    .bind(contact_id)
                    .execute(&mut *transaction)
                    .await?;
                transaction.commit().await?;
                tracing::warn!(
                    contact_id,
                    message_id = message.message_id,
                    "media send permanently failed: recipient has no prekey bundle or usable session"
                );
                Ok(None)
            }
            other => other?.map(Some).ok_or_else(|| {
                TwonlyError::Generic("Signal engine returned no encrypted envelope".into())
            }),
        }
    }
}

/// Whether a story row's recipient is woken for it. Stories wake only for the
/// first item in a day, so a burst of them is one alert rather than a stream:
///
/// - an older own story row in the same chat that has not expired yet means
///   this is not the first. Ties on the timestamp are broken by message id, so
///   two items prepared at once cannot each defer to the other.
/// - a direct copy of the same media already wakes the recipient.
/// - a row the server or recipient already acknowledged is being prepared
///   again for a reupload, and was announced the first time.
/// - the two have not sent each other a text or media message in two weeks;
///   the recipient would not announce it then, so waking them is pointless.
///
/// The answer also travels inside the story, so the receiver announces
/// exactly the items it was woken for.
async fn story_wakes_recipient(
    database: &AppDatabase,
    message: &MessageRow,
    media_id: &str,
    contact_id: i64,
    now: i64,
) -> Result<bool> {
    let quiet = sqlx::query_scalar::<_, i64>(
        r#"SELECT EXISTS(
               SELECT 1 FROM messages older
               WHERE older.is_story = 1 AND older.sender_id IS NULL
                 AND older.group_id = ? AND older.media_id IS NOT NULL
                 AND older.created_at > ?
                 AND (older.created_at < ?
                      OR (older.created_at = ? AND older.message_id < ?))
           ) OR EXISTS(
               SELECT 1 FROM messages direct
               JOIN group_members gm ON gm.group_id = direct.group_id
               WHERE direct.media_id = ? AND direct.is_story = 0 AND gm.contact_id = ?
           ) OR EXISTS(
               SELECT 1 FROM message_actions action
               WHERE action.message_id = ? AND action.contact_id = ?
                 AND action.type IN ('ackByServerAt', 'ackByUserAt')
           ) OR NOT EXISTS(
               SELECT 1 FROM groups chat
               WHERE chat.group_id = ? AND chat.last_text_or_media_at > ?
           )"#,
    )
    .bind(&message.group_id)
    .bind(now - STORY_LIFETIME_SECONDS)
    .bind(message.created_at)
    .bind(message.created_at)
    .bind(&message.message_id)
    .bind(media_id)
    .bind(contact_id)
    .bind(&message.message_id)
    .bind(contact_id)
    .bind(&message.group_id)
    .bind(now - STORY_ANNOUNCE_RECENT_EXCHANGE_SECONDS)
    .fetch_one(&database.pool)
    .await?;
    Ok(quiet == 0)
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
    use crate::services::media_upload::MediaUploadService;
    use crate::user_config::UserConfig;
    use libsignal_protocol::IdentityKeyPair;
    use rand::SeedableRng;

    #[tokio::test(start_paused = true)]
    async fn upload_watch_interrupts_an_existing_long_sleep() {
        let watch = Arc::new(UploadWatch::new());
        let started = Instant::now();
        let waiting = {
            let watch = watch.clone();
            tokio::spawn(async move { watch.wait(WATCH_MAX_DELAY).await })
        };
        tokio::task::yield_now().await;
        tokio::time::advance(Duration::from_secs(1)).await;
        watch.request();
        assert!(waiting.await.unwrap());
        assert_eq!(started.elapsed(), Duration::from_secs(1));
    }

    #[tokio::test(start_paused = true)]
    async fn upload_watch_keeps_a_completion_received_between_checks() {
        let watch = UploadWatch::new();
        let started = Instant::now();
        watch.request();
        assert!(watch.wait(WATCH_MAX_DELAY).await);
        // A completion delivered while a status request is in flight must
        // survive until the watcher starts waiting again.
        let generation = watch.request();
        assert!(watch.wait(WATCH_MAX_DELAY).await);
        assert_eq!(watch.requests.load(Ordering::SeqCst), generation);
        assert_eq!(started.elapsed(), Duration::ZERO);
        // Consuming the completion hint must not leave a busy polling loop.
        assert!(!watch.wait(WATCH_FIRST_DELAY).await);
        assert_eq!(started.elapsed(), WATCH_FIRST_DELAY);
    }

    #[tokio::test(start_paused = true)]
    async fn upload_watch_polls_quickly_then_backs_off_and_resets() {
        let mut cadence = WatchCadence::new();
        for _ in 0..14 {
            tokio::time::advance(WATCH_FIRST_DELAY).await;
            cadence.advance();
            assert_eq!(cadence.delay, WATCH_FIRST_DELAY);
        }
        tokio::time::advance(WATCH_FIRST_DELAY).await;
        cadence.advance();
        assert_eq!(cadence.delay, Duration::from_secs(2));
        for _ in 0..10 {
            cadence.advance();
        }
        assert_eq!(cadence.delay, WATCH_MAX_DELAY);
        cadence = WatchCadence::new();
        cadence.advance();
        assert_eq!(cadence.delay, WATCH_FIRST_DELAY);
    }

    #[test]
    fn upload_watch_releases_claim_when_cancelled_before_first_poll() {
        let watch = UploadWatch::new();
        watch.watching.store(true, Ordering::SeqCst);
        let guard = WatchingGuard(&watch);
        let future = async move {
            std::future::pending::<()>().await;
            drop(guard);
        };
        drop(future);
        assert!(!watch.watching.load(Ordering::SeqCst));
    }

    #[tokio::test]
    async fn cancelled_transfers_only_notify_after_dispatch_won() -> anyhow::Result<()> {
        for state in [
            AttachmentState::Abandoned,
            AttachmentState::Ready,
            AttachmentState::Uploading,
        ] {
            let directory = tempfile::tempdir()?;
            let ctx = upload_test_context(directory.path(), 42).await?;
            let database = ctx.app_db.read().await.clone();
            sqlx::query("INSERT INTO media_files(media_id, type, upload_state) VALUES ('m', 'image', 'backgroundUploadTaskStarted')")
                .execute(&database.pool).await?;
            sqlx::query("INSERT INTO groups(group_id, group_name) VALUES ('g', 'Group')")
                .execute(&database.pool)
                .await?;
            sqlx::query("INSERT INTO messages(message_id, group_id, type, media_id, is_story) VALUES ('s', 'g', 'media', 'm', 1)")
                .execute(&database.pool).await?;
            let mut job = reupload_test_job(&database, "m", "slot").await?;
            job.multipart_path = directory.path().join("multipart").display().to_string();
            job.manifest_path = directory.path().join("manifest").display().to_string();
            job.complete_body_path = directory.path().join("complete").display().to_string();
            for path in [
                &job.multipart_path,
                &job.manifest_path,
                &job.complete_body_path,
            ] {
                std::fs::write(path, b"request")?;
            }
            let service = DirectMediaUploadService::new(&ctx);
            let result = service
                .finish_cancellation(
                    &job,
                    AttachmentStatus {
                        state: state as i32,
                        ..Default::default()
                    },
                )
                .await;
            if state == AttachmentState::Uploading {
                assert!(result.is_err());
                assert_eq!(service.pending_job_count().await?, 1);
                assert!(Path::new(&job.manifest_path).exists());
            } else {
                assert_eq!(result?, state == AttachmentState::Ready);
                assert_eq!(service.pending_job_count().await?, 0);
                assert!(!Path::new(&job.manifest_path).exists());
                let ack: Option<i64> =
                    sqlx::query_scalar("SELECT ack_by_server FROM messages WHERE message_id = 's'")
                        .fetch_one(&database.pool)
                        .await?;
                assert_eq!(ack.is_some(), state == AttachmentState::Ready);
                let slot: String = sqlx::query_scalar(
                    "SELECT state FROM direct_media_upload_slots WHERE attachment_id = 'slot'",
                )
                .fetch_one(&database.pool)
                .await?;
                assert_eq!(
                    slot,
                    if state == AttachmentState::Ready {
                        "consumed"
                    } else {
                        "abandoned"
                    }
                );
            }
        }
        Ok(())
    }

    #[tokio::test]
    async fn missing_bundle_skips_only_the_unsent_story_recipient() -> anyhow::Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx = upload_test_context(directory.path(), 42).await?;
        let database = ctx.app_db.read().await.clone();
        for contact_id in [7, 8] {
            sqlx::query("INSERT INTO contacts(user_id, username, accepted) VALUES (?, ?, 1)")
                .bind(contact_id)
                .bind(format!("user-{contact_id}"))
                .execute(&database.pool)
                .await?;
        }
        sqlx::query("INSERT INTO groups(group_id, group_name) VALUES ('g', 'Group')")
            .execute(&database.pool)
            .await?;
        sqlx::query("INSERT INTO media_files(media_id, type, upload_state) VALUES ('m', 'image', 'preprocessing')")
            .execute(&database.pool).await?;
        for (message_id, contact_id) in [("missing", 7), ("healthy", 8)] {
            sqlx::query("INSERT INTO messages(message_id, group_id, type, media_id, is_story) VALUES (?, 'g', 'media', 'm', 1)")
                .bind(message_id).execute(&database.pool).await?;
            sqlx::query("INSERT INTO receipts(receipt_id, contact_id, message_id, message, will_be_retried_by_media_upload) VALUES (?, ?, ?, x'00', 1)")
                .bind(message_id).bind(contact_id).bind(message_id)
                .execute(&database.pool).await?;
        }
        let row = |id: &str| MessageRow {
            group_id: "g".into(),
            message_id: id.into(),
            created_at: chrono::Utc::now().timestamp(),
            quotes_message_id: None,
            additional_message_data: None,
            is_widget_media: 0,
            is_story: 1,
        };
        let service = DirectMediaUploadService::new(&ctx);
        assert!(service
            .recipient_envelope(
                &row("missing"),
                7,
                Err(TwonlyError::PeerHasNoPrekeyBundle(7))
            )
            .await?
            .is_none());
        assert_eq!(
            service
                .recipient_envelope(&row("healthy"), 8, Ok(Some(vec![1, 2, 3])))
                .await?,
            Some(vec![1, 2, 3])
        );
        let remaining: Vec<String> = sqlx::query_scalar("SELECT message_id FROM messages")
            .fetch_all(&database.pool)
            .await?;
        assert_eq!(remaining, vec!["healthy"]);
        let receipts: Vec<String> = sqlx::query_scalar("SELECT receipt_id FROM receipts")
            .fetch_all(&database.pool)
            .await?;
        assert_eq!(receipts, vec!["healthy"]);
        let accepted: i64 = sqlx::query_scalar("SELECT accepted FROM contacts WHERE user_id = 7")
            .fetch_one(&database.pool)
            .await?;
        assert_eq!(accepted, 1, "skipping must not modify the contact");
        assert!(service
            .recipient_envelope(
                &row("healthy"),
                8,
                Err(TwonlyError::Generic("network unavailable".into()))
            )
            .await
            .is_err());
        assert_eq!(
            sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM messages")
                .fetch_one(&database.pool)
                .await?,
            1
        );
        Ok(())
    }

    #[tokio::test]
    async fn missing_bundle_permanently_fails_only_that_media_recipient() -> anyhow::Result<()> {
        let sender_dir = tempfile::tempdir()?;
        let receiver_dir = tempfile::tempdir()?;
        let sender = upload_test_context(sender_dir.path(), 42).await?;
        let receiver = upload_test_context(receiver_dir.path(), 7).await?;
        let bundle = receiver
            .signal_engine
            .lock()
            .await
            .as_ref()
            .unwrap()
            .generate_bundle()
            .await?;
        sender
            .signal_engine
            .lock()
            .await
            .as_ref()
            .unwrap()
            .process_prekey_bundle("7".into(), 1, bundle)
            .await?;
        let database = sender.app_db.read().await.clone();
        for statement in [
            "INSERT INTO contacts(user_id, username, signal_version) VALUES(7, 'healthy', 'v2'), (8, 'missing', 'v2')",
            "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES('group', 'Group', 0), ('direct', 'Direct', 1)",
            "INSERT INTO group_members(group_id, contact_id) VALUES('group', 7), ('group', 8), ('direct', 8)",
        ] {
            sqlx::query(statement).execute(&database.pool).await?;
        }
        let upload = MediaUploadService::new(&sender);
        let media_id = upload.initialize("audio".into(), None, false).await?;
        let source = crate::services::mediafiles::MediaFileService::new(&sender)
            .temp_path(&media_id, "audio");
        std::fs::create_dir_all(source.parent().unwrap())?;
        std::fs::write(&source, b"voice message")?;
        for group_id in ["group", "direct"] {
            sqlx::query("INSERT INTO messages(message_id, group_id, type, media_id) VALUES(?, ?, 'media', ?)")
                .bind(group_id).bind(group_id).bind(&media_id)
                .execute(&database.pool).await?;
            sqlx::query("INSERT INTO receipts(receipt_id, contact_id, message_id, message, will_be_retried_by_media_upload) VALUES(?, 8, ?, x'00', 1)")
                .bind(group_id).bind(group_id).execute(&database.pool).await?;
        }
        let row = |id: &str| MessageRow {
            group_id: id.into(),
            message_id: id.into(),
            created_at: chrono::Utc::now().timestamp(),
            quotes_message_id: None,
            additional_message_data: None,
            is_widget_media: 0,
            is_story: 0,
        };
        let direct = DirectMediaUploadService::new(&sender);
        // Network errors remain retryable and must not write terminal actions.
        assert!(direct
            .recipient_envelope(
                &row("group"),
                7,
                Err(TwonlyError::Generic("network unavailable".into()))
            )
            .await
            .is_err());
        for id in ["group", "direct"] {
            assert!(direct
                .recipient_envelope(&row(id), 8, Err(TwonlyError::PeerHasNoPrekeyBundle(8)))
                .await?
                .is_none());
            // Repeating the result is idempotent and keeps the original time.
            assert!(direct
                .recipient_envelope(&row(id), 8, Err(TwonlyError::PeerHasNoPrekeyBundle(8)))
                .await?
                .is_none());
            assert!(!upload.record_reupload_request(8, &media_id, id).await?);
        }
        assert_eq!(
            sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM message_actions WHERE type = 'sendFailed'"
            )
            .fetch_one(&database.pool)
            .await?,
            2
        );
        assert_eq!(
            sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM receipts")
                .fetch_one(&database.pool)
                .await?,
            0
        );
        // Real encryption succeeds for the healthy group member. Preparation
        // can be retried without ever asking the network for the failed peer.
        for _ in 0..2 {
            let (_, _, manifest) = direct.prepare_media(&media_id).await?;
            assert_eq!(manifest.dispatches.len(), 1);
            assert_eq!(manifest.dispatches[0].recipient_user_id, 7);
        }
        let mut transaction = database.pool.begin().await?;
        MediaFile::mark_uploaded(&mut transaction, &media_id).await?;
        transaction.commit().await?;
        let acks: Vec<(String, i64)> = sqlx::query_as(
            "SELECT message_id, contact_id FROM message_actions WHERE type = 'ackByServerAt'",
        )
        .fetch_all(&database.pool)
        .await?;
        assert_eq!(acks, vec![("group".into(), 7)]);
        let messages: Vec<(String, Option<i64>)> =
            sqlx::query_as("SELECT message_id, ack_by_server FROM messages ORDER BY message_id")
                .fetch_all(&database.pool)
                .await?;
        assert_eq!(messages[0], ("direct".into(), None));
        assert!(messages[1].1.is_some(), "the group must finish normally");
        assert!(
            !upload
                .record_reupload_request(8, &media_id, "group")
                .await?
        );

        // Keys published later must not revive this failed send. A new
        // message to the same contact remains independent and can succeed.
        let bundle = receiver
            .signal_engine
            .lock()
            .await
            .as_ref()
            .unwrap()
            .generate_bundle()
            .await?;
        sender
            .signal_engine
            .lock()
            .await
            .as_ref()
            .unwrap()
            .process_prekey_bundle("8".into(), 1, bundle)
            .await?;
        let (_, _, manifest) = direct.prepare_media(&media_id).await?;
        assert_eq!(manifest.dispatches.len(), 1);
        assert_eq!(manifest.dispatches[0].recipient_user_id, 7);
        sqlx::query("INSERT INTO messages(message_id, group_id, type, media_id) VALUES('fresh', 'direct', 'media', ?)")
            .bind(&media_id).execute(&database.pool).await?;
        let (_, _, manifest) = direct.prepare_media(&media_id).await?;
        assert_eq!(manifest.dispatches.len(), 2);
        assert!(manifest.dispatches.iter().any(|d| d.recipient_user_id == 8));
        Ok(())
    }

    #[tokio::test]
    async fn media_with_only_failed_recipients_stops_preparation() -> anyhow::Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx = upload_test_context(directory.path(), 42).await?;
        let database = ctx.app_db.read().await.clone();
        let upload = MediaUploadService::new(&ctx);
        let media_id = upload.initialize("audio".into(), None, false).await?;
        let source =
            crate::services::mediafiles::MediaFileService::new(&ctx).temp_path(&media_id, "audio");
        std::fs::create_dir_all(source.parent().unwrap())?;
        std::fs::write(&source, b"voice message")?;
        for statement in [
            "INSERT INTO contacts(user_id, username) VALUES(8, 'missing')",
            "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES('direct', 'Direct', 1)",
            "INSERT INTO group_members(group_id, contact_id) VALUES('direct', 8)",
            "INSERT INTO direct_media_upload_slots(attachment_id, expires_at, maximum_object_bytes, upload_url, upload_fields_json, capability, state) VALUES('slot', 9999999999, 1000000, 'https://objects.example', '{}', x'01', 'cached')",
        ] {
            sqlx::query(statement).execute(&database.pool).await?;
        }
        sqlx::query("INSERT INTO app_metadata(key, value) VALUES(?, ?)")
            .bind(API_NAMESPACE_KEY)
            .bind(RustApi::api_base_url("https".into()))
            .execute(&database.pool)
            .await?;
        sqlx::query("INSERT INTO messages(message_id, group_id, type, media_id) VALUES('failed', 'direct', 'media', ?)")
            .bind(&media_id).execute(&database.pool).await?;
        sqlx::query("INSERT INTO message_actions(message_id, contact_id, type) VALUES('failed', 8, 'sendFailed')")
            .execute(&database.pool).await?;
        upload.start_upload(&media_id).await?;
        let state: String =
            sqlx::query_scalar("SELECT upload_state FROM media_files WHERE media_id = ?")
                .bind(&media_id)
                .fetch_one(&database.pool)
                .await?;
        assert_eq!(state, "storedOnly");
        // No slot or network is needed when maintenance encounters it again.
        sqlx::query("DELETE FROM direct_media_upload_slots")
            .execute(&database.pool)
            .await?;
        upload.start_upload(&media_id).await?;
        assert_eq!(
            DirectMediaUploadService::new(&ctx)
                .pending_job_count()
                .await?,
            0
        );
        assert_eq!(sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM messages WHERE message_id = 'failed' AND ack_by_server IS NULL")
            .fetch_one(&database.pool).await?, 1);
        Ok(())
    }

    #[tokio::test]
    async fn server_ready_is_required_before_acknowledging_an_upload() -> anyhow::Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx = upload_test_context(directory.path(), 42).await?;
        let database = ctx.app_db.read().await.clone();
        sqlx::query("INSERT INTO media_files(media_id, type, upload_state) VALUES('pending-media', 'image', 'backgroundUploadTaskStarted')")
            .execute(&database.pool).await?;
        sqlx::query("INSERT INTO groups(group_id, group_name) VALUES('pending-group', 'Group')")
            .execute(&database.pool)
            .await?;
        sqlx::query("INSERT INTO messages(message_id, group_id, type, media_id) VALUES('pending-message', 'pending-group', 'media', 'pending-media')")
            .execute(&database.pool).await?;
        let mut job = reupload_test_job(&database, "pending-media", "pending-slot").await?;
        job.multipart_path = directory
            .path()
            .join("media.multipart")
            .display()
            .to_string();
        job.manifest_path = directory.path().join("manifest.pb").display().to_string();
        job.complete_body_path = directory.path().join("complete.pb").display().to_string();
        for path in [
            &job.multipart_path,
            &job.manifest_path,
            &job.complete_body_path,
        ] {
            std::fs::write(path, b"durable request")?;
        }
        sqlx::query("UPDATE direct_media_upload_jobs SET multipart_path = ?, manifest_path = ?, complete_body_path = ? WHERE attachment_id = ?")
            .bind(&job.multipart_path).bind(&job.manifest_path)
            .bind(&job.complete_body_path).bind(&job.attachment_id)
            .execute(&database.pool).await?;
        let service = DirectMediaUploadService::new(&ctx);
        for state in [
            AttachmentState::Unknown,
            AttachmentState::Reserved,
            AttachmentState::Uploading,
        ] {
            service
                .apply_status(
                    &job,
                    AttachmentStatus {
                        state: state as i32,
                        ..Default::default()
                    },
                )
                .await?;
            let ack: Option<i64> = sqlx::query_scalar(
                "SELECT ack_by_server FROM messages WHERE message_id = 'pending-message'",
            )
            .fetch_one(&database.pool)
            .await?;
            assert!(ack.is_none(), "{state:?} must not acknowledge the message");
            assert_eq!(service.pending_job_count().await?, 1);
            for path in [
                &job.multipart_path,
                &job.manifest_path,
                &job.complete_body_path,
            ] {
                assert!(
                    Path::new(path).exists(),
                    "{state:?} must keep request files"
                );
            }
        }
        for _ in 0..2 {
            service
                .apply_status(
                    &job,
                    AttachmentStatus {
                        state: AttachmentState::Ready as i32,
                        ..Default::default()
                    },
                )
                .await?;
        }
        let ack: Option<i64> = sqlx::query_scalar(
            "SELECT ack_by_server FROM messages WHERE message_id = 'pending-message'",
        )
        .fetch_one(&database.pool)
        .await?;
        assert!(ack.is_some());
        assert_eq!(service.pending_job_count().await?, 0);
        let state: String = sqlx::query_scalar(
            "SELECT upload_state FROM media_files WHERE media_id = 'pending-media'",
        )
        .fetch_one(&database.pool)
        .await?;
        assert_eq!(state, "uploaded");
        for path in [
            &job.multipart_path,
            &job.manifest_path,
            &job.complete_body_path,
        ] {
            assert!(
                !Path::new(path).exists(),
                "Ready must release request files"
            );
        }
        Ok(())
    }

    async fn upload_test_context(root: &Path, user_id: i64) -> anyhow::Result<Arc<Context>> {
        let data_dir = root.join("data");
        std::fs::create_dir_all(data_dir.join("keyvalue"))?;
        let config = UserConfig {
            user_id,
            username: format!("user-{user_id}"),
            display_name: format!("User {user_id}"),
            is_user_discovery_enabled: false,
            ..Default::default()
        };
        std::fs::write(
            data_dir.join("keyvalue/user.json"),
            serde_json::to_vec(&config)?,
        )?;
        let context = Context::init_for_testing(root.join("database"), data_dir).await?;
        let mut csprng = rand::rngs::StdRng::from_os_rng();
        let identity = IdentityKeyPair::generate(&mut csprng);
        let registration_id = rand::Rng::random::<u32>(&mut csprng) & 0x7fff_ffff;
        context
            .inject_test_signal_identity(identity.serialize().to_vec(), registration_id as i64)
            .await?;
        context.inject_test_user_id(user_id).await?;
        Ok(context)
    }

    #[tokio::test]
    async fn media_reupload_only_dispatches_requested_recipient_message_pairs() -> anyhow::Result<()>
    {
        let sender_dir = tempfile::tempdir()?;
        let receiver_dirs = [tempfile::tempdir()?, tempfile::tempdir()?];
        let sender = upload_test_context(sender_dir.path(), 42).await?;
        let mut receivers = Vec::new();
        let database = sender.app_db.read().await.clone();
        for (user_id, directory) in [7, 8].into_iter().zip(&receiver_dirs) {
            let receiver = upload_test_context(directory.path(), user_id).await?;
            let bundle = receiver
                .signal_engine
                .lock()
                .await
                .as_ref()
                .unwrap()
                .generate_bundle()
                .await?;
            sender
                .signal_engine
                .lock()
                .await
                .as_ref()
                .unwrap()
                .process_prekey_bundle(user_id.to_string(), 1, bundle)
                .await?;
            sqlx::query("INSERT INTO contacts(user_id, username, accepted, signal_version) VALUES(?, ?, 1, 'v2')")
                .bind(user_id).bind(format!("receiver-{user_id}"))
                .execute(&database.pool).await?;
            receivers.push(receiver);
        }
        let upload = MediaUploadService::new(&sender);
        let media_id = upload.initialize("image".into(), None, false).await?;
        let source = crate::services::mediafiles::MediaFileService::new(&sender)
            .temp_path(&media_id, "image");
        std::fs::create_dir_all(source.parent().unwrap())?;
        std::fs::write(&source, b"old group image")?;
        let created_at = chrono::Utc::now().timestamp() - 90 * 24 * 60 * 60;
        for group_id in ["original-group", "other-group"] {
            sqlx::query("INSERT INTO groups(group_id, group_name) VALUES(?, ?)")
                .bind(group_id)
                .bind(group_id)
                .execute(&database.pool)
                .await?;
            for contact_id in [7, 8] {
                sqlx::query("INSERT INTO group_members(group_id, contact_id) VALUES(?, ?)")
                    .bind(group_id)
                    .bind(contact_id)
                    .execute(&database.pool)
                    .await?;
            }
            sqlx::query("INSERT INTO messages(message_id, group_id, type, media_id, created_at) VALUES(?, ?, 'media', ?, ?)")
                .bind(group_id).bind(group_id).bind(&media_id).bind(created_at)
                .execute(&database.pool).await?;
        }

        let direct = DirectMediaUploadService::new(&sender);
        let (_, _, initial) = direct.prepare_media(&media_id).await?;
        assert_eq!(initial.dispatches.len(), 4);
        assert!(initial
            .dispatches
            .iter()
            .all(|dispatch| dispatch.push_data.is_some()));

        assert!(
            upload
                .record_reupload_request(7, &media_id, "original-group")
                .await?
        );
        let (_, _, repair) = direct.prepare_media(&media_id).await?;
        assert_eq!(repair.dispatches.len(), 1);
        assert_eq!(repair.dispatches[0].recipient_user_id, 7);
        assert!(repair.dispatches[0].push_data.is_none());

        // Requests survive a preparation retry and remain tied to their own
        // messages even when both contacts belong to both chats.
        assert!(
            upload
                .record_reupload_request(8, &media_id, "other-group")
                .await?
        );
        assert!(
            upload
                .record_reupload_request(7, &media_id, "original-group")
                .await?
        );
        assert!(
            !upload
                .record_reupload_request(99, &media_id, "original-group")
                .await?
        );
        let (_, _, repair) = direct.prepare_media(&media_id).await?;
        assert_eq!(repair.dispatches.len(), 2);
        for dispatch in &repair.dispatches {
            let receiver = &receivers[if dispatch.recipient_user_id == 7 {
                0
            } else {
                1
            }];
            let envelope =
                crate::api::proto::client::Message::decode(dispatch.encrypted_body.as_slice())?;
            let plaintext = receiver
                .signal_engine
                .lock()
                .await
                .as_ref()
                .unwrap()
                .decrypt_message("42".into(), 1, envelope.encrypted_content.unwrap())
                .await?;
            let content = EncryptedContent::decode(plaintext.as_slice())?;
            let expected = if dispatch.recipient_user_id == 7 {
                "original-group"
            } else {
                "other-group"
            };
            assert_eq!(content.group_id.as_deref(), Some(expected));
            let media = content.media.unwrap();
            assert_eq!(media.sender_message_id, expected);
            assert_eq!(media.timestamp, created_at * 1_000);
        }

        // Legacy queues have no message scope, but still cannot broadcast to
        // contacts outside their saved requester list.
        for legacy in ["[7]", "7"] {
            sqlx::query("UPDATE media_files SET reupload_targets = NULL, reupload_requested_by = ? WHERE media_id = ?")
                .bind(legacy).bind(&media_id).execute(&database.pool).await?;
            let (_, _, repair) = direct.prepare_media(&media_id).await?;
            assert_eq!(repair.dispatches.len(), 2);
            assert!(repair
                .dispatches
                .iter()
                .all(|dispatch| dispatch.recipient_user_id == 7));
        }
        for invalid in ["[]", "invalid"] {
            sqlx::query("UPDATE media_files SET reupload_requested_by = ? WHERE media_id = ?")
                .bind(invalid)
                .bind(&media_id)
                .execute(&database.pool)
                .await?;
            assert!(direct.prepare_media(&media_id).await.is_err());
        }
        for invalid in ["[]", "invalid"] {
            sqlx::query("UPDATE media_files SET reupload_targets = ?, reupload_requested_by = NULL WHERE media_id = ?")
                .bind(invalid).bind(&media_id).execute(&database.pool).await?;
            assert!(direct.prepare_media(&media_id).await.is_err());
        }
        Ok(())
    }

    async fn reupload_test_job(
        database: &AppDatabase,
        media_id: &str,
        attachment_id: &str,
    ) -> anyhow::Result<PendingJob> {
        sqlx::query(
            r#"INSERT INTO direct_media_upload_slots
               (attachment_id, expires_at, maximum_object_bytes, upload_url,
                upload_fields_json, capability, state)
               VALUES(?, 9999999999, 1000000, 'https://objects.example', '{}', x'01', 'reserved')"#,
        )
        .bind(attachment_id)
        .execute(&database.pool)
        .await?;
        sqlx::query(
            r#"INSERT INTO direct_media_upload_jobs
               (attachment_id, media_id, multipart_path, manifest_path, complete_body_path,
                native_descriptor_json, state, expires_at, reupload_requested_by, reupload_targets)
               SELECT ?, media_id, '', '', '', '{}', 'scheduled', 9999999999,
                      reupload_requested_by, reupload_targets FROM media_files WHERE media_id = ?"#,
        )
        .bind(attachment_id)
        .bind(media_id)
        .execute(&database.pool)
        .await?;
        Ok(sqlx::query_as::<_, PendingJob>(
            r#"SELECT j.attachment_id, j.media_id, j.multipart_path, j.manifest_path,
                      j.complete_body_path, s.capability, j.expires_at,
                      j.reupload_requested_by, j.reupload_targets
               FROM direct_media_upload_jobs j
               JOIN direct_media_upload_slots s ON s.attachment_id = j.attachment_id
               WHERE j.attachment_id = ?"#,
        )
        .bind(attachment_id)
        .fetch_one(&database.pool)
        .await?)
    }

    #[tokio::test]
    async fn native_recovery_preserves_job_and_does_not_repeat_within_interval(
    ) -> anyhow::Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx = upload_test_context(directory.path(), 42).await?;
        let database = ctx.app_db.read().await.clone();
        sqlx::query("INSERT INTO media_files(media_id, type) VALUES('recover-media', 'image')")
            .execute(&database.pool)
            .await?;
        let job = reupload_test_job(&database, "recover-media", "recover-slot").await?;
        sqlx::query("UPDATE direct_media_upload_jobs SET updated_at = 0 WHERE attachment_id = 'recover-slot'")
            .execute(&database.pool).await?;
        let service = DirectMediaUploadService::new(&ctx);
        service.recover_native_transfer(&job).await?;
        let first: (String, String, i64) = sqlx::query_as(
            "SELECT attachment_id, native_descriptor_json, updated_at FROM direct_media_upload_jobs WHERE media_id = 'recover-media'",
        ).fetch_one(&database.pool).await?;
        assert_eq!(first.0, "recover-slot");
        assert_eq!(first.1, "{}");
        assert!(first.2 > 0);
        // An intervening claim recent enough to skip recovery must stay intact.
        sqlx::query("UPDATE direct_media_upload_jobs SET updated_at = updated_at + 1 WHERE attachment_id = 'recover-slot'")
            .execute(&database.pool).await?;
        service.recover_native_transfer(&job).await?;
        let second: i64 = sqlx::query_scalar(
            "SELECT updated_at FROM direct_media_upload_jobs WHERE attachment_id = 'recover-slot'",
        )
        .fetch_one(&database.pool)
        .await?;
        assert_eq!(second, first.2 + 1);
        sqlx::query("DELETE FROM direct_media_upload_jobs WHERE attachment_id = 'recover-slot'")
            .execute(&database.pool)
            .await?;
        // A stale reconciliation snapshot cannot resurrect a settled job.
        service.recover_native_transfer(&job).await?;
        assert_eq!(service.pending_job_count().await?, 0);
        Ok(())
    }

    #[tokio::test]
    async fn media_reupload_completion_preserves_retries_and_newer_requests() -> anyhow::Result<()>
    {
        let directory = tempfile::tempdir()?;
        let sender = upload_test_context(directory.path(), 42).await?;
        let database = sender.app_db.read().await.clone();
        let upload = MediaUploadService::new(&sender);
        let media_id = upload.initialize("image".into(), None, false).await?;
        for statement in [
            "INSERT INTO contacts(user_id, username) VALUES(7, 'receiver-7'), (8, 'receiver-8')",
            "INSERT INTO groups(group_id, group_name) VALUES('group', 'Group')",
            "INSERT INTO group_members(group_id, contact_id) VALUES('group', 7), ('group', 8)",
        ] {
            sqlx::query(statement).execute(&database.pool).await?;
        }
        sqlx::query("INSERT INTO messages(message_id, group_id, type, media_id) VALUES('message', 'group', 'media', ?)")
            .bind(&media_id).execute(&database.pool).await?;
        assert!(
            upload
                .record_reupload_request(7, &media_id, "message")
                .await?
        );
        let direct = DirectMediaUploadService::new(&sender);
        let retry = reupload_test_job(&database, &media_id, "retry").await?;
        direct.settle(&retry, Outcome::Retry).await?;
        let media = sqlx::query_as::<_, (String, Option<String>)>(
            "SELECT upload_state, reupload_targets FROM media_files WHERE media_id = ?",
        )
        .bind(&media_id)
        .fetch_one(&database.pool)
        .await?;
        assert_eq!(media.0, "preprocessing");
        assert_eq!(media.1, retry.reupload_targets);

        let older = reupload_test_job(&database, &media_id, "older").await?;
        assert!(
            upload
                .record_reupload_request(8, &media_id, "message")
                .await?
        );
        let newer = reupload_test_job(&database, &media_id, "newer").await?;
        direct.settle(&older, Outcome::Uploaded).await?;
        let pending = sqlx::query_scalar::<_, Option<String>>(
            "SELECT reupload_targets FROM media_files WHERE media_id = ?",
        )
        .bind(&media_id)
        .fetch_one(&database.pool)
        .await?;
        assert_eq!(pending, newer.reupload_targets);
        // The older success set the shared media row to uploaded. A failed
        // newer repair still needs to resume with its saved recipient scope.
        direct.settle(&newer, Outcome::Retry).await?;
        let state = sqlx::query_scalar::<_, String>(
            "SELECT upload_state FROM media_files WHERE media_id = ?",
        )
        .bind(&media_id)
        .fetch_one(&database.pool)
        .await?;
        assert_eq!(state, "preprocessing");
        let completed = reupload_test_job(&database, &media_id, "completed").await?;
        direct.settle(&completed, Outcome::Uploaded).await?;
        let cleared = sqlx::query_as::<_, (Option<String>, Option<String>)>(
            "SELECT reupload_requested_by, reupload_targets FROM media_files WHERE media_id = ?",
        )
        .bind(&media_id)
        .fetch_one(&database.pool)
        .await?;
        assert_eq!(cleared, (None, None));

        // A later repair must not include contacts from a completed repair.
        assert!(
            upload
                .record_reupload_request(8, &media_id, "message")
                .await?
        );
        let requesters = sqlx::query_scalar::<_, String>(
            "SELECT reupload_requested_by FROM media_files WHERE media_id = ?",
        )
        .bind(&media_id)
        .fetch_one(&database.pool)
        .await?;
        assert_eq!(requesters, "[8]");
        Ok(())
    }

    #[tokio::test]
    async fn story_upload_preparation_encrypts_media_and_dispatch_payload() -> anyhow::Result<()> {
        let sender_dir = tempfile::tempdir()?;
        let receiver_dir = tempfile::tempdir()?;
        let sender = upload_test_context(sender_dir.path(), 42).await?;
        let receiver = upload_test_context(receiver_dir.path(), 7).await?;

        let receiver_bundle = receiver
            .signal_engine
            .lock()
            .await
            .as_ref()
            .unwrap()
            .generate_bundle()
            .await?;
        sender
            .signal_engine
            .lock()
            .await
            .as_ref()
            .unwrap()
            .process_prekey_bundle("7".into(), 1, receiver_bundle)
            .await?;

        let upload = MediaUploadService::new(&sender);
        let media_id = upload.initialize("image".into(), None, false).await?;
        let original = b"story image bytes";
        let source = crate::services::mediafiles::MediaFileService::new(&sender)
            .temp_path(&media_id, "image");
        if let Some(parent) = source.parent() {
            std::fs::create_dir_all(parent)?;
        }
        std::fs::write(&source, original)?;

        let database = sender.app_db.read().await.clone();
        sqlx::query(
            "INSERT INTO contacts(user_id, username, accepted, signal_version) VALUES(7, 'receiver', 1, 'v2')",
        )
        .execute(&database.pool)
        .await?;
        // They wrote to each other recently, so the story wakes the receiver.
        sqlx::query(
            "INSERT INTO groups(group_id, group_name, is_direct_chat, last_text_or_media_at) VALUES('direct-7', 'Receiver', 1, CAST(strftime('%s','now') AS INTEGER))",
        )
        .execute(&database.pool)
        .await?;
        sqlx::query("INSERT INTO group_members(group_id, contact_id) VALUES('direct-7', 7)")
            .execute(&database.pool)
            .await?;
        let created_at = chrono::Utc::now().timestamp();
        sqlx::query(
            r#"INSERT INTO messages
               (message_id, group_id, type, media_id, is_story, created_at)
               VALUES('story-message', 'direct-7', 'media', ?, 1, ?)"#,
        )
        .bind(&media_id)
        .bind(created_at)
        .execute(&database.pool)
        .await?;
        drop(database);

        let (encrypted_path, encrypted_size, manifest) = DirectMediaUploadService::new(&sender)
            .prepare_media(&media_id)
            .await?;

        let encrypted_media = std::fs::read(encrypted_path)?;
        assert_eq!(encrypted_size, original.len() as i64);
        assert_ne!(encrypted_media, original);
        assert_eq!(manifest.dispatches.len(), 1);
        let dispatch = &manifest.dispatches[0];
        assert_eq!(dispatch.recipient_user_id, 7);
        assert_eq!(dispatch.push_data.as_deref(), Some([1].as_slice()));

        let envelope =
            crate::api::proto::client::Message::decode(dispatch.encrypted_body.as_slice())?;
        assert_eq!(
            envelope.r#type,
            crate::api::proto::client::message::Type::CiphertextV2 as i32
        );
        let plaintext = receiver
            .signal_engine
            .lock()
            .await
            .as_ref()
            .unwrap()
            .decrypt_message(
                "42".into(),
                1,
                envelope
                    .encrypted_content
                    .expect("encrypted story envelope"),
            )
            .await?;
        let content = EncryptedContent::decode(plaintext.as_slice())?;
        let story = content.story.expect("story payload");
        assert!(story.notify);
        let media = story.media.expect("story media payload");
        assert_eq!(media.sender_message_id, "story-message");
        assert_eq!(media.timestamp, created_at * 1_000);
        assert_eq!(media.download_token, Some(dispatch.download_token.clone()));
        assert_eq!(media.encryption_key.as_deref().map(<[u8]>::len), Some(32));
        assert_eq!(media.encryption_nonce.as_deref().map(<[u8]>::len), Some(12));
        assert_eq!(media.encryption_mac.as_deref().map(<[u8]>::len), Some(16));
        Ok(())
    }

    #[test]
    fn cancelled_watcher_releases_process_claim() {
        let watch = UploadWatch::new();
        watch.watching.store(true, Ordering::SeqCst);
        drop(WatchingGuard(&watch));
        assert!(!watch.watching.load(Ordering::SeqCst));
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

    #[tokio::test]
    async fn usable_slot_count_and_reserve_accept_unexpired_slots() {
        let directory = tempfile::tempdir().unwrap();
        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await
        .unwrap();
        let service = DirectMediaUploadService::new(&ctx);

        // Slot expiring in 1 hour (which is < 24 hours)
        let soon = chrono::Utc::now().timestamp() + 3600;
        let database = ctx.app_db.read().await.clone();
        sqlx::query(
            r#"INSERT INTO direct_media_upload_slots
               (attachment_id, expires_at, maximum_object_bytes, upload_url,
                upload_fields_json, capability, state)
               VALUES('slot-1', ?, 1000000, 'https://objects.example', '{}', x'01', 'cached')"#,
        )
        .bind(soon)
        .execute(&database.pool)
        .await
        .unwrap();

        assert_eq!(service.usable_slot_count().await.unwrap(), 1);

        // Slot should be successfully reserved even though remaining TTL < 24 hours
        let mut transaction = database.pool.begin().await.unwrap();
        let slot = sqlx::query_as::<_, CachedSlot>(
            r#"UPDATE direct_media_upload_slots SET state = 'reserved'
               WHERE attachment_id = (
                 SELECT attachment_id FROM direct_media_upload_slots
                 WHERE state = 'cached'
                   AND expires_at > CAST(strftime('%s','now') AS INTEGER)
                 ORDER BY expires_at ASC LIMIT 1
               )
               RETURNING attachment_id, expires_at, maximum_object_bytes, upload_url,
                         upload_fields_json, capability"#,
        )
        .fetch_optional(&mut *transaction)
        .await
        .unwrap();
        transaction.commit().await.unwrap();

        assert!(slot.is_some());
        assert_eq!(slot.unwrap().attachment_id, "slot-1");
    }

    #[tokio::test]
    async fn reconcile_reclaims_orphaned_reserved_slots() {
        let directory = tempfile::tempdir().unwrap();
        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await
        .unwrap();
        let service = DirectMediaUploadService::new(&ctx);

        let database = ctx.app_db.read().await.clone();
        sqlx::query(
            r#"INSERT INTO direct_media_upload_slots
               (attachment_id, expires_at, maximum_object_bytes, upload_url,
                upload_fields_json, capability, state)
               VALUES('orphaned-slot', 9999999999, 1000000, 'https://objects.example', '{}', x'01', 'reserved')"#,
        )
        .execute(&database.pool)
        .await
        .unwrap();

        assert_eq!(service.usable_slot_count().await.unwrap(), 0);

        service.reconcile().await.unwrap();

        assert_eq!(service.usable_slot_count().await.unwrap(), 1);
        let state = sqlx::query_scalar::<_, String>(
            "SELECT state FROM direct_media_upload_slots WHERE attachment_id = 'orphaned-slot'",
        )
        .fetch_one(&database.pool)
        .await
        .unwrap();
        assert_eq!(state, "cached");
    }

    #[tokio::test]
    async fn stale_media_jobs_are_cleaned_up_and_slots_cached() {
        let directory = tempfile::tempdir().unwrap();
        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await
        .unwrap();
        let service = DirectMediaUploadService::new(&ctx);

        let job_dir = directory.path().join("data/direct-media-upload/slot-stale");
        std::fs::create_dir_all(&job_dir).unwrap();
        let multipart = job_dir.join("media.multipart");
        let manifest = job_dir.join("manifest.pb");
        let complete = job_dir.join("complete.pb");
        for p in [&multipart, &manifest, &complete] {
            std::fs::write(p, b"data").unwrap();
        }

        let database = ctx.app_db.read().await.clone();
        sqlx::query(
            r#"INSERT INTO direct_media_upload_slots
               (attachment_id, expires_at, maximum_object_bytes, upload_url,
                upload_fields_json, capability, state)
               VALUES('slot-stale', 9999999999, 1000000, 'https://objects.example', '{}', x'01', 'reserved')"#,
        )
        .execute(&database.pool)
        .await
        .unwrap();

        sqlx::query(
            r#"INSERT INTO direct_media_upload_jobs
               (attachment_id, media_id, multipart_path, manifest_path,
                complete_body_path, native_descriptor_json, state, expires_at)
               VALUES('slot-stale', 'media-stale', ?, ?, ?, '{}', 'scheduled', 9999999999)"#,
        )
        .bind(multipart.to_string_lossy().as_ref())
        .bind(manifest.to_string_lossy().as_ref())
        .bind(complete.to_string_lossy().as_ref())
        .execute(&database.pool)
        .await
        .unwrap();

        assert_eq!(service.usable_slot_count().await.unwrap(), 0);

        service.cleanup_stale_media_jobs("media-stale").await;

        assert_eq!(service.usable_slot_count().await.unwrap(), 1);
        assert!(!multipart.exists());
        assert!(!job_dir.exists());
    }

    #[tokio::test]
    async fn known_slot_ids_include_in_flight_reservations() {
        let directory = tempfile::tempdir().unwrap();
        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await
        .unwrap();
        let service = DirectMediaUploadService::new(&ctx);

        let database = ctx.app_db.read().await.clone();
        let expired = chrono::Utc::now().timestamp() - 60;
        for (attachment_id, state, expires_at) in [
            ("slot-cached", "cached", 9999999999),
            ("slot-reserved", "reserved", 9999999999),
            ("slot-consumed", "consumed", 9999999999),
            ("slot-expired", "cached", expired),
        ] {
            sqlx::query(
                r#"INSERT INTO direct_media_upload_slots
                   (attachment_id, expires_at, maximum_object_bytes, upload_url,
                    upload_fields_json, capability, state)
                   VALUES(?, ?, 1000000, 'https://objects.example', '{}', x'01', ?)"#,
            )
            .bind(attachment_id)
            .bind(expires_at)
            .bind(state)
            .execute(&database.pool)
            .await
            .unwrap();
        }

        let mut known = service.locally_known_slot_ids().await.unwrap();
        known.sort();

        // The reserved slot is the one an upload is running against: leaving it
        // out makes the server abandon the transfer as `not_in_client_cache`.
        assert_eq!(known, vec!["slot-cached", "slot-reserved"]);
    }

    fn story_row(message_id: &str, created_at: i64) -> MessageRow {
        MessageRow {
            group_id: "d".into(),
            message_id: message_id.into(),
            created_at,
            quotes_message_id: None,
            additional_message_data: None,
            is_widget_media: 0,
            is_story: 1,
        }
    }

    #[tokio::test]
    async fn only_the_first_story_of_a_day_wakes_its_recipient() {
        let directory = tempfile::tempdir().unwrap();
        let database_path = directory.path().join("app.sqlite");
        let database = AppDatabase::new(database_path.to_str().unwrap(), None, false)
            .await
            .unwrap();
        database.run_migrations().await.unwrap();
        let now = 1_000_000_000;
        let expired = now - STORY_LIFETIME_SECONDS - 60;
        for statement in [
            "INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'anna', 1)".to_owned(),
            format!("INSERT INTO groups(group_id, group_name, is_direct_chat, last_text_or_media_at) VALUES ('d', 'Anna', 1, {}), ('trip', 'Trip', 0, NULL)", now - 3600),
            "INSERT INTO group_members(group_id, contact_id) VALUES ('d', 7), ('trip', 7)".to_owned(),
            "INSERT INTO media_files(media_id, type) VALUES ('old', 'image'), ('first', 'image'), ('second', 'image'), ('twin', 'image')".to_owned(),
            format!("INSERT INTO messages(message_id, group_id, type, media_id, is_story, created_at) VALUES ('old', 'd', 'media', 'old', 1, {expired})"),
            format!("INSERT INTO messages(message_id, group_id, type, media_id, is_story, created_at) VALUES ('first', 'd', 'media', 'first', 1, {})", now - 120),
            format!("INSERT INTO messages(message_id, group_id, type, media_id, is_story, created_at) VALUES ('second', 'd', 'media', 'second', 1, {now})"),
            format!("INSERT INTO messages(message_id, group_id, type, media_id, is_story, created_at) VALUES ('twin', 'd', 'media', 'twin', 1, {now})"),
        ] {
            sqlx::query(sqlx::AssertSqlSafe(statement))
                .execute(&database.pool)
                .await
                .unwrap();
        }
        let wakes = |row: MessageRow, media_id: &'static str| {
            let database = &database;
            async move {
                story_wakes_recipient(database, &row, media_id, 7, now)
                    .await
                    .unwrap()
            }
        };

        // An expired story does not count against the first one of a new day.
        assert!(wakes(story_row("first", now - 120), "first").await);
        assert!(!wakes(story_row("second", now), "second").await);
        // Two items posted in the same second: exactly one of them is first
        // once the older one is gone.
        sqlx::query("DELETE FROM messages WHERE message_id = 'first'")
            .execute(&database.pool)
            .await
            .unwrap();
        assert!(wakes(story_row("second", now), "second").await);
        assert!(!wakes(story_row("twin", now), "twin").await);

        // A direct copy of the same media already wakes the recipient.
        sqlx::query(
            "INSERT INTO messages(message_id, group_id, type, media_id) VALUES ('direct', 'trip', 'media', 'second')",
        )
        .execute(&database.pool)
        .await
        .unwrap();
        assert!(!wakes(story_row("second", now), "second").await);
        sqlx::query("DELETE FROM messages WHERE message_id = 'direct'")
            .execute(&database.pool)
            .await
            .unwrap();

        // Preparing an item again after it reached the server does not
        // announce it a second time.
        sqlx::query(
            "INSERT INTO message_actions(message_id, contact_id, type) VALUES ('second', 7, 'ackByServerAt')",
        )
        .execute(&database.pool)
        .await
        .unwrap();
        assert!(!wakes(story_row("second", now), "second").await);

        // Two weeks without a text or media message between them: the
        // recipient would not announce it, so they are not woken for it.
        sqlx::query("DELETE FROM message_actions")
            .execute(&database.pool)
            .await
            .unwrap();
        assert!(wakes(story_row("second", now), "second").await);
        sqlx::query(sqlx::AssertSqlSafe(format!(
            "UPDATE groups SET last_text_or_media_at = {} WHERE group_id = 'd'",
            now - STORY_ANNOUNCE_RECENT_EXCHANGE_SECONDS - 60
        )))
        .execute(&database.pool)
        .await
        .unwrap();
        assert!(!wakes(story_row("second", now), "second").await);
    }
}
