use keyring_core::{Entry, Error as KeyringError};

/// A simple wrapper around `keyring-core` for secure storage on iOS, Android, and other platforms.
///
/// IMPORTANT: This struct assumes that a `keyring-core` default store has been initialized
/// (e.g., via `keyring_core::set_default_store`). In the White Noise project, this is handled
/// during application startup in `Whitenoise::initialize_keyring_store`.
pub struct SecureStorage {
    service_name: String,
}

impl SecureStorage {
    /// Creates a new `SecureStorage` instance with the specified service name.
    /// The service name is used as a namespace in the system keyring.
    pub fn new(service_name: &str) -> Self {
        Self {
            service_name: service_name.to_string(),
        }
    }

    /// Initializes the platform-native secure storage backend for iOS and Android.
    ///
    /// # Arguments
    /// * `group_id` - (iOS only) Optional App Group ID to allow cross-process keychain access.
    ///
    /// This function registers the appropriate credential store (Protected Store for iOS,
    /// Keystore for Android) with `keyring-core`. It is safe to call multiple times.
    pub fn init() -> Result<(), String> {
        if keyring_core::get_default_store().is_some() {
            return Ok(());
        }

        #[cfg(target_os = "ios")]
        {
            use std::collections::HashMap;
            let group = "CN332ZUGRP.eu.twonly.shared";
            let mut config = HashMap::new();
            config.insert("access-group", group);
            let store =
                apple_native_keyring_store::protected::Store::new_with_configuration(&config)
                    .map_err(|e| format!("Failed to init iOS Protected Store: {}", e))?;
            keyring_core::set_default_store(store);
        }

        #[cfg(target_os = "android")]
        {
            let store = android_native_keyring_store::Store::new()
                .map_err(|e| format!("Failed to init Android Store: {}", e))?;
            keyring_core::set_default_store(store);
        }

        #[cfg(not(any(target_os = "ios", target_os = "android")))]
        {
            let store = keyring_core::mock::Store::new()
                .map_err(|e| format!("Failed to init Mock Store: {}", e))?;
            keyring_core::set_default_store(store);
            tracing::warn!("Using mock store as default keyring store!");
        }

        Ok(())
    }

    /// Writes a secret value to the secure keyring associated with the given key.
    ///
    /// # Arguments
    /// * `key` - The identifier (account name) for the secret.
    /// * `value` - The secret string to store.
    pub fn write(&self, key: &str, value: &str) -> Result<(), String> {
        let entry = self.get_entry(key)?;

        entry
            .set_password(value)
            .map_err(|e| format!("Failed to write secret to keyring: {}", e))?;

        Ok(())
    }

    /// Reads a secret value from the secure keyring associated with the given key.
    ///
    /// Returns `Ok(Some(String))` if the key exists, `Ok(None)` if it doesn't,
    /// or an `Err` if a system error occurs.
    pub fn read(&self, key: &str) -> Result<Option<String>, String> {
        let entry = self.get_entry(key)?;

        match entry.get_password() {
            Ok(password) => Ok(Some(password)),
            Err(KeyringError::NoEntry) => Ok(None),
            Err(e) => Err(format!("Failed to read secret from keyring: {}", e)),
        }
    }

    /// Deletes the secret associated with the given key from the secure keyring.
    ///
    /// If the key does not exist, this function returns `Ok(())` (idempotent).
    pub fn delete(&self, key: &str) -> Result<(), String> {
        let entry = self.get_entry(key)?;

        match entry.delete_credential() {
            Ok(()) => Ok(()),
            Err(KeyringError::NoEntry) => Ok(()),
            Err(e) => Err(format!("Failed to delete secret from keyring: {}", e)),
        }
    }

    /// Helper to create a keyring entry with the appropriate platform modifiers.
    fn get_entry(&self, key: &str) -> Result<Entry, String> {
        #[cfg(target_os = "ios")]
        {
            use std::collections::HashMap;
            let mut modifiers = HashMap::new();
            modifiers.insert("access-policy", "AfterFirstUnlock");
            Entry::new_with_modifiers(&self.service_name, key, &modifiers)
                .map_err(|e| format!("Failed to create keyring entry with modifiers: {}", e))
        }

        #[cfg(not(target_os = "ios"))]
        {
            Entry::new(&self.service_name, key)
                .map_err(|e| format!("Failed to create keyring entry: {}", e))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_secure_storage_flow() {
        // Initialize the store (will use MockStore on non-mobile platforms)
        SecureStorage::init().unwrap();

        let storage = SecureStorage::new("eu.twonly.test");
        let key = "test_secret_key";
        let secret = "my_awesome_secret_123";

        // 1. Write the secret
        storage.write(key, secret).expect("Failed to write secret");

        // 2. Read the secret and verify it matches
        let read_val = storage.read(key).expect("Failed to read secret");
        assert_eq!(read_val, Some(secret.to_string()));

        // 3. Delete the secret
        storage.delete(key).expect("Failed to delete secret");

        // 4. Verify the secret is gone
        let after_delete = storage.read(key).expect("Failed to read after delete");
        assert_eq!(after_delete, None);
    }
}
