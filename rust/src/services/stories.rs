/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Stories: an image or video shared with many contacts for 24 hours.
//!
//! A story item travels the ordinary media path. Each recipient gets a hidden
//! message row in their 1:1 chat -- on the sender one row per recipient, all
//! sharing one media file -- so upload, receipts and opened tracking need
//! nothing of their own. The chat shows a story row only once somebody saved
//! it; every other story row leaves 24 hours after the sender's timestamp.

use crate::api::proto::client::{encrypted_content, EncryptedContent};
use crate::context::Context;
use crate::database::app::contacts::table::Contact;
use crate::database::app::groups::native::Group;
use crate::error::{Result, TwonlyError};
use crate::services::direct_media_upload::DirectMediaUploadService;
use crate::services::media_upload::media_lock;
use crate::services::mediafiles::MediaFileService;
use crate::services::messages::MessageService;
use prost::Message as _;
use sqlx::{Sqlite, Transaction};
use std::collections::BTreeSet;
use std::sync::Arc;

/// How long a story item is visible after its sender posted it.
pub const STORY_LIFETIME_SECONDS: i64 = 24 * 60 * 60;

/// "All contacts" reaches only existing chats with an exchange in the last
/// month.
pub const STORY_AUDIENCE_RECENT_EXCHANGE_SECONDS: i64 = 30 * 24 * 60 * 60;

/// A story is announced only between people who sent each other a text or
/// media message within this long.
pub const STORY_ANNOUNCE_RECENT_EXCHANGE_SECONDS: i64 = 14 * 24 * 60 * 60;

/// Whether the 1:1 chat `group_id` carried a text or media message, either
/// way, within the last two weeks.
pub(crate) async fn exchanged_recently(
    t: &mut Transaction<'_, Sqlite>, group_id: &str, now: i64,
) -> Result<bool> {
    let since = now - STORY_ANNOUNCE_RECENT_EXCHANGE_SECONDS;

    Ok(sqlx::query_scalar!(
        r#"SELECT EXISTS(
               SELECT 1 FROM groups WHERE group_id = ? AND last_text_or_media_at > ?
           ) AS "recent!: bool""#,
        group_id,
        since,
    )
    .fetch_one(&mut **t)
    .await?)
}

/// Who a story item goes to: contacts with a recent exchange, or the members
/// of the selected contact groups that share stories.
#[derive(Clone, Debug, Default, PartialEq, Eq)]

pub struct StoryAudience {
    pub all: bool,
    pub contact_group_ids: Vec<i64>,
}

/// The contacts `audience` reaches, in ascending order. Blocked and deleted
/// contacts are left out, as are group members who left. "All contacts" also
/// requires an existing direct chat with a text or media exchange in 30 days.
pub(crate) async fn resolve_audience(
    t: &mut Transaction<'_, Sqlite>, audience: &StoryAudience, now: i64,
) -> Result<Vec<i64>> {
    let reachable = sqlx::query_scalar!(
        r#"SELECT c.user_id FROM contacts c
           WHERE c.accepted = 1 AND c.blocked = 0
             AND c.deleted_by_user = 0 AND c.account_deleted = 0
             AND (? = 0 OR EXISTS (
                 SELECT 1 FROM groups g
                 JOIN group_members gm ON gm.group_id = g.group_id
                 WHERE gm.contact_id = c.user_id AND g.is_direct_chat = 1
                   AND g.last_text_or_media_at > ?
             ))"#,
        audience.all,
        now - STORY_AUDIENCE_RECENT_EXCHANGE_SECONDS
    )
    .fetch_all(&mut **t)
    .await?
    .into_iter()
    .collect::<BTreeSet<i64>>();

    if audience.all {
        return Ok(reachable.into_iter().collect());
    }

    let mut members = BTreeSet::new();

    for contact_group_id in &audience.contact_group_ids {
        let direct = sqlx::query_scalar!(
            r#"SELECT cgm.user_id AS "user_id!: i64"
               FROM contact_group_members cgm
               JOIN contact_groups cg ON cg.id = cgm.contact_group_id
               WHERE cg.id = ? AND cg.share_stories = 1 AND cgm.user_id IS NOT NULL"#,
            contact_group_id,
        )
        .fetch_all(&mut **t)
        .await?;

        let via_chats = sqlx::query_scalar!(
            r#"SELECT gm.contact_id
               FROM contact_group_members cgm
               JOIN contact_groups cg ON cg.id = cgm.contact_group_id
               JOIN group_members gm ON gm.group_id = cgm.group_id
               WHERE cg.id = ? AND cg.share_stories = 1 AND cgm.group_id IS NOT NULL
                 AND (gm.member_state IS NULL OR gm.member_state != 'leftGroup')"#,
            contact_group_id,
        )
        .fetch_all(&mut **t)
        .await?;

        members.extend(direct);

        members.extend(via_chats);
    }

    Ok(members.intersection(&reachable).copied().collect())
}

