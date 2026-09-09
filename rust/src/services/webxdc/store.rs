/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! The twonly webxdc store: catalog metadata and bundle downloads.
//!
//! Apps are published through the admin panel and served by the API, so a
//! sender can only ever point at code twonly has already published. What
//! arrives in a message is an id and a version, never a bundle.

use crate::api::proto::http_requests::{WebxdcCatalog, WebxdcCatalogEntry};
use crate::bridge::api::RustApi;
use crate::context::Context;
use crate::error::{Result, TwonlyError};
use prost::Message as ProstMessage;
use sha2::{Digest, Sha256};
use std::path::PathBuf;
use std::sync::Arc;

/// No published app may be larger than this, whatever the catalog claims. The
/// catalog is fetched over TLS from our own server, but it is still the input
/// that decides how much a client downloads and stores.
const MAX_BUNDLE_BYTES: i64 = 32 * 1024 * 1024;

/// What the server accepts in a manifest, checked again here. A description is
/// one line under an app's name in the store, whatever the catalog carries.
const MAX_NAME_CHARS: usize = 128;
const MAX_DESCRIPTION_CHARS: usize = 200;
const MAX_LANGUAGES: usize = 16;

/// Ids are opaque and are never used to build a path or a URL beyond the
/// catalog lookup, but a strict charset keeps the failure obvious if that ever
/// changes.
fn is_valid_app_id(app_id: &str) -> bool {
    !app_id.is_empty()
        && app_id.len() <= 64
        && app_id
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '-' || c == '_' || c == '.')
        && !app_id.starts_with('.')
}

/// One translated catalog field -- a name or a description -- in the language
/// the reader asked for.
///
/// `languages` is what the UI prefers, most preferred first. An exact tag wins,
/// then one sharing its primary language (`de-at` for a reader of `de`), then
/// English, then whatever the app has at all: a name or a description in the
/// wrong language still says more about an app than a blank line does.
pub fn pick_localized(translations: &str, languages: &[String]) -> Option<String> {
    let by_language: std::collections::BTreeMap<String, String> =
        serde_json::from_str(translations).ok()?;
    for language in languages.iter().map(|language| language.to_lowercase()) {
        if let Some(text) = by_language.get(&language) {
            return Some(text.clone());
        }
        let primary = language.split('-').next().unwrap_or(&language);
        if let Some((_, text)) = by_language
            .iter()
            .find(|(tag, _)| tag.split('-').next() == Some(primary))
        {
            return Some(text.clone());
        }
    }
    by_language
        .get("en")
        .or_else(|| by_language.values().next())
        .cloned()
}

pub struct WebxdcStore {
    ctx: Arc<Context>,
}

impl WebxdcStore {
    pub fn new(ctx: &Arc<Context>) -> Self {
        Self { ctx: ctx.clone() }
    }

    fn url(path: &str) -> String {
        format!("{}webxdc/{path}", RustApi::api_base_url("https".into()))
    }

