/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 */

//! Home-screen widget state and its native-process manifest.
//!
//! WidgetKit and AppWidget never open the encrypted application database. They
//! only read the JSON and PNG files produced here under the shared data root.
//!
//! Every contact group and directly selected person holds their latest image.
//! An arriving image deletes the one it replaces once no selection holds it.

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

/// A widget image lives until the next one takes its place. Only images that
/// could not be published yet — a download still running, a file that could not
/// be read — are kept on a clock, because nothing else would ever remove them.
const ABANDONED_MEDIA_SECONDS: i64 = 24 * 60 * 60;

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
    contacts: Vec<ManifestContact>,
    images: Vec<ManifestImage>,
}

#[derive(Serialize, FromRow)]

struct ManifestGroup {
    id: i64,
    name: String,
    emoji: Option<String>,
}

#[derive(Serialize, FromRow)]

struct ManifestContact {
    id: i64,
    name: String,
}

#[derive(Serialize)]

struct ManifestImage {
    media_id: String,
    path: String,
    sender: String,
    sender_id: i64,
    /// The contact groups this image is the current one for. Not the sender's
    /// full membership: an older image still holds every group a newer one did
    /// not claim, and publishing the full list would offer two images to the
    /// same group.
    group_ids: Vec<i64>,
    received_at: i64,
}

#[derive(FromRow)]

struct WidgetMediaRow {
    media_id: String,
    media_type: String,
    sender_id: i64,
    sender: String,
    created_at: i64,
    download_state: String,
}

fn widget_root(ctx: &Context) -> PathBuf {
    Path::new(&ctx.config.data_dir).join("widget")
}

fn config_path(ctx: &Context) -> PathBuf {
    widget_root(ctx).join("native-config.json")
}

