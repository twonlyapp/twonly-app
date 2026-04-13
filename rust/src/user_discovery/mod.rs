mod error;
pub mod stores;
mod traits;

use std::collections::HashMap;

use blahaj::{Share, Sharks};
use postcard::{from_bytes, to_allocvec};
use prost::Message;
use serde::{Deserialize, Serialize};
use crate::user_discovery::error::{Result, UserDiscoveryError};
use crate::user_discovery::traits::{AnnouncedUser, OtherPromotion, UserDiscoveryUtils};
use crate::user_discovery::user_discovery_message::{UserDiscoveryAnnouncement, UserDiscoveryPromotion};
use crate::user_discovery::user_discovery_message::user_discovery_promotion::AnnouncementShareDecrypted;
use crate::user_discovery::user_discovery_message::user_discovery_promotion::announcement_share_decrypted::SignedData;
pub use traits::UserDiscoveryStore;

#[cfg(test)]
static TRANSMITTED_NETWORK_BYTES: std::sync::OnceLock<std::sync::Mutex<usize>> =
    std::sync::OnceLock::new();

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
    // The users' id:
    user_id: UserID,
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
            user_id: 0,
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

        let signature = self.utils.sign_data(&signed_data.encode_to_vec())?;

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

    /// Returns all users discovery though the user discovery and there relations
    pub fn get_all_announced_users(
        &self,
    ) -> Result<HashMap<AnnouncedUser, Vec<(UserID, Option<i64>)>>> {
        self.store.get_all_announced_users()
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
                .get_own_promotions_after_version(received_version.promotion)?;
            messages.extend_from_slice(&promoting_messages);
        }
        #[cfg(test)]
        {
            let mut count = TRANSMITTED_NETWORK_BYTES.get().unwrap().lock().unwrap();
            for message in &messages {
                *count += message.len();
            }
        }
        // static TRANSMITTED_NETWORK_BYTES: std::sync::OnceLock<usize> = std::sync::OnceLock::new();
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
        // tracing::debug!("{received_version:?} >  {stored_version:?}");
        Ok(received_version.announcement > stored_version.announcement
            || received_version.promotion > stored_version.promotion)
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
            } else if let Some(udp) = message.user_discovery_promotion {
                self.handle_user_discovery_promotion(contact_id, udp)?;
            } else {
                tracing::warn!("Got unknown user discovery messaging. Ignoring it.");
                continue;
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

                if !self
                    .utils
                    .verify_stored_pubkey(contact_id, &signed_data.public_key)?
                {
                    return Err(UserDiscoveryError::MaliciousAnnouncementData(format!(
                        "public key does not match with stored one",
                    )));
                }

                if !self.utils.verify_signature(
                    &signed_data.encode_to_vec(),
                    &signed_data.public_key,
                    &asd.signature,
                )? {
                    return Err(UserDiscoveryError::MaliciousAnnouncementData(format!(
                        "signature invalid",
                    )));
                }

                tracing::debug!("Increased promotion version id.");
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
                        public_key_verified_timestamp: None,
                    }),
                    ..Default::default()
                };

                self.store.push_own_promotion(
                    contact_id,
                    config.promotion_version,
                    message.encode_to_vec(),
                )?;

                let announced_user = AnnouncedUser {
                    user_id: signed_data.user_id,
                    public_key: signed_data.public_key,
                    public_id: uda.public_id,
                };

                tracing::debug!(
                    "NEW PROMOTION: {} knows {}",
                    contact_id,
                    announced_user.user_id
                );
                // User is known, so add him to thr users relations
                self.store.push_new_user_relation(
                    contact_id,
                    announced_user,
                    None, // This flag mus be handled by the applications as this comes from an announcement.
                )?;

                Ok(())
            }
            Err(err) => Err(UserDiscoveryError::ShamirsSecret(err.to_string())),
        }
    }

    fn handle_user_discovery_promotion(
        &self,
        from_contact_id: UserID,
        udp: UserDiscoveryPromotion,
    ) -> Result<()> {
        tracing::debug!("Received a new UDP with public_id = {}.", &udp.public_id);

        self.store.store_other_promotion(OtherPromotion {
            from_contact_id,
            promotion_id: udp.promotion_id,
            threshold: udp.threshold as u8,
            public_id: udp.public_id,
            announcement_share: udp.announcement_share,
            public_key_verified_timestamp: udp.public_key_verified_timestamp,
        })?;

        if let Some(contact) = self.store.get_announced_user_by_public_id(udp.public_id)? {
            tracing::debug!(
                "NEW PROMOTION 2: {} knows {}",
                from_contact_id,
                contact.user_id
            );
            // The user is already known, just propagate the relation ship
            self.store.push_new_user_relation(
                from_contact_id,
                contact,
                udp.public_key_verified_timestamp,
            )?;
            return Ok(());
        }

        let promotions = self.store.get_other_promotions_by_public_id(udp.public_id);

        if promotions.len() < udp.threshold as usize {
            tracing::debug!(
                "Not enough shares ({} < {}) to decrypt announcement. Waiting for next share.",
                promotions.len(),
                udp.threshold
            );
            return Ok(());
        }

        tracing::debug!("Enough shares decrypting announcement.");

        let shares: Vec<_> = promotions
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

                    if !self.utils.verify_signature(
                        &signed_data.encode_to_vec(),
                        &signed_data.public_key,
                        &asd.signature,
                    )? {
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

                    let user_id = self.get_config()?.user_id;
                    for promotion in promotions {
                        // Do not store the announcement of the users itself.
                        // Or in case the promotion promotes myself
                        if promotion.from_contact_id == announced_user.user_id
                            || announced_user.user_id == user_id
                        {
                            continue;
                        }
                        tracing::debug!(
                            "NEW PROMOTION: {} knows {}",
                            promotion.from_contact_id,
                            announced_user.user_id
                        );
                        self.store.push_new_user_relation(
                            promotion.from_contact_id,
                            announced_user.clone(),
                            promotion.public_key_verified_timestamp,
                        )?;
                    }
                }
                Ok(())
            }
            Err(err) => Err(UserDiscoveryError::ShamirsSecret(err.to_string())),
        }
    }
}

