/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

pub(crate) mod backup_password_keys;
mod identity_key;
mod main_key;

use crate::error::Result;
use crate::error::TwonlyError;
pub(crate) use crate::keys::backup_password_keys::BackupPasswordKeys;
pub(crate) use crate::keys::identity_key::signal_identity_key::SignalIdentityKey;
pub(crate) use crate::keys::main_key::{DatabaseKey, MainKey};
use crate::secure_storage::SecureStorage;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use zeroize::{Zeroize, ZeroizeOnDrop};

const KEY_MANAGER_ID: &str = "twonly_key_manager";
const KEY_MANAGER_V2_PREFIX: &[u8] = b"TWONLY_KEY_MANAGER_V2\0";

#[derive(Debug, PartialEq, Zeroize, ZeroizeOnDrop, Serialize, Deserialize)]
pub(crate) struct KeyManager {
    pub(crate) user_id: Option<i64>,
    pub(crate) main_key: MainKey,
    pub(crate) signal_identity: Option<SignalIdentityKey>,
    pub(crate) backup_password: Option<BackupPasswordKeys>,
}

impl KeyManager {
    pub fn generate() -> Result<Self> {
        Ok(KeyManager {
            main_key: MainKey::generate(),
            signal_identity: None,
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

        Self::from_bytes(&bytes)
    }

    /// Stores the main key into the secure keychain/local storage.
    pub fn store_to_keychain(&self, storage: &SecureStorage) -> Result<()> {
        let serialized = self.to_bytes()?;

        let hex_key = hex::encode(serialized);
        storage.write(KEY_MANAGER_ID, &hex_key)?;

        Ok(())
    }

    /// Removes the KeyManager from the secure keychain/local storage.
    pub fn remove_from_keychain(storage: &SecureStorage) -> Result<()> {
        storage.delete(KEY_MANAGER_ID)?;
        Ok(())
    }

    pub(crate) fn to_bytes(&self) -> Result<Vec<u8>> {
        let payload = postcard::to_allocvec(self)?;
        let mut serialized = Vec::with_capacity(KEY_MANAGER_V2_PREFIX.len() + payload.len());
        serialized.extend_from_slice(KEY_MANAGER_V2_PREFIX);
        serialized.extend_from_slice(&payload);
        Ok(serialized)
    }

    pub(crate) fn from_bytes(bytes: &[u8]) -> Result<Self> {
        if let Some(payload) = bytes.strip_prefix(KEY_MANAGER_V2_PREFIX) {
            return Ok(postcard::from_bytes(payload)?);
        }

        // Key managers written before V2 used postcard's positional encoding and
        // embedded a signed-prekey HashMap in the Signal identity. Read that
        // shape once and discard the obsolete private-key copy during migration.
        let legacy: LegacyKeyManager = postcard::from_bytes(bytes)?;
        Ok(legacy.into_current())
    }
}

#[derive(Deserialize)]
struct LegacyKeyManager {
    user_id: Option<i64>,
    main_key: MainKey,
    signal_identity: Option<LegacySignalIdentityKey>,
    backup_password: Option<BackupPasswordKeys>,
}

impl LegacyKeyManager {
    fn into_current(self) -> KeyManager {
        KeyManager {
            user_id: self.user_id,
            main_key: self.main_key,
            signal_identity: self
                .signal_identity
                .map(LegacySignalIdentityKey::into_current),
            backup_password: self.backup_password,
        }
    }
}

#[derive(Deserialize)]
struct LegacySignalIdentityKey {
    identity_key_pair_structure: Vec<u8>,
    registration_id: i64,
    pre_key_store: HashMap<i64, Vec<u8>>,
}

impl LegacySignalIdentityKey {
    fn into_current(mut self) -> SignalIdentityKey {
        for value in self.pre_key_store.values_mut() {
            value.zeroize();
        }
        self.pre_key_store.clear();
        SignalIdentityKey {
            identity_key_pair_structure: std::mem::take(&mut self.identity_key_pair_structure),
            registration_id: self.registration_id,
        }
    }
}

impl Drop for LegacySignalIdentityKey {
    fn drop(&mut self) {
        self.identity_key_pair_structure.zeroize();
        self.registration_id.zeroize();
        for value in self.pre_key_store.values_mut() {
            value.zeroize();
        }
        self.pre_key_store.clear();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[derive(Serialize)]
    struct OldKeyManager<'a> {
        user_id: Option<i64>,
        main_key: &'a MainKey,
        signal_identity: Option<OldSignalIdentity>,
        backup_password: Option<&'a BackupPasswordKeys>,
    }

    #[derive(Serialize)]
    struct OldSignalIdentity {
        identity_key_pair_structure: Vec<u8>,
        registration_id: i64,
        pre_key_store: HashMap<i64, Vec<u8>>,
    }

    #[test]
    fn reads_legacy_key_manager_and_drops_pre_key_store() {
        let key_manager = KeyManager::generate().unwrap();
        let legacy = OldKeyManager {
            user_id: Some(42),
            main_key: &key_manager.main_key,
            signal_identity: Some(OldSignalIdentity {
                identity_key_pair_structure: vec![1, 2, 3],
                registration_id: 7,
                pre_key_store: HashMap::from([(1, vec![4, 5, 6])]),
            }),
            backup_password: None,
        };
        let bytes = postcard::to_allocvec(&legacy).unwrap();

        let migrated = KeyManager::from_bytes(&bytes).unwrap();
        assert_eq!(migrated.user_id, Some(42));
        assert_eq!(
            migrated.signal_identity,
            Some(SignalIdentityKey {
                identity_key_pair_structure: vec![1, 2, 3],
                registration_id: 7,
            })
        );
    }

    #[test]
    fn v2_roundtrip_is_prefixed() {
        let key_manager = KeyManager::generate().unwrap();
        let bytes = key_manager.to_bytes().unwrap();
        assert!(bytes.starts_with(KEY_MANAGER_V2_PREFIX));
        assert_eq!(KeyManager::from_bytes(&bytes).unwrap(), key_manager);
    }
}