/// People selected directly or through a contact group in a placed widget.
/// Group-valued members are expanded through their ordinary members.
pub async fn allowed_contact_ids(ctx: &Arc<Context>) -> Result<Vec<i64>> {
    let database = ctx.app_db.read().await.clone();

    let ids = sqlx::query_scalar!(
        r#"SELECT DISTINCT contact_id AS "contact_id!" FROM (
             SELECT contact_id FROM home_widget_contacts
             UNION
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

    let current = sqlx::query!(
        "SELECT user_id, widget_sharing_granted FROM contacts WHERE accepted = 1",
    )
    .map(|row| (row.user_id, row.widget_sharing_granted))
    .fetch_all(&database.pool)
    .await?;

    let mut changed = Vec::new();

    let mut transaction = database.pool.begin().await?;

    for (contact_id, granted) in current {
        let next = allowed.contains(&contact_id);

        if (granted != 0) == next {
            continue;
        }

        sqlx::query!(
            "UPDATE contacts SET widget_sharing_granted = ? WHERE user_id = ?",
            next,
            contact_id
        )
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

    sqlx::query!(
        "INSERT OR IGNORE INTO home_widgets(widget_id, platform) VALUES (?, ?)",
        widget_id,
        platform
    )
    .execute(&database.pool)
    .await?;

    sync_permissions(ctx).await
}

pub async fn unregister_widget(ctx: &Arc<Context>, widget_id: &str) -> Result<()> {
    let database = ctx.app_db.read().await.clone();

    sqlx::query!(
        "DELETE FROM home_widgets WHERE widget_id = ?",
        widget_id
    )
    .execute(&database.pool)
    .await?;

    sync_permissions(ctx).await
}

pub async fn set_widget_groups(
    ctx: &Arc<Context>, widget_id: &str, platform: &str, contact_group_ids: &[i64],
) -> Result<()> {
    let database = ctx.app_db.read().await.clone();

    let mut transaction = database.pool.begin().await?;

    sqlx::query!(
        "INSERT OR IGNORE INTO home_widgets(widget_id, platform) VALUES (?, ?)",
        widget_id,
        platform
    )
    .execute(&mut *transaction)
    .await?;

    sqlx::query!(
        "DELETE FROM home_widget_groups WHERE widget_id = ?",
        widget_id
    )
    .execute(&mut *transaction)
    .await?;

    for group_id in contact_group_ids {
        sqlx::query!(
            "INSERT OR IGNORE INTO home_widget_groups(widget_id, contact_group_id) VALUES (?, ?)",
            widget_id,
            group_id
        )
        .execute(&mut *transaction)
        .await?;
    }

    transaction.commit().await?;

    sync_permissions(ctx).await
}

/// Imports native placement/config changes. Both widget implementations write
/// `{ widgets: [{id, platform, group_ids, contact_ids}] }` atomically to this
/// file.
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
        #[serde(default)]
        contact_ids: Vec<i64>,
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

    sqlx::query!("DELETE FROM home_widgets WHERE 1")
        .execute(&mut *transaction)
        .await?;

    let oldest_live = chrono::Utc::now().timestamp() - STALE_WIDGET_SECONDS;

    for widget in config.widgets {
        if widget.last_seen.is_some_and(|seen| seen < oldest_live) {
            continue;
        }

        sqlx::query!(
            "INSERT INTO home_widgets(widget_id, platform) VALUES (?, ?)",
            &widget.id,
            &widget.platform
        )
        .execute(&mut *transaction)
        .await?;

        for group_id in widget.group_ids {
            sqlx::query!(
                "INSERT OR IGNORE INTO home_widget_groups(widget_id, contact_group_id) VALUES (?, \
                 ?)",
                &widget.id,
                group_id
            )
            .execute(&mut *transaction)
            .await?;
        }

        for contact_id in widget.contact_ids {
            sqlx::query!(
                r#"INSERT OR IGNORE INTO home_widget_contacts(widget_id, contact_id)
                   SELECT ?, user_id FROM contacts WHERE user_id = ?"#,
                &widget.id,
                contact_id
            )
            .execute(&mut *transaction)
            .await?;
        }
    }

    transaction.commit().await?;

    Ok(())
}

async fn contact_group_ids_for_sender(ctx: &Arc<Context>, sender_id: i64) -> Result<Vec<i64>> {
    let database = ctx.app_db.read().await.clone();

    Ok(sqlx::query_scalar!(
        r#"SELECT DISTINCT contact_group_id FROM (
             SELECT contact_group_id FROM contact_group_members WHERE user_id = ?
             UNION
             SELECT cgm.contact_group_id
             FROM contact_group_members cgm
             JOIN group_members gm ON gm.group_id = cgm.group_id
             WHERE gm.contact_id = ?
           ) ORDER BY contact_group_id"#,
        sender_id,
        sender_id
    )
    .fetch_all(&database.pool)
    .await?)
}

