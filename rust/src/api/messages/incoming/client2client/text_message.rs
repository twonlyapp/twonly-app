/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::encrypted_content;
use crate::database::app::tables::{Group, Message, MessageType, NewMessage};
use crate::error::Result;
use crate::utils::milliseconds_to_seconds;
use encrypted_content::message_update::Type;
use sqlx::{Sqlite, Transaction};

pub(crate) async fn handle_text_message(
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    group_id: &str,
    message: encrypted_content::TextMessage,
) -> Result<()> {
    Message::check_message_owner(t, &message.sender_message_id, from_user_id).await?;

    let timestamp = milliseconds_to_seconds(message.timestamp);

    NewMessage::builder()
        .group_id(group_id)
        .message_id(&message.sender_message_id)
        .message_type(MessageType::Text)
        .created_at(timestamp)
        .sender_id(from_user_id)
        .content(&message.text)
        .maybe_quotes_message_id(message.quote_message_id.as_deref())
        .ack_by_server(chrono::Utc::now().timestamp())
        .build()
        .insert(t)
        .await?;

    Group::increase_last_message_exchange(t, group_id, timestamp).await?;

    Ok(())
}

pub(crate) async fn handle_message_update(
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    update: encrypted_content::MessageUpdate,
) -> Result<()> {
    let timestamp = milliseconds_to_seconds(update.timestamp);

    let update_type = Type::try_from(update.r#type)?;
    tracing::info!(?update_type, from_user_id, "update text message");

    match update_type {
        Type::Opened => {
            for message_id in update.multiple_target_message_ids {
                let action_at = sqlx::query_scalar::<_, i64>(
                    "SELECT MAX(created_at, ?) FROM messages WHERE message_id = ?",
                )
                .bind(timestamp)
                .bind(&message_id)
                .fetch_optional(&mut **t)
                .await?;

                let Some(action_at) = action_at else { continue };

                sqlx::query!(
                    r#"
                    INSERT INTO message_actions(message_id, contact_id, type, action_at)
                    VALUES (?, ?, 'openedAt', ?)
                    ON CONFLICT(message_id, contact_id, type)
                    DO UPDATE SET action_at = excluded.action_at
                    "#,
                    message_id,
                    from_user_id,
                    action_at,
                )
                .execute(&mut **t)
                .await?;

                sqlx::query!(
                    r#"UPDATE messages SET opened_at = ?, opened_by_all = CASE WHEN NOT EXISTS(
                           SELECT 1 FROM group_members gm
                           WHERE gm.group_id = messages.group_id AND NOT EXISTS(
                               SELECT 1 FROM message_actions ma
                               WHERE ma.message_id = messages.message_id
                                 AND ma.contact_id = gm.contact_id AND ma.type = 'openedAt'
                           )
                       ) THEN ? ELSE NULL END
                       WHERE message_id = ?"#,
                    action_at,
                    action_at,
                    message_id,
                )
                .execute(&mut **t)
                .await?;
            }
        }
        Type::Delete => {
            let media_id = sqlx::query_scalar!(
                "SELECT media_id FROM messages WHERE message_id = ? AND sender_id = ?",
                update.sender_message_id,
                from_user_id,
            )
            .fetch_optional(&mut **t)
            .await?
            .flatten();

            sqlx::query!(
                "DELETE FROM message_histories WHERE message_id = ?",
                update.sender_message_id
            )
            .execute(&mut **t)
            .await?;

            sqlx::query!(
                "DELETE FROM receipts WHERE message_id = ?",
                update.sender_message_id
            )
            .execute(&mut **t)
            .await?;

            sqlx::query!(
                r#"
                UPDATE messages
                SET is_deleted_from_sender = 1, content = NULL, media_id = NULL, modified_at = ?
                WHERE message_id = ? AND sender_id = ?
                "#,
                timestamp,
                update.sender_message_id,
                from_user_id,
            )
            .execute(&mut **t)
            .await?;

            if let Some(media_id) = media_id {
                let references = sqlx::query_scalar!(
                    "SELECT COUNT(*) FROM messages WHERE media_id = ?",
                    media_id,
                )
                .fetch_one(&mut **t)
                .await?;

                if references == 0 {
                    let media_type = sqlx::query_scalar!(
                        "SELECT type FROM media_files WHERE media_id = ?",
                        media_id,
                    )
                    .fetch_optional(&mut **t)
                    .await?;
                    sqlx::query!("DELETE FROM media_files WHERE media_id = ?", media_id)
                        .execute(&mut **t)
                        .await?;
                    if let Some(media_type) = media_type {
                        let ctx = crate::context::Context::get_static()?;
                        let ctx = ctx.clone();
                        tokio::spawn(async move {
                            // Let the surrounding message transaction commit before
                            // applying its corresponding filesystem side effect.
                            tokio::time::sleep(std::time::Duration::from_millis(50)).await;
                            if let Err(error) =
                                crate::services::mediafiles::MediaFileService::new(&ctx)
                                    .remove_files_if_deleted(&media_id, &media_type)
                                    .await
                            {
                                tracing::warn!(media_id, %error, "could not remove media files");
                            }
                        });
                    }
                }
            }
        }
        Type::EditText => {
            sqlx::query!(
                r#"INSERT INTO message_histories(message_id, content, created_at)
                   SELECT message_id, content, ? FROM messages
                   WHERE message_id = ? AND sender_id = ? AND content IS NOT NULL"#,
                timestamp,
                update.sender_message_id,
                from_user_id,
            )
            .execute(&mut **t)
            .await?;

            sqlx::query!(
                r#"
                UPDATE messages
                SET content = ?, modified_at = ?
                WHERE message_id = ? AND sender_id = ? AND content IS NOT NULL
                "#,
                update.text,
                timestamp,
                update.sender_message_id,
                from_user_id,
            )
            .execute(&mut **t)
            .await?;
        }
    }
    Ok(())
}
