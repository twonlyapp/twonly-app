use super::table::*;
use crate::database::app::contacts;
use crate::database::app::mediafiles::table::MediaFile;
use crate::error::Result;
use sqlx::SqliteConnection;

pub async fn get(connection: &mut SqliteConnection, id: &str) -> Result<Option<StoredMessage>> {
    Ok(sqlx::query_as!(
        StoredMessage,
        r#"
            SELECT
            group_id AS "group_id!",
                    message_id AS "message_id!",
                    activity_message_id AS "activity_message_id?: String",
                    original_sender_id AS "original_sender_id?: i64",
                    sender_id AS "sender_id?: i64",
                    type AS "type!",
                    content AS "content?",
                    media_id AS "media_id?",
                    additional_message_data AS "additional_message_data?",
                    media_stored AS "media_stored!: bool",
                    media_reopened AS "media_reopened!: bool",
                    download_token AS "download_token?",
                    quotes_message_id AS "quotes_message_id?",
                    is_deleted_from_sender AS "is_deleted_from_sender!: bool",
                    is_widget_media AS "is_widget_media!: bool",
                    is_story AS "is_story!: bool",
                    opened_at AS "opened_at?: i64",
                    opened_by_all AS "opened_by_all?: i64",
                    created_at AS "created_at!",
                    modified_at AS "modified_at?",
                    ack_by_user AS "ack_by_user?: i64",
                    ack_by_server AS "ack_by_server?: i64"
                FROM chat_messages WHERE message_id = ?
        "#,
        id,
    )
    .fetch_optional(connection)
    .await?)
}