/// Publishes the latest image for each contact group and directly selected
/// person, then deletes images that no longer belong to any selection.
///
/// A group holds exactly one image: the most recent one a member of it sent.
/// The next arrival takes that place, and the image it replaced is gone — not
/// hidden, not aged out, deleted along with its files. Walking the rows newest
/// first and letting each claim only the groups still unclaimed is what makes
/// that true for every group at once, including a sender who is in several.
pub async fn refresh_manifest(ctx: &Arc<Context>) -> Result<()> {
    // Startup pruning and native pushes can run before permission sync. Import
    // first so a directly selected person's image is never pruned as unused.
    import_native_configuration(ctx).await?;

    let root = widget_root(ctx);

    let images_dir = root.join("images");

    std::fs::create_dir_all(&images_dir)?;

    let database = ctx.app_db.read().await.clone();

    let groups = sqlx::query_as!(
        ManifestGroup,
        "SELECT id, name, emoji FROM contact_groups ORDER BY name COLLATE NOCASE, id",
    )
    .fetch_all(&database.pool)
    .await?;

    // Matches getContactDisplayName: a nonempty nickname takes priority over
    // the profile's display name, with the username as the final fallback.
    let contacts = sqlx::query_as!(
        ManifestContact,
        r#"SELECT user_id AS "id!",
                  COALESCE(NULLIF(nick_name, ''), display_name, username) AS "name!: String"
           FROM contacts WHERE accepted = 1 AND blocked = 0
             AND deleted_by_user = 0 AND account_deleted = 0
           ORDER BY COALESCE(NULLIF(nick_name, ''), display_name, username) COLLATE NOCASE,
                    user_id"#,
    )
    .fetch_all(&database.pool)
    .await?;

    let directly_selected: BTreeSet<i64> =
        sqlx::query_scalar!("SELECT DISTINCT contact_id FROM home_widget_contacts")
            .fetch_all(&database.pool)
            .await?
            .into_iter()
            .collect();

    let rows = sqlx::query_as!(
        WidgetMediaRow,
        r#"SELECT f.media_id, f.type AS media_type, m.sender_id AS "sender_id!",
                  COALESCE(NULLIF(c.nick_name, ''), c.display_name, c.username) AS "sender!: String",
                  m.created_at, f.download_state AS "download_state!"
           FROM messages m
           JOIN media_files f ON f.media_id = m.media_id
           JOIN contacts c ON c.user_id = m.sender_id
           WHERE m.is_widget_media = 1 AND f.is_widget_media = 1
           ORDER BY m.created_at DESC, m.rowid DESC"#,
    )
    .fetch_all(&database.pool)
    .await?;

    drop(database);

    let abandoned_before = chrono::Utc::now().timestamp() - ABANDONED_MEDIA_SECONDS;

    let mut claimed: BTreeSet<i64> = BTreeSet::new();

    let mut claimed_contacts: BTreeSet<i64> = BTreeSet::new();

    let mut images = Vec::new();

    let mut superseded: Vec<(String, String)> = Vec::new();

    for row in rows {
        if row.download_state == "ready" {
            let holds: Vec<i64> = contact_group_ids_for_sender(ctx, row.sender_id)
                .await?
                .into_iter()
                .filter(|group_id| !claimed.contains(group_id))
                .collect();

            let holds_contact = directly_selected.contains(&row.sender_id)
                && !claimed_contacts.contains(&row.sender_id);

            if holds.is_empty() && !holds_contact {
                superseded.push((row.media_id, row.media_type));

                continue;
            }

            // Claimed only once the file is really on disk in the form the
            // widgets read: an image that claims a group it cannot then be
            // rendered for would blank that group instead of leaving the
            // previous image in place.
            if let Some(path) = publish_image(ctx, &images_dir, &row) {
                claimed.extend(holds.iter().copied());

                if holds_contact {
                    claimed_contacts.insert(row.sender_id);
                }

                images.push(ManifestImage {
                    media_id: row.media_id,
                    path,
                    sender: row.sender,
                    sender_id: row.sender_id,
                    group_ids: holds,
                    received_at: row.created_at,
                });

                continue;
            }
        }

        // Not publishable this round: a download still running, or a file that
        // could not be read. Kept so the next refresh can try again — but
        // something that never became showable would otherwise stay forever,
        // since only a successor deletes an image now.
        if row.created_at <= abandoned_before {
            tracing::info!(media_id = %row.media_id, "dropping abandoned widget media");

            superseded.push((row.media_id, row.media_type));
        }
    }

    remove_media(ctx, &superseded).await?;

    remove_orphaned_images(&images_dir, &images);

    let manifest = WidgetManifest {
        version: 1,
        updated_at: chrono::Utc::now().timestamp(),
        groups,
        contacts,
        images,
    };

    let temporary = root.join("manifest.json.tmp");

    let destination = root.join("manifest.json");

    std::fs::write(&temporary, serde_json::to_vec(&manifest)?)?;

    std::fs::rename(temporary, destination)?;

    Ok(())
}

