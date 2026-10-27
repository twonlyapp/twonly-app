/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::messages::incoming::messages::{
    self, queue_encrypted_content, send_queued_receipt,
};
use crate::api::messages::outgoing::{
    decorate_content, prepare_user_discovery, send_c2c_message_to_contact,
};
use crate::api::proto::client::{self as proto, encrypted_content};
use crate::context::Context;
use crate::database::app::contacts::table::Contact;
use crate::database::app::groups::native::Group;
use crate::error::{Result, TwonlyError};
use crate::user_config::UserConfig;
use prost::Message as _;
use std::sync::Arc;

// Match the server mailbox lifetime. Older rows without receipts may already
// have been delivered by builds that did not persist server acknowledgements.
const TEXT_RECOVERY_MAX_AGE_SECONDS: i64 = 60 * 24 * 60 * 60;

pub struct MessageService {
    ctx: Arc<Context>,
}

impl MessageService {
    pub fn new(ctx: &Arc<Context>) -> Self {
        Self { ctx: ctx.clone() }
    }

    /// Older builds committed the message before asynchronously creating its
    /// outbox. A pause in that gap left no receipt for any retry sweep to find.
    pub(crate) async fn recover_unqueued_text(&self) -> Result<()> {
        let database = self.ctx.app_db.read().await.clone();
        let cutoff = chrono::Utc::now().timestamp() - TEXT_RECOVERY_MAX_AGE_SECONDS;
        let ids = sqlx::query_scalar!(
            "SELECT m.message_id FROM messages m WHERE m.sender_id IS NULL
             AND m.type = 'text' AND m.content IS NOT NULL
             AND m.ack_by_server IS NULL AND m.ack_by_user IS NULL
             AND m.is_deleted_from_sender = 0
             AND m.created_at >= ?
             AND NOT EXISTS (SELECT 1 FROM receipts r WHERE r.message_id = m.message_id)
             AND EXISTS (SELECT 1 FROM group_members gm JOIN contacts c ON c.user_id = gm.contact_id
                         JOIN groups g ON g.group_id = gm.group_id
                         WHERE gm.group_id = m.group_id AND g.left_group = 0 AND c.account_deleted = 0
                         AND (gm.member_state IS NULL OR gm.member_state != 'leftGroup'))
             ORDER BY m.created_at, m.message_id",
            cutoff,
        )
        .fetch_all(&database.pool)
        .await?;
        if ids.is_empty() {
            return Ok(());
        }
        prepare_user_discovery(&self.ctx, true).await?;
        for id in ids {
            // Native background code uses another SQLite connection. Reserve
            // the writer before reading so its writes cannot invalidate our snapshot.
            let mut t = database.pool.begin_with("BEGIN IMMEDIATE").await?;
            let Some(message) = crate::database::app::messages::queries::get(&mut t, &id).await?
            else {
                continue;
            };
            // Recheck under the writer: a concurrent recovery or late delivery
            // receipt may have resolved this row since the initial scan.
            if message.ack_by_server.is_some()
                || message.ack_by_user.is_some()
                || message.is_deleted_from_sender
                || message.created_at < cutoff
            {
                continue;
            }
            let queued = sqlx::query_scalar!(
                "SELECT EXISTS(SELECT 1 FROM receipts WHERE message_id = ?)",
                id
            )
            .fetch_one(&mut *t)
            .await?
                != 0;
            if queued {
                continue;
            }
            let content = proto::EncryptedContent {
                text_message: Some(encrypted_content::TextMessage {
                    sender_message_id: id.clone(),
                    text: message.content.unwrap_or_default(),
                    timestamp: message.created_at * 1000,
                    quote_message_id: message.quotes_message_id,
                    additional_message_data: message.additional_message_data,
                }),
                ..Default::default()
            }
            .encode_to_vec();
            self.send_to_group_in_transaction(&mut t, message.group_id, content, Some(id), false)
                .await?;
            t.commit().await?;
        }
        Ok(())
    }