    fn client() -> Result<reqwest::Client> {
        reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(30))
            .build()
            .map_err(|error| TwonlyError::Generic(error.to_string()))
    }

    /// Brings the cached catalog in line with what the server publishes.
    ///
    /// Only metadata is fetched: names, icons, sizes and hashes. Bundles are
    /// downloaded when a user actually starts an app, so browsing the store
    /// costs one small request rather than every app.
    ///
    /// An app the server no longer offers is not dropped if an instance on this
    /// device points at it: unpublishing takes an app out of the store, it does
    /// not take it away from the chats it was already placed in.
    pub async fn refresh_catalog(&self) -> Result<()> {
        let response = Self::client()?
            .get(Self::url("catalog"))
            .send()
            .await
            .map_err(|error| TwonlyError::Generic(error.to_string()))?;
        if !response.status().is_success() {
            return Err(TwonlyError::Generic(format!(
                "webxdc catalog returned {}",
                response.status()
            )));
        }
        let bytes = response
            .bytes()
            .await
            .map_err(|error| TwonlyError::Generic(error.to_string()))?;
        let catalog = WebxdcCatalog::decode(bytes.as_ref())?;

        let database = self.ctx.app_db.read().await.clone();
        let mut transaction = database.pool.begin().await?;
        // Everything the catalog no longer carries goes, except what a chat on
        // this device is still running. What survives is marked unpublished, so
        // it can be started but not placed into another chat; the rows the
        // catalog does carry are marked published again right below.
        sqlx::query!(
            r#"DELETE FROM webxdc_apps
               WHERE NOT EXISTS (SELECT 1 FROM webxdc_instances
                                 WHERE webxdc_instances.app_id = webxdc_apps.app_id
                                   AND webxdc_instances.version = webxdc_apps.version)"#
        )
        .execute(&mut *transaction)
        .await?;
        sqlx::query!("UPDATE webxdc_apps SET published = 0")
            .execute(&mut *transaction)
            .await?;
        let now = chrono::Utc::now().timestamp();
        for (position, entry) in catalog.entries.iter().enumerate() {
            let sort_order = position as i64;
            if !Self::entry_is_sane(entry) {
                tracing::warn!(app_id = entry.app_id, "skipping unusable catalog entry");
                continue;
            }
            let icon = (!entry.icon.is_empty()).then(|| entry.icon.clone());
            // Every translation is kept, and the one to show is chosen when the
            // store is opened: the language a user reads is not something this
            // device tells the server by asking for one.
            let description =
                serde_json::to_string(&entry.description).unwrap_or_else(|_| "{}".to_string());
            let name_translations = serde_json::to_string(&entry.name_translations)
                .unwrap_or_else(|_| "{}".to_string());
            sqlx::query!(
                r#"INSERT INTO webxdc_apps
                       (app_id, version, name, name_translations, source_code_url,
                        description, icon, bundle_sha256, bundle_bytes, published,
                        cached_at, pro_only, sort_order, one_time)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?, ?)
                   ON CONFLICT(app_id, version) DO UPDATE SET
                       name = excluded.name,
                       name_translations = excluded.name_translations,
                       source_code_url = excluded.source_code_url,
                       description = excluded.description,
                       icon = excluded.icon,
                       bundle_sha256 = excluded.bundle_sha256,
                       bundle_bytes = excluded.bundle_bytes,
                       published = 1,
                       pro_only = excluded.pro_only,
                       sort_order = excluded.sort_order,
                       one_time = excluded.one_time,
                       cached_at = excluded.cached_at"#,
                entry.app_id,
                entry.version,
                entry.name,
                name_translations,
                entry.source_code_url,
                description,
                icon,
                entry.bundle_sha256,
                entry.bundle_bytes,
                now,
                entry.pro_only,
                sort_order,
                entry.one_time,
            )
            .execute(&mut *transaction)
            .await?;
        }
        transaction.commit().await?;
        Ok(())
    }

    fn entry_is_sane(entry: &WebxdcCatalogEntry) -> bool {
        is_valid_app_id(&entry.app_id)
            && entry.version >= 0
            && !entry.name.is_empty()
            && entry.name.chars().count() <= MAX_NAME_CHARS
            && entry.name_translations.len() <= MAX_LANGUAGES
            && entry
                .name_translations
                .values()
                .all(|name| name.chars().count() <= MAX_NAME_CHARS)
            && entry.description.len() <= MAX_LANGUAGES
            && entry
                .description
                .values()
                .all(|text| text.chars().count() <= MAX_DESCRIPTION_CHARS)
            && entry.bundle_bytes > 0
            && entry.bundle_bytes <= MAX_BUNDLE_BYTES
            && entry.bundle_sha256.len() == 64
            && entry
                .bundle_sha256
                .chars()
                .all(|c| c.is_ascii_hexdigit() && !c.is_ascii_uppercase())
    }

    fn bundles_dir(&self) -> PathBuf {
        PathBuf::from(&self.ctx.config.data_dir)
            .join("webxdc")
            .join("bundles")
    }

    /// Bundles are content addressed, so two instances of the same app share
    /// one file and a changed bundle can never land on an existing path.
    pub fn bundle_path(&self, sha256: &str) -> PathBuf {
        self.bundles_dir().join(format!("{sha256}.xdc"))
    }

    /// Resolves the hash a `(app_id, version)` pair maps to.
    ///
    /// Callers pin the result on the instance, and keep running it until the
    /// next time the app is started: a refresh in between must not change the
    /// code behind a game that is being played.
    pub async fn resolve_bundle_sha256(&self, app_id: &str, version: i64) -> Result<String> {
        if !is_valid_app_id(app_id) {
            return Err(TwonlyError::Generic("invalid webxdc app id".into()));
        }
        match self.known_bundle(app_id, version).await? {
            Some(sha256) => Ok(sha256),
            None => {
                // The sender may be running a version this device has not seen
                // advertised yet.
                self.refresh_catalog().await?;
                self.known_bundle(app_id, version).await?.ok_or_else(|| {
                    TwonlyError::Generic(format!("webxdc app {app_id}@{version} is not published"))
                })
            }
        }
    }

    /// The hash a version maps to, published or merely still cached for an
    /// instance that runs it.
    async fn known_bundle(&self, app_id: &str, version: i64) -> Result<Option<String>> {
        let database = self.ctx.app_db.read().await.clone();
        let row = sqlx::query_scalar!(
            r#"SELECT bundle_sha256 AS "bundle_sha256!: String"
               FROM webxdc_apps WHERE app_id = ? AND version = ?"#,
            app_id,
            version,
        )
        .fetch_optional(&database.pool)
        .await?;
        Ok(row)
    }

    /// The newest version of an app the store currently offers.
    ///
    /// Read from the cache, so it says what the last refresh saw. Callers that
    /// care about being current refresh first and treat a failure as "no update
    /// today" rather than as a reason not to start the app.
    pub async fn newest_published(&self, app_id: &str) -> Result<Option<(i64, String)>> {
        let database = self.ctx.app_db.read().await.clone();
        let row = sqlx::query!(
            r#"SELECT version AS "version!: i64", bundle_sha256 AS "bundle_sha256!: String"
               FROM webxdc_apps
               WHERE app_id = ? AND published = 1
               ORDER BY version DESC
               LIMIT 1"#,
            app_id,
        )
        .fetch_optional(&database.pool)
        .await?;
        Ok(row.map(|row| (row.version, row.bundle_sha256)))
    }

    /// Downloads the bundle unless it is already on disk, and returns the path
    /// only once its hash matches what was asked for.
    pub async fn ensure_bundle(&self, sha256: &str) -> Result<PathBuf> {
        let path = self.bundle_path(sha256);
        if path.is_file() {
            return Ok(path);
        }
        std::fs::create_dir_all(self.bundles_dir())?;

        let mut response = Self::client()?
            .get(Self::url(&format!("blob/{sha256}")))
            .send()
            .await
            .map_err(|error| TwonlyError::Generic(error.to_string()))?;
        if !response.status().is_success() {
            return Err(TwonlyError::Generic(format!(
                "webxdc blob returned {}",
                response.status()
            )));
        }

        // Streamed with a running hash and a hard byte ceiling: a
        // `Content-Length` is a claim, not a limit.
        let mut hasher = Sha256::new();
        let mut body = Vec::new();
        while let Some(chunk) = response
            .chunk()
            .await
            .map_err(|error| TwonlyError::Generic(error.to_string()))?
        {
            if body.len() as i64 + chunk.len() as i64 > MAX_BUNDLE_BYTES {
                return Err(TwonlyError::Generic("webxdc bundle is too large".into()));
            }
            hasher.update(&chunk);
            body.extend_from_slice(&chunk);
        }

        let digest = hex::encode(hasher.finalize());
        if digest != sha256 {
            return Err(TwonlyError::Generic(format!(
                "webxdc bundle hash mismatch: expected {sha256}, got {digest}"
            )));
        }

        // Written beside the target and renamed, so a bundle only ever appears
        // at its content-addressed path complete and verified.
        let temporary = self.bundles_dir().join(format!("{sha256}.partial"));
        std::fs::write(&temporary, &body)?;
        std::fs::rename(&temporary, &path)?;
        Ok(path)
    }
}

