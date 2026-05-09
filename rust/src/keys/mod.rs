mod identity_key;
mod main_key;

use crate::backup::backup_password::BackupPasswordKeys;
use crate::error::Result;
use crate::error::TwonlyError;
pub(crate) use crate::keys::identity_key::IdentityKey;
pub(crate) use crate::keys::main_key::{DatabaseKey, MainKey};
use crate::secure_storage::SecureStorage;
use aes_gcm::Aes256Gcm;
use serde::{Deserialize, Serialize};
use zeroize::{Zeroize, ZeroizeOnDrop};

const KEY_MANAGER_ID: &str = "twonly_key_manager";

#[derive(Debug, PartialEq, Zeroize, ZeroizeOnDrop, Serialize, Deserialize)]
pub(crate) struct KeyManager {
    pub(crate) user_id: Option<i64>,
    pub(crate) main_key: MainKey,
    pub(crate) identity_keys: Vec<IdentityKey>,
    pub(crate) backup_password: Option<BackupPasswordKeys>,
}

impl KeyManager {
    pub fn generate() -> Result<Self> {
        Ok(KeyManager {
            main_key: MainKey::generate(),
            identity_keys: vec![],
            backup_password: None,
            user_id: None,
        })
    }

    /// Tries to load the KeyManager from the secure keychain/local storage.
    pub fn try_from_keychain(storage: &SecureStorage) -> Result<Self> {
        let hex_key = storage
            .read(KEY_MANAGER_ID)?
            .ok_or_else(|| TwonlyError::MissingMainKey)?;

        let bytes = hex::decode(hex_key)?;

        let main_key: KeyManager = postcard::from_bytes(&bytes)?;

        Ok(main_key)
    }

    /// Stores the main key into the secure keychain/local storage.
    pub fn store_to_keychain(&self, storage: &SecureStorage) -> Result<()> {
        let serialized = postcard::to_allocvec(self)?;

        let hex_key = hex::encode(serialized);
        storage.write(KEY_MANAGER_ID, &hex_key)?;

        Ok(())
    }
}
