mod error;
pub mod stores;
mod traits;

use blahaj::{Share, Sharks};
use postcard::{from_bytes, to_allocvec};
use prost::Message;
use serde::{Deserialize, Serialize};
use crate::user_discovery::error::{Result, UserDiscoveryError};
use crate::user_discovery::traits::UserDiscoveryUtils;
use crate::user_discovery::user_discovery_message::{UserDiscoveryAnnouncement, UserDiscoveryPromotion};
use crate::user_discovery::user_discovery_message::user_discovery_promotion::AnnouncementShareDecrypted;
use crate::user_discovery::user_discovery_message::user_discovery_promotion::announcement_share_decrypted::SignedData;
pub use traits::UserDiscoveryStore;

pub type UserID = i64;

include!(concat!(env!("OUT_DIR"), "/_.rs"));

#[derive(Serialize, Deserialize, Clone, Debug)]
struct UserDiscoveryConfig {
    /// The number of required shares to get the secret
    threshold: u8,
    /// Currently limited to <= 255 as GF 256 is used
    total_number_of_shares: usize,
    /// Version of announcements
    announcement_version: u32,
    /// Version of promotions
    promotion_version: u32,
    /// This is a random public_id associated with a single announcement.
    public_id: u64,
    /// Verification shares
    verification_shares: Vec<Vec<u8>>,
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
        }
    }
}

pub struct UserDiscovery<Store, Utils>
where
    Store: UserDiscoveryStore,
    Utils: UserDiscoveryUtils,
{
    store: Store,
    utils: Utils,
}

impl<Store: UserDiscoveryStore, Utils: UserDiscoveryUtils> UserDiscovery<Store, Utils> {
    pub fn new(store: Store, utils: Utils) -> Result<Self> {
        Ok(Self { store, utils })
    }

    pub fn initialize_or_update(
        &self,
        threshold: u8,
        user_id: UserID,
        public_key: Vec<u8>,
    ) -> Result<()> {
        let mut config = match self.store.get_config() {
            Ok(config) => {
                let mut config: UserDiscoveryConfig = from_bytes(&config)?;
                config.threshold = threshold;
                config
            }
            Err(_) => UserDiscoveryConfig {
                threshold,
                ..Default::default()
            },
        };

        let public_id = rand::random();

        let signed_data = SignedData {
            public_id,
            user_id,
            public_key,
        };

        let signature = self.utils.sign_data(signed_data.encode_to_vec())?;

        let verification_shares = self.setup_announcements(&config, signed_data, signature)?;

        config.public_id = public_id;
        config.announcement_version += 1;
        config.verification_shares = verification_shares;

        self.store.update_config(to_allocvec(&config)?)?;

        Ok(())
    }

    fn setup_announcements(
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
            .take(config.total_number_of_shares)
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

        self.store.set_shares(shares)?;

        Ok(verification_shares)
    }

    fn get_config(&self) -> Result<UserDiscoveryConfig> {
        Ok(from_bytes(&self.store.get_config()?)?)
    }

    /// Returns the current version of the user discovery.
    pub fn get_current_version(&self) -> Result<Vec<u8>> {
        let config = self.get_config()?;
        Ok(UserDiscoveryVersion {
            announcement: config.announcement_version,
            promotion: config.promotion_version,
        }
        .encode_to_vec())
    }

    /// Returns all new user discovery messages for the provided contact
    pub fn get_new_messages(
        &self,
        contact_id: UserID,
        received_version: &[u8],
    ) -> Result<Vec<Vec<u8>>> {
        let mut messages = vec![];
        let received_version = UserDiscoveryVersion::decode(received_version)?;

        let config = self.get_config()?;
        let version = Some(UserDiscoveryVersion {
            announcement: config.announcement_version,
            promotion: config.promotion_version,
        });

        if received_version.announcement < config.announcement_version {
            tracing::info!("New announcement message available for {}", contact_id);

            let announcement_share = self.store.get_share_for_contact(contact_id)?;

            let user_discovery_announcement = Some(UserDiscoveryAnnouncement {
                public_id: config.public_id,
                threshold: config.threshold as u32,
                announcement_share,
                verification_shares: config.verification_shares,
            });

            messages.push(
                UserDiscoveryMessage {
                    user_discovery_announcement,
                    version,
                    ..Default::default()
                }
                .encode_to_vec(),
            );

            // messages.push(value);
        }
        if received_version.promotion < config.promotion_version {
            tracing::info!("New promotion message available for user {}", contact_id);
            let promoting_messages = self
                .store
                .get_promotions_after_version(received_version.promotion)?;
            messages.extend_from_slice(&promoting_messages);
        }
        Ok(messages)
    }

    /// Checks if the provided user has new announcements.
    /// In this case the user should be requested to send there updates.
    pub fn should_request_new_messages(&self, contact_id: UserID, version: &[u8]) -> Result<bool> {
        let received_version = UserDiscoveryVersion::decode(version)?;
        let stored_version = match self.store.get_contact_version(contact_id)? {
            Some(buf) => UserDiscoveryVersion::decode(buf.as_slice())?,
            None => UserDiscoveryVersion {
                announcement: 0,
                promotion: 0,
            },
        };
        Ok(received_version.announcement > stored_version.announcement
            || received_version.promotion < received_version.promotion)
    }

    pub(crate) fn get_contact_version(&self, contact_id: UserID) -> Result<Option<Vec<u8>>> {
        self.store.get_contact_version(contact_id)
    }

