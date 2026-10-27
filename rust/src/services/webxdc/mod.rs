/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Webxdc app instances and their update log.
//!
//! An instance is one app placed into one chat. Its state is the ordered log of
//! updates in `webxdc_updates`, which lives outside `messages` on purpose: the
//! per-chat purge deletes message rows one by one, and a log with holes in it
//! rebuilds a state that is wrong rather than empty.

pub mod bundle;
pub mod store;
pub(crate) mod visibility;

use crate::api::messages::outgoing::send_c2c_message_to_contact;
use crate::api::proto::client as proto;
use crate::context::Context;
use crate::database::app::messages::native::{MessageType, NewMessage};
use crate::error::{Result, TwonlyError};
use hmac::{Hmac, KeyInit, Mac};
use sha2::{Digest, Sha256};
use sqlx::{Sqlite, Transaction};
use std::sync::Arc;

/// The spec's default ceiling for one serialised update.
pub const SEND_UPDATE_MAX_SIZE: usize = 128_000;

/// The spec's default pacing hint, advertised to apps as `sendUpdateInterval`.
pub const SEND_UPDATE_INTERVAL_MS: i64 = 10_000;

/// Bounds on how much an app may accumulate. An app is third-party code that
/// can call `sendUpdate` in a loop, so both the count and the total size need a
/// ceiling that does not depend on the app behaving.
const MAX_UPDATES_PER_INSTANCE: i64 = 100_000;

const MAX_PAYLOAD_BYTES_PER_INSTANCE: i64 = 32 * 1024 * 1024;

/// Sending burst allowance, counted over the trailing minute. High enough that
/// two people playing a turn-based game quickly never reach it -- a move, a
/// Mills capture after it, a seat claim and a score all count -- since a
/// refused move has to be played again. An app sending in a loop still does.
const MAX_UPDATES_PER_MINUTE: i64 = 30;

const SYNC_CHUNK_BYTES: usize = 48 * 1024;

const MAX_SYNC_CHUNKS: u32 = 700;

#[derive(sqlx::FromRow)]

struct SyncInstanceRow {
    instance_id: String,
    app_id: String,
    version: i64,
    summary: Option<String>,
    document: Option<String>,
    created_at: i64,
    last_update_at: i64,
}

#[derive(sqlx::FromRow)]

struct SyncUpdateRow {
    message_id: String,
    sender_id: Option<i64>,
    payload: String,
    info: Option<String>,
    href: Option<String>,
    received_at: i64,
}

#[derive(sqlx::FromRow)]

struct PendingUpdateRow {
    message_id: String,
    sender_id: i64,
    payload: String,
    info: Option<String>,
    notification_content: Option<String>,
    href: Option<String>,
    summary: Option<String>,
    document: Option<String>,
    received_at: i64,
}

/// Text an app can put in front of the user, outside its own sandbox. Bounded
/// so a chat row or a notification cannot be filled with app-controlled text.
const MAX_INFO_CHARS: usize = 200;

const MAX_SUMMARY_CHARS: usize = 64;

const MAX_DOCUMENT_CHARS: usize = 128;

/// Games select an outcome; the receiving twonly app owns its wording.
#[derive(Debug, Clone, Copy, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "snake_case")]
pub(crate) enum GameNotification {
    Turn,
    Won,
    Lost,
}

#[derive(Debug, serde::Serialize, serde::Deserialize)]
#[serde(untagged, deny_unknown_fields)]
pub(crate) enum AppNotification {
    Text(String),
    Game { game: GameNotification },
}

pub struct WebxdcInstance {
    pub instance_id: String,
    pub group_id: String,
    pub app_id: String,
    pub version: i64,
    pub bundle_sha256: Option<String>,
    pub origin_token: String,
    pub summary: Option<String>,
    pub document: Option<String>,
}

pub struct WebxdcUpdate {
    pub serial: i64,
    pub payload: String,
    pub info: Option<String>,
    pub href: Option<String>,
    /// `None` when this device sent the update.
    pub sender_id: Option<i64>,
}

pub struct WebxdcService {
    ctx: Arc<Context>,
}

impl WebxdcService {
    pub fn new(ctx: &Arc<Context>) -> Self {
        Self { ctx: ctx.clone() }
    }

    fn store(&self) -> store::WebxdcStore {
        store::WebxdcStore::new(&self.ctx)
    }

    /// Requests existing one-time app state after joining a group. Spawned so
    /// the group-create transaction can commit before the sender needs the app
    /// database connection.
    pub(crate) fn spawn_sync_request(ctx: &Arc<Context>, group_id: String, contact_id: i64) {
        let ctx = ctx.clone();

        crate::database::lifecycle::spawn(async move {
            let data = proto::AdditionalMessageData {
                r#type: proto::additional_message_data::Type::WebxdcSyncRequest as i32,
                webxdc_sync_request: Some(proto::WebxdcSyncRequest {}),
                ..Default::default()
            };

            let content = proto::EncryptedContent {
                group_id: Some(group_id),
                additional_data_message: Some(proto::encrypted_content::AdditionalDataMessage {
                    sender_message_id: uuid::Uuid::new_v4().to_string(),
                    timestamp: chrono::Utc::now().timestamp_millis(),
                    r#type: "webxdcSyncRequest".into(),
                    additional_message_data: Some(prost::Message::encode_to_vec(&data)),
                    hidden: true,
                }),
                ..Default::default()
            };

            if let Err(error) = send_c2c_message_to_contact()
                .ctx(&ctx)
                .contact_id(contact_id)
                .encrypted_content(prost::Message::encode_to_vec(&content))
                .call()
                .await
            {
                tracing::warn!(%error, "could not request one-time app state");
            }
        });
    }

    /// Sends every one-time app and its authoritative update log to one new
    /// member. Transfers are hidden, encrypted contact-to-contact messages.
    pub async fn send_one_time_apps_to_contact(
        &self, group_id: &str, contact_id: i64,
    ) -> Result<()> {
        let database = self.ctx.app_db.read().await.clone();

        let local_user_id = self.ctx.user_id().await?;

        let instances = sqlx::query_as!(
            SyncInstanceRow,
            r#"SELECT instance.instance_id, instance.app_id, instance.version,
                      instance.summary, instance.document, instance.created_at,
                      instance.last_update_at
               FROM webxdc_instances AS instance
               JOIN webxdc_apps AS app
                 ON app.app_id = instance.app_id AND app.version = instance.version
               WHERE instance.group_id = ? AND app.one_time = 1
               ORDER BY instance.created_at, instance.instance_id"#,
            group_id
        )
        .fetch_all(&database.pool)
        .await?;

        for instance in instances {
            let updates = sqlx::query_as!(
                SyncUpdateRow,
                r#"SELECT message_id, sender_id, payload, info, href, received_at
                   FROM webxdc_updates WHERE instance_id = ? ORDER BY serial"#,
                &instance.instance_id
            )
            .fetch_all(&database.pool)
            .await?;

            let payload = proto::WebxdcSyncPayload {
                instances: vec![proto::WebxdcSyncInstance {
                    instance_id: instance.instance_id,
                    app_id: instance.app_id,
                    version: instance.version,
                    summary: instance.summary,
                    document: instance.document,
                    created_at: instance.created_at,
                    last_update_at: instance.last_update_at,
                    updates: updates
                        .into_iter()
                        .map(|update| proto::WebxdcSyncUpdate {
                            message_id: update.message_id,
                            sender_id: update.sender_id.or(Some(local_user_id)),
                            payload: update.payload,
                            info: update.info,
                            href: update.href,
                            received_at: update.received_at,
                        })
                        .collect(),
                }],
            };

            let encoded = prost::Message::encode_to_vec(&payload);

            let chunk_count = encoded.len().div_ceil(SYNC_CHUNK_BYTES) as u32;

            if chunk_count == 0 || chunk_count > MAX_SYNC_CHUNKS {
                tracing::warn!(
                    instance_id = payload.instances[0].instance_id,
                    "one-time app is too large to sync"
                );

                continue;
            }

            let transfer_id = uuid::Uuid::new_v4().to_string();

            let digest = Sha256::digest(&encoded).to_vec();

            for (chunk_index, bytes) in encoded.chunks(SYNC_CHUNK_BYTES).enumerate() {
                let data = proto::AdditionalMessageData {
                    r#type: proto::additional_message_data::Type::WebxdcSync as i32,
                    webxdc_sync: Some(proto::WebxdcSyncChunk {
                        transfer_id: transfer_id.clone(),
                        chunk_index: chunk_index as u32,
                        chunk_count,
                        payload_sha256: digest.clone(),
                        payload: bytes.to_vec(),
                    }),
                    ..Default::default()
                };

                let content = proto::EncryptedContent {
                    group_id: Some(group_id.to_owned()),
                    additional_data_message: Some(
                        proto::encrypted_content::AdditionalDataMessage {
                            sender_message_id: uuid::Uuid::new_v4().to_string(),
                            timestamp: chrono::Utc::now().timestamp_millis(),
                            r#type: "webxdcSync".into(),
                            additional_message_data: Some(prost::Message::encode_to_vec(&data)),
                            hidden: true,
                        },
                    ),
                    ..Default::default()
                };

                send_c2c_message_to_contact()
                    .ctx(&self.ctx)
                    .contact_id(contact_id)
                    .encrypted_content(prost::Message::encode_to_vec(&content))
                    .call()
                    .await?;
            }
        }

        Ok(())
    }

    pub(crate) async fn handle_sync_chunk(
        transaction: &mut Transaction<'_, Sqlite>, group_id: &str, sender_id: i64,
        chunk: &proto::WebxdcSyncChunk,
    ) -> Result<()> {
        if chunk.transfer_id.is_empty()
            || chunk.chunk_count == 0
            || chunk.chunk_count > MAX_SYNC_CHUNKS
            || chunk.chunk_index >= chunk.chunk_count
            || chunk.payload.len() > SYNC_CHUNK_BYTES
            || chunk.payload_sha256.len() != 32
        {
            return Err(TwonlyError::Generic("invalid webxdc sync chunk".into()));
        }

        let sender_is_member: bool = sqlx::query_scalar!(
            r#"SELECT EXISTS(SELECT 1 FROM group_members WHERE group_id = ? AND contact_id = ? AND 
             (member_state IS NULL OR member_state != 'leftGroup')) AS "sender_is_member!: bool""#,
            group_id,
            sender_id
        )
        .fetch_one(&mut **transaction)
        .await?;

        if !sender_is_member {
            return Err(TwonlyError::Generic(
                "webxdc sync sender is not a group member".into(),
            ));
        }

        sqlx::query!(
            r#"INSERT INTO webxdc_sync_chunks
                   (transfer_id, group_id, sender_id, chunk_index, chunk_count,
                    payload_sha256, payload)
               VALUES (?, ?, ?, ?, ?, ?, ?)
               ON CONFLICT(transfer_id, sender_id, chunk_index) DO NOTHING"#,
            &chunk.transfer_id,
            group_id,
            sender_id,
            chunk.chunk_index as i64,
            chunk.chunk_count as i64,
            &chunk.payload_sha256,
            &chunk.payload
        )
        .execute(&mut **transaction)
        .await?;

        sqlx::query!(
            "DELETE FROM webxdc_sync_chunks WHERE created_at < strftime('%s','now') - 86400",
        )
        .execute(&mut **transaction)
        .await?;

