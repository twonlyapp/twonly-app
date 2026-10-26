/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::error::Result;
use aes_gcm::aead::{Aead, Generate, KeyInit};
use aes_gcm::{Aes256Gcm, Nonce};
use hkdf::Hkdf;
use rand::TryRngCore;
use serde::{Deserialize, Serialize};
use sha2::Sha256;
use zeroize::{Zeroize, ZeroizeOnDrop};

/// `MainKey` is responsible for handling the cryptographically secure,
/// immutable master key. It uses HKDF to derive subordinate keys
/// (Authentication Token, Backup Key, Media Main Key).
#[derive(Clone, Debug, PartialEq, Zeroize, ZeroizeOnDrop, Serialize, Deserialize)]

pub struct MainKey {
    /// The 32-byte main master key
    main_key: [u8; 32],
}

#[derive(Debug)]

pub(crate) enum DatabaseKey {
    RustDb,
    AppDb,
}

impl MainKey {
    /// Generates a new cryptographically secure MainKey.
    pub fn generate() -> Self {
        let mut main_key = [0u8; 32];

        rand::rngs::OsRng
            .try_fill_bytes(&mut main_key)
            .expect("OS randomness unavailable");

        Self { main_key }
    }

    /// Download token required to download a backup.
    /// This ensures that the user who tries to download the backup must have
    /// knowledge over the main key
    pub fn get_backup_download_token(&self) -> [u8; 32] {
        self.derive_key(b"backup_download_token")
    }

    /// Uses as a password to authenitcate agains the server
    pub fn get_login_token(&self) -> [u8; 32] {
        self.derive_key(b"server_auth_token")
    }

    /// Derives the database encryption key.
    pub(crate) fn get_database_key(&self, db: DatabaseKey) -> String {
        let db_name: &[u8] = match db {
            DatabaseKey::RustDb => b"rust_db",
            DatabaseKey::AppDb => b"app_db",
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

    pub fn encrypt_cloud_media_key(&self, media_key: &[u8; 32], addition: &str) -> Vec<u8> {
        let info = format!("cloud_media_key_{}", addition);

        self.encrypt_with_info(info.as_bytes(), media_key)
    }

    pub fn decrypt_cloud_media_key(
        &self, encrypted_media_key: &[u8], addition: &str,
    ) -> Result<[u8; 32]> {
        let info = format!("cloud_media_key_{}", addition);

        let decrypted = self.decrypt_with_info(info.as_bytes(), encrypted_media_key)?;

        if decrypted.len() != 32 {
            Err("Invalid decrypted key length".to_string())?;
        }

        let mut result = [0u8; 32];

        result.copy_from_slice(&decrypted);

        Ok(result)
    }

    fn derive_key(&self, info: &[u8]) -> [u8; 32] {
        let hk = Hkdf::<Sha256>::new(None, &self.main_key);

        let mut okm = [0u8; 32];

        hk.expand(info, &mut okm).expect("HKDF expand failed");

        okm
    }

    fn encrypt_with_info(&self, info: &[u8], payload: &[u8]) -> Vec<u8> {
        let derived_key = self.derive_key(info);

        let cipher = Aes256Gcm::new(&derived_key.into());

        let nonce = Nonce::generate();

        let ciphertext = cipher
            .encrypt(&nonce, payload)
            .expect("encryption failure!");

        let mut result = nonce.to_vec();

        result.extend_from_slice(&ciphertext);

        result
    }

    fn decrypt_with_info(&self, info: &[u8], encrypted_data: &[u8]) -> Result<Vec<u8>> {
        if encrypted_data.len() < 12 {
            Err("Invalid encrypted data length".to_string())?;
        }

        let derived_key = self.derive_key(info);

        let cipher = Aes256Gcm::new(&derived_key.into());

        let nonce = Nonce::try_from(&encrypted_data[..12]).expect("nonce length was checked");

        let ciphertext = &encrypted_data[12..];

        Ok(cipher
            .decrypt(&nonce, ciphertext)
            .map_err(|_| "Decryption failure".to_string())?)
    }
}

#[cfg(test)]
mod tests {

    use super::*;

    // These values were recorded before upgrading hkdf/sha2 and aes-gcm.
    // Existing database keys and encrypted backups must survive the upgrade.
    #[test]
    fn legacy_keys_and_backup_remain_compatible() {
        let key = MainKey { main_key: [42; 32] };

        assert_eq!(
            hex::encode(key.get_login_token()),
            "00af5a5969df9abd87ca3784c1ad6c23fa1756c4782da78ca89ce936fd985d58"
        );
        assert_eq!(
            key.get_database_key(DatabaseKey::AppDb),
            "ddc7b95d030dbe2d30e2fc539107165d53ef3be3c8d971ff6d295e942b48adb7"
        );
        assert_eq!(
            key.get_database_key(DatabaseKey::RustDb),
            "6233c4153db21d36c8c7ef59eb79c14a9735d727d49b86e986bba0afbda703c6"
        );

        let encrypted = hex::decode(concat!(
            "090909090909090909090909",
            "44a37d0ea17e12f1f349ad678ba5ba7a083b5cc4fbded2fecdb75c249f5efb280c6c9b22b1"
        ))
        .unwrap();

        assert_eq!(
            key.decrypt_backup(&encrypted).unwrap(),
            b"legacy backup payload"
        );
    }

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