#[cfg(test)]
mod tests {

    use std::collections::{HashMap, HashSet};
    use std::vec;

    use crate::user_discovery::stores::InMemoryStore;
    use crate::user_discovery::traits::tests::TestingUtils;
    use crate::user_discovery::{
        UserDiscovery, UserDiscoveryVersion, UserID, TRANSMITTED_NETWORK_BYTES,
    };
    use prost::Message;

    fn get_version_bytes(announcement: u32, promotion: u32) -> Vec<u8> {
        UserDiscoveryVersion {
            announcement,
            promotion,
        }
        .encode_to_vec()
    }

    fn get_ud(user_id: usize) -> UserDiscovery<InMemoryStore, TestingUtils> {
        let store = InMemoryStore::default();
        let ud = UserDiscovery::new(store.to_owned(), TestingUtils::default()).unwrap();

        ud.initialize_or_update(2, user_id as UserID, vec![user_id as u8; 32])
            .unwrap();

        let version = ud.get_current_version().unwrap();

        assert_eq!(version, get_version_bytes(1, 0));
        ud
    }

    fn assert_new_messages(
        from: (usize, &UserDiscovery<InMemoryStore, TestingUtils>),
        to: (usize, &UserDiscovery<InMemoryStore, TestingUtils>),
        has_new_messages: bool,
    ) {
        // From sends a message with his current version to To
        let to_received_version = &from.1.get_current_version().unwrap();
        assert_eq!(
            to.1.should_request_new_messages(from.0 as UserID, to_received_version)
                .unwrap(),
            has_new_messages
        );
    }

    fn request_and_handle_messages(
        from: (usize, &UserDiscovery<InMemoryStore, TestingUtils>),
        to: (usize, &UserDiscovery<InMemoryStore, TestingUtils>),
        messages_count: usize,
    ) {
        // From sends a message with his current version to To
        let to_received_version = &from.1.get_current_version().unwrap();
        assert_eq!(
            to.1.should_request_new_messages(from.0 as UserID, to_received_version)
                .unwrap(),
            true
        );

        // As To has a older version stored he sends a request to From: Give me all messages since version.
        let from_request_version_from_to =
            to.1.get_contact_version(from.0 as UserID)
                .unwrap()
                .unwrap_or(get_version_bytes(0, 0));

        let new_messages = from
            .1
            .get_new_messages(to.0 as UserID, &from_request_version_from_to)
            .unwrap();

        assert!(new_messages.len() <= messages_count);

        to.1.handle_user_discovery_messages(from.0 as UserID, new_messages)
            .unwrap();

        assert_eq!(
            to.1.should_request_new_messages(
                from.0 as UserID,
                &from.1.get_current_version().unwrap()
            )
            .unwrap(),
            false
        );
    }

    const ALICE: usize = 0;
    const BOB: usize = 1;
    const CHARLIE: usize = 2;
    const DAVID: usize = 3;
    const FRANK: usize = 4;
    const TEST_USER_COUNT: usize = 5;
    struct TestUsers {
        names: [&'static str; TEST_USER_COUNT],
        friends: [Vec<usize>; TEST_USER_COUNT],
        uds: Vec<UserDiscovery<InMemoryStore, TestingUtils>>,
    }

    impl TestUsers {
        fn get() -> Self {
            let names = ["ALICE", "BOB", "CHARLIE", "DAVID", "FRANK"];
            let mut uds = vec![];
            for index in 0..names.len() {
                uds.push(get_ud(index));
            }
            let friends = [
                vec![BOB, CHARLIE],
                vec![ALICE, CHARLIE, DAVID],
                vec![ALICE, BOB, DAVID, FRANK],
                vec![BOB, CHARLIE],
                vec![CHARLIE],
            ];
            Self {
                names,
                uds,
                friends,
            }
        }
    }

