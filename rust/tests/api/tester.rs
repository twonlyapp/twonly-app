use libsignal_protocol::IdentityKeyPair;
use rand::SeedableRng;
use rust_lib_twonly::api::{ApiRuntime, Server};
use rust_lib_twonly::bridge::api::{ApiConnectionState, ServerResult};
use rust_lib_twonly::context::Context;
use rust_lib_twonly::services::notifications::{self, NotificationAddition, NotificationBatch};
use sha2::{Digest, Sha256};
use std::sync::Arc;
use tempfile::TempDir;
use tokio::time::{sleep, Duration};

/// Installs the tracing subscriber shared by every integration test.
///
/// Logging is entirely opt-in through the environment: without `RUST_LOG` no
/// subscriber is installed at all, so a plain `cargo test` run stays quiet.
/// `RUST_LOG` selects the filter, and `NO_COLOR` (or `TWONLY_LOG_ANSI=0`)
/// switches the formatter from ansi to plain for CI logs.
///
/// Calling it more than once is a no-op, so every test can call it.
pub(crate) fn init_tracing() {
    let Ok(filter) = tracing_subscriber::EnvFilter::try_from_default_env() else {
        return;
    };

    let ansi = match std::env::var("TWONLY_LOG_ANSI") {
        Ok(value) => !matches!(value.trim(), "" | "0" | "false" | "no"),
        Err(_) => std::env::var_os("NO_COLOR").is_none_or(|value| value.is_empty()),
    };

    let subscriber = tracing_subscriber::fmt()
        .with_env_filter(filter)
        .with_ansi(ansi);

    let _ = if ansi {
        subscriber
            .event_format(rust_lib_twonly::log::ShortEventFormatter::ansi())
            .try_init()
    } else {
        subscriber
            .event_format(rust_lib_twonly::log::ShortEventFormatter::plain())
            .try_init()
    };
}

pub(crate) struct Tester {
    pub context: Arc<Context>,
    pub username: String,
    pub lang_code: String,
    pub is_ios: bool,
    pub user_id: i64,
    // drop will auto delete the folder
    _temp_dir: TempDir,
}

#[allow(dead_code)]
impl Tester {
    pub async fn set_contact_verified(&self, user_id: i64, verified: bool) -> anyhow::Result<()> {
        let database = self.context.app_db.read().await.clone();
        if verified {
            sqlx::query!(
                "INSERT INTO key_verifications(contact_id, type) VALUES (?, 'manualTest')",
                user_id,
            )
            .execute(&database.pool)
            .await?;
        } else {
            sqlx::query!(
                "DELETE FROM key_verifications WHERE contact_id = ? AND type = 'manualTest'",
                user_id,
            )
            .execute(&database.pool)
            .await?;
        }
        database.notify_committed(["key_verifications"]);
        Ok(())
    }

