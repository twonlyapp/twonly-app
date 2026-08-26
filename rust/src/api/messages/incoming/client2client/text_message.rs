/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::encrypted_content;
use crate::database::app::tables::{Group, Message, MessageType, NewMessage};
use crate::error::Result;
use crate::utils::milliseconds_to_seconds;
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
