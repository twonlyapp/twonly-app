/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! The app's side of the memories importer.
//!
//! - Pairing: the page shows `https://me.twonly.eu/i/#v1/<pairing_id>/<key>`.
//!   [`claim`] seals a grant (an import-scoped wrap key, the id key, a fresh
//!   upload token and this account's name) to the page's X25519 key and
//!   claims the pairing on the server, which hands the envelope to the page.
//! - Discovery: [`reconcile_imported_memories`] pages through the server's
//!   memories list, and for every imported memory this device does not know
//!   yet downloads the thumbnail, checks it like any untrusted upload,
//!   decrypts its metadata and adds it to the gallery.
//!
//! Every imported payload must carry `addition = "import_<importer_id>"` for
//! the importer the server lists it under, unwrap under this account's main
//! key, and authenticate; anything else is skipped and recorded, never
//! deleted automatically.

use crate::api::Server;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::database::app::mediafiles::table::MediaFilePatch;
use crate::database::app::patch::NullableReal;
use crate::error::{Result, TwonlyError};
use crate::keys::MainKey;
use crate::services::mediafiles::MediaFileService;
use crate::services::memory_import_progress;
use crate::user_config::UserConfig;
use base64::Engine as _;
use chacha20poly1305::aead::{Aead, KeyInit, Payload};
use chacha20poly1305::{ChaCha20Poly1305, Nonce, XChaCha20Poly1305, XNonce};
use hkdf::Hkdf;
use prost::Message as _;
use rand::TryRngCore;
use sha2::{Digest, Sha256};
use std::collections::HashSet;
use std::sync::Arc;
use uuid::Uuid;
use zeroize::Zeroize;

pub const PAIRING_LINK_PREFIX: &str = "https://me.twonly.eu/i/#v1/";
const PAIRING_INFO: &[u8] = b"twonly importer pairing v1";
const GRANT_VERSION: u32 = 1;
const GRANT_SECONDS: i64 = 2 * 24 * 60 * 60;
const THUMBNAIL_MAX_PAYLOAD: usize = 400_000;
// Largest single-media plan cap plus the server's 100 KB upload allowance.
// Keep in sync with MemoriesCloudService's encrypted response limit.
const FULL_MEDIA_MAX_PAYLOAD: usize = 100_000_000 + 100_000;
const THUMBNAIL_MAX_SIDE: u32 = 2048;
const LIST_PAGE: i64 = 50;
/// Far enough in the future to start the newest-first list at the top.
const LIST_START: i64 = 4_102_444_800;
const SOURCE_NAMES: &[(&str, &str)] = &[("snapchat", "Snapchat")];

/// What the page receives, sealed. Matches `proto/importer.proto` of the page.
#[derive(Clone, PartialEq, prost::Message)]
pub struct ImporterGrant {
    #[prost(uint32, tag = "1")]
    pub version: u32,
    #[prost(string, tag = "2")]
    pub import_id: String,
    #[prost(string, tag = "3")]
    pub addition: String,
    #[prost(bytes = "vec", tag = "4")]
    pub kek: Vec<u8>,
    #[prost(bytes = "vec", tag = "5")]
    pub id_key: Vec<u8>,
    #[prost(bytes = "vec", tag = "6")]
    pub importer_token: Vec<u8>,
    #[prost(string, tag = "7")]
    pub username: String,
    #[prost(string, tag = "8")]
    pub display_name: String,
    #[prost(int64, tag = "9")]
    pub expires_at: i64,
}

impl Drop for ImporterGrant {
    fn drop(&mut self) {
        self.kek.zeroize();
        self.id_key.zeroize();
        self.importer_token.zeroize();
    }
}

#[derive(Clone, PartialEq, prost::Message)]
pub struct ImporterEnvelope {
    #[prost(bytes = "vec", tag = "1")]
    pub e_pub: Vec<u8>,
    #[prost(bytes = "vec", tag = "2")]
    pub nonce: Vec<u8>,
    #[prost(bytes = "vec", tag = "3")]
    pub ciphertext: Vec<u8>,
}

/// Inside the thumbnail payload's `encrypted_metadata`.
#[derive(Clone, PartialEq, prost::Message)]
pub struct ImportedMemoryMetadata {
    #[prost(string, tag = "1")]
    pub source: String,
    /// 1 image, 2 video.
    #[prost(uint32, tag = "2")]
    pub media_type: u32,
    /// Unix seconds.
    #[prost(int64, tag = "3")]
    pub created_at: i64,
    #[prost(double, optional, tag = "4")]
    pub latitude: Option<f64>,
    #[prost(double, optional, tag = "5")]
    pub longitude: Option<f64>,
    #[prost(bool, tag = "6")]
    pub had_overlay: bool,
}

/// The cloud payload, with the importer's optional metadata field.
#[derive(Clone, PartialEq, prost::Message)]
pub struct CloudMediaBackupEncrypted {
    #[prost(string, tag = "1")]
    pub addition: String,
    #[prost(bytes = "vec", tag = "2")]
    pub encrypted_media_key: Vec<u8>,
    #[prost(bytes = "vec", tag = "3")]
    pub media_nonce: Vec<u8>,
    #[prost(bytes = "vec", tag = "4")]
    pub media_ciphertext: Vec<u8>,
    #[prost(bytes = "vec", optional, tag = "5")]
    pub encrypted_metadata: Option<Vec<u8>>,
}

fn error(message: &str) -> TwonlyError {
    TwonlyError::Generic(message.into())
}

fn random<const N: usize>() -> [u8; N] {
    let mut bytes = [0_u8; N];
    rand::rngs::OsRng
        .try_fill_bytes(&mut bytes)
        .expect("OS randomness unavailable");
    bytes
}

/// `(pairing_id, page public key)` from a pairing link.
pub fn parse_pairing_link(link: &str) -> Result<(Uuid, [u8; 32])> {
    let rest = link
        .strip_prefix(PAIRING_LINK_PREFIX)
        .ok_or_else(|| error("not a pairing link"))?;
    let (id, key) = rest
        .split_once('/')
        .ok_or_else(|| error("not a pairing link"))?;
    let pairing_id = Uuid::parse_str(id).map_err(|_| error("not a pairing link"))?;
    if pairing_id.get_version_num() != 4 || pairing_id.hyphenated().to_string() != id {
        return Err(error("not a pairing link"));
    }
    if key.len() != 43 {
        return Err(error("not a pairing link"));
    }
    let key = base64::engine::general_purpose::URL_SAFE_NO_PAD
        .decode(key)
        .map_err(|_| error("not a pairing link"))?;
    let key: [u8; 32] = key.try_into().map_err(|_| error("not a pairing link"))?;
    Ok((pairing_id, key))
}

