/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 */

//! Home-screen widget state and its native-process manifest.
//!
//! WidgetKit and AppWidget never open the encrypted application database. They
//! only read the JSON and PNG files produced here under the shared data root.

use crate::api::messages::outgoing::send_c2c_message_to_contact;
use crate::api::proto::client::EncryptedContent;
use crate::context::Context;
use crate::error::Result;
use crate::services::mediafiles::MediaFileService;
use prost::Message as _;
use serde::Serialize;
use sqlx::FromRow;
use std::collections::BTreeSet;
use std::path::{Path, PathBuf};
use std::sync::Arc;

const WIDGET_LIFETIME_SECONDS: i64 = 24 * 60 * 60;

/// Mirrors `staleWidgetSeconds` in the iOS widget: an entry that has not
/// refreshed within this belongs to a widget that is no longer placed, and its
/// contact groups must stop granting anyone permission to share.
const STALE_WIDGET_SECONDS: i64 = 48 * 60 * 60;

/// WidgetKit gives an extension roughly 30 MB, and a decoded full-resolution
/// camera image alone exceeds that, which the system answers by killing the
/// extension mid-render: the home screen then shows an empty widget. The
/// largest supported family never needs more than this on either platform.
const WIDGET_IMAGE_MAX_EDGE: u32 = 1200;

#[derive(Serialize)]
struct WidgetManifest {
    version: u8,
    updated_at: i64,
    groups: Vec<ManifestGroup>,
    images: Vec<ManifestImage>,
}

#[derive(Serialize, FromRow)]
struct ManifestGroup {
    id: i64,
    name: String,
    emoji: Option<String>,
}

#[derive(Serialize)]
struct ManifestImage {
    media_id: String,
    path: String,
    sender: String,
    group_ids: Vec<i64>,
    expires_at: i64,
}

#[derive(FromRow)]
struct WidgetMediaRow {
    media_id: String,
    media_type: String,
    sender_id: i64,
    sender: String,
    created_at: i64,
}

#[derive(FromRow)]
struct ExpiredMediaRow {
    media_id: String,
    media_type: String,
}

fn widget_root(ctx: &Context) -> PathBuf {
    Path::new(&ctx.config.data_dir).join("widget")
}

fn config_path(ctx: &Context) -> PathBuf {
    widget_root(ctx).join("native-config.json")
}

/// Contacts reachable through at least one contact group used by a placed
/// widget. Group-valued members are expanded through their ordinary members.
pub async fn allowed_contact_ids(ctx: &Arc<Context>) -> Result<Vec<i64>> {
    let database = ctx.app_db.read().await.clone();
    let ids = sqlx::query_scalar::<_, i64>(
        r#"SELECT DISTINCT contact_id FROM (
             SELECT cgm.user_id AS contact_id
             FROM home_widget_groups hwg
             JOIN contact_group_members cgm
               ON cgm.contact_group_id = hwg.contact_group_id
             WHERE cgm.user_id IS NOT NULL
             UNION
             SELECT gm.contact_id
             FROM home_widget_groups hwg
             JOIN contact_group_members cgm
               ON cgm.contact_group_id = hwg.contact_group_id
             JOIN group_members gm ON gm.group_id = cgm.group_id
             WHERE cgm.group_id IS NOT NULL
               AND (gm.member_state IS NULL OR gm.member_state != 'leftGroup')
           ) ORDER BY contact_id"#,
    )
    .fetch_all(&database.pool)
    .await?;
    Ok(ids)
}

/// Reconciles the derived grant set and explicitly announces every change.
pub async fn sync_permissions(ctx: &Arc<Context>) -> Result<()> {
    import_native_configuration(ctx).await?;
    let allowed: BTreeSet<i64> = allowed_contact_ids(ctx).await?.into_iter().collect();
    let database = ctx.app_db.read().await.clone();
    let current = sqlx::query_as::<_, (i64, i64)>(
        "SELECT user_id, widget_sharing_granted FROM contacts WHERE accepted = 1",
    )
    .fetch_all(&database.pool)
    .await?;

    let mut changed = Vec::new();
    let mut transaction = database.pool.begin().await?;
    for (contact_id, granted) in current {
        let next = allowed.contains(&contact_id);
        if (granted != 0) == next {
            continue;
        }
        sqlx::query("UPDATE contacts SET widget_sharing_granted = ? WHERE user_id = ?")
            .bind(next)
            .bind(contact_id)
            .execute(&mut *transaction)
            .await?;
        changed.push((contact_id, next));
    }
    transaction.commit().await?;
    drop(database);

    for (contact_id, allowed) in changed {
        send_c2c_message_to_contact()
            .ctx(ctx)
            .contact_id(contact_id)
            .encrypted_content(
                EncryptedContent {
                    widget_sharing_allowed: Some(allowed),
                    ..Default::default()
                }
                .encode_to_vec(),
            )
            .call()
            .await?;
    }
    refresh_manifest(ctx).await
}

