pub mod error;
pub mod stores;
#[cfg(test)]
pub mod tests;
pub mod traits;

use std::collections::{HashMap, HashSet};
use std::sync::Arc;
use std::u8;
use blahaj::{Share, Sharks};
use prost::Message;
use serde::{Deserialize, Serialize};
use tokio::sync::{Mutex, MutexGuard};
use crate::user_discovery::error::{Result, UserDiscoveryError};
use crate::user_discovery::traits::{AnnouncedUser, OtherPromotion, UserDiscoveryUtils};
use crate::user_discovery::user_discovery_message::{UserDiscoveryAnnouncement, UserDiscoveryPromotion};
use crate::user_discovery::user_discovery_message::user_discovery_promotion::AnnouncementShareDecrypted;
use crate::user_discovery::user_discovery_message::user_discovery_promotion::announcement_share_decrypted::SignedData;
pub use traits::UserDiscoveryStore;

/// Type of the user id, this must be consistent with the user id defined in
/// the types.proto
pub type UserID = i64;

include!(concat!(env!("OUT_DIR"), "/user_discovery.rs"));

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

///
/// The main struct to access the user discovery functionality.
///
/// As generic values it requires a UserDiscoveryStore and a UserDiscoveryUtils.
///
pub struct UserDiscovery<Store, Utils>
where
    Store: UserDiscoveryStore,
    Utils: UserDiscoveryUtils,
{
    store: Store,
    utils: Utils,
    config_lock: Arc<Mutex<bool>>,
}

