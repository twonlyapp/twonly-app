/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! What the Flutter layer may ask of the webxdc runtime.
//!
//! Everything the webview says arrives here. None of it is trusted: the
//! instance an update belongs to, the limits it has to fit in and the text it
//! may put in front of the user are all decided on this side, because
//! `webxdc.js` is code the app can replace.

use crate::error::Result;
use crate::services::webxdc::{bundle, store::WebxdcStore, WebxdcService};

pub struct WebxdcStoreApp {
    pub app_id: String,
    pub version: i64,
    /// Already in the reader's language, like the description.
    pub name: String,
    /// One line about the app, already in the reader's language.
    pub description: Option<String>,
    pub source_code_url: Option<String>,
    pub icon: Option<Vec<u8>>,
    pub bundle_bytes: i64,
}

pub struct WebxdcInstanceInfo {
    pub instance_id: String,
    pub group_id: String,
    pub app_id: String,
    pub version: i64,
    /// The webview host this instance is served from. Unique per instance, so
    /// the browser's own origin model keeps one app's stored data out of reach
    /// of every other app.
    pub origin_token: String,
    pub summary: Option<String>,
    pub document: Option<String>,
}

pub struct WebxdcUpdateEntry {
    pub serial: i64,
    pub payload: String,
    pub info: Option<String>,
    pub href: Option<String>,
    /// `None` when this device sent it.
    pub sender_id: Option<i64>,
}

pub struct WebxdcResponse {
    pub status: u16,
    pub mime: String,
    pub header_names: Vec<String>,
    pub header_values: Vec<String>,
    pub body: Vec<u8>,
}

/// Refreshes the store listing. Metadata only; no bundle is fetched.
pub async fn refresh_catalog() -> Result<()> {
    let ctx = crate::context::Context::get_static()?;
    WebxdcStore::new(ctx).refresh_catalog().await
}

/// What the in-app store offers, newest version of each app only.
///
/// `languages` is what the UI prefers, most preferred first. Names and
/// descriptions are cached in every language the catalog carries and picked
/// here, so which language a user reads is never sent anywhere.
pub async fn catalog(languages: Vec<String>) -> Result<Vec<WebxdcStoreApp>> {
    let ctx = crate::context::Context::get_static()?;
    let database = ctx.app_db.read().await.clone();
    let rows = sqlx::query!(
        r#"SELECT app_id AS "app_id!: String", version AS "version!: i64",
                  name AS "name!: String",
                  name_translations AS "name_translations!: String",
                  source_code_url AS "source_code_url: String",
                  description AS "description!: String",
                  icon AS "icon: Vec<u8>", bundle_bytes AS "bundle_bytes!: i64"
           FROM webxdc_apps
           WHERE published = 1
             AND version = (SELECT MAX(version) FROM webxdc_apps AS newer
                            WHERE newer.app_id = webxdc_apps.app_id AND newer.published = 1)
           ORDER BY name ASC"#
    )
    .fetch_all(&database.pool)
    .await?;
    let mut apps: Vec<WebxdcStoreApp> = rows
        .into_iter()
        .map(|row| WebxdcStoreApp {
            app_id: row.app_id,
            version: row.version,
            // The untranslated name is what an app translated into no language
            // the reader has is still called.
            name: crate::services::webxdc::store::pick_localized(
                &row.name_translations,
                &languages,
            )
            .unwrap_or(row.name),
            description: crate::services::webxdc::store::pick_localized(
                &row.description,
                &languages,
            ),
            source_code_url: row.source_code_url,
            icon: row.icon,
            bundle_bytes: row.bundle_bytes,
        })
        .collect();
    // The query orders by the untranslated name, which is not the order the
    // list is read in once the names are the reader's.
    apps.sort_by_key(|app| app.name.to_lowercase());
    Ok(apps)
}

/// Places an app into a chat and returns the id of the message that carries it.
pub async fn create_instance(group_id: String, app_id: String, version: i64) -> Result<String> {
    let ctx = crate::context::Context::get_static()?;
    WebxdcService::new(ctx)
        .create_instance(group_id, app_id, version)
        .await
}

pub async fn instance(instance_id: String) -> Result<Option<WebxdcInstanceInfo>> {
    let ctx = crate::context::Context::get_static()?;
    Ok(WebxdcService::new(ctx)
        .instance(&instance_id)
        .await?
        .map(|instance| WebxdcInstanceInfo {
            instance_id: instance.instance_id,
            group_id: instance.group_id,
            app_id: instance.app_id,
            version: instance.version,
            origin_token: instance.origin_token,
            summary: instance.summary,
            document: instance.document,
        }))
}

/// Downloads and verifies the bundle if it is not already on disk, and returns
/// where it landed. Called when the user starts an app, never on message
/// arrival: a message must not be able to make a device fetch anything.
pub async fn prepare_bundle(instance_id: String) -> Result<String> {
    let ctx = crate::context::Context::get_static()?;
    let path = WebxdcService::new(ctx).prepare_bundle(&instance_id).await?;
    Ok(path.display().to_string())
}

/// Answers one request the webview made for a file inside the bundle.
///
/// The platform shim has already established that the request came from this
/// instance's own origin; everything after that is decided here.
pub async fn serve(instance_id: String, request_path: String) -> Result<WebxdcResponse> {
    let ctx = crate::context::Context::get_static()?;
    let service = WebxdcService::new(ctx);
    // The bundle the instance is pinned to, not whatever the store offers now:
    // every file of one run comes out of the same `.xdc`, and the store was
    // already consulted when the app started.
    let path = service.pinned_bundle(&instance_id).await?;
    let init = service.init_script_values(&instance_id).await?;
    let response = bundle::serve(&path, &request_path, &init);
    let (header_names, header_values) = response.headers.into_iter().unzip();
    Ok(WebxdcResponse {
        status: response.status,
        mime: response.mime,
        header_names,
        header_values,
        body: response.body,
    })
}

pub async fn updates_after(instance_id: String, serial: i64) -> Result<Vec<WebxdcUpdateEntry>> {
    let ctx = crate::context::Context::get_static()?;
    Ok(WebxdcService::new(ctx)
        .updates_after(&instance_id, serial)
        .await?
        .into_iter()
        .map(|update| WebxdcUpdateEntry {
            serial: update.serial,
            payload: update.payload,
            info: update.info,
            href: update.href,
            sender_id: update.sender_id,
        })
        .collect())
}

pub async fn send_update(
    instance_id: String,
    payload: String,
    info: Option<String>,
    href: Option<String>,
    summary: Option<String>,
    document: Option<String>,
) -> Result<()> {
    let ctx = crate::context::Context::get_static()?;
    WebxdcService::new(ctx)
        .send_update(instance_id, payload, info, href, summary, document)
        .await
}

/// The address the running app sees for a participant. Stable inside one
/// instance and unrelated to the same user's address in any other.
pub fn address_for(instance_id: String, user_id: i64) -> String {
    WebxdcService::address_for(&instance_id, user_id)
}

/// Drops an instance and its whole update log, returning the origin whose web
/// storage the platform layer still has to clear. The log is only half the
/// state: an app is free to keep everything in `localStorage`, which no
/// database delete reaches.
pub async fn delete_instance(instance_id: String) -> Result<Option<String>> {
    let ctx = crate::context::Context::get_static()?;
    WebxdcService::new(ctx).delete_instance(&instance_id).await
}