/// Writes the copy of one image the widgets read, and answers with its path.
///
/// None means this row cannot be shown right now. One unreadable file must not
/// abort the whole manifest: bailing out here would freeze every other widget
/// image at its last version.
fn publish_image(ctx: &Arc<Context>, images_dir: &Path, row: &WidgetMediaRow) -> Option<String> {
    let source = MediaFileService::new(ctx).temp_path(&row.media_id, &row.media_type);

    if !source.exists() {
        return None;
    }

    let destination = images_dir.join(format!("{}.png", row.media_id));

    let decoded = match image::open(&source) {
        Ok(decoded) => decoded,
        Err(error) => {
            tracing::warn!(media_id = %row.media_id, %error, "widget image decode failed");

            return None;
        }
    };

    let scaled =
        if decoded.width() > WIDGET_IMAGE_MAX_EDGE || decoded.height() > WIDGET_IMAGE_MAX_EDGE {
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

        return None;
    }

    Some(destination.display().to_string())
}

/// Drops rendered images no manifest entry names any more.
///
/// Every path out of [`remove_media`] already deletes the one it owns; this
/// only catches what a crash between the two steps left behind, so that the
/// directory cannot grow by a file nobody will ever look at again.
fn remove_orphaned_images(images_dir: &Path, published: &[ManifestImage]) {
    let live: BTreeSet<&str> = published.iter().map(|image| image.path.as_str()).collect();

    let Ok(entries) = std::fs::read_dir(images_dir) else {
        return;
    };

    for entry in entries.flatten() {
        let path = entry.path();

        if path.extension().is_some_and(|extension| extension == "png")
            && !live.contains(path.display().to_string().as_str())
        {
            let _ = std::fs::remove_file(path);
        }
    }
}

/// Deletes widget media outright: the message, the media file, and every copy
/// of the image on disk.
///
/// Widget media exists for the home screen and nowhere else — it is hidden from
/// chats and never enters memories — so an image no group holds any more has no
/// second place to live on in.
async fn remove_media(ctx: &Arc<Context>, media: &[(String, String)]) -> Result<()> {
    if media.is_empty() {
        return Ok(());
    }

    let database = ctx.app_db.read().await.clone();

    let mut transaction = database.pool.begin().await?;

    for (media_id, _) in media {
        sqlx::query!(
            "DELETE FROM messages WHERE media_id = ?",
            media_id
        )
        .execute(&mut *transaction)
        .await?;

        sqlx::query!(
            "DELETE FROM media_files WHERE media_id = ?",
            media_id
        )
        .execute(&mut *transaction)
        .await?;
    }

    transaction.commit().await?;

    drop(database);

    let files = MediaFileService::new(ctx);

    for (media_id, media_type) in media {
        files.remove_files(media_id, media_type)?;

        let _ = std::fs::remove_file(
            widget_root(ctx)
                .join("images")
                .join(format!("{media_id}.png")),
        );
    }

    Ok(())
}

/// Removes one image the user dismissed from a widget, everywhere it lives.
///
/// Deliberately not a "hide": the sender shared it into a widget on the home
/// screen, so taking it back has to remove the bytes rather than filter them
/// out of one view. Its groups then hold nothing until the next image arrives —
/// the one it replaced is long gone.
pub async fn delete_media(ctx: &Arc<Context>, media_id: &str) -> Result<()> {
    let database = ctx.app_db.read().await.clone();

    let media_type = sqlx::query_scalar!(
        "SELECT type FROM media_files WHERE media_id = ? AND is_widget_media = 1",
        media_id
    )
    .fetch_optional(&database.pool)
    .await?;

    drop(database);

    let Some(media_type) = media_type else {
        // Already gone: a newer image and the user can race each other.
        return Ok(());
    };

    remove_media(ctx, &[(media_id.to_string(), media_type)]).await?;

    refresh_manifest(ctx).await
}