    #[tokio::test]
    async fn test_initialize_user_discovery() {
        pretty_env_logger::init();
        let counter = TRANSMITTED_NETWORK_BYTES.get_or_init(|| std::sync::Mutex::new(0));

        let users = TestUsers::get();

        fn to_all_friends(from: usize, message_count: usize, users: &TestUsers) {
            for friend in &users.friends[from] {
                tracing::debug!("From {} to {}", users.names[from], users.names[*friend]);

                if message_count == 0 {
                    assert_new_messages(
                        (from, &users.uds[from]),
                        (*friend, &users.uds[*friend]),
                        false,
                    );
                } else {
                    request_and_handle_messages(
                        (from, &users.uds[from]),
                        (*friend, &users.uds[*friend]),
                        message_count,
                    );
                }
            }
        }

        let message_flows = [
            // ALICE: own announcement sending to BOB and CHARLIE
            (ALICE, 1),
            // BOB: own announcement + promotion for ALICE
            (BOB, 2),
            // BOBs version should not have any new messages for his friends
            (BOB, 0),
            // ALICE: promotion for BOB
            (ALICE, 1),
            // CHARLIE: own announcement + promotion for ALICE, BOB
            (CHARLIE, 3),
            // DAVID: own announcement + promotion for BOB, CHARLIE
            (DAVID, 3),
            // BOB: promotion for CHARLIE, DAVID
            (BOB, 2),
            // CHARLIE: promotion for DAVID
            (CHARLIE, 1),
            // FRANK: own announcement +  promotion for CHARLIE
            (FRANK, 2),
            // CHARLIE: promotion for FRANK
            (CHARLIE, 1),
            // ALICE: promotion for CHARLIE
            (ALICE, 1),
        ];

        for (i, (from, count)) in message_flows.into_iter().enumerate() {
            tracing::debug!("MESSAGE FLOW: {i}");
            to_all_friends(from, count, &users);
        }

        tracing::debug!("Now all users should have the newest version.");

        for from in 0..TEST_USER_COUNT {
            for to in &users.friends[from] {
                tracing::debug!(
                    "Does {} has open messages for {}?",
                    &users.names[from],
                    &users.names[*to]
                );
                assert_new_messages((from, &users.uds[from]), (*to, &users.uds[*to]), false);
            }
        }

        tracing::debug!("Test if all exchanges where successful.");

        let announced_users_expected = [
            // ALICE should now know that BOB and CHARLIE, BOB and DAVID and CHARLIE and DAVID are friends.
            // Alice should also have one protected share from Frank.
            (
                ALICE,
                vec![
                    (BOB, vec![CHARLIE]), // ALICE knows Bob and that CHARLIE is connected with BOB
                    (CHARLIE, vec![BOB]), // ALICE knows CHARLIE and that BOB is connected with CHARLIE
                    (DAVID, vec![BOB, CHARLIE]), // ALICE knows DAVID and that BOB and CHARLIE are connected with DAVID
                ],
            ),
            (
                BOB,
                vec![
                    (ALICE, vec![CHARLIE]),
                    (CHARLIE, vec![ALICE, DAVID]),
                    (DAVID, vec![CHARLIE]),
                ],
            ),
            (
                CHARLIE,
                vec![
                    (ALICE, vec![BOB]),
                    (BOB, vec![ALICE, DAVID]),
                    (DAVID, vec![BOB]),
                    (FRANK, vec![]),
                ],
            ),
            (
                DAVID,
                vec![
                    (ALICE, vec![BOB, CHARLIE]),
                    (BOB, vec![CHARLIE]),
                    (CHARLIE, vec![BOB]),
                ],
            ),
            (FRANK, vec![(CHARLIE, vec![])]),
        ];

        for (user, announcements) in announced_users_expected {
            let announced_users2 = users.uds[user].get_all_announced_users().unwrap();
            let mut announced_users = HashMap::new();
            for a in announced_users2 {
                announced_users.insert(a.0.user_id, a.1.iter().map(|x| x.0).collect::<Vec<_>>());
            }
            tracing::debug!("{} knows now: {}", users.names[user], announced_users.len());
            assert_eq!(announced_users.len(), announcements.len());
            for (contact_id, announced_users_expected) in announcements {
                let announced_users = announced_users.get(&(contact_id as i64)).unwrap();
                tracing::debug!(
                    "{} knows now that {} has the following friends: {}",
                    users.names[user],
                    users.names[contact_id],
                    announced_users
                        .iter()
                        .map(|x| users.names[*x as usize])
                        .collect::<Vec<_>>()
                        .join(", ")
                );
                let announced_users: HashSet<i64> = announced_users.iter().cloned().collect();
                let announced_users_expected: HashSet<i64> = announced_users_expected
                    .iter()
                    .cloned()
                    .map(|x| x as i64)
                    .collect();
                assert_eq!(announced_users, announced_users_expected);
            }
        }

        let count = TRANSMITTED_NETWORK_BYTES.get().unwrap().lock().unwrap();

        tracing::info!("Transmitted a total of {} bytes.", *count);
    }
}