#[cfg(test)]
mod tests {
    use super::pick_localized;

    fn languages(preferred: &[&str]) -> Vec<String> {
        preferred.iter().map(|tag| (*tag).to_string()).collect()
    }

    #[test]
    fn shows_the_field_in_the_language_the_reader_asked_for() {
        let both = r#"{"de":"Spiele Dame.","en":"Play checkers."}"#;
        assert_eq!(
            pick_localized(both, &languages(&["de"])).as_deref(),
            Some("Spiele Dame.")
        );
        // A regional locale reads the language it belongs to.
        assert_eq!(
            pick_localized(both, &languages(&["de-AT"])).as_deref(),
            Some("Spiele Dame.")
        );
        // And a reader of the language takes a regional translation over none.
        assert_eq!(
            pick_localized(r#"{"de-at":"Spiele Dame."}"#, &languages(&["de"])).as_deref(),
            Some("Spiele Dame.")
        );
    }

    #[test]
    fn falls_back_rather_than_showing_nothing() {
        let english_only = r#"{"en":"Play checkers."}"#;
        assert_eq!(
            pick_localized(english_only, &languages(&["de"])).as_deref(),
            Some("Play checkers.")
        );
        // Not a language anyone asked for, but better than a blank line.
        assert_eq!(
            pick_localized(r#"{"fr":"Jouez aux dames."}"#, &languages(&["de"])).as_deref(),
            Some("Jouez aux dames.")
        );
    }

    #[test]
    fn has_nothing_to_show_for_an_app_that_describes_itself_nowhere() {
        assert_eq!(pick_localized("{}", &languages(&["de"])), None);
        // Whatever this is, it is not a catalog description.
        assert_eq!(pick_localized("null", &languages(&["de"])), None);
        assert_eq!(pick_localized("", &languages(&["de"])), None);
    }
}
