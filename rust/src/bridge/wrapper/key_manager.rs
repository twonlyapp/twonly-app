/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::bridge::get_twonly_flutter;
use crate::error::{Result, TwonlyError};
use crate::keys::SignalIdentityKey;
use crate::signal::engine::RustSignalEngine;

pub struct RustKeyManager {}

impl RustKeyManager {
    pub async fn get_user_id() -> Result<Option<i64>> {
        let key_manager = get_twonly_flutter()?.key_manager.lock().await;
        Ok(key_manager.user_id)
    }

    pub async fn set_user_id(user_id: i64) -> Result<()> {
        let ctx = get_twonly_flutter()?;
        {
            let mut key_manager = ctx.key_manager.lock().await;
            key_manager.user_id = Some(user_id);
            key_manager.store_to_keychain(&ctx.secure_storage)?;
        }

        let mut guard = ctx.signal_engine.lock().await;
        match RustSignalEngine::new(user_id.to_string()).await {
            Ok(engine) => *guard = Some(engine),
            Err(e) => {
                tracing::warn!(
                    "Failed to initialize Signal engine on set_user_id: {}. It will be initialized later.",
                    e
                );
                *guard = None;
            }
        }

        Ok(())
    }

    pub async fn import_signal_identity(
        identity_key_pair_structure: Vec<u8>,
        registration_id: i64,
    ) -> Result<()> {
        let ctx = get_twonly_flutter()?;
        let user_id = {
            let mut key_manager = ctx.key_manager.lock().await;
            key_manager.signal_identity = Some(SignalIdentityKey {
                identity_key_pair_structure,
                registration_id,
            });
            key_manager.store_to_keychain(&ctx.secure_storage)?;
            key_manager.user_id
        };

        if let Some(user_id) = user_id {
            let mut guard = ctx.signal_engine.lock().await;
            match RustSignalEngine::new(user_id.to_string()).await {
                Ok(engine) => *guard = Some(engine),
                Err(e) => {
                    tracing::warn!(
                        "Failed to initialize Signal engine on import_signal_identity: {}.",
                        e
                    );
                    *guard = None;
                }
            }
        }

        Ok(())
    }

    pub async fn get_signal_identity() -> Result<(Vec<u8>, i64)> {
        let ctx = get_twonly_flutter()?;
        let key_manager = ctx.key_manager.lock().await;
        if let Some(signal_identity) = &key_manager.signal_identity {
            Ok((
                signal_identity.identity_key_pair_structure.to_owned(),
                signal_identity.registration_id,
            ))
        } else {
            Err(TwonlyError::SignalIdentityNotFound)
        }
    }

    pub async fn remove_key_manager() -> Result<()> {
        let ctx = get_twonly_flutter()?;
        crate::keys::KeyManager::remove_from_keychain(&ctx.secure_storage)?;
        Ok(())
    }

    /// Serialize the key_manager. Needed for the passwordless_recovery feature.
    pub async fn serialize() -> Result<Vec<u8>> {
        let ctx = get_twonly_flutter()?;
        let key_manager = ctx.key_manager.lock().await;
        key_manager.to_bytes()
    }

    pub async fn import_serialized(serialized_bytes: Vec<u8>) -> Result<()> {
        let ctx = get_twonly_flutter()?;
        let key_manager = crate::keys::KeyManager::from_bytes(&serialized_bytes)?;
        key_manager.store_to_keychain(&ctx.secure_storage)?;
        *ctx.key_manager.lock().await = key_manager;
        Ok(())
    }

    pub async fn encrypt_cloud_media_key(media_key: Vec<u8>, addition: String) -> Result<Vec<u8>> {
        let key_manager = get_twonly_flutter()?.key_manager.lock().await;
        if media_key.len() != 32 {
            return Err(TwonlyError::WronKeySize(32, media_key.len()));
        }
        let mut key_array = [0u8; 32];
        key_array.copy_from_slice(&media_key);
        Ok(key_manager
            .main_key
            .encrypt_cloud_media_key(&key_array, &addition))
    }

    pub async fn decrypt_cloud_media_key(
        encrypted_media_key: Vec<u8>,
        addition: String,
    ) -> Result<Vec<u8>> {
        let key_manager = get_twonly_flutter()?.key_manager.lock().await;
        let decrypted = key_manager
            .main_key
            .decrypt_cloud_media_key(&encrypted_media_key, &addition)?;
        Ok(decrypted.to_vec())
    }
}
