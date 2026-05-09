use crate::context::Context;
use crate::database::Database;
use crate::error::{Result, TwonlyError};
use crate::keys::{DatabaseKey, MainKey};
use std::fs::{remove_file, File};
use std::io::{copy, Cursor};
use std::path::PathBuf;
use walkdir::WalkDir;
use zeroize::Zeroize;
use zip::write::SimpleFileOptions;
use zip::{CompressionMethod, ZipArchive, ZipWriter};

struct BackupArchive {}

impl BackupArchive {
    fn get_backup_files(ctx: &Context) -> Result<Vec<(&str, PathBuf, bool, Option<String>)>> {
        let config = ctx.get_config()?;
        let database_dir = PathBuf::from(&config.database_dir);
        let data_dir = PathBuf::from(&config.data_dir);
        let keys = ctx.get_key_manager()?;
        let rust_db_key = keys.main_key.get_database_key(DatabaseKey::RustDb);

        Ok(vec![
            ("twonly.sqlite", database_dir.clone(), true, None),
            ("rust_db.sqlite", database_dir, true, Some(rust_db_key)),
            ("user_discovery_config.json", data_dir.clone(), false, None),
            ("user.json", data_dir.join("keyvalue"), false, None),
        ])
    }

    pub(crate) async fn create_backup(ctx: &Context) -> Result<PathBuf> {
        let config = ctx.get_config()?;
        let data_dir = PathBuf::from(&config.data_dir);

        let backup_data_dir = data_dir.join("temp_backup_dir");
        if backup_data_dir.is_dir() {
            std::fs::remove_dir_all(&backup_data_dir)?;
        }
        std::fs::create_dir_all(&backup_data_dir)?;

        for (file_name, source_dir, is_db, mut encryption_key) in Self::get_backup_files(ctx)? {
            let file_path = source_dir.join(file_name);
            if !file_path.exists() {
                tracing::warn!(
                    "Could not backup {} as it does not exist.",
                    file_path.display()
                );
                continue;
            }

            if is_db {
                let db = Database::new(
                    &file_path.display().to_string(),
                    encryption_key.as_deref(),
                    encryption_key.is_none(),
                )
                .await?;
                let backup_database_file = backup_data_dir.join(file_name).display().to_string();
                db.create_backup(backup_database_file.as_str(), encryption_key.as_deref())
                    .await?;
            } else {
                let file_backup = backup_data_dir.join(file_name);
                std::fs::copy(file_path, file_backup)?;
            }
            encryption_key.zeroize();
        }

        let mut keys = ctx.get_key_manager()?;

        let keys_serialized = postcard::to_allocvec(&keys)?;

        let mut zip_data = Vec::new();

        {
            let mut zip = ZipWriter::new(Cursor::new(&mut zip_data));
            let options =
                SimpleFileOptions::default().compression_method(CompressionMethod::Deflated);

            zip.start_file(".key_manager.bin", options)?;
            copy(&mut keys_serialized.as_slice(), &mut zip)?;

            for entry in WalkDir::new(&backup_data_dir) {
                let entry = entry?;
                let path = entry.path();

                if !path.is_file() {
                    continue;
                }

                if let Ok(name) = path.strip_prefix(&backup_data_dir) {
                    zip.start_file(name.to_string_lossy(), options)?;
                    copy(&mut File::open(path)?, &mut zip)?;
                }
            }
            zip.finish()?;
        }

        let zip_path = data_dir.join("temp_backup.zip");
        std::fs::write(&zip_path, keys.main_key.encrypt_backup(&zip_data))?;

        std::fs::remove_dir_all(&backup_data_dir)?;
        keys.zeroize();

        Ok(zip_path)
    }

