use super::table::*;
use crate::database::app::{contacts, mediafiles, messages};
use crate::error::Result;
use sqlx::SqliteConnection;

pub async fn received(
    connection: &mut SqliteConnection, cutoff: i64, group: Option<&str>, contact: Option<i64>,
) -> Result<ReceivedStories> {
    let messages: Vec<messages::table::StoredMessage> = sqlx::query_as!(
        messages::table::StoredMessage,
        r#"
            SELECT m.group_id AS "group_id!",
                m.message_id AS "message_id!",
                NULL AS "activity_message_id?: String",
                m.sender_id AS "original_sender_id?",
                m.sender_id AS "sender_id?",
                m.type AS "type!",
                m.content AS "content?",
                m.media_id AS "media_id?",
                m.additional_message_data AS "additional_message_data?",
                m.media_stored AS "media_stored!: bool",
                m.media_reopened AS "media_reopened!: bool",
                m.download_token AS "download_token?",
                m.quotes_message_id AS "quotes_message_id?",
                m.is_deleted_from_sender AS "is_deleted_from_sender!: bool",
                m.is_widget_media AS "is_widget_media!: bool",
                m.is_story AS "is_story!: bool",
                m.opened_at AS "opened_at?",
                m.opened_by_all AS "opened_by_all?",
                m.created_at AS "created_at!",
                m.modified_at AS "modified_at?",
                m.ack_by_user AS "ack_by_user?",
                m.ack_by_server AS "ack_by_server?"
            FROM messages m
            JOIN media_files f
            ON f.media_id = m.media_id
            JOIN contacts c
            ON c.user_id = m.sender_id
            WHERE m.is_story = 1
                AND m.sender_id IS NOT NULL
                AND m.is_deleted_from_sender = 0
                AND m.created_at > ?
                AND c.accepted = 1
                AND c.blocked = 0
                AND (f.download_state IS NULL
                    OR f.download_state != 'reuploadRequested'
            )
                AND (? IS NULL
                    OR m.group_id = ?
            )
                AND (? IS NULL
                    OR m.sender_id = ?
            )
            ORDER BY m.created_at,
                m.message_id
        "#,
        cutoff,
        group,
        group,
        contact,
        contact,
    )
    .fetch_all(&mut *connection)
    .await?;

    let ids = messages.iter().filter_map(|m| m.media_id.clone()).collect();

    let files = mediafiles::queries::list(
        connection,
        &mediafiles::table::MediaQuery {
            filter: mediafiles::table::MediaFilter::Ids,
            ids,
            group_id: None,
            hash: None,
            favorites_only: false,
        },
    )
    .await?;

    Ok(ReceivedStories { messages, files })
}

pub async fn own(connection: &mut SqliteConnection, cutoff: i64) -> Result<OwnStories> {
    let items: Vec<OwnStorySummary> = sqlx::query_as!(
        OwnStorySummary,
        r#"
            SELECT m.media_id AS "media_id!",
                MIN(m.created_at) AS "posted_at!",
                COUNT(*) AS "recipient_count!",
                SUM(CASE
                WHEN m.opened_at IS NULL THEN 0
                ELSE 1
                END
            ) AS "viewer_count!"
            FROM messages m
            JOIN media_files f
            ON f.media_id = m.media_id
            WHERE m.is_story = 1
                AND m.sender_id IS NULL
                AND m.created_at > ?
            GROUP BY m.media_id
            ORDER BY "posted_at!",
                m.media_id
        "#,
        cutoff,
    )
    .fetch_all(&mut *connection)
    .await?;

    let ids = items.iter().map(|i| i.media_id.clone()).collect();

    let files = mediafiles::queries::list(
        connection,
        &mediafiles::table::MediaQuery {
            filter: mediafiles::table::MediaFilter::Ids,
            ids,
            group_id: None,
            hash: None,
            favorites_only: false,
        },
    )
    .await?;

    Ok(OwnStories { items, files })
}

pub async fn viewers(connection: &mut SqliteConnection, media: &str) -> Result<StoryViewers> {
    let links: Vec<StoryViewerLink> = sqlx::query_as!(
        StoryViewerLink,
        r#"
            SELECT m.message_id AS "message_id!",
                gm.contact_id AS "contact_id!",
                COALESCE(opened.action_at,m.opened_at) AS "opened_at?",
                COALESCE(received.action_at,m.ack_by_user,opened.action_at,m.opened_at) AS "received_at?"
            FROM messages m
            JOIN group_members gm
            ON gm.group_id = m.group_id
            JOIN contacts c
            ON c.user_id = gm.contact_id
            LEFT JOIN message_actions received
            ON received.message_id = m.message_id
                AND received.contact_id = gm.contact_id
                AND received.type = 'ackByUserAt'
            LEFT JOIN message_actions opened
            ON opened.message_id = m.message_id
                AND opened.contact_id = gm.contact_id
                AND opened.type = 'openedAt'
            WHERE m.media_id = ?
                AND m.is_story = 1
                AND m.sender_id IS NULL
            ORDER BY "opened_at?" IS NULL,
                "opened_at?" DESC,
                "received_at?" IS NULL,
                "received_at?" DESC,
                c.username,
                m.message_id,
                gm.contact_id
        "#,
        media,
    )
    .fetch_all(&mut *connection)
    .await?;

    let message_ids = links.iter().map(|l| l.message_id.clone()).collect();

    let messages = messages::queries::list(
        connection,
        &messages::table::MessageQuery {
            filter: messages::table::MessageFilter::Ids,
            group_id: None,
            ids: message_ids,
            limit: 100,
            before: None,
            before_message_id: None,
            now_ms: 0,
        },
    )
    .await?;

    let ids = links.iter().map(|l| l.contact_id).collect();

    let contacts = contacts::queries::list(
        connection,
        &contacts::table::ContactQuery {
            filter: contacts::table::ContactFilter::Ids,
            ids,
            username: None,
            username2: None,
            required_send_images: 0,
            manual_approval: false,
        },
    )
    .await?;

    Ok(StoryViewers {
        links,
        messages,
        contacts,
    })
}
