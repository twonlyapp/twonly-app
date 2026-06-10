use crate::error::Result;
use aes_gcm::aead::rand_core::RngCore;
use aes_gcm::aead::{Aead, AeadCore, KeyInit, OsRng};
use aes_gcm::{Aes256Gcm, Key, Nonce};
use hkdf::Hkdf;
use serde::{Deserialize, Serialize};
use sha2::Sha256;
use zeroize::{Zeroize, ZeroizeOnDrop};

/// `MainKey` is responsible for handling the cryptographically secure, immutable master key.
/// It uses HKDF to derive subordinate keys (Authentication Token, Backup Key, Media Main Key).
#[derive(Debug, PartialEq, Zeroize, ZeroizeOnDrop, Serialize, Deserialize)]
pub struct MainKey {
    /// The 32-byte main master key
    main_key: [u8; 32],
}

#[derive(Debug)]
pub(crate) enum DatabaseKey {
    RustDb,
}

impl MainKey {
    /// Generates a new cryptographically secure MainKey.
    pub fn generate() -> Self {
        let mut main_key = [0u8; 32];
        OsRng.fill_bytes(&mut main_key);
        Self { main_key }
    }

    /// Download token required to download a backup.
    /// This ensures that the user who tries to download the backup must have knowledge over the
    /// main key
    pub fn get_backup_download_token(&self) -> [u8; 32] {
        self.derive_key(b"backup_download_token")
    }

    /// Uses as a password to authenitcate agains the server
    pub fn get_login_token(&self) -> [u8; 32] {
        self.derive_key(b"server_auth_token")
    }

    /// Derives the database encryption key.
    pub(crate) fn get_database_key(&self, db: DatabaseKey) -> String {
        let db_name = match db {
            DatabaseKey::RustDb => b"rust_db",
        };
        let info = [b"database_key_", db_name as &[u8]].concat();
        let key = self.derive_key(&info);
        hex::encode(key)
    }

    /// Encrypts a backup payload.
    /// The backup key is derived using HKDF from the main key.
    pub fn encrypt_backup(&self, backup_payload: &[u8]) -> Vec<u8> {
        self.encrypt_with_info(b"backup_key", backup_payload)
    }

    /// Decrypts a backup payload.
    pub fn decrypt_backup(&self, encrypted_backup: &[u8]) -> Result<Vec<u8>> {
        self.decrypt_with_info(b"backup_key", encrypted_backup)
    }

    // Encrypts a newly generated media key using the derived Media Main Key.
    // pub fn encrypt_media_key(&self, media_key: &[u8; 32]) -> Vec<u8> {
    //     self.encrypt_with_info(b"media_main_key", media_key)
    // }

    // Decrypts a wrapped media key using the derived Media Main Key.
    // pub fn decrypt_media_key(&self, wrapped_media_key: &[u8]) -> Result<[u8; 32]> {
    //     let decrypted = self.decrypt_with_info(b"media_main_key", wrapped_media_key)?;

    //     if decrypted.len() != 32 {
    //         return Err("Invalid decrypted key length".to_string())?;
    //     }

    //     let mut result = [0u8; 32];
    //     result.copy_from_slice(&decrypted);
    //     Ok(result)
    // }

    fn derive_key(&self, info: &[u8]) -> [u8; 32] {
        let hk = Hkdf::<Sha256>::new(None, &self.main_key);
        let mut okm = [0u8; 32];
        hk.expand(info, &mut okm).expect("HKDF expand failed");
        okm
    }

    fn encrypt_with_info(&self, info: &[u8], payload: &[u8]) -> Vec<u8> {
        let derived_key = self.derive_key(info);
        let key = Key::<Aes256Gcm>::from_slice(&derived_key);
        let cipher = Aes256Gcm::new(key);
        let nonce = Aes256Gcm::generate_nonce(&mut OsRng);
        let ciphertext = cipher
            .encrypt(&nonce, payload)
            .expect("encryption failure!");

        let mut result = nonce.to_vec();
        result.extend_from_slice(&ciphertext);
        result
    }