/// Republishes the manifest, which is what drops superseded media.
///
/// Retention is no longer a clock the caller has to tick: an image is deleted
/// by its successor, during the refresh that publishes it. This stays as the
/// maintenance entry point so a wake-up or a launch settles the media that
/// arrived while nothing was running.
pub async fn purge_widget_media(ctx: &Arc<Context>) -> Result<()> {
    refresh_manifest(ctx).await
}

#[cfg(test)]
mod tests {

    use super::*;

    fn native_config(ctx: &Context, widgets: serde_json::Value) -> anyhow::Result<()> {
        std::fs::create_dir_all(widget_root(ctx))?;

        std::fs::write(
            config_path(ctx),
            serde_json::to_vec(&serde_json::json!({ "widgets": widgets }))?,
        )?;

        Ok(())
    }

    fn manifest(ctx: &Context) -> anyhow::Result<serde_json::Value> {
        Ok(serde_json::from_slice(&std::fs::read(
            widget_root(ctx).join("manifest.json"),
        )?)?)
    }

    #[tokio::test]

    async fn direct_and_group_selections_grant_a_union_and_removal_revokes_it() -> anyhow::Result<()>
    {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let database = ctx.app_db.read().await.clone();

        for statement in [
            "INSERT INTO contacts(user_id, username) VALUES (7, 'alice'), (8, 'bob'), (9, 'carol')",
            "INSERT INTO contact_groups(id, name, text_color, background_color) VALUES (1, \
             'Friends', 0, 0)",
            "INSERT INTO contact_group_members(contact_group_id, user_id) VALUES (1, 7), (1, 8)",
        ] {
            sqlx::query(sqlx::AssertSqlSafe(statement))
                .execute(&database.pool)
                .await?;
        }

        native_config(
            &ctx,
            serde_json::json!([
                {"id": "android:1", "platform": "android", "group_ids": [1], "contact_ids": [7, 9, 999]},
                {"id": "ios:expired", "platform": "ios", "contact_ids": [8], "last_seen": 1}
            ]),
        )?;

        import_native_configuration(&ctx).await?;

        assert_eq!(allowed_contact_ids(&ctx).await?, vec![7, 8, 9]);

        native_config(
            &ctx,
            serde_json::json!([
                {"id": "android:1", "platform": "android", "contact_ids": [9]}
            ]),
        )?;

        import_native_configuration(&ctx).await?;

        assert_eq!(allowed_contact_ids(&ctx).await?, vec![9]);

        native_config(&ctx, serde_json::json!([]))?;

        import_native_configuration(&ctx).await?;

        assert!(allowed_contact_ids(&ctx).await?.is_empty());

        Ok(())
    }

    #[tokio::test]

    async fn a_person_without_contact_groups_keeps_only_their_latest_image() -> anyhow::Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let database = ctx.app_db.read().await.clone();

        for statement in [
            "INSERT INTO contacts(user_id, username, display_name, nick_name, accepted) VALUES \
             (7, 'alice', 'Alice Smith', 'Ali', 1)",
            "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('d', 'Alice', 1)",
        ] {
            sqlx::query(sqlx::AssertSqlSafe(statement))
                .execute(&database.pool)
                .await?;
        }

        // The native selection has not been synced into Rust's tables yet.
        native_config(
            &ctx,
            serde_json::json!([
                {"id": "android:1", "platform": "android", "contact_ids": [7]}
            ]),
        )?;

        for id in ["old", "new"] {
            sqlx::query(
                "INSERT INTO media_files(media_id, type, is_widget_media, download_state) VALUES \
                 (?, 'image', 1, 'ready')",
            )
            .bind(id)
            .execute(&database.pool)
            .await?;

            sqlx::query(
                "INSERT INTO messages(message_id, group_id, sender_id, type, media_id, \
                 is_widget_media, created_at) VALUES (?, 'd', 7, 'media', ?, 1, 100)",
            )
            .bind(id)
            .bind(id)
            .execute(&database.pool)
            .await?;

            let photo = MediaFileService::new(&ctx).temp_path(id, "image");

            MediaFileService::ensure_parent(&photo)?;

            image::RgbImage::new(10, 10).save(&photo)?;
        }

