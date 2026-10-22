use super::table::{MessagePatch, StoredMessage};
use crate::error::{Result, TwonlyError};
use sqlx::{Sqlite, Transaction};

pub async fn upsert(
    tx: &mut Transaction<'_, Sqlite>, patch: MessagePatch,
) -> Result<StoredMessage> {
    if patch.message_id.is_none() {
        return Err(TwonlyError::Generic(
            "messages.message_id is required".into(),
        ));
    }

    if patch.group_id.is_none() {
        return Err(TwonlyError::Generic("messages.group_id is required".into()));
    }

    if patch.r#type.is_none() {
        return Err(TwonlyError::Generic("messages.type is required".into()));
    }

    let id = patch.message_id.clone().expect("primary key checked");

    macro_rules! upsert {
        ($deleted:literal) => {
            sqlx::query!(
                r#"
                    INSERT INTO messages (
                        group_id,
                        message_id,
                        sender_id,
                        type,
                        content,
                        media_id,
                        additional_message_data,
                        media_stored,
                        media_reopened,
                        download_token,
                        quotes_message_id,
                        is_deleted_from_sender,
                        is_widget_media,
                        is_story,
                        opened_at,
                        opened_by_all,
                        created_at,
                        modified_at,
                        ack_by_user,
                        ack_by_server
                    ) VALUES (
                        ?,
                        ?,
                        ?,
                        ?,
                        ?,
                        ?,
                        ?,
                        COALESCE(?, 0),
                        COALESCE(?, 0),
                        ?,
                        ?,
                        COALESCE(?, 0),
                        COALESCE(?, 0),
                        COALESCE(?, 0),
                        ?,
                        ?,
                        COALESCE(?, CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
                        ?,
                        ?,
                        ?
                    )
                    ON CONFLICT(message_id) DO UPDATE SET
                        group_id = CASE WHEN ? THEN excluded.group_id ELSE messages.group_id END,
                        sender_id = CASE WHEN ? THEN excluded.sender_id ELSE messages.sender_id END,
                        type = CASE WHEN ? THEN excluded.type ELSE messages.type END,
                        content = CASE WHEN ? THEN excluded.content ELSE messages.content END,
                        media_id = CASE WHEN ? THEN excluded.media_id ELSE messages.media_id END,
                        additional_message_data = CASE WHEN ? THEN excluded.additional_message_data
                            ELSE messages.additional_message_data END,
                        media_stored = CASE WHEN ? THEN excluded.media_stored ELSE messages.media_stored END,
                        media_reopened = CASE WHEN ? THEN excluded.media_reopened ELSE messages.media_reopened END,
                        download_token = CASE WHEN ? THEN excluded.download_token ELSE messages.download_token END,
                        quotes_message_id = CASE WHEN ? THEN excluded.quotes_message_id ELSE messages.quotes_message_id END,
                        is_widget_media = CASE WHEN ? THEN excluded.is_widget_media ELSE messages.is_widget_media END,
                        is_story = CASE WHEN ? THEN excluded.is_story ELSE messages.is_story END,
                        opened_at = CASE WHEN ? THEN excluded.opened_at ELSE messages.opened_at END,
                        opened_by_all = CASE WHEN ? THEN excluded.opened_by_all ELSE messages.opened_by_all END,
                        created_at = CASE WHEN ? THEN excluded.created_at ELSE messages.created_at END,
                        modified_at = CASE WHEN ? THEN excluded.modified_at ELSE messages.modified_at END,
                        ack_by_user = CASE WHEN ? THEN excluded.ack_by_user ELSE messages.ack_by_user END,
                        ack_by_server = CASE WHEN ? THEN excluded.ack_by_server ELSE messages.ack_by_server END
                "# + $deleted,

        patch.group_id.as_deref(),
        patch.message_id.as_deref(),
        patch.sender_id.as_ref().and_then(|value| value.value),
        patch.r#type.as_deref(),
        patch.content.as_ref().and_then(|value| value.value.as_deref()),
        patch.media_id.as_ref().and_then(|value| value.value.as_deref()),
        patch.additional_message_data.as_ref().and_then(|value| value.value.as_deref()),
        patch.media_stored,
        patch.media_reopened,
        patch.download_token.as_ref().and_then(|value| value.value.as_deref()),
        patch.quotes_message_id.as_ref().and_then(|value| value.value.as_deref()),
        patch.is_deleted_from_sender,
        patch.is_widget_media,
        patch.is_story,
        patch.opened_at.as_ref().and_then(|value| value.value),
        patch.opened_by_all.as_ref().and_then(|value| value.value),
        patch.created_at,
        patch.modified_at.as_ref().and_then(|value| value.value),
        patch.ack_by_user.as_ref().and_then(|value| value.value),
        patch.ack_by_server.as_ref().and_then(|value| value.value),
        patch.group_id.is_some(),
        patch.sender_id.is_some(),
        patch.r#type.is_some(),
        patch.content.is_some(),
        patch.media_id.is_some(),
        patch.additional_message_data.is_some(),
        patch.media_stored.is_some(),
        patch.media_reopened.is_some(),
        patch.download_token.is_some(),
        patch.quotes_message_id.is_some(),
        patch.is_widget_media.is_some(),
        patch.is_story.is_some(),
        patch.opened_at.is_some(),
        patch.opened_by_all.is_some(),
        patch.created_at.is_some(),
        patch.modified_at.is_some(),
        patch.ack_by_user.is_some(),
        patch.ack_by_server.is_some(),
            ).execute(&mut **tx).await?
        };
    }

    if patch.is_deleted_from_sender.is_some() {
        upsert!(", is_deleted_from_sender = excluded.is_deleted_from_sender");
    } else {
        upsert!("");
    }

    Ok(super::queries::get(&mut **tx, &id)
        .await?
        .expect("row exists"))
}

