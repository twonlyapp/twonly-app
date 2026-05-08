mod backup_password;
mod backup_passwordless;
mod identity_key;
mod main_key;

pub(crate) use crate::keys::main_key::{DatabaseKey, MainKey};
use crate::secure_storage::SecureStorage;
use crate::{error::Result, keys::identity_key::IdentityKey};
use serde::{Deserialize, Serialize};
use zeroize::{Zeroize, ZeroizeOnDrop};

const KEY_MANAGER_ID: &str = "twonly_key_manager";

#[derive(Zeroize, ZeroizeOnDrop, Serialize, Deserialize)]
pub(crate) struct KeyManager {
    pub(crate) main_key: MainKey,
    pub(crate) identity_keys: Vec<IdentityKey>,
}

impl KeyManager {
    pub fn generate() -> Result<Self> {
        Ok(KeyManager {
            main_key: MainKey::generate(),
            identity_keys: vec![],
        })
    }

    /// Tries to load the KeyManager from the secure keychain/local storage.
    pub fn try_from_keychain(storage: &SecureStorage) -> Result<Self> {
        let hex_key = storage
            .read(KEY_MANAGER_ID)?
            .ok_or_else(|| "Main key not found in keychain".to_string())?;

        let bytes = hex::decode(hex_key).map_err(|e| format!("Failed to decode hex key: {}", e))?;

        let main_key: KeyManager = postcard::from_bytes(&bytes)
            .map_err(|e| format!("Failed to deserialize KeyManager: {}", e))?;

        Ok(main_key)
    }

    /// Stores the main key into the secure keychain/local storage.
    pub fn store_to_keychain(&self, storage: &SecureStorage) -> Result<()> {
        let serialized = postcard::to_allocvec(self)
            .map_err(|e| format!("Failed to serialize KeyManager: {}", e))?;

        let hex_key = hex::encode(serialized);
        storage.write(KEY_MANAGER_ID, &hex_key)?;

        Ok(())
    }
}
