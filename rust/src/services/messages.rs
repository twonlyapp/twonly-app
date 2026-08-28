/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::messages::incoming::messages::{
    self, queue_encrypted_content, send_queued_receipt,
};
use crate::api::messages::outgoing::{decorate_content, send_c2c_message_to_contact};
use crate::api::proto::client::{self as proto, encrypted_content};
use crate::context::Context;
use crate::database::app::tables::{Contact, Group};
use crate::error::{Result, TwonlyError};
use crate::user_config::UserConfig;
use prost::Message as _;
use std::sync::Arc;

pub struct MessageService {
    ctx: Arc<Context>,
}

impl MessageService {
    pub fn new(ctx: &Arc<Context>) -> Self {
        Self { ctx: ctx.clone() }
    }

    pub async fn send_to_group(
        &self,
        group_id: String,
        encrypted_content: Vec<u8>,
        message_id: Option<String>,
        only_send_if_no_receipts_are_open: bool,
    ) -> Result<()> {
        let mut content = proto::EncryptedContent::decode(encrypted_content.as_slice())?;
        content.group_id = Some(group_id.clone());
        let database = self.ctx.app_db.read().await.clone();
        if message_id.is_some()
            || content.reaction.is_some()
            || content.media.is_some()
            || content.text_message.is_some()
        {
            sqlx::query!("UPDATE groups SET last_message_exchange = CAST(strftime('%s','now') AS INTEGER) WHERE group_id = ?", group_id)
                .execute(&database.pool).await?;
            database.notify_committed(["groups"]);
        }
        let members = sqlx::query_scalar!(
            r#"SELECT contact_id FROM group_members
               WHERE group_id = ? AND (member_state IS NULL OR member_state != 'leftGroup')"#,
            group_id,
        )
        .fetch_all(&database.pool)
        .await?;
        let bytes = content.encode_to_vec();
        for contact_id in members {
            send_c2c_message_to_contact()
                .ctx(&self.ctx)
                .contact_id(contact_id)
                .encrypted_content(bytes.clone())
                .maybe_message_id(message_id.clone())
                .only_send_if_no_receipts_are_open(only_send_if_no_receipts_are_open)
                .call()
                .await?;
        }
        Ok(())
    }

    pub async fn send_to_group_in_transaction(
        &self,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
        group_id: String,
        encrypted_content: Vec<u8>,
        message_id: Option<String>,
        only_send_if_no_receipts_are_open: bool,
    ) -> Result<()> {
        let mut content = proto::EncryptedContent::decode(encrypted_content.as_slice())?;
        content.group_id = Some(group_id.clone());
        if message_id.is_some()
            || content.reaction.is_some()
            || content.media.is_some()
            || content.text_message.is_some()
        {
            sqlx::query!("UPDATE groups SET last_message_exchange = CAST(strftime('%s','now') AS INTEGER) WHERE group_id = ?", group_id)
                .execute(&mut **t).await?;
        }
        let members = sqlx::query_scalar!(
            r#"SELECT contact_id FROM group_members
               WHERE group_id = ? AND (member_state IS NULL OR member_state != 'leftGroup')"#,
            group_id,
        )
        .fetch_all(&mut **t)
        .await?;

        let bytes = content.encode_to_vec();
        let mut receipt_ids = Vec::new();

        for contact_id in members {
            let mut contact_content = proto::EncryptedContent::decode(bytes.as_slice())?;
            decorate_content(
                &self.ctx,
                contact_id,
                &mut contact_content,
                message_id.is_some(),
            )
            .await?;

            if only_send_if_no_receipts_are_open {
                let count = sqlx::query_scalar!(
                    "SELECT COUNT(*) FROM receipts WHERE contact_id = ?",
                    contact_id
                )
                .fetch_one(&mut **t)
                .await?;
                if count > 10 {
                    continue;
                }
            }

            let mut retry_count = 0_i64;
            let mut last_retry = None;
            if let Some(msg_id) = &message_id {
                let previous = sqlx::query!(
                    r#"SELECT COUNT(*) AS "count!: i64", MAX(last_retry) AS last_retry
                       FROM receipts WHERE contact_id = ? AND message_id = ?"#,
                    contact_id,
                    msg_id,
                )
                .fetch_one(&mut **t)
                .await?;
                retry_count = previous.count;
                last_retry = previous.last_retry;
                sqlx::query!(
                    "DELETE FROM receipts WHERE contact_id = ? AND message_id = ?",
                    contact_id,
                    msg_id
                )
                .execute(&mut **t)
                .await?;
            }

            let receipt_id = queue_encrypted_content(t, contact_id, contact_content, true).await?;

            sqlx::query!(
                r#"UPDATE receipts SET message_id = ?, will_be_retried_by_media_upload = ?,
                   retry_count = ?, last_retry = ? WHERE receipt_id = ?"#,
                message_id,
                false, // only_return_encrypted_data is false for send_to_group
                retry_count,
                last_retry,
                receipt_id
            )
            .execute(&mut **t)
            .await?;

            receipt_ids.push(receipt_id);
        }

        // We CANNOT spawn the sending here immediately because the transaction is NOT committed yet!
        for receipt_id in receipt_ids {
            let ctx = self.ctx.clone();
            tokio::spawn(async move {
                // Sleep slightly to let the transaction commit
                tokio::time::sleep(std::time::Duration::from_millis(50)).await;
                if let Err(error) = send_queued_receipt(&ctx, &receipt_id).await {
                    tracing::warn!(receipt_id, "queued group message send failed: {error}");
                }
            });
        }
        Ok(())
    }