fn pairing_key(shared: &[u8], pairing_id: &str, e_pub: &[u8], p_pub: &[u8]) -> [u8; 32] {
    let salt = [e_pub, p_pub].concat();
    let info = [PAIRING_INFO, pairing_id.as_bytes()].concat();
    let mut key = [0_u8; 32];
    Hkdf::<Sha256>::new(Some(&salt), shared)
        .expand(&info, &mut key)
        .expect("32 bytes is a valid HKDF length");
    key
}

/// Seals `grant` to the page's key: ephemeral X25519, HKDF-SHA256 and
/// XChaCha20-Poly1305 bound to the pairing id and both public keys.
pub fn seal_envelope(pairing_id: &Uuid, page_public: &[u8; 32], grant: &[u8]) -> Result<Vec<u8>> {
    let pairing_id = pairing_id.hyphenated().to_string();
    let secret = x25519_dalek::StaticSecret::from(random::<32>());
    let e_pub = x25519_dalek::PublicKey::from(&secret).to_bytes();
    let shared = secret.diffie_hellman(&x25519_dalek::PublicKey::from(*page_public));
    if shared.as_bytes().iter().all(|byte| *byte == 0) {
        return Err(error("the page key is not usable"));
    }
    let mut key = pairing_key(shared.as_bytes(), &pairing_id, &e_pub, page_public);
    let nonce = random::<24>();
    let aad = [pairing_id.as_bytes(), &e_pub, page_public].concat();
    let ciphertext = XChaCha20Poly1305::new(&key.into())
        .encrypt(
            &XNonce::try_from(&nonce[..]).expect("24 bytes"),
            Payload {
                msg: grant,
                aad: &aad,
            },
        )
        .map_err(|_| error("sealing failed"))?;
    key.zeroize();
    Ok(ImporterEnvelope {
        e_pub: e_pub.to_vec(),
        nonce: nonce.to_vec(),
        ciphertext,
    }
    .encode_to_vec())
}

/// The page's side of [`seal_envelope`]. The app never opens envelopes; the
/// tests use this to check both implementations agree.
pub fn open_envelope(
    pairing_id: &Uuid, page_private: [u8; 32], envelope: &[u8],
) -> Result<Vec<u8>> {
    let pairing_id = pairing_id.hyphenated().to_string();
    let envelope = ImporterEnvelope::decode(envelope).map_err(|_| error("invalid envelope"))?;
    let e_pub: [u8; 32] = envelope
        .e_pub
        .as_slice()
        .try_into()
        .map_err(|_| error("invalid envelope"))?;
    if envelope.nonce.len() != 24 {
        return Err(error("invalid envelope"));
    }
    let secret = x25519_dalek::StaticSecret::from(page_private);
    let p_pub = x25519_dalek::PublicKey::from(&secret).to_bytes();
    let shared = secret.diffie_hellman(&x25519_dalek::PublicKey::from(e_pub));
    if shared.as_bytes().iter().all(|byte| *byte == 0) {
        return Err(error("invalid envelope"));
    }
    let key = pairing_key(shared.as_bytes(), &pairing_id, &e_pub, &p_pub);
    let aad = [pairing_id.as_bytes(), &e_pub, &p_pub].concat();
    XChaCha20Poly1305::new(&key.into())
        .decrypt(
            &XNonce::try_from(&envelope.nonce[..]).expect("24 bytes"),
            Payload {
                msg: &envelope.ciphertext,
                aad: &aad,
            },
        )
        .map_err(|_| error("the envelope could not be opened"))
}

/// Builds the grant for one import from this account's main key.
pub fn build_grant(
    main_key: &MainKey, import_id: Uuid, importer_token: [u8; 32], username: &str,
    display_name: &str, now: i64,
) -> Result<ImporterGrant> {
    Ok(ImporterGrant {
        version: GRANT_VERSION,
        import_id: import_id.hyphenated().to_string(),
        addition: MainKey::import_addition(import_id),
        kek: main_key.export_import_wrap_key(import_id)?.to_vec(),
        id_key: main_key.derive_import_id_key().to_vec(),
        importer_token: importer_token.to_vec(),
        username: username.to_owned(),
        display_name: display_name.to_owned(),
        expires_at: now + GRANT_SECONDS,
    })
}

#[derive(Debug, Clone)]
pub struct ClaimedImporter {
    pub import_id: String,
    pub expires_at: i64,
}

/// Claims the pairing behind `link` for this account. Call only from the
/// connect screen, after the user confirmed, and only for links from the
/// scanner or a system-camera open.
pub async fn claim(ctx: &Arc<Context>, link: &str) -> Result<ServerResult<ClaimedImporter>> {
    let (pairing_id, page_public) = parse_pairing_link(link)?;
    let import_id = Uuid::new_v4();
    let mut token = random::<32>();
    let config = UserConfig::load_required_from(ctx)?;
    let now = chrono::Utc::now().timestamp();
    let grant = {
        let key_manager = ctx.key_manager.lock().await;
        build_grant(
            &key_manager.main_key,
            import_id,
            token,
            &config.username,
            &config.display_name,
            now,
        )?
    };
    let mut grant_bytes = grant.encode_to_vec();
    let envelope = seal_envelope(&pairing_id, &page_public, &grant_bytes);
    grant_bytes.zeroize();
    let token_hash = Sha256::digest(token).to_vec();
    token.zeroize();
    let result = Server::claim_importer_pairing(
        ctx,
        pairing_id.hyphenated().to_string(),
        envelope?,
        import_id.hyphenated().to_string(),
        token_hash,
    )
    .await?;
    Ok(match result {
        ServerResult::Ok(()) => ServerResult::Ok(ClaimedImporter {
            import_id: import_id.hyphenated().to_string(),
            expires_at: grant.expires_at,
        }),
        ServerResult::ErrorCode(code) => ServerResult::ErrorCode(code),
    })
}

/// The `addition` a payload must carry: `"app"` for the app's own memories,
/// the canonical `"import_<uuid>"` for an importer's.
pub fn expected_addition(importer_id: Option<&str>) -> Result<String> {
    match importer_id {
        None => Ok("app".into()),
        Some(id) => {
            let uuid = Uuid::parse_str(id).map_err(|_| error("invalid importer id"))?;
            if uuid.hyphenated().to_string() != id || uuid.get_version_num() != 4 {
                return Err(error("invalid importer id"));
            }
            Ok(MainKey::import_addition(uuid))
        }
    }
}

/// Why an imported memory could not be shown. Permanent failures are not
/// retried: the payload itself is wrong.
#[derive(Debug, Clone, PartialEq)]
pub enum OpenError {
    Malformed,
    WrongAddition,
    KeyUnwrap,
    Decrypt,
    Metadata,
    Image,
}

