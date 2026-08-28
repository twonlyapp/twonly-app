use libsignal_protocol::{GenericSignedPreKey, IdentityKeyPair, KeyPair, SignedPreKeyRecord};
use rand::SeedableRng;
use rust_lib_twonly::api::{ApiRuntime, Server};
use rust_lib_twonly::bridge::api::{ApiConnectionState, ServerResult};
use rust_lib_twonly::context::Context;
use sha2::{Digest, Sha256};
use std::sync::Arc;
use tempfile::TempDir;
use tokio::time::{sleep, Duration};

pub(crate) struct Tester {
    pub context: Arc<Context>,
    pub username: String,
    pub lang_code: String,
    pub is_ios: bool,
    pub user_id: i64,
    // drop will auto delete the folder
    _temp_dir: TempDir,
}

impl Tester {
    pub async fn set_contact_verified(&self, user_id: i64, verified: bool) -> anyhow::Result<()> {
        let database = self.context.get_app_database().await;
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
            let database = self.context.get_app_database().await;
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
            let database = self.context.get_app_database().await;
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
        let database = self.context.get_app_database().await;
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
            let database = self.context.get_app_database().await;
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
            let database = self.context.get_app_database().await;
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
            let database = self.context.get_app_database().await;
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

    pub async fn wait_for_reaction(
        &self,
        message_id: &str,
        sender_id: i64,
        emoji: &str,
    ) -> anyhow::Result<()> {
        for _ in 0..100 {
            let database = self.context.get_app_database().await;
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
            let database = self.context.get_app_database().await;
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
            let database = self.context.get_app_database().await;
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
            let database = self.context.get_app_database().await;
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
            let database = self.context.get_app_database().await;
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
            let database = self.context.get_app_database().await;
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
            let database = self.context.get_app_database().await;
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
            let timestamp = libsignal_protocol::Timestamp::from_epoch_millis(
                std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap()
                    .as_millis() as u64,
            );

            let signed_pre_key_pair = KeyPair::generate(&mut csprng);
            let signature = identity_pair
                .private_key()
                .calculate_signature_for_multipart_message(
                    &[&signed_pre_key_pair.public_key.serialize()],
                    &mut csprng,
                )
                .map_err(|e| anyhow::anyhow!("Signal error: {}", e))?;

            let signed_prekey =
                SignedPreKeyRecord::new(1.into(), timestamp, &signed_pre_key_pair, &signature);
            let mut pre_key_store = std::collections::HashMap::new();
            pre_key_store.insert(
                1,
                signed_prekey
                    .serialize()
                    .map_err(|e| anyhow::anyhow!("Signal error: {}", e))?,
            );

            context
                .inject_test_signal_identity(
                    identity_pair.serialize().to_vec(),
                    registration_id as i64,
                    pre_key_store,
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

        // After the user has register, it should reconnected and reauthenticated
        ApiRuntime::close(&self.context).await?;
        ApiRuntime::connect(&self.context).await?;

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
