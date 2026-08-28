/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use std::collections::HashSet;
use crate::api::server::Server;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use std::path::PathBuf;
use std::sync::Arc;
use blahaj::{Share, Sharks};
use libsignal_protocol::{IdentityKey, IdentityKeyPair};
use prost::Message;
use rand::SeedableRng;
use serde::{Deserialize, Serialize};
use tokio::sync::{Mutex, RwLock};
use crate::database::signal::Database;
use crate::keys::KeyManager;
use crate::error::{Result, TwonlyError};
use crate::user_discovery::user_discovery_message::{UserDiscoveryAnnouncement, UserDiscoveryPromotion};
use crate::user_discovery::user_discovery_message::user_discovery_promotion::AnnouncementShareDecrypted;
use crate::user_discovery::user_discovery_message::user_discovery_promotion::announcement_share_decrypted::SignedData;

/// Type of the user id, this must be consistent with the user id defined in
/// the types.proto
pub type UserID = i64;

include!(concat!(env!("OUT_DIR"), "/user_discovery.rs"));

#[derive(Clone, sqlx::FromRow)]
pub struct OtherPromotion {
    pub promotion_id: u32,
    pub public_id: i64,
    pub from_contact_id: UserID,
    pub threshold: u8,
    pub announcement_share: Vec<u8>,
    pub public_key_verified_timestamp: Option<i64>,
}

#[derive(Clone, Hash, PartialEq, Eq, Debug)]
pub struct AnnouncedUser {
    pub user_id: UserID,
    pub public_key: Vec<u8>,
    pub public_id: i64,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
struct UserDiscoveryConfig {
    /// The number of required shares to get the secret
    threshold: u8,
    /// Currently limited to <= 255 as GF 256 is used
    total_number_of_shares: u8,
    /// Version of announcements
    announcement_version: u32,
    /// Version of promotions
    promotion_version: u32,
    /// This is a random public_id associated with a single announcement.
    public_id: i64,
    /// Verification shares
    verification_shares: Vec<Vec<u8>>,
    // The users' id:
    user_id: UserID,
    // If others user should promote the promotion to other users
    share_promotion: bool,
}

pub struct UserDiscovery {
    config_path: PathBuf,
    key_manager: Arc<Mutex<KeyManager>>,
    rust_db: Arc<RwLock<Arc<Database>>>,
    config_lock: Arc<Mutex<()>>,
}

impl UserDiscovery {
    /// Refreshes server-owned data for announcements after the API connection
    /// has authenticated. Cryptographic discovery state remains owned here;
    /// the API runtime only invokes this lifecycle hook.
    pub async fn on_connected(&self, ctx: &Arc<Context>) -> Result<()> {
        let database = ctx.app_db.read().await.clone();
        let announcements = sqlx::query!(
            r#"SELECT announced_user_id, announced_public_key
               FROM user_discovery_announced_users WHERE username IS NULL"#
        )
        .fetch_all(&database.pool)
        .await?;

        for announcement in announcements {
            let user = match Server::get_user_by_id(ctx, announcement.announced_user_id).await? {
                ServerResult::Ok(user) => user,
                ServerResult::ErrorCode(code) => {
                    tracing::warn!(
                        user_id = announcement.announced_user_id,
                        code,
                        "could not refresh announced user"
                    );
                    continue;
                }
            };
            if user.public_identity_key.as_deref()
                != Some(announcement.announced_public_key.as_slice())
            {
                tracing::error!(
                    user_id = announcement.announced_user_id,
                    "server returned a different identity key for announced user"
                );
                continue;
            }
            let Some(username) = user.username else {
                continue;
            };

            let username = String::from_utf8(username)?;
            sqlx::query!(
                "UPDATE user_discovery_announced_users SET username = ? WHERE announced_user_id = ?",
                username,
                announcement.announced_user_id,
            )
            .execute(&database.pool)
            .await?;
        }
        database.notify_committed(["user_discovery_announced_users"]);
        Ok(())
    }
    pub fn new(
        data_dir: &str,
        key_manager: Arc<Mutex<KeyManager>>,
        rust_db: Arc<RwLock<Arc<Database>>>,
    ) -> Result<Self> {
        Ok(Self {
            config_path: PathBuf::from(data_dir).join("user_discovery_config.json"),
            key_manager,
            rust_db,
            config_lock: Arc::default(),
        })
    }