pub async fn register_widget(ctx: &Arc<Context>, widget_id: &str, platform: &str) -> Result<()> {
    let database = ctx.app_db.read().await.clone();
    sqlx::query("INSERT OR IGNORE INTO home_widgets(widget_id, platform) VALUES (?, ?)")
        .bind(widget_id)
        .bind(platform)
        .execute(&database.pool)
        .await?;
    sync_permissions(ctx).await
}

pub async fn unregister_widget(ctx: &Arc<Context>, widget_id: &str) -> Result<()> {
    let database = ctx.app_db.read().await.clone();
    sqlx::query("DELETE FROM home_widgets WHERE widget_id = ?")
        .bind(widget_id)
        .execute(&database.pool)
        .await?;
    sync_permissions(ctx).await
}

pub async fn set_widget_groups(
    ctx: &Arc<Context>,
    widget_id: &str,
    platform: &str,
    contact_group_ids: &[i64],
) -> Result<()> {
    let database = ctx.app_db.read().await.clone();
    let mut transaction = database.pool.begin().await?;
    sqlx::query("INSERT OR IGNORE INTO home_widgets(widget_id, platform) VALUES (?, ?)")
        .bind(widget_id)
        .bind(platform)
        .execute(&mut *transaction)
        .await?;
    sqlx::query("DELETE FROM home_widget_groups WHERE widget_id = ?")
        .bind(widget_id)
        .execute(&mut *transaction)
        .await?;
    for group_id in contact_group_ids {
        sqlx::query(
            "INSERT OR IGNORE INTO home_widget_groups(widget_id, contact_group_id) VALUES (?, ?)",
        )
        .bind(widget_id)
        .bind(group_id)
        .execute(&mut *transaction)
        .await?;
    }
    transaction.commit().await?;
    sync_permissions(ctx).await
}

/// Imports native placement/config changes. Both widget implementations write
/// `{ widgets: [{id, platform, group_ids}] }` atomically to this file.
async fn import_native_configuration(ctx: &Arc<Context>) -> Result<()> {
    #[derive(serde::Deserialize)]
    struct NativeConfig {
        #[serde(default)]
        widgets: Vec<NativeWidget>,
    }
    #[derive(serde::Deserialize)]
    struct NativeWidget {
        id: String,
        platform: String,
        #[serde(default)]
        group_ids: Vec<i64>,
        /// When this widget last rebuilt itself. Only iOS records it: nothing
        /// tells a WidgetKit extension that its widget was removed, so an entry
        /// that stops refreshing is how a removal becomes visible. Android
        /// enumerates its widgets directly and writes no timestamp.
        #[serde(default)]
        last_seen: Option<i64>,
    }

    let path = config_path(ctx);
    let Ok(bytes) = std::fs::read(path) else {
        return Ok(());
    };
    let config: NativeConfig = serde_json::from_slice(&bytes)?;
    let database = ctx.app_db.read().await.clone();
    let mut transaction = database.pool.begin().await?;
    sqlx::query("DELETE FROM home_widgets WHERE 1")
        .execute(&mut *transaction)
        .await?;
    let oldest_live = chrono::Utc::now().timestamp() - STALE_WIDGET_SECONDS;
    for widget in config.widgets {
        if widget.last_seen.is_some_and(|seen| seen < oldest_live) {
            continue;
        }
        sqlx::query("INSERT INTO home_widgets(widget_id, platform) VALUES (?, ?)")
            .bind(&widget.id)
            .bind(&widget.platform)
            .execute(&mut *transaction)
            .await?;
        for group_id in widget.group_ids {
            sqlx::query(
                "INSERT OR IGNORE INTO home_widget_groups(widget_id, contact_group_id) VALUES (?, ?)",
            )
            .bind(&widget.id)
            .bind(group_id)
            .execute(&mut *transaction)
            .await?;
        }
    }
    transaction.commit().await?;
    Ok(())
}

async fn contact_group_ids_for_sender(ctx: &Arc<Context>, sender_id: i64) -> Result<Vec<i64>> {
    let database = ctx.app_db.read().await.clone();
    Ok(sqlx::query_scalar::<_, i64>(
        r#"SELECT DISTINCT contact_group_id FROM (
             SELECT contact_group_id FROM contact_group_members WHERE user_id = ?
             UNION
             SELECT cgm.contact_group_id
             FROM contact_group_members cgm
             JOIN group_members gm ON gm.group_id = cgm.group_id
             WHERE gm.contact_id = ?
           ) ORDER BY contact_group_id"#,
    )
    .bind(sender_id)
    .bind(sender_id)
    .fetch_all(&database.pool)
    .await?)
}