        let rows: Vec<(i64, i64, Vec<u8>, Vec<u8>)> = sqlx::query!(
            r#"SELECT chunk_index, chunk_count, payload_sha256, payload
               FROM webxdc_sync_chunks
               WHERE transfer_id = ? AND sender_id = ?
               ORDER BY chunk_index"#,
            &chunk.transfer_id,
            sender_id
        )
        .map(|row| {
            (
                row.chunk_index,
                row.chunk_count,
                row.payload_sha256,
                row.payload,
            )
        })
        .fetch_all(&mut **transaction)
        .await?;

        if rows.len() != chunk.chunk_count as usize {
            return Ok(());
        }

        if rows.iter().enumerate().any(|(index, row)| {
            row.0 != index as i64
                || row.1 != chunk.chunk_count as i64
                || row.2 != chunk.payload_sha256
        }) {
            return Err(TwonlyError::Generic(
                "inconsistent webxdc sync chunks".into(),
            ));
        }

        let encoded: Vec<u8> = rows.into_iter().flat_map(|row| row.3).collect();

        if Sha256::digest(&encoded).as_slice() != chunk.payload_sha256.as_slice() {
            return Err(TwonlyError::Generic("webxdc sync digest mismatch".into()));
        }

        let payload = <proto::WebxdcSyncPayload as prost::Message>::decode(encoded.as_slice())?;

        Self::install_sync_payload(transaction, group_id, sender_id, payload).await?;

        sqlx::query!(
            "DELETE FROM webxdc_sync_chunks WHERE transfer_id = ? AND sender_id = ?",
            &chunk.transfer_id,
            sender_id
        )
        .execute(&mut **transaction)
        .await?;