impl OpenError {
    pub fn permanent(&self) -> bool {
        true
    }

    pub fn reason(&self) -> &'static str {
        match self {
            OpenError::Malformed => "malformed payload",
            OpenError::WrongAddition => "wrong addition",
            OpenError::KeyUnwrap => "key does not unwrap",
            OpenError::Decrypt => "content does not authenticate",
            OpenError::Metadata => "invalid metadata",
            OpenError::Image => "thumbnail is not a valid image",
        }
    }
}

fn chacha_open(
    key: &[u8; 32], nonce: &[u8], sealed: &[u8],
) -> std::result::Result<Vec<u8>, OpenError> {
    if nonce.len() != 12 || sealed.len() < 16 {
        return Err(OpenError::Malformed);
    }
    ChaCha20Poly1305::new(&(*key).into())
        .decrypt(
            &Nonce::try_from(nonce).map_err(|_| OpenError::Malformed)?,
            sealed,
        )
        .map_err(|_| OpenError::Decrypt)
}

/// Decrypts any cloud payload after checking its `addition` against what the
/// server's row says. Used for full media as well as thumbnails.
pub fn open_cloud_payload(
    main_key: &MainKey, importer_id: Option<&str>, payload: &[u8],
) -> std::result::Result<(Vec<u8>, CloudMediaBackupEncrypted, [u8; 32]), OpenError> {
    let expected = expected_addition(importer_id).map_err(|_| OpenError::WrongAddition)?;
    let decoded = CloudMediaBackupEncrypted::decode(payload).map_err(|_| OpenError::Malformed)?;
    if decoded.addition != expected {
        return Err(OpenError::WrongAddition);
    }
    let media_key = main_key
        .decrypt_cloud_media_key(&decoded.encrypted_media_key, &decoded.addition)
        .map_err(|_| OpenError::KeyUnwrap)?;
    let plain = chacha_open(&media_key, &decoded.media_nonce, &decoded.media_ciphertext)?;
    Ok((plain, decoded, media_key))
}

fn valid_metadata(metadata: &ImportedMemoryMetadata, now: i64) -> bool {
    let source_ok = !metadata.source.is_empty()
        && metadata.source.len() <= 32
        && metadata
            .source
            .bytes()
            .all(|b| b.is_ascii_lowercase() || b.is_ascii_digit() || b == b'_' || b == b'-');
    let location_ok = match (metadata.latitude, metadata.longitude) {
        (None, None) => true,
        (Some(lat), Some(lon)) => {
            lat.is_finite() && lon.is_finite() && lat.abs() <= 90.0 && lon.abs() <= 180.0
        }
        _ => false,
    };
    source_ok
        && matches!(metadata.media_type, 1 | 2)
        && metadata.created_at >= 946_684_800
        && metadata.created_at <= now + 86_400
        && location_ok
}

/// A checked imported thumbnail.
#[derive(Debug)]
pub struct OpenedThumbnail {
    pub thumbnail: Vec<u8>,
    pub metadata: ImportedMemoryMetadata,
    pub width: u32,
    pub height: u32,
}

/// Opens an imported thumbnail payload: addition, key unwrap, content and
/// metadata authentication, bounded metadata and a bounded image decode.
pub fn open_imported_thumbnail(
    main_key: &MainKey, importer_id: &str, payload: &[u8], now: i64,
) -> std::result::Result<OpenedThumbnail, OpenError> {
    if payload.len() > THUMBNAIL_MAX_PAYLOAD {
        return Err(OpenError::Malformed);
    }
    let (thumbnail, decoded, mut media_key) =
        open_cloud_payload(main_key, Some(importer_id), payload)?;
    let sealed = decoded.encrypted_metadata.ok_or(OpenError::Metadata)?;
    if sealed.len() < 12 + 16 || sealed.len() > 4096 {
        media_key.zeroize();
        return Err(OpenError::Metadata);
    }
    let metadata = chacha_open(&media_key, &sealed[..12], &sealed[12..]);
    media_key.zeroize();
    let metadata =
        ImportedMemoryMetadata::decode(metadata?.as_slice()).map_err(|_| OpenError::Metadata)?;
    if !valid_metadata(&metadata, now) {
        return Err(OpenError::Metadata);
    }
    let mut reader = image::ImageReader::new(std::io::Cursor::new(&thumbnail));
    reader.set_format(image::ImageFormat::WebP);
    let mut limits = image::Limits::default();
    limits.max_image_width = Some(THUMBNAIL_MAX_SIDE);
    limits.max_image_height = Some(THUMBNAIL_MAX_SIDE);
    limits.max_alloc = Some(64 * 1024 * 1024);
    reader.limits(limits);
    let image = reader.decode().map_err(|_| OpenError::Image)?;
    Ok(OpenedThumbnail {
        width: image.width(),
        height: image.height(),
        thumbnail,
        metadata,
    })
}

/// Display name of a source id; an unknown id is never shown raw.
pub fn source_display_name(source: &str) -> &'static str {
    SOURCE_NAMES
        .iter()
        .find(|(id, _)| *id == source)
        .map(|(_, name)| *name)
        .unwrap_or("another app")
}

#[derive(Debug, Default, Clone)]
pub struct ReconcileReport {
    pub listed: usize,
    pub added: Vec<String>,
    pub already_local: usize,
    /// App memories this device does not have; restoring them is not this
    /// service's job.
    pub app_rows_missing: usize,
    pub failed: Vec<(String, String)>,
}