    pub async fn insert_and_send_text(
        &self,
        group_id: String,
        text: String,
        quote_message_id: Option<String>,
    ) -> Result<String> {
        let database = self.ctx.app_db.read().await.clone();
        let message_id = uuid::Uuid::new_v4().to_string();
        let timestamp = chrono::Utc::now().timestamp_millis();
        sqlx::query!(
            "UPDATE groups SET draft_message = NULL WHERE group_id = ?",
            group_id
        )
        .execute(&database.pool)
        .await?;
        database.notify_committed(["groups"]);
        sqlx::query!(
            r#"INSERT INTO messages(group_id, message_id, type, content, quotes_message_id, created_at)
               VALUES (?, ?, 'text', ?, ?, ?)"#,
            group_id,
            message_id,
            text,
            quote_message_id,
            timestamp / 1000,
        )
        .execute(&database.pool)
        .await?;
        database.notify_committed(["messages"]);
        self.send_to_group(
            group_id,
            proto::EncryptedContent {
                text_message: Some(encrypted_content::TextMessage {
                    sender_message_id: message_id.clone(),
                    text,
                    timestamp,
                    quote_message_id,
                }),
                ..Default::default()
            }
            .encode_to_vec(),
            Some(message_id.clone()),
            false,
        )
        .await?;
        Ok(message_id)
    }

    pub async fn insert_and_send_additional_data(
        &self,
        group_id: String,
        message_type: String,
        additional_data: Vec<u8>,
    ) -> Result<String> {
        let database = self.ctx.app_db.read().await.clone();
        let message_id = uuid::Uuid::new_v4().to_string();
        let timestamp = chrono::Utc::now().timestamp_millis();
        sqlx::query!(
            r#"INSERT INTO messages(group_id, message_id, type, additional_message_data, created_at)
               VALUES (?, ?, ?, ?, ?)"#,
            group_id,
            message_id,
            message_type,
            additional_data,
            timestamp / 1000,
        )
        .execute(&database.pool)
        .await?;
        database.notify_committed(["messages"]);
        self.send_to_group(
            group_id,
            proto::EncryptedContent {
                additional_data_message: Some(encrypted_content::AdditionalDataMessage {
                    sender_message_id: message_id.clone(),
                    additional_message_data: Some(additional_data),
                    timestamp,
                    r#type: message_type,
                }),
                ..Default::default()
            }
            .encode_to_vec(),
            Some(message_id.clone()),
            false,
        )
        .await?;
        Ok(message_id)
    }

    pub async fn insert_and_send_contact_share(
        &self,
        group_id: String,
        contact_ids: Vec<i64>,
    ) -> Result<String> {
        let app = self.ctx.app_db.read().await.clone();
        let signal = self.ctx.rust_db.read().await.clone();
        let mut contacts = Vec::new();
        for contact_id in contact_ids {
            let contact = sqlx::query!(
                "SELECT username, display_name FROM contacts WHERE user_id = ?",
                contact_id
            )
            .fetch_optional(&app.pool)
            .await?;
            let identity = sqlx::query_scalar!(
                "SELECT identity_key FROM signal_identities WHERE name = ?",
                contact_id.to_string()
            )
            .fetch_optional(&signal.pool)
            .await?;
            if let (Some(contact), Some(public_identity_key)) = (contact, identity) {
                contacts.push(proto::SharedContact {
                    user_id: contact_id,
                    public_identity_key,
                    display_name: contact.display_name.unwrap_or(contact.username),
                });
            }
        }
        let data = proto::AdditionalMessageData {
            r#type: proto::additional_message_data::Type::Contacts as i32,
            link: None,
            contacts,
            restored_flame_counter: None,
            ask_about_user_id: None,
        }
        .encode_to_vec();
        self.insert_and_send_additional_data(group_id, "contacts".into(), data)
            .await
    }

