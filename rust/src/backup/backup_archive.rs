/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::context::Context;
use crate::database::app::APP_DATABASE_FILE;
use crate::database::signal::Database;
use crate::error::Result;
use crate::keys::{DatabaseKey, KeyManager};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::BTreeMap;
use std::fs::{remove_file, File};
use std::io::{copy, Cursor};
use std::path::{Path, PathBuf};
use walkdir::WalkDir;
use zeroize::Zeroize;
use zip::write::SimpleFileOptions;
use zip::{CompressionMethod, ZipArchive, ZipWriter};

pub(crate) struct BackupArchive {}

const BACKUP_MANIFEST_FILE: &str = "backup-manifest.json";
const BACKUP_FORMAT_VERSION: u32 = 2;

#[derive(Debug, Serialize, Deserialize)]
struct BackupManifest {
    format_version: u32,
    drift_schema_version: u32,
    app_schema_version: i64,
    files: BTreeMap<String, BackupManifestFile>,
}

#[derive(Debug, Serialize, Deserialize)]
struct BackupManifestFile {
    size: u64,
    sha256: String,
}

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
        let app_db_key = keys.main_key.get_database_key(DatabaseKey::AppDb);

        Ok(vec![
            ("twonly.sqlite", database_dir.clone(), true, None),
            (
                "rust_db.sqlite",
                database_dir.clone(),
                true,
                Some(rust_db_key),
            ),
            (APP_DATABASE_FILE, database_dir, true, Some(app_db_key)),
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
                if file_name == APP_DATABASE_FILE {
                    let backup_database_file = backup_data_dir.join(file_name);
                    let app_database = ctx.get_app_database().await;
                    app_database
                        .create_backup(
                            &backup_database_file.display().to_string(),
                            encryption_key.as_deref().ok_or_else(|| {
                                crate::error::TwonlyError::Generic(
                                    "Missing app database backup key".to_owned(),
                                )
                            })?,
                        )
                        .await?;
                    let backup_db = Database::new(
                        &backup_database_file.display().to_string(),
                        encryption_key.as_deref(),
                        true,
                    )
                    .await?;
                    backup_db.check_integrity().await?;
                    backup_db.pool.close().await;
                    encryption_key.zeroize();
                    continue;
                }
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

        Self::write_manifest(&backup_data_dir)?;

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

        Self::validate_manifest(&restore_temp_dir)?;

        let restored_app_database = restore_temp_dir.join(APP_DATABASE_FILE);
        let has_app_database = restored_app_database.exists();
        let app_database_key = key_manager.main_key.get_database_key(DatabaseKey::AppDb);
        if !has_app_database {
            // A format-v1 archive has no app_db.sqlite. Build and verify it in
            // staging before touching any active database file.
            let staged_app_database = crate::database::app::AppDatabase::new(
                &restored_app_database.display().to_string(),
                Some(&app_database_key),
                false,
            )
            .await?;
            staged_app_database.run_migrations().await?;
            staged_app_database
                .import_legacy(&restore_temp_dir.join("twonly.sqlite"))
                .await?;
            staged_app_database.pool.close().await;
        }
        let staged_app_database = crate::database::app::AppDatabase::new(
            &restored_app_database.display().to_string(),
            Some(&app_database_key),
            true,
        )
        .await?;
        let integrity = sqlx::query_scalar!(r#"PRAGMA integrity_check"#)
            .fetch_one(&staged_app_database.pool)
            .await?;
        let integrity = integrity.ok_or_else(|| {
            crate::error::TwonlyError::Generic(
                "Staged app database integrity check returned no result".to_owned(),
            )
        })?;
        staged_app_database.pool.close().await;
        if integrity.to_lowercase() != "ok" {
            return Err(crate::error::TwonlyError::Generic(format!(
                "Staged app database integrity check failed: {integrity}"
            )));
        }
        let rust_database_key = key_manager.main_key.get_database_key(DatabaseKey::RustDb);
        let staged_rust_database_path = restore_temp_dir.join("rust_db.sqlite");
        let staged_rust_database = Database::new(
            &staged_rust_database_path.display().to_string(),
            Some(&rust_database_key),
            true,
        )
        .await?;
        staged_rust_database.check_integrity().await?;
        staged_rust_database.pool.close().await;

        // app_db.sqlite is owned by a replaceable Rust handle. Close it before
        // replacing the file so subsequent DAO calls cannot continue using an
        // unlinked pre-restore database.
        let current_app_database = ctx.get_app_database().await;
        current_app_database.pool.close().await;
        let current_rust_database = ctx.get_rust_db().await;
        current_rust_database.pool.close().await;

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

        let database_dir = PathBuf::from(&ctx.get_config()?.database_dir);
        let app_database_path = database_dir.join(APP_DATABASE_FILE);
        let app_database = crate::database::app::AppDatabase::new(
            &app_database_path.display().to_string(),
            Some(&app_database_key),
            false,
        )
        .await?;
        app_database.run_migrations().await?;
        ctx.replace_app_database(app_database).await;

        let rust_database_path = database_dir.join("rust_db.sqlite");
        let rust_database = Database::new(
            &rust_database_path.display().to_string(),
            Some(&rust_database_key),
            false,
        )
        .await?;
        rust_database.run_migrations().await?;
        ctx.replace_rust_database(rust_database, &key_manager)
            .await?;

        std::fs::remove_dir_all(&restore_temp_dir)?;

        Ok(())
    }

    fn write_manifest(directory: &Path) -> Result<()> {
        let mut files = BTreeMap::new();
        for entry in WalkDir::new(directory).min_depth(1).max_depth(1) {
            let entry = entry?;
            if !entry.path().is_file() || entry.file_name() == BACKUP_MANIFEST_FILE {
                continue;
            }
            let bytes = std::fs::read(entry.path())?;
            files.insert(
                entry.file_name().to_string_lossy().to_string(),
                BackupManifestFile {
                    size: bytes.len() as u64,
                    sha256: hex::encode(Sha256::digest(&bytes)),
                },
            );
        }
        let manifest = BackupManifest {
            format_version: BACKUP_FORMAT_VERSION,
            drift_schema_version: 25,
            app_schema_version: crate::database::app::APP_SCHEMA_VERSION,
            files,
        };
        std::fs::write(
            directory.join(BACKUP_MANIFEST_FILE),
            serde_json::to_vec_pretty(&manifest)
                .map_err(|error| crate::error::TwonlyError::Generic(error.to_string()))?,
        )?;
        Ok(())
    }

    fn validate_manifest(directory: &Path) -> Result<()> {
        let path = directory.join(BACKUP_MANIFEST_FILE);
        if !path.exists() {
            // Format v1 archives predate the manifest and are migrated from
            // twonly.sqlite below.
            return Ok(());
        }
        let manifest: BackupManifest =
            serde_json::from_slice(&std::fs::read(path)?).map_err(|error| {
                crate::error::TwonlyError::Generic(format!("Invalid backup manifest: {error}"))
            })?;
        if manifest.format_version != BACKUP_FORMAT_VERSION {
            return Err(crate::error::TwonlyError::Generic(format!(
                "Unsupported backup format {}",
                manifest.format_version
            )));
        }
        for (name, expected) in manifest.files {
            let file = directory.join(&name);
            if !file.exists() {
                return Err(crate::error::TwonlyError::Generic(format!(
                    "Backup entry {name} is missing"
                )));
            }
            let bytes = std::fs::read(file)?;
            let actual_hash = hex::encode(Sha256::digest(&bytes));
            if bytes.len() as u64 != expected.size || actual_hash != expected.sha256 {
                return Err(crate::error::TwonlyError::Generic(format!(
                    "Backup entry {name} failed checksum validation"
                )));
            }
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use crate::secure_storage::SecureStorage;

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
            let key_manager = ctx.get_key_manager().await.unwrap();
            key_manager.store_to_keychain(&secure_storage).unwrap();

            // Add a file
            let config_file = PathBuf::from(&config.data_dir).join("user_discovery_config.json");
            std::fs::write(config_file, "original config").unwrap();
            key_manager.main_key.get_login_token()
        };
        {
            let app_db = ctx.get_app_database().await;
            sqlx::query!(
                r#"
                INSERT INTO contacts(user_id, username)
                VALUES(1, 'original contact')
                "#
            )
            .execute(&app_db.pool)
            .await
            .unwrap();
        }

        // 2. Create backup
        let backup_path = BackupArchive::create_backup(&ctx).await.unwrap();
        assert!(backup_path.exists());

        // 3. Modify data (to simulate state before restore)
        {
            let config = ctx.get_config().unwrap();

            let config_file = PathBuf::from(&config.data_dir).join("user_discovery_config.json");
            std::fs::write(config_file, "new config").unwrap();

            let app_db = ctx.get_app_database().await;
            sqlx::query!(
                r#"
                UPDATE contacts
                SET username = 'changed contact'
                WHERE user_id = 1
                "#
            )
            .execute(&app_db.pool)
            .await
            .unwrap();
        }

        // 4. Restore backup
        BackupArchive::restore_from_backup(&ctx, &backup_path)
            .await
            .unwrap();

        // 5. Verify restored data
        {
            let config = ctx.get_config().unwrap();
            let key_manager = ctx.get_key_manager().await.unwrap();

            let config_file = PathBuf::from(&config.data_dir).join("user_discovery_config.json");
            let config_content = std::fs::read_to_string(config_file).unwrap();
            assert_eq!(config_content, "original config");

            assert_eq!(key_manager.main_key.get_login_token(), original_login_token);

            let app_db = ctx.get_app_database().await;
            let username = sqlx::query_scalar!(
                r#"
                SELECT username
                FROM contacts
                WHERE user_id = 1
                "#
            )
            .fetch_one(&app_db.pool)
            .await
            .unwrap();
            assert_eq!(username, "original contact");
        }
    }

    #[tokio::test]
    async fn restores_pre_app_database_backup_by_importing_twonly_sqlite() {
        let _ = pretty_env_logger::try_init();
        let temp_dir = tempdir().unwrap();
        let ctx = Context::init_for_testing(
            temp_dir.path().join("database"),
            temp_dir.path().join("data"),
        )
        .await
        .unwrap();
        let database_dir = PathBuf::from(&ctx.get_config().unwrap().database_dir);
        let legacy_path = database_dir.join("twonly.sqlite");
        let legacy =
            crate::database::app::AppDatabase::new(&legacy_path.display().to_string(), None, false)
                .await
                .unwrap();
        legacy.run_migrations().await.unwrap();
        sqlx::query!(r#"PRAGMA user_version = 25"#)
            .execute(&legacy.pool)
            .await
            .unwrap();
        sqlx::query!(
            r#"
            INSERT INTO contacts(user_id, username)
            VALUES(99, 'from old backup')
            "#
        )
        .execute(&legacy.pool)
        .await
        .unwrap();
        legacy.pool.close().await;

        let archive_path = BackupArchive::create_backup(&ctx).await.unwrap();
        remove_file_from_encrypted_archive(&ctx, &archive_path, APP_DATABASE_FILE).await;

        let app_db = ctx.get_app_database().await;
        sqlx::query!(
            r#"
            INSERT INTO contacts(user_id, username)
            VALUES(1, 'current data')
            "#
        )
        .execute(&app_db.pool)
        .await
        .unwrap();

        BackupArchive::restore_from_backup(&ctx, &archive_path)
            .await
            .unwrap();

        let restored = ctx.get_app_database().await;
        let contacts = sqlx::query!(
            r#"
            SELECT user_id, username
            FROM contacts
            ORDER BY user_id
            "#
        )
        .fetch_all(&restored.pool)
        .await
        .unwrap()
        .into_iter()
        .map(|row| (row.user_id, row.username))
        .collect::<Vec<_>>();
        assert_eq!(contacts, vec![(99, "from old backup".to_owned())]);
    }

    async fn remove_file_from_encrypted_archive(
        ctx: &Context,
        archive_path: &Path,
        excluded_name: &str,
    ) {
        let keys = ctx.get_key_manager().await.unwrap();
        let encrypted = std::fs::read(archive_path).unwrap();
        let decrypted = keys.main_key.decrypt_backup(&encrypted).unwrap();
        let mut source = ZipArchive::new(Cursor::new(decrypted)).unwrap();
        let mut rebuilt = Vec::new();
        {
            let mut writer = ZipWriter::new(Cursor::new(&mut rebuilt));
            let options =
                SimpleFileOptions::default().compression_method(CompressionMethod::Deflated);
            for index in 0..source.len() {
                let mut entry = source.by_index(index).unwrap();
                if entry.name() == excluded_name
                    || entry.name() == BACKUP_MANIFEST_FILE
                    || !entry.is_file()
                {
                    continue;
                }
                writer.start_file(entry.name(), options).unwrap();
                copy(&mut entry, &mut writer).unwrap();
            }
            writer.finish().unwrap();
        }
        std::fs::write(archive_path, keys.main_key.encrypt_backup(&rebuilt)).unwrap();
    }
}
