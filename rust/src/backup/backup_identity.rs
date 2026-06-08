use crate::error::{Result, TwonlyError};
use crate::keys::{BackupPasswordKeys, KeyManager};
use crate::secure_storage::SecureStorage;
use aes_gcm::aead::rand_core::RngCore;
use aes_gcm::aead::{Aead, KeyInit, OsRng};
use aes_gcm::{Aes256Gcm, Nonce};

pub(crate) struct BackupIdentity();

impl BackupIdentity {
    pub(crate) fn encrypt_key_manager(key_manager: &KeyManager) -> Result<Vec<u8>> {
        let Some(keys) = &key_manager.backup_password else {
            return Err(TwonlyError::Generic("No backup password".into()));
        };

        let serialized_bytes = postcard::to_allocvec(key_manager)?;

        let key = aes_gcm::Key::<Aes256Gcm>::from_slice(&keys.encryption_key);
        let cipher = Aes256Gcm::new(key);

        let mut nonce_bytes = [0u8; 12];
        OsRng.fill_bytes(&mut nonce_bytes);
        let nonce = Nonce::from_slice(&nonce_bytes);

        let ciphertext = cipher.encrypt(nonce, serialized_bytes.as_slice())?;

        let mut encrypted_bytes = vec![];
        encrypted_bytes.extend_from_slice(&nonce_bytes);
        encrypted_bytes.extend_from_slice(&ciphertext);

        Ok(encrypted_bytes)
    }

    pub(crate) fn restore_key_manager(
        secure_storage: &SecureStorage,
        backup_password_keys: &BackupPasswordKeys,
        encrypted_bytes: &[u8],
    ) -> Result<()> {
        if encrypted_bytes.len() < 12 {
            return Err(TwonlyError::Generic(
                "Invalid encrypted backup length".into(),
            ));
        }

        let (nonce_bytes, ciphertext) = encrypted_bytes.split_at(12);
        let nonce = Nonce::from_slice(nonce_bytes);

        let key = aes_gcm::Key::<Aes256Gcm>::from_slice(&backup_password_keys.encryption_key);
        let cipher = Aes256Gcm::new(key);

        let decrypted_bytes = cipher.decrypt(nonce, ciphertext)?;

        let key_manager: KeyManager = postcard::from_bytes(&decrypted_bytes)?;

        key_manager.store_to_keychain(secure_storage)?;

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_backup_encryption_decryption() {
        let secure_storage = SecureStorage::new("testing");
        let mut key_manager = KeyManager::generate().unwrap();
        let password = "my_secure_password";
        let salt = 10;

        let backup_keys = BackupPasswordKeys::from_password(password, salt).unwrap();
        key_manager.backup_password = Some(backup_keys.clone());

        let encrypted = BackupIdentity::encrypt_key_manager(&key_manager).unwrap();

        BackupIdentity::restore_key_manager(&secure_storage, &backup_keys, &encrypted).unwrap();

        let restored = KeyManager::try_from_keychain(&secure_storage).unwrap();

        assert_eq!(restored, key_manager);
    }
}