        Ok(())
    }

    async fn install_sync_payload(
        transaction: &mut Transaction<'_, Sqlite>, group_id: &str, sender_id: i64,
        payload: proto::WebxdcSyncPayload,
    ) -> Result<()> {
        if payload.instances.len() > 1 {
            return Err(TwonlyError::Generic("invalid webxdc sync payload".into()));
        }

        for instance in payload.instances {
            if instance.instance_id.is_empty()
                || instance.app_id.is_empty()
                || instance.updates.len() as i64 > MAX_UPDATES_PER_INSTANCE
                || instance
                    .updates
                    .iter()
                    .map(|update| update.payload.len() as i64)
                    .sum::<i64>()
                    > MAX_PAYLOAD_BYTES_PER_INSTANCE
            {
                return Err(TwonlyError::Generic("invalid webxdc sync payload".into()));
            }

            let exists: bool = sqlx::query_scalar!(
                r#"SELECT EXISTS(SELECT 1 FROM webxdc_instances WHERE instance_id = ?) AS "exists!: bool""#,
                &instance.instance_id
            )
            .fetch_one(&mut **transaction)
            .await?;

            if exists {
                Self::apply_pending_updates(
                    transaction,
                    &instance.instance_id,
                    &instance.app_id,
                    instance.version,
                    group_id,
                )
                .await?;

                continue;
            }

            let app_data = proto::AdditionalMessageData {
                r#type: proto::additional_message_data::Type::WebxdcApp as i32,
                webxdc_app: Some(proto::WebxdcApp {
                    app_id: instance.app_id.clone(),
                    version: instance.version,
                }),
                ..Default::default()
            };

            sqlx::query!(
                r#"INSERT INTO messages
                       (group_id, message_id, sender_id, type,
                        additional_message_data, created_at, ack_by_server)
                   VALUES (?, ?, ?, 'webxdcApp', ?, ?, strftime('%s','now'))
                   ON CONFLICT(message_id) DO NOTHING"#,
                group_id,
                &instance.instance_id,
                sender_id,
                prost::Message::encode_to_vec(&app_data),
                instance.created_at
            )
            .execute(&mut **transaction)
            .await?;

            Self::insert_instance(
                transaction,
                &instance.instance_id,
                group_id,
                &instance.app_id,
                instance.version,
            )
            .await?;

            sqlx::query!(
                "UPDATE webxdc_instances SET created_at = ? WHERE instance_id = ?",
                instance.created_at,
                &instance.instance_id
            )
            .execute(&mut **transaction)
            .await?;

            for update in instance.updates {
                if update.message_id.is_empty() || update.payload.len() > SEND_UPDATE_MAX_SIZE {
                    return Err(TwonlyError::Generic("invalid webxdc sync update".into()));
                }

                let info = sanitize(update.info.as_deref(), MAX_INFO_CHARS);

                let href = update.href.as_deref().and_then(sanitize_href);

                Self::append_update(
                    transaction,
                    &instance.instance_id,
                    &update.message_id,
                    update.sender_id,
                    &update.payload,
                    info.as_deref(),
                    href.as_deref(),
                    update.received_at,
                )
                .await?;
            }

            let summary = sanitize(instance.summary.as_deref(), MAX_SUMMARY_CHARS);

            let document = sanitize(instance.document.as_deref(), MAX_DOCUMENT_CHARS);

            Self::apply_instance_labels(
                transaction,
                &instance.instance_id,
                summary.as_deref(),
                document.as_deref(),
                instance.last_update_at,
            )
            .await?;

            Self::apply_pending_updates(
                transaction,
                &instance.instance_id,
                &instance.app_id,
                instance.version,
                group_id,
            )
            .await?;
        }

        Ok(())
    }

    /// Places an app into a chat and tells the other members which app and
    /// which version, so every participant runs the same code.
    pub async fn create_instance(
        &self, group_id: String, app_id: String, version: i64,
    ) -> Result<String> {
        // Resolved before anything is sent: pointing a chat at an app the store
        // does not offer should fail here rather than on every recipient's
        // device.
        self.store().resolve_bundle_sha256(&app_id, version).await?;

        self.ensure_chat_allowed(&group_id, &app_id).await?;

        if self
            .existing_instance_if_limited(&group_id, &app_id, version)
            .await?
            .is_some()
        {
            return Err(TwonlyError::Generic(
                "this app has already been added to the chat".into(),
            ));
        }

        let data = proto::AdditionalMessageData {
            r#type: proto::additional_message_data::Type::WebxdcApp as i32,
            webxdc_app: Some(proto::WebxdcApp {
                app_id: app_id.clone(),
                version,
            }),
            ..Default::default()
        };

        let message_id = crate::services::messages::MessageService::new(&self.ctx)
            .insert_and_send_additional_data(
                group_id.clone(),
                "webxdcApp".into(),
                prost::Message::encode_to_vec(&data),
                // The card is a real message: it shows in the chat and is worth
                // a notification.
                false,
            )
            .await?;

        let database = self.ctx.app_db.read().await.clone();

        let mut transaction = database.pool.begin().await?;

        Self::insert_instance(&mut transaction, &message_id, &group_id, &app_id, version).await?;

        transaction.commit().await?;

        Ok(message_id)
    }

    async fn ensure_chat_allowed(&self, group_id: &str, app_id: &str) -> Result<()> {
        let database = self.ctx.app_db.read().await.clone();

        let allowed: bool = sqlx::query_scalar!(
            r#"SELECT EXISTS(SELECT 1 FROM groups WHERE group_id = ? AND
                (is_direct_chat = 1 OR COALESCE((
                    SELECT direct_chat_only FROM webxdc_apps WHERE app_id = ?
                    ORDER BY published DESC, version DESC LIMIT 1
                ), 0) = 0)) AS "allowed!: bool""#,
            group_id,
            app_id
        )
        .fetch_one(&database.pool)
        .await?;

        if !allowed {
            return Err(TwonlyError::Generic(
                "this app can only be played in direct chats".into(),
            ));
        }

        Ok(())
    }

    async fn existing_instance_if_limited(
        &self, group_id: &str, app_id: &str, version: i64,
    ) -> Result<Option<String>> {
        let database = self.ctx.app_db.read().await.clone();

        let one_time: bool = sqlx::query_scalar!(
            "SELECT one_time FROM webxdc_apps WHERE app_id = ? AND version = ? AND published = 1",
            app_id,
            version
        )
        .fetch_one(&database.pool)
        .await?;

        if !one_time {
            return Ok(None);
        }

        Ok(sqlx::query_scalar!(
            "SELECT instance_id FROM webxdc_instances WHERE group_id = ? AND app_id = ? LIMIT 1",
            group_id,
            app_id
        )
        .fetch_optional(&database.pool)
        .await?)
    }

    /// Records the instance a peer placed into a chat. Nothing is downloaded
    /// here: a message must not be able to make a device fetch a bundle, only
    /// the user tapping Start may.
    pub(crate) async fn handle_incoming_app(
        transaction: &mut Transaction<'_, Sqlite>, message_id: &str, group_id: &str,
        app: &proto::WebxdcApp,
    ) -> Result<()> {
        Self::insert_instance(transaction, message_id, group_id, &app.app_id, app.version).await?;

        Self::apply_pending_updates(transaction, message_id, &app.app_id, app.version, group_id)
            .await
    }

    async fn insert_instance(
        transaction: &mut Transaction<'_, Sqlite>, instance_id: &str, group_id: &str, app_id: &str,
        version: i64,
    ) -> Result<()> {
        // Unguessable and per instance: this becomes the webview origin, and
        // the origin is what keeps one instance's stored data out of reach of
        // every other instance.
        let origin_token = uuid::Uuid::new_v4().simple().to_string();

        sqlx::query!(
            r#"INSERT INTO webxdc_instances
                   (instance_id, group_id, app_id, version, origin_token)
               VALUES (?, ?, ?, ?, ?)
               ON CONFLICT(instance_id) DO NOTHING"#,
            instance_id,
            group_id,
            app_id,
            version,
            origin_token,
        )
        .execute(&mut **transaction)
        .await?;

        Ok(())
    }

    /// Appends a peer's update to the log.
    ///
    /// The instance is looked up by the id in the payload and checked against
    /// the chat the message actually arrived in, so a member of one chat cannot
    /// inject state into a game being played in another.
    pub(crate) async fn handle_incoming_update(
        transaction: &mut Transaction<'_, Sqlite>, message_id: &str, group_id: &str,
        sender_id: i64, update: &proto::WebxdcUpdate, received_at: i64, self_user_id: i64,
    ) -> Result<()> {
        if update.instance_id.is_empty() || update.payload.len() > SEND_UPDATE_MAX_SIZE {
            tracing::warn!("invalid webxdc update, dropping");

            return Ok(());
        }

        let notification_content =
            crate::services::notifications::webxdc_notification_content(update, self_user_id);

        let instance = sqlx::query!(
            r#"SELECT group_id AS "group_id!: String", app_id AS "app_id!: String",
                      version AS "version!: i64"
               FROM webxdc_instances WHERE instance_id = ?"#,
            update.instance_id,
        )
        .fetch_optional(&mut **transaction)
        .await?;

        let Some(instance) = instance else {
            // A newly joined member can receive a live update before the app
            // snapshot. Keep it until the instance arrives; deletion removes
            // these rows with the group.
            sqlx::query!(
                "DELETE FROM webxdc_pending_updates WHERE received_at < strftime('%s','now') - \
                 604800",
            )
            .execute(&mut **transaction)
            .await?;

            let pending: (i64, i64) = sqlx::query!(
                r#"SELECT COUNT(*) AS "count!: i64",
                          COALESCE(SUM(LENGTH(payload)), 0) AS "bytes!: i64"
                   FROM webxdc_pending_updates WHERE instance_id = ? AND group_id = ?"#,
                &update.instance_id,
                group_id
            )
            .map(|row| (row.count, row.bytes))
            .fetch_one(&mut **transaction)
            .await?;

            if pending.0 >= MAX_UPDATES_PER_INSTANCE
                || pending.1 + update.payload.len() as i64 > MAX_PAYLOAD_BYTES_PER_INSTANCE
            {
                tracing::warn!("pending webxdc instance is over budget, dropping update");

                return Ok(());
            }

            sqlx::query!(
                r#"INSERT INTO webxdc_pending_updates
                       (message_id, instance_id, group_id, sender_id, payload,
                        info, href, summary, document, received_at, notification_content)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                   ON CONFLICT(message_id) DO NOTHING"#,
                message_id,
                &update.instance_id,
                group_id,
                sender_id,
                &update.payload,
                &update.info,
                &update.href,
                &update.summary,
                &update.document,
                received_at,
                notification_content
            )
            .execute(&mut **transaction)
            .await?;

            return Ok(());
        };

        if instance.group_id != group_id {
            tracing::warn!("webxdc update arrived in the wrong chat, dropping");

            return Ok(());
        }

        if !Self::within_instance_budget(transaction, &update.instance_id).await? {
            tracing::warn!("webxdc instance is over budget, dropping update");

            return Ok(());
        }

        let info = announcement(update);

        let href = update.href.as_deref().and_then(sanitize_href);

        let summary = sanitize(update.summary.as_deref(), MAX_SUMMARY_CHARS);

        let document = sanitize(update.document.as_deref(), MAX_DOCUMENT_CHARS);

        let inserted = Self::append_update(
            transaction,
            &update.instance_id,
            message_id,
            Some(sender_id),
            &update.payload,
            info.as_deref(),
            href.as_deref(),
            received_at,
        )
        .await?;

        if !inserted {
            return Ok(());
        }

        Self::apply_instance_labels(
            transaction,
            &update.instance_id,
            summary.as_deref(),
            document.as_deref(),
            received_at,
        )
        .await?;

        if let Some(info) = info.as_deref() {
            Self::insert_info_message(
                transaction,
                &update.instance_id,
                &instance.app_id,
                instance.version,
                group_id,
                message_id,
                Some(sender_id),
                info,
                received_at,
                notification_content.as_deref(),
            )
            .await?;
        }

        Ok(())
    }

    #[allow(clippy::too_many_arguments)]
    async fn apply_pending_updates(
        transaction: &mut Transaction<'_, Sqlite>, instance_id: &str, app_id: &str, version: i64,
        group_id: &str,
    ) -> Result<()> {
        let rows = sqlx::query_as!(
            PendingUpdateRow,
            r#"SELECT message_id, sender_id, payload, info, notification_content, href, summary, document, received_at
               FROM webxdc_pending_updates
               WHERE instance_id = ? AND group_id = ?
               ORDER BY received_at, message_id"#,
            instance_id,
            group_id
        )
        .fetch_all(&mut **transaction)
        .await?;

        for row in rows {
            if row.message_id.is_empty() || row.payload.len() > SEND_UPDATE_MAX_SIZE {
                continue;
            }

            if !Self::within_instance_budget(transaction, instance_id).await? {
                tracing::warn!("webxdc instance is over budget, dropping pending updates");

                break;
            }

            let info = sanitize(row.info.as_deref(), MAX_INFO_CHARS);

            let href = row.href.as_deref().and_then(sanitize_href);

            let summary = sanitize(row.summary.as_deref(), MAX_SUMMARY_CHARS);

            let document = sanitize(row.document.as_deref(), MAX_DOCUMENT_CHARS);

            let inserted = Self::append_update(
                transaction,
                instance_id,
                &row.message_id,
                Some(row.sender_id),
                &row.payload,
                info.as_deref(),
                href.as_deref(),
                row.received_at,
            )
            .await?;

            if !inserted {
                continue;
            }

            Self::apply_instance_labels(
                transaction,
                instance_id,
                summary.as_deref(),
                document.as_deref(),
                row.received_at,
            )
            .await?;

            if let Some(info) = info.as_deref() {
                Self::insert_info_message(
                    transaction,
                    instance_id,
                    app_id,
                    version,
                    group_id,
                    &row.message_id,
                    Some(row.sender_id),
                    info,
                    row.received_at,
                    row.notification_content.as_deref(),
                )
                .await?;
            }
        }

        sqlx::query!(
            "DELETE FROM webxdc_pending_updates WHERE instance_id = ? AND group_id = ?",
            instance_id,
            group_id
        )
        .execute(&mut **transaction)
        .await?;

        Ok(())
    }

    /// Records the latest activity behind the instance's single timeline card.
    ///
    /// An app announces things a person is meant to read -- "a new game
    /// started", "it is your turn". The update carrying it is state rather than
    /// a message and stays hidden, so the announcement is materialised here
    /// instead as internal receipt state. `chat_messages` projects its sender
    /// and read/delivery state onto the original card and hides the info row.
    /// It replaces the previous activity and moves the card in the timeline.
    ///
    /// Both devices build the row out of the update they already have, so
    /// nothing extra is sent, and the id derived from the update's own message
    /// id makes a redelivery a no-op rather than a second announcement.
    #[allow(clippy::too_many_arguments)]
    async fn insert_info_message(
        transaction: &mut Transaction<'_, Sqlite>, instance_id: &str, app_id: &str, version: i64,
        group_id: &str, update_message_id: &str, sender_id: Option<i64>, info: &str,
        created_at: i64, notification_content: Option<&str>,
    ) -> Result<()> {
        let latest: Option<String> = sqlx::query_scalar!(
            "SELECT message_id FROM webxdc_updates
             WHERE instance_id = ? AND info IS NOT NULL
             ORDER BY received_at DESC, serial DESC LIMIT 1",
            instance_id
        )
        .fetch_optional(&mut **transaction)
        .await?;

        if latest.as_deref() != Some(update_message_id) {
            return Ok(());
        }

        // Only generated info rows are replaced. User-sent app text and the
        // complete update log remain, as do undelivered game receipts.
        sqlx::query!(
            "DELETE FROM messages WHERE group_id = ? AND message_id IN (
                SELECT message_id || '-info' FROM webxdc_updates
                WHERE instance_id = ? AND message_id != ?
            )",
            group_id,
            instance_id,
            update_message_id
        )
        .execute(&mut **transaction)
        .await?;

        sqlx::query!(
            "UPDATE messages SET created_at = MAX(created_at, ?)
             WHERE message_id = ? AND group_id = ? AND type = 'webxdcApp'",
            created_at,
            instance_id,
            group_id
        )
        .execute(&mut **transaction)
        .await?;

        let origin = proto::AdditionalMessageData {
            r#type: proto::additional_message_data::Type::WebxdcSent as i32,
            webxdc_origin: Some(proto::WebxdcOrigin {
                instance_id: instance_id.to_owned(),
                app_id: app_id.to_owned(),
                version,
                notification_content: notification_content.map(str::to_owned),
            }),
            ..Default::default()
        };

        let origin = prost::Message::encode_to_vec(&origin);

        NewMessage::builder()
            .group_id(group_id)
            .message_id(&Self::info_message_id(update_message_id))
            .message_type(MessageType::Text)
            .content(info)
            .maybe_sender_id(sender_id)
            .additional_message_data(&origin)
            .created_at(created_at)
            // Incoming updates have already arrived. Outgoing announcements
            // wait for their update's transport receipt to be acknowledged.
            .maybe_ack_by_server(sender_id.map(|_| created_at))
            .build()
            .insert(transaction)
            .await
    }

    /// The id of the chat row an update's `info` becomes.
    pub(crate) fn info_message_id(update_message_id: &str) -> String {
        format!("{update_message_id}-info")
    }

    /// Assigns the next local serial and stores the entry.
    ///
    /// Serials are per instance, gap free and never reused, which is exactly
    /// what `setUpdateListener` promises the app. They are local: two devices
    /// number the same update differently, and neither ever sends its numbering
    /// to the other.
    #[allow(clippy::too_many_arguments)]
    async fn append_update(
        transaction: &mut Transaction<'_, Sqlite>, instance_id: &str, message_id: &str,
        sender_id: Option<i64>, payload: &str, info: Option<&str>, href: Option<&str>,
        received_at: i64,
    ) -> Result<bool> {
        let next_serial: i64 = sqlx::query_scalar!(
            r#"SELECT COALESCE(MAX(serial), 0) + 1 AS "next!: i64"
               FROM webxdc_updates WHERE instance_id = ?"#,
            instance_id,
        )
        .fetch_one(&mut **transaction)
        .await?;

        // `message_id` is unique, so a redelivered message is a no-op rather
        // than a duplicated move.
        let inserted = sqlx::query!(
            r#"INSERT INTO webxdc_updates
                   (instance_id, serial, message_id, sender_id, payload, info, href, received_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)
               ON CONFLICT(message_id) DO NOTHING"#,
            instance_id,
            next_serial,
            message_id,
            sender_id,
            payload,
            info,
            href,
            received_at,
        )
        .execute(&mut **transaction)
        .await?;

        Ok(inserted.rows_affected() > 0)
    }

    async fn apply_instance_labels(
        transaction: &mut Transaction<'_, Sqlite>, instance_id: &str, summary: Option<&str>,
        document: Option<&str>, received_at: i64,
    ) -> Result<()> {
        sqlx::query!(
            r#"UPDATE webxdc_instances
               SET summary = COALESCE(?, summary),
                   document = COALESCE(?, document),
                   last_update_at = ?
               WHERE instance_id = ? AND ? >= COALESCE((
                   SELECT MAX(received_at) FROM webxdc_updates WHERE instance_id = ?
               ), ?)"#,
            summary,
            document,
            received_at,
            instance_id,
            received_at,
            instance_id,
            received_at,
        )
        .execute(&mut **transaction)
        .await?;

        Ok(())
    }

    async fn within_instance_budget(
        transaction: &mut Transaction<'_, Sqlite>, instance_id: &str,
    ) -> Result<bool> {
        let row = sqlx::query!(
            r#"SELECT COUNT(*) AS "count!: i64",
                      COALESCE(SUM(LENGTH(payload)), 0) AS "bytes!: i64"
               FROM webxdc_updates WHERE instance_id = ?"#,
            instance_id,
        )
        .fetch_one(&mut **transaction)
        .await?;

        Ok(row.count < MAX_UPDATES_PER_INSTANCE && row.bytes < MAX_PAYLOAD_BYTES_PER_INSTANCE)
    }

    /// Sends an update the running app produced.
    ///
    /// Everything crossing the bridge from the webview is checked here rather
    /// than in `webxdc.js`, which the app can rewrite at will.
    #[allow(clippy::too_many_arguments)]
    pub async fn send_update(
        &self, instance_id: String, payload: String, info: Option<String>, href: Option<String>,
        summary: Option<String>, document: Option<String>, notify: Option<String>,
    ) -> Result<()> {
        if payload.len() > SEND_UPDATE_MAX_SIZE {
            return Err(TwonlyError::Generic(format!(
                "update of {} bytes exceeds sendUpdateMaxSize",
                payload.len()
            )));
        }

        let instance = self
            .instance(&instance_id)
            .await?
            .ok_or_else(|| TwonlyError::Generic("unknown webxdc instance".into()))?;

        let database = self.ctx.app_db.read().await.clone();

        let now = chrono::Utc::now().timestamp();

        let minute_ago = now - 60;

        let recent: i64 = sqlx::query_scalar!(
            r#"SELECT COUNT(*) AS "count!: i64" FROM webxdc_updates
               WHERE instance_id = ? AND sender_id IS NULL AND received_at > ?"#,
            instance_id,
            minute_ago,
        )
        .fetch_one(&database.pool)
        .await?;

        if recent >= MAX_UPDATES_PER_MINUTE {
            return Err(TwonlyError::Generic(
                "this app is sending updates too quickly".into(),
            ));
        }

        let notify = if let Some(raw) = notify {
            if raw.len() > SEND_UPDATE_MAX_SIZE {
                return Err(TwonlyError::Generic(
                    "notification list is too large".into(),
                ));
            }

            let entries: std::collections::BTreeMap<String, AppNotification> =
                serde_json::from_str(&raw).map_err(|_| {
                    TwonlyError::Generic(
                        "notify must map member addresses to text or a game outcome".into(),
                    )
                })?;

            let members = self.members(&instance_id).await?;

            let members: serde_json::Value = serde_json::from_str(&members)?;

            let mut cleaned = std::collections::BTreeMap::new();

            for (address, notification) in entries {
                if !members["members"]
                    .as_array()
                    .unwrap()
                    .iter()
                    .any(|m| m["id"] == address)
                {
                    return Err(TwonlyError::Generic(
                        "unknown notification recipient".into(),
                    ));
                }

                match notification {
                    AppNotification::Text(text) => {
                        if let Some(text) = sanitize(Some(&text), MAX_INFO_CHARS) {
                            cleaned.insert(address, AppNotification::Text(text));
                        }
                    }
                    game @ AppNotification::Game { .. } => {
                        cleaned.insert(address, game);
                    }
                }
            }

            Some(serde_json::to_string(&cleaned)?)
        } else {
            None
        };

        let info = sanitize(info.as_deref(), MAX_INFO_CHARS);

        let href = href.as_deref().and_then(sanitize_href);

        let summary = sanitize(summary.as_deref(), MAX_SUMMARY_CHARS);

        let document = sanitize(document.as_deref(), MAX_DOCUMENT_CHARS);

        let data = proto::AdditionalMessageData {
            r#type: proto::additional_message_data::Type::WebxdcUpdate as i32,
            webxdc_update: Some(proto::WebxdcUpdate {
                instance_id: instance_id.clone(),
                payload: payload.clone(),
                info: info.clone(),
                href: href.clone(),
                summary: summary.clone(),
                document: document.clone(),
                notify,
            }),
            ..Default::default()
        };

        let message_id = uuid::Uuid::new_v4().to_string();

        let mut transaction = database.pool.begin().await?;

        Self::append_update(
            &mut transaction,
            &instance_id,
            &message_id,
            None,
            &payload,
            info.as_deref(),
            href.as_deref(),
            now,
        )
        .await?;

        Self::apply_instance_labels(
            &mut transaction,
            &instance_id,
            summary.as_deref(),
            document.as_deref(),
            now,
        )
        .await?;

        // The same row every other member of the chat builds when the update
        // reaches them, so what was announced reads the same everywhere.
        if let Some(info) = info.as_deref() {
            Self::insert_info_message(
                &mut transaction,
                &instance_id,
                &instance.app_id,
                instance.version,
                &instance.group_id,
                &message_id,
                None,
                info,
                now,
                None,
            )
            .await?;
        }

        // Persist the log, announcement and delivery receipts together. The
        // transport carries the hidden update. The receipt handlers derive its
        // announcement ID without attaching the receipt to the chat row: purging
        // a chat announcement must not cascade-delete an undelivered game move.
        crate::services::messages::MessageService::new(&self.ctx)
            .send_to_group_in_transaction(
                &mut transaction,
                instance.group_id,
                prost::Message::encode_to_vec(&proto::EncryptedContent {
                    additional_data_message: Some(
                        proto::encrypted_content::AdditionalDataMessage {
                            sender_message_id: message_id.clone(),
                            additional_message_data: Some(prost::Message::encode_to_vec(&data)),
                            timestamp: now * 1000,
                            r#type: "webxdcUpdate".into(),
                            hidden: true,
                        },
                    ),
                    ..Default::default()
                }),
                None,
                false,
            )
            .await?;

        transaction.commit().await?;

        Ok(())
    }

    pub async fn instance(&self, instance_id: &str) -> Result<Option<WebxdcInstance>> {
        let database = self.ctx.app_db.read().await.clone();

        let row = sqlx::query!(
            r#"SELECT instance_id AS "instance_id!: String", group_id AS "group_id!: String",
                      app_id AS "app_id!: String", version AS "version!: i64",
                      bundle_sha256 AS "bundle_sha256: String",
                      origin_token AS "origin_token!: String",
                      summary AS "summary: String", document AS "document: String"
               FROM webxdc_instances WHERE instance_id = ?"#,
            instance_id,
        )
        .fetch_optional(&database.pool)
        .await?;

        Ok(row.map(|row| WebxdcInstance {
            instance_id: row.instance_id,
            group_id: row.group_id,
            app_id: row.app_id,
            version: row.version,
            bundle_sha256: row.bundle_sha256,
            origin_token: row.origin_token,
            summary: row.summary,
            document: row.document,
        }))
    }

    /// Everything the app has not seen yet, in serial order.
    pub async fn updates_after(&self, instance_id: &str, serial: i64) -> Result<Vec<WebxdcUpdate>> {
        let database = self.ctx.app_db.read().await.clone();

        let rows = sqlx::query!(
            r#"SELECT serial AS "serial!: i64", payload AS "payload!: String",
                      info AS "info: String", href AS "href: String",
                      sender_id AS "sender_id: i64"
               FROM webxdc_updates
               WHERE instance_id = ? AND serial > ?
               ORDER BY serial ASC"#,
            instance_id,
            serial,
        )
        .fetch_all(&database.pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|row| WebxdcUpdate {
                serial: row.serial,
                payload: row.payload,
                info: row.info,
                href: row.href,
                sender_id: row.sender_id,
            })
            .collect())
    }

    /// Starts with local code. Only a missing bundle needs the network.
    /// Updates downloaded after a previous close are adopted here, before any
    /// files are served; an in-flight background download never changes a run.
    pub async fn prepare_bundle(&self, instance_id: &str) -> Result<std::path::PathBuf> {
        let instance = self
            .instance(instance_id)
            .await?
            .ok_or_else(|| TwonlyError::Generic("unknown webxdc instance".into()))?;

        self.ensure_chat_allowed(&instance.group_id, &instance.app_id)
            .await?;

        if let Some(path) = self.apply_cached_update(&instance, instance_id).await? {
            return Ok(path);
        }

        match self.pinned_bundle(instance_id).await {
            Ok(path) => Ok(path),
            // A release replaces every older version in the store, so a card
            // placed before it can point at one the server no longer has.
            // Starting the newest is what the next launch would do anyway.
            Err(error) => match self.adopt_newest(&instance, instance_id).await {
                Ok(Some(path)) => Ok(path),
                _ => Err(error),
            },
        }
    }

    /// Downloads the newest published version and moves the instance to it.
    /// Only for a launch whose pinned version cannot be had any more.
    async fn adopt_newest(
        &self, instance: &WebxdcInstance, instance_id: &str,
    ) -> Result<Option<std::path::PathBuf>> {
        let store = self.store();

        store.refresh_catalog().await?;

        let Some((version, sha256)) = store.newest_published(&instance.app_id).await? else {
            return Ok(None);
        };

        if version <= instance.version {
            return Ok(None);
        }

        store.ensure_bundle(&sha256).await?;

        self.apply_cached_update(instance, instance_id).await
    }

    /// Checks and downloads after the app closes, without moving its pin.
    /// The user may already have reopened it when the network finishes.
    pub async fn cache_update(&self, instance_id: &str) -> Result<()> {
        let Some(instance) = self.instance(instance_id).await? else {
            return Ok(());
        };

        let store = self.store();

        store.refresh_catalog().await?;

        if let Some((version, sha256)) = store.newest_published(&instance.app_id).await? {
            if version > instance.version {
                store.ensure_bundle(&sha256).await?;
            }
        }

        Ok(())
    }

    /// The bundle an instance is pinned to, on disk and verified.
    ///
    /// No catalog lookup and no update check: this answers every file the
    /// running app asks for, so all of them have to come out of the one bundle
    /// the app started with. Only an instance that has never run here still
    /// needs its hash resolved, which is what the fallback is for.
    pub async fn pinned_bundle(&self, instance_id: &str) -> Result<std::path::PathBuf> {
        let instance = self
            .instance(instance_id)
            .await?
            .ok_or_else(|| TwonlyError::Generic("unknown webxdc instance".into()))?;

        let store = self.store();

        let sha256 = match instance.bundle_sha256 {
            Some(sha256) => sha256,
            None => {
                let sha256 = store
                    .resolve_bundle_sha256(&instance.app_id, instance.version)
                    .await?;

                self.ensure_chat_allowed(&instance.group_id, &instance.app_id)
                    .await?;

                Self::pin(&self.ctx, instance_id, instance.version, &sha256).await?;

                sha256
            }
        };

        store.ensure_bundle(&sha256).await
    }

    /// Adopts a newer version only if its complete, verified download is on
    /// disk. Never fetch here: cached apps must open even while the server
    /// is down.
    async fn apply_cached_update(
        &self, instance: &WebxdcInstance, instance_id: &str,
    ) -> Result<Option<std::path::PathBuf>> {
        let store = self.store();

        let Some((version, sha256)) = store.newest_published(&instance.app_id).await? else {
            return Ok(None);
        };

        let path = store.bundle_path(&sha256);

        if version <= instance.version || !path.is_file() {
            return Ok(None);
        }

        Self::pin(&self.ctx, instance_id, version, &sha256).await?;

        tracing::info!(
            "webxdc {} moved from version {} to {version}",
            instance.app_id,
            instance.version
        );

        if let Some(previous) = &instance.bundle_sha256 {
            self.discard_unused_bundle(previous).await;
        }

        Ok(Some(path))
    }

    /// Deletes a bundle nothing points at any more, after an update moved the
    /// last instance off it.
    ///
    /// Bundles are content addressed and shared between instances, so the file
    /// goes only once no instance is pinned to it. Best effort: a bundle left
    /// behind costs disk space and nothing else.
    async fn discard_unused_bundle(&self, sha256: &str) {
        let database = self.ctx.app_db.read().await.clone();

        let still_pinned = sqlx::query_scalar!(
            r#"SELECT COUNT(*) AS "count!: i64" FROM webxdc_instances WHERE bundle_sha256 = ?"#,
            sha256,
        )
        .fetch_one(&database.pool)
        .await;

        if !matches!(still_pinned, Ok(0)) {
            return;
        }

        if let Err(error) = std::fs::remove_file(self.store().bundle_path(sha256)) {
            tracing::info!("the superseded webxdc bundle stayed on disk: {error}");
        }
    }

    /// Records the exact code an instance runs. Everything for the rest of this
    /// run -- the files served, the bundle verified -- follows from it.
    async fn pin(ctx: &Arc<Context>, instance_id: &str, version: i64, sha256: &str) -> Result<()> {
        let database = ctx.app_db.read().await.clone();

        sqlx::query!(
            "UPDATE webxdc_instances SET version = ?, bundle_sha256 = ? WHERE instance_id = ?",
            version,
            sha256,
            instance_id,
        )
        .execute(&database.pool)
        .await?;

        Ok(())
    }

    /// Current chat members, using the same instance-scoped IDs as selfAddr.
    pub async fn members(&self, instance_id: &str) -> Result<String> {
        let instance = self
            .instance(instance_id)
            .await?
            .ok_or_else(|| TwonlyError::Generic("unknown webxdc instance".into()))?;

        let user = crate::user_config::UserConfig::load_required_from(&self.ctx)?;

        let database = self.ctx.app_db.read().await.clone();

        // Match getContactDisplayName: nickname, profile display name, username.
        let rows: Vec<(i64, String, bool)> = sqlx::query!(
            r#"SELECT c.user_id AS "user_id!",
                      COALESCE(NULLIF(c.nick_name, ''), c.display_name, c.username) AS "name!: String",
                      c.account_deleted AS "account_deleted: bool"
               FROM group_members m JOIN contacts c ON c.user_id = m.contact_id
               WHERE m.group_id = ? AND (m.member_state IS NULL OR m.member_state != 'leftGroup')
               ORDER BY c.user_id"#,
            &instance.group_id
        )
        .map(|row| (row.user_id, row.name, row.account_deleted))
        .fetch_all(&database.pool)
        .await?;

        let self_id = Self::address_for(instance_id, user.user_id);

        let mut members =
            vec![serde_json::json!({"id": self_id, "displayName": user.display_name})];

        for (id, mut name, account_deleted) in rows {
            if id != user.user_id {
                if account_deleted {
                    name = name.chars().flat_map(|c| [c, '\u{0336}']).collect();
                }

                members.push(serde_json::json!({"id": Self::address_for(instance_id, id), "displayName": name}));
            }
        }

        Ok(serde_json::json!({"selfId": self_id, "members": members}).to_string())
    }

    /// The values `webxdc.js` is served with, as a JSON object.
    ///
    /// Produced here rather than passed in, so what the app is told about its
    /// user is decided on this side. `selfAddr` is a per-instance pseudonym;
    /// `selfName` is the display name the chat already shows.
    pub async fn init_script_values(&self, instance_id: &str) -> Result<String> {
        let display_name = crate::user_config::UserConfig::load_from(&self.ctx)?
            .map(|config| config.display_name)
            .unwrap_or_default();

        let user_id = crate::user_config::UserConfig::load_from(&self.ctx)?
            .map(|config| config.user_id)
            .unwrap_or_default();

        Ok(serde_json::json!({
            "selfAddr": Self::address_for(instance_id, user_id),
            "selfName": display_name,
            "sendUpdateInterval": SEND_UPDATE_INTERVAL_MS,
            "sendUpdateMaxSize": SEND_UPDATE_MAX_SIZE,
        })
        .to_string())
    }

    /// The address the app sees for a participant.
    ///
    /// Derived from the instance id, which every participant knows and nobody
    /// outside the chat does, so the same peer looks identical on every device
    /// while the same user in two different chats does not.
    pub fn address_for(instance_id: &str, user_id: i64) -> String {
        let mut mac = Hmac::<Sha256>::new_from_slice(instance_id.as_bytes())
            .expect("hmac accepts keys of any length");

        mac.update(&user_id.to_be_bytes());

        let digest = mac.finalize().into_bytes();

        format!("{}@twonly", hex::encode(&digest[..8]))
    }

    /// Removes an instance and everything it accumulated, returning the origin
    /// whose web storage the platform layer still has to clear. The update log
    /// is only half the state: an app is free to keep everything in
    /// `localStorage`, which no database delete can reach.
    pub async fn delete_instance(&self, instance_id: &str) -> Result<Option<String>> {
        let Some(instance) = self.instance(instance_id).await? else {
            return Ok(None);
        };

        let database = self.ctx.app_db.read().await.clone();

        let mut transaction = database.pool.begin().await?;

        // The instance deletion first removes its internal activity messages;
        // then foreign keys remove the log. This also covers deleting the card.
        sqlx::query!(
            "DELETE FROM webxdc_instances WHERE instance_id = ?",
            instance_id
        )
        .execute(&mut *transaction)
        .await?;

        transaction.commit().await?;

        Ok(Some(instance.origin_token))
    }
}