    /// Returns the latest version for this discovery.
    /// Before calling this function the application must sure that contact_id is qualified to be announced.
    pub fn handle_user_discovery_messages(
        &self,
        contact_id: UserID,
        messages: Vec<Vec<u8>>,
    ) -> Result<()> {
        for message in messages {
            let message = UserDiscoveryMessage::decode(message.as_slice())?;
            let Some(version) = message.version else {
                continue;
            };

            if let Some(uda) = message.user_discovery_announcement {
                self.handle_user_discovery_announcement(contact_id, uda)?;
            }
            if let Some(udp) = message.user_discovery_promotion {
                self.handle
                tracing::info!("Got UDP from {contact_id}");
            }

            self.store
                .set_contact_version(contact_id, version.encode_to_vec())?;
        }

        Ok(())
    }

    fn handle_user_discovery_announcement(
        &self,
        contact_id: UserID,
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

                if !self.utils.verify_pubkey_and_signature_from(
                    contact_id,
                    signed_data.encode_to_vec(),
                    signed_data.public_key,
                    asd.signature,
                )? {
                    return Err(UserDiscoveryError::MaliciousAnnouncementData(format!(
                        "signature invalid or public key does not match with stored one",
                    )));
                }

                let mut config = self.get_config()?;
                config.promotion_version += 1;
                self.store.update_config(to_allocvec(&config)?)?;

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
                        verification_state: None,
                    }),
                    ..Default::default()
                };

                self.store
                    .push_promotion(config.promotion_version, message.encode_to_vec())?;

                Ok(())
            }
            Err(err) => {
                return Err(UserDiscoveryError::ShamirsSecret(err.to_string()));
            }
        }
    }

    fn handle_user_discovery_promotion(
        &self,
        contact_id: UserID,
        uda: UserDiscoveryPromotion,
    ) {

        // contact_id
        // uda.promotion_id
        // uda.public_id
        // uda.threshold
        // uda.announcement_share
        // uda.verification_state

        // store this into the received_promotion_table 
        // check if the threshold is reached
        // in case thr threshold is reached -> CALL STORE -> NEW USER
        // otherwise do nothing

    }

}

#[cfg(test)]
mod tests {

    use crate::user_discovery::stores::InMemoryStore;
    use crate::user_discovery::traits::tests::TestingUtils;
    use crate::user_discovery::{UserDiscovery, UserDiscoveryVersion, UserID};
    use prost::Message;

    fn get_version_bytes(announcement: u32, promotion: u32) -> Vec<u8> {
        UserDiscoveryVersion {
            announcement,
            promotion,
        }
        .encode_to_vec()
    }

    fn zero() -> Vec<u8> {
        get_version_bytes(0, 0)
    }

    fn get_ud(user_id: UserID, friends: &[UserID]) -> UserDiscovery<InMemoryStore, TestingUtils> {
        let store = InMemoryStore::default();
        store.set_friends(friends.iter().copied().collect());
        let ud = UserDiscovery::new(store.to_owned(), TestingUtils::default()).unwrap();

        ud.initialize_or_update(3, user_id, vec![user_id as u8; 32])
            .unwrap();

        let version = ud.get_current_version().unwrap();

        assert_eq!(version, get_version_bytes(1, 0));
        ud
    }

    fn init() {
        tracing_subscriber::fmt()
            .with_max_level(tracing::Level::DEBUG)
            .init();
    }

    fn request_and_handle_messages(
        from: (UserID, &UserDiscovery<InMemoryStore, TestingUtils>),
        to: (UserID, &UserDiscovery<InMemoryStore, TestingUtils>),
        messages_count: usize,
    ) {
        // From sends a message with his current version to To
        let to_received_version = &from.1.get_current_version().unwrap();
        assert_eq!(
            to.1.should_request_new_messages(from.0, to_received_version)
                .unwrap(),
            true
        );

        // As To has a older version stored he sends a request to From: Give me all messages since version.
        let from_request_version_from_to =
            to.1.get_contact_version(from.0).unwrap().unwrap_or(zero());

        let new_messages = from
            .1
            .get_new_messages(to.0, &from_request_version_from_to)
            .unwrap();

        assert_eq!(new_messages.len(), messages_count);

        to.1.handle_user_discovery_messages(from.0, new_messages)
            .unwrap();

        assert_eq!(
            to.1.should_request_new_messages(from.0, &from.1.get_current_version().unwrap())
                .unwrap(),
            false
        );
    }

    #[tokio::test]
    async fn test_initialize_user_discovery() {
        init();

        const ALICE: UserID = 0;
        const BOB: UserID = 1;
        const CHARLIE: UserID = 2;
        const DAVID: UserID = 3;
        const FRANK: UserID = 4;

        let alice_ud = get_ud(ALICE, &[BOB, CHARLIE]);
        let bob_ud = get_ud(BOB, &[ALICE, CHARLIE, DAVID]);
        let charlie_ud = get_ud(CHARLIE, &[ALICE, BOB, DAVID, FRANK]);
        let david_ud = get_ud(DAVID, &[BOB, CHARLIE]);
        let frank_ud = get_ud(FRANK, &[CHARLIE]);

        {
            // Alice send UDA to Bob and Charlie
            request_and_handle_messages((ALICE, &alice_ud), (BOB, &bob_ud), 1);
            request_and_handle_messages((ALICE, &alice_ud), (CHARLIE, &charlie_ud), 1);
        }

        {
            // This now contains Bob's own announcement in addition this now also contains the promotion from Alice 
            request_and_handle_messages((BOB, &bob_ud), (DAVID, &david_ud), 2);
            request_and_handle_messages((BOB, &bob_ud), (CHARLIE, &charlie_ud), 2);
        }

        todo!();
    }
}