/// The 1:1 chats a story sent to `audience` would go to right now, one per
/// contact it reaches. Explicit contact groups can include chats not created
/// yet, by the id they will get. "All contacts" only includes existing chats.
pub async fn audience_chats(ctx: &Arc<Context>, audience: &StoryAudience) -> Result<Vec<String>> {
    let user_id = ctx.user_id().await?;

    let database = ctx.app_db.read().await.clone();

    let mut transaction = database.pool.begin().await?;

    let contacts =
        resolve_audience(&mut transaction, audience, chrono::Utc::now().timestamp()).await?;

    transaction.rollback().await?;

    Ok(contacts
        .into_iter()
        .map(|contact_id| Group::direct_chat_id(user_id, contact_id))
        .collect())
}

/// The 1:1 chat a story row for `contact_id` is filed under, created if the
/// two never wrote to each other.
pub(crate) async fn direct_chat(
    ctx: &Context, t: &mut Transaction<'_, Sqlite>, contact_id: i64,
) -> Result<String> {
    let group_id = Group::direct_chat_id(ctx.user_id().await?, contact_id);

    let exists = sqlx::query_scalar!(
        r#"SELECT EXISTS(SELECT 1 FROM groups WHERE group_id = ?) AS "exists!: bool""#,
        group_id,
    )
    .fetch_one(&mut **t)
    .await?;

    if !exists {
        let contact = Contact::get_contact_by_id(t, contact_id)
            .await?
            .ok_or_else(|| TwonlyError::Generic(format!("contact {contact_id} does not exist")))?;

        Group::create_direct_chat(ctx, t, contact).await?;
    }

    Ok(group_id)
}

/// Removes story rows that are no longer a story. A row some message quotes is
/// kept as a tombstone without media, so the quote can say the story is gone
/// instead of pointing at nothing. Returns the media the rows let go of.
pub(crate) async fn retire_rows(
    t: &mut Transaction<'_, Sqlite>, message_ids: &[String], now: i64,
) -> Result<BTreeSet<String>> {
    let mut released = BTreeSet::new();

    for message_id in message_ids {
        if let Some(media_id) = sqlx::query_scalar!(
            "SELECT media_id FROM messages WHERE message_id = ?",
            message_id,
        )
        .fetch_optional(&mut **t)
        .await?
        .flatten()
        {
            released.insert(media_id);
        }

        // A tombstone keeps its row, so nothing cascades to what hangs off it.
        sqlx::query!("DELETE FROM receipts WHERE message_id = ?", message_id)
            .execute(&mut **t)
            .await?;

        sqlx::query!(
            r#"UPDATE notification_outbox SET cleared_at = ?
               WHERE message_id = ? AND kind = 'story' AND cleared_at IS NULL"#,
            now,
            message_id,
        )
        .execute(&mut **t)
        .await?;

        let quoted = sqlx::query_scalar!(
            r#"SELECT EXISTS(SELECT 1 FROM messages WHERE quotes_message_id = ?) AS "quoted!: bool""#,
            message_id,
        )
        .fetch_one(&mut **t)
        .await?;

        if quoted {
            sqlx::query!(
                "UPDATE messages SET media_id = NULL WHERE message_id = ?",
                message_id,
            )
            .execute(&mut **t)
            .await?;
        } else {
            sqlx::query!("DELETE FROM messages WHERE message_id = ?", message_id)
                .execute(&mut **t)
                .await?;
        }
    }

    Ok(released)
}

