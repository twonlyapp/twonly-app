/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use std::path::PathBuf;

use crate::backup::backup_archive::BackupArchive;
pub use crate::backup::backup_archive::{BackupFileSize, BackupStorageInfo, BackupTableSize};
use crate::backup::backup_identity::BackupIdentity;
use crate::bridge::get_twonly_flutter;
use crate::context::Context;
use crate::error::{Result, TwonlyError};
pub use crate::keys::backup_password_keys::BackupPasswordKeys;

pub struct RustBackupIdentity();

pub struct RustBackupArchive();

impl RustBackupIdentity {
    pub async fn get_backup_password_keys(
        user_id: i64, password: String,
    ) -> Result<BackupPasswordKeys> {
        BackupPasswordKeys::from_password(&password, user_id)
    }

    pub async fn get_backup_id() -> Option<String> {
        let key_manager = get_twonly_flutter().ok()?.key_manager.lock().await;

        Some(hex::encode(key_manager.backup_password.clone()?.backup_id))
    }

    pub async fn set_backup_password_keys(user_id: i64, password: String) -> Result<()> {
        let backup_keys = BackupPasswordKeys::from_password(&password, user_id)?;

        let ctx = get_twonly_flutter()?;

        let mut key_manager = ctx.key_manager.lock().await;

        key_manager.backup_password = Some(backup_keys);

        key_manager.store_to_keychain(&ctx.secure_storage)?;

        Ok(())
    }

    pub async fn import_backup_password_keys(
        backup_id: Vec<u8>, encryption_key: Vec<u8>,
    ) -> Result<()> {
        let backup_id: [u8; 32] = backup_id
            .try_into()
            .map_err(|a: Vec<u8>| TwonlyError::WronKeySize(2, a.len()))?;

        let encryption_key: [u8; 32] = encryption_key
            .try_into()
            .map_err(|a: Vec<u8>| TwonlyError::WronKeySize(2, a.len()))?;

        let backup_keys = BackupPasswordKeys::new(backup_id, encryption_key);

        let ctx = get_twonly_flutter()?;

        let mut key_manager = ctx.key_manager.lock().await;

        key_manager.backup_password = Some(backup_keys);

        key_manager.store_to_keychain(&ctx.secure_storage)?;

        Ok(())
    }

    pub async fn get_identity_backup_bytes() -> Result<Vec<u8>> {
        let key_manager = get_twonly_flutter()?.key_manager.lock().await;

        BackupIdentity::encrypt_key_manager(&key_manager)
    }

    pub async fn restore_identity_backup(
        keys: BackupPasswordKeys, encrypted_bytes: Vec<u8>,
    ) -> Result<()> {
        let ctx = get_twonly_flutter()?;

        let _lifecycle = ctx.database_lifecycle.lock().await;

        let restored = BackupIdentity::decrypt_key_manager(&keys, &encrypted_bytes)?;

        crate::keys::restore::stage(&ctx.secure_storage, restored)
    }
}

impl RustBackupArchive {
    pub async fn storage_info() -> Result<BackupStorageInfo> {
        BackupArchive::storage_info(Context::get_static()?).await
    }

    pub async fn create_backup_archive() -> Result<(String, String)> {
        let ctx = Context::get_static()?;

        let (token, path) = BackupArchive::create_backup_with_token(ctx).await?;

        Ok((token, path.canonicalize()?.to_string_lossy().to_string()))
    }

    pub async fn restore_backup_archive(file_path: String) -> Result<()> {
        let ctx = Context::get_static()?;

        BackupArchive::restore_from_backup(ctx, &PathBuf::from(file_path)).await
    }

    pub async fn get_backup_download_token() -> Option<String> {
        let ctx = get_twonly_flutter().ok()?;

        if let Some(identity) = crate::keys::restore::pending(&ctx.secure_storage).ok()? {
            return Some(hex::encode(
                identity.key_manager.main_key.get_backup_download_token(),
            ));
        }

        let key_manager = ctx.key_manager.lock().await;

        Some(hex::encode(
            key_manager.main_key.get_backup_download_token(),
        ))
    }
}