/// Adds every imported memory the server lists and this device lacks.
/// Lists everything first, so the progress bar knows how many memories are
/// missing, then downloads them. Resumable and idempotent: every memory is
/// committed on its own (the list's download links stay valid for two days),
/// and inserting a memory that exists is a no-op. Never deletes anything.
pub async fn reconcile_imported_memories(ctx: &Arc<Context>) -> Result<ReconcileReport> {
    let client = crate::api::http::client_builder()
        .timeout(std::time::Duration::from_secs(60))
        .build()
        .map_err(|e| error(&format!("http client: {e}")))?;
    let mut report = ReconcileReport::default();
    let known_unreadable: HashSet<String> = {
        let database = ctx.app_db.read().await.clone();
        sqlx::query_scalar::<_, String>(
            "SELECT media_id FROM imported_memory_failures WHERE permanent = 1",
        )
        .fetch_all(&database.pool)
        .await?
        .into_iter()
        .collect()
    };
    let (mut offset_date, mut offset_id) = (LIST_START, None::<String>);
    let mut seen = HashSet::new();
    let mut missing = Vec::new();
    loop {
        let page = match Server::get_memories_list(ctx, offset_date, offset_id.clone(), LIST_PAGE)
            .await?
        {
            ServerResult::Ok(list) => list.items,
            ServerResult::ErrorCode(code) => {
                return Err(error(&format!("memories list failed: {code}")))
            }
        };
        let Some(last) = page.last() else {
            break;
        };
        offset_date = last.original_date;
        offset_id = Some(last.media_id.clone());
        report.listed += page.len();

        let local = local_media_ids(ctx, page.iter().map(|item| item.media_id.as_str())).await?;
        for item in &page {
            if !seen.insert(item.media_id.clone()) {
                continue;
            }
            if local.contains(&item.media_id) {
                report.already_local += 1;
                continue;
            }
            let Some(importer_id) = item.importer_id.as_deref() else {
                report.app_rows_missing += 1;
                continue;
            };
            // A payload that failed a check that retrying cannot change waits
            // for the user to delete it.
            if known_unreadable.contains(&item.media_id) {
                report
                    .failed
                    .push((item.media_id.clone(), "unreadable".into()));
                continue;
            }
            if Uuid::parse_str(&item.media_id).is_err() {
                report
                    .failed
                    .push((item.media_id.clone(), OpenError::Malformed.reason().into()));
                continue;
            }
            missing.push((
                item.media_id.clone(),
                importer_id.to_owned(),
                item.thumbnail_download_url.clone(),
            ));
        }
        if (page.len() as i64) < LIST_PAGE {
            break;
        }
    }

    memory_import_progress::begin(missing.len());
    for (media_id, importer_id, url) in missing {
        let added = add_imported(ctx, &client, &media_id, &importer_id, &url).await;
        memory_import_progress::advance();
        match added {
            Ok(()) => report.added.push(media_id),
            Err(reason) => {
                record_failure(ctx, &media_id, &importer_id, &reason).await?;
                report.failed.push((media_id, reason));
            }
        }
    }
    Ok(report)
}

static RECONCILING: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(false);
static RECONCILE_AGAIN: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(false);

/// Runs [`reconcile_imported_memories`] in the background. Overlapping
/// requests coalesce: a request during a scan schedules one more pass.
pub fn spawn_reconcile(ctx: &Arc<Context>) {
    use std::sync::atomic::Ordering;
    if RECONCILING.swap(true, Ordering::AcqRel) {
        RECONCILE_AGAIN.store(true, Ordering::Release);
        return;
    }
    let ctx = ctx.clone();
    tokio::spawn(async move {
        // Passes coalesced into this task share one progress bar.
        let _progress = memory_import_progress::FinishOnDrop;
        loop {
            RECONCILE_AGAIN.store(false, Ordering::Release);
            match reconcile_imported_memories(&ctx).await {
                Ok(report) if !report.added.is_empty() || !report.failed.is_empty() => {
                    tracing::info!(
                        added = report.added.len(),
                        failed = report.failed.len(),
                        "imported memories reconciled"
                    );
                }
                Ok(_) => {}
                Err(error) => tracing::warn!(%error, "imported memories reconciliation failed"),
            }
            if !RECONCILE_AGAIN.load(Ordering::Acquire) {
                RECONCILING.store(false, Ordering::Release);
                // A request between the check and the reset starts a new task.
                if !RECONCILE_AGAIN.swap(false, Ordering::AcqRel)
                    || RECONCILING.swap(true, Ordering::AcqRel)
                {
                    return;
                }
            }
        }
    });
}

static LAST_FULL_SCAN: std::sync::Mutex<Option<std::time::Instant>> = std::sync::Mutex::new(None);

/// Starts a reconciliation when it can find something: when forced (a
/// `memoriesImported` push, a restore), when the server's memory count
/// differs from this device's cloud-backed count, or once a day, since equal
/// counts can hide different ids. Counts only decide whether to look; they
/// never delete anything.
pub async fn reconcile_if_needed(ctx: &Arc<Context>, force: bool) -> Result<bool> {
    let daily = {
        let last = LAST_FULL_SCAN
            .lock()
            .unwrap_or_else(std::sync::PoisonError::into_inner);
        last.is_none_or(|at| at.elapsed() > std::time::Duration::from_secs(24 * 60 * 60))
    };
    let mut run = force || daily;
    if !run {
        let server = match Server::get_memories_usage(ctx).await? {
            ServerResult::Ok(usage) => usage.count,
            ServerResult::ErrorCode(code) => return Err(TwonlyError::Api(code)),
        };
        let database = ctx.app_db.read().await.clone();
        let local: i64 =
            sqlx::query_scalar("SELECT COUNT(*) FROM media_files WHERE cloud_state = 'uploaded'")
                .fetch_one(&database.pool)
                .await?;
        run = server != local;
    }
    if run {
        *LAST_FULL_SCAN
            .lock()
            .unwrap_or_else(std::sync::PoisonError::into_inner) = Some(std::time::Instant::now());
        spawn_reconcile(ctx);
    }
    Ok(run)
}

/// One past import on this device, from the local memories.
#[derive(Debug, Clone)]
pub struct PastImport {
    pub importer_id: String,
    pub source: String,
    pub count: i64,
    pub first_created_at: i64,
    pub last_created_at: i64,
}

pub async fn past_imports(ctx: &Arc<Context>) -> Result<Vec<PastImport>> {
    let database = ctx.app_db.read().await.clone();
    let rows: Vec<(String, String, i64, i64, i64)> = sqlx::query_as(
        "SELECT i.importer_id, i.source, COUNT(*), MIN(m.created_at), MAX(m.created_at) FROM \
         imported_memories i JOIN media_files m ON m.media_id = i.media_id GROUP BY \
         i.importer_id, i.source ORDER BY MAX(m.created_at) DESC",
    )
    .fetch_all(&database.pool)
    .await?;
    Ok(rows
        .into_iter()
        .map(
            |(importer_id, source, count, first_created_at, last_created_at)| PastImport {
                importer_id,
                source,
                count,
                first_created_at,
                last_created_at,
            },
        )
        .collect())
}

/// An imported memory whose payload failed the checks.
#[derive(Debug, Clone)]
pub struct UnreadableImport {
    pub media_id: String,
    pub importer_id: Option<String>,
    pub reason: String,
}

pub async fn unreadable_imports(ctx: &Arc<Context>) -> Result<Vec<UnreadableImport>> {
    let database = ctx.app_db.read().await.clone();
    let rows: Vec<(String, Option<String>, String)> = sqlx::query_as(
        "SELECT media_id, importer_id, reason FROM imported_memory_failures ORDER BY media_id",
    )
    .fetch_all(&database.pool)
    .await?;
    Ok(rows
        .into_iter()
        .map(|(media_id, importer_id, reason)| UnreadableImport {
            media_id,
            importer_id,
            reason,
        })
        .collect())
}