    pub async fn send_to_group(
        &self, group_id: String, encrypted_content: Vec<u8>, message_id: Option<String>,
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
            sqlx::query!(
                "UPDATE groups SET last_message_exchange = CAST(strftime('%s','now') AS INTEGER), \
                 deleted_content = 0 WHERE group_id = ?",
                group_id
            )
            .execute(&database.pool)
            .await?;
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
    /// Persisted messages require [`prepare_user_discovery`] before the caller
    /// opens its transaction. Initializing it here would reacquire the writer.
    pub async fn send_to_group_in_transaction(
        &self, t: &mut sqlx::Transaction<'_, sqlx::Sqlite>, group_id: String,
        encrypted_content: Vec<u8>, message_id: Option<String>,
        only_send_if_no_receipts_are_open: bool,
    ) -> Result<()> {
        let mut content = proto::EncryptedContent::decode(encrypted_content.as_slice())?;

        content.group_id = Some(group_id.clone());

        if message_id.is_some()
            || content.reaction.is_some()
            || content.media.is_some()
            || content.text_message.is_some()
        {
            sqlx::query!(
                "UPDATE groups SET last_message_exchange = CAST(strftime('%s','now') AS INTEGER), \
                 deleted_content = 0 WHERE group_id = ?",
                group_id
            )
            .execute(&mut **t)
            .await?;
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

        // The single-connection pool keeps each sender's first receipt lookup
        // waiting until this transaction commits (or rolls back). No timer is
        // needed: a committed update can be sent immediately.
        for receipt_id in receipt_ids {
            let ctx = self.ctx.clone();

            crate::database::lifecycle::spawn(async move {
                if let Err(error) = send_queued_receipt(&ctx, &receipt_id).await {
                    tracing::warn!(receipt_id, "queued group message send failed: {error}");
                }
            });
        }

        Ok(())
    }

    /// Persists an outgoing text message and hands the delivery off.
    ///
    /// The composer may provide the ID and timestamp of an already visible
    /// pending bubble. Persist those unchanged so Drift replaces that bubble
    /// without moving or duplicating it. Delivery runs on a separate task after
    /// the local row commits.
    ///
    /// `additional_message_data` records where the text came from when the
    /// sender did not type it -- today, the webxdc app that produced it. It is
    /// stored beside the message so the chat can say so on both devices.
    pub async fn insert_and_send_text(
        &self, group_id: String, text: String, quote_message_id: Option<String>,
        additional_message_data: Option<Vec<u8>>, message_id: Option<String>,
        timestamp_ms: Option<i64>,
    ) -> Result<String> {
        if let Some(data) = additional_message_data.as_deref() {
            crate::services::stickers::validate_additional_if_sticker(data)?;
        }

        prepare_user_discovery(&self.ctx, true).await?;

        let database = self.ctx.app_db.read().await.clone();

        let message_id = message_id.unwrap_or_else(|| uuid::Uuid::new_v4().to_string());

        let timestamp = timestamp_ms.unwrap_or_else(|| chrono::Utc::now().timestamp_millis());

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

        Group::record_text_or_media(&mut t, &group_id, timestamp / 1000).await?;

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

        // Persist the retryable plaintext outbox with the visible message.
        // Suspending or terminating the app after this commit cannot strand
        // a bubble without a receipt for the reconnect sweep to deliver.
        self.send_to_group_in_transaction(
            &mut t,
            group_id,
            content,
            Some(message_id.clone()),
            false,
        )
        .await?;

        t.commit().await?;

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
        &self, group_id: String, message_type: String, additional_data: Vec<u8>, hidden: bool,
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
        &self, group_id: String, contact_ids: Vec<i64>,
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
            sticker: None,
            live_location: None,
        }
        .encode_to_vec();

        self.insert_and_send_additional_data(group_id, "contacts".into(), data, false)
            .await
    }

    pub async fn insert_and_send_ask_about_user(
        &self, contact_id: i64, ask_about_user_id: i64,
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
            sticker: None,
            live_location: None,
        }
        .encode_to_vec();

        self.insert_and_send_additional_data(group_id, "askAboutUser".into(), data, false)
            .await
    }

