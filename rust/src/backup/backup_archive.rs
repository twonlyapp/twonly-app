use crate::context::Context;
use crate::database::Database;
use crate::error::Result;
use crate::keys::{DatabaseKey, KeyManager};
use std::fs::{remove_file, File};
use std::io::{copy, Cursor};
use std::path::{Path, PathBuf};
use walkdir::WalkDir;
use zeroize::Zeroize;
use zip::write::SimpleFileOptions;
use zip::{CompressionMethod, ZipArchive, ZipWriter};

pub(crate) struct BackupArchive {}

impl BackupArchive {
    #[allow(clippy::type_complexity)]
    fn get_backup_files(
        ctx: &Context,
        keys: &KeyManager,
    ) -> Result<Vec<(&'static str, PathBuf, bool, Option<String>)>> {
        let config = ctx.get_config()?;
        let database_dir = PathBuf::from(&config.database_dir);
        let data_dir = PathBuf::from(&config.data_dir);
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

        let keys = ctx.get_key_manager().await?;

        for (file_name, source_dir, is_db, mut encryption_key) in
            Self::get_backup_files(ctx, &keys)?
        {
            let file_path = source_dir.join(file_name);
            if !file_path.exists() {
                tracing::warn!(
                    "Could not backup {} as it does not exist.",
                    file_path.display()
                );
                continue;
            }

            if is_db {
                // To avoid write-lock conflicts with Dart (which has the live database open in write mode),
                // we copy the database file first, then open the copy to perform the backup.
                let temp_copy_path = backup_data_dir.join(format!("{}.temp_copy", file_name));
                std::fs::copy(&file_path, &temp_copy_path)?;

                let db = Database::new(
                    &temp_copy_path.display().to_string(),
                    encryption_key.as_deref(),
                    false, // Open the copy in write mode required for encrypted backups
                )
                .await?;
                let backup_database_file = backup_data_dir.join(file_name).display().to_string();
                db.create_backup(backup_database_file.as_str(), encryption_key.as_deref())
                    .await?;

                // Close database connection to release file lock before removing it
                db.pool.close().await;
                remove_file(&temp_copy_path)?;

                // Perform integrity check of the new database file
                let backup_db =
                    Database::new(&backup_database_file, encryption_key.as_deref(), true).await?;
                backup_db.check_integrity().await?;
                backup_db.pool.close().await;
            } else {
                let file_backup = backup_data_dir.join(file_name);
                std::fs::copy(file_path, file_backup)?;
            }
            encryption_key.zeroize();
        }

        let mut zip_data = Vec::new();

        {
            let mut zip = ZipWriter::new(Cursor::new(&mut zip_data));
            let options =
                SimpleFileOptions::default().compression_method(CompressionMethod::Deflated);

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

        Ok(zip_path)
    }

    pub(crate) async fn restore_from_backup(ctx: &Context, file_path: &Path) -> Result<()> {
        let data_dir = PathBuf::from(&ctx.get_config()?.data_dir);
        let key_manager = ctx.get_key_manager().await?;

        let encrypted_zip = std::fs::read(file_path)?;
        let zip_content = key_manager.main_key.decrypt_backup(&encrypted_zip)?;

        let restore_temp_dir = data_dir.join("restore_temp");

        if restore_temp_dir.exists() {
            std::fs::remove_dir_all(&restore_temp_dir)?;
        }

        std::fs::create_dir_all(&restore_temp_dir)?;

        let mut archive = ZipArchive::new(Cursor::new(zip_content))?;

        for i in 0..archive.len() {
            let mut file = archive.by_index(i)?;

            if file.is_file() {
                let enclosed_name = file.enclosed_name();
                if let Some(name) = enclosed_name.as_ref().and_then(|p| p.file_name()) {
                    let restored_file = restore_temp_dir.join(name);
                    copy(&mut file, &mut File::create(&restored_file)?)?;
                };
            }
        }

        for (file_name, target_dir, is_db, _) in Self::get_backup_files(ctx, &key_manager)? {
            let src = restore_temp_dir.join(file_name);
            if src.exists() {
                std::fs::create_dir_all(&target_dir)?;
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

        std::fs::remove_dir_all(&restore_temp_dir)?;

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use crate::{
        database::tables::received_messages::ReceivedMessage, secure_storage::SecureStorage,
    };

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
        let original_login_token = {
            let secure_storage = SecureStorage::new("testing");
            let config = ctx.get_config().unwrap();
            let rust_db_path = PathBuf::from(&config.database_dir).join("rust_db.sqlite");
            let key_manager = ctx.get_key_manager().await.unwrap();
            key_manager.store_to_keychain(&secure_storage).unwrap();

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
            key_manager.main_key.get_login_token()
        };

        // 2. Create backup
        let backup_path = BackupArchive::create_backup(&ctx).await.unwrap();
        assert!(backup_path.exists());

        // 3. Modify data (to simulate state before restore)
        {
            let config = ctx.get_config().unwrap();
            let rust_db_path = PathBuf::from(&config.database_dir).join("rust_db.sqlite");
            let key_manager = ctx.get_key_manager().await.unwrap();
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
        }

        // 4. Restore backup
        BackupArchive::restore_from_backup(&ctx, &backup_path)
            .await
            .unwrap();

        // 5. Verify restored data
        {
            let config = ctx.get_config().unwrap();
            let rust_db_path = PathBuf::from(&config.database_dir).join("rust_db.sqlite");
            let key_manager = ctx.get_key_manager().await.unwrap();
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

            assert_eq!(key_manager.main_key.get_login_token(), original_login_token);
        }
    }
}