/// Strips what has no business in a chat row and bounds the length.
///
/// `info`, `summary` and `document` are written by the app and rendered outside
/// its sandbox, so they are plain text: no markup, no formatting, and no
/// direction overrides, which are otherwise enough to make a row read as
/// something it is not.
/// The announcement an update carries, bounded and stripped exactly as the
/// chat row built from it will be.
///
/// Every reader of an update's `info` goes through this, so what a device wakes
/// for, what it notifies for, and what it writes into the chat can never
/// disagree -- an app cannot buy a push with an `info` that turns out to be
/// nothing but spaces.
pub(crate) fn announcement(update: &proto::WebxdcUpdate) -> Option<String> {
    sanitize(update.info.as_deref(), MAX_INFO_CHARS)
}

fn sanitize(text: Option<&str>, max_chars: usize) -> Option<String> {
    let text = text?;

    let cleaned: String = text
        .chars()
        .filter(|c| {
            !c.is_control()
                && !matches!(
                    c,
                    '\u{200e}'..='\u{200f}' | '\u{202a}'..='\u{202e}' | '\u{2066}'..='\u{2069}'
                )
        })
        .take(max_chars)
        .collect();

    let cleaned = cleaned.trim().to_string();

    (!cleaned.is_empty()).then_some(cleaned)
}