pub async fn update(tx: &mut Transaction<'_, Sqlite>, id: &str, patch: MessagePatch) -> Result<()> {
    update_matching(tx, false, id, patch).await
}

async fn update_matching(
    tx: &mut Transaction<'_, Sqlite>, by_media: bool, id: &str, patch: MessagePatch,
) -> Result<()> {
    if !(patch.group_id.is_some()
        || patch.message_id.is_some()
        || patch.sender_id.is_some()
        || patch.r#type.is_some()
        || patch.content.is_some()
        || patch.media_id.is_some()
        || patch.additional_message_data.is_some()
        || patch.media_stored.is_some()
        || patch.media_reopened.is_some()
        || patch.download_token.is_some()
        || patch.quotes_message_id.is_some()
        || patch.is_deleted_from_sender.is_some()
        || patch.is_widget_media.is_some()
        || patch.is_story.is_some()
        || patch.opened_at.is_some()
        || patch.opened_by_all.is_some()
        || patch.created_at.is_some()
        || patch.modified_at.is_some()
        || patch.ack_by_user.is_some()
        || patch.ack_by_server.is_some())
    {
        return Ok(());
    }

    // Omitting this assignment also avoids firing UPDATE OF deletion triggers.
    macro_rules! update {
        ($predicate:literal, $deleted:literal $(, $deleted_arg:expr)* $(,)?) => {
            sqlx::query!(
                r#"
                    UPDATE messages SET group_id = CASE WHEN ? THEN ? ELSE group_id END,
                    message_id = CASE WHEN ? THEN ? ELSE message_id END,
                    sender_id = CASE WHEN ? THEN ? ELSE sender_id END,
                    type = CASE WHEN ? THEN ? ELSE type END,
                    content = CASE WHEN ? THEN ? ELSE content END,
                    media_id = CASE WHEN ? THEN ? ELSE media_id END,
                    additional_message_data = CASE WHEN ? THEN ? ELSE additional_message_data END,
                    media_stored = CASE WHEN ? THEN ? ELSE media_stored END,
                    media_reopened = CASE WHEN ? THEN ? ELSE media_reopened END,
                    download_token = CASE WHEN ? THEN ? ELSE download_token END,
                    quotes_message_id = CASE WHEN ? THEN ? ELSE quotes_message_id END,
                    is_widget_media = CASE WHEN ? THEN ? ELSE is_widget_media END,
                    is_story = CASE WHEN ? THEN ? ELSE is_story END,
                    opened_at = CASE WHEN ? THEN ? ELSE opened_at END,
                    opened_by_all = CASE WHEN ? THEN ? ELSE opened_by_all END,
                    created_at = CASE WHEN ? THEN ? ELSE created_at END,
                    modified_at = CASE WHEN ? THEN ? ELSE modified_at END,
                    ack_by_user = CASE WHEN ? THEN ? ELSE ack_by_user END,
                    ack_by_server = CASE WHEN ? THEN ? ELSE ack_by_server END
                "# + $deleted + $predicate,
                patch.group_id.is_some(),
                patch.group_id.as_deref(),
                patch.message_id.is_some(),
                patch.message_id.as_deref(),
                patch.sender_id.is_some(),
                patch.sender_id.as_ref().and_then(|value| value.value),
                patch.r#type.is_some(),
                patch.r#type.as_deref(),
                patch.content.is_some(),
                patch.content.as_ref().and_then(|value| value.value.as_deref()),
                patch.media_id.is_some(),
                patch.media_id.as_ref().and_then(|value| value.value.as_deref()),
                patch.additional_message_data.is_some(),
                patch.additional_message_data.as_ref().and_then(|value| value.value.as_deref()),
                patch.media_stored.is_some(),
                patch.media_stored,
                patch.media_reopened.is_some(),
                patch.media_reopened,
                patch.download_token.is_some(),
                patch.download_token.as_ref().and_then(|value| value.value.as_deref()),
                patch.quotes_message_id.is_some(),
                patch.quotes_message_id.as_ref().and_then(|value| value.value.as_deref()),
                patch.is_widget_media.is_some(),
                patch.is_widget_media,
                patch.is_story.is_some(),
                patch.is_story,
                patch.opened_at.is_some(),
                patch.opened_at.as_ref().and_then(|value| value.value),
                patch.opened_by_all.is_some(),
                patch.opened_by_all.as_ref().and_then(|value| value.value),
                patch.created_at.is_some(),
                patch.created_at,
                patch.modified_at.is_some(),
                patch.modified_at.as_ref().and_then(|value| value.value),
                patch.ack_by_user.is_some(),
                patch.ack_by_user.as_ref().and_then(|value| value.value),
                patch.ack_by_server.is_some(),
                patch.ack_by_server.as_ref().and_then(|value| value.value),
                $($deleted_arg,)* id
            ).execute(&mut **tx).await?
        };
    }

    match (by_media, patch.is_deleted_from_sender) {
        (false, None) => {
            update!(" WHERE message_id = ?", "");
        }
        (true, None) => {
            update!(" WHERE media_id = ?", "");
        }
        (false, Some(deleted)) => {
            update!(
                " WHERE message_id = ?",
                ", is_deleted_from_sender = ?",
                deleted
            );
        }
        (true, Some(deleted)) => {
            update!(
                " WHERE media_id = ?",
                ", is_deleted_from_sender = ?",
                deleted
            );
        }
    }

    Ok(())
}