    pub async fn initialize_from_config(&self, ctx: &Context) -> Result<()> {
        let config = crate::user_config::UserConfig::load_required_from(ctx)?;

        if !config.is_user_discovery_enabled {
            return Ok(());
        }

        let discovery_config_path =
            PathBuf::from(&ctx.config.data_dir).join("user_discovery_config.json");

        let settings_are_current = std::fs::read_to_string(&discovery_config_path)
            .ok()
            .and_then(|value| serde_json::from_str::<serde_json::Value>(&value).ok())
            .is_some_and(|value| {
                value.get("threshold").and_then(serde_json::Value::as_u64)
                    == Some(u64::from(config.user_discovery_threshold))
                    && value
                        .get("share_promotion")
                        .and_then(serde_json::Value::as_bool)
                        == Some(config.user_discovery_share_promotion)
            });

        if settings_are_current {
            let database = ctx.app_db.read().await.clone();
            let has_shares =
                sqlx::query_scalar!("SELECT EXISTS(SELECT 1 FROM user_discovery_shares LIMIT 1)")
                    .fetch_one(&database.pool)
                    .await?
                    != 0;
            if has_shares {
                return Ok(());
            }
        }

        let key_manager = ctx.key_manager.lock().await;
        let user_id = key_manager.user_id.ok_or_else(|| {
            TwonlyError::Generic("cannot initialize user discovery without user ID".into())
        })?;
        let identity = key_manager
            .signal_identity
            .as_ref()
            .ok_or(TwonlyError::SignalIdentityNotFound)?;
        let identity = IdentityKeyPair::try_from(identity.identity_key_pair_structure.as_slice())
            .map_err(|error| {
            TwonlyError::Generic(format!("invalid Signal identity: {error}"))
        })?;
        let public_key = identity.identity_key().serialize().to_vec();
        drop(key_manager);

        let database = ctx.app_db.read().await.clone();
        let mut transaction = database.pool.begin().await?;
        self.initialize_or_update(
                config.user_discovery_threshold,
                user_id,
                public_key,
                config.user_discovery_share_promotion,
                &mut transaction,
            )
            .await?;
        transaction.commit().await?;
        database.notify_committed(["user_discovery_shares"]);
        Ok(())
    }

