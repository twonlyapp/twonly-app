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
            sqlx::query!("UPDATE groups SET last_message_exchange = CAST(strftime('%s','now') AS INTEGER), deleted_content = 0 WHERE group_id = ?", group_id)
                .execute(&database.pool).await?;
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

    /// Queues one message to every member from inside the caller's
    /// transaction.
    ///
    /// Everything here runs on `t`. The app database has a single connection,
    /// and the caller is holding it, so anything that went to the pool instead
    /// would wait thirty seconds for a connection that cannot be freed until
    /// this call returns.
    ///
    /// That is also why `message_id` has to stay `None` here: a persisted
    /// message asks user discovery for a version, which needs it initialized,
    /// and initializing it writes through the pool. Callers with a message id
    /// go through [`Self::send_to_group`], which sends outside a transaction.
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
        // Members are filtered here rather than in SQL so an excluded one can be
        // named. A member the sender believes has left is absent from every
        // group message, and silently: a membership row the group has moved
        // past -- a restored backup holding a stale state, say -- looks exactly
        // like a delivery that failed, from either end.
        let rows = sqlx::query!(
            r#"SELECT contact_id, member_state FROM group_members WHERE group_id = ?"#,
            group_id,
        )
        .fetch_all(&mut **t)
        .await?;

        let mut members = Vec::with_capacity(rows.len());
        for row in rows {
            if row.member_state.as_deref() == Some("leftGroup") {
                tracing::info!(
                    group_id,
                    contact_id = row.contact_id,
                    "not sending to a group member recorded as having left"
                );
                continue;
            }
            members.push(row.contact_id);
        }

        tracing::info!(
            group_id,
            members = members.len(),
            "sending a group message to its members"
        );

        let bytes = content.encode_to_vec();
        let mut receipt_ids = Vec::new();

        for contact_id in members {
            let mut contact_content = proto::EncryptedContent::decode(bytes.as_slice())?;
            decorate_content(
                &self.ctx,
                t,
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
                    tracing::info!(
                        group_id,
                        contact_id,
                        open_receipts = count,
                        "not sending to a group member with too many open receipts"
                    );
                    continue;
                }
            }

            let mut retry_count = 0_i64;
            let mut last_retry = None;
            // A resend of a message the server already took has already pushed
            // this member once. The replacement receipt must not ask for a
            // second alert about the same message.
            let mut already_woken = false;
            if let Some(msg_id) = &message_id {
                let previous = sqlx::query!(
                    r#"SELECT COUNT(*) AS "count!: i64", MAX(last_retry) AS last_retry,
                              MAX(ack_by_server_at) AS acknowledged
                       FROM receipts WHERE contact_id = ? AND message_id = ?"#,
                    contact_id,
                    msg_id,
                )
                .fetch_one(&mut **t)
                .await?;
                retry_count = previous.count;
                last_retry = previous.last_retry;
                already_woken = previous.acknowledged.is_some();
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
                   retry_count = ?, last_retry = ?,
                   wake_receiver = CASE WHEN ? THEN 0 ELSE wake_receiver END
                   WHERE receipt_id = ?"#,
                message_id,
                false, // only_return_encrypted_data is false for send_to_group
                retry_count,
                last_retry,
                already_woken,
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

    /// Persists an outgoing text message and hands the delivery off.
    ///
    /// The composer is blocked on this call, and the chat list can only render
    /// the new bubble once its own `SELECT` gets the single SQLite connection
    /// back. Everything the send needs -- decorating the payload, queueing a
    /// receipt per member, establishing a session, the server round trip --
    /// competes for exactly that connection, which is how a message could reach
    /// the other side before showing up here. So the row the UI renders from is
    /// committed and published on its own, in one transaction, and the send
    /// runs on a separate task.
    /// Sends a text message.
    ///
    /// `additional_message_data` records where the text came from when the
    /// sender did not type it -- today, the webxdc app that produced it. It is
    /// stored beside the message so the chat can say so on both devices.
    pub async fn insert_and_send_text(
        &self,
        group_id: String,
        text: String,
        quote_message_id: Option<String>,
        additional_message_data: Option<Vec<u8>>,
    ) -> Result<String> {
        let database = self.ctx.app_db.read().await.clone();
        let message_id = uuid::Uuid::new_v4().to_string();
        let timestamp = chrono::Utc::now().timestamp_millis();

        let mut t = database.pool.begin().await?;
        sqlx::query!(
            "UPDATE groups SET draft_message = NULL WHERE group_id = ?",
            group_id
        )
        .execute(&mut *t)
        .await?;
        sqlx::query!(
            r#"INSERT INTO messages(group_id, message_id, type, content, quotes_message_id,
                                    additional_message_data, created_at)
               VALUES (?, ?, 'text', ?, ?, ?, ?)"#,
            group_id,
            message_id,
            text,
            quote_message_id,
            additional_message_data,
            timestamp / 1000,
        )
        .execute(&mut *t)
        .await?;
        // The commit hook installed on the connection publishes `groups` and
        // `messages` on its own, so the chat list is already on its way.
        t.commit().await?;

        let content = proto::EncryptedContent {
            text_message: Some(encrypted_content::TextMessage {
                sender_message_id: message_id.clone(),
                text,
                timestamp,
                quote_message_id,
                additional_message_data,
            }),
            ..Default::default()
        }
        .encode_to_vec();

        // The message row already carries the "not acknowledged yet" state the
        // bubble shows, so a failure here is reported the same way a failed
        // network send is: the bubble stays unacknowledged until a retry sweep
        // gets it through.
        let ctx = self.ctx.clone();
        let sent_message_id = message_id.clone();
        tokio::spawn(async move {
            if let Err(error) = Self::new(&ctx)
                .send_to_group(group_id, content, Some(sent_message_id.clone()), false)
                .await
            {
                tracing::warn!(
                    message_id = sent_message_id,
                    "sending the text message failed: {error}"
                );
            }
        });

        Ok(message_id)
    }

    /// Sends one additional-data message and, unless it is hidden, records it
    /// in the chat.
    ///
    /// `hidden` marks state a feature exchanges rather than something a person
    /// sent: no row is written, so it cannot show up in a chat or be swept up
    /// by the deletion timer, and the receiving side neither notifies nor wakes
    /// for it.
    pub async fn insert_and_send_additional_data(
        &self,
        group_id: String,
        message_type: String,
        additional_data: Vec<u8>,
        hidden: bool,
    ) -> Result<String> {
        let database = self.ctx.app_db.read().await.clone();
        let message_id = uuid::Uuid::new_v4().to_string();
        let timestamp = chrono::Utc::now().timestamp_millis();
        if !hidden {
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
        }
        self.send_to_group(
            group_id,
            proto::EncryptedContent {
                additional_data_message: Some(encrypted_content::AdditionalDataMessage {
                    sender_message_id: message_id.clone(),
                    additional_message_data: Some(additional_data),
                    timestamp,
                    r#type: message_type,
                    hidden,
                }),
                ..Default::default()
            }
            .encode_to_vec(),
            // A receipt's `message_id` is a foreign key into `messages`, and a
            // hidden message has no row there. It is also what ties a receipt
            // to a chat message so delivery state can be shown and a retry
            // deduplicated -- neither of which a hidden message has any use
            // for, so it goes out unattached.
            if hidden {
                None
            } else {
                Some(message_id.clone())
            },
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
            let Some(contact) = contact else {
                tracing::warn!("skipping unknown contact {contact_id} in contact share");
                continue;
            };
            // A contact without a locally known identity key is still worth
            // sharing: the recipient only needs the user id to add them. The
            // key is what lets the recipient inherit the trust edge, so an
            // empty one simply means they cannot, not that the share fails.
            if identity.is_none() {
                tracing::info!("sharing contact {contact_id} without an identity key");
            }
            contacts.push(proto::SharedContact {
                user_id: contact_id,
                public_identity_key: identity.unwrap_or_default(),
                display_name: contact.display_name.unwrap_or(contact.username),
            });
        }
        if contacts.is_empty() {
            return Err(TwonlyError::Generic(
                "none of the selected contacts could be shared".into(),
            ));
        }
        let data = proto::AdditionalMessageData {
            r#type: proto::additional_message_data::Type::Contacts as i32,
            link: None,
            contacts,
            restored_flame_counter: None,
            ask_about_user_id: None,
            webxdc_app: None,
            webxdc_update: None,
            webxdc_origin: None,
            webxdc_sync: None,
            webxdc_sync_request: None,
        }
        .encode_to_vec();
        self.insert_and_send_additional_data(group_id, "contacts".into(), data, false)
            .await
    }

    pub async fn insert_and_send_ask_about_user(
        &self,
        contact_id: i64,
        ask_about_user_id: i64,
    ) -> Result<String> {
        let local_user_id = self
            .ctx
            .key_manager
            .lock()
            .await
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
        let data = proto::AdditionalMessageData {
            r#type: proto::additional_message_data::Type::AskAboutUser as i32,
            link: None,
            contacts: Vec::new(),
            restored_flame_counter: None,
            ask_about_user_id: Some(ask_about_user_id),
            webxdc_app: None,
            webxdc_update: None,
            webxdc_origin: None,
            webxdc_sync: None,
            webxdc_sync_request: None,
        }
        .encode_to_vec();
        self.insert_and_send_additional_data(group_id, "askAboutUser".into(), data, false)
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
        let mut transaction = database.pool.begin().await?;
        for message_id in &message_ids {
            sqlx::query!(
                "UPDATE messages SET opened_at = ?, opened_by_all = ? WHERE message_id = ?",
                timestamp / 1000,
                timestamp / 1000,
                message_id
            )
            .execute(&mut *transaction)
            .await?;
        }
        crate::services::notifications::clear_opened_messages(
            &mut transaction,
            &message_ids,
            timestamp / 1000,
        )
        .await?;
        transaction.commit().await?;
        Ok(())
    }

    pub async fn retransmit_all(&self) -> Result<()> {
        messages::retransmit_queued_receipts(&self.ctx).await
    }

    pub async fn send_receipt(&self, receipt_id: String) -> Result<()> {
        messages::send_queued_receipt(&self.ctx, &receipt_id).await
    }
}