    fn decrypt_with_info(&self, info: &[u8], encrypted_data: &[u8]) -> Result<Vec<u8>> {
        if encrypted_data.len() < 12 {
            return Err("Invalid encrypted data length".to_string())?;
        }

        let derived_key = self.derive_key(info);
        let key = Key::<Aes256Gcm>::from_slice(&derived_key);
        let cipher = Aes256Gcm::new(key);
        let nonce = Nonce::from_slice(&encrypted_data[..12]);
        let ciphertext = &encrypted_data[12..];

        Ok(cipher
            .decrypt(nonce, ciphertext)
            .map_err(|_| "Decryption failure".to_string())?)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_backup_encryption_decryption_success() {
        let km = MainKey::generate();
        let payload = b"this is a secret backup payload";

        let encrypted = km.encrypt_backup(payload);
        let decrypted = km.decrypt_backup(&encrypted).unwrap();

        assert_eq!(payload.as_slice(), decrypted.as_slice());
    }

    #[test]
    fn test_backup_decryption_tampered_payload_fails() {
        let km = MainKey::generate();
        let payload = b"this is a secret backup payload";
        let mut encrypted = km.encrypt_backup(payload);

        // Tamper with the ciphertext (assuming length > 12)
        let last_idx = encrypted.len() - 1;
        encrypted[last_idx] ^= 1; // Flip a bit

        let result = km.decrypt_backup(&encrypted);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err().to_string(), "Decryption failure");
    }

    #[test]
    fn test_backup_decryption_too_short_fails() {
        let km = MainKey::generate();
        let short_payload = vec![0u8; 10]; // Less than 12 bytes nonce

        let result = km.decrypt_backup(&short_payload);
        assert!(result.is_err());
        assert_eq!(
            result.unwrap_err().to_string(),
            "Invalid encrypted data length"
        );
    }

    // #[test]
    // fn test_media_key_encryption_decryption_success() {
    //     let km = MainKey::generate();
    //     let mut media_key = [0u8; 32];
    //     OsRng.fill_bytes(&mut media_key);

    //     let encrypted = km.encrypt_media_key(&media_key);
    //     let decrypted = km.decrypt_media_key(&encrypted).unwrap();

    //     assert_eq!(media_key, decrypted);
    // }

    // #[test]
    // fn test_media_key_decryption_tampered_payload_fails() {
    //     let km = MainKey::generate();
    //     let mut media_key = [0u8; 32];
    //     OsRng.fill_bytes(&mut media_key);

    //     let mut encrypted = km.encrypt_media_key(&media_key);

    //     // Tamper with the ciphertext
    //     let last_idx = encrypted.len() - 1;
    //     encrypted[last_idx] ^= 1;

    //     let result = km.decrypt_media_key(&encrypted);
    //     assert!(result.is_err());
    //     assert_eq!(result.unwrap_err().to_string(), "Decryption failure");
    // }

    // #[test]
    // fn test_media_key_decryption_too_short_fails() {
    //     let km = MainKey::generate();
    //     let short_payload = vec![0u8; 10]; // Less than 12 bytes nonce

    //     let result = km.decrypt_media_key(&short_payload);
    //     assert!(result.is_err());
    //     assert_eq!(
    //         result.unwrap_err().to_string(),
    //         "Invalid encrypted data length"
    //     );
    // }

    // #[test]
    // fn test_media_key_decryption_wrong_decrypted_length_fails() {
    //     let km = MainKey::generate();

    //     // Manually encrypt a 31 byte payload
    //     let hk = Hkdf::<Sha256>::new(None, &km.main_key);
    //     let mut media_main_key = [0u8; 32];
    //     hk.expand(b"media_main_key", &mut media_main_key)
    //         .expect("HKDF expand failed");

    //     let key = Key::<Aes256Gcm>::from_slice(&media_main_key);
    //     let cipher = Aes256Gcm::new(key);
    //     let nonce = Aes256Gcm::generate_nonce(&mut OsRng);
    //     let payload = vec![0u8; 31];
    //     let ciphertext = cipher
    //         .encrypt(&nonce, payload.as_ref())
    //         .expect("encryption failure");

    //     let mut encrypted = nonce.to_vec();
    //     encrypted.extend_from_slice(&ciphertext);

    //     let result = km.decrypt_media_key(&encrypted);
    //     assert!(result.is_err());
    //     assert_eq!(
    //         result.unwrap_err().to_string(),
    //         "Invalid decrypted key length"
    //     );
    // }
}