/// Deletes the media files that `retire_rows` let go of and nothing else holds.
pub(crate) async fn release_media(
    ctx: &Arc<Context>, t: &mut Transaction<'_, Sqlite>, media_ids: BTreeSet<String>,
) -> Result<()> {
    for media_id in media_ids {
        let media = sqlx::query!(
            r#"SELECT type AS media_type, stored, is_draft_media FROM media_files
               WHERE media_id = ?
                 AND NOT EXISTS (SELECT 1 FROM messages WHERE media_id = media_files.media_id)"#,
            media_id,
        )
        .fetch_optional(&mut **t)
        .await?;

        let Some(media) = media else {
            continue;
        };

        if media.stored != 0 || media.is_draft_media != 0 {
            continue;
        }

        sqlx::query!("DELETE FROM media_files WHERE media_id = ?", media_id)
            .execute(&mut **t)
            .await?;

        MediaFileService::new(ctx).remove_files(&media_id, &media.media_type)?;
    }

    Ok(())
}

/// Lets every story item older than 24 hours go, on both ends: a received one
/// disappears from its sender's ring, and an own one stops being retried for
/// recipients that never acknowledged it. Saved items stay, as ordinary stored
/// media in their chat.
pub async fn purge_expired(ctx: &Arc<Context>) -> Result<()> {
    let now = chrono::Utc::now().timestamp();

    let cutoff = now - STORY_LIFETIME_SECONDS;

    let database = ctx.app_db.read().await.clone();

    let mut transaction = database.pool.begin().await?;

    let expired = sqlx::query_scalar!(
        r#"SELECT message_id FROM messages
           WHERE is_story = 1 AND media_stored = 0 AND created_at <= ?"#,
        cutoff,
    )
    .fetch_all(&mut *transaction)
    .await?;

    if expired.is_empty() {
        return Ok(());
    }

    let released = retire_rows(&mut transaction, &expired, now).await?;

    release_media(ctx, &mut transaction, released).await?;

    transaction.commit().await?;

    tracing::info!(count = expired.len(), "purged expired story rows");

    Ok(())
}

/// Takes one of the user's own story items down before it expires: every
/// recipient is told to drop it if it was dispatched. Unsent uploads are
/// cancelled first, so nobody receives either the story or a deletion.
pub async fn delete_item(ctx: &Arc<Context>, media_id: &str) -> Result<()> {
    let lock = media_lock(media_id);

    let _guard = lock.lock().await;

    let database = ctx.app_db.read().await.clone();

    let rows = sqlx::query!(
        r#"SELECT message_id, group_id FROM messages
           WHERE media_id = ? AND is_story = 1 AND sender_id IS NULL AND media_stored = 0"#,
        media_id,
    )
    .fetch_all(&database.pool)
    .await?;

    if rows.is_empty() {
        return Ok(());
    }

    let uploaded = sqlx::query_scalar!(
        "SELECT EXISTS(SELECT 1 FROM media_files WHERE media_id = ? AND upload_state = 'uploaded')",
        media_id
    )
    .fetch_one(&database.pool)
    .await?
        != 0;

    // The media lock keeps preparation and reconciliation from racing this
    // decision. The server arbitrates cancellation against final dispatch.
    let dispatched = DirectMediaUploadService::new(ctx)
        .cancel_pending_upload(media_id)
        .await?
        || uploaded;

    drop(database);

    let timestamp = chrono::Utc::now().timestamp_millis();

    let messages = MessageService::new(ctx);

    for row in rows.iter().filter(|_| dispatched) {
        let content = EncryptedContent {
            message_update: Some(encrypted_content::MessageUpdate {
                r#type: encrypted_content::message_update::Type::Delete as i32,
                sender_message_id: Some(row.message_id.clone()),
                multiple_target_message_ids: Vec::new(),
                text: None,
                timestamp,
            }),
            ..Default::default()
        };

        messages
            .send_to_group(row.group_id.clone(), content.encode_to_vec(), None, false)
            .await?;
    }

    let message_ids = rows
        .into_iter()
        .map(|row| row.message_id)
        .collect::<Vec<_>>();

    let database = ctx.app_db.read().await.clone();

    let mut transaction = database.pool.begin().await?;

    let released = retire_rows(&mut transaction, &message_ids, timestamp / 1_000).await?;

    // A stored Memory may outlive the story. Stop retrying its cancelled send;
    // if the same media was also sent in a chat, prepare that remaining send
    // again with a fresh manifest that no longer includes story recipients.
    if !dispatched {
        sqlx::query!(
            r#"UPDATE media_files SET upload_state = CASE
                 WHEN EXISTS(SELECT 1 FROM messages WHERE media_id = ?)
                 THEN 'preprocessing' ELSE 'storedOnly' END
               WHERE media_id = ?"#,
            media_id,
            media_id
        )
        .execute(&mut *transaction)
        .await?;
    }

    release_media(ctx, &mut transaction, released).await?;

    transaction.commit().await?;

    Ok(())
}

