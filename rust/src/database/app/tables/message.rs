/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use sqlx::{Sqlite, Transaction};

use crate::error::{Result, TwonlyError};

pub struct Message;

pub enum MessageType<'a> {
    Text,
    Media,
    Reaction,
    Other(&'a str),
}

#[derive(bon::Builder)]
pub struct NewMessage<'a> {
    group_id: &'a str,
    message_id: &'a str,
    sender_id: Option<i64>,
    message_type: MessageType<'a>,
    content: Option<&'a str>,
    media_id: Option<&'a str>,
    additional_message_data: Option<&'a [u8]>,
    quotes_message_id: Option<&'a str>,
    created_at: i64,
    ack_by_server: Option<i64>,
}

impl<'a> NewMessage<'a> {
    pub async fn insert(self, tr: &mut Transaction<'_, Sqlite>) -> Result<()> {
        Message::insert(tr, self).await
    }
}

impl Message {
    pub async fn insert(tr: &mut Transaction<'_, Sqlite>, message: NewMessage<'_>) -> Result<()> {
        sqlx::query!(
            r#"
            INSERT INTO messages(
                group_id,
                message_id,
                sender_id,
                type,
                content,
                media_id,
                additional_message_data,
                quotes_message_id,
                created_at,
                ack_by_server
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(message_id) DO NOTHING
            "#,
            message.group_id,
            message.message_id,
            message.sender_id,
            message.message_type.as_str(),
            message.content,
            message.media_id,
            message.additional_message_data,
            message.quotes_message_id,
            message.created_at,
            message.ack_by_server,
        )
        .execute(&mut **tr)
        .await?;

        Ok(())
    }

    pub async fn check_message_owner(
        t: &mut Transaction<'_, Sqlite>,
        message_id: &str,
        from_user_id: i64,
    ) -> Result<()> {
        let owner = sqlx::query_scalar!(
            r#"
            SELECT sender_id
            FROM messages
            WHERE message_id = ?
            "#,
            message_id,
        )
        .fetch_optional(&mut **t)
        .await?
        .flatten();

        if owner.is_some_and(|owner| owner != from_user_id) {
            return Err(TwonlyError::Generic(
                "attempted cross-sender message overwrite".into(),
            ));
        }

        Ok(())
    }
}

impl<'a> MessageType<'a> {
    pub fn as_str(&self) -> &'a str {
        match self {
            Self::Text => "text",
            Self::Media => "media",
            Self::Reaction => "reaction",
            Self::Other(s) => s,
        }
    }
}
