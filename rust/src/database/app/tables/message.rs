/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use sqlx::{Sqlite, Transaction};

use crate::error::{Result, TwonlyError};

pub struct Message;

pub struct DeletedMessageMedia {
    pub media_id: String,
    pub media_type: String,
}

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
    pub async fn record_opened(
        t: &mut Transaction<'_, Sqlite>,
        message_id: &str,
        contact_id: i64,
        timestamp: i64,
    ) -> Result<()> {
        let action_at = sqlx::query_scalar!(
            r#"SELECT MAX(created_at, ?) AS "action_at!: i64" FROM messages WHERE message_id = ?"#,
            timestamp,
            message_id,
        )
        .fetch_optional(&mut **t)
        .await?;
        let Some(action_at) = action_at else {
            return Ok(());
        };

        sqlx::query!(
            r#"INSERT INTO message_actions(message_id, contact_id, type, action_at)
               VALUES (?, ?, 'openedAt', ?)
               ON CONFLICT(message_id, contact_id, type)
               DO UPDATE SET action_at = excluded.action_at"#,
            message_id,
            contact_id,
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
        Ok(())
    }

    pub async fn delete_from_sender(
        t: &mut Transaction<'_, Sqlite>,
        message_id: Option<&str>,
        sender_id: i64,
        timestamp: i64,
    ) -> Result<Option<DeletedMessageMedia>> {
        let media_id = sqlx::query_scalar!(
            "SELECT media_id FROM messages WHERE message_id = ? AND sender_id = ?",
            message_id,
            sender_id,
        )
        .fetch_optional(&mut **t)
        .await?
        .flatten();

        sqlx::query!(
            "DELETE FROM message_histories WHERE message_id = ?",
            message_id
        )
        .execute(&mut **t)
        .await?;
        sqlx::query!("DELETE FROM receipts WHERE message_id = ?", message_id)
            .execute(&mut **t)
            .await?;
        sqlx::query!(
            r#"UPDATE messages
               SET is_deleted_from_sender = 1, content = NULL, media_id = NULL, modified_at = ?
               WHERE message_id = ? AND sender_id = ?"#,
            timestamp,
            message_id,
            sender_id,
        )
        .execute(&mut **t)
        .await?;

        let Some(media_id) = media_id else {
            return Ok(None);
        };
        let references =
            sqlx::query_scalar!("SELECT COUNT(*) FROM messages WHERE media_id = ?", media_id,)
                .fetch_one(&mut **t)
                .await?;
        if references != 0 {
            return Ok(None);
        }
        let media_type =
            sqlx::query_scalar!("SELECT type FROM media_files WHERE media_id = ?", media_id,)
                .fetch_optional(&mut **t)
                .await?;
        sqlx::query!("DELETE FROM media_files WHERE media_id = ?", media_id)
            .execute(&mut **t)
            .await?;
        Ok(media_type.map(|media_type| DeletedMessageMedia {
            media_id,
            media_type,
        }))
    }

    pub async fn edit_text(
        t: &mut Transaction<'_, Sqlite>,
        message_id: Option<&str>,
        sender_id: i64,
        text: Option<&str>,
        timestamp: i64,
    ) -> Result<()> {
        sqlx::query!(
            r#"INSERT INTO message_histories(message_id, content, created_at)
               SELECT message_id, content, ? FROM messages
               WHERE message_id = ? AND sender_id = ? AND content IS NOT NULL"#,
            timestamp,
            message_id,
            sender_id,
        )
        .execute(&mut **t)
        .await?;
        sqlx::query!(
            r#"UPDATE messages SET content = ?, modified_at = ?
               WHERE message_id = ? AND sender_id = ? AND content IS NOT NULL"#,
            text,
            timestamp,
            message_id,
            sender_id,
        )
        .execute(&mut **t)
        .await?;
        Ok(())
    }

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
