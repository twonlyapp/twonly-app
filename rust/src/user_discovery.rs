/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use std::collections::HashSet;
use crate::api::server::Server;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::database::app::contacts::table::Contact;
use crate::database::app::AppDatabase;
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
use crate::user_config::MIN_USER_DISCOVERY_THRESHOLD;
use crate::user_discovery::user_discovery_message::{UserDiscoveryAnnouncement, UserDiscoveryPromotion};
use crate::user_discovery::user_discovery_message::user_discovery_promotion::AnnouncementShareDecrypted;
use crate::user_discovery::user_discovery_message::user_discovery_promotion::announcement_share_decrypted::SignedData;

/// Type of the user id, this must be consistent with the user id defined in
/// the types.proto
pub type UserID = i64;

fn is_supported_threshold(threshold: u32) -> bool {
    (u32::from(MIN_USER_DISCOVERY_THRESHOLD)..=u32::from(u8::MAX)).contains(&threshold)
}

const CONFIG_KEY: &str = "user_discovery_config";

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
    database_dir: PathBuf,
    key_manager: Arc<Mutex<KeyManager>>,
    rust_db: Arc<RwLock<Arc<Database>>>,
    app_db: Arc<RwLock<Arc<AppDatabase>>>,
}

impl UserDiscovery {
    /// Refreshes server-owned data for announcements after the API connection
    /// has authenticated. Cryptographic discovery state remains owned here;
    /// the API runtime only invokes this lifecycle hook.
    pub async fn on_connected(&self, ctx: &Arc<Context>) -> Result<()> {
        let database = ctx.app_db.read().await.clone();

        // A deleted account never gets a username, so without its mark it
        // would be asked about on every connection, forever.
        let announcements = sqlx::query!(
            r#"SELECT announced_user_id, announced_public_key
               FROM user_discovery_announced_users
               WHERE username IS NULL AND account_deleted = 0"#
        )
        .fetch_all(&database.pool)
        .await?;

        for announcement in announcements {
            let user = match Server::get_user_by_id(ctx, announcement.announced_user_id).await? {
                ServerResult::Ok(user) => user,
                // The API error handler has already marked the account.
                ServerResult::ErrorCode(code)
                    if code == crate::api::proto::error::ErrorCode::UserIdNotFound as i32 =>
                {
                    continue;
                }
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
                tracing::warn!(
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
                "UPDATE user_discovery_announced_users SET username = ? WHERE announced_user_id = \
                 ?",
                username,
                announcement.announced_user_id,
            )
            .execute(&database.pool)
            .await?;
        }

        Ok(())
    }

    pub fn new(
        data_dir: &str, database_dir: &str, key_manager: Arc<Mutex<KeyManager>>,
        rust_db: Arc<RwLock<Arc<Database>>>, app_db: Arc<RwLock<Arc<AppDatabase>>>,
    ) -> Result<Self> {
        Ok(Self {
            config_path: PathBuf::from(data_dir).join("user_discovery_config.json"),
            database_dir: PathBuf::from(database_dir),
            key_manager,
            rust_db,
            app_db,
        })
    }

    pub async fn initialize_from_config(&self, ctx: &Context) -> Result<()> {
        self.refresh_session_identities(ctx).await?;

        let config = crate::user_config::UserConfig::load_required_from(ctx)?;

        if !config.is_user_discovery_enabled {
            return Ok(());
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

        let stored = Self::read_config(&mut transaction).await?;
        // Legacy JSON and SQLite were committed separately. Regenerate rather
        // than importing a possibly mismatched generation, preserving versions
        // so peers will actually request its replacement.
        let mut previous = match stored.clone() {
            Some(config) => config,
            None => self.read_legacy_config()?.unwrap_or_default(),
        };
        let last_promotion: i64 = sqlx::query_scalar(
            "SELECT COALESCE(MAX(version_id), 0) FROM user_discovery_own_promotions",
        )
        .fetch_one(&mut *transaction)
        .await?;
        previous.promotion_version = previous.promotion_version.max(
            u32::try_from(last_promotion)
                .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?,
        );
        // Loading user.json clamps legacy values in memory; persist that
        // normalization as part of the one-time discovery upgrade as well.
        if stored.is_none() || previous.threshold < MIN_USER_DISCOVERY_THRESHOLD {
            crate::user_config::UserConfig::update(ctx, |config| {
                config.user_discovery_threshold = config
                    .user_discovery_threshold
                    .max(MIN_USER_DISCOVERY_THRESHOLD);
            })?;
        }
        let current = stored.is_some()
            && previous.threshold == config.user_discovery_threshold
            && previous.share_promotion == config.user_discovery_share_promotion
            && self
                .generation_is_consistent(&previous, user_id, &public_key, &mut transaction)
                .await?;
        if !current {
            Self::write_config(&previous, &mut transaction).await?;
            self.initialize_or_update(
                config.user_discovery_threshold,
                user_id,
                public_key,
                config.user_discovery_share_promotion,
                &mut transaction,
            )
            .await?;
        }
        self.retire_unsupported_promotions(&mut transaction).await?;

        transaction.commit().await?;

        self.refresh_verification_policy(ctx).await
    }

    /// Publish corrections for personal claims emitted by older versions.
    /// This also advances the discovery version so peers request revocations.
    async fn refresh_verification_policy(&self, ctx: &Context) -> Result<()> {
        let database = ctx.app_db.read().await.clone();
        let mut transaction = database.pool.begin().await?;

        let pending = sqlx::query_scalar!(
            "SELECT EXISTS(SELECT 1 FROM app_metadata WHERE key = 'verification_policy_refresh')",
        )
        .fetch_one(&mut *transaction)
        .await?
            != 0;

        if pending {
            let contacts = sqlx::query_scalar!(
                "SELECT DISTINCT contact_id FROM user_discovery_own_promotions WHERE promotion != X''",
            )
            .fetch_all(&mut *transaction)
            .await?;

            for contact in contacts {
                self.update_verification_state_for_user(contact, None, &mut transaction)
                    .await?;
            }

            sqlx::query!("DELETE FROM app_metadata WHERE key = 'verification_policy_refresh'")
                .execute(&mut *transaction)
                .await?;
        }

        transaction.commit().await?;

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
        &self, input_data: &[u8], public_key: &[u8], signature: &[u8],
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

    /// Claims about another key remain stored but cannot verify this session.
    /// This snapshot lets all app queries use the same key comparison without
    /// attaching the separate, encrypted Signal database to every connection.
    pub(crate) async fn refresh_session_identity(
        &self, contact_id: UserID, t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<()> {
        let announced: bool = sqlx::query_scalar(
            "SELECT EXISTS(SELECT 1 FROM user_discovery_announced_users WHERE announced_user_id = ?)",
        )
        .bind(contact_id)
        .fetch_one(&mut **t)
        .await?;
        if !announced {
            return Ok(());
        }

        let database = self.rust_db.read().await.clone();
        let identity: Option<Vec<u8>> =
            sqlx::query_scalar("SELECT identity_key FROM signal_identities WHERE name = ?")
                .bind(contact_id.to_string())
                .fetch_optional(&database.pool)
                .await?;

        sqlx::query(
            "UPDATE user_discovery_announced_users SET session_identity_key = ?
             WHERE announced_user_id = ? AND session_identity_key IS NOT ?",
        )
        .bind(&identity)
        .bind(contact_id)
        .bind(&identity)
        .execute(&mut **t)
        .await?;

        Ok(())
    }

    async fn refresh_session_identities(&self, ctx: &Context) -> Result<()> {
        let database = ctx.app_db.read().await.clone();
        let mut transaction = database.pool.begin().await?;
        let contacts: Vec<i64> =
            sqlx::query_scalar("SELECT announced_user_id FROM user_discovery_announced_users")
                .fetch_all(&mut *transaction)
                .await?;
        for contact_id in contacts {
            self.refresh_session_identity(contact_id, &mut transaction)
                .await?;
        }
        transaction.commit().await?;
        Ok(())
    }

    /// Initializes or updates the user discovery.
    ///
    /// This function will generate new verification shares and update the
    /// config.
    ///
    /// # Arguments
    ///
    /// * `threshold` - The number of required shares to get the secret
    /// * `user_id` - The owner's user id
    /// * `public_key` - The owner's public key
    ///
    /// # Returns
    ///
    /// * `Ok(())` - If the user discovery was initialized or updated
    ///   successfully
    /// * `Err(TwonlyError)` - If the user discovery was not initialized or
    ///   updated successfully
    pub async fn initialize_or_update(
        &self, threshold: u8, user_id: UserID, public_key: Vec<u8>, share_promotion: bool,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<()> {
        if threshold < MIN_USER_DISCOVERY_THRESHOLD {
            return Err(TwonlyError::UserDiscoveryStore(format!(
                "user discovery threshold must be at least {MIN_USER_DISCOVERY_THRESHOLD}"
            )));
        }

        tracing::info!("Protocols: initialize_or_update started, getting config from store");

        let mut config = Self::read_config(t).await?.unwrap_or_default();
        config.threshold = threshold;
        config.user_id = user_id;

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

        config.public_id = public_id;
        config.announcement_version += 1;
        config.verification_shares = verification_shares;
        config.share_promotion = share_promotion;
        Self::write_config(&config, t).await?;

        tracing::info!("Protocols: initialize_or_update finished");

        Ok(())
    }

    ///
    /// Returns the current version of the owner's user discovery state.
    ///
    /// The version is incremented every time the user discovery is initialized
    /// or updated. It should be send contacts which participate in the user
    /// discovery, so they can check if there is new data available for them
    /// using the `get_new_messages` function on there side.  
    ///
    ///
    /// # Returns
    ///
    /// * `Ok(Vec<u8>)` - The current version of the user discovery
    /// * `Err(TwonlyError)` - If there where errors in the store.
    pub async fn get_current_version(&self) -> Result<Vec<u8>> {
        let database = self.app_db.read().await.clone();
        Self::get_current_version_in(&mut *database.pool.acquire().await?).await
    }

    pub(crate) async fn get_current_version_in(
        connection: &mut sqlx::SqliteConnection,
    ) -> Result<Vec<u8>> {
        let config = Self::read_config(connection)
            .await?
            .ok_or(TwonlyError::UserDiscoveryNotInitialized)?;
        Ok(UserDiscoveryVersion {
            announcement: config.announcement_version,
            promotion: config.promotion_version,
        }
        .encode_to_vec())
    }

    ///
    /// Returns all new user discovery messages for the provided contact and his
    /// current version.
    ///
    /// # Arguments
    ///
    /// * `contact_id` - The contact id of the user
    /// * `received_version` - The version of the user discovery the contact has
    ///   received so far
    ///
    /// # Returns
    ///
    /// * `Ok(Vec<Vec<u8>>)` - The new user discovery messages
    /// * `Err(TwonlyError)` - If there where errors in the store or if the
    ///   received version is invalid.
    pub async fn get_new_messages(
        &self, ctx: &Context, contact_id: UserID, received_version: &[u8],
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<Vec<Vec<u8>>> {
        let mut messages = vec![];

        let received_version = UserDiscoveryVersion::decode(received_version)?;

        let config = Self::read_config(t)
            .await?
            .ok_or(TwonlyError::UserDiscoveryNotInitialized)?;

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
                    "SELECT share_id, share FROM user_discovery_shares WHERE contact_id IS NULL \
                     LIMIT 1"
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
                    version,
                    ..Default::default()
                }
                .encode_to_vec(),
            );
        }

        if received_version.promotion < config.promotion_version {
            let promoting_messages = sqlx::query!(
                "SELECT contact_id, promotion FROM user_discovery_own_promotions WHERE version_id > ?",
                received_version.promotion,
            )
            .fetch_all(&mut **t)
            .await
            .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;

            let size = promoting_messages.len();

            let mut filtered = Vec::new();

            for row in promoting_messages {
                // A promotion vouches for the contact it names. One blocked,
                // removed or excluded since it was made is not passed on.
                if row.promotion.is_empty()
                    || !Contact::is_user_discovery_allowed(ctx, t, row.contact_id).await?
                {
                    continue;
                }

                let Ok(mut message) = UserDiscoveryMessage::decode(row.promotion.as_slice()) else {
                    continue;
                };

                if let Some(promotion) = message.user_discovery_promotion.as_mut() {
                    if !is_supported_threshold(promotion.threshold) {
                        continue;
                    }
                    // Older builds also advertised inherited claims. Derive
                    // the assertion from current personal evidence every time
                    // it leaves this device, including after a restoration.
                    promotion.public_key_verified_timestamp =
                        crate::database::app::key_verifications::queries::direct_verified_at(
                            t,
                            row.contact_id,
                        )
                        .await?;
                }

                filtered.push(message.encode_to_vec());
            }

            let last_version = filtered
                .last()
                .and_then(|bytes| UserDiscoveryMessage::decode(bytes.as_slice()).ok())
                .and_then(|message| message.version);
            if filtered.len() != size || last_version != version {
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
    /// Before calling this function the application must sure that contact_id
    /// is qualified to be announced.
    pub async fn handle_new_messages(
        &self, contact_id: UserID, public_key_verified_timestamp: Option<i64>,
        messages: Vec<Vec<u8>>, t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<()> {
        let stored = sqlx::query_scalar!(
            "SELECT user_discovery_version FROM contacts WHERE user_id = ?",
            contact_id,
        )
        .fetch_optional(&mut **t)
        .await?
        .flatten();
        let initial = stored
            .as_deref()
            .map(UserDiscoveryVersion::decode)
            .transpose()?
            .unwrap_or_default();
        let mut received = initial;
        let mut announcement_failed = false;
        let mut promotion_failed = false;
        for message in messages {
            let Ok(message) = UserDiscoveryMessage::decode(message.as_slice()) else {
                announcement_failed = true;
                promotion_failed = true;
                tracing::warn!(
                    "Could not parse the discovery message; leaving its version retryable"
                );
                continue;
            };
            let Some(version) = message.version else {
                continue;
            };
            if let Some(uda) = message.user_discovery_announcement {
                if let Err(error) = self
                    .handle_user_discovery_announcement(
                        contact_id,
                        public_key_verified_timestamp,
                        uda,
                        t,
                    )
                    .await
                {
                    announcement_failed = true;
                    tracing::warn!("Ignoring: {error}");
                }
            } else if let Some(udp) = message.user_discovery_promotion {
                if let Err(error) = self
                    .handle_user_discovery_promotion(contact_id, udp, t)
                    .await
                {
                    promotion_failed = true;
                    tracing::warn!("Ignoring: {error}");
                }
            }
            received.announcement = if announcement_failed {
                initial.announcement
            } else {
                received.announcement.max(version.announcement)
            };
            received.promotion = if promotion_failed {
                initial.promotion
            } else {
                received.promotion.max(version.promotion)
            };
        }
        if announcement_failed {
            received.announcement = initial.announcement;
        }
        if promotion_failed {
            received.promotion = initial.promotion;
        }
        let version = received.encode_to_vec();
        sqlx::query!(
            "UPDATE contacts SET user_discovery_version = ? WHERE user_id = ?",
            version,
            contact_id,
        )
        .execute(&mut **t)
        .await?;

        Ok(())
    }

    pub async fn update_verification_state_for_user(
        &self, contact_id: UserID, public_key_verified_timestamp: Option<i64>,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<()> {
        // Callers cannot promote inherited evidence into a personal claim.
        let _ = public_key_verified_timestamp;

        let public_key_verified_timestamp =
            crate::database::app::key_verifications::queries::direct_verified_at(t, contact_id)
                .await?;

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
            tracing::warn!("A contact should only have a promotion message...");

            return Ok(());
        };

        if !is_supported_threshold(old_promotion.threshold) {
            self.retire_unsupported_promotions(t).await?;
            return Ok(());
        }

        let config = Self::advance_promotion_version(t).await?;
        let new_promotion_version = config.promotion_version;
        let announcement_version = config.announcement_version;

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
            "INSERT INTO user_discovery_own_promotions(version_id, contact_id, promotion) VALUES (?, ?, ?)",
            new_promotion_version,
            contact_id,
            promotion,
        )
        .execute(&mut **t)
        .await
        .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;

        Ok(())
    }

    async fn setup_announcements(
        &self, config: &UserDiscoveryConfig, signed_data: SignedData, signature: Vec<u8>,
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

        // `WHERE 1` is load-bearing: without a WHERE clause SQLite takes the
        // truncate optimization, which drops every row without ever invoking
        // the update hook the change stream is built on, so the UI would never
        // learn the shares were replaced.
        sqlx::query!("DELETE FROM user_discovery_shares WHERE 1")
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

    #[cfg(test)]
    async fn get_config_snapshot(&self) -> Result<UserDiscoveryConfig> {
        let database = self.app_db.read().await.clone();
        Self::read_config(&mut *database.pool.acquire().await?)
            .await?
            .ok_or(TwonlyError::UserDiscoveryNotInitialized)
    }

    async fn read_config(
        connection: &mut sqlx::SqliteConnection,
    ) -> Result<Option<UserDiscoveryConfig>> {
        let config: Option<String> =
            sqlx::query_scalar("SELECT value FROM app_metadata WHERE key = ?")
                .bind(CONFIG_KEY)
                .fetch_optional(connection)
                .await?;
        config
            .map(|json| serde_json::from_str(&json).map_err(Into::into))
            .transpose()
    }

    // Used only for the one-time upgrade. SQLite is authoritative thereafter,
    // including after a backup restore; stale JSON must never overwrite it.
    fn read_legacy_config(&self) -> Result<Option<UserDiscoveryConfig>> {
        let _store = crate::database::maintenance::settings_access(&self.database_dir)?;
        match std::fs::read_to_string(&self.config_path) {
            Ok(json) => Ok(serde_json::from_str(&json).ok()),
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(None),
            Err(error) => Err(error.into()),
        }
    }

    async fn write_config(
        config: &UserDiscoveryConfig, connection: &mut sqlx::SqliteConnection,
    ) -> Result<()> {
        sqlx::query(
            "INSERT INTO app_metadata(key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value",
        )
        .bind(CONFIG_KEY)
        .bind(serde_json::to_string(config)?)
        .execute(connection)
        .await?;
        Ok(())
    }

    async fn advance_promotion_version(
        connection: &mut sqlx::SqliteConnection,
    ) -> Result<UserDiscoveryConfig> {
        let mut config = Self::read_config(connection)
            .await?
            .ok_or(TwonlyError::UserDiscoveryNotInitialized)?;
        let last: i64 = sqlx::query_scalar(
            "SELECT COALESCE(MAX(version_id), 0) FROM user_discovery_own_promotions",
        )
        .fetch_one(&mut *connection)
        .await?;
        let last = u32::try_from(last)
            .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;
        config.promotion_version = config
            .promotion_version
            .max(last)
            .checked_add(1)
            .ok_or_else(|| TwonlyError::UserDiscoveryStore("promotion version exhausted".into()))?;
        Self::write_config(&config, connection).await?;
        Ok(config)
    }

    /// Every assigned share must reconstruct the same signed announcement.
    /// Checking existence or length alone cannot detect mixed generations.
    async fn generation_is_consistent(
        &self, config: &UserDiscoveryConfig, user_id: UserID, public_key: &[u8],
        connection: &mut sqlx::SqliteConnection,
    ) -> Result<bool> {
        if !is_supported_threshold(u32::from(config.threshold))
            || config.user_id != user_id
            || config.verification_shares.len() + 1 != usize::from(config.threshold)
        {
            return Ok(false);
        }
        let shares: Vec<Vec<u8>> = sqlx::query_scalar("SELECT share FROM user_discovery_shares")
            .fetch_all(connection)
            .await?;
        if shares.is_empty()
            || shares.len() + config.verification_shares.len()
                != usize::from(config.total_number_of_shares)
        {
            return Ok(false);
        }
        let mut verification = Vec::new();
        let mut coordinates = HashSet::new();
        for bytes in &config.verification_shares {
            if !coordinates.insert(bytes.first().copied()) {
                return Ok(false);
            }
            let Ok(share) = Share::try_from(bytes.as_slice()) else {
                return Ok(false);
            };
            verification.push(share);
        }
        let mut expected = None;
        let sharks = Sharks(config.threshold);
        for bytes in &shares {
            if !coordinates.insert(bytes.first().copied()) {
                return Ok(false);
            }
            let Ok(share) = Share::try_from(bytes.as_slice()) else {
                return Ok(false);
            };
            verification.push(share);
            let recovered = sharks.recover(&verification);
            verification.pop();
            let Ok(secret) = recovered else {
                return Ok(false);
            };
            if let Some(expected) = &expected {
                if expected != &secret {
                    return Ok(false);
                }
            } else {
                let Ok(announcement) = AnnouncementShareDecrypted::decode(secret.as_slice()) else {
                    return Ok(false);
                };
                let Some(data) = announcement.signed_data else {
                    return Ok(false);
                };
                if data.public_id != config.public_id
                    || data.user_id != user_id
                    || data.public_key != public_key
                    || !self
                        .verify_signature(
                            &data.encode_to_vec(),
                            public_key,
                            &announcement.signature,
                        )
                        .await?
                {
                    return Ok(false);
                }
                expected = Some(secret);
            }
        }
        Ok(true)
    }

    /// Remove legacy relays too: upgrading our own threshold does not rewrite
    /// cached announcements made by other people.
    async fn retire_unsupported_promotions(
        &self, connection: &mut sqlx::SqliteConnection,
    ) -> Result<()> {
        let cached: Vec<(i64, i64, Vec<u8>)> = sqlx::query_as(
            "SELECT version_id, contact_id, promotion FROM user_discovery_own_promotions WHERE promotion != X''",
        ).fetch_all(&mut *connection).await?;
        let mut changed = false;
        for (version, contact, bytes) in cached {
            let supported = UserDiscoveryMessage::decode(bytes.as_slice())
                .ok()
                .and_then(|message| message.user_discovery_promotion)
                .is_some_and(|promotion| is_supported_threshold(promotion.threshold));
            if supported {
                continue;
            }
            sqlx::query(
                "UPDATE user_discovery_own_promotions SET promotion = X'' WHERE version_id = ?",
            )
            .bind(version)
            .execute(&mut *connection)
            .await?;
            // Ask the author again on the next exchange, even when we already
            // recorded the version containing the obsolete announcement.
            sqlx::query("UPDATE contacts SET user_discovery_version = NULL WHERE user_id = ?")
                .bind(contact)
                .execute(&mut *connection)
                .await?;
            changed = true;
        }
        sqlx::query(
            "DELETE FROM user_discovery_other_promotions WHERE threshold < ? OR threshold > ?",
        )
        .bind(MIN_USER_DISCOVERY_THRESHOLD)
        .bind(u8::MAX)
        .execute(&mut *connection)
        .await?;
        if changed {
            Self::advance_promotion_version(connection).await?;
        }
        Ok(())
    }

    async fn handle_user_discovery_announcement(
        &self, contact_id: UserID, public_key_verified_timestamp: Option<i64>,
        uda: UserDiscoveryAnnouncement, t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<()> {
        tracing::info!("Got a user discovery announcement from {contact_id}.");

        if !is_supported_threshold(uda.threshold) {
            tracing::warn!(
                "Ignoring user-discovery announcement with unsupported threshold {} (expected \
                 {}..={}).",
                uda.threshold,
                MIN_USER_DISCOVERY_THRESHOLD,
                u8::MAX
            );

            return Ok(());
        }

        if uda.threshold as usize != uda.verification_shares.len() + 1 {
            tracing::warn!(
                "UDA contains to few shares to verify: {} != {} + 1.",
                uda.threshold,
                uda.verification_shares.len(),
            );

            return Err(TwonlyError::MaliciousAnnouncementData(
                "incorrect verification share count".into(),
            ));
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

                if uda.public_id != signed_data.public_id {
                    return Err(TwonlyError::MaliciousAnnouncementData(
                        "announcement public ID does not match its signed data".into(),
                    ));
                }

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
                    let config = Self::advance_promotion_version(t).await?;
                    let new_promotion_version = config.promotion_version;
                    let announcement_version = config.announcement_version;

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
                        "UPDATE user_discovery_own_promotions SET promotion = X'' WHERE \
                         contact_id = ?",
                        contact_id,
                    )
                    .execute(&mut **t)
                    .await
                    .map_err(|error| TwonlyError::UserDiscoveryStore(error.to_string()))?;

                    sqlx::query!(
                        "INSERT INTO user_discovery_own_promotions(version_id, contact_id, promotion) VALUES \
                         (?, ?, ?)",
                        new_promotion_version,
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

                // As we no now the public_id from the user, all promotions up to this point are
                // also known, so add these to the relations database as well
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
        &self, from_contact_id: UserID, udp: UserDiscoveryPromotion,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<()> {
        tracing::debug!("Received a new UDP with public_id = {}.", &udp.public_id);

        if !is_supported_threshold(udp.threshold) {
            tracing::warn!(
                "Ignoring user-discovery promotion with unsupported threshold {} (expected \
                 {}..={}).",
                udp.threshold,
                MIN_USER_DISCOVERY_THRESHOLD,
                u8::MAX
            );

            return Ok(());
        }

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

        // Deduplicate shares by their raw bytes to prevent invalid Shamir's Secret
        // Sharing recoveries. Multiple identical shares (e.g. due to contact
        // resending promotions, or DB duplicate writes) will cause `recover` to
        // interpolate incorrectly and return garbage bytes.
        let mut unique_shares_set = HashSet::new();

        let mut unique_promotions = Vec::new();

        for p in promotions {
            if unique_shares_set.insert(p.announcement_share.clone()) {
                unique_promotions.push(p);
            }
        }

        if unique_promotions.len() < udp.threshold as usize {
            tracing::debug!(
                "Not enough unique shares ({} < {}) to decrypt announcement. Waiting for next \
                 share.",
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
                        tracing::warn!(
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

                    let config = Self::read_config(t)
                        .await?
                        .ok_or(TwonlyError::UserDiscoveryNotInitialized)?;

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
        &self, promotion: OtherPromotion, t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
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
        &self, public_id: i64, t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
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
        &self, public_id: i64, t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
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
        &self, from_contact_id: UserID, announced_user: AnnouncedUser,
        public_key_verified_timestamp: Option<i64>, t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
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

        self.refresh_session_identity(announced_user.user_id, t)
            .await?;

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
            threshold: MIN_USER_DISCOVERY_THRESHOLD,
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

#[cfg(test)]
mod tests {

    use super::*;

    async fn initialized_discovery() -> Result<(tempfile::TempDir, Arc<Context>)> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        crate::api::ApiRuntime::close(&ctx).await?;
        crate::user_config::UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"me","displayName":"Me","isUserDiscoveryEnabled":true}"#,
        )?;
        let identity = IdentityKeyPair::generate(&mut rand::rngs::StdRng::from_os_rng());
        ctx.inject_test_signal_identity(identity.serialize().to_vec(), 1)
            .await?;
        ctx.inject_test_user_id(42).await?;
        Ok((directory, ctx))
    }

    #[tokio::test]
    async fn outgoing_discovery_version_uses_the_envelope_transaction() -> Result<()> {
        let (_directory, ctx) = initialized_discovery().await?;
        let database = ctx.app_db.read().await.clone();
        sqlx::query("INSERT INTO contacts(user_id, username, accepted, media_send_counter) VALUES (7, 'peer', 1, 4)")
            .execute(&database.pool).await?;
        let mut tx = database.pool.begin().await?;
        let mut content = crate::api::proto::client::EncryptedContent::default();
        tokio::time::timeout(
            std::time::Duration::from_secs(2),
            crate::api::messages::outgoing::decorate_content(&ctx, &mut tx, 7, &mut content, true),
        )
        .await
        .expect("must not acquire the pool while holding its writer")?;
        let version = UserDiscoveryVersion::decode(
            content.sender_user_discovery_version.unwrap().as_slice(),
        )?;
        assert_eq!(version.announcement, 1);
        tx.rollback().await?;
        Ok(())
    }

    #[tokio::test]
    async fn backup_restore_preserves_the_authoritative_discovery_generation() -> Result<()> {
        let (_directory, ctx) = initialized_discovery().await?;
        let original = ctx.user_discovery.get().await.get_config_snapshot().await?;
        let archive = crate::backup::backup_archive::BackupArchive::create_backup(&ctx).await?;
        crate::user_config::UserConfig::update(&ctx, |config| config.user_discovery_threshold = 4)?;
        ctx.user_discovery
            .get()
            .await
            .initialize_from_config(&ctx)
            .await?;
        assert_ne!(
            ctx.user_discovery
                .get()
                .await
                .get_config_snapshot()
                .await?
                .public_id,
            original.public_id
        );
        crate::backup::backup_archive::BackupArchive::restore_from_backup(&ctx, &archive).await?;
        ctx.user_discovery
            .get()
            .await
            .initialize_from_config(&ctx)
            .await?;
        let restored = ctx.user_discovery.get().await.get_config_snapshot().await?;
        assert_eq!(restored.public_id, original.public_id);
        assert_eq!(restored.threshold, original.threshold);
        assert_eq!(restored.announcement_version, original.announcement_version);
        crate::api::ApiRuntime::close(&ctx).await?;
        Ok(())
    }

    #[tokio::test]
    async fn discovery_generation_rolls_back_with_its_shares() -> Result<()> {
        let (_directory, ctx) = initialized_discovery().await?;
        let discovery = ctx.user_discovery.get().await;
        let database = ctx.app_db.read().await.clone();
        let before = discovery.get_current_version().await?;
        let original = discovery.get_config_snapshot().await?;
        let shares: Vec<Vec<u8>> =
            sqlx::query_scalar("SELECT share FROM user_discovery_shares ORDER BY share_id")
                .fetch_all(&database.pool)
                .await?;
        let public_key = IdentityKeyPair::try_from(
            ctx.key_manager
                .lock()
                .await
                .signal_identity
                .as_ref()
                .unwrap()
                .identity_key_pair_structure
                .as_slice(),
        )?
        .identity_key()
        .serialize()
        .to_vec();
        let mut tx = database.pool.begin().await?;
        discovery
            .initialize_or_update(4, 42, public_key.clone(), true, &mut tx)
            .await?;
        assert_eq!(
            UserDiscovery::read_config(&mut tx)
                .await?
                .unwrap()
                .threshold,
            4
        );
        tx.rollback().await?;
        assert_eq!(discovery.get_current_version().await?, before);
        assert_eq!(
            discovery.get_config_snapshot().await?.public_id,
            original.public_id
        );
        assert_eq!(
            sqlx::query_scalar::<_, Vec<u8>>(
                "SELECT share FROM user_discovery_shares ORDER BY share_id"
            )
            .fetch_all(&database.pool)
            .await?,
            shares
        );
        let mut tx = database.pool.begin().await?;
        assert!(
            discovery
                .generation_is_consistent(&original, 42, &public_key, &mut tx)
                .await?
        );
        tx.rollback().await?;
        Ok(())
    }

    #[tokio::test]
    async fn legacy_threshold_two_is_persisted_as_three_and_reannounced() -> Result<()> {
        let (_directory, ctx) = initialized_discovery().await?;
        let discovery = ctx.user_discovery.get().await;
        let database = ctx.app_db.read().await.clone();
        let mut legacy = discovery.get_config_snapshot().await?;
        legacy.threshold = 2;
        legacy.announcement_version = 7;
        let old_public_id = legacy.public_id;
        // Model an old installation, including inconsistent JSON/SQL shares.
        std::fs::write(&discovery.config_path, serde_json::to_vec(&legacy)?)?;
        sqlx::query("DELETE FROM app_metadata WHERE key = ?")
            .bind(CONFIG_KEY)
            .execute(&database.pool)
            .await?;
        sqlx::query("UPDATE user_discovery_shares SET share = X'0102'")
            .execute(&database.pool)
            .await?;
        let settings_path = PathBuf::from(&ctx.config.data_dir).join("keyvalue/user.json");
        let mut settings: serde_json::Value =
            serde_json::from_slice(&std::fs::read(&settings_path)?)?;
        settings["userDiscoveryThreshold"] = 2.into();
        std::fs::write(&settings_path, serde_json::to_vec(&settings)?)?;

        discovery.initialize_from_config(&ctx).await?;
        let current = discovery.get_config_snapshot().await?;
        assert_eq!(current.threshold, 3);
        assert_eq!(current.announcement_version, 8);
        assert_ne!(current.public_id, old_public_id);
        let settings: serde_json::Value = serde_json::from_slice(&std::fs::read(&settings_path)?)?;
        assert_eq!(settings["userDiscoveryThreshold"], 3);
        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'peer')")
            .execute(&database.pool)
            .await?;
        let mut tx = database.pool.begin().await?;
        let messages = discovery
            .get_new_messages(
                &ctx,
                7,
                &UserDiscoveryVersion {
                    announcement: 7,
                    promotion: current.promotion_version,
                }
                .encode_to_vec(),
                &mut tx,
            )
            .await?;
        let announcement = UserDiscoveryMessage::decode(messages[0].as_slice())?
            .user_discovery_announcement
            .unwrap();
        assert_eq!(announcement.threshold, 3);
        let shares: Vec<_> = announcement
            .verification_shares
            .iter()
            .chain(std::iter::once(&announcement.announcement_share))
            .map(|bytes| Share::try_from(bytes.as_slice()).unwrap())
            .collect();
        let recovered = Sharks(3).recover(&shares).unwrap();
        let data = AnnouncementShareDecrypted::decode(recovered.as_slice())?
            .signed_data
            .unwrap();
        assert_eq!(data.public_id, current.public_id);
        assert_eq!(data.user_id, 42);
        tx.commit().await?;
        // The obsolete JSON must not undo the upgrade or cause regeneration
        // on every send/restart.
        discovery.initialize_from_config(&ctx).await?;
        assert_eq!(
            discovery.get_config_snapshot().await?.public_id,
            current.public_id
        );
        Ok(())
    }

    #[tokio::test]
    async fn mixed_generation_is_repaired_without_lowering_a_higher_threshold() -> Result<()> {
        let (_directory, ctx) = initialized_discovery().await?;
        let discovery = ctx.user_discovery.get().await;
        crate::user_config::UserConfig::update(&ctx, |config| config.user_discovery_threshold = 4)?;
        discovery.initialize_from_config(&ctx).await?;
        let original = discovery.get_config_snapshot().await?;
        let database = ctx.app_db.read().await.clone();
        // Same lengths still need checking: a generation with different
        // polynomial coefficients reconstructs different plaintext.
        let key = IdentityKeyPair::try_from(
            ctx.key_manager
                .lock()
                .await
                .signal_identity
                .as_ref()
                .unwrap()
                .identity_key_pair_structure
                .as_slice(),
        )?
        .identity_key()
        .serialize()
        .to_vec();
        let mut tx = database.pool.begin().await?;
        discovery
            .initialize_or_update(4, 42, key.clone(), true, &mut tx)
            .await?;
        let foreign: Vec<u8> =
            sqlx::query_scalar("SELECT share FROM user_discovery_shares LIMIT 1")
                .fetch_one(&mut *tx)
                .await?;
        tx.rollback().await?;
        sqlx::query("UPDATE user_discovery_shares SET share = ? WHERE share_id = (SELECT MAX(share_id) FROM user_discovery_shares)")
            .bind(foreign).execute(&database.pool).await?;
        discovery.initialize_from_config(&ctx).await?;
        let current = discovery.get_config_snapshot().await?;
        assert_eq!(current.threshold, 4);
        assert!(current.announcement_version > original.announcement_version);
        assert_ne!(current.public_id, original.public_id);
        let mut tx = database.pool.begin().await?;
        assert!(
            discovery
                .generation_is_consistent(&current, 42, &key, &mut tx)
                .await?
        );
        tx.rollback().await?;
        Ok(())
    }

    #[tokio::test]
    async fn legacy_cached_promotions_are_retired_and_do_not_hide_later_updates() -> Result<()> {
        let (_directory, ctx) = initialized_discovery().await?;
        let discovery = ctx.user_discovery.get().await;
        let database = ctx.app_db.read().await.clone();
        sqlx::query("INSERT INTO contacts(user_id, username, accepted, media_send_counter, user_discovery_version) VALUES (7, 'old', 1, 4, X'0801'), (8, 'current', 1, 4, NULL)")
            .execute(&database.pool).await?;
        for (contact, threshold) in [(7, 2), (8, 3)] {
            let bytes = UserDiscoveryMessage {
                version: Some(UserDiscoveryVersion {
                    announcement: 1,
                    promotion: (contact - 6) as u32,
                }),
                user_discovery_promotion: Some(UserDiscoveryPromotion {
                    threshold,
                    public_id: contact,
                    announcement_share: vec![1, 2],
                    ..Default::default()
                }),
                ..Default::default()
            }
            .encode_to_vec();
            sqlx::query(
                "INSERT INTO user_discovery_own_promotions(contact_id, promotion) VALUES (?, ?)",
            )
            .bind(contact)
            .bind(bytes)
            .execute(&database.pool)
            .await?;
        }
        sqlx::query("INSERT INTO user_discovery_other_promotions(from_contact_id,promotion_id,public_id,threshold,announcement_share) VALUES (7,1,70,2,X'0102')")
            .execute(&database.pool).await?;
        // Sending must filter legacy caches even before startup cleanup runs.
        let mut tx = database.pool.begin().await?;
        let mut config = UserDiscovery::read_config(&mut tx).await?.unwrap();
        config.promotion_version = 2;
        UserDiscovery::write_config(&config, &mut tx).await?;
        let request = UserDiscoveryVersion {
            announcement: config.announcement_version,
            promotion: 0,
        }
        .encode_to_vec();
        let messages = discovery
            .get_new_messages(&ctx, 8, &request, &mut tx)
            .await?;
        let promotions: Vec<_> = messages
            .iter()
            .filter_map(|bytes| {
                UserDiscoveryMessage::decode(bytes.as_slice())
                    .unwrap()
                    .user_discovery_promotion
            })
            .collect();
        assert_eq!(promotions.len(), 1);
        assert_eq!(promotions[0].threshold, 3);
        tx.commit().await?;
        discovery.initialize_from_config(&ctx).await?;
        assert_eq!(
            sqlx::query_scalar::<_, i64>(
                "SELECT length(promotion) FROM user_discovery_own_promotions WHERE contact_id = 7"
            )
            .fetch_one(&database.pool)
            .await?,
            0
        );
        assert!(sqlx::query_scalar::<_, Option<Vec<u8>>>(
            "SELECT user_discovery_version FROM contacts WHERE user_id = 7"
        )
        .fetch_one(&database.pool)
        .await?
        .is_none());
        assert_eq!(
            sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM user_discovery_other_promotions")
                .fetch_one(&database.pool)
                .await?,
            0
        );
        let cleaned = discovery.get_config_snapshot().await?;
        assert!(cleaned.promotion_version > 2);
        discovery.initialize_from_config(&ctx).await?;
        assert_eq!(
            discovery.get_config_snapshot().await?.promotion_version,
            cleaned.promotion_version
        );

        let mut tx = database.pool.begin().await?;
        // A cursor bump without a promotion must still return a terminal
        // version, otherwise receivers ask for the same update forever.
        let messages = discovery
            .get_new_messages(
                &ctx,
                8,
                &UserDiscoveryVersion {
                    announcement: cleaned.announcement_version,
                    promotion: 2,
                }
                .encode_to_vec(),
                &mut tx,
            )
            .await?;
        assert_eq!(messages.len(), 1);
        assert_eq!(
            UserDiscoveryMessage::decode(messages[0].as_slice())?
                .version
                .unwrap()
                .promotion,
            cleaned.promotion_version
        );
        discovery
            .update_verification_state_for_user(8, None, &mut tx)
            .await?;
        let messages = discovery
            .get_new_messages(
                &ctx,
                8,
                &UserDiscoveryVersion {
                    announcement: cleaned.announcement_version,
                    promotion: cleaned.promotion_version,
                }
                .encode_to_vec(),
                &mut tx,
            )
            .await?;
        assert!(messages.iter().any(|bytes| {
            UserDiscoveryMessage::decode(bytes.as_slice())
                .unwrap()
                .user_discovery_promotion
                .is_some()
        }));
        tx.commit().await?;
        Ok(())
    }

    #[tokio::test]
    async fn malformed_announcement_is_retryable_even_after_a_version_marker() -> Result<()> {
        let (_directory, ctx) = initialized_discovery().await?;
        let discovery = ctx.user_discovery.get().await;
        let database = ctx.app_db.read().await.clone();
        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'peer')")
            .execute(&database.pool)
            .await?;
        let version = UserDiscoveryVersion {
            announcement: 5,
            promotion: 9,
        };
        let malformed = UserDiscoveryMessage {
            version: Some(version),
            user_discovery_announcement: Some(UserDiscoveryAnnouncement {
                threshold: 3,
                announcement_share: vec![1, 2],
                verification_shares: vec![vec![2, 3, 4], vec![3, 4, 5]],
                ..Default::default()
            }),
            ..Default::default()
        }
        .encode_to_vec();
        let marker = UserDiscoveryMessage {
            version: Some(version),
            ..Default::default()
        }
        .encode_to_vec();
        let mut tx = database.pool.begin().await?;
        discovery
            .handle_new_messages(7, None, vec![malformed, marker], &mut tx)
            .await?;
        let received: Vec<u8> =
            sqlx::query_scalar("SELECT user_discovery_version FROM contacts WHERE user_id = 7")
                .fetch_one(&mut *tx)
                .await?;
        let received = UserDiscoveryVersion::decode(received.as_slice())?;
        assert_eq!(received.announcement, 0);
        assert_eq!(received.promotion, 9);
        tx.commit().await?;
        Ok(())
    }

    #[tokio::test]
    async fn discovery_verification_requires_the_current_session_key() -> Result<()> {
        use crate::database::app::key_verifications::queries as verification_queries;
        use crate::database::app::key_verifications::table::VerificationStatus;
        use crate::database::app::recovery::queries as recovery_queries;

        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        crate::api::ApiRuntime::close(&ctx).await?;
        let discovery = ctx.user_discovery.get().await;
        let database = ctx.app_db.read().await.clone();
        let signal = ctx.rust_db.read().await.clone();
        let mut tx = database.pool.begin().await?;
        sqlx::raw_sql(
            "INSERT INTO contacts(user_id,username,accepted) VALUES (1,'bob',1),(7,'carol',1);
             INSERT INTO key_verifications(contact_id,type) VALUES (1,'manual');
             INSERT INTO groups(group_id,group_name) VALUES ('g','group');
             INSERT INTO group_members(group_id,contact_id) VALUES ('g',7);",
        )
        .execute(&mut *tx)
        .await?;
        let announced = |key| AnnouncedUser {
            user_id: 7,
            public_key: vec![key],
            public_id: 70,
        };

        discovery
            .push_new_user_relation(1, announced(1), Some(123), &mut tx)
            .await?;
        assert!(verification_queries::transferred(&mut tx, 7)
            .await?
            .relations
            .is_empty());

        // A server-authorized identity can establish a session while the old
        // discovery claim remains stored. Only the inherited trust disappears.
        sqlx::query(
            "INSERT INTO signal_identities(name,identity_key,timestamp) VALUES ('7',X'02',0)",
        )
        .execute(&signal.pool)
        .await?;
        discovery.refresh_session_identity(7, &mut tx).await?;
        assert!(verification_queries::transferred(&mut tx, 7)
            .await?
            .relations
            .is_empty());
        assert_eq!(
            verification_queries::groups(&mut tx, Some("g")).await?[0].status,
            VerificationStatus::NotTrusted,
        );
        assert!(!recovery_queries::verified_ids(&mut tx).await?.contains(&7));
        assert_eq!(
            Contact::get_contact_by_id(&mut tx, 7)
                .await?
                .unwrap()
                .accepted,
            1
        );
        let timestamp: Option<i64> = sqlx::query_scalar(
            "SELECT public_key_verified_timestamp FROM user_discovery_user_relations WHERE announced_user_id = 7",
        )
        .fetch_one(&mut *tx)
        .await?;
        assert_eq!(timestamp, Some(123));

        discovery
            .push_new_user_relation(1, announced(2), Some(124), &mut tx)
            .await?;
        assert_eq!(
            verification_queries::transferred(&mut tx, 7)
                .await?
                .relations
                .len(),
            1
        );
        assert_eq!(
            verification_queries::groups(&mut tx, Some("g")).await?[0].status,
            VerificationStatus::PartialTrusted,
        );
        assert!(recovery_queries::verified_ids(&mut tx).await?.contains(&7));

        // A later claim for the old key cannot restore inherited verification.
        discovery
            .push_new_user_relation(1, announced(1), Some(125), &mut tx)
            .await?;
        assert!(verification_queries::transferred(&mut tx, 7)
            .await?
            .relations
            .is_empty());

        // Independent personal verification still applies.
        crate::database::app::key_verifications::writes::insert(&mut tx, 7, "manual", None).await?;
        assert_eq!(
            verification_queries::groups(&mut tx, Some("g")).await?[0].status,
            VerificationStatus::Trusted,
        );
        tx.commit().await?;
        Ok(())
    }

    #[tokio::test]
    async fn initialization_refreshes_discovery_identity_snapshots() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        crate::api::ApiRuntime::close(&ctx).await?;
        crate::user_config::UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"me","displayName":"Me","isUserDiscoveryEnabled":false}"#,
        )?;
        let database = ctx.app_db.read().await.clone();
        let signal = ctx.rust_db.read().await.clone();
        sqlx::raw_sql(
            "INSERT INTO user_discovery_announced_users
             (announced_user_id,announced_public_key,public_id,session_identity_key)
             VALUES (7,X'01',70,NULL),(8,X'02',80,X'02'),(9,X'03',90,X'03');",
        )
        .execute(&database.pool)
        .await?;
        sqlx::raw_sql(
            "INSERT INTO signal_identities(name,identity_key,timestamp)
             VALUES ('7',X'01',0),('8',X'09',0);",
        )
        .execute(&signal.pool)
        .await?;
        ctx.user_discovery
            .get()
            .await
            .initialize_from_config(&ctx)
            .await?;
        let identities: Vec<Option<Vec<u8>>> = sqlx::query_scalar(
            "SELECT session_identity_key FROM user_discovery_announced_users ORDER BY announced_user_id",
        )
        .fetch_all(&database.pool)
        .await?;
        assert_eq!(identities, vec![Some(vec![1]), Some(vec![9]), None]);
        Ok(())
    }

    #[test]

    fn only_accepts_supported_discovery_thresholds() {
        assert!(!is_supported_threshold(u32::from(
            MIN_USER_DISCOVERY_THRESHOLD - 1
        )));

        assert!(is_supported_threshold(u32::from(
            MIN_USER_DISCOVERY_THRESHOLD
        )));

        assert!(is_supported_threshold(u32::from(u8::MAX)));

        assert!(!is_supported_threshold(u32::from(u8::MAX) + 1));
    }

    #[tokio::test]

    async fn inherited_claims_are_never_advertised_as_personal_verification() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        crate::api::ApiRuntime::close(&ctx).await?;
        crate::user_config::UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"me","displayName":"Me"}"#,
        )?;
        let discovery = ctx.user_discovery.get().await;
        let database = ctx.app_db.read().await.clone();
        let mut tx = database.pool.begin().await?;
        UserDiscovery::write_config(
            &UserDiscoveryConfig {
                user_id: 42,
                announcement_version: 1,
                promotion_version: 2,
                ..Default::default()
            },
            &mut tx,
        )
        .await?;
        sqlx::raw_sql(
            "INSERT INTO contacts(user_id,username,accepted,media_send_counter)
             VALUES (1,'root',1,4),(2,'inherited',1,4);
             INSERT INTO key_verifications(contact_id,type,verified_by)
             VALUES (1,'manual',NULL),(2,'contactSharedByVerified',1);",
        )
        .execute(&mut *tx)
        .await?;

        for id in [1, 2] {
            let message = UserDiscoveryMessage {
                version: Some(UserDiscoveryVersion {
                    announcement: 1,
                    promotion: id as u32,
                }),
                user_discovery_promotion: Some(UserDiscoveryPromotion {
                    public_id: id,
                    threshold: 3,
                    public_key_verified_timestamp: Some(123),
                    ..Default::default()
                }),
                ..Default::default()
            }
            .encode_to_vec();
            sqlx::query(
                "INSERT INTO user_discovery_own_promotions(contact_id,promotion) VALUES (?,?)",
            )
            .bind(id)
            .bind(message)
            .execute(&mut *tx)
            .await?;
        }
        let version = UserDiscoveryVersion {
            announcement: 1,
            promotion: 0,
        }
        .encode_to_vec();
        let messages = discovery
            .get_new_messages(&ctx, 1, &version, &mut tx)
            .await?;
        assert_eq!(messages.len(), 2);
        for bytes in messages {
            let message = UserDiscoveryMessage::decode(bytes.as_slice())?;
            let promotion = message.user_discovery_promotion.unwrap();
            assert_eq!(
                promotion.public_key_verified_timestamp.is_some(),
                promotion.public_id == 1
            );
        }
        discovery
            .update_verification_state_for_user(2, Some(999), &mut tx)
            .await?;
        let promotion: Vec<u8> = sqlx::query_scalar(
            "SELECT promotion FROM user_discovery_own_promotions WHERE contact_id = 2 ORDER BY version_id DESC LIMIT 1",
        ).fetch_one(&mut *tx).await?;
        assert!(UserDiscoveryMessage::decode(promotion.as_slice())?
            .user_discovery_promotion
            .unwrap()
            .public_key_verified_timestamp
            .is_none());
        tx.commit().await?;

        let old_version = discovery.get_config_snapshot().await?.promotion_version;
        discovery.refresh_verification_policy(&ctx).await?;
        assert!(discovery.get_config_snapshot().await?.promotion_version > old_version);
        let old_version = discovery.get_config_snapshot().await?.promotion_version;
        discovery.refresh_verification_policy(&ctx).await?;
        assert_eq!(
            discovery.get_config_snapshot().await?.promotion_version,
            old_version
        );
        Ok(())
    }

    #[tokio::test]

    async fn promotions_of_contacts_no_longer_allowed_are_not_passed_on() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        crate::api::ApiRuntime::close(&ctx).await?;
        crate::user_config::UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"me","displayName":"Me"}"#,
        )?;
        let discovery = ctx.user_discovery.get().await;
        let database = ctx.app_db.read().await.clone();
        let mut tx = database.pool.begin().await?;
        UserDiscovery::write_config(
            &UserDiscoveryConfig {
                user_id: 42,
                announcement_version: 1,
                promotion_version: 3,
                ..Default::default()
            },
            &mut tx,
        )
        .await?;
        sqlx::raw_sql(
            "INSERT INTO contacts(user_id,username,accepted,blocked,user_discovery_excluded,
                                  media_send_counter)
             VALUES (1,'friend',1,0,0,4),(2,'blocked',1,1,0,4),(3,'excluded',1,0,1,4);",
        )
        .execute(&mut *tx)
        .await?;

        for id in [1, 2, 3] {
            let message = UserDiscoveryMessage {
                version: Some(UserDiscoveryVersion {
                    announcement: 1,
                    promotion: id as u32,
                }),
                user_discovery_promotion: Some(UserDiscoveryPromotion {
                    public_id: id,
                    threshold: 3,
                    ..Default::default()
                }),
                ..Default::default()
            }
            .encode_to_vec();
            sqlx::query(
                "INSERT INTO user_discovery_own_promotions(contact_id,promotion) VALUES (?,?)",
            )
            .bind(id)
            .bind(message)
            .execute(&mut *tx)
            .await?;
        }

        let version = UserDiscoveryVersion {
            announcement: 1,
            promotion: 0,
        }
        .encode_to_vec();
        let promoted: Vec<Option<i64>> = discovery
            .get_new_messages(&ctx, 1, &version, &mut tx)
            .await?
            .into_iter()
            .map(|bytes| UserDiscoveryMessage::decode(bytes.as_slice()))
            .collect::<std::result::Result<Vec<_>, _>>()?
            .into_iter()
            .map(|message| message.user_discovery_promotion.map(|p| p.public_id))
            .collect();
        // The friend's promotion, then the bare version that moves the
        // receiver past the two left out.
        assert_eq!(promoted, vec![Some(1), None]);
        Ok(())
    }
}