/// Deletes one unreadable imported memory from the cloud, on the user's tap.
pub async fn delete_unreadable(ctx: &Arc<Context>, media_id: &str) -> Result<()> {
    match Server::delete_memory(ctx, media_id.to_owned()).await? {
        ServerResult::Ok(()) => {}
        // Already gone on the server.
        ServerResult::ErrorCode(0) => {}
        ServerResult::ErrorCode(code) => return Err(TwonlyError::Api(code)),
    }
    let database = ctx.app_db.read().await.clone();
    sqlx::query("DELETE FROM imported_memory_failures WHERE media_id = ?")
        .bind(media_id)
        .execute(&database.pool)
        .await?;
    Ok(())
}

/// "Delete everything from this import": revokes the importer if it still
/// exists, deletes its memories on the server, then this device's copies.
pub async fn delete_import(ctx: &Arc<Context>, importer_id: &str) -> Result<()> {
    expected_addition(Some(importer_id))?;
    match Server::delete_memory_importer_uploads(ctx, importer_id.to_owned()).await? {
        ServerResult::Ok(()) => {}
        ServerResult::ErrorCode(code) => return Err(TwonlyError::Api(code)),
    }
    let database = ctx.app_db.read().await.clone();
    let rows: Vec<(String, String)> = sqlx::query_as(
        "SELECT m.media_id, m.type FROM media_files m JOIN imported_memories i ON i.media_id = \
         m.media_id WHERE i.importer_id = ?",
    )
    .bind(importer_id)
    .fetch_all(&database.pool)
    .await?;
    let mut tx = database.pool.begin().await?;
    for (media_id, _) in &rows {
        crate::database::app::mediafiles::writes::delete(&mut tx, media_id).await?;
    }
    sqlx::query("DELETE FROM imported_memory_failures WHERE importer_id = ?")
        .bind(importer_id)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    let service = MediaFileService::new(ctx);
    for (media_id, media_type) in &rows {
        if let Err(error) = service.remove_files(media_id, media_type) {
            tracing::warn!(%error, "could not remove an imported memory's files");
        }
    }
    Ok(())
}

async fn local_media_ids<'a>(
    ctx: &Arc<Context>, ids: impl Iterator<Item = &'a str>,
) -> Result<HashSet<String>> {
    let ids: Vec<&str> = ids.collect();
    if ids.is_empty() {
        return Ok(HashSet::new());
    }
    let database = ctx.app_db.read().await.clone();
    let placeholders = vec!["?"; ids.len()].join(",");
    let sql = format!("SELECT media_id FROM media_files WHERE media_id IN ({placeholders})");
    // Only "?" placeholders are formatted in; the ids are bound.
    let mut query = sqlx::query_scalar::<_, String>(sqlx::AssertSqlSafe(sql));
    for id in &ids {
        query = query.bind(*id);
    }
    Ok(query.fetch_all(&database.pool).await?.into_iter().collect())
}

async fn record_failure(
    ctx: &Arc<Context>, media_id: &str, importer_id: &str, reason: &str,
) -> Result<()> {
    let database = ctx.app_db.read().await.clone();
    let now = chrono::Utc::now().timestamp();
    sqlx::query(
        "INSERT INTO imported_memory_failures (media_id, importer_id, reason, permanent, attempts, \
         next_attempt_at) VALUES (?, ?, ?, 1, 1, ?) ON CONFLICT(media_id) DO UPDATE SET reason = \
         excluded.reason, attempts = attempts + 1, next_attempt_at = excluded.next_attempt_at",
    )
    .bind(media_id)
    .bind(importer_id)
    .bind(reason)
    .bind(now + 24 * 60 * 60)
    .execute(&database.pool)
    .await?;
    Ok(())
}

async fn download_imported_thumbnail(
    client: &reqwest::Client, url: &str,
) -> std::result::Result<Vec<u8>, String> {
    download_cloud_payload(client, url, THUMBNAIL_MAX_PAYLOAD).await
}

async fn download_cloud_payload(
    client: &reqwest::Client, url: &str, max_payload: usize,
) -> std::result::Result<Vec<u8>, String> {
    let mut response = client
        .get(url)
        .send()
        .await
        .map_err(|e| format!("download: {e}"))?;
    if !response.status().is_success() {
        return Err(format!("download status {}", response.status()));
    }
    if response
        .content_length()
        .is_some_and(|n| n > max_payload as u64)
    {
        return Err(OpenError::Malformed.reason().into());
    }
    let mut payload = Vec::new();
    while let Some(chunk) = response
        .chunk()
        .await
        .map_err(|e| format!("download: {e}"))?
    {
        // Enforce the limit even without Content-Length, before buffering
        // another chunk. Subtraction avoids overflowing a length sum.
        if chunk.len() > max_payload - payload.len() {
            return Err(OpenError::Malformed.reason().into());
        }
        payload.extend_from_slice(&chunk);
    }
    Ok(payload)
}

async fn add_imported(
    ctx: &Arc<Context>, client: &reqwest::Client, media_id: &str, importer_id: &str, url: &str,
) -> std::result::Result<(), String> {
    // Network and decoding happen before the transaction; the transaction
    // only writes.
    let payload = download_imported_thumbnail(client, url).await?;
    let opened = {
        let key_manager = ctx.key_manager.lock().await;
        open_imported_thumbnail(
            &key_manager.main_key,
            importer_id,
            &payload,
            chrono::Utc::now().timestamp(),
        )
    }
    .map_err(|e| e.reason().to_string())?;

    let service = MediaFileService::new(ctx);
    let path = service.thumbnail_path(media_id);
    MediaFileService::ensure_parent(&path).map_err(|e| e.to_string())?;
    std::fs::write(&path, &opened.thumbnail).map_err(|e| e.to_string())?;

    let media_type = if opened.metadata.media_type == 2 {
        "video"
    } else {
        "image"
    };
    let database = ctx.app_db.read().await.clone();
    let mut tx = database.pool.begin().await.map_err(|e| e.to_string())?;
    crate::database::app::mediafiles::writes::upsert(
        &mut tx,
        MediaFilePatch {
            media_id: Some(media_id.to_owned()),
            r#type: Some(media_type.into()),
            cloud_state: Some("uploaded".into()),
            stored: Some(false),
            has_thumbnail: Some(true),
            created_at: Some(opened.metadata.created_at),
            location_latitude: opened
                .metadata
                .latitude
                .map(|value| NullableReal { value: Some(value) }),
            location_longitude: opened
                .metadata
                .longitude
                .map(|value| NullableReal { value: Some(value) }),
            ..Default::default()
        },
    )
    .await
    .map_err(|e| e.to_string())?;
    sqlx::query(
        "INSERT OR IGNORE INTO imported_memories (media_id, importer_id, source) VALUES (?, ?, ?)",
    )
    .bind(media_id)
    .bind(importer_id)
    .bind(&opened.metadata.source)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;
    sqlx::query("DELETE FROM imported_memory_failures WHERE media_id = ?")
        .bind(media_id)
        .execute(&mut *tx)
        .await
        .map_err(|e| e.to_string())?;
    tx.commit().await.map_err(|e| e.to_string())?;
    Ok(())
}