    pub async fn wait_for_additional_data_message(
        &self,
        message_id: &str,
        sender_id: i64,
        message_type: &str,
        expected_data: &[u8],
    ) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let message = sqlx::query!(
                "SELECT sender_id, type, additional_message_data FROM messages WHERE message_id = ?",
                message_id,
            )
            .fetch_optional(&database.pool)
            .await?;
            if message.is_some_and(|message| {
                message.sender_id == Some(sender_id)
                    && message.r#type == message_type
                    && message.additional_message_data.as_deref() == Some(expected_data)
            }) {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "additional-data message {message_id} from {sender_id} did not arrive"
        ))
    }

    pub async fn wait_for_shared_contact_verification(
        &self,
        contact_id: i64,
        verified_by: i64,
    ) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let exists = sqlx::query_scalar!(
                "SELECT EXISTS(SELECT 1 FROM key_verifications WHERE contact_id = ? AND type = 'contactSharedByVerified' AND verified_by = ?)",
                contact_id,
                verified_by,
            )
            .fetch_one(&database.pool)
            .await?;
            if exists != 0 {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "contact {contact_id} was not verified through {verified_by}"
        ))
    }

    pub async fn is_contact_verified(&self, contact_id: i64) -> anyhow::Result<bool> {
        let database = self.context.app_db.read().await.clone();
        let verified = sqlx::query_scalar!(
            r#"
            SELECT EXISTS(
                SELECT 1
                FROM key_verifications AS verification
                WHERE verification.contact_id = ?
                  AND (
                    verification.type != 'contactSharedByVerified'
                    OR EXISTS(
                        SELECT 1 FROM key_verifications AS verifier_verification
                        WHERE verifier_verification.contact_id = verification.verified_by
                    )
                  )
            )
            "#,
            contact_id,
        )
        .fetch_one(&database.pool)
        .await?;
        Ok(verified != 0)
    }

    pub async fn wait_for_contact_state(
        &self,
        user_id: i64,
        accepted: bool,
        requested: bool,
    ) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let state = sqlx::query!(
                "SELECT accepted, requested FROM contacts WHERE user_id = ?",
                user_id
            )
            .fetch_optional(&database.pool)
            .await?;
            if state.is_some_and(|contact| {
                contact.accepted == i64::from(accepted) && contact.requested == i64::from(requested)
            }) {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "contact {user_id} did not reach accepted={accepted}, requested={requested}"
        ))
    }

    pub async fn wait_for_contact_username(
        &self,
        user_id: i64,
        expected_username: &str,
    ) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let username =
                sqlx::query_scalar!("SELECT username FROM contacts WHERE user_id = ?", user_id)
                    .fetch_optional(&database.pool)
                    .await?;
            if let Some(username) = username {
                if username == expected_username {
                    return Ok(());
                }
            } else {
                tracing::info!("username is None for user_id={}", user_id);
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "contact {user_id} did not reach username={expected_username}"
        ))
    }

    pub async fn wait_for_text_message(
        &self,
        message_id: &str,
        sender_id: i64,
        expected_text: &str,
    ) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let message = sqlx::query!(
                "SELECT sender_id, content, is_deleted_from_sender FROM messages WHERE message_id = ?",
                message_id
            )
            .fetch_optional(&database.pool)
            .await?;
            if message.is_some_and(|message| {
                message.sender_id == Some(sender_id)
                    && message.content.as_deref() == Some(expected_text)
                    && message.is_deleted_from_sender == 0
            }) {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "message {message_id} from {sender_id} did not contain {expected_text:?}"
        ))
    }

    pub async fn wait_for_message_ack_by_server(&self, message_id: &str) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let acknowledged_at = sqlx::query_scalar::<_, Option<i64>>(
                "SELECT ack_by_server FROM messages WHERE message_id = ?",
            )
            .bind(message_id)
            .fetch_optional(&database.pool)
            .await?
            .flatten();
            if acknowledged_at.is_some() {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "message {message_id} was not acknowledged by the server"
        ))
    }

    pub async fn wait_for_reaction(
        &self,
        message_id: &str,
        sender_id: i64,
        emoji: &str,
    ) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let exists = sqlx::query_scalar!(
                "SELECT EXISTS(SELECT 1 FROM reactions WHERE message_id = ? AND sender_id = ? AND emoji = ?)",
                message_id,
                sender_id,
                emoji,
            )
            .fetch_one(&database.pool)
            .await?;
            if exists != 0 {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "reaction {emoji:?} from {sender_id} did not arrive for message {message_id}"
        ))
    }

    pub async fn wait_for_reaction_deleted(
        &self,
        message_id: &str,
        sender_id: i64,
        emoji: &str,
    ) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let exists = sqlx::query_scalar!(
                "SELECT EXISTS(SELECT 1 FROM reactions WHERE message_id = ? AND sender_id = ? AND emoji = ?)",
                message_id,
                sender_id,
                emoji,
            )
            .fetch_one(&database.pool)
            .await?;
            if exists == 0 {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "reaction {emoji:?} from {sender_id} was not deleted for message {message_id}"
        ))
    }

    pub async fn wait_for_message_deleted(&self, message_id: &str) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let deleted = sqlx::query_scalar!(
                "SELECT is_deleted_from_sender FROM messages WHERE message_id = ?",
                message_id
            )
            .fetch_optional(&database.pool)
            .await?;
            if deleted == Some(1) {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "message {message_id} was not deleted by its sender"
        ))
    }

    pub async fn wait_for_group_exists(
        &self,
        group_id: &str,
        group_name: &str,
    ) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let row = sqlx::query!("SELECT group_name FROM groups WHERE group_id = ?", group_id)
                .fetch_optional(&database.pool)
                .await?;
            if row.is_some_and(|r| r.group_name == group_name) {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "group {group_id} with name {group_name:?} did not appear"
        ))
    }

    pub async fn wait_for_group_member_removed(
        &self,
        group_id: &str,
        contact_id: i64,
    ) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let state = sqlx::query_scalar!(
                "SELECT member_state FROM group_members WHERE group_id = ? AND contact_id = ?",
                group_id,
                contact_id,
            )
            .fetch_optional(&database.pool)
            .await?;
            match state {
                None => return Ok(()),
                Some(s) if s.as_deref() == Some("leftGroup") => return Ok(()),
                _ => {}
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "member {contact_id} was not removed from group {group_id}"
        ))
    }

    pub async fn wait_for_group_name(
        &self,
        group_id: &str,
        expected_name: &str,
    ) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let name =
                sqlx::query_scalar!("SELECT group_name FROM groups WHERE group_id = ?", group_id)
                    .fetch_optional(&database.pool)
                    .await?;
            if name.as_deref() == Some(expected_name) {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "group {group_id} name did not update to {expected_name:?}"
        ))
    }

    pub async fn wait_for_group_left(&self, group_id: &str) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let left =
                sqlx::query_scalar!("SELECT left_group FROM groups WHERE group_id = ?", group_id)
                    .fetch_optional(&database.pool)
                    .await?;
            if left == Some(1) {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!("group {group_id} was not marked as left"))
    }

    pub async fn new() -> anyhow::Result<Self> {
        let temp_dir = tempfile::tempdir()?;
        let db_dir = temp_dir.path().join("db");
        let data_dir = temp_dir.path().join("data");

        std::fs::create_dir_all(data_dir.join("keyvalue"))?;

        let config = rust_lib_twonly::user_config::UserConfig {
            app_version: 100,
            device_id: 1,
            can_use_login_token_for_auth: true,
            is_user_discovery_enabled: true,
            user_discovery_threshold: 3,
            user_discovery_share_promotion: true,
            typing_indicators: true,
            ..Default::default()
        };
        std::fs::write(
            data_dir.join("keyvalue").join("user.json"),
            serde_json::to_string(&config).unwrap(),
        )?;

        let context = Context::init_for_testing(db_dir, data_dir).await?;

        {
            let mut csprng = rand::rngs::StdRng::from_os_rng();
            let identity_pair = IdentityKeyPair::generate(&mut csprng);
            let registration_id: u32 = rand::Rng::random::<u32>(&mut csprng) & 0x7FFFFFFF;
            context
                .inject_test_signal_identity(
                    identity_pair.serialize().to_vec(),
                    registration_id as i64,
                )
                .await?;
        }

        let username = format!(
            "usr_{}",
            &uuid::Uuid::new_v4().to_string().replace("-", "")[..8]
        );

        Ok(Self {
            context,
            username,
            lang_code: "en".to_string(),
            is_ios: false,
            user_id: 0,
            _temp_dir: temp_dir,
        })
    }

    pub fn update_username(&mut self, new_username: String) -> anyhow::Result<()> {
        self.username = new_username.clone();

        let path = self
            ._temp_dir
            .path()
            .join("data")
            .join("keyvalue")
            .join("user.json");
        let content = std::fs::read_to_string(&path)?;
        let mut config: rust_lib_twonly::user_config::UserConfig = serde_json::from_str(&content)?;
        config.username = new_username;
        config.avatar_counter += 1;

        std::fs::write(&path, serde_json::to_string(&config)?)?;
        Ok(())
    }

    pub fn update_profile(
        &mut self,
        new_username: Option<String>,
        new_display_name: Option<String>,
        new_avatar_svg: Option<String>,
    ) -> anyhow::Result<()> {
        let path = self
            ._temp_dir
            .path()
            .join("data")
            .join("keyvalue")
            .join("user.json");
        let content = std::fs::read_to_string(&path)?;
        let mut config: rust_lib_twonly::user_config::UserConfig = serde_json::from_str(&content)?;
        if let Some(u) = new_username {
            self.username = u.clone();
            config.username = u;
        }
        if let Some(d) = new_display_name {
            config.display_name = d;
        }
        if let Some(a) = new_avatar_svg {
            config.avatar_svg = Some(a);
        }
        config.avatar_counter += 1;

        std::fs::write(&path, serde_json::to_string(&config)?)?;
        Ok(())
    }

    pub async fn wait_for_contact_display_name(
        &self,
        user_id: i64,
        expected_display_name: &str,
    ) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let display_name = sqlx::query_scalar!(
                "SELECT display_name FROM contacts WHERE user_id = ?",
                user_id
            )
            .fetch_optional(&database.pool)
            .await?
            .flatten();
            if display_name.as_deref() == Some(expected_display_name) {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "contact {user_id} did not reach display_name={expected_display_name}"
        ))
    }

    pub async fn wait_for_contact_avatar_exists(&self, user_id: i64) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let avatar = sqlx::query_scalar!(
                "SELECT avatar_svg_compressed FROM contacts WHERE user_id = ?",
                user_id
            )
            .fetch_optional(&database.pool)
            .await?
            .flatten();
            if avatar.is_some() {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!("contact {user_id} did not receive avatar"))
    }

    /// Reads the receiver's notification outbox through the very API the iOS
    /// Notification Service Extension and the Android worker call.
    pub async fn notification_batch(&self, locale: &str) -> anyhow::Result<NotificationBatch> {
        Ok(notifications::pending_batch(&self.context, locale).await?)
    }

    /// Waits until an undelivered notification of `kind` from `sender_id` is
    /// pending, and returns it. Incoming messages are committed asynchronously,
    /// so every notification assertion has to poll.
    pub async fn wait_for_notification(
        &self,
        kind: &str,
        sender_id: i64,
    ) -> anyhow::Result<NotificationAddition> {
        for _ in 0..100 {
            let batch = self.notification_batch(&self.lang_code).await?;
            if let Some(addition) = batch
                .additions
                .into_iter()
                .find(|addition| addition.kind == kind && addition.sender_id == sender_id)
            {
                return Ok(addition);
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "no pending {kind} notification from {sender_id} arrived"
        ))
    }

    /// Marks pending notifications as delivered, mirroring what the native
    /// layer does once it has actually scheduled them.
    pub async fn acknowledge_notifications(&self, event_ids: &[String]) -> anyhow::Result<()> {
        Ok(notifications::acknowledge_batch(&self.context, event_ids).await?)
    }

    pub async fn clear_notification_conversation(
        &self,
        conversation_id: &str,
    ) -> anyhow::Result<Vec<String>> {
        Ok(notifications::clear_conversation(&self.context, conversation_id).await?)
    }

    pub async fn clear_contact_request_notifications(&self) -> anyhow::Result<Vec<String>> {
        Ok(notifications::clear_contact_requests(&self.context).await?)
    }

    /// The value the running app pushes into the iOS app icon badge.
    pub async fn notification_badge_count(&self) -> anyhow::Result<i64> {
        Ok(notifications::badge_count(&self.context).await?)
    }

    /// Number of rows the outbox holds for one receipt, used to prove that a
    /// redelivered envelope cannot notify twice.
    pub async fn notification_rows_for_event(&self, event_id: &str) -> anyhow::Result<i64> {
        let database = self.context.app_db.read().await.clone();
        Ok(sqlx::query_scalar!(
            "SELECT COUNT(*) FROM notification_outbox WHERE event_id = ?",
            event_id
        )
        .fetch_one(&database.pool)
        .await?)
    }

    pub async fn notification_rows_for_message(&self, message_id: &str) -> anyhow::Result<i64> {
        let database = self.context.app_db.read().await.clone();
        Ok(sqlx::query_scalar!(
            "SELECT COUNT(*) FROM notification_outbox WHERE message_id = ?",
            message_id
        )
        .fetch_one(&database.pool)
        .await?)
    }

    pub async fn set_contact_blocked(&self, user_id: i64, blocked: bool) -> anyhow::Result<()> {
        let database = self.context.app_db.read().await.clone();
        let blocked = i64::from(blocked);
        sqlx::query!(
            "UPDATE contacts SET blocked = ? WHERE user_id = ?",
            blocked,
            user_id
        )
        .execute(&database.pool)
        .await?;
        database.notify_committed(["contacts"]);
        Ok(())
    }

    pub async fn wait_for_quoted_text_message(
        &self,
        message_id: &str,
        sender_id: i64,
        expected_text: &str,
        expected_quote_id: &str,
    ) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let message = sqlx::query!(
                "SELECT sender_id, content, quotes_message_id, is_deleted_from_sender FROM messages WHERE message_id = ?",
                message_id
            )
            .fetch_optional(&database.pool)
            .await?;
            if message.is_some_and(|message| {
                message.sender_id == Some(sender_id)
                    && message.content.as_deref() == Some(expected_text)
                    && message.quotes_message_id.as_deref() == Some(expected_quote_id)
                    && message.is_deleted_from_sender == 0
            }) {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "message {message_id} with quote {expected_quote_id} did not arrive"
        ))
    }

    pub async fn wait_for_typing_indicator(
        &self,
        group_id: &str,
        contact_id: i64,
        is_typing: bool,
    ) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let state = sqlx::query!(
                "SELECT last_type_indicator FROM group_members WHERE group_id = ? AND contact_id = ?",
                group_id,
                contact_id,
            )
            .fetch_optional(&database.pool)
            .await?;
            if let Some(row) = state {
                if is_typing && row.last_type_indicator.is_some() {
                    return Ok(());
                } else if !is_typing && row.last_type_indicator.is_none() {
                    return Ok(());
                }
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "typing indicator for contact {contact_id} in {group_id} did not reach is_typing={is_typing}"
        ))
    }

    pub async fn wait_for_message_opened(&self, message_id: &str) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let opened = sqlx::query_scalar!(
                "SELECT opened_at FROM messages WHERE message_id = ?",
                message_id
            )
            .fetch_optional(&database.pool)
            .await?
            .flatten();
            if opened.is_some() {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "message {message_id} was not marked as opened"
        ))
    }

    pub async fn wait_for_group_chat_deletion_time(
        &self,
        group_id: &str,
        expected_ms: i64,
    ) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let ms = sqlx::query_scalar!(
                "SELECT delete_messages_after_milliseconds FROM groups WHERE group_id = ?",
                group_id
            )
            .fetch_optional(&database.pool)
            .await?;
            if ms == Some(expected_ms) {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "group {group_id} delete_messages_after_milliseconds did not reach {expected_ms}"
        ))
    }

    pub async fn wait_for_flame_counter(
        &self,
        group_id: &str,
        min_flame: i64,
    ) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let flame = sqlx::query_scalar!(
                "SELECT flame_counter FROM groups WHERE group_id = ?",
                group_id
            )
            .fetch_optional(&database.pool)
            .await?;
            if flame.is_some_and(|f| f >= min_flame) {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "group {group_id} flame_counter did not reach {min_flame}"
        ))
    }

    pub async fn wait_for_media_stored(&self, message_id: &str) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let stored = sqlx::query_scalar!(
                "SELECT media_stored FROM messages WHERE message_id = ?",
                message_id
            )
            .fetch_optional(&database.pool)
            .await?;
            if stored == Some(1) {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "message {message_id} was not marked as media_stored"
        ))
    }

    pub async fn wait_for_media_reopened(&self, message_id: &str) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let reopened = sqlx::query_scalar!(
                "SELECT media_reopened FROM messages WHERE message_id = ?",
                message_id
            )
            .fetch_optional(&database.pool)
            .await?;
            if reopened == Some(1) {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "message {message_id} was not marked as media_reopened"
        ))
    }

    pub async fn wait_for_media_upload_state(
        &self,
        media_id: &str,
        expected_state: &str,
    ) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let state = sqlx::query_scalar!(
                "SELECT upload_state FROM media_files WHERE media_id = ?",
                media_id
            )
            .fetch_optional(&database.pool)
            .await?
            .flatten();
            if state.as_deref() == Some(expected_state) {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "media {media_id} upload_state did not reach {expected_state}"
        ))
    }

    pub async fn wait_for_media_download_state(
        &self,
        media_id: &str,
        expected_state: &str,
    ) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let state = sqlx::query_scalar!(
                "SELECT download_state FROM media_files WHERE media_id = ?",
                media_id
            )
            .fetch_optional(&database.pool)
            .await?
            .flatten();
            if state.as_deref() == Some(expected_state) {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "media {media_id} download_state did not reach {expected_state}"
        ))
    }

    pub async fn wait_for_recovery_contacts_share(&self, contact_id: i64) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let share = sqlx::query_scalar!(
                "SELECT recovery_contacts_secret_share FROM contacts WHERE user_id = ?",
                contact_id
            )
            .fetch_optional(&database.pool)
            .await?;
            if share.is_some_and(|s| s.is_some()) {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "contact {contact_id} did not receive recovery share"
        ))
    }

    pub async fn wait_for_recovery_last_heartbeat(&self, contact_id: i64) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let heartbeat = sqlx::query_scalar!(
                "SELECT recovery_last_heartbeat FROM contacts WHERE user_id = ?",
                contact_id
            )
            .fetch_optional(&database.pool)
            .await?;
            if heartbeat.is_some_and(|h| h.is_some()) {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "contact {contact_id} did not record recovery heartbeat"
        ))
    }

    pub async fn wait_for_recovery_share_deleted(&self, contact_id: i64) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.app_db.read().await.clone();
            let share = sqlx::query_scalar!(
                "SELECT recovery_contacts_secret_share FROM contacts WHERE user_id = ?",
                contact_id
            )
            .fetch_optional(&database.pool)
            .await?;
            if share == Some(None) {
                return Ok(());
            }
            sleep(Duration::from_millis(100)).await;
        }
        Err(anyhow::anyhow!(
            "recovery share for contact {contact_id} was not deleted"
        ))
    }

    pub async fn register_and_authenticate(&mut self) -> anyhow::Result<()> {
        let ServerResult::Ok(pow) = Server::get_proof_of_work(&self.context).await? else {
            return Err(anyhow::anyhow!("got no proof of work"));
        };

        let proof_of_work = Tester::calculate_pow(&pow.prefix, pow.difficulty as usize);

        let user_id = Server::register(
            &self.context,
            self.username.clone(),
            proof_of_work,
            self.lang_code.clone(),
            self.is_ios,
        )
        .await?;

        let ServerResult::Ok(user_id) = user_id else {
            return Err(anyhow::anyhow!("got no user_id"));
        };

        self.user_id = user_id;
        self.context.inject_test_user_id(user_id).await?;

        // Reload the API configuration so the new login_token/user_id is picked up by the API Client
        ApiRuntime::reload_configuration(&self.context).await?;
        self.wait_until(ApiConnectionState::Authenticated).await?;

        Server::generate_and_upload_pqc_pre_keys(&self.context).await?;

        Ok(())
    }

    pub fn is_valid(difficulty: usize, digest: &[u8]) -> bool {
        let bits = digest
            .iter()
            .map(|b| format!("{:08b}", b))
            .collect::<String>();
        bits.starts_with(&"0".repeat(difficulty))
    }

    pub fn calculate_pow(prefix: &str, difficulty: usize) -> i64 {
        let mut i = 0;
        loop {
            i += 1;
            let s = format!("{}{}", prefix, i);
            let mut hasher = Sha256::new();
            hasher.update(s.as_bytes());
            let digest = hasher.finalize();
            if Self::is_valid(difficulty, &digest) {
                return i;
            }
        }
    }

    pub(crate) async fn wait_until(&self, required: ApiConnectionState) -> anyhow::Result<()> {
        let mut state = ApiRuntime::connection_state(&self.context).await?;

        for _ in 0..1_000 {
            state = ApiRuntime::connection_state(&self.context).await?;
            if state == required {
                break;
            }
            sleep(Duration::from_millis(10)).await;
        }

        assert_eq!(
            state, required,
            "API should be in {required:?} and not in {state:?}"
        );
        Ok(())
    }
}