pub async fn refresh_manifest(ctx: &Arc<Context>) -> Result<()> {
    let root = widget_root(ctx);
    let images_dir = root.join("images");
    std::fs::create_dir_all(&images_dir)?;

    let database = ctx.app_db.read().await.clone();
    let groups = sqlx::query_as::<_, ManifestGroup>(
        "SELECT id, name, emoji FROM contact_groups ORDER BY name COLLATE NOCASE, id",
    )
    .fetch_all(&database.pool)
    .await?;
    let rows = sqlx::query_as::<_, WidgetMediaRow>(
        r#"SELECT f.media_id, f.type AS media_type, m.sender_id,
                  COALESCE(c.display_name, c.username) AS sender, m.created_at
           FROM messages m
           JOIN media_files f ON f.media_id = m.media_id
           JOIN contacts c ON c.user_id = m.sender_id
           WHERE m.is_widget_media = 1 AND f.is_widget_media = 1
             AND f.download_state = 'ready'
             AND m.created_at > CAST(strftime('%s','now') AS INTEGER) - 86400
           ORDER BY m.created_at DESC"#,
    )
    .fetch_all(&database.pool)
    .await?;
    drop(database);

    let files = MediaFileService::new(ctx);
    let mut images = Vec::with_capacity(rows.len());
    for row in rows {
        let source = files.temp_path(&row.media_id, &row.media_type);
        if !source.exists() {
            continue;
        }
        let destination = images_dir.join(format!("{}.png", row.media_id));
        // One unreadable file must not abort the whole manifest: bailing out
        // here would freeze every other widget image at its last version.
        let decoded = match image::open(&source) {
            Ok(decoded) => decoded,
            Err(error) => {
                tracing::warn!(media_id = %row.media_id, %error, "widget image decode failed");
                continue;
            }
        };
        let scaled = if decoded.width() > WIDGET_IMAGE_MAX_EDGE
            || decoded.height() > WIDGET_IMAGE_MAX_EDGE
        {
            decoded.resize(
                WIDGET_IMAGE_MAX_EDGE,
                WIDGET_IMAGE_MAX_EDGE,
                image::imageops::FilterType::Triangle,
            )
        } else {
            decoded
        };
        if let Err(error) = scaled.save_with_format(&destination, image::ImageFormat::Png) {
            tracing::warn!(media_id = %row.media_id, %error, "widget image encode failed");
            continue;
        }
        images.push(ManifestImage {
            media_id: row.media_id,
            path: destination.display().to_string(),
            sender: row.sender,
            group_ids: contact_group_ids_for_sender(ctx, row.sender_id).await?,
            expires_at: row.created_at + WIDGET_LIFETIME_SECONDS,
        });
    }

    let manifest = WidgetManifest {
        version: 1,
        updated_at: chrono::Utc::now().timestamp(),
        groups,
        images,
    };
    let temporary = root.join("manifest.json.tmp");
    let destination = root.join("manifest.json");
    std::fs::write(&temporary, serde_json::to_vec(&manifest)?)?;
    std::fs::rename(temporary, destination)?;
    Ok(())
}

/// Removes one image the user dismissed from a widget, everywhere it lives.
///
/// Deliberately not a "hide": the sender shared it into a widget on the home
/// screen, so taking it back has to remove the bytes rather than filter them
/// out of one view.
pub async fn delete_media(ctx: &Arc<Context>, media_id: &str) -> Result<()> {
    let database = ctx.app_db.read().await.clone();
    let media_type = sqlx::query_scalar::<_, String>(
        "SELECT type FROM media_files WHERE media_id = ? AND is_widget_media = 1",
    )
    .bind(media_id)
    .fetch_optional(&database.pool)
    .await?;
    let Some(media_type) = media_type else {
        // Already gone: the expiry sweep and the user can race each other.
        return Ok(());
    };

    let mut transaction = database.pool.begin().await?;
    sqlx::query("DELETE FROM messages WHERE media_id = ?")
        .bind(media_id)
        .execute(&mut *transaction)
        .await?;
    sqlx::query("DELETE FROM media_files WHERE media_id = ?")
        .bind(media_id)
        .execute(&mut *transaction)
        .await?;
    transaction.commit().await?;
    drop(database);

    MediaFileService::new(ctx).remove_files(media_id, &media_type)?;
    let _ = std::fs::remove_file(
        widget_root(ctx)
            .join("images")
            .join(format!("{media_id}.png")),
    );
    refresh_manifest(ctx).await
}

pub async fn purge_widget_media(ctx: &Arc<Context>) -> Result<()> {
    let database = ctx.app_db.read().await.clone();
    let expired = sqlx::query_as::<_, ExpiredMediaRow>(
        r#"SELECT DISTINCT f.media_id, f.type AS media_type
           FROM media_files f JOIN messages m ON m.media_id = f.media_id
           WHERE f.is_widget_media = 1 AND m.created_at <= ?"#,
    )
    .bind(chrono::Utc::now().timestamp() - WIDGET_LIFETIME_SECONDS)
    .fetch_all(&database.pool)
    .await?;
    let mut transaction = database.pool.begin().await?;
    for media in &expired {
        sqlx::query("DELETE FROM messages WHERE media_id = ?")
            .bind(&media.media_id)
            .execute(&mut *transaction)
            .await?;
        sqlx::query("DELETE FROM media_files WHERE media_id = ?")
            .bind(&media.media_id)
            .execute(&mut *transaction)
            .await?;
    }
    transaction.commit().await?;
    drop(database);

    let files = MediaFileService::new(ctx);
    for media in expired {
        files.remove_files(&media.media_id, &media.media_type)?;
        let _ = std::fs::remove_file(
            widget_root(ctx)
                .join("images")
                .join(format!("{}.png", media.media_id)),
        );
    }
    refresh_manifest(ctx).await
}