/// The importer a local memory came from, if any. Full-media downloads check
/// the payload's `addition` against it.
pub async fn local_importer_id(ctx: &Arc<Context>, media_id: &str) -> Result<Option<String>> {
    let database = ctx.app_db.read().await.clone();
    Ok(sqlx::query_scalar::<_, String>(
        "SELECT importer_id FROM imported_memories WHERE media_id = ?",
    )
    .bind(media_id)
    .fetch_optional(&database.pool)
    .await?)
}

/// The decrypted thumbnail this device stored for a memory.
pub fn local_thumbnail(ctx: &Arc<Context>, media_id: &str) -> Result<Vec<u8>> {
    Ok(std::fs::read(
        MediaFileService::new(ctx).thumbnail_path(media_id),
    )?)
}

/// Downloads and decrypts a memory's full media with the same checks as its
/// thumbnail.
pub async fn download_full_media(ctx: &Arc<Context>, media_id: &str) -> Result<Vec<u8>> {
    let importer_id = local_importer_id(ctx, media_id).await?;
    let url = match Server::get_memories_url(ctx, media_id.to_owned(), false).await? {
        ServerResult::Ok(url) => url.full_download_url,
        ServerResult::ErrorCode(code) => {
            return Err(error(&format!("memories url failed: {code}")))
        }
    };
    let client = crate::api::http::client_builder()
        .timeout(std::time::Duration::from_secs(300))
        .build()
        .map_err(|e| error(&format!("http client: {e}")))?;
    let payload = download_cloud_payload(&client, &url, FULL_MEDIA_MAX_PAYLOAD)
        .await
        .map_err(|e| error(&e))?;
    let key_manager = ctx.key_manager.lock().await;
    let (plain, _, mut media_key) =
        open_cloud_payload(&key_manager.main_key, importer_id.as_deref(), &payload)
            .map_err(|e| error(e.reason()))?;
    media_key.zeroize();
    Ok(plain)
}

#[cfg(test)]
mod tests {
    use super::*;
    use hmac::{Hmac, Mac};

    /// An unfinished response stays open so oversized bodies must be rejected
    /// while streaming, rather than at EOF or on the HTTP client's timeout.
    async fn download_test_thumbnail(
        headers: &str, body: &[u8], keep_open: bool,
    ) -> std::result::Result<Vec<u8>, String> {
        download_test_payload(headers, body, keep_open, THUMBNAIL_MAX_PAYLOAD).await
    }

