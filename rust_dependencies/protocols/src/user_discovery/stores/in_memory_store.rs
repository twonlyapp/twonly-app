use crate::user_discovery::error::{Result, UserDiscoveryError};
use crate::user_discovery::traits::{AnnouncedUser, OtherPromotion, UserDiscoveryStore};
use crate::user_discovery::UserID;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};

#[derive(Default)]
pub(crate) struct Storage {
    config: Option<String>,
    unused_shares: Vec<Vec<u8>>,
    used_shares: HashMap<UserID, Vec<u8>>,
    contact_versions: HashMap<UserID, Vec<u8>>,
    other_promotions: Vec<OtherPromotion>,
    announced_users: HashMap<AnnouncedUser, Vec<(UserID, Option<i64>)>>,
    own_promotions: Vec<(UserID, Vec<u8>)>,
}

#[derive(Default, Clone)]
pub struct InMemoryStore {
    pub(crate) storage: Arc<Mutex<Storage>>,
}

impl InMemoryStore {
    fn storage(&self) -> std::sync::MutexGuard<'_, Storage> {
        self.storage.lock().unwrap()
    }
}

impl UserDiscoveryStore for InMemoryStore {
    async fn get_config(&self) -> Result<String> {
        if let Some(storage) = self.storage().config.clone() {
            return Ok(storage);
        }
        Err(UserDiscoveryError::NotInitialized)
    }

    async fn update_config(&self, update: String) -> Result<()> {
        self.storage().config = Some(update);
        Ok(())
    }

    async fn set_shares(&self, shares: Vec<Vec<u8>>) -> Result<()> {
        self.storage().used_shares.clear();
        self.storage().unused_shares = shares;
        Ok(())
    }

    async fn get_share_for_contact(&self, contact_id: UserID) -> Result<Vec<u8>> {
        let mut storage = self.storage();
        if let Some(share) = storage.used_shares.get(&contact_id) {
            return Ok(share.to_vec());
        }
        if let Some(new_share) = storage.unused_shares.pop() {
            storage.used_shares.insert(contact_id, new_share.clone());
            return Ok(new_share);
        }
        Err(UserDiscoveryError::NoSharesLeft)
    }

    async fn get_contact_version(&self, contact_id: UserID) -> Result<Option<Vec<u8>>> {
        Ok(self.storage().contact_versions.get(&contact_id).cloned())
    }

    async fn set_contact_version(&self, contact_id: UserID, update: Vec<u8>) -> Result<()> {
        self.storage().contact_versions.insert(contact_id, update);
        Ok(())
    }

    async fn push_own_promotion(
        &self,
        contact_id: UserID,
        version: u32,
        promotion: Vec<u8>,
    ) -> Result<()> {
        let mut storage = self.storage();
        // println!("{} != {}", version, storage.promotions.len());
        if version as usize != storage.own_promotions.len() + 1 {
            return Err(UserDiscoveryError::PushedInvalidVersion);
        }
        storage.own_promotions.push((contact_id, promotion));
        Ok(())
    }

    async fn get_own_promotions_after_version(&self, version: u32) -> Result<Vec<Vec<u8>>> {
        let storage = self.storage();
        let elements = storage.own_promotions[(version as usize)..]
            .into_iter()
            .map(|(_, promotion)| promotion.to_owned())
            .collect();
        Ok(elements)
    }

    async fn store_other_promotion(&self, promotion: OtherPromotion) -> Result<()> {
        self.storage().other_promotions.push(promotion);
        Ok(())
    }

    async fn get_other_promotions_by_public_id(
        &self,
        public_id: i64,
    ) -> Result<Vec<OtherPromotion>> {
        Ok(self
            .storage()
            .other_promotions
            .iter()
            .filter(|other| other.public_id == public_id)
            .map(OtherPromotion::to_owned)
            .collect())
    }

    async fn get_announced_user_by_public_id(
        &self,
        public_id: i64,
    ) -> Result<Option<AnnouncedUser>> {
        Ok(self
            .storage()
            .announced_users
            .iter()
            .find(|(u, _)| u.public_id == public_id)
            .map(|u| u.0.to_owned()))
    }

    async fn get_all_announced_users(
        &self,
    ) -> Result<HashMap<AnnouncedUser, Vec<(UserID, Option<i64>)>>> {
        Ok(self.storage().announced_users.clone())
    }

    async fn push_new_user_relation(
        &self,
        from_contact_id: UserID,
        announced_user: AnnouncedUser,
        public_key_verified_timestamp: Option<i64>,
    ) -> Result<()> {
        let mut storage = self.storage();
        let entry = storage
            .announced_users
            .entry(announced_user.clone())
            .or_insert(vec![]);
        if announced_user.user_id != from_contact_id {
            entry.push((from_contact_id, public_key_verified_timestamp));
        }
        Ok(())
    }
}
