use super::table::*;
use crate::database::app::contacts::table::Contact;
use crate::error::Result;
use sqlx::SqliteConnection;

pub async fn list(
    connection: &mut SqliteConnection, ids: &[String],
) -> Result<Vec<StoredReaction>> {
    if ids.is_empty() {
        return Ok(Vec::new());
    }

    Ok(sqlx::query_as!(
        StoredReaction,
        r#"
            SELECT message_id,
                emoji,
                sender_id,
                created_at
            FROM reactions
            WHERE message_id IN (
                SELECT value
                FROM json_each(?)
            )
            ORDER BY created_at DESC,
                rowid DESC
        "#,
        serde_json::to_string(ids)?,
    )
    .fetch_all(connection)
    .await?)
}

pub async fn last(
    connection: &mut SqliteConnection, group: &str,
) -> Result<Option<StoredReaction>> {
    Ok(sqlx::query_as!(
        StoredReaction,
        r#"
            SELECT r.message_id,
                r.emoji,
                r.sender_id,
                r.created_at
            FROM reactions r
            JOIN messages m
            ON m.message_id = r.message_id
            WHERE m.group_id = ?
                AND (m.is_story = 0
                    OR m.media_stored = 1
            )
            ORDER BY m.created_at DESC,
                r.created_at DESC,
                r.rowid DESC
            LIMIT 1
        "#,
        group,
    )
    .fetch_optional(connection)
    .await?)
}

pub async fn latest_by_group(connection: &mut SqliteConnection) -> Result<Vec<GroupReaction>> {
    crate::performance::rows("sqlite.reactions.latest_by_group", async {
        let rows = sqlx::query!(
            r#"
            SELECT group_id AS "group_id!",
                message_id AS "message_id!",
                emoji AS "emoji!",
                sender_id,
                created_at AS "created_at!"
            FROM (
                SELECT m.group_id,
                    r.message_id,
                    r.emoji,
                    r.sender_id,
                    r.created_at,
                    ROW_NUMBER() OVER (
                        PARTITION BY m.group_id
                        ORDER BY m.created_at DESC, r.created_at DESC, r.rowid DESC
                    ) AS rank
                FROM reactions r
                JOIN messages m ON m.message_id = r.message_id
                WHERE m.is_story = 0 OR m.media_stored = 1
            )
            WHERE rank = 1
            ORDER BY group_id
        "#,
        )
        .fetch_all(connection)
        .await?;

        Ok(rows
            .into_iter()
            .map(|row| GroupReaction {
                group_id: row.group_id,
                reaction: StoredReaction {
                    message_id: row.message_id,
                    emoji: row.emoji,
                    sender_id: row.sender_id,
                    created_at: row.created_at,
                },
            })
            .collect())
    })
    .await
}

pub async fn with_contacts(
    connection: &mut SqliteConnection, message: &str,
) -> Result<ReactionsWithContacts> {
    let reactions = sqlx::query_as!(
        StoredReaction,
        r#"
            SELECT message_id,
                emoji,
                sender_id,
                created_at
            FROM reactions
            WHERE message_id = ?
            ORDER BY rowid
        "#,
        message,
    )
    .fetch_all(&mut *connection)
    .await?;

    let contacts = sqlx::query_as!(
        Contact,
        r#"
            SELECT user_id, username, display_name, nick_name, avatar_svg_compressed, prefer_photo_avatar,
            sender_profile_counter, accepted, deleted_by_user, requested, requested_by_user, blocked,
            verified, account_deleted, created_at, signal_version, user_discovery_version,
            user_discovery_excluded, user_discovery_manual_approved, recovery_is_trusted_friend,
            recovery_last_heartbeat, recovery_secret_share, recovery_contacts_secret_share,
            recovery_contacts_last_heartbeat, recovery_contacts_threshold, ask_for_friend_promotions,
            media_send_counter, media_received_counter, widget_sharing_allowed, widget_sharing_granted,
            twonly_score, joined_at
            FROM contacts
            WHERE user_id IN (
                SELECT sender_id
                FROM reactions
                WHERE message_id = ?
            )
            ORDER BY user_id
        "#,
        message,
    )
    .fetch_all(connection)
    .await?;

    Ok(ReactionsWithContacts {
        reactions,
        contacts,
    })
}
