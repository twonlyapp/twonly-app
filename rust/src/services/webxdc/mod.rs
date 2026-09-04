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

use crate::api::proto::client as proto;
use crate::context::Context;
use crate::database::app::tables::{MessageType, NewMessage};
use crate::error::{Result, TwonlyError};
use hmac::{Hmac, Mac};
use sha2::Sha256;
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
/// Sending burst allowance, counted over the trailing minute.
const MAX_UPDATES_PER_MINUTE: i64 = 12;

/// Text an app can put in front of the user, outside its own sandbox. Bounded
/// so a chat row or a notification cannot be filled with app-controlled text.
const MAX_INFO_CHARS: usize = 200;
const MAX_SUMMARY_CHARS: usize = 64;
const MAX_DOCUMENT_CHARS: usize = 128;

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

    /// Places an app into a chat and tells the other members which app and
    /// which version, so every participant runs the same code.
    pub async fn create_instance(
        &self,
        group_id: String,
        app_id: String,
        version: i64,
    ) -> Result<String> {
        // Resolved before anything is sent: pointing a chat at an app the store
        // does not offer should fail here rather than on every recipient's
        // device.
        self.store().resolve_bundle_sha256(&app_id, version).await?;

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

    /// Records the instance a peer placed into a chat. Nothing is downloaded
    /// here: a message must not be able to make a device fetch a bundle, only
    /// the user tapping Start may.
    pub(crate) async fn handle_incoming_app(
        transaction: &mut Transaction<'_, Sqlite>,
        message_id: &str,
        group_id: &str,
        app: &proto::WebxdcApp,
    ) -> Result<()> {
        Self::insert_instance(transaction, message_id, group_id, &app.app_id, app.version).await
    }

    async fn insert_instance(
        transaction: &mut Transaction<'_, Sqlite>,
        instance_id: &str,
        group_id: &str,
        app_id: &str,
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
        transaction: &mut Transaction<'_, Sqlite>,
        message_id: &str,
        group_id: &str,
        sender_id: i64,
        update: &proto::WebxdcUpdate,
        received_at: i64,
    ) -> Result<()> {
        let instance = sqlx::query!(
            r#"SELECT group_id AS "group_id!: String", app_id AS "app_id!: String",
                      version AS "version!: i64"
               FROM webxdc_instances WHERE instance_id = ?"#,
            update.instance_id,
        )
        .fetch_optional(&mut **transaction)
        .await?;

        let Some(instance) = instance else {
            // The card may still be on its way, or may already have been
            // deleted. Dropping the update is the only safe answer: a log entry
            // with no instance cannot be replayed in order.
            tracing::info!("webxdc update for an unknown instance, dropping");
            return Ok(());
        };
        if instance.group_id != group_id {
            tracing::warn!("webxdc update arrived in the wrong chat, dropping");
            return Ok(());
        }
        if update.payload.len() > SEND_UPDATE_MAX_SIZE {
            tracing::warn!("webxdc update exceeds the payload limit, dropping");
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

        Self::append_update(
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
            )
            .await?;
        }

        Ok(())
    }

    /// Writes an update's `info` into the chat as a message of its own.
    ///
    /// An app announces things a person is meant to read -- "a new game
    /// started", "it is your turn". The update carrying it is state rather than
    /// a message and stays hidden, so the announcement is materialised here
    /// instead: an ordinary chat row that names the app it came from and points
    /// back at its card.
    ///
    /// Both devices build the row out of the update they already have, so
    /// nothing extra is sent, and the id derived from the update's own message
    /// id makes a redelivery a no-op rather than a second announcement.
    #[allow(clippy::too_many_arguments)]
    async fn insert_info_message(
        transaction: &mut Transaction<'_, Sqlite>,
        instance_id: &str,
        app_id: &str,
        version: i64,
        group_id: &str,
        update_message_id: &str,
        sender_id: Option<i64>,
        info: &str,
        created_at: i64,
    ) -> Result<()> {
        let origin = proto::AdditionalMessageData {
            r#type: proto::additional_message_data::Type::WebxdcSent as i32,
            webxdc_origin: Some(proto::WebxdcOrigin {
                instance_id: instance_id.to_owned(),
                app_id: app_id.to_owned(),
                version,
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
            // The announcement is built locally from an update that has already
            // arrived, so there is nothing left to wait for.
            .ack_by_server(created_at)
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
        transaction: &mut Transaction<'_, Sqlite>,
        instance_id: &str,
        message_id: &str,
        sender_id: Option<i64>,
        payload: &str,
        info: Option<&str>,
        href: Option<&str>,
        received_at: i64,
    ) -> Result<()> {
        let next_serial: i64 = sqlx::query_scalar!(
            r#"SELECT COALESCE(MAX(serial), 0) + 1 AS "next!: i64"
               FROM webxdc_updates WHERE instance_id = ?"#,
            instance_id,
        )
        .fetch_one(&mut **transaction)
        .await?;

        // `message_id` is unique, so a redelivered message is a no-op rather
        // than a duplicated move.
        sqlx::query!(
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
        Ok(())
    }

    async fn apply_instance_labels(
        transaction: &mut Transaction<'_, Sqlite>,
        instance_id: &str,
        summary: Option<&str>,
        document: Option<&str>,
        received_at: i64,
    ) -> Result<()> {
        sqlx::query!(
            r#"UPDATE webxdc_instances
               SET summary = COALESCE(?, summary),
                   document = COALESCE(?, document),
                   last_update_at = ?
               WHERE instance_id = ?"#,
            summary,
            document,
            received_at,
            instance_id,
        )
        .execute(&mut **transaction)
        .await?;
        Ok(())
    }

    async fn within_instance_budget(
        transaction: &mut Transaction<'_, Sqlite>,
        instance_id: &str,
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
    pub async fn send_update(
        &self,
        instance_id: String,
        payload: String,
        info: Option<String>,
        href: Option<String>,
        summary: Option<String>,
        document: Option<String>,
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
            }),
            ..Default::default()
        };
        let message_id = crate::services::messages::MessageService::new(&self.ctx)
            .insert_and_send_additional_data(
                instance.group_id.clone(),
                "webxdcUpdate".into(),
                prost::Message::encode_to_vec(&data),
                // App state, not a message. The log in `webxdc_updates` is the
                // record; a chat row would only be noise, and a notification
                // for every move would be worse.
                true,
            )
            .await?;

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
            )
            .await?;
        }

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

    /// Starts an app: checks the store for a newer version, and makes the
    /// bundle the instance ends up on available on disk.
    ///
    /// Called when the user starts the app, never on message arrival, and never
    /// again while the app runs. This is the one moment an update may land: the
    /// code behind a game changes between two of its runs, never between two of
    /// its own updates.
    pub async fn prepare_bundle(&self, instance_id: &str) -> Result<std::path::PathBuf> {
        let instance = self
            .instance(instance_id)
            .await?
            .ok_or_else(|| TwonlyError::Generic("unknown webxdc instance".into()))?;

        // A refresh that fails means this device is offline or the server is
        // down. Neither is a reason to refuse to start an app whose bundle is
        // already here, so the failure is logged and the instance keeps the
        // version it has.
        if let Err(error) = self.store().refresh_catalog().await {
            tracing::info!("checking for a webxdc update failed: {error}");
        }
        if let Some(path) = self.apply_update(&instance, instance_id).await? {
            return Ok(path);
        }
        self.pinned_bundle(instance_id).await
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
                Self::pin(&self.ctx, instance_id, instance.version, &sha256).await?;
                sha256
            }
        };
        store.ensure_bundle(&sha256).await
    }

    /// Moves an instance to a newer published version, if there is one.
    ///
    /// Returns the bundle it moved to, or `None` when the instance is to stay
    /// where it is -- because nothing newer is published, or because the newer
    /// bundle could not be fetched. The pin is written only after the download
    /// verified: an instance must never end up pointing at code this device
    /// does not have, when it does have the code it was running before.
    async fn apply_update(
        &self,
        instance: &WebxdcInstance,
        instance_id: &str,
    ) -> Result<Option<std::path::PathBuf>> {
        let store = self.store();
        let Some((version, sha256)) = store.newest_published(&instance.app_id).await? else {
            return Ok(None);
        };
        if version <= instance.version {
            return Ok(None);
        }

        match store.ensure_bundle(&sha256).await {
            Ok(path) => {
                Self::pin(&self.ctx, instance_id, version, &sha256).await?;
                tracing::info!(
                    "webxdc {} moved from version {} to {version}",
                    instance.app_id,
                    instance.version,
                );
                if let Some(previous) = &instance.bundle_sha256 {
                    self.discard_unused_bundle(previous).await;
                }
                Ok(Some(path))
            }
            // Nothing has been written yet, so the caller starts the version
            // the instance already had.
            Err(error) if instance.bundle_sha256.is_some() => {
                tracing::warn!("fetching the webxdc update failed: {error}");
                Ok(None)
            }
            // Nothing to fall back to: this instance has never run here.
            Err(error) => Err(error),
        }
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
        let mut mac = <Hmac<Sha256> as Mac>::new_from_slice(instance_id.as_bytes())
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
        sqlx::query!(
            "DELETE FROM webxdc_updates WHERE instance_id = ?",
            instance_id
        )
        .execute(&mut *transaction)
        .await?;
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
        assert_eq!(a, WebxdcService::address_for("instance-a", 42));
        assert_ne!(a, WebxdcService::address_for("instance-b", 42));
        assert_ne!(a, WebxdcService::address_for("instance-a", 43));
    }
}