    async fn sign_data(&self, input_data: &[u8]) -> Result<Vec<u8>> {
        let key_manager = self.key_manager.lock().await;
        let identity = key_manager
            .signal_identity
            .as_ref()
            .ok_or_else(|| TwonlyError::UserDiscoveryStore("no Signal identity found".into()))?;
        let key_pair = IdentityKeyPair::try_from(identity.identity_key_pair_structure.as_slice())
            .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;
        let mut csprng = rand::rngs::StdRng::from_os_rng();
        key_pair
            .private_key()
            .calculate_signature_for_multipart_message(&[input_data], &mut csprng)
            .map(|signature| signature.to_vec())
            .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))
    }

    async fn verify_signature(
        &self,
        input_data: &[u8],
        public_key: &[u8],
        signature: &[u8],
    ) -> Result<bool> {
        let identity = match IdentityKey::decode(public_key) {
            Ok(identity) => identity,
            Err(_) => return Ok(false),
        };
        Ok(identity
            .public_key()
            .verify_signature(input_data, signature))
    }

    async fn verify_stored_pubkey(&self, contact_id: UserID, public_key: &[u8]) -> Result<bool> {
        let database = self.rust_db.read().await.clone();
        let stored = sqlx::query_scalar!(
            "SELECT identity_key FROM signal_identities WHERE name = ?",
            contact_id.to_string(),
        )
        .fetch_optional(&database.pool)
        .await
        .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;
        Ok(stored.as_deref() == Some(public_key))
    }

    /// Initializes or updates the user discovery.
    ///
    /// This function will generate new verification shares and update the config.
    ///
    /// # Arguments
    ///
    /// * `threshold` - The number of required shares to get the secret
    /// * `user_id` - The owner's user id
    /// * `public_key` - The owner's public key
    ///
    /// # Returns
    ///
    /// * `Ok(())` - If the user discovery was initialized or updated successfully
    /// * `Err(TwonlyError)` - If the user discovery was not initialized or updated successfully
    ///
    pub async fn initialize_or_update(
        &self,
        threshold: u8,
        user_id: UserID,
        public_key: Vec<u8>,
        share_promotion: bool,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<()> {
        tracing::info!("Protocols: initialize_or_update started, getting config from store");
        let config = match self.read_config() {
            Ok(config) => {
                let mut config: UserDiscoveryConfig = serde_json::from_str(&config)?;
                config.threshold = threshold;
                config
            }
            Err(_) => UserDiscoveryConfig {
                threshold,
                user_id,
                total_number_of_shares: 255,
                ..Default::default()
            },
        };

        let public_id = rand::random();

        let signed_data = SignedData {
            public_id,
            user_id,
            public_key,
        };

        tracing::info!("Protocols: signing data");
        let signature = self.sign_data(&signed_data.encode_to_vec()).await?;

        debug_assert_eq!(threshold, config.threshold);

        tracing::info!("Protocols: setting up announcements");
        let verification_shares = self
            .setup_announcements(&config, signed_data, signature, t)
            .await?;

        debug_assert_eq!(verification_shares.len(), threshold as usize - 1);

        tracing::info!("Protocols: updating config in store");

        {
            let mut final_config = match self.read_config() {
                Ok(c) => serde_json::from_str(&c)?,
                Err(_) => UserDiscoveryConfig {
                    threshold,
                    user_id,
                    ..Default::default()
                },
            };

            final_config.public_id = public_id;
            final_config.announcement_version += 1;
            final_config.verification_shares = verification_shares;
            final_config.share_promotion = share_promotion;
            final_config.threshold = threshold;

            self.write_config(&final_config)?;
        }

        tracing::info!("Protocols: initialize_or_update finished");
        Ok(())
    }

    ///
    /// Returns the current version of the owner's user discovery state.
    ///
    /// The version is incremented every time the user discovery is initialized or updated.
    /// It should be send contacts which participate in the user discovery, so they can
    /// check if there is new data available for them using the `get_new_messages` function
    /// on there side.  
    ///
    ///
    /// # Returns
    ///
    /// * `Ok(Vec<u8>)` - The current version of the user discovery
    /// * `Err(TwonlyError)` - If there where errors in the store.
    ///
    pub async fn get_current_version(&self) -> Result<Vec<u8>> {
        let config = self.get_config_snapshot().await?;
        Ok(UserDiscoveryVersion {
            announcement: config.announcement_version,
            promotion: config.promotion_version,
        }
        .encode_to_vec())
    }

    ///
    /// Returns all new user discovery messages for the provided contact and his current version.
    ///
    /// # Arguments
    ///
    /// * `contact_id` - The contact id of the user
    /// * `received_version` - The version of the user discovery the contact has received so far
    ///
    /// # Returns
    ///
    /// * `Ok(Vec<Vec<u8>>)` - The new user discovery messages
    /// * `Err(TwonlyError)` - If there where errors in the store or if the received version is invalid.
    ///
    pub async fn get_new_messages(
        &self,
        contact_id: UserID,
        received_version: &[u8],
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<Vec<Vec<u8>>> {
        let mut messages = vec![];
        let received_version = UserDiscoveryVersion::decode(received_version)?;
        let config = self.get_config_snapshot().await?;
        let version = Some(UserDiscoveryVersion {
            announcement: config.announcement_version,
            promotion: config.promotion_version,
        });

        if received_version.announcement < config.announcement_version {
            let announcement_share = if let Some(share) = sqlx::query_scalar!(
                "SELECT share FROM user_discovery_shares WHERE contact_id = ? LIMIT 1",
                contact_id,
            )
            .fetch_optional(&mut **t)
            .await
            .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?
            {
                share
            } else {
                let row = sqlx::query!(
                    "SELECT share_id, share FROM user_discovery_shares WHERE contact_id IS NULL LIMIT 1"
                )
                .fetch_optional(&mut **t)
                .await
                .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?
                .ok_or(TwonlyError::NoSharesLeft)?;
                sqlx::query!(
                    "UPDATE user_discovery_shares SET contact_id = ? WHERE share_id = ?",
                    contact_id,
                    row.share_id,
                )
                .execute(&mut **t)
                .await
                .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;
                row.share
            };

            messages.push(
                UserDiscoveryMessage {
                    user_discovery_announcement: Some(UserDiscoveryAnnouncement {
                        public_id: config.public_id,
                        threshold: config.threshold as u32,
                        announcement_share,
                        verification_shares: config.verification_shares.clone(),
                        share_promotion: config.share_promotion,
                    }),
                    version: version.clone(),
                    ..Default::default()
                }
                .encode_to_vec(),
            );
        }

        if received_version.promotion < config.promotion_version {
            let promoting_messages = sqlx::query_scalar!(
                "SELECT promotion FROM user_discovery_own_promotions WHERE version_id > ?",
                received_version.promotion,
            )
            .fetch_all(&mut **t)
            .await
            .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;
            let size = promoting_messages.len();
            let mut filtered: Vec<Vec<u8>> = promoting_messages
                .into_iter()
                .filter(|message| !message.is_empty())
                .collect();
            if filtered.len() != size {
                filtered.push(
                    UserDiscoveryMessage {
                        version,
                        ..Default::default()
                    }
                    .encode_to_vec(),
                );
            }
            messages.extend(filtered);
        }

        Ok(messages)
    }

    /// Returns the latest version for this discovery.
    /// Before calling this function the application must sure that contact_id is qualified to be announced.
    pub async fn handle_new_messages(
        &self,
        contact_id: UserID,
        public_key_verified_timestamp: Option<i64>,
        messages: Vec<Vec<u8>>,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<()> {
        for message in messages {
            let Ok(message) = UserDiscoveryMessage::decode(message.as_slice()) else {
                tracing::error!("Could not parse the message. Continue to the next message...");
                continue;
            };
            let Some(version) = message.version else {
                continue;
            };

            if let Some(uda) = message.user_discovery_announcement {
                if let Err(err) = self
                    .handle_user_discovery_announcement(
                        contact_id,
                        public_key_verified_timestamp,
                        uda,
                        t,
                    )
                    .await
                {
                    tracing::warn!("Ignoring: {err}");
                }
            } else if let Some(udp) = message.user_discovery_promotion {
                if let Err(err) = self
                    .handle_user_discovery_promotion(contact_id, udp, t)
                    .await
                {
                    tracing::warn!("Ignoring: {err}");
                }
            }

            // Always update the version...
            let version = version.encode_to_vec();
            sqlx::query!(
                "UPDATE contacts SET user_discovery_version = ? WHERE user_id = ?",
                version,
                contact_id,
            )
            .execute(&mut **t)
            .await
            .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;
        }

        Ok(())
    }

    pub async fn update_verification_state_for_user(
        &self,
        contact_id: UserID,
        public_key_verified_timestamp: Option<i64>,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<()> {
        let current_promotion = sqlx::query_scalar!(
            r#"SELECT promotion FROM user_discovery_own_promotions
               WHERE contact_id = ? ORDER BY version_id DESC LIMIT 1"#,
            contact_id,
        )
        .fetch_optional(&mut **t)
        .await
        .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;
        let Some(current_promotion) = current_promotion else {
            // User does not participate...
            return Ok(());
        };

        let old_message = UserDiscoveryMessage::decode(current_promotion.as_slice())?;

        let Some(old_promotion) = old_message.user_discovery_promotion else {
            tracing::error!("A contact should only have a promotion message...");
            return Ok(());
        };

        // Read-modify-write the config to get the new promotion_version
        let mut new_promotion_version = 0u32;
        let mut announcement_version = 0u32;
        self.read_modify_write_config(|config| {
            config.promotion_version += 1;
            new_promotion_version = config.promotion_version;
            announcement_version = config.announcement_version;
        })
        .await?;

        let message = UserDiscoveryMessage {
            version: Some(UserDiscoveryVersion {
                announcement: announcement_version,
                promotion: new_promotion_version,
            }),
            user_discovery_promotion: Some(UserDiscoveryPromotion {
                promotion_id: rand::random(),
                public_id: old_promotion.public_id,
                threshold: old_promotion.threshold,
                announcement_share: old_promotion.announcement_share,
                public_key_verified_timestamp,
            }),
            ..Default::default()
        };

        let promotion = message.encode_to_vec();
        sqlx::query!(
            "UPDATE user_discovery_own_promotions SET promotion = X'' WHERE contact_id = ?",
            contact_id,
        )
        .execute(&mut **t)
        .await
        .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;
        sqlx::query!(
            "INSERT INTO user_discovery_own_promotions(contact_id, promotion) VALUES (?, ?)",
            contact_id,
            promotion,
        )
        .execute(&mut **t)
        .await
        .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;

        Ok(())
    }

    async fn setup_announcements(
        &self,
        config: &UserDiscoveryConfig,
        signed_data: SignedData,
        signature: Vec<u8>,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<Vec<Vec<u8>>> {
        tracing::debug!(
            "Initializing user discovery with {} total shares and with a threshold of {}",
            config.total_number_of_shares,
            config.threshold
        );

        let encrypted_announcement = AnnouncementShareDecrypted {
            signed_data: Some(signed_data),
            signature,
        }
        .encode_to_vec();

        let sharks = Sharks(config.threshold);
        let dealer = sharks.dealer(&encrypted_announcement);

        let mut shares: Vec<Vec<u8>> = dealer
            .take(config.total_number_of_shares as usize)
            .map(|x| Vec::from(&x))
            .collect();

        if shares.len() != config.total_number_of_shares as usize
            || shares.is_empty()
            || shares.len() <= (config.threshold as usize * 2)
        {
            return Err(TwonlyError::ShamirsSecret(
                "Invalid length of shares where generated".to_string(),
            ));
        }

        tracing::debug!(
            "Generated {} shares each with a size of: {}",
            shares.len(),
            shares[0].len()
        );

        let mut verification_shares = vec![];

        let split_index = shares.len() - (config.threshold - 1) as usize;
        verification_shares.extend(shares.drain(split_index..));

        sqlx::query!("DELETE FROM user_discovery_shares")
            .execute(&mut **t)
            .await
            .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;
        for share in shares {
            sqlx::query!(
                "INSERT INTO user_discovery_shares (share) VALUES (?)",
                share
            )
            .execute(&mut **t)
            .await
            .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;
        }

        Ok(verification_shares)
    }

    /// Reads the config from the store without holding any lock.
    /// Use this for read-only access to the config.
    async fn get_config_snapshot(&self) -> Result<UserDiscoveryConfig> {
        Ok(serde_json::from_str(&self.read_config()?)?)
    }

    fn read_config(&self) -> Result<String> {
        if !self.config_path.is_file() {
            return Err(TwonlyError::UserDiscoveryNotInitialized);
        }
        Ok(std::fs::read_to_string(&self.config_path)?)
    }

    fn write_config(&self, config: &UserDiscoveryConfig) -> Result<()> {
        std::fs::write(&self.config_path, serde_json::to_string_pretty(config)?)?;
        Ok(())
    }

    /// Atomically reads the config, applies the mutation, and writes it back.
    /// The config_lock is only held during the read-modify-write cycle,
    /// NOT across any async Dart callbacks from the caller.
    async fn read_modify_write_config<F>(&self, mutate: F) -> Result<()>
    where
        F: FnOnce(&mut UserDiscoveryConfig),
    {
        let _lock =
            tokio::time::timeout(std::time::Duration::from_secs(10), self.config_lock.lock())
                .await
                .ok();
        let mut config: UserDiscoveryConfig = serde_json::from_str(&self.read_config()?)?;
        mutate(&mut config);
        self.write_config(&config)?;
        Ok(())
    }

    async fn handle_user_discovery_announcement(
        &self,
        contact_id: UserID,
        public_key_verified_timestamp: Option<i64>,
        uda: UserDiscoveryAnnouncement,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<()> {
        tracing::info!("Got a user discovery announcement from {contact_id}.");

        if uda.threshold as usize != uda.verification_shares.len() + 1 {
            tracing::error!(
                "UDA contains to few shares to verify: {} != {} + 1.",
                uda.threshold,
                uda.verification_shares.len(),
            );
            return Ok(());
        }

        let sharks = Sharks(uda.threshold as u8);

        let mut all_shares = uda.verification_shares.clone();
        all_shares.push(uda.announcement_share.clone());
        let shares: Vec<_> = all_shares
            .iter()
            .filter_map(|x| Share::try_from(x.as_slice()).ok())
            .collect();

        match sharks.recover(&shares) {
            Ok(secret) => {
                let asd = AnnouncementShareDecrypted::decode(secret.as_slice())?;

                let Some(signed_data) = asd.signed_data else {
                    return Err(TwonlyError::MaliciousAnnouncementData(
                        "missing signed data".into(),
                    ));
                };

                if contact_id != signed_data.user_id {
                    return Err(TwonlyError::MaliciousAnnouncementData(format!(
                        "contact_id ({contact_id}) != signed_data.user_id ({})",
                        signed_data.user_id
                    )));
                }

                if !self
                    .verify_stored_pubkey(contact_id, &signed_data.public_key)
                    .await?
                {
                    return Err(TwonlyError::MaliciousAnnouncementData(
                        "public key does not match with stored one".to_string(),
                    ));
                }

                if !self
                    .verify_signature(
                        &signed_data.encode_to_vec(),
                        &signed_data.public_key,
                        &asd.signature,
                    )
                    .await?
                {
                    return Err(TwonlyError::MaliciousAnnouncementData(
                        "signature invalid".to_string(),
                    ));
                }

                // Only add this user to the promotions if the users enabled this feature
                if uda.share_promotion {
                    // Read-modify-write the config to get the new promotion_version
                    let mut new_promotion_version = 0u32;
                    let mut announcement_version = 0u32;
                    self.read_modify_write_config(|config| {
                        config.promotion_version += 1;
                        new_promotion_version = config.promotion_version;
                        announcement_version = config.announcement_version;
                    })
                    .await?;

                    let message = UserDiscoveryMessage {
                        version: Some(UserDiscoveryVersion {
                            announcement: announcement_version,
                            promotion: new_promotion_version,
                        }),
                        user_discovery_promotion: Some(UserDiscoveryPromotion {
                            promotion_id: rand::random(),
                            public_id: signed_data.public_id,
                            threshold: uda.threshold,
                            announcement_share: uda.announcement_share,
                            public_key_verified_timestamp,
                        }),
                        ..Default::default()
                    };

                    let promotion = message.encode_to_vec();
                    sqlx::query!(
                        "UPDATE user_discovery_own_promotions SET promotion = X'' WHERE contact_id = ?",
                        contact_id,
                    )
                    .execute(&mut **t)
                    .await
                    .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;
                    sqlx::query!(
                        "INSERT INTO user_discovery_own_promotions(contact_id, promotion) VALUES (?, ?)",
                        contact_id,
                        promotion,
                    )
                    .execute(&mut **t)
                    .await
                    .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;
                }

                let announced_user = AnnouncedUser {
                    user_id: signed_data.user_id,
                    public_key: signed_data.public_key,
                    public_id: uda.public_id,
                };

                tracing::debug!(
                    "NEW PROMOTION 3: {} knows {}",
                    contact_id,
                    announced_user.user_id
                );

                // User is known, so add him to thr users relations
                self.push_new_user_relation(
                    contact_id,
                    announced_user.clone(),
                    public_key_verified_timestamp,
                    t,
                )
                .await?;

                // As we no now the public_id from the user, all promotions up to this point are also known, so add these to the relations database as well
                let promotions = self
                    .get_other_promotions_by_public_id(uda.public_id, t)
                    .await?;

                for promotion in promotions {
                    self.push_new_user_relation(
                        promotion.from_contact_id,
                        announced_user.clone(),
                        promotion.public_key_verified_timestamp,
                        t,
                    )
                    .await?;
                }

                Ok(())
            }
            Err(err) => Err(TwonlyError::ShamirsSecret(err.to_string())),
        }
    }

    async fn handle_user_discovery_promotion(
        &self,
        from_contact_id: UserID,
        udp: UserDiscoveryPromotion,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<()> {
        tracing::debug!("Received a new UDP with public_id = {}.", &udp.public_id);

        if udp.announcement_share.is_empty() {
            tracing::info!("Got empty announcement share. Ignoring it..");
            return Ok(());
        }

        self.store_other_promotion(
            OtherPromotion {
                from_contact_id,
                promotion_id: udp.promotion_id,
                threshold: udp.threshold as u8,
                public_id: udp.public_id,
                announcement_share: udp.announcement_share,
                public_key_verified_timestamp: udp.public_key_verified_timestamp,
            },
            t,
        )
        .await?;

        if let Some(contact) = self
            .get_announced_user_by_public_id(udp.public_id, t)
            .await?
        {
            tracing::debug!(
                "NEW PROMOTION 2: {} knows {}",
                from_contact_id,
                contact.user_id
            );
            // The user is already known, just propagate the relation ship
            self.push_new_user_relation(
                from_contact_id,
                contact,
                udp.public_key_verified_timestamp,
                t,
            )
            .await?;
            return Ok(());
        }

        let promotions = self
            .get_other_promotions_by_public_id(udp.public_id, t)
            .await?;

        // Deduplicate shares by their raw bytes to prevent invalid Shamir's Secret Sharing recoveries.
        // Multiple identical shares (e.g. due to contact resending promotions, or DB duplicate writes)
        // will cause `recover` to interpolate incorrectly and return garbage bytes.
        let mut unique_shares_set = HashSet::new();
        let mut unique_promotions = Vec::new();
        for p in promotions {
            if unique_shares_set.insert(p.announcement_share.clone()) {
                unique_promotions.push(p);
            }
        }

        if unique_promotions.len() < udp.threshold as usize {
            tracing::debug!(
                "Not enough unique shares ({} < {}) to decrypt announcement. Waiting for next share.",
                unique_promotions.len(),
                udp.threshold
            );
            return Ok(());
        }

        tracing::debug!("Enough shares decrypting announcement.");

        let shares: Vec<_> = unique_promotions
            .iter()
            .map(|x| x.announcement_share.to_owned())
            .filter_map(|x| Share::try_from(x.as_slice()).ok())
            .collect();

        match Sharks(udp.threshold as u8).recover(&shares) {
            Ok(secret) => {
                tracing::debug!("Could decrypt announcement.");
                let asd = AnnouncementShareDecrypted::decode(secret.as_slice())?;
                if let Some(signed_data) = asd.signed_data {
                    if udp.public_id != signed_data.public_id {
                        tracing::error!(
                            "Mismatch of the announced public id and the signed public id "
                        );
                        return Ok(());
                    }

                    if !self
                        .verify_signature(
                            &signed_data.encode_to_vec(),
                            &signed_data.public_key,
                            &asd.signature,
                        )
                        .await?
                    {
                        return Err(TwonlyError::MaliciousAnnouncementData(
                            "signature is invalid".to_string(),
                        ));
                    }

                    tracing::debug!("Announcement valid.");

                    let announced_user = AnnouncedUser {
                        user_id: signed_data.user_id,
                        public_key: signed_data.public_key,
                        public_id: udp.public_id,
                    };

                    let config = self.get_config_snapshot().await?;

                    let user_id = config.user_id;
                    for promotion in unique_promotions {
                        // Do not store the announcement of the users itself.
                        // Or in case the promotion promotes myself
                        if promotion.from_contact_id == announced_user.user_id
                            || announced_user.user_id == user_id
                        {
                            continue;
                        }
                        tracing::debug!(
                            "NEW PROMOTION: {:x} knows {:x}",
                            promotion.from_contact_id,
                            announced_user.user_id
                        );
                        self.push_new_user_relation(
                            promotion.from_contact_id,
                            announced_user.clone(),
                            promotion.public_key_verified_timestamp,
                            t,
                        )
                        .await?;
                    }
                }
                Ok(())
            }
            Err(err) => Err(TwonlyError::ShamirsSecret(err.to_string())),
        }
    }

    async fn store_other_promotion(
        &self,
        promotion: OtherPromotion,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<()> {
        sqlx::query!(
            r#"
            INSERT INTO user_discovery_other_promotions (
                from_contact_id, promotion_id, public_id, threshold,
                announcement_share, public_key_verified_timestamp
            ) VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(from_contact_id, public_id) DO UPDATE SET
                promotion_id = excluded.promotion_id,
                threshold = excluded.threshold,
                announcement_share = excluded.announcement_share,
                public_key_verified_timestamp = excluded.public_key_verified_timestamp
            "#,
            promotion.from_contact_id,
            promotion.promotion_id,
            promotion.public_id,
            promotion.threshold,
            promotion.announcement_share,
            promotion.public_key_verified_timestamp,
        )
        .execute(&mut **t)
        .await
        .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;
        Ok(())
    }

    async fn get_announced_user_by_public_id(
        &self,
        public_id: i64,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<Option<AnnouncedUser>> {
        let row = sqlx::query!(
            r#"
            SELECT announced_user_id, announced_public_key, public_id
            FROM user_discovery_announced_users
            WHERE public_id = ?
            "#,
            public_id,
        )
        .fetch_optional(&mut **t)
        .await
        .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;
        Ok(row.map(|row| AnnouncedUser {
            user_id: row.announced_user_id,
            public_key: row.announced_public_key,
            public_id: row.public_id,
        }))
    }

    async fn get_other_promotions_by_public_id(
        &self,
        public_id: i64,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<Vec<OtherPromotion>> {
        let rows = sqlx::query!(
            r#"
            SELECT promotion_id, public_id, from_contact_id, threshold,
                   announcement_share, public_key_verified_timestamp
            FROM user_discovery_other_promotions
            WHERE public_id = ?
            "#,
            public_id,
        )
        .fetch_all(&mut **t)
        .await
        .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;
        rows.into_iter()
            .map(|row| {
                Ok(OtherPromotion {
                    promotion_id: u32::try_from(row.promotion_id)
                        .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?,
                    public_id: row.public_id,
                    from_contact_id: row.from_contact_id,
                    threshold: u8::try_from(row.threshold)
                        .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?,
                    announcement_share: row.announcement_share,
                    public_key_verified_timestamp: row.public_key_verified_timestamp,
                })
            })
            .collect()
    }

    async fn push_new_user_relation(
        &self,
        from_contact_id: UserID,
        announced_user: AnnouncedUser,
        public_key_verified_timestamp: Option<i64>,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<()> {
        sqlx::query!(
            r#"
            INSERT INTO user_discovery_announced_users (
                announced_user_id, announced_public_key, public_id
            ) VALUES (?, ?, ?)
            ON CONFLICT DO UPDATE SET
                announced_user_id = excluded.announced_user_id,
                announced_public_key = excluded.announced_public_key,
                public_id = excluded.public_id
            "#,
            announced_user.user_id,
            announced_user.public_key,
            announced_user.public_id,
        )
        .execute(&mut **t)
        .await
        .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;
        sqlx::query!(
            r#"
            INSERT INTO user_discovery_user_relations (
                announced_user_id, from_contact_id, public_key_verified_timestamp
            ) VALUES (?, ?, ?)
            ON CONFLICT(announced_user_id, from_contact_id) DO UPDATE SET
                public_key_verified_timestamp = excluded.public_key_verified_timestamp
            "#,
            announced_user.user_id,
            from_contact_id,
            public_key_verified_timestamp,
        )
        .execute(&mut **t)
        .await
        .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;
        Ok(())
    }
}

impl Default for UserDiscoveryConfig {
    fn default() -> Self {
        Self {
            threshold: 2,
            total_number_of_shares: 255,
            announcement_version: 0,
            promotion_version: 0,
            verification_shares: vec![],
            public_id: 0,
            share_promotion: true,
            user_id: 0,
        }
    }
}
