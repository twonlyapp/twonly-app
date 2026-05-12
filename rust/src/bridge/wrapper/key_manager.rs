use std::collections::HashMap;

use crate::bridge::get_twonly_flutter;
use crate::error::{Result, TwonlyError};
use crate::keys::SignalIdentityKey;

pub struct RustKeyManager {}

impl RustKeyManager {
    pub async fn get_login_token() -> Result<Vec<u8>> {
        let key_manager = get_twonly_flutter()?.key_manager.lock().await;
        Ok(key_manager.main_key.get_login_token().to_vec())
    }

    pub async fn get_user_id() -> Result<Option<i64>> {
        let key_manager = get_twonly_flutter()?.key_manager.lock().await;
        Ok(key_manager.user_id)
    }

    pub async fn set_user_id(user_id: i64) -> Result<()> {
        let ctx = get_twonly_flutter()?;
        let mut key_manager = ctx.key_manager.lock().await;
        key_manager.user_id = Some(user_id);
        key_manager.store_to_keychain(&ctx.secure_storage)?;
        Ok(())
    }

    pub async fn import_signal_identity(
        identity_key_pair_structure: Vec<u8>,
        registration_id: i64,
        signed_pre_key_store: HashMap<i64, Vec<u8>>,
    ) -> Result<()> {
        let ctx = get_twonly_flutter()?;
        let mut key_manager = ctx.key_manager.lock().await;
        key_manager.signal_identity = Some(SignalIdentityKey {
            identity_key_pair_structure,
            registration_id,
            pre_key_store: signed_pre_key_store,
        });
        key_manager.store_to_keychain(&ctx.secure_storage)?;
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

    pub async fn load_signed_prekey(signed_pre_key_id: i64) -> Result<Option<Vec<u8>>> {
        let ctx = get_twonly_flutter()?;
        let key_manager = ctx.key_manager.lock().await;
        if let Some(signal_identity) = &key_manager.signal_identity {
            Ok(signal_identity
                .pre_key_store
                .get(&signed_pre_key_id)
                .cloned())
        } else {
            Err(TwonlyError::SignalIdentityNotFound)
        }
    }

    pub async fn store_signed_prekey(signed_pre_key_id: i64, record: Vec<u8>) -> Result<()> {
        let ctx = get_twonly_flutter()?;
        let mut key_manager = ctx.key_manager.lock().await;
        if let Some(signal_identity) = &mut key_manager.signal_identity {
            signal_identity
                .pre_key_store
                .insert(signed_pre_key_id, record);
            key_manager.store_to_keychain(&ctx.secure_storage)?;
            Ok(())
        } else {
            Err(TwonlyError::SignalIdentityNotFound)
        }
    }

    pub async fn remove_signed_prekey(signed_pre_key_id: i64) -> Result<()> {
        let ctx = get_twonly_flutter()?;
        let mut key_manager = ctx.key_manager.lock().await;
        if let Some(signal_identity) = &mut key_manager.signal_identity {
            signal_identity.pre_key_store.remove(&signed_pre_key_id);
            key_manager.store_to_keychain(&ctx.secure_storage)?;
            Ok(())
        } else {
            Err(TwonlyError::SignalIdentityNotFound)
        }
    }

    pub async fn load_signed_prekeys() -> Result<HashMap<i64, Vec<u8>>> {
        let ctx = get_twonly_flutter()?;
        let key_manager = ctx.key_manager.lock().await;
        if let Some(signal_identity) = &key_manager.signal_identity {
            Ok(signal_identity.pre_key_store.to_owned())
        } else {
            Err(TwonlyError::SignalIdentityNotFound)
        }
    }

    pub async fn remove_key_manager() -> Result<()> {
        let ctx = get_twonly_flutter()?;
        crate::keys::KeyManager::remove_from_keychain(&ctx.secure_storage)?;
        Ok(())
    }
}
