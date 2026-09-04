/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::encrypted_content;
use crate::context::Context;
use crate::database::app::tables::{Group, Message, MessageType, NewMessage};
use crate::error::Result;
use crate::services::mediafiles::MediaFileService;
use crate::utils::{current_time, milliseconds_to_seconds};
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
        .maybe_additional_message_data(message.additional_message_data.as_deref())
        .ack_by_server(current_time().timestamp())
        .build()
        .insert(t)
        .await?;

    Group::increase_last_message_exchange(t, group_id, timestamp).await?;

    Ok(())
}

pub(crate) async fn handle_message_update(
    ctx: &std::sync::Arc<Context>,
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
                Message::record_opened(t, &message_id, from_user_id, timestamp).await?;
            }
        }
        Type::Delete => {
            let deleted_media = Message::delete_from_sender(
                t,
                update.sender_message_id.as_deref(),
                from_user_id,
                timestamp,
            )
            .await?;

            if let Some(media) = deleted_media {
                MediaFileService::new(ctx)
                    .remove_files_if_deleted(t, &media.media_id, &media.media_type)
                    .await?;
            }
        }
        Type::EditText => {
            Message::edit_text(
                t,
                update.sender_message_id.as_deref(),
                from_user_id,
                update.text.as_deref(),
                timestamp,
            )
            .await?;
        }
    }
    Ok(())
}