    pub async fn insert_and_send_ask_about_user(
        &self,
        contact_id: i64,
        ask_about_user_id: i64,
    ) -> Result<String> {
        let local_user_id = self
            .ctx
            .key_manager.lock().await
            .user_id
            .ok_or_else(|| TwonlyError::Generic("local user ID is unavailable".into()))?;
        let group_id = Group::direct_chat_id(local_user_id, contact_id);
        let database = self.ctx.app_db.read().await.clone();
        let mut transaction = database.pool.begin().await?;
        let contact = Contact::get_contact_by_id(&mut transaction, contact_id)
            .await?
            .ok_or_else(|| TwonlyError::Generic("contact does not exist".into()))?;
        Group::create_direct_chat(&self.ctx, &mut transaction, contact).await?;
        transaction.commit().await?;
        database.notify_committed(["groups", "group_members"]);
        let data = proto::AdditionalMessageData {
            r#type: proto::additional_message_data::Type::AskAboutUser as i32,
            link: None,
            contacts: Vec::new(),
            restored_flame_counter: None,
            ask_about_user_id: Some(ask_about_user_id),
        }
        .encode_to_vec();
        self.insert_and_send_additional_data(group_id, "askAboutUser".into(), data)
            .await
    }

    pub async fn send_typing(&self, group_id: String, is_typing: bool) -> Result<()> {
        if !UserConfig::load_from(&self.ctx)?.is_some_and(|config| config.typing_indicators) {
            return Ok(());
        }
        self.send_to_group(
            group_id,
            proto::EncryptedContent {
                typing_indicator: Some(encrypted_content::TypingIndicator {
                    is_typing,
                    created_at: chrono::Utc::now().timestamp_millis(),
                }),
                ..Default::default()
            }
            .encode_to_vec(),
            None,
            true,
        )
        .await
    }

    pub async fn edit_text(
        &self,
        group_id: String,
        message_id: String,
        text: String,
    ) -> Result<()> {
        self.send_to_group(
            group_id,
            proto::EncryptedContent {
                message_update: Some(encrypted_content::MessageUpdate {
                    r#type: encrypted_content::message_update::Type::EditText as i32,
                    sender_message_id: Some(message_id),
                    multiple_target_message_ids: Vec::new(),
                    text: Some(text),
                    timestamp: chrono::Utc::now().timestamp_millis(),
                }),
                ..Default::default()
            }
            .encode_to_vec(),
            None,
            false,
        )
        .await
    }

    pub async fn react(
        &self,
        group_id: String,
        message_id: String,
        emoji: String,
        remove: bool,
    ) -> Result<()> {
        self.send_to_group(
            group_id,
            proto::EncryptedContent {
                reaction: Some(encrypted_content::Reaction {
                    target_message_id: message_id,
                    emoji,
                    remove,
                }),
                ..Default::default()
            }
            .encode_to_vec(),
            None,
            false,
        )
        .await
    }

    pub async fn delete_message(&self, group_id: String, message_id: String) -> Result<()> {
        self.send_to_group(
            group_id,
            proto::EncryptedContent {
                message_update: Some(encrypted_content::MessageUpdate {
                    r#type: encrypted_content::message_update::Type::Delete as i32,
                    sender_message_id: Some(message_id),
                    multiple_target_message_ids: Vec::new(),
                    text: None,
                    timestamp: chrono::Utc::now().timestamp_millis(),
                }),
                ..Default::default()
            }
            .encode_to_vec(),
            None,
            false,
        )
        .await
    }

    pub async fn notify_opened(&self, contact_id: i64, message_ids: Vec<String>) -> Result<()> {
        if message_ids.is_empty() {
            return Ok(());
        }
        let timestamp = chrono::Utc::now().timestamp_millis();
        let content = proto::EncryptedContent {
            message_update: Some(encrypted_content::MessageUpdate {
                r#type: encrypted_content::message_update::Type::Opened as i32,
                sender_message_id: None,
                multiple_target_message_ids: message_ids.clone(),
                text: None,
                timestamp,
            }),
            ..Default::default()
        };
        send_c2c_message_to_contact()
            .ctx(&self.ctx)
            .contact_id(contact_id)
            .encrypted_content(content.encode_to_vec())
            .call()
            .await?;
        let database = self.ctx.app_db.read().await.clone();
        for message_id in message_ids {
            sqlx::query!(
                "UPDATE messages SET opened_at = ?, opened_by_all = ? WHERE message_id = ?",
                timestamp / 1000,
                timestamp / 1000,
                message_id
            )
            .execute(&database.pool)
            .await?;
        }
        database.notify_committed(["messages"]);
        Ok(())
    }

    pub async fn retransmit_all(&self) -> Result<()> {
        messages::retransmit_queued_receipts(&self.ctx).await
    }

    pub async fn send_receipt(&self, receipt_id: String) -> Result<()> {
        messages::send_queued_receipt(&self.ctx, &receipt_id).await
    }
}