    pub(crate) async fn restore_from_backup(
        ctx: &Context,
        main_key_bytes: &[u8],
        file_path: &PathBuf,
    ) -> Result<()> {
        let data_dir = PathBuf::from(&ctx.get_config()?.data_dir);

        let main_key_arr: [u8; 32] = main_key_bytes
            .try_into()
            .map_err(|_| TwonlyError::Generic("Invalid main key length".to_string()))?;

        let mut main_key = MainKey::from_main_key(main_key_arr);

        let encrypted_zip = std::fs::read(file_path)?;
        let zip_content = main_key.decrypt_backup(&encrypted_zip)?;

        let restore_temp_dir = data_dir.join("restore_temp");

        if restore_temp_dir.exists() {
            std::fs::remove_dir_all(&restore_temp_dir)?;
        }

        std::fs::create_dir_all(&restore_temp_dir)?;

        let mut archive = ZipArchive::new(Cursor::new(zip_content))?;

        for i in 0..archive.len() {
            let mut file = archive.by_index(i)?;

            if file.is_file() {
                let name = file.name().to_string();
                if name == ".key_manager.bin" {
                    let mut data = Vec::new();
                    copy(&mut file, &mut data)?;
                    let key_manager: crate::keys::KeyManager = postcard::from_bytes(&data)?;
                    key_manager.store_to_keychain(ctx.get_secure_storage()?)?;
                    continue;
                }

                let enclosed_name = file.enclosed_name();
                if let Some(name) = enclosed_name.as_ref().and_then(|p| p.file_name()) {
                    let restored_file = restore_temp_dir.join(name);
                    copy(&mut file, &mut File::create(&restored_file)?)?;
                };
            }
        }

        for (file_name, target_dir, is_db, _) in Self::get_backup_files(ctx)? {
            let src = restore_temp_dir.join(file_name);
            if src.exists() {
                let dst = target_dir.join(file_name);
                if is_db {
                    // Remove existing database and its temporary files (WAL, SHM)
                    let _ = remove_file(&dst);
                    let _ = remove_file(target_dir.join(format!("{}-wal", file_name)));
                    let _ = remove_file(target_dir.join(format!("{}-shm", file_name)));
                }

                std::fs::copy(src, dst)?;
            }
        }

        main_key.zeroize();
        std::fs::remove_dir_all(&restore_temp_dir)?;

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use crate::{database::tables::received_messages::ReceivedMessage, keys::KeyManager};

    use super::*;
    use tempfile::tempdir;

    #[tokio::test]
    async fn test_backup_and_restore() {
        let _ = pretty_env_logger::try_init();

        let temp_dir = tempdir().unwrap();

        let ctx = Context::init_for_testing(
            temp_dir.path().join("database"),
            temp_dir.path().join("data"),
        )
        .await
        .unwrap();

        // 1. Add some data
        {
            let config = ctx.get_config().unwrap();
            let rust_db_path = PathBuf::from(&config.database_dir).join("rust_db.sqlite");
            let mut key_manager = ctx.get_key_manager().unwrap();
            key_manager
                .identity_keys
                .push(crate::keys::IdentityKey::Nost());
            key_manager
                .store_to_keychain(ctx.get_secure_storage().unwrap())
                .unwrap();

            let db = Database::new(
                &rust_db_path.display().to_string(),
                Some(&key_manager.main_key.get_database_key(DatabaseKey::RustDb)),
                false,
            )
            .await
            .unwrap();

            ReceivedMessage::insert(&db.pool, 1, b"original message")
                .await
                .unwrap();

            // Add a file
            let config_file = PathBuf::from(&config.data_dir).join("user_discovery_config.json");
            std::fs::write(config_file, "original config").unwrap();
        }

        // 2. Create backup
        let backup_path = BackupArchive::create_backup(&ctx).await.unwrap();
        assert!(backup_path.exists());

        // Save the original main key bytes
        let original_main_key = *ctx.get_key_manager().unwrap().main_key.as_bytes();

        // 3. Modify data (to simulate state before restore)
        {
            let config = ctx.get_config().unwrap();
            let rust_db_path = PathBuf::from(&config.database_dir).join("rust_db.sqlite");
            let key_manager = ctx.get_key_manager().unwrap();
            let db = Database::new(
                &rust_db_path.display().to_string(),
                Some(&key_manager.main_key.get_database_key(DatabaseKey::RustDb)),
                false,
            )
            .await
            .unwrap();

            ReceivedMessage::insert(&db.pool, 2, b"new message")
                .await
                .unwrap();

            let config_file = PathBuf::from(&config.data_dir).join("user_discovery_config.json");
            std::fs::write(config_file, "new config").unwrap();

            // Delete old keys to ensure they will be actually restored

            let key_manager = KeyManager::generate().unwrap();
            key_manager
                .store_to_keychain(&ctx.get_secure_storage().unwrap())
                .unwrap();
        }

        // 4. Restore backup
        BackupArchive::restore_from_backup(&ctx, &original_main_key, &backup_path)
            .await
            .unwrap();

        // 5. Verify restored data
        {
            let config = ctx.get_config().unwrap();
            let rust_db_path = PathBuf::from(&config.database_dir).join("rust_db.sqlite");
            let key_manager = ctx.get_key_manager().unwrap();
            let db = Database::new(
                &rust_db_path.display().to_string(),
                Some(&key_manager.main_key.get_database_key(DatabaseKey::RustDb)),
                false,
            )
            .await
            .unwrap();

            let messages = ReceivedMessage::get_all(&db.pool).await.unwrap();
            // Should only have the original message because restore overwrites
            assert_eq!(messages.len(), 1);
            assert_eq!(messages[0].sender_id, 1);
            assert_eq!(messages[0].content, b"original message");

            let config_file = PathBuf::from(&config.data_dir).join("user_discovery_config.json");
            let config_content = std::fs::read_to_string(config_file).unwrap();
            assert_eq!(config_content, "original config");

            let key_manager = ctx.get_key_manager().unwrap();
            assert_eq!(key_manager.identity_keys.len(), 1);
            match &key_manager.identity_keys[0] {
                crate::keys::IdentityKey::Nost() => {}
                _ => panic!("Wrong identity key!"),
            }
        }
    }
}