impl<Store: UserDiscoveryStore, Utils: UserDiscoveryUtils> UserDiscovery<Store, Utils> {
    /// Creates a new instance of the user discovery.
    pub fn new(store: Store, utils: Utils) -> Result<Self> {
        Ok(Self {
            store,
            utils,
            config_lock: Arc::default(),
        })
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
    /// * `Err(UserDiscoveryError)` - If the user discovery was not initialized or updated successfully
    ///
    pub async fn initialize_or_update(
        &self,
        threshold: u8,
        user_id: UserID,
        public_key: Vec<u8>,
        share_promotion: bool,
    ) -> Result<()> {
        tracing::info!("Protocols: initialize_or_update started, getting config_lock");
        let config_lock = self.config_lock.lock().await;
        tracing::info!("Protocols: got config_lock, getting config from store");
        let mut config = match self.store.get_config().await {
            Ok(config) => {
                let mut config: UserDiscoveryConfig = serde_json::from_str(&config)?;
                config.threshold = threshold;
                config
            }
            Err(_) => UserDiscoveryConfig {
                threshold,
                user_id,
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
        let signature = self.utils.sign_data(&signed_data.encode_to_vec()).await?;

        debug_assert_eq!(threshold, config.threshold);

        tracing::info!("Protocols: setting up announcements");
        let verification_shares = self
            .setup_announcements(&config, signed_data, signature)
            .await?;

        debug_assert_eq!(verification_shares.len(), threshold as usize - 1);

        config.public_id = public_id;
        config.announcement_version += 1;
        config.verification_shares = verification_shares;
        config.share_promotion = share_promotion;

        tracing::info!("Protocols: updating config in store");
        self.update_config(config, config_lock).await?;

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
    /// * `Err(UserDiscoveryError)` - If there where errors in the store.
    ///
    pub async fn get_current_version(&self) -> Result<Vec<u8>> {
        let (config, _) = self.get_config().await?;
        Ok(UserDiscoveryVersion {
            announcement: config.announcement_version,
            promotion: config.promotion_version,
        }
        .encode_to_vec())
    }

    ///
    /// Returns all users discovery though the user discovery and there relations
    ///
    /// # Returns
    ///
    /// * `Ok(HashMap<AnnouncedUser, Vec<(UserID, Option<i64>)>>)` - All connections the user has discovered
    /// * `Err(UserDiscoveryError)` - If there where erros in the store.
    ///
    pub async fn get_all_announced_users(
        &self,
    ) -> Result<HashMap<AnnouncedUser, Vec<(UserID, Option<i64>)>>> {
        self.store.get_all_announced_users().await
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
    /// * `Err(UserDiscoveryError)` - If there where errors in the store or if the received version is invalid.
    ///
    pub async fn get_new_messages(
        &self,
        contact_id: UserID,
        received_version: &[u8],
    ) -> Result<Vec<Vec<u8>>> {
        let mut messages = vec![];
        let received_version = UserDiscoveryVersion::decode(received_version)?;

        let (config, _) = self.get_config().await?;
        let version = Some(UserDiscoveryVersion {
            announcement: config.announcement_version,
            promotion: config.promotion_version,
        });

        if received_version.announcement < config.announcement_version {
            tracing::info!("New announcement message available for {}", contact_id);

            let announcement_share = self.store.get_share_for_contact(contact_id).await?;

            let user_discovery_announcement = Some(UserDiscoveryAnnouncement {
                public_id: config.public_id,
                threshold: config.threshold as u32,
                announcement_share,
                verification_shares: config.verification_shares,
                share_promotion: config.share_promotion,
            });

            messages.push(
                UserDiscoveryMessage {
                    user_discovery_announcement,
                    version,
                    ..Default::default()
                }
                .encode_to_vec(),
            );
        }
        if received_version.promotion < config.promotion_version {
            tracing::info!("New promotion message available for user {}", contact_id);
            let promoting_messages = self
                .store
                .get_own_promotions_after_version(received_version.promotion)
                .await?;

            let size = promoting_messages.len();
            let mut filtered: Vec<Vec<u8>> = promoting_messages
                .into_iter()
                .filter(|x| !x.is_empty()) // filter ignored versions
                .collect();

            if filtered.len() != size {
                // ensure the receiver will get the later version in case the last message was filtered out
                filtered.push(
                    UserDiscoveryMessage {
                        version: Some(UserDiscoveryVersion {
                            announcement: config.announcement_version,
                            promotion: config.promotion_version,
                        }),
                        ..Default::default()
                    }
                    .encode_to_vec(),
                );
            }
            messages.extend_from_slice(&filtered);
        }
        Ok(messages)
    }

    ///
    /// Checks if the provided user has new announcements and a request of update should be send.
    ///
    /// # Arguments
    ///
    /// * `contact_id` - The contact id of the user
    /// * `version` - The current version of the user discovery from the contact
    ///
    /// # Returns
    ///
    /// * `Ok(bool)` - True if the user has new announcements
    /// * `Err(UserDiscoveryError)` - If there where errors in the store or if the received version is invalid.
    ///
    pub async fn should_request_new_messages(
        &self,
        contact_id: UserID,
        version: &[u8],
    ) -> Result<Option<Vec<u8>>> {
        let received_version = UserDiscoveryVersion::decode(version)?;
        let stored_version = match self.store.get_contact_version(contact_id).await? {
            Some(buf) => UserDiscoveryVersion::decode(buf.as_slice())?,
            None => UserDiscoveryVersion {
                announcement: 0,
                promotion: 0,
            },
        };
        tracing::debug!(
            received.announcement = %received_version.announcement,
            received.promotion = %received_version.promotion,
            stored.announcement = %stored_version.announcement,
            stored.promotion = %stored_version.promotion,
            "Comparing version numbers"
        );
        if received_version.announcement > stored_version.announcement
            || received_version.promotion > stored_version.promotion
        {
            Ok(Some(stored_version.encode_to_vec()))
        } else {
            Ok(None)
        }
    }

    #[cfg(test)]
    pub(crate) async fn get_contact_version(&self, contact_id: UserID) -> Result<Option<Vec<u8>>> {
        self.store.get_contact_version(contact_id).await
    }

    /// Returns the latest version for this discovery.
    /// Before calling this function the application must sure that contact_id is qualified to be announced.
    pub async fn handle_new_messages(
        &self,
        contact_id: UserID,
        public_key_verified_timestamp: Option<i64>,
        messages: Vec<Vec<u8>>,
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
                    )
                    .await
                {
                    tracing::warn!("Ignoring: {err}");
                }
            } else if let Some(udp) = message.user_discovery_promotion {
                if let Err(err) = self.handle_user_discovery_promotion(contact_id, udp).await {
                    tracing::warn!("Ignoring: {err}");
                }
            }

            // Always update the version...
            self.store
                .set_contact_version(contact_id, version.encode_to_vec())
                .await?;
        }

        Ok(())
    }

    pub async fn update_verification_state_for_user(
        &self,
        contact_id: UserID,
        public_key_verified_timestamp: Option<i64>,
    ) -> Result<()> {
        let (mut config, config_lock) = self.get_config().await?;
        config.promotion_version += 1;

        let Some(current_promotion) = self.store.get_contact_promotion(contact_id).await? else {
            // User does not participate...
            return Ok(());
        };

        let old_message = UserDiscoveryMessage::decode(current_promotion.as_slice())?;

        let Some(old_promotion) = old_message.user_discovery_promotion else {
            tracing::error!("A contact should only have a promotion message...");
            return Ok(());
        };

        let message = UserDiscoveryMessage {
            version: Some(UserDiscoveryVersion {
                announcement: config.announcement_version,
                promotion: config.promotion_version,
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

        self.store
            .push_own_promotion_and_clear_old_version(
                contact_id,
                config.promotion_version,
                message.encode_to_vec(),
            )
            .await?;

        self.update_config(config, config_lock).await?;

        Ok(())
    }

    async fn setup_announcements(
        &self,
        config: &UserDiscoveryConfig,
        signed_data: SignedData,
        signature: Vec<u8>,
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

        let sharks = Sharks(config.threshold as u8);
        let dealer = sharks.dealer(&encrypted_announcement);

        let mut shares: Vec<Vec<u8>> = dealer
            .take(config.total_number_of_shares as usize)
            .map(|x| Vec::from(&x))
            .collect();

        if shares.len() != config.total_number_of_shares as usize
            || shares.is_empty()
            || shares.len() <= (config.threshold as usize * 2)
        {
            return Err(UserDiscoveryError::ShamirsSecret(
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

        self.store.set_shares(shares).await?;

        Ok(verification_shares)
    }

    async fn get_config(&self) -> Result<(UserDiscoveryConfig, MutexGuard<'_, bool>)> {
        let mut lock = self.config_lock.lock().await;
        *lock = true;
        Ok((serde_json::from_str(&self.store.get_config().await?)?, lock))
    }

    async fn update_config(
        &self,
        config: UserDiscoveryConfig,
        mut config_lock: MutexGuard<'_, bool>,
    ) -> Result<()> {
        self.store
            .update_config(serde_json::to_string_pretty(&config)?)
            .await?;
        *config_lock = false;
        Ok(())
    }

    async fn handle_user_discovery_announcement(
        &self,
        contact_id: UserID,
        public_key_verified_timestamp: Option<i64>,
        uda: UserDiscoveryAnnouncement,
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
                    return Err(UserDiscoveryError::MaliciousAnnouncementData(
                        "missing signed data".into(),
                    ));
                };

                if contact_id != signed_data.user_id {
                    return Err(UserDiscoveryError::MaliciousAnnouncementData(format!(
                        "contact_id ({contact_id}) != signed_data.user_id ({})",
                        signed_data.user_id
                    )));
                }

                if !self
                    .utils
                    .verify_stored_pubkey(contact_id, &signed_data.public_key)
                    .await?
                {
                    return Err(UserDiscoveryError::MaliciousAnnouncementData(format!(
                        "public key does not match with stored one",
                    )));
                }

                if !self
                    .utils
                    .verify_signature(
                        &signed_data.encode_to_vec(),
                        &signed_data.public_key,
                        &asd.signature,
                    )
                    .await?
                {
                    return Err(UserDiscoveryError::MaliciousAnnouncementData(format!(
                        "signature invalid",
                    )));
                }

                // Only add this user to the promotions if the users enabled this feature
                if uda.share_promotion {
                    let (mut config, config_lock) = self.get_config().await?;
                    config.promotion_version += 1;

                    let message = UserDiscoveryMessage {
                        version: Some(UserDiscoveryVersion {
                            announcement: config.announcement_version,
                            promotion: config.promotion_version,
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

                    self.store
                        .push_own_promotion_and_clear_old_version(
                            contact_id,
                            config.promotion_version,
                            message.encode_to_vec(),
                        )
                        .await?;

                    self.update_config(config, config_lock).await?;
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
                self.store
                    .push_new_user_relation(
                        contact_id,
                        announced_user.clone(),
                        public_key_verified_timestamp,
                    )
                    .await?;

                // As we no now the public_id from the user, all promotions up to this point are also known, so add these to the relations database as well
                let promotions = self
                    .store
                    .get_other_promotions_by_public_id(uda.public_id)
                    .await?;

                for promotion in promotions {
                    self.store
                        .push_new_user_relation(
                            promotion.from_contact_id,
                            announced_user,
                            promotion.public_key_verified_timestamp,
                        )
                        .await?;
                    return Ok(());
                }

                Ok(())
            }
            Err(err) => Err(UserDiscoveryError::ShamirsSecret(err.to_string())),
        }
    }

    async fn handle_user_discovery_promotion(
        &self,
        from_contact_id: UserID,
        udp: UserDiscoveryPromotion,
    ) -> Result<()> {
        tracing::debug!("Received a new UDP with public_id = {}.", &udp.public_id);

        if udp.announcement_share.is_empty() {
            tracing::info!("Got empty announcement share. Ignoring it..");
            return Ok(());
        }

        self.store
            .store_other_promotion(OtherPromotion {
                from_contact_id,
                promotion_id: udp.promotion_id,
                threshold: udp.threshold as u8,
                public_id: udp.public_id,
                announcement_share: udp.announcement_share,
                public_key_verified_timestamp: udp.public_key_verified_timestamp,
            })
            .await?;

        if let Some(contact) = self
            .store
            .get_announced_user_by_public_id(udp.public_id)
            .await?
        {
            tracing::debug!(
                "NEW PROMOTION 2: {} knows {}",
                from_contact_id,
                contact.user_id
            );
            // The user is already known, just propagate the relation ship
            self.store
                .push_new_user_relation(from_contact_id, contact, udp.public_key_verified_timestamp)
                .await?;
            return Ok(());
        }

        let promotions = self
            .store
            .get_other_promotions_by_public_id(udp.public_id)
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
                        .utils
                        .verify_signature(
                            &signed_data.encode_to_vec(),
                            &signed_data.public_key,
                            &asd.signature,
                        )
                        .await?
                    {
                        return Err(UserDiscoveryError::MaliciousAnnouncementData(format!(
                            "signature is invalid",
                        )));
                    }

                    tracing::debug!("Announcement valid.");

                    let announced_user = AnnouncedUser {
                        user_id: signed_data.user_id,
                        public_key: signed_data.public_key,
                        public_id: udp.public_id,
                    };

                    let (config, _) = self.get_config().await?;

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
                        self.store
                            .push_new_user_relation(
                                promotion.from_contact_id,
                                announced_user.clone(),
                                promotion.public_key_verified_timestamp,
                            )
                            .await?;
                    }
                }
                Ok(())
            }
            Err(err) => Err(UserDiscoveryError::ShamirsSecret(err.to_string())),
        }
    }
}

impl Default for UserDiscoveryConfig {
    fn default() -> Self {
        Self {
            threshold: 2,
            total_number_of_shares: u8::MAX,
            announcement_version: 0,
            promotion_version: 0,
            verification_shares: vec![],
            public_id: 0,
            share_promotion: true,
            user_id: 0,
        }
    }
}