pub async fn list(
    connection: &mut SqliteConnection, input: &MessageQuery,
) -> Result<Vec<StoredMessage>> {
    if matches!(input.filter, MessageFilter::LatestByGroup) {
        return Ok(sqlx::query_as!(
        StoredMessage,
        r#"
            SELECT
            group_id AS "group_id!",
                    message_id AS "message_id!",
                    activity_message_id AS "activity_message_id?: String",
                    original_sender_id AS "original_sender_id?: i64",
                    sender_id AS "sender_id?: i64",
                    type AS "type!",
                    content AS "content?",
                    media_id AS "media_id?",
                    additional_message_data AS "additional_message_data?",
                    media_stored AS "media_stored!: bool",
                    media_reopened AS "media_reopened!: bool",
                    download_token AS "download_token?",
                    quotes_message_id AS "quotes_message_id?",
                    is_deleted_from_sender AS "is_deleted_from_sender!: bool",
                    is_widget_media AS "is_widget_media!: bool",
                    is_story AS "is_story!: bool",
                    opened_at AS "opened_at?: i64",
                    opened_by_all AS "opened_by_all?: i64",
                    created_at AS "created_at!",
                    modified_at AS "modified_at?",
                    ack_by_user AS "ack_by_user?: i64",
                    ack_by_server AS "ack_by_server?: i64"
                FROM (
                        SELECT m.group_id, m.message_id, m.activity_message_id, m.original_sender_id, m.sender_id, m.type, m.content, m.media_id,
                            m.additional_message_data, m.media_stored, m.media_reopened, m.download_token,
                            m.quotes_message_id, m.is_deleted_from_sender, m.is_widget_media, m.is_story,
                            m.opened_at, m.opened_by_all, m.created_at, m.modified_at, m.ack_by_user,
                            m.ack_by_server, ROW_NUMBER() OVER (
                            PARTITION BY m.group_id
                            ORDER BY m.created_at DESC, m.message_id DESC
                        ) AS rank
                        FROM chat_messages m
                        JOIN groups g
                        ON g.group_id = m.group_id
                        LEFT JOIN media_files f
                        ON f.media_id = m.media_id
                        WHERE (m.is_story = 0
                                OR m.media_stored = 1
                        )
                            AND (m.type != 'media'
                                OR f.media_id IS NOT NULL
                                OR m.is_deleted_from_sender = 1
                        )
                            AND (m.opened_at IS NULL
                                OR m.media_stored = 1
                                OR m.type = 'webxdcApp'
                                OR m.opened_at > CAST(strftime('%s','now') AS INTEGER) -
                                    g.delete_messages_after_milliseconds / 1000
                        )
                            AND (f.download_state IS NULL
                                OR f.download_state != 'reuploadRequested'
                        )
                    )
                    WHERE rank = 1
                    ORDER BY group_id
        "#,
    )
    .fetch_all(connection).await?);
    }

    macro_rules! select {
        ($joins:literal, $filter:literal, $order:literal $(, $arg:expr)* $(,)?) => {
            if let Some(group) = input.group_id.as_deref() {
                sqlx::query_as!(StoredMessage, r#"
                    SELECT m.group_id AS "group_id!",
                    m.message_id AS "message_id!",
                    m.activity_message_id AS "activity_message_id?: String",
                    m.original_sender_id AS "original_sender_id?: i64",
                    m.sender_id AS "sender_id?: i64",
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
                    m.opened_at AS "opened_at?: i64",
                    m.opened_by_all AS "opened_by_all?: i64",
                    m.created_at AS "created_at!",
                    m.modified_at AS "modified_at?",
                    m.ack_by_user AS "ack_by_user?: i64",
                    m.ack_by_server AS "ack_by_server?: i64" FROM chat_messages m
                "# + $joins + " WHERE m.group_id = ? " + $filter + $order, group, $($arg),*).fetch_all(&mut *connection).await?
            } else {
                sqlx::query_as!(StoredMessage, r#"
                    SELECT m.group_id AS "group_id!",
                    m.message_id AS "message_id!",
                    m.activity_message_id AS "activity_message_id?: String",
                    m.original_sender_id AS "original_sender_id?: i64",
                    m.sender_id AS "sender_id?: i64",
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
                    m.opened_at AS "opened_at?: i64",
                    m.opened_by_all AS "opened_by_all?: i64",
                    m.created_at AS "created_at!",
                    m.modified_at AS "modified_at?",
                    m.ack_by_user AS "ack_by_user?: i64",
                    m.ack_by_server AS "ack_by_server?: i64" FROM chat_messages m
                "# + $joins + " WHERE 1 " + $filter + $order, $($arg),*).fetch_all(&mut *connection).await?
            }
        };
    }

    let mut rows = match input.filter {
        MessageFilter::Ids => select!(
            r#"

        "#,
            r#"
                AND m.message_id IN (SELECT value FROM json_each(?))
            "#,
            r#"
                ORDER BY m.rowid
            "#,
            serde_json::to_string(&input.ids)?
        ),
        MessageFilter::MediaIds => select!(
            r#"

        "#,
            r#"
                AND m.media_id IN (SELECT value FROM json_each(?))
            "#,
            r#"
                ORDER BY m.rowid
            "#,
            serde_json::to_string(&input.ids)?
        ),
        MessageFilter::Unopened => select!(
            r#"
                LEFT JOIN media_files f ON f.media_id = m.media_id JOIN groups g ON g.group_id = m.group_id
            "#,
            r#"
                AND m.opened_at IS NULL AND m.is_widget_media = 0 AND (m.is_story = 0 OR m.media_stored = 1)
                AND m.is_deleted_from_sender = 0 AND (m.media_id IS NULL OR f.download_state IS NULL
                OR f.download_state != 'reuploadRequested') AND (m.type != 'media' OR f.media_id IS NOT NULL
                OR m.is_deleted_from_sender = 1)
            "#,
            r#"
                ORDER BY m.created_at DESC, m.message_id DESC
            "#
        ),
        MessageFilter::MediaUnopened => select!(
            r#"
                LEFT JOIN media_files f ON f.media_id = m.media_id JOIN groups g ON g.group_id = m.group_id
            "#,
            r#"
                AND m.opened_at IS NULL AND m.is_widget_media = 0 AND (m.is_story = 0 OR m.media_stored = 1)
                AND m.is_deleted_from_sender = 0 AND (m.media_id IS NULL OR f.download_state IS NULL
                OR f.download_state != 'reuploadRequested') AND f.type != 'audio' AND m.media_id IS NOT NULL
                AND m.sender_id IS NOT NULL AND m.type = 'media'
            "#,
            r#"
                ORDER BY m.created_at, m.message_id
            "#
        ),
        MessageFilter::Last => {
            if let Some(before) = input.before {
                select!(
                    r#"
                        LEFT JOIN media_files f ON f.media_id = m.media_id JOIN groups g ON g.group_id = m.group_id
                    "#,
                    r#"
                        AND (m.is_story = 0 OR m.media_stored = 1) AND (m.opened_at IS NULL OR m.media_stored = 1
                        OR m.type = 'webxdcApp'
                        OR m.opened_at > CAST((? - g.delete_messages_after_milliseconds) / 1000 AS INTEGER))
                        AND (m.type != 'media' OR f.media_id IS NOT NULL OR m.is_deleted_from_sender = 1)
                        AND (f.download_state IS NULL OR f.download_state != 'reuploadRequested') AND (m.created_at < ?
                        OR (m.created_at = ? AND m.message_id < ?))
                    "#,
                    r#"
                        ORDER BY m.created_at DESC, m.message_id DESC LIMIT ?
                    "#,
                    input.now_ms,
                    before,
                    before,
                    input.before_message_id.as_deref(),
                    1_i64
                )
            } else {
                select!(
                    r#"
                        LEFT JOIN media_files f ON f.media_id = m.media_id JOIN groups g ON g.group_id = m.group_id
                    "#,
                    r#"
                        AND (m.is_story = 0 OR m.media_stored = 1) AND (m.opened_at IS NULL OR m.media_stored = 1
                        OR m.type = 'webxdcApp'
                        OR m.opened_at > CAST((? - g.delete_messages_after_milliseconds) / 1000 AS INTEGER))
                        AND (m.type != 'media' OR f.media_id IS NOT NULL OR m.is_deleted_from_sender = 1)
                        AND (f.download_state IS NULL OR f.download_state != 'reuploadRequested')
                    "#,
                    r#"
                        ORDER BY m.created_at DESC, m.message_id DESC LIMIT ?
                    "#,
                    input.now_ms,
                    1_i64
                )
            }
        }
        MessageFilter::Page => {
            if let Some(before) = input.before {
                select!(
                    r#"
                        LEFT JOIN media_files f ON f.media_id = m.media_id JOIN groups g ON g.group_id = m.group_id
                    "#,
                    r#"
                        AND (m.is_story = 0 OR m.media_stored = 1) AND (m.opened_at IS NULL OR m.media_stored = 1
                        OR m.type = 'webxdcApp'
                        OR m.opened_at > CAST((? - g.delete_messages_after_milliseconds) / 1000 AS INTEGER))
                        AND (m.is_deleted_from_sender = 1 OR m.type NOT IN ('text','media') OR (m.type = 'text'
                        AND m.content IS NOT NULL) OR (m.type = 'media' AND m.media_id IS NOT NULL
                        AND (f.download_state IS NULL OR f.download_state != 'reuploadRequested'))) AND (m.created_at < ?
                        OR (m.created_at = ? AND m.message_id < ?))
                    "#,
                    r#"
                        ORDER BY m.created_at DESC, m.message_id DESC LIMIT ?
                    "#,
                    input.now_ms,
                    before,
                    before,
                    input.before_message_id.as_deref(),
                    input.limit
                )
            } else {
                select!(
                    r#"
                        LEFT JOIN media_files f ON f.media_id = m.media_id JOIN groups g ON g.group_id = m.group_id
                    "#,
                    r#"
                        AND (m.is_story = 0 OR m.media_stored = 1) AND (m.opened_at IS NULL OR m.media_stored = 1
                        OR m.type = 'webxdcApp'
                        OR m.opened_at > CAST((? - g.delete_messages_after_milliseconds) / 1000 AS INTEGER))
                        AND (m.is_deleted_from_sender = 1 OR m.type NOT IN ('text','media') OR (m.type = 'text'
                        AND m.content IS NOT NULL) OR (m.type = 'media' AND m.media_id IS NOT NULL
                        AND (f.download_state IS NULL OR f.download_state != 'reuploadRequested')))
                    "#,
                    r#"
                        ORDER BY m.created_at DESC, m.message_id DESC LIMIT ?
                    "#,
                    input.now_ms,
                    input.limit
                )
            }
        }
        MessageFilter::LatestByGroup => unreachable!(),
    };

    if matches!(input.filter, MessageFilter::Page) {
        rows.reverse();
    }

    Ok(rows)
}

pub async fn unopened_media(connection: &mut SqliteConnection) -> Result<Vec<MediaFile>> {
    Ok(sqlx::query_as!(
        MediaFile,
        r#"
            SELECT f.media_id AS "media_id!",
                f.type AS "type!",
                f.upload_state AS "upload_state?",
                f.cloud_state AS "cloud_state!",
                f.blurhash AS "blurhash?",
                f.download_state AS "download_state?",
                f.requires_authentication AS "requires_authentication!: bool",
                f.stored AS "stored!: bool",
                f.is_draft_media AS "is_draft_media!: bool",
                f.is_widget_media AS "is_widget_media!: bool",
                f.is_favorite AS "is_favorite!: bool",
                f.has_crop_analyzed AS "has_crop_analyzed!: bool",
                f.pre_progressing_process AS "pre_progressing_process?",
                f.reupload_requested_by AS "reupload_requested_by?",
                f.display_limit_in_milliseconds AS "display_limit_in_milliseconds?",
                f.remove_audio AS "remove_audio?: bool",
                f.trim_start_ms AS "trim_start_ms?",
                f.trim_end_ms AS "trim_end_ms?",
                f.download_token AS "download_token?",
                f.encryption_key AS "encryption_key?",
                f.encryption_mac AS "encryption_mac?",
                f.encryption_nonce AS "encryption_nonce?",
                f.stored_file_hash AS "stored_file_hash?",
                f.has_thumbnail AS "has_thumbnail!: bool",
                f.size_in_bytes AS "size_in_bytes?",
                f.location_latitude AS "location_latitude?",
                f.location_longitude AS "location_longitude?",
                f.location_accuracy AS "location_accuracy?",
                f.location_status AS "location_status?",
                f.location_deadline_at AS "location_deadline_at?",
                f.gallery_export_pending AS "gallery_export_pending!: bool",
                f.created_at AS "created_at!",
                f.created_at_month AS "created_at_month?"
            FROM messages m
            JOIN media_files f
            ON f.media_id = m.media_id
            WHERE m.opened_at IS NULL
                AND m.is_widget_media = 0
                AND (m.is_story = 0
                    OR m.media_stored = 1
            )
                AND m.type = 'media'
                AND f.download_state = 'ready'
                AND f.type IN ('image','gif')
            ORDER BY m.rowid
        "#,
    )
    .fetch_all(connection)
    .await?)
}

pub async fn actions(
    connection: &mut SqliteConnection, message: &str,
) -> Result<MessageActionsWithContacts> {
    let actions: Vec<MessageAction> = sqlx::query_as!(
        MessageAction,
        r#"
            SELECT m.message_id AS "message_id!",
                a.contact_id AS "contact_id!",
                a.type AS "type!",
                a.action_at AS "action_at!"
            FROM chat_messages m JOIN message_actions a ON a.message_id = COALESCE(m.activity_message_id, m.message_id)
            WHERE m.message_id = ?
            ORDER BY a.rowid
        "#,
        message,
    )
    .fetch_all(&mut *connection)
    .await?;

    let ids = actions.iter().map(|a| a.contact_id).collect();

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

    Ok(MessageActionsWithContacts { actions, contacts })
}

pub async fn delivery_actions(
    connection: &mut SqliteConnection, messages: &[String],
) -> Result<Vec<MessageAction>> {
    Ok(sqlx::query_as!(
        MessageAction,
        r#"
            SELECT m.message_id AS "message_id!",
                a.contact_id AS "contact_id!",
                a.type AS "type!",
                a.action_at AS "action_at!"
            FROM message_actions a
            JOIN chat_messages m
            ON COALESCE(m.activity_message_id, m.message_id) = a.message_id
            JOIN groups g
            ON g.group_id = m.group_id
            WHERE m.message_id IN (
                SELECT value
                FROM json_each(?)
            )
                AND (a.type = 'ackByUserAt'
                    OR (a.type = 'sendFailed'
                        AND g.is_direct_chat = 1
                )
            )
            ORDER BY a.rowid
        "#,
        serde_json::to_string(messages)?,
    )
    .fetch_all(connection)
    .await?)
}

/// Freeze each visible message's receipt identity before an asynchronous send.
pub(crate) async fn opened_targets(
    connection: &mut SqliteConnection, messages: &[String], contact_id: i64,
) -> Result<Vec<String>> {
    let ids = serde_json::to_string(messages)?;
    Ok(sqlx::query_scalar(
        "SELECT DISTINCT COALESCE(m.activity_message_id, m.message_id)
         FROM json_each(?) requested
         LEFT JOIN webxdc_updates u ON substr(requested.value, -5) = '-info'
             AND u.message_id = substr(requested.value, 1, length(requested.value) - 5)
             AND u.info IS NOT NULL
         JOIN chat_messages m ON m.message_id = COALESCE(u.instance_id, requested.value)
         WHERE m.sender_id = ? AND (requested.value = m.message_id
             OR requested.value = m.activity_message_id)",
    )
    .bind(&ids)
    .bind(contact_id)
    .fetch_all(connection)
    .await?)
}

pub async fn history(
    connection: &mut SqliteConnection, message: &str,
) -> Result<Vec<MessageHistory>> {
    Ok(sqlx::query_as!(
        MessageHistory,
        r#"
            SELECT id AS "id!",
                message_id AS "message_id!",
                contact_id AS "contact_id?",
                content AS "content?",
                created_at AS "created_at!"
            FROM message_histories
            WHERE message_id = ?
            ORDER BY created_at DESC,
                id DESC
        "#,
        message,
    )
    .fetch_all(connection)
    .await?)
}