    async fn download_test_payload(
        headers: &str, body: &[u8], keep_open: bool, max_payload: usize,
    ) -> std::result::Result<Vec<u8>, String> {
        use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};

        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let url = format!("http://{}/thumbnail", listener.local_addr().unwrap());
        let mut response = headers.as_bytes().to_vec();
        response.extend_from_slice(body);
        let server = tokio::spawn(async move {
            let (socket, _) = listener.accept().await.unwrap();
            let mut socket = BufReader::new(socket);
            loop {
                let mut line = String::new();
                assert_ne!(socket.read_line(&mut line).await.unwrap(), 0);
                if line == "\r\n" {
                    break;
                }
            }
            socket.get_mut().write_all(&response).await.unwrap();
            if keep_open {
                std::future::pending::<()>().await;
            }
        });
        let client = crate::api::http::client_builder()
            .no_proxy()
            .build()
            .unwrap();
        let result = tokio::time::timeout(
            std::time::Duration::from_secs(5),
            download_cloud_payload(&client, &url, max_payload),
        )
        .await;
        server.abort();
        let _ = server.await;
        result.expect("download must finish without waiting for the server to close")
    }

    fn chunked_body(payload: &[u8]) -> Vec<u8> {
        let mut body = Vec::new();
        for chunk in payload.chunks(16_000) {
            body.extend_from_slice(format!("{:x}\r\n", chunk.len()).as_bytes());
            body.extend_from_slice(chunk);
            body.extend_from_slice(b"\r\n");
        }
        body
    }

    #[tokio::test]
    async fn thumbnail_download_accepts_bodies_up_to_the_limit() {
        for length in [0, THUMBNAIL_MAX_PAYLOAD - 1, THUMBNAIL_MAX_PAYLOAD] {
            let payload = vec![42; length];
            let headers = format!("HTTP/1.1 200 OK\r\nContent-Length: {length}\r\n\r\n");
            assert_eq!(
                download_test_thumbnail(&headers, &payload, false)
                    .await
                    .unwrap(),
                payload
            );
            let mut chunked = chunked_body(&payload);
            chunked.extend_from_slice(b"0\r\n\r\n");
            assert_eq!(
                download_test_thumbnail(
                    "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n",
                    &chunked,
                    false,
                )
                .await
                .unwrap(),
                payload
            );
            assert_eq!(
                download_test_thumbnail("HTTP/1.1 200 OK\r\n\r\n", &payload, false)
                    .await
                    .unwrap(),
                payload
            );
        }
    }

    #[tokio::test]
    async fn thumbnail_download_rejects_oversized_declared_lengths_before_reading() {
        // The second length would wrap to zero if cast to a 32-bit usize.
        for length in [THUMBNAIL_MAX_PAYLOAD as u64 + 1, u64::from(u32::MAX) + 1] {
            let headers = format!("HTTP/1.1 200 OK\r\nContent-Length: {length}\r\n\r\n");
            assert_eq!(
                download_test_thumbnail(&headers, &[], true)
                    .await
                    .unwrap_err(),
                OpenError::Malformed.reason()
            );
        }
    }

    #[tokio::test]
    async fn thumbnail_download_rejects_oversized_chunked_body_before_eof() {
        // No terminating chunk: the server continues to hold the response open.
        let body = chunked_body(&vec![42; THUMBNAIL_MAX_PAYLOAD + 1]);
        assert_eq!(
            download_test_thumbnail(
                "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n",
                &body,
                true,
            )
            .await
            .unwrap_err(),
            OpenError::Malformed.reason()
        );
    }

    #[tokio::test]
    async fn thumbnail_download_rejects_oversized_lengthless_body_before_eof() {
        assert_eq!(
            download_test_thumbnail(
                "HTTP/1.1 200 OK\r\n\r\n",
                &vec![42; THUMBNAIL_MAX_PAYLOAD + 1],
                true,
            )
            .await
            .unwrap_err(),
            OpenError::Malformed.reason()
        );
    }

    #[tokio::test]
    async fn thumbnail_download_preserves_status_and_body_errors() {
        assert_eq!(
            download_test_thumbnail("HTTP/1.1 503 Service Unavailable\r\n\r\n", &[], true)
                .await
                .unwrap_err(),
            "download status 503 Service Unavailable"
        );
        assert!(download_test_thumbnail(
            "HTTP/1.1 200 OK\r\nContent-Length: 10\r\n\r\n",
            b"short",
            false
        )
        .await
        .unwrap_err()
        .starts_with("download: "));
    }

    #[tokio::test]
    async fn full_media_download_rejects_oversized_declared_lengths_before_reading() {
        for length in [FULL_MEDIA_MAX_PAYLOAD as u64 + 1, u64::from(u32::MAX) + 1] {
            let headers = format!("HTTP/1.1 200 OK\r\nContent-Length: {length}\r\n\r\n");
            assert_eq!(
                download_test_payload(&headers, &[], true, FULL_MEDIA_MAX_PAYLOAD)
                    .await
                    .unwrap_err(),
                OpenError::Malformed.reason()
            );
        }
    }

    #[tokio::test]
    async fn full_media_download_accepts_payloads_larger_than_thumbnails() {
        let payload = vec![42; THUMBNAIL_MAX_PAYLOAD + 1];
        assert_eq!(
            download_test_payload(
                "HTTP/1.1 200 OK\r\n\r\n",
                &payload,
                false,
                FULL_MEDIA_MAX_PAYLOAD,
            )
            .await
            .unwrap(),
            payload
        );
    }

    #[tokio::test]
    async fn full_media_download_rejects_oversized_stream_before_eof() {
        use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};

        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let url = format!("http://{}/full", listener.local_addr().unwrap());
        let server = tokio::spawn(async move {
            let (socket, _) = listener.accept().await.unwrap();
            let mut socket = BufReader::new(socket);
            loop {
                let mut line = String::new();
                assert_ne!(socket.read_line(&mut line).await.unwrap(), 0);
                if line == "\r\n" {
                    break;
                }
            }
            socket
                .get_mut()
                .write_all(b"HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n")
                .await
                .unwrap();
            // Generate the oversized response without storing it on the server.
            let chunk = vec![42; 64_000];
            let mut remaining = FULL_MEDIA_MAX_PAYLOAD + 1;
            while remaining > 0 {
                let length = remaining.min(chunk.len());
                socket
                    .get_mut()
                    .write_all(format!("{length:x}\r\n").as_bytes())
                    .await
                    .unwrap();
                socket.get_mut().write_all(&chunk[..length]).await.unwrap();
                socket.get_mut().write_all(b"\r\n").await.unwrap();
                remaining -= length;
            }
            // No terminating chunk: rejection must happen before EOF.
            std::future::pending::<()>().await;
        });
        let client = crate::api::http::client_builder()
            .no_proxy()
            .build()
            .unwrap();
        let result = tokio::time::timeout(
            std::time::Duration::from_secs(5),
            download_cloud_payload(&client, &url, FULL_MEDIA_MAX_PAYLOAD),
        )
        .await;
        server.abort();
        let _ = server.await;
        assert_eq!(
            result.expect("must reject before EOF").unwrap_err(),
            OpenError::Malformed.reason()
        );
    }

    #[derive(serde::Deserialize)]
    #[serde(rename_all = "camelCase")]
    struct Vectors {
        main_key_hex: String,
        import_id: String,
        addition: String,
        media_id: String,
        source_item_id: String,
        media_key_hex: String,
        thumbnail_plain_hex: String,
        full_plain_hex: String,
        thumbnail_payload_hex: String,
        full_payload_hex: String,
        grant_hex: String,
        pairing_id: String,
        page_private_hex: String,
        page_public_hex: String,
        envelope_hex: String,
    }

    fn vectors() -> Vectors {
        serde_json::from_str(include_str!("../../tests/fixtures/importer/payloads.json")).unwrap()
    }

    fn main_key(hex_key: &str) -> MainKey {
        serde_json::from_value(serde_json::json!({
            "main_key": hex::decode(hex_key).unwrap(),
        }))
        .unwrap()
    }

    #[test]
    fn opens_an_envelope_sealed_by_the_page_code() {
        // The vector was sealed by the page's sealing code (sealEnvelope).
        let v = vectors();
        let private: [u8; 32] = hex::decode(&v.page_private_hex)
            .unwrap()
            .try_into()
            .unwrap();
        let grant = open_envelope(
            &Uuid::parse_str(&v.pairing_id).unwrap(),
            private,
            &hex::decode(&v.envelope_hex).unwrap(),
        )
        .unwrap();
        assert_eq!(hex::encode(&grant), v.grant_hex);
        let decoded = ImporterGrant::decode(grant.as_slice()).unwrap();
        assert_eq!(decoded.import_id, v.import_id);
        assert_eq!(decoded.addition, v.addition);
        assert_eq!(decoded.username, "alice");
    }

    #[test]
    fn a_sealed_grant_opens_only_for_its_pairing() {
        let page_private = random::<32>();
        let page_public =
            x25519_dalek::PublicKey::from(&x25519_dalek::StaticSecret::from(page_private))
                .to_bytes();
        let pairing = Uuid::new_v4();
        let key = MainKey::generate();
        let grant = build_grant(&key, Uuid::new_v4(), [3; 32], "tobi", "Tobi", 1_000).unwrap();
        let envelope = seal_envelope(&pairing, &page_public, &grant.encode_to_vec()).unwrap();
        let opened = ImporterGrant::decode(
            open_envelope(&pairing, page_private, &envelope)
                .unwrap()
                .as_slice(),
        )
        .unwrap();
        assert_eq!(opened, grant);
        assert_eq!(opened.expires_at, 1_000 + GRANT_SECONDS);
        assert!(open_envelope(&Uuid::new_v4(), page_private, &envelope).is_err());
        assert!(open_envelope(&pairing, random::<32>(), &envelope).is_err());
        // A low-order page key is refused.
        assert!(seal_envelope(&pairing, &[0; 32], b"x").is_err());
    }

    #[test]
    fn the_grant_key_is_this_imports_wrap_key() {
        let v = vectors();
        let key = main_key(&v.main_key_hex);
        let import_id = Uuid::parse_str(&v.import_id).unwrap();
        let grant = build_grant(&key, import_id, [7; 32], "tobi", "Tobi", 0).unwrap();
        assert_eq!(grant.addition, v.addition);
        let page_grant =
            ImporterGrant::decode(hex::decode(&v.grant_hex).unwrap().as_slice()).unwrap();
        assert_eq!(grant.kek, page_grant.kek);
        assert_eq!(grant.id_key, page_grant.id_key);
    }

    #[test]
    fn decrypts_payloads_made_by_the_page_code() {
        let v = vectors();
        let key = main_key(&v.main_key_hex);
        let (full, decoded, media_key) = open_cloud_payload(
            &key,
            Some(&v.import_id),
            &hex::decode(&v.full_payload_hex).unwrap(),
        )
        .unwrap();
        assert_eq!(hex::encode(full), v.full_plain_hex);
        assert_eq!(hex::encode(media_key), v.media_key_hex);
        assert_eq!(decoded.encrypted_metadata, None);

        // The thumbnail payload with metadata, opened field by field (its
        // plaintext is not an image, so the full check is exercised below).
        let (thumb, decoded, media_key) = open_cloud_payload(
            &key,
            Some(&v.import_id),
            &hex::decode(&v.thumbnail_payload_hex).unwrap(),
        )
        .unwrap();
        assert_eq!(hex::encode(thumb), v.thumbnail_plain_hex);
        let sealed = decoded.encrypted_metadata.unwrap();
        let metadata = ImportedMemoryMetadata::decode(
            chacha_open(&media_key, &sealed[..12], &sealed[12..])
                .unwrap()
                .as_slice(),
        )
        .unwrap();
        assert_eq!(metadata.source, "snapchat");
        assert_eq!(metadata.media_type, 1);
        assert_eq!(metadata.created_at, 1_742_481_047);
        assert_eq!(metadata.latitude, Some(52.520008));
        assert_eq!(metadata.longitude, Some(13.404954));
        assert!(metadata.had_overlay);
        assert!(valid_metadata(&metadata, chrono::Utc::now().timestamp()));
        assert_eq!(source_display_name(&metadata.source), "Snapchat");
        assert_eq!(source_display_name("<script>"), "another app");
    }

    #[test]
    fn media_ids_match_the_page_derivation() {
        let v = vectors();
        let key = main_key(&v.main_key_hex);
        let mut mac = Hmac::<Sha256>::new_from_slice(&key.derive_import_id_key()).unwrap();
        mac.update(format!("snapchat\0{}", v.source_item_id).as_bytes());
        let mut id: [u8; 16] = mac.finalize().into_bytes()[..16].try_into().unwrap();
        id[6] = (id[6] & 0x0f) | 0x40;
        id[8] = (id[8] & 0x3f) | 0x80;
        assert_eq!(Uuid::from_bytes(id).to_string(), v.media_id);
    }

    #[test]
    fn the_addition_must_match_the_row_in_both_directions() {
        let v = vectors();
        let key = main_key(&v.main_key_hex);
        let full = hex::decode(&v.full_payload_hex).unwrap();
        // An import payload on a row without importer, and on another importer's row.
        assert_eq!(
            open_cloud_payload(&key, None, &full).unwrap_err(),
            OpenError::WrongAddition
        );
        assert_eq!(
            open_cloud_payload(&key, Some(&Uuid::new_v4().to_string()), &full).unwrap_err(),
            OpenError::WrongAddition
        );
        // Non-canonical importer ids are refused rather than normalised.
        assert_eq!(
            open_cloud_payload(&key, Some(&v.import_id.to_uppercase()), &full).unwrap_err(),
            OpenError::WrongAddition
        );
        // An "app" payload on an importer's row.
        let mut app = CloudMediaBackupEncrypted::decode(full.as_slice()).unwrap();
        app.addition = "app".into();
        assert_eq!(
            open_cloud_payload(&key, Some(&v.import_id), &app.encode_to_vec()).unwrap_err(),
            OpenError::WrongAddition
        );
        // Another account's key does not unwrap it.
        assert_eq!(
            open_cloud_payload(&MainKey::generate(), Some(&v.import_id), &full).unwrap_err(),
            OpenError::KeyUnwrap
        );
        // A flipped bit does not authenticate.
        let mut tampered = CloudMediaBackupEncrypted::decode(full.as_slice()).unwrap();
        tampered.media_ciphertext[0] ^= 1;
        assert_eq!(
            open_cloud_payload(&key, Some(&v.import_id), &tampered.encode_to_vec()).unwrap_err(),
            OpenError::Decrypt
        );
        assert_eq!(
            open_cloud_payload(&key, Some(&v.import_id), b"\xff\xff").unwrap_err(),
            OpenError::Malformed
        );
    }

    #[test]
    fn imported_thumbnails_need_valid_metadata_and_a_valid_image() {
        let v = vectors();
        let key = main_key(&v.main_key_hex);
        // The vector's thumbnail plaintext is text, not a WebP.
        assert_eq!(
            open_imported_thumbnail(
                &key,
                &v.import_id,
                &hex::decode(&v.thumbnail_payload_hex).unwrap(),
                2_000_000_000
            )
            .unwrap_err(),
            OpenError::Image
        );
        // Without metadata.
        assert_eq!(
            open_imported_thumbnail(
                &key,
                &v.import_id,
                &hex::decode(&v.full_payload_hex).unwrap(),
                2_000_000_000
            )
            .unwrap_err(),
            OpenError::Metadata
        );
        let mut bad = ImportedMemoryMetadata {
            source: "snapchat".into(),
            media_type: 1,
            created_at: 1_700_000_000,
            latitude: Some(1.0),
            longitude: None,
            had_overlay: false,
        };
        assert!(!valid_metadata(&bad, 2_000_000_000));
        bad.longitude = Some(f64::NAN);
        assert!(!valid_metadata(&bad, 2_000_000_000));
        bad.longitude = Some(2.0);
        assert!(valid_metadata(&bad, 2_000_000_000));
        bad.source = "Snap Chat".into();
        assert!(!valid_metadata(&bad, 2_000_000_000));
        bad.source = "snapchat".into();
        bad.media_type = 3;
        assert!(!valid_metadata(&bad, 2_000_000_000));
        bad.media_type = 2;
        bad.created_at = 2_100_000_000;
        assert!(!valid_metadata(&bad, 2_000_000_000));
    }

    #[test]
    fn pairing_links_are_strict() {
        let v = vectors();
        let public = hex::decode(&v.page_public_hex).unwrap();
        let link = format!(
            "{PAIRING_LINK_PREFIX}{}/{}",
            v.pairing_id,
            base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(&public)
        );
        let (id, key) = parse_pairing_link(&link).unwrap();
        assert_eq!(id.to_string(), v.pairing_id);
        assert_eq!(key.to_vec(), public);
        for bad in [
            link.replace("me.twonly.eu", "me.twonly.eu.evil"),
            link.replace("#v1", "#v2"),
            format!("{link}/x"),
            link.to_uppercase(),
            "https://me.twonly.eu/i/#v1/not-a-uuid/AAAA".into(),
        ] {
            assert!(parse_pairing_link(&bad).is_err(), "{bad}");
        }
    }
}