/// `href` decides which document the app opens when a chat row is tapped, so it
/// may only ever address the app's own files.
fn sanitize_href(href: &str) -> Option<String> {
    let href = href.trim();

    if href.is_empty() || href.len() > 512 {
        return None;
    }

    // Anything that could name another origin or another scheme is refused
    // outright rather than rewritten.
    if href.starts_with("//") || href.contains(':') || href.contains('\\') || href.contains('\0') {
        return None;
    }

    let path = href.split(['?', '#']).next().unwrap_or_default();

    if path.split('/').any(|segment| segment == "..") {
        return None;
    }

    Some(href.to_string())
}

#[cfg(test)]
mod tests {

    use super::{proto, sanitize, sanitize_href, Context, Result, WebxdcService};
    use sha2::{Digest, Sha256};

    #[tokio::test]
    async fn single_game_card_tracks_the_latest_turn_without_changing_protocol_ownership(
    ) -> Result<()> {
        use crate::database::app::messages::native::Message;
        use crate::database::app::messages::queries;
        use crate::database::app::messages::table::{MessageFilter, MessageQuery};
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        crate::user_config::UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"me","displayName":"Me"}"#,
        )?;
        let database = ctx.app_db.read().await.clone();
        for statement in [
            "INSERT INTO contacts(user_id,username,signal_version) VALUES \
             (7,'alice','v2'),(8,'bob','v2')",
            "INSERT INTO groups(group_id,group_name,is_direct_chat) VALUES ('g','Games',1)",
            "INSERT INTO group_members(group_id,contact_id) VALUES ('g',7),('g',8)",
            "INSERT INTO messages(message_id,group_id,sender_id,type,created_at) VALUES \
             ('card','g',7,'webxdcApp',100)",
            "INSERT INTO messages(message_id,group_id,sender_id,type,content,created_at) VALUES \
             ('ordinary','g',7,'text','Hello',250)",
            "INSERT INTO webxdc_instances(instance_id,group_id,app_id,version,origin_token) \
             VALUES ('card','g','chess',1,'origin')",
        ] {
            sqlx::query(statement).execute(&database.pool).await?;
        }
        let page = MessageQuery {
            filter: MessageFilter::Page,
            group_id: Some("g".into()),
            ids: vec![],
            limit: 100,
            before: None,
            before_message_id: None,
            now_ms: chrono::Utc::now().timestamp_millis(),
        };
        let update = |summary: &str| proto::WebxdcUpdate {
            instance_id: "card".into(),
            payload: "{}".into(),
            info: Some("Played a move".into()),
            summary: Some(summary.into()),
            ..Default::default()
        };
        let mut tx = database.pool.begin().await?;
        WebxdcService::handle_incoming_update(
            &mut tx,
            "first",
            "g",
            8,
            &update("Alice's turn"),
            200,
            42,
        )
        .await?;
        let rows = queries::list(&mut tx, &page).await?;
        assert_eq!(
            rows.iter()
                .map(|row| row.message_id.as_str())
                .collect::<Vec<_>>(),
            ["card", "ordinary"]
        );
        assert_eq!(rows[0].r#type, "webxdcApp");
        assert_eq!(rows[0].content.as_deref(), Some("Played a move"));
        assert_eq!(rows[0].sender_id, Some(8));
        assert_eq!(rows[0].created_at, 200);
        assert!(queries::get(&mut tx, "first-info").await?.is_none());
        tx.commit().await?;

        // Exercise the real local publishing path: the same original card
        // moves after the ordinary chat message and changes to the right side.
        let service = WebxdcService::new(&ctx);
        service
            .send_update(
                "card".into(),
                "{}".into(),
                Some("My move".into()),
                None,
                Some("Bob's turn".into()),
                None,
                Some("{}".into()),
            )
            .await?;
        let mut tx = database.pool.begin().await?;
        let rows = queries::list(&mut tx, &page).await?;
        assert_eq!(
            rows.iter()
                .map(|row| row.message_id.as_str())
                .collect::<Vec<_>>(),
            ["ordinary", "card"]
        );
        assert_eq!(rows[1].sender_id, None);
        assert_eq!(rows[1].content.as_deref(), Some("My move"));
        let mine = rows[1].created_at;
        let raw_sender: Option<i64> =
            sqlx::query_scalar("SELECT sender_id FROM messages WHERE message_id = 'card'")
                .fetch_one(&mut *tx)
                .await?;
        assert_eq!(
            raw_sender,
            Some(7),
            "the immutable creator still owns the original transport message"
        );
        Message::check_message_owner(&mut tx, "card", 7).await?;

        let receipt: String =
            sqlx::query_scalar("SELECT receipt_id FROM receipts WHERE contact_id = 7")
                .fetch_one(&mut *tx)
                .await?;
        crate::api::messages::incoming::messages::handle_sender_delivery_receipt(
            &mut tx, 7, &receipt,
        )
        .await?;
        let actions = queries::delivery_actions(&mut tx, &["card".into()]).await?;
        assert_eq!(actions.len(), 1);
        assert_eq!(actions[0].message_id, "card");
        assert_eq!(actions[0].r#type, "ackByUserAt");
        assert!(queries::get(&mut tx, "card")
            .await?
            .unwrap()
            .ack_by_server
            .is_some());

        WebxdcService::handle_incoming_update(
            &mut tx,
            "reply",
            "g",
            8,
            &update("My turn"),
            mine + 2,
            42,
        )
        .await?;
        assert_eq!(
            queries::get(&mut tx, "card").await?.unwrap().sender_id,
            Some(8)
        );
        let read_targets = queries::opened_targets(&mut tx, &["card".into()], 8).await?;
        assert_eq!(read_targets, ["reply-info"]);
        assert!(queries::opened_targets(&mut tx, &["card".into()], 7)
            .await?
            .is_empty());
        sqlx::query("UPDATE messages SET opened_at = ? WHERE message_id = ?")
            .bind(mine + 3)
            .bind(&read_targets[0])
            .execute(&mut *tx)
            .await?;
        assert_eq!(
            queries::get(&mut tx, "card").await?.unwrap().opened_at,
            Some(mine + 3)
        );
        let latest = queries::list(
            &mut tx,
            &MessageQuery {
                filter: MessageFilter::LatestByGroup,
                ..page.clone()
            },
        )
        .await?;
        assert_eq!(
            latest[0].message_id, "card",
            "reading a game must not remove its latest-chat preview"
        );

        WebxdcService::handle_incoming_update(
            &mut tx,
            "newest",
            "g",
            7,
            &update("Newest turn"),
            mine + 4,
            42,
        )
        .await?;
        // An old read receipt, an out-of-order move, and a duplicate cannot
        // change the current turn, subtitle, position or unread state.
        Message::record_opened(&mut tx, &read_targets[0], 8, mine + 5).await?;
        WebxdcService::handle_incoming_update(
            &mut tx,
            "late",
            "g",
            8,
            &update("Stale subtitle"),
            mine - 1,
            42,
        )
        .await?;
        WebxdcService::handle_incoming_update(
            &mut tx,
            "newest",
            "g",
            8,
            &update("Duplicate subtitle"),
            mine + 8,
            42,
        )
        .await?;
        let before_same_second = queries::get(&mut tx, "card").await?.unwrap();
        WebxdcService::handle_incoming_update(
            &mut tx,
            "same-second",
            "g",
            7,
            &update("Newest turn"),
            mine + 4,
            42,
        )
        .await?;
        let current = queries::get(&mut tx, "card").await?.unwrap();
        assert_eq!(current.created_at, before_same_second.created_at);
        assert_ne!(
            current.activity_message_id,
            before_same_second.activity_message_id
        );
        assert_eq!(
            current.activity_message_id.as_deref(),
            Some("same-second-info")
        );
        assert!(
            queries::opened_targets(
                &mut tx,
                &[before_same_second.activity_message_id.unwrap()],
                7,
            )
            .await?
            .is_empty(),
            "an earlier move's read report cannot open a later turn"
        );
        assert_eq!(current.sender_id, Some(7));
        assert_eq!(current.original_sender_id, Some(7));
        assert_eq!(current.created_at, mine + 4);
        assert_eq!(current.opened_at, None);
        let summary: String =
            sqlx::query_scalar("SELECT summary FROM webxdc_instances WHERE instance_id = 'card'")
                .fetch_one(&mut *tx)
                .await?;
        assert_eq!(summary, "Newest turn");
        let before = queries::list(
            &mut tx,
            &MessageQuery {
                before: Some(mine + 4),
                before_message_id: Some("card".into()),
                ..page.clone()
            },
        )
        .await?;
        assert_eq!(
            before
                .iter()
                .map(|row| row.message_id.as_str())
                .collect::<Vec<_>>(),
            ["ordinary"]
        );
        tx.commit().await?;
        let mut tx = database.pool.begin().await?;
        WebxdcService::handle_incoming_update(
            &mut tx,
            "rolled-back",
            "g",
            8,
            &update("Rolled back"),
            mine + 6,
            42,
        )
        .await?;
        tx.rollback().await?;
        let rows = queries::list(&mut *database.read_pool.acquire().await?, &page).await?;
        assert_eq!(rows.len(), 2);
        assert_eq!(rows[1], current);

        let mut tx = database.pool.begin().await?;
        sqlx::query("DELETE FROM messages WHERE message_id = 'card'")
            .execute(&mut *tx)
            .await?;
        let remaining = queries::list(&mut tx, &page).await?;
        assert_eq!(
            remaining
                .iter()
                .map(|row| row.message_id.as_str())
                .collect::<Vec<_>>(),
            ["ordinary"]
        );
        assert_eq!(
            sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM messages WHERE message_id LIKE '%-info'"
            )
            .fetch_one(&mut *tx)
            .await?,
            0,
            "deleting a card must not reveal orphan move text"
        );
        tx.rollback().await?;
        assert_eq!(
            service.delete_instance("card").await?.as_deref(),
            Some("origin")
        );
        assert_eq!(
            sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM messages WHERE message_id LIKE '%-info'"
            )
            .fetch_one(&database.pool)
            .await?,
            0
        );
        Ok(())
    }

    #[test]
    fn game_notification_outcomes_are_closed_and_legacy_text_is_preserved() {
        for outcome in ["turn", "won", "lost"] {
            let value = serde_json::json!({"game": outcome});
            let notification: super::AppNotification =
                serde_json::from_value(value.clone()).unwrap();
            assert_eq!(serde_json::to_value(notification).unwrap(), value);
        }
        for value in [
            serde_json::json!({"game":"draw"}),
            serde_json::json!({"game":"turn","text":"injected"}),
            serde_json::json!(null),
        ] {
            assert!(serde_json::from_value::<super::AppNotification>(value).is_err());
        }
        let text = serde_json::json!("Dinner added");
        let notification: super::AppNotification = serde_json::from_value(text.clone()).unwrap();
        assert_eq!(serde_json::to_value(notification).unwrap(), text);
    }

    #[tokio::test]

    async fn upgrading_compacts_existing_game_announcements_without_losing_moves() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let database = ctx.app_db.read().await.clone();

        sqlx::raw_sql(
            "INSERT INTO groups(group_id, group_name) VALUES ('g', 'Games');
             INSERT INTO messages(message_id, group_id, type, content, created_at)
             VALUES ('card', 'g', 'webxdcApp', NULL, 100),
                    ('first-info', 'g', 'text', 'First move', 200),
                    ('last-info', 'g', 'text', 'Last move', 300),
                    ('shared', 'g', 'text', 'Shared text', 250);
             INSERT INTO webxdc_instances(instance_id, group_id, app_id, version, origin_token)
             VALUES ('card', 'g', 'chess', 1, 'origin');
             INSERT INTO webxdc_updates(instance_id, serial, message_id, payload, info, \
             received_at)
             VALUES ('card', 1, 'first', '{}', 'First move', 200),
                    ('card', 2, 'last', '{}', 'Last move', 300);
             DROP INDEX idx_webxdc_updates_announcements;",
        )
        .execute(&database.pool)
        .await?;

        sqlx::raw_sql(include_str!(
            "../../database/app/migrations/0042_webxdc_latest_announcement.sql"
        ))
        .execute(&database.pool)
        .await?;

        let ids: Vec<String> =
            sqlx::query_scalar("SELECT message_id FROM messages ORDER BY message_id")
                .fetch_all(&database.pool)
                .await?;

        assert_eq!(ids, ["card", "last-info", "shared"]);

        // Upgrade an existing two-row conversation without dropping its game
        // log or the hidden row that outstanding receipts still refer to.
        sqlx::raw_sql("DROP VIEW chat_messages; DROP TRIGGER webxdc_activity_cleanup;")
            .execute(&database.pool)
            .await?;
        sqlx::raw_sql(include_str!(
            "../../database/app/migrations/0048_webxdc_single_timeline_card.sql"
        ))
        .execute(&database.pool)
        .await?;
        let visible: Vec<String> = sqlx::query_scalar(
            "SELECT message_id FROM chat_messages ORDER BY created_at, message_id",
        )
        .fetch_all(&database.pool)
        .await?;
        assert_eq!(visible, ["shared", "card"]);

        let card_at: i64 =
            sqlx::query_scalar("SELECT created_at FROM messages WHERE message_id = 'card'")
                .fetch_one(&database.pool)
                .await?;

        assert_eq!(card_at, 300);

        let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM webxdc_updates")
            .fetch_one(&database.pool)
            .await?;

        assert_eq!(count, 2);

        Ok(())
    }

    #[tokio::test]

    async fn direct_chat_only_apps_cannot_be_created_or_started_in_groups() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let database = ctx.app_db.read().await.clone();

        sqlx::raw_sql(
            "INSERT INTO groups(group_id, group_name, is_direct_chat)
             VALUES ('direct', 'Alice', 1), ('group', 'Friends', 0);
             INSERT INTO webxdc_apps(app_id, version, name, bundle_sha256, bundle_bytes, \
             cached_at, direct_chat_only)
             VALUES ('chess', 1, 'Chess', 'hash', 10, 0, 1);
             INSERT INTO messages(message_id, group_id, type) VALUES ('card', 'group', \
             'webxdcApp');
             INSERT INTO webxdc_instances(instance_id, group_id, app_id, version, origin_token)
             VALUES ('card', 'group', 'chess', 1, 'origin');",
        )
        .execute(&database.pool)
        .await?;

        let service = WebxdcService::new(&ctx);

        service.ensure_chat_allowed("direct", "chess").await?;

        assert!(service.ensure_chat_allowed("group", "chess").await.is_err());

        assert!(service
            .create_instance("group".into(), "chess".into(), 1)
            .await
            .is_err());

        assert!(service.prepare_bundle("card").await.is_err());

        let cards: i64 =
            sqlx::query_scalar("SELECT COUNT(*) FROM messages WHERE type = 'webxdcApp'")
                .fetch_one(&database.pool)
                .await?;

        assert_eq!(
            cards, 1,
            "rejected placement leaves no card or outgoing message"
        );

        sqlx::query("UPDATE webxdc_apps SET direct_chat_only = 0")
            .execute(&database.pool)
            .await?;

        service.ensure_chat_allowed("group", "chess").await?;

        Ok(())
    }

    #[tokio::test]

    async fn game_announcements_replace_only_the_same_instances_automatic_text() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let database = ctx.app_db.read().await.clone();

        sqlx::raw_sql(
            "INSERT INTO contacts(user_id, username) VALUES (7, 'sender');
             INSERT INTO groups(group_id, group_name) VALUES ('g', 'Games');
             INSERT INTO messages(message_id, group_id, type, created_at)
             VALUES ('card', 'g', 'webxdcApp', 100), ('other-card', 'g', 'webxdcApp', 100),
                    ('person', 'g', 'text', 250);
             INSERT INTO webxdc_instances(instance_id, group_id, app_id, version, origin_token, \
             created_at)
             VALUES ('card', 'g', 'chess', 1, 'origin', 100),
                    ('other-card', 'g', 'chess', 1, 'other-origin', 100);",
        )
        .execute(&database.pool)
        .await?;

        let mut tx = database.pool.begin().await?;

        for (id, instance, info, at) in [
            ("move-1", "card", Some("Alice played"), 200),
            ("other-move", "other-card", Some("Bob played"), 260),
            ("move-2", "card", Some("Ben played"), 300),
            ("late-move", "card", Some("Older move"), 150),
            ("move-1", "card", Some("Alice played"), 200),
            ("silent", "card", None, 400),
        ] {
            WebxdcService::handle_incoming_update(
                &mut tx,
                id,
                "g",
                7,
                &proto::WebxdcUpdate {
                    instance_id: instance.into(),
                    payload: "{}".into(),
                    info: info.map(str::to_owned),
                    ..Default::default()
                },
                at,
                42,
            )
            .await?;

            if id == "move-1" && at == 200 {
                sqlx::query(
                    "INSERT OR IGNORE INTO notification_outbox(event_id, notification_id, \
                     conversation_id, sender_id, message_id, kind, created_at) VALUES ('first', \
                     'move-1', 'g', 7, 'move-1-info', 'webxdc', 200)",
                )
                .execute(&mut *tx)
                .await?;
            }
        }

        let messages: Vec<(String, Option<String>, i64)> = sqlx::query_as(
            "SELECT message_id, content, created_at FROM messages ORDER BY created_at, message_id",
        )
        .fetch_all(&mut *tx)
        .await?;

        assert_eq!(
            messages
                .iter()
                .map(|row| row.0.as_str())
                .collect::<Vec<_>>(),
            [
                "person",
                "other-card",
                "other-move-info",
                "card",
                "move-2-info"
            ]
        );

        assert_eq!(messages.last().unwrap().1.as_deref(), Some("Ben played"));

        assert_eq!(
            messages[3].2, 300,
            "silent, late and replayed updates do not move the card"
        );

        let updates: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM webxdc_updates")
            .fetch_one(&mut *tx)
            .await?;

        assert_eq!(
            updates, 5,
            "the full game history is retained without duplicate moves"
        );

        let cleared: Option<i64> = sqlx::query_scalar(
            "SELECT cleared_at FROM notification_outbox WHERE event_id = 'first'",
        )
        .fetch_one(&mut *tx)
        .await?;

        assert!(
            cleared.is_some(),
            "superseded announcements no longer count towards the badge"
        );

        tx.commit().await?;

        Ok(())
    }

    #[tokio::test]

    async fn incoming_game_announcements_lift_the_chat_but_silent_updates_do_not() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let database = ctx.app_db.read().await.clone();

        sqlx::raw_sql(
            "INSERT INTO contacts(user_id, username) VALUES (7, 'sender');
             INSERT INTO groups(group_id, group_name, last_message_exchange) VALUES ('g', 'Games', \
             100);
             INSERT INTO messages(message_id, group_id, type, created_at) VALUES ('card', 'g', \
             'webxdcApp', 100);
             INSERT INTO webxdc_instances(instance_id, group_id, app_id, version, origin_token)
             VALUES ('card', 'g', 'connect4', 3, 'origin');",
        )
        .execute(&database.pool)
        .await?;

        for (message_id, info, timestamp, expected_activity) in [
            ("silent", None, 200, 100),
            ("move", Some("Your turn"), 300, 300),
            ("silent-again", None, 400, 300),
        ] {
            let mut tx = database.pool.begin().await?;

            WebxdcService::handle_incoming_update(
                &mut tx,
                message_id,
                "g",
                7,
                &proto::WebxdcUpdate {
                    instance_id: "card".into(),
                    payload: "{}".into(),
                    info: info.map(str::to_owned),
                    ..Default::default()
                },
                timestamp,
                42,
            )
            .await?;

            tx.commit().await?;

            let activity: i64 =
                sqlx::query_scalar("SELECT last_message_exchange FROM groups WHERE group_id = 'g'")
                    .fetch_one(&database.pool)
                    .await?;

            assert_eq!(activity, expected_activity);
        }

        Ok(())
    }

    #[tokio::test]

    async fn outgoing_announcements_track_delivery_without_owning_the_game_outbox() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        crate::user_config::UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"anna","displayName":"Anna"}"#,
        )?;

        let database = ctx.app_db.read().await.clone();

        for statement in [
            "INSERT INTO contacts(user_id, username, signal_version) VALUES (7, 'ben', 'v2')",
            "INSERT INTO groups(group_id, group_name, last_message_exchange) VALUES ('g', \
             'Games', 100)",
            "INSERT INTO group_members(group_id, contact_id) VALUES ('g', 7)",
            "INSERT INTO messages(message_id, group_id, type, created_at) VALUES ('card', 'g', \
             'webxdcApp', 100)",
            "INSERT INTO webxdc_instances(instance_id, group_id, app_id, version, origin_token) \
             VALUES ('card', 'g', 'connect4', 3, 'origin')",
        ] {
            sqlx::query(statement).execute(&database.pool).await?;
        }

        let service = WebxdcService::new(&ctx);

        let notify =
            serde_json::json!({WebxdcService::address_for("card", 7): {"game":"turn"}}).to_string();

        for (info, delete_announcement) in [
            (Some("Ben's turn"), false),
            (Some("Ben's turn"), true),
            (None, false),
        ] {
            sqlx::query("UPDATE groups SET last_message_exchange = 100 WHERE group_id = 'g'")
                .execute(&database.pool)
                .await?;

            let sent_at = chrono::Utc::now().timestamp();

            tokio::time::timeout(
                std::time::Duration::from_secs(1),
                service.send_update(
                    "card".into(),
                    "{}".into(),
                    info.map(str::to_owned),
                    None,
                    None,
                    None,
                    Some(notify.clone()),
                ),
            )
            .await
            .expect("queuing a game move waited for the network")?;

            let last_exchange: i64 =
                sqlx::query_scalar("SELECT last_message_exchange FROM groups WHERE group_id = 'g'")
                    .fetch_one(&database.pool)
                    .await?;

            if info.is_some() {
                assert!(last_exchange >= sent_at, "visible game moves lift the chat");
            } else {
                assert_eq!(last_exchange, 100, "silent updates leave chat order alone");
            }

            let update_id: String = sqlx::query_scalar(
                "SELECT message_id FROM webxdc_updates WHERE instance_id = 'card' ORDER BY serial \
                 DESC LIMIT 1",
            )
            .fetch_one(&database.pool)
            .await?;

            let info_id = WebxdcService::info_message_id(&update_id);

            let (receipt_id, attached_id, wake, message): (String, Option<String>, i64, Vec<u8>) =
                sqlx::query_as(
                    "SELECT receipt_id, message_id, wake_receiver, message FROM receipts WHERE \
                     contact_id = 7",
                )
                .fetch_one(&database.pool)
                .await?;

            assert_eq!(
                attached_id, None,
                "purging chat info must not delete the move"
            );

            assert_eq!(wake, i64::from(info.is_some()));

            let envelope = <proto::Message as prost::Message>::decode(message.as_slice())?;

            let content = <proto::EncryptedContent as prost::Message>::decode(
                envelope.encrypted_content.unwrap().as_slice(),
            )?;

            let outgoing = content.additional_data_message.unwrap();

            assert!(outgoing.hidden);

            assert_eq!(outgoing.sender_message_id, update_id);

            assert_eq!(content.group_id.as_deref(), Some("g"));

            if info.is_some() {
                let ack: Option<i64> =
                    sqlx::query_scalar("SELECT ack_by_server FROM messages WHERE message_id = ?")
                        .bind(&info_id)
                        .fetch_one(&database.pool)
                        .await?;

                assert_eq!(ack, None, "a queued move is not yet acknowledged");
            }

            let mut tx = database.pool.begin().await?;

            if delete_announcement {
                sqlx::query("DELETE FROM messages WHERE message_id = ?")
                    .bind(&info_id)
                    .execute(&mut *tx)
                    .await?;

                let exists: bool = sqlx::query_scalar(
                    "SELECT EXISTS(SELECT 1 FROM receipts WHERE receipt_id = ?)",
                )
                .bind(&receipt_id)
                .fetch_one(&mut *tx)
                .await?;

                assert!(exists);
            }

            crate::api::messages::incoming::messages::handle_sender_delivery_receipt(
                &mut tx,
                7,
                &receipt_id,
            )
            .await?;

            let actions: i64 = sqlx::query_scalar(
                "SELECT COUNT(*) FROM message_actions WHERE message_id = ? AND contact_id = 7 AND \
                 type = 'ackByUserAt'",
            )
            .bind(&info_id)
            .fetch_one(&mut *tx)
            .await?;

            assert_eq!(actions, i64::from(info.is_some() && !delete_announcement));

            tx.commit().await?;
        }

        Ok(())
    }

    #[tokio::test]

    async fn sync_chunks_install_one_time_app_only_when_complete() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let database = ctx.app_db.read().await.clone();

        for statement in [
            "INSERT INTO contacts(user_id, username) VALUES (7, 'sender')",
            "INSERT INTO groups(group_id, group_name) VALUES ('g', 'Chat')",
            "INSERT INTO group_members(group_id, contact_id) VALUES ('g', 7)",
        ] {
            sqlx::query(statement).execute(&database.pool).await?;
        }

        let payload = proto::WebxdcSyncPayload {
            instances: vec![proto::WebxdcSyncInstance {
                instance_id: "card".into(),
                app_id: "expenses".into(),
                version: 1,
                summary: Some("Trip".into()),
                document: Some("3 expenses".into()),
                created_at: 100,
                last_update_at: 200,
                updates: vec![proto::WebxdcSyncUpdate {
                    message_id: "update".into(),
                    sender_id: Some(7),
                    payload: r#"{"expense":1}"#.into(),
                    info: Some("Dinner".into()),
                    href: None,
                    received_at: 150,
                }],
            }],
        };

        let encoded = prost::Message::encode_to_vec(&payload);

        let split = encoded.len() / 2;

        let digest = Sha256::digest(&encoded).to_vec();

        let chunks = [
            proto::WebxdcSyncChunk {
                transfer_id: "transfer".into(),
                chunk_index: 0,
                chunk_count: 2,
                payload_sha256: digest.clone(),
                payload: encoded[..split].to_vec(),
            },
            proto::WebxdcSyncChunk {
                transfer_id: "transfer".into(),
                chunk_index: 1,
                chunk_count: 2,
                payload_sha256: digest,
                payload: encoded[split..].to_vec(),
            },
        ];

        let mut transaction = database.pool.begin().await?;

        WebxdcService::handle_incoming_update(
            &mut transaction,
            "live-update",
            "g",
            7,
            &proto::WebxdcUpdate {
                instance_id: "card".into(),
                payload: r#"{"expense":2}"#.into(),
                info: Some("Taxi".into()),
                href: None,
                summary: Some("Trip updated".into()),
                document: Some("2 expenses".into()),
                notify: Some(serde_json::json!({WebxdcService::address_for("card", 42): "Your expense was added"}).to_string()),
            },
            250,
            42,
        )
        .await?;

        WebxdcService::handle_sync_chunk(&mut transaction, "g", 7, &chunks[1]).await?;

        let before: i64 =
            sqlx::query_scalar("SELECT COUNT(*) FROM webxdc_instances WHERE instance_id = 'card'")
                .fetch_one(&mut *transaction)
                .await?;

        assert_eq!(before, 0);

        WebxdcService::handle_sync_chunk(&mut transaction, "g", 7, &chunks[0]).await?;

        transaction.commit().await?;

        let instance = WebxdcService::new(&ctx).instance("card").await?.unwrap();

        assert_eq!(instance.app_id, "expenses");

        assert_eq!(instance.summary.as_deref(), Some("Trip updated"));

        assert_eq!(instance.document.as_deref(), Some("2 expenses"));

        let updates = WebxdcService::new(&ctx).updates_after("card", 0).await?;

        assert_eq!(updates.len(), 2);

        assert_eq!(updates[0].payload, r#"{"expense":1}"#);

        assert_eq!(updates[1].payload, r#"{"expense":2}"#);

        let pending: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM webxdc_pending_updates")
            .fetch_one(&database.pool)
            .await?;

        assert_eq!(pending, 0);

        let announcements: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM messages WHERE message_id = 'live-update-info'",
        )
        .fetch_one(&database.pool)
        .await?;

        assert_eq!(announcements, 1);
        let card = crate::database::app::messages::queries::get(
            &mut *database.read_pool.acquire().await?,
            "card",
        )
        .await?
        .unwrap();
        let origin = <proto::AdditionalMessageData as prost::Message>::decode(
            card.additional_message_data.as_deref().unwrap(),
        )?
        .webxdc_origin
        .unwrap();
        assert_eq!(
            origin.notification_content.as_deref(),
            Some("Your expense was added")
        );
        assert_eq!(updates[1].info.as_deref(), Some("Taxi"));

        Ok(())
    }

    #[tokio::test]

    async fn one_time_app_refuses_another_instance_in_the_same_chat() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let database = ctx.app_db.read().await.clone();

        for statement in [
            "INSERT INTO groups(group_id, group_name) VALUES ('g', 'Chat'), ('other', 'Other')",
            "INSERT INTO messages(message_id, group_id, type) VALUES ('card', 'g', 'webxdcApp')",
            "INSERT INTO webxdc_apps(app_id, version, name, bundle_sha256, bundle_bytes, \
             cached_at, published, one_time) VALUES ('expenses', 1, 'Expenses', 'hash', 10, 0, 1, \
             1)",
            "INSERT INTO webxdc_instances(instance_id, group_id, app_id, version, origin_token) \
             VALUES ('card', 'g', 'expenses', 1, 'origin')",
        ] {
            sqlx::query(statement).execute(&database.pool).await?;
        }

        let service = WebxdcService::new(&ctx);

        assert_eq!(
            service
                .existing_instance_if_limited("g", "expenses", 1)
                .await?
                .as_deref(),
            Some("card")
        );

        assert_eq!(
            service
                .existing_instance_if_limited("other", "expenses", 1)
                .await?,
            None
        );

        Ok(())
    }

    #[tokio::test]

    async fn cached_launch_never_waits_for_updates_and_pins_only_between_runs() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let database = ctx.app_db.read().await.clone();

        for statement in [
            "INSERT INTO groups(group_id, group_name) VALUES ('g', 'Chat')",
            "INSERT INTO messages(message_id, group_id, type) VALUES ('card', 'g', 'webxdcApp')",
            "INSERT INTO webxdc_instances(instance_id, group_id, app_id, version, origin_token, \
             bundle_sha256) VALUES ('card', 'g', 'expenses', 1, 'origin', 'old-hash')",
            "INSERT INTO webxdc_apps(app_id, version, name, bundle_sha256, bundle_bytes, \
             cached_at, published) VALUES ('expenses', 2, 'Expenses', 'new-hash', 10, 0, 1)",
        ] {
            sqlx::query(statement).execute(&database.pool).await?;
        }

        let service = WebxdcService::new(&ctx);

        let old = service.store().bundle_path("old-hash");

        let new = service.store().bundle_path("new-hash");

        std::fs::create_dir_all(old.parent().unwrap())?;

        std::fs::write(&old, b"previously downloaded code")?;

        // A newer catalog row and an unfinished download cannot block launch.
        std::fs::write(new.with_extension("partial"), b"unfinished")?;

        let path = tokio::time::timeout(
            std::time::Duration::from_millis(500),
            service.prepare_bundle("card"),
        )
        .await
        .expect("cached launch attempted a network request")?;

        assert_eq!(path, old);

        assert_eq!(service.instance("card").await?.unwrap().version, 1);

        // Simulate a background download finishing after the user reopened.
        std::fs::write(&new, b"new downloaded code")?;

        assert_eq!(service.pinned_bundle("card").await?, old);

        assert_eq!(service.instance("card").await?.unwrap().version, 1);

        // Only the next launch adopts the already downloaded update.
        assert_eq!(service.prepare_bundle("card").await?, new);

        assert_eq!(service.instance("card").await?.unwrap().version, 2);

        assert!(!old.exists());

        Ok(())
    }

    #[tokio::test]

    async fn member_api_is_scoped_and_excludes_departed_members() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        crate::user_config::UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"anna","displayName":"Anna"}"#,
        )?;

        let database = ctx.app_db.read().await.clone();

        for statement in [
            "INSERT INTO contacts(user_id, username, display_name, nick_name) VALUES (7, 'ben', \
             'Ben', 'Benny'), (8, 'clara', 'Clara', NULL), (9, 'dan', 'Dan', NULL)",
            "INSERT INTO groups(group_id, group_name) VALUES ('g', 'Trip'), ('other', 'Other')",
            "INSERT INTO group_members(group_id, contact_id, member_state) VALUES ('g', 7, NULL), \
             ('g', 8, 'leftGroup'), ('other', 9, NULL)",
            "INSERT INTO messages(message_id, group_id, type) VALUES ('card', 'g', 'webxdcApp')",
            "INSERT INTO webxdc_instances(instance_id, group_id, app_id, version, origin_token) \
             VALUES ('card', 'g', 'expenses', 1, 'origin')",
        ] {
            sqlx::query(statement).execute(&database.pool).await?;
        }

        let service = WebxdcService::new(&ctx);

        let members: serde_json::Value = serde_json::from_str(&service.members("card").await?)?;

        assert_eq!(members["selfId"], WebxdcService::address_for("card", 42));

        assert_eq!(members["members"].as_array().unwrap().len(), 2);

        assert_eq!(members["members"][0]["displayName"], "Anna");

        assert_eq!(members["members"][1]["displayName"], "Benny");

        assert_eq!(
            members["members"][1]["id"],
            WebxdcService::address_for("card", 7)
        );

        for (statement, expected) in [
            (
                "UPDATE contacts SET nick_name = '' WHERE user_id = 7",
                "Ben",
            ),
            (
                "UPDATE contacts SET display_name = NULL WHERE user_id = 7",
                "ben",
            ),
            (
                "UPDATE contacts SET account_deleted = 1 WHERE user_id = 7",
                "b\u{0336}e\u{0336}n\u{0336}",
            ),
            (
                "UPDATE contacts SET account_deleted = 0, display_name = '' WHERE user_id = 7",
                "",
            ),
        ] {
            sqlx::query(statement).execute(&database.pool).await?;

            let members: serde_json::Value = serde_json::from_str(&service.members("card").await?)?;

            assert_eq!(members["members"][1]["displayName"], expected);
        }

        assert!(service.members("missing").await.is_err());

        assert!(service
            .send_update(
                "card".into(),
                "{}".into(),
                Some("Dinner".into()),
                None,
                None,
                None,
                Some(r#"{"unrelated-member":"Dinner"}"#.into())
            )
            .await
            .is_err());

        Ok(())
    }

    /// The announcement lands in the chat as an ordinary message, and lands
    /// there once however often the update it came with is delivered.
    #[tokio::test]

    async fn an_announcement_becomes_a_chat_message_of_its_own() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let context =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let database = context.app_db.read().await.clone();

        let mut transaction = database.pool.begin().await?;

        // A chat with an app card in it, which is what an instance is keyed by.
        sqlx::query!("INSERT INTO groups(group_id, group_name) VALUES ('group-1', 'Chat')")
            .execute(&mut *transaction)
            .await?;

        sqlx::query!(
            r#"INSERT INTO messages(group_id, message_id, type, created_at)
               VALUES ('group-1', 'card-1', 'webxdcApp', 0)"#
        )
        .execute(&mut *transaction)
        .await?;

        WebxdcService::insert_instance(&mut transaction, "card-1", "group-1", "mills", 3).await?;

        WebxdcService::append_update(
            &mut transaction,
            "card-1",
            "update-1",
            None,
            "{}",
            Some("Alice is on turn"),
            None,
            1234,
        )
        .await?;

        for _ in 0..2 {
            WebxdcService::insert_info_message(
                &mut transaction,
                "card-1",
                "mills",
                3,
                "group-1",
                "update-1",
                None,
                "Alice is on turn",
                1234,
                None,
            )
            .await?;
        }

        let rows = sqlx::query!(
            r#"SELECT message_id AS "message_id!: String", content AS "content: String",
                      additional_message_data AS "data: Vec<u8>", created_at AS "created_at!: i64"
               FROM messages WHERE type = 'text'"#
        )
        .fetch_all(&mut *transaction)
        .await?;

        assert_eq!(rows.len(), 1, "the same update announced twice");

        assert_eq!(
            rows[0].message_id,
            WebxdcService::info_message_id("update-1")
        );

        assert_eq!(rows[0].content.as_deref(), Some("Alice is on turn"));

        assert_eq!(rows[0].created_at, 1234);

        // The card the row points back at.
        let data = <proto::AdditionalMessageData as prost::Message>::decode(
            rows[0].data.as_deref().expect("no origin recorded"),
        )
        .expect("the origin does not decode");

        let origin = data.webxdc_origin.expect("no app named");

        assert_eq!(origin.instance_id, "card-1");

        assert_eq!(origin.app_id, "mills");

        assert_eq!(origin.version, 3);

        Ok(())
    }

    #[test]

    fn sanitize_drops_control_and_direction_characters() {
        assert_eq!(
            sanitize(Some("your\u{202e}turn\n"), 200).as_deref(),
            Some("yourturn")
        );

        assert_eq!(sanitize(Some("   "), 200), None);

        assert_eq!(sanitize(Some("abcdef"), 3).as_deref(), Some("abc"));
    }

    #[test]

    fn hrefs_may_only_address_the_app_itself() {
        assert_eq!(
            sanitize_href("board.html?id=3").as_deref(),
            Some("board.html?id=3")
        );

        assert_eq!(
            sanitize_href("/sub/page.html").as_deref(),
            Some("/sub/page.html")
        );

        for href in [
            "https://example.com",
            "//example.com",
            "javascript:alert(1)",
            "data:text/html,x",
            "../../etc/passwd",
            "a\\b",
        ] {
            assert!(sanitize_href(href).is_none(), "{href} was not refused");
        }
    }

    #[test]

    fn an_announcement_belongs_to_the_update_it_arrived_with() {
        // Derived rather than random, so the same update redelivered writes the
        // same row instead of announcing twice.
        let id = WebxdcService::info_message_id("update-1");

        assert_eq!(id, WebxdcService::info_message_id("update-1"));

        assert_ne!(id, WebxdcService::info_message_id("update-2"));

        assert_ne!(id, "update-1");
    }

    #[test]

    fn addresses_are_stable_per_instance_and_differ_across_instances() {
        let a = WebxdcService::address_for("instance-a", 42);

        assert_eq!(a, "c46ce99818ddcffb@twonly");

        assert_eq!(a, WebxdcService::address_for("instance-a", 42));

        assert_ne!(a, WebxdcService::address_for("instance-b", 42));

        assert_ne!(a, WebxdcService::address_for("instance-a", 43));
    }
}
