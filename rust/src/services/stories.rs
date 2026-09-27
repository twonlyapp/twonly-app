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
use crate::database::app::tables::{Contact, Group};
use crate::error::{Result, TwonlyError};
use crate::services::mediafiles::MediaFileService;
use crate::services::messages::MessageService;
use prost::Message as _;
use sqlx::{Sqlite, Transaction};
use std::collections::BTreeSet;
use std::sync::Arc;

/// How long a story item is visible after its sender posted it.
pub const STORY_LIFETIME_SECONDS: i64 = 24 * 60 * 60;

/// A story is announced only between people who sent each other a text or
/// media message within this long.
pub const STORY_ANNOUNCE_RECENT_EXCHANGE_SECONDS: i64 = 14 * 24 * 60 * 60;

/// Whether the 1:1 chat `group_id` carried a text or media message, either
/// way, within the last two weeks.
pub(crate) async fn exchanged_recently(
    t: &mut Transaction<'_, Sqlite>,
    group_id: &str,
    now: i64,
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

/// Who a story item goes to: every contact, or the members of the selected
/// contact groups that share stories.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct StoryAudience {
    pub all: bool,
    pub contact_group_ids: Vec<i64>,
}

/// The contacts `audience` reaches, in ascending order. Blocked and deleted
/// contacts are left out, as are group members who left.
pub(crate) async fn resolve_audience(
    t: &mut Transaction<'_, Sqlite>,
    audience: &StoryAudience,
) -> Result<Vec<i64>> {
    let reachable = sqlx::query_scalar!(
        r#"SELECT user_id FROM contacts
           WHERE accepted = 1 AND blocked = 0 AND deleted_by_user = 0 AND account_deleted = 0"#
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
/// contact it reaches. Chats not created yet are included by the id they
/// will get, so the list lines up with chats picked for a direct send.
pub async fn audience_chats(ctx: &Arc<Context>, audience: &StoryAudience) -> Result<Vec<String>> {
    let user_id = ctx.user_id().await?;
    let database = ctx.app_db.read().await.clone();
    let mut transaction = database.pool.begin().await?;
    let contacts = resolve_audience(&mut transaction, audience).await?;
    transaction.rollback().await?;
    Ok(contacts
        .into_iter()
        .map(|contact_id| Group::direct_chat_id(user_id, contact_id))
        .collect())
}

/// The 1:1 chat a story row for `contact_id` is filed under, created if the
/// two never wrote to each other.
pub(crate) async fn direct_chat(
    ctx: &Context,
    t: &mut Transaction<'_, Sqlite>,
    contact_id: i64,
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
async fn retire_rows(
    t: &mut Transaction<'_, Sqlite>,
    message_ids: &[String],
    now: i64,
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
async fn release_media(
    ctx: &Arc<Context>,
    t: &mut Transaction<'_, Sqlite>,
    media_ids: BTreeSet<String>,
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
/// recipient is told to drop it, and the item goes here too. Items whose upload
/// has not finished are refused, since a delete could overtake the media and
/// the item would then arrive after all.
pub async fn delete_item(ctx: &Arc<Context>, media_id: &str) -> Result<()> {
    let database = ctx.app_db.read().await.clone();
    let upload_state = sqlx::query_scalar!(
        "SELECT upload_state FROM media_files WHERE media_id = ?",
        media_id,
    )
    .fetch_optional(&database.pool)
    .await?
    .flatten();
    if upload_state.as_deref() != Some("uploaded") {
        return Err(TwonlyError::Generic(
            "a story item can only be deleted once its upload finished".into(),
        ));
    }
    let rows = sqlx::query!(
        r#"SELECT message_id, group_id FROM messages
           WHERE media_id = ? AND is_story = 1 AND sender_id IS NULL AND media_stored = 0"#,
        media_id,
    )
    .fetch_all(&database.pool)
    .await?;
    drop(database);

    let timestamp = chrono::Utc::now().timestamp_millis();
    let messages = MessageService::new(ctx);
    for row in &rows {
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
                "INSERT INTO contacts(user_id, username, accepted, deleted_by_user) VALUES (3, 'c', 1, 1)",
                "INSERT INTO contacts(user_id, username) VALUES (4, 'd')",
                "INSERT INTO contacts(user_id, username, accepted, account_deleted) VALUES (5, 'e', 1, 1)",
                "INSERT INTO contacts(user_id, username, accepted) VALUES (6, 'f', 1)",
                "INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'g', 1)",
                "INSERT INTO contacts(user_id, username, accepted) VALUES (8, 'h', 1)",
                "INSERT INTO groups(group_id, group_name) VALUES ('trip', 'Trip')",
                "INSERT INTO group_members(group_id, contact_id) VALUES ('trip', 7)",
                "INSERT INTO group_members(group_id, contact_id, member_state) VALUES ('trip', 8, 'leftGroup')",
                "INSERT INTO group_members(group_id, contact_id) VALUES ('trip', 2)",
                "INSERT INTO contact_groups(id, name, text_color, background_color, share_stories) VALUES (1, 'Close', 0, 0, 1)",
                "INSERT INTO contact_groups(id, name, text_color, background_color, share_stories) VALUES (2, 'Work', 0, 0, 0)",
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
            resolve_audience(&mut t, &resolve(true, &[])).await?,
            vec![1, 6, 7, 8]
        );
        // Blocked (2) and not accepted (4) members stay out, and so does the
        // member who left the chat group (8).
        assert_eq!(
            resolve_audience(&mut t, &resolve(false, &[1])).await?,
            vec![1, 7]
        );
        // A group that does not share stories reaches nobody.
        assert_eq!(
            resolve_audience(&mut t, &resolve(false, &[2])).await?,
            Vec::<i64>::new()
        );
        assert_eq!(
            resolve_audience(&mut t, &resolve(false, &[1, 2])).await?,
            vec![1, 7]
        );
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
        // No chat with either exists yet; the ids are the ones they will get,
        // so they can be compared with chats picked for a direct send.
        assert_eq!(
            audience_chats(&ctx, &everybody).await?,
            vec![Group::direct_chat_id(42, 1), Group::direct_chat_id(42, 77)]
        );
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
            "INSERT INTO media_files(media_id, type) VALUES ('m1', 'image'), ('m2', 'image'), ('m3', 'image'), ('m4', 'image')".to_owned(),
            format!("INSERT INTO messages(message_id, group_id, sender_id, type, media_id, is_story, created_at) VALUES ('gone', 'd', 7, 'media', 'm1', 1, {expired})"),
            format!("INSERT INTO messages(message_id, group_id, sender_id, type, media_id, is_story, created_at) VALUES ('quoted', 'd', 7, 'media', 'm2', 1, {expired})"),
            format!("INSERT INTO messages(message_id, group_id, sender_id, type, media_id, is_story, media_stored, created_at) VALUES ('saved', 'd', 7, 'media', 'm3', 1, 1, {expired})"),
            format!("INSERT INTO messages(message_id, group_id, sender_id, type, media_id, is_story, created_at) VALUES ('live', 'd', 7, 'media', 'm4', 1, {fresh})"),
            "INSERT INTO messages(message_id, group_id, type, content, quotes_message_id) VALUES ('reply', 'd', 'text', '🔥', 'quoted')".to_owned(),
            "INSERT INTO receipts(receipt_id, contact_id, message_id, message) VALUES ('r1', 7, 'gone', x'00'), ('r2', 7, 'quoted', x'00')".to_owned(),
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