pub async fn update_by_media(
    tx: &mut Transaction<'_, Sqlite>, id: &str, patch: MessagePatch,
) -> Result<()> {
    // Both indexed selectors expand to compile-checked SQL.
    update_matching(tx, true, id, patch).await
}

pub async fn delete(tx: &mut Transaction<'_, Sqlite>, id: &str) -> Result<()> {
    sqlx::query!(
        r#"
            DELETE FROM messages WHERE message_id = ?
        "#,
        id,
    )
    .execute(&mut **tx)
    .await?;

    Ok(())
}

pub async fn clear_chat(tx: &mut Transaction<'_, Sqlite>, group: &str) -> Result<()> {
    sqlx::query!(
        r#"
            DELETE
            FROM messages
            WHERE group_id = ?
                AND (is_story = 0
                    OR media_stored = 1
            )
                AND NOT EXISTS (
                SELECT 1
                FROM webxdc_instances instance
                LEFT JOIN webxdc_apps app
                ON app.app_id = instance.app_id
                    AND app.version = instance.version
                WHERE instance.instance_id = messages.message_id
                    AND (app.one_time = 1
                        OR app.app_id IS NULL
                )
            )
        "#,
        group,
    )
    .execute(&mut **tx)
    .await?;

    sqlx::query!(
        r#"
            UPDATE groups
            SET deleted_content = 1,
                archived = 0,
                pinned = 0,
                draft_message = NULL
            WHERE group_id = ?
        "#,
        group,
    )
    .execute(&mut **tx)
    .await?;

    Ok(())
}

pub async fn edit(
    tx: &mut Transaction<'_, Sqlite>, sender: Option<i64>, id: &str, text: &str, timestamp: i64,
) -> Result<()> {
    sqlx::query!(
        r#"
            INSERT INTO message_histories(message_id,content,created_at)
            SELECT message_id,
                content,
                ?
            FROM messages
            WHERE message_id = ?
                AND sender_id IS ?
                AND content IS NOT NULL
        "#,
        timestamp,
        id,
        sender,
    )
    .execute(&mut **tx)
    .await?;

    sqlx::query!(
        r#"
            UPDATE messages
            SET content = ?,
                modified_at = ?
            WHERE message_id = ?
                AND sender_id IS ?
                AND content IS NOT NULL
        "#,
        text,
        timestamp,
        id,
        sender,
    )
    .execute(&mut **tx)
    .await?;

    Ok(())
}

