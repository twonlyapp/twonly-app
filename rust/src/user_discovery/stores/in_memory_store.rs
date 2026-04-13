use crate::user_discovery::error::UserDiscoveryError;
use crate::user_discovery::traits::UserDiscoveryStore;
use crate::user_discovery::UserID;
use std::collections::{HashMap, HashSet};
use std::sync::{Arc, Mutex};

#[derive(Default)]
pub(crate) struct Storage {
    config: Option<Vec<u8>>,
    unused_shares: Vec<Vec<u8>>,
    used_shares: HashMap<UserID, Vec<u8>>,
    contact_versions: HashMap<UserID, Vec<u8>>,
    friends: HashSet<UserID>,
    promotions: Vec<Vec<u8>>,
}

#[derive(Default, Clone)]
pub struct InMemoryStore {
    pub(crate) storage: Arc<Mutex<Storage>>,
}

impl InMemoryStore {
    fn storage(&self) -> std::sync::MutexGuard<'_, Storage> {
        self.storage.lock().unwrap()
    }
    pub fn set_friends(&self, friends: HashSet<UserID>) {
        self.storage().friends = friends;
    }
}

impl UserDiscoveryStore for InMemoryStore {
    fn get_config(&self) -> crate::user_discovery::error::Result<Vec<u8>> {
        if let Some(storage) = self.storage().config.clone() {
            return Ok(storage);
        }
        Err(UserDiscoveryError::NotInitialized)
    }

    fn update_config(&self, update: Vec<u8>) -> crate::user_discovery::error::Result<()> {
        self.storage().config = Some(update);
        Ok(())
    }

    fn set_shares(&self, shares: Vec<Vec<u8>>) -> crate::user_discovery::error::Result<()> {
        self.storage().unused_shares = shares;
        Ok(())
    }

    fn get_share_for_contact(
        &self,
        contact_id: UserID,
    ) -> crate::user_discovery::error::Result<Vec<u8>> {
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

    fn get_contact_version(
        &self,
        contact_id: UserID,
    ) -> crate::user_discovery::error::Result<Option<Vec<u8>>> {
        Ok(self.storage().contact_versions.get(&contact_id).cloned())
    }

    fn set_contact_version(
        &self,
        contact_id: UserID,
        update: Vec<u8>,
    ) -> crate::user_discovery::error::Result<()> {
        self.storage().contact_versions.insert(contact_id, update);
        Ok(())
    }

    fn push_promotion(
        &self,
        version: u32,
        promotion: Vec<u8>,
    ) -> crate::user_discovery::error::Result<()> {
        let mut storage = self.storage();
        // println!("{} != {}", version, storage.promotions.len());
        if version as usize != storage.promotions.len() + 1 {
            return Err(UserDiscoveryError::PushedInvalidVersion);
        }
        storage.promotions.push(promotion);
        Ok(())
    }

    fn get_promotions_after_version(
        &self,
        version: u32,
    ) -> crate::user_discovery::error::Result<Vec<Vec<u8>>> {
        let storage = self.storage();
        let elements = storage.promotions[(version as usize)..].to_vec();
        Ok(elements)
    }
}