#[cfg(test)]
mod tests {

    use super::*;

    async fn context() -> Result<(tempfile::TempDir, Arc<Context>)> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        crate::user_config::UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"ben","displayName":"Ben"}"#,
        )?;

        ctx.inject_test_user_id(42).await?;

        Ok((directory, ctx))
    }

    async fn execute(ctx: &Context, statements: &[&str]) -> Result<()> {
        let database = ctx.app_db.read().await.clone();

        for statement in statements {
            sqlx::query(sqlx::AssertSqlSafe(*statement))
                .execute(&database.pool)
                .await?;
        }

        Ok(())
    }

    #[tokio::test]

    async fn an_audience_reaches_reachable_contacts_of_story_groups() -> Result<()> {
        let (_directory, ctx) = context().await?;

        execute(
            &ctx,
            &[
                "INSERT INTO contacts(user_id, username, accepted) VALUES (1, 'a', 1)",
                "INSERT INTO contacts(user_id, username, accepted, blocked) VALUES (2, 'b', 1, 1)",
                "INSERT INTO contacts(user_id, username, accepted, deleted_by_user) VALUES (3, \
                 'c', 1, 1)",
                "INSERT INTO contacts(user_id, username) VALUES (4, 'd')",
                "INSERT INTO contacts(user_id, username, accepted, account_deleted) VALUES (5, \
                 'e', 1, 1)",
                "INSERT INTO contacts(user_id, username, accepted) VALUES (6, 'f', 1)",
                "INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'g', 1)",
                "INSERT INTO contacts(user_id, username, accepted) VALUES (8, 'h', 1)",
                "INSERT INTO groups(group_id, group_name) VALUES ('trip', 'Trip')",
                "INSERT INTO group_members(group_id, contact_id) VALUES ('trip', 7)",
                "INSERT INTO group_members(group_id, contact_id, member_state) VALUES ('trip', 8, \
                 'leftGroup')",
                "INSERT INTO group_members(group_id, contact_id) VALUES ('trip', 2)",
                "INSERT INTO contact_groups(id, name, text_color, background_color, \
                 share_stories) VALUES (1, 'Close', 0, 0, 1)",
                "INSERT INTO contact_groups(id, name, text_color, background_color, \
                 share_stories) VALUES (2, 'Work', 0, 0, 0)",
                "INSERT INTO contact_group_members(contact_group_id, user_id) VALUES (1, 1)",
                "INSERT INTO contact_group_members(contact_group_id, user_id) VALUES (1, 4)",
                "INSERT INTO contact_group_members(contact_group_id, group_id) VALUES (1, 'trip')",
                "INSERT INTO contact_group_members(contact_group_id, user_id) VALUES (2, 6)",
            ],
        )
        .await?;

        let database = ctx.app_db.read().await.clone();

        let mut t = database.pool.begin().await?;

        let resolve = |all: bool, groups: &[i64]| StoryAudience {
            all,
            contact_group_ids: groups.to_vec(),
        };

        assert_eq!(
            resolve_audience(&mut t, &resolve(true, &[]), 1_000_000_000).await?,
            Vec::<i64>::new()
        );

        // Blocked (2) and not accepted (4) members stay out, and so does the
        // member who left the chat group (8).
        assert_eq!(
            resolve_audience(&mut t, &resolve(false, &[1]), 1_000_000_000).await?,
            vec![1, 7]
        );

        // A group that does not share stories reaches nobody.
        assert_eq!(
            resolve_audience(&mut t, &resolve(false, &[2]), 1_000_000_000).await?,
            Vec::<i64>::new()
        );

        assert_eq!(
            resolve_audience(&mut t, &resolve(false, &[1, 2]), 1_000_000_000).await?,
            vec![1, 7]
        );

        Ok(())
    }

    #[tokio::test]

    async fn all_contacts_requires_a_direct_exchange_within_thirty_days() -> Result<()> {
        let (_directory, ctx) = context().await?;

        let now = 1_000_000_000;

        let cutoff = now - STORY_AUDIENCE_RECENT_EXCHANGE_SECONDS;

        let database = ctx.app_db.read().await.clone();

        let mut t = database.pool.begin().await?;

        for contact_id in 1..=10 {
            sqlx::query("INSERT INTO contacts(user_id, username, accepted) VALUES (?, ?, 1)")
                .bind(contact_id)
                .bind(format!("contact-{contact_id}"))
                .execute(&mut *t)
                .await?;
        }

        // No chat (1), no exchange (2), expired exchange (3), exact cutoff (4),
        // just inside (5), outside the notification window (6), recent (7),
        // recent but unreachable (8, 9), and only a shared group (10).
        for (contact_id, last_exchange) in [
            (2, None),
            (3, Some(cutoff - 1)),
            (4, Some(cutoff)),
            (5, Some(cutoff + 1)),
            (6, Some(now - 21 * 24 * 60 * 60)),
            (7, Some(now - 60)),
            (8, Some(now - 60)),
            (9, Some(now - 60)),
        ] {
            let group_id = direct_chat(&ctx, &mut t, contact_id).await?;

            sqlx::query("UPDATE groups SET last_text_or_media_at = ? WHERE group_id = ?")
                .bind(last_exchange)
                .bind(group_id)
                .execute(&mut *t)
                .await?;
        }

        sqlx::query("UPDATE contacts SET blocked = 1 WHERE user_id = 8")
            .execute(&mut *t)
            .await?;

        sqlx::query("UPDATE contacts SET accepted = 0 WHERE user_id = 9")
            .execute(&mut *t)
            .await?;

        sqlx::query(
            "INSERT INTO groups(group_id, group_name, last_text_or_media_at) VALUES ('trip', \
             'Trip', ?)",
        )
        .bind(now)
        .execute(&mut *t)
        .await?;

        sqlx::query("INSERT INTO group_members(group_id, contact_id) VALUES ('trip', 10)")
            .execute(&mut *t)
            .await?;

        let all = StoryAudience {
            all: true,
            contact_group_ids: vec![],
        };

        assert_eq!(resolve_audience(&mut t, &all, now).await?, vec![5, 6, 7]);

        Ok(())
    }

    #[tokio::test]

    async fn an_audience_is_named_by_the_chats_it_reaches() -> Result<()> {
        let (_directory, ctx) = context().await?;

        execute(
            &ctx,
            &[
                "INSERT INTO contacts(user_id, username, accepted) VALUES (1, 'a', 1)",
                "INSERT INTO contacts(user_id, username, accepted) VALUES (77, 'b', 1)",
                "INSERT INTO contacts(user_id, username) VALUES (3, 'c')",
            ],
        )
        .await?;

        let everybody = StoryAudience {
            all: true,
            contact_group_ids: vec![],
        };

        // "All" never proposes a new chat, while explicit story groups may.
        assert!(audience_chats(&ctx, &everybody).await?.is_empty());

        execute(
            &ctx,
            &[
                "INSERT INTO contact_groups(id, name, text_color, background_color, \
                 share_stories) VALUES (1, 'Close', 0, 0, 1)",
                "INSERT INTO contact_group_members(contact_group_id, user_id) VALUES (1, 1), (1, \
                 77)",
            ],
        )
        .await?;

        let explicit = StoryAudience {
            all: false,
            contact_group_ids: vec![1],
        };

        assert_eq!(
            audience_chats(&ctx, &explicit).await?,
            vec![Group::direct_chat_id(42, 1), Group::direct_chat_id(42, 77)]
        );

        let database = ctx.app_db.read().await.clone();

        let mut t = database.pool.begin().await?;

        let group_id = direct_chat(&ctx, &mut t, 1).await?;

        Group::record_text_or_media(&mut t, &group_id, chrono::Utc::now().timestamp()).await?;

        t.commit().await?;

        assert_eq!(audience_chats(&ctx, &everybody).await?, vec![group_id]);

        Ok(())
    }

    #[tokio::test]

    async fn deleting_unsent_story_stops_retries_without_notifying_recipients() -> Result<()> {
        let (_directory, ctx) = context().await?;

        execute(
            &ctx,
            &[
                "INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'anna', 1)",
                "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('d', 'Anna', 1)",
                "INSERT INTO group_members(group_id, contact_id) VALUES ('d', 7)",
            ],
        )
        .await?;

        let database = ctx.app_db.read().await.clone();

        for state in [
            "initialized",
            "preprocessing",
            "uploading",
            "uploadLimitReached",
            "fileLimitReached",
        ] {
            for stored in [false, true] {
                sqlx::query(
                    "INSERT INTO media_files(media_id, type, upload_state, stored) VALUES ('m', \
                     'image', ?, ?)",
                )
                .bind(state)
                .bind(stored)
                .execute(&database.pool)
                .await?;

                execute(
                    &ctx,
                    &[
                        "INSERT INTO messages(message_id, group_id, type, media_id, is_story) \
                         VALUES ('s', 'd', 'media', 'm', 1)",
                        "INSERT INTO receipts(receipt_id, contact_id, message_id, message, \
                         will_be_retried_by_media_upload) VALUES ('r', 7, 's', x'00', 1)",
                    ],
                )
                .await?;

                delete_item(&ctx, "m").await?;

                delete_item(&ctx, "m").await?;

                let messages: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM messages")
                    .fetch_one(&database.pool)
                    .await?;

                let receipts: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM receipts")
                    .fetch_one(&database.pool)
                    .await?;

                assert_eq!(messages, 0);

                assert_eq!(receipts, 0, "no deletion or upload receipt is queued");

                let media: Option<(i64, Option<String>)> = sqlx::query_as(
                    "SELECT stored, upload_state FROM media_files WHERE media_id = 'm'",
                )
                .fetch_optional(&database.pool)
                .await?;

                if stored {
                    assert_eq!(media, Some((1, Some("storedOnly".into()))));

                    sqlx::query("DELETE FROM media_files WHERE media_id = 'm'")
                        .execute(&database.pool)
                        .await?;
                } else {
                    assert!(media.is_none());
                }
            }
        }

        Ok(())
    }

    #[tokio::test]

    async fn deleting_unsent_story_preserves_its_shared_chat_send_and_quotes() -> Result<()> {
        let (_directory, ctx) = context().await?;

        execute(
            &ctx,
            &[
                "INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'anna', 1)",
                "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('d', 'Anna', 1)",
                "INSERT INTO group_members(group_id, contact_id) VALUES ('d', 7)",
                "INSERT INTO media_files(media_id, type, upload_state) VALUES ('m', 'image', \
                 'preprocessing')",
                "INSERT INTO messages(message_id, group_id, type, media_id, is_story) VALUES \
                 ('s', 'd', 'media', 'm', 1), ('chat', 'd', 'media', 'm', 0)",
                "INSERT INTO messages(message_id, group_id, type, content, quotes_message_id) \
                 VALUES ('reply', 'd', 'text', 'Reply', 's')",
                "INSERT INTO receipts(receipt_id, contact_id, message_id, message) VALUES ('rs', \
                 7, 's', x'00'), ('rc', 7, 'chat', x'00')",
            ],
        )
        .await?;

        delete_item(&ctx, "m").await?;

        let database = ctx.app_db.read().await.clone();

        let rows: Vec<(String, Option<String>)> =
            sqlx::query_as("SELECT message_id, media_id FROM messages ORDER BY message_id")
                .fetch_all(&database.pool)
                .await?;

        assert_eq!(
            rows,
            vec![
                ("chat".into(), Some("m".into())),
                ("reply".into(), None),
                ("s".into(), None)
            ]
        );

        let state: String =
            sqlx::query_scalar("SELECT upload_state FROM media_files WHERE media_id = 'm'")
                .fetch_one(&database.pool)
                .await?;

        assert_eq!(state, "preprocessing");

        let receipts: Vec<String> = sqlx::query_scalar("SELECT receipt_id FROM receipts")
            .fetch_all(&database.pool)
            .await?;

        assert_eq!(receipts, vec!["rc"]);

        Ok(())
    }

    #[tokio::test]

    async fn expired_story_rows_leave_unless_saved_or_quoted() -> Result<()> {
        let (_directory, ctx) = context().await?;

        let now = chrono::Utc::now().timestamp();

        let expired = now - STORY_LIFETIME_SECONDS - 60;

        let fresh = now - 60;

        let statements = [
            "INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'anna', 1)".to_owned(),
            "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('d', 'Anna', 1)"
                .to_owned(),
            "INSERT INTO media_files(media_id, type) VALUES ('m1', 'image'), ('m2', 'image'), \
             ('m3', 'image'), ('m4', 'image')"
                .to_owned(),
            format!(
                "INSERT INTO messages(message_id, group_id, sender_id, type, media_id, is_story, \
                 created_at) VALUES ('gone', 'd', 7, 'media', 'm1', 1, {expired})"
            ),
            format!(
                "INSERT INTO messages(message_id, group_id, sender_id, type, media_id, is_story, \
                 created_at) VALUES ('quoted', 'd', 7, 'media', 'm2', 1, {expired})"
            ),
            format!(
                "INSERT INTO messages(message_id, group_id, sender_id, type, media_id, is_story, \
                 media_stored, created_at) VALUES ('saved', 'd', 7, 'media', 'm3', 1, 1, \
                 {expired})"
            ),
            format!(
                "INSERT INTO messages(message_id, group_id, sender_id, type, media_id, is_story, \
                 created_at) VALUES ('live', 'd', 7, 'media', 'm4', 1, {fresh})"
            ),
            "INSERT INTO messages(message_id, group_id, type, content, quotes_message_id) VALUES \
             ('reply', 'd', 'text', '🔥', 'quoted')"
                .to_owned(),
            "INSERT INTO receipts(receipt_id, contact_id, message_id, message) VALUES ('r1', 7, \
             'gone', x'00'), ('r2', 7, 'quoted', x'00')"
                .to_owned(),
        ];

        let statements = statements.iter().map(String::as_str).collect::<Vec<_>>();

        execute(&ctx, &statements).await?;

        purge_expired(&ctx).await?;

        let database = ctx.app_db.read().await.clone();

        let rows: Vec<(String, Option<String>)> =
            sqlx::query_as("SELECT message_id, media_id FROM messages ORDER BY message_id")
                .fetch_all(&database.pool)
                .await?;

        assert_eq!(
            rows,
            vec![
                ("live".into(), Some("m4".into())),
                // Kept so the reply can still say what it answered.
                ("quoted".into(), None),
                ("reply".into(), None),
                ("saved".into(), Some("m3".into())),
            ]
        );

        let media: Vec<String> =
            sqlx::query_scalar("SELECT media_id FROM media_files ORDER BY media_id")
                .fetch_all(&database.pool)
                .await?;

        assert_eq!(media, vec!["m3".to_owned(), "m4".to_owned()]);

        let receipts: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM receipts")
            .fetch_one(&database.pool)
            .await?;

        assert_eq!(receipts, 0);

        // Once nothing quotes the tombstone any more, it goes too.
        sqlx::query("DELETE FROM messages WHERE message_id = 'reply'")
            .execute(&database.pool)
            .await?;

        purge_expired(&ctx).await?;

        let quoted: i64 =
            sqlx::query_scalar("SELECT COUNT(*) FROM messages WHERE message_id = 'quoted'")
                .fetch_one(&database.pool)
                .await?;

        assert_eq!(quoted, 0);

        Ok(())
    }
}