pub async fn purge(tx: &mut Transaction<'_, Sqlite>, now_ms: i64) -> Result<()> {
    sqlx::query!(
        r#"
            DELETE
            FROM group_histories
            WHERE action_at < (
                SELECT CAST((? - g.delete_messages_after_milliseconds) / 1000 AS INTEGER)
                FROM groups g
                WHERE g.group_id = group_histories.group_id
            )
        "#,
        now_ms,
    )
    .execute(&mut **tx)
    .await?;

    sqlx::query!(
        r#"
            DELETE
            FROM messages
            WHERE type != 'webxdcApp'
                AND (is_story = 0
                    OR media_stored = 1
            )
                AND (is_widget_media = 0
                    OR sender_id IS NULL
            )
                AND (media_stored = 0
                    OR is_deleted_from_sender = 1
            )
                AND EXISTS(
                SELECT 1
                FROM groups g
                WHERE g.group_id = messages.group_id
                    AND ((opened_by_all IS NOT NULL
                            AND opened_by_all < CAST((? - g.delete_messages_after_milliseconds) / 1000 AS INTEGER)
                    )
                        OR (is_deleted_from_sender = 1
                            AND messages.created_at < CAST((? - g.delete_messages_after_milliseconds) / 1000 AS
                                INTEGER)
                    )
                )
            )
        "#,
        now_ms,
        now_ms,
    )
    .execute(&mut **tx).await?;

    Ok(())
}

pub async fn delete_from_sender(
    tx: &mut Transaction<'_, Sqlite>, sender: Option<i64>, id: &str,
) -> Result<()> {
    let row = sqlx::query!(
        "SELECT media_id FROM messages WHERE message_id = ? AND sender_id IS ?",
        id,
        sender
    )
    .fetch_optional(&mut **tx)
    .await?;

    let Some(row) = row else {
        return Ok(());
    };

    let media = row.media_id;

    sqlx::query!(
        r#"
            DELETE FROM message_histories WHERE message_id = ?
        "#,
        id,
    )
    .execute(&mut **tx)
    .await?;

    sqlx::query!(
        r#"
            DELETE FROM receipts WHERE message_id = ?
        "#,
        id,
    )
    .execute(&mut **tx)
    .await?;

    sqlx::query!(
        r#"
            UPDATE messages
            SET is_deleted_from_sender = 1,
                content = NULL,
                media_id = NULL,
                additional_message_data = NULL
            WHERE message_id = ?
        "#,
        id,
    )
    .execute(&mut **tx)
    .await?;

    if let Some(media) = media.filter(|_| sender.is_some()) {
        let references: bool = sqlx::query_scalar!(
            r#"
                SELECT EXISTS(SELECT 1 FROM messages WHERE media_id = ?) AS "value!: bool"
            "#,
            &media,
        )
        .fetch_one(&mut **tx)
        .await?;

        if !references {
            sqlx::query!(
                r#"
                    INSERT INTO pending_media_file_removals(media_id,media_type)
                    SELECT media_id,
                        type
                    FROM media_files
                    WHERE media_id = ?
                    ON CONFLICT(media_id) DO UPDATE
                    SET media_type = excluded.media_type
                "#,
                &media,
            )
            .execute(&mut **tx)
            .await?;

            sqlx::query!(
                r#"
                    DELETE FROM media_files WHERE media_id = ?
                "#,
                media,
            )
            .execute(&mut **tx)
            .await?;
        }
    }

    Ok(())
}

pub async fn drain_file_removals(
    database: &crate::database::app::AppDatabase, remove: impl Fn(&str, &str) -> Result<()>,
) -> Result<()> {
    for _ in 0..100 {
        let mut tx = database.pool.begin().await?;

        // This write obtains SQLite's writer lock before checking whether a
        // media row has been recreated. Another process cannot insert one
        // between that check and file removal.
        let job = sqlx::query!(
            r#"
                DELETE
                FROM pending_media_file_removals
                WHERE media_id = (
                    SELECT media_id
                    FROM pending_media_file_removals
                    ORDER BY rowid
                    LIMIT 1
                ) RETURNING media_id,
                    media_type
            "#,
        )
        .fetch_optional(&mut *tx)
        .await?;

        let Some(job) = job else {
            tx.commit().await?;

            return Ok(());
        };

        let (id, kind) = (job.media_id, job.media_type);

        let exists: bool = sqlx::query_scalar!(
            r#"
                SELECT EXISTS(SELECT 1 FROM media_files WHERE media_id = ?) AS "value!: bool"
            "#,
            &id,
        )
        .fetch_one(&mut *tx)
        .await?;

        if !exists {
            if let Err(error) = remove(&id, &kind) {
                tx.rollback().await?;

                return Err(error);
            }
        }

        tx.commit().await?;
    }

    Ok(())
}