        refresh_manifest(&ctx).await?;

        let published = manifest(&ctx)?;

        assert_eq!(published["images"].as_array().unwrap().len(), 1);

        assert_eq!(published["images"][0]["media_id"], "new");

        assert_eq!(published["images"][0]["group_ids"], serde_json::json!([]));

        assert_eq!(published["images"][0]["sender"], "Ali");

        assert_eq!(published["contacts"][0]["name"], "Ali");

        assert!(!MediaFileService::new(&ctx)
            .temp_path("old", "image")
            .exists());

        native_config(&ctx, serde_json::json!([]))?;

        refresh_manifest(&ctx).await?;

        assert!(manifest(&ctx)?["images"].as_array().unwrap().is_empty());

        assert!(!MediaFileService::new(&ctx)
            .temp_path("new", "image")
            .exists());

        Ok(())
    }

    #[tokio::test]

    async fn selectable_people_use_the_app_display_name_priority() -> anyhow::Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let database = ctx.app_db.read().await.clone();

        for statement in [
            "INSERT INTO contacts(user_id, username, display_name, nick_name, accepted) VALUES \
             (7, 'alice', 'Alice Smith', 'Ali', 1), (8, 'bob', 'Robert', '', 1), (9, 'carol', \
             NULL, NULL, 1)",
            "INSERT INTO contacts(user_id, username, accepted, blocked) VALUES (10, 'blocked', 1, \
             1)",
            "INSERT INTO contacts(user_id, username) VALUES (11, 'unaccepted')",
        ] {
            sqlx::query(sqlx::AssertSqlSafe(statement))
                .execute(&database.pool)
                .await?;
        }

        refresh_manifest(&ctx).await?;

        let published = manifest(&ctx)?;

        let names: Vec<&str> = published["contacts"]
            .as_array()
            .unwrap()
            .iter()
            .map(|contact| contact["name"].as_str().unwrap())
            .collect();

        assert_eq!(names, vec!["Ali", "carol", "Robert"]);

        Ok(())
    }

    #[tokio::test]

    async fn a_published_widget_image_identifies_its_sender() -> anyhow::Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let database = ctx.app_db.read().await.clone();

        for statement in [
            "INSERT INTO contacts(user_id, username) VALUES (7, 'alice')",
            "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('d', 'Alice', 1)",
            "INSERT INTO contact_groups(id, name, text_color, background_color) VALUES (1, \
             'Friends', 0, 0)",
            "INSERT INTO contact_group_members(contact_group_id, user_id) VALUES (1, 7)",
            "INSERT INTO media_files(media_id, type, is_widget_media, download_state) VALUES \
             ('photo', 'image', 1, 'ready')",
            "INSERT INTO messages(message_id, group_id, sender_id, type, media_id, \
             is_widget_media) VALUES ('message', 'd', 7, 'media', 'photo', 1)",
        ] {
            sqlx::query(sqlx::AssertSqlSafe(statement))
                .execute(&database.pool)
                .await?;
        }

        let photo = MediaFileService::new(&ctx).temp_path("photo", "image");

        MediaFileService::ensure_parent(&photo)?;

        image::RgbImage::new(10, 10).save(&photo)?;

        refresh_manifest(&ctx).await?;

        let manifest: serde_json::Value =
            serde_json::from_slice(&std::fs::read(widget_root(&ctx).join("manifest.json"))?)?;

        assert_eq!(manifest["images"].as_array().unwrap().len(), 1);

        assert_eq!(manifest["images"][0]["sender_id"], 7);

        assert_eq!(manifest["images"][0]["sender"], "alice");

        assert_eq!(manifest["images"][0]["group_ids"], serde_json::json!([1]));

        Ok(())
    }
}