    pub async fn send_typing(&self, group_id: String, is_typing: bool) -> Result<()> {
        self.send_typing_indicator(group_id, is_typing, false).await
    }

    /// Tells the group that the chat was left, so their indicator goes away
    /// now instead of when the last announcement expires.
    pub async fn send_chat_closed(&self, group_id: String) -> Result<()> {
        self.send_typing_indicator(group_id, false, true).await
    }

    async fn send_typing_indicator(
        &self, group_id: String, is_typing: bool, chat_closed: bool,
    ) -> Result<()> {
        if !UserConfig::load_from(&self.ctx)?.is_some_and(|config| config.typing_indicators) {
            return Ok(());
        }

        self.send_to_group(
            group_id,
            proto::EncryptedContent {
                typing_indicator: Some(encrypted_content::TypingIndicator {
                    is_typing,
                    created_at: chrono::Utc::now().timestamp_millis(),
                    chat_closed,
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
        &self, group_id: String, message_id: String, text: String,
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
        &self, group_id: String, message_id: String, emoji: String, remove: bool,
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

        let database = self.ctx.app_db.read().await.clone();
        // A game card is stable in the UI, while each move has its own receipt
        // identity. Snapshot that identity before sending, so a turn arriving
        // during the request cannot accidentally be acknowledged as opened.
        let message_ids = crate::database::app::messages::queries::opened_targets(
            &mut *database.read_pool.acquire().await?,
            &message_ids,
            contact_id,
        )
        .await?;
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

#[cfg(test)]
mod pending_text_tests {

    use super::*;

    #[tokio::test]
    async fn recovery_leaves_texts_older_than_the_mailbox_lifetime_unqueued() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        crate::api::ApiRuntime::close(&ctx).await?;
        let database = ctx.app_db.read().await.clone();
        sqlx::raw_sql(
            "INSERT INTO contacts(user_id, username) VALUES (7, 'peer');
             INSERT INTO groups(group_id, group_name) VALUES ('chat', 'Chat');
             INSERT INTO group_members(group_id, contact_id) VALUES ('chat', 7);",
        )
        .execute(&database.pool)
        .await?;
        let cutoff = chrono::Utc::now().timestamp() - TEXT_RECOVERY_MAX_AGE_SECONDS;
        for (id, created_at) in [("too-old", cutoff - 60), ("recent-enough", cutoff + 60)] {
            sqlx::query(
                "INSERT INTO messages(message_id, group_id, type, content, created_at)
                 VALUES (?, 'chat', 'text', 'Retained text', ?)",
            )
            .bind(id)
            .bind(created_at)
            .execute(&database.pool)
            .await?;
        }
        for _ in 0..2 {
            MessageService::new(&ctx).recover_unqueued_text().await?;
        }
        let queued: Vec<String> = sqlx::query_scalar("SELECT message_id FROM receipts")
            .fetch_all(&database.pool)
            .await?;
        assert_eq!(queued, vec!["recent-enough"]);
        let old_rows: i64 =
            sqlx::query_scalar("SELECT COUNT(*) FROM messages WHERE message_id = 'too-old'")
                .fetch_one(&database.pool)
                .await?;
        assert_eq!(old_rows, 1, "keep old local history without resending it");
        database.close().await;
        ctx.rust_db.read().await.pool.close().await;
        Ok(())
    }

    #[tokio::test]
    async fn reconnect_recovers_an_old_unqueued_text_once_and_keeps_delivered_messages_finished(
    ) -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        crate::api::ApiRuntime::close(&ctx).await?;
        let database = ctx.app_db.read().await.clone();
        sqlx::raw_sql(
            "INSERT INTO contacts(user_id, username) VALUES (7, 'peer');
             INSERT INTO groups(group_id, group_name, left_group) VALUES ('chat', 'Chat', 0), ('left', 'Left', 1);
             INSERT INTO group_members(group_id, contact_id) VALUES ('chat', 7);
             INSERT INTO group_members(group_id, contact_id) VALUES ('left', 7);
             INSERT INTO messages(message_id, group_id, type, content, ack_by_server)
             VALUES ('stranded', 'chat', 'text', 'Retained text', NULL),
                    ('delivered', 'chat', 'text', 'Already delivered', 123),
                    ('left', 'left', 'text', 'Do not resend after leaving', NULL);",
        )
        .execute(&database.pool)
        .await?;
        for _ in 0..2 {
            MessageService::new(&ctx).recover_unqueued_text().await?;
        }
        let pending: Vec<String> =
            sqlx::query_scalar("SELECT message_id FROM receipts ORDER BY message_id")
                .fetch_all(&database.pool)
                .await?;
        assert_eq!(pending, vec!["stranded"]);
        Ok(())
    }

    #[tokio::test]
    async fn a_text_is_not_committed_without_its_durable_delivery_receipt() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        crate::api::ApiRuntime::close(&ctx).await?;
        let database = ctx.app_db.read().await.clone();
        sqlx::raw_sql(
            "INSERT INTO contacts(user_id, username) VALUES (7, 'peer');
             INSERT INTO groups(group_id, group_name) VALUES ('chat', 'Chat');
             INSERT INTO group_members(group_id, contact_id) VALUES ('chat', 7);
             CREATE TRIGGER fail_receipt BEFORE INSERT ON receipts
             BEGIN SELECT RAISE(ABORT, 'receipt storage failed'); END;",
        )
        .execute(&database.pool)
        .await?;
        let result = MessageService::new(&ctx)
            .insert_and_send_text(
                "chat".into(),
                "Keep retryable".into(),
                None,
                None,
                Some("pending".into()),
                None,
            )
            .await;
        assert!(
            result.is_err(),
            "a failed outbox insertion must reach the composer"
        );
        let count: i64 =
            sqlx::query_scalar("SELECT COUNT(*) FROM messages WHERE message_id = 'pending'")
                .fetch_one(&database.pool)
                .await?;
        assert_eq!(
            count, 0,
            "do not leave an unacknowledged bubble which no receipt sweep can find"
        );
        sqlx::query("DROP TRIGGER fail_receipt")
            .execute(&database.pool)
            .await?;
        MessageService::new(&ctx)
            .insert_and_send_text(
                "chat".into(),
                "Keep retryable".into(),
                None,
                None,
                Some("pending".into()),
                None,
            )
            .await?;
        let count: i64 =
            sqlx::query_scalar("SELECT COUNT(*) FROM receipts WHERE message_id = 'pending'")
                .fetch_one(&database.pool)
                .await?;
        assert_eq!(
            count, 1,
            "the receipt must already exist when persistence returns"
        );
        Ok(())
    }

    #[tokio::test]

    async fn persists_the_pending_bubbles_identity_and_timestamp() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;

        let database = ctx.app_db.read().await.clone();

        sqlx::query("INSERT INTO groups(group_id, group_name) VALUES ('chat', 'Chat')")
            .execute(&database.pool)
            .await?;

        let id = uuid::Uuid::new_v4().to_string();

        let timestamp = 1_790_000_000_000_i64;

        let returned_id = MessageService::new(&ctx)
            .insert_and_send_text(
                "chat".into(),
                "Immediate message".into(),
                None,
                None,
                Some(id.clone()),
                Some(timestamp),
            )
            .await?;

        assert_eq!(returned_id, id);

        let (stored_id, content, created_at): (String, String, i64) = sqlx::query_as(
            "SELECT message_id, content, created_at FROM messages WHERE group_id = 'chat'",
        )
        .fetch_one(&database.pool)
        .await?;

        assert_eq!(stored_id, id);

        assert_eq!(content, "Immediate message");

        assert_eq!(created_at, timestamp / 1000);

        // Existing callers still let Rust allocate the identity and timestamp.
        let generated_id = MessageService::new(&ctx)
            .insert_and_send_text("chat".into(), "Another".into(), None, None, None, None)
            .await?;

        assert_ne!(generated_id, id);

        assert!(uuid::Uuid::parse_str(&generated_id).is_ok());

        Ok(())
    }
}
