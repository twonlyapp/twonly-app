use crate::error::{Result, TwonlyError};
use crate::keys::KeyManager;
use crate::secure_storage::{self, SecureStorage};
use aes_gcm::aead::rand_core::RngCore;
use aes_gcm::aead::{Aead, KeyInit, OsRng};
use aes_gcm::{Aes256Gcm, Nonce};
use mdk_core::key_packages;
use scrypt::{scrypt, Params};
use serde::{Deserialize, Serialize};
use zeroize::{Zeroize, ZeroizeOnDrop};

#[derive(Debug, Clone, PartialEq, Zeroize, ZeroizeOnDrop, Serialize, Deserialize)]
pub(crate) struct BackupPasswordKeys {
    backup_id: [u8; 32],
    encryption_key: [u8; 32],
}

impl BackupPasswordKeys {
    pub(crate) fn new(backup_id: [u8; 32], encryption_key: [u8; 32]) -> Self {
        Self {
            backup_id,
            encryption_key,
        }
    }

    pub(crate) fn from_password(password: &str, username: &str) -> Result<Self> {
        let params = Params::new(17, 8, 1)?;
        let mut output = [0u8; 64];

        scrypt(
            password.as_bytes(),
            username.as_bytes(),
            &params,
            &mut output,
        )?;

        let mut backup_id = [0u8; 32];
        let mut encryption_key = [0u8; 32];
        backup_id.copy_from_slice(&output[0..32]);
        encryption_key.copy_from_slice(&output[32..64]);

        Ok(Self::new(backup_id, encryption_key))
    }

    fn encrypt_key_manager(key_manager: KeyManager) -> Result<Vec<u8>> {
        let Some(keys) = &key_manager.backup_password else {
            return Err(TwonlyError::Generic("No backup password".into()));
        };

        let serialized_bytes = postcard::to_allocvec(&key_manager)?;

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
        secure_storage: SecureStorage,
        encrypted_bytes: &[u8],
        keys: &BackupPasswordKeys,
    ) -> Result<()> {
        if encrypted_bytes.len() < 12 {
            return Err(TwonlyError::Generic(
                "Invalid encrypted backup length".into(),
            ));
        }

        let (nonce_bytes, ciphertext) = encrypted_bytes.split_at(12);
        let nonce = Nonce::from_slice(nonce_bytes);

        let key = aes_gcm::Key::<Aes256Gcm>::from_slice(&keys.encryption_key);
        let cipher = Aes256Gcm::new(key);

        let decrypted_bytes = cipher.decrypt(nonce, ciphertext)?;

        let key_manager: KeyManager = postcard::from_bytes(&decrypted_bytes)?;

        key_manager.store_to_keychain(&secure_storage)?;

        Ok(())
    }
}

#[derive(Debug, PartialEq, Zeroize, ZeroizeOnDrop, Serialize, Deserialize)]
pub(crate) struct BackupPlainTextContent {
    pub(crate) user_id: i64,
    pub(crate) key_manager: KeyManager,
}

impl BackupPlainTextContent {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_backup_encryption_decryption() {
        let mut key_manager = KeyManager::generate().unwrap();
        let password = "my_secure_password";
        let salt = "my_random_salt";

        let keys = BackupPasswordKeys::from_password(password, salt).unwrap();
        key_manager.backup_password = Some(keys.clone());

        let content = BackupPlainTextContent {
            user_id: 12345,
            key_manager,
        };

        let encrypted = content.get_encrypted_backup().unwrap();
        let decrypted = BackupPlainTextContent::from_encrypted_backup(&encrypted, &keys).unwrap();

        assert_eq!(content.user_id, decrypted.user_id);
        assert_eq!(content.key_manager.main_key, decrypted.key_manager.main_key);
    }
}
