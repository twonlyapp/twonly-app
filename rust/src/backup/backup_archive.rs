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
use sqlx::{AssertSqlSafe, Row};
use std::collections::BTreeMap;
use std::fs::{remove_file, File};
use std::io::{copy, Cursor};
use std::path::{Path, PathBuf};
use std::sync::Arc;
use walkdir::WalkDir;
use zeroize::Zeroize;
use zip::write::SimpleFileOptions;
use zip::{CompressionMethod, ZipArchive, ZipWriter};

/// How long a database pool gets to hand its connections back before the
/// restore stops waiting for it.
const POOL_CLOSE_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(10);

async fn close_pool_or_log(pool: &sqlx::SqlitePool, name: &str) {
    if tokio::time::timeout(POOL_CLOSE_TIMEOUT, pool.close())
        .await
        .is_err()
    {
        tracing::warn!("{name} pool did not close within the timeout, replacing it anyway");
    }
}

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

pub struct BackupStorageInfo {
    pub database_size_bytes: i64,
    pub free_size_bytes: i64,
    pub tables: Vec<BackupTableSize>,
    pub files: Vec<BackupFileSize>,
}

pub struct BackupTableSize {
    pub name: String,
    pub rows: i64,
    pub table_size_bytes: i64,
    pub index_size_bytes: i64,
}

pub struct BackupFileSize {
    pub name: String,
    /// None means the source file is absent and will be skipped by the backup.
    pub size_bytes: Option<i64>,
}

impl BackupArchive {
    /// Read current storage usage without creating or uploading a backup.
    pub(crate) async fn storage_info(ctx: &Context) -> Result<BackupStorageInfo> {
        let files = {
            let keys = ctx.key_manager.lock().await;
            Self::get_backup_files(ctx, &keys)?
                .into_iter()
                .map(|(name, directory, _, mut key)| {
                    key.zeroize();
                    let size_bytes = match directory.join(name).metadata() {
                        Ok(metadata) => Some(metadata.len() as i64),
                        Err(error) if error.kind() == std::io::ErrorKind::NotFound => None,
                        Err(error) => return Err(error.into()),
                    };
                    Ok(BackupFileSize {
                        name: name.to_owned(),
                        size_bytes,
                    })
                })
                .collect::<Result<Vec<_>>>()?
        };

        let database = ctx.app_db.read().await.clone();
        let mut transaction = database.pool.begin().await?;
        // SQLCipher returns page_size as TEXT for encrypted databases, unlike
        // SQLite. Cast the table-valued pragma so both return an integer.
        let page_size: i64 =
            sqlx::query_scalar("SELECT CAST(page_size AS INTEGER) FROM pragma_page_size")
                .fetch_one(&mut *transaction)
                .await?;
        let page_count: i64 = sqlx::query_scalar("PRAGMA page_count")
            .fetch_one(&mut *transaction)
            .await?;
        let free_pages: i64 = sqlx::query_scalar("PRAGMA freelist_count")
            .fetch_one(&mut *transaction)
            .await?;

        // Attribute each index (including SQLite's automatic indexes) to its
        // owning table. dbstat includes overflow pages for large text/blobs.
        let table_sizes = sqlx::query(
            "SELECT t.name, \
             COALESCE(SUM(CASE WHEN s.type = 'table' THEN d.pgsize ELSE 0 END), 0) AS table_bytes, \
             COALESCE(SUM(CASE WHEN s.type = 'index' THEN d.pgsize ELSE 0 END), 0) AS index_bytes \
             FROM sqlite_schema t \
             LEFT JOIN sqlite_schema s ON s.tbl_name = t.name AND s.type IN ('table', 'index') \
             LEFT JOIN dbstat d ON d.name = s.name \
             WHERE t.type = 'table' AND t.name NOT LIKE 'sqlite_%' \
             GROUP BY t.name ORDER BY table_bytes + index_bytes DESC, t.name",
        )
        .fetch_all(&mut *transaction)
        .await?;

        let mut tables = Vec::with_capacity(table_sizes.len());
        for table in table_sizes {
            let name: String = table.try_get("name")?;
            let quoted_name = name.replace('"', "\"\"");
            let rows = sqlx::query_scalar(AssertSqlSafe(format!(
                "SELECT COUNT(*) FROM \"{quoted_name}\""
            )))
            .fetch_one(&mut *transaction)
            .await?;
            tables.push(BackupTableSize {
                name,
                rows,
                table_size_bytes: table.try_get("table_bytes")?,
                index_size_bytes: table.try_get("index_bytes")?,
            });
        }
        transaction.commit().await?;

        Ok(BackupStorageInfo {
            database_size_bytes: page_count * page_size,
            free_size_bytes: free_pages * page_size,
            tables,
            files,
        })
    }

    #[allow(clippy::type_complexity)]
    fn get_backup_files(
        ctx: &Context,
        keys: &KeyManager,
    ) -> Result<Vec<(&'static str, PathBuf, bool, Option<String>)>> {
        let config = &ctx.config;
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
        let config = &ctx.config;
        let data_dir = PathBuf::from(&config.data_dir);

        let backup_data_dir = data_dir.join("temp_backup_dir");
        if backup_data_dir.is_dir() {
            std::fs::remove_dir_all(&backup_data_dir)?;
        }
        std::fs::create_dir_all(&backup_data_dir)?;

        let keys = ctx.key_manager.lock().await;

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
                    let app_database = ctx.app_db.read().await.clone();
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
        let data_dir = PathBuf::from(&ctx.config.data_dir);
        let key_manager = ctx.key_manager.lock().await;

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
        // `Pool::close` waits for every checked out connection to come back. A
        // caller that still holds one would hang the restore here forever,
        // while this task keeps the KeyManager locked and every later recovery
        // attempt blocks on it too. The files are replaced right below and the
        // handles are swapped out, so a pool that refuses to drain is not worth
        // waiting for.
        let current_app_database = ctx.app_db.read().await.clone();
        close_pool_or_log(&current_app_database.pool, "app_db").await;
        let current_rust_database = ctx.rust_db.read().await.clone();
        close_pool_or_log(&current_rust_database.pool, "rust_db").await;

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

        let database_dir = PathBuf::from(&ctx.config.database_dir);
        let app_database_path = database_dir.join(APP_DATABASE_FILE);
        let app_database = crate::database::app::AppDatabase::new(
            &app_database_path.display().to_string(),
            Some(&app_database_key),
            false,
        )
        .await?;
        app_database.run_migrations().await?;

        *ctx.app_db.write().await = Arc::new(app_database);

        let rust_database_path = database_dir.join("rust_db.sqlite");
        let rust_database = Database::new(
            &rust_database_path.display().to_string(),
            Some(&rust_database_key),
            false,
        )
        .await?;
        rust_database.run_migrations().await?;

        // A backup is a snapshot of a Double Ratchet at an earlier point in
        // time. Once either peer has advanced past that snapshot, restoring
        // its session record cannot make it current again and can make both
        // sides keep encrypting against incompatible states. Start with no
        // peer sessions instead. The regular V2 send path establishes them
        // lazily from a current prekey bundle, while an old inbound ciphertext
        // is answered by the existing SESSION_RESET_REQUIRED recovery flow.
        //
        // Reset throttles describe the discarded sessions, so retaining them
        // could suppress the first legitimate repair after recovery.
        let mut signal_transaction = rust_database.pool.begin().await?;
        sqlx::query!("DELETE FROM signal_sessions")
            .execute(&mut *signal_transaction)
            .await?;
        sqlx::query!("DELETE FROM signal_session_resets")
            .execute(&mut *signal_transaction)
            .await?;
        signal_transaction.commit().await?;

        ctx.replace_rust_database(rust_database, &key_manager)
            .await?;

        // The restored `user.json` says prekeys were published recently, but
        // the ones the server hands out may have been uploaded after this
        // archive was written, and their private halves are not in it. Sessions
        // peers build from those bundles could never be opened. Clearing the
        // marks makes the next `on_connected` publish a signed prekey and a
        // fresh batch of PQC prekeys that this database actually holds.
        //
        // Peer sessions were discarded above. They are rebuilt lazily from
        // current bundles, avoiding use of ratchet state rewound by the
        // archive. See `signal::reset` for recovery of messages already in
        // flight when the backup was restored.
        if let Err(error) = crate::user_config::UserConfig::update(ctx, |config| {
            config.signal_last_signed_pre_key_updated = None;
            config.signal_last_pqc_pre_keys_uploaded = None;
        }) {
            tracing::warn!("could not schedule a prekey republish after the restore: {error}");
        }

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
    async fn storage_info_measures_pages_indexes_and_backup_sources() {
        let temp_dir = tempdir().unwrap();
        let ctx = Context::init_for_testing(
            temp_dir.path().join("database"),
            temp_dir.path().join("data"),
        )
        .await
        .unwrap();
        let data_dir = PathBuf::from(&ctx.config.data_dir);
        std::fs::create_dir_all(data_dir.join("keyvalue")).unwrap();
        std::fs::write(data_dir.join("keyvalue/user.json"), "{\"userId\":1}").unwrap();
        std::fs::write(data_dir.join("user_discovery_config.json"), "{}").unwrap();

        let database = ctx.app_db.read().await.clone();
        // A quoted identifier exercises row counting; the large blobs require
        // overflow pages, and UNIQUE creates an automatic index.
        sqlx::query("CREATE TABLE \"size\"\"test\" (name TEXT UNIQUE, payload BLOB)")
            .execute(&database.pool)
            .await
            .unwrap();
        sqlx::query("CREATE INDEX size_test_payload ON \"size\"\"test\" (payload)")
            .execute(&database.pool)
            .await
            .unwrap();
        sqlx::query(
            "INSERT INTO \"size\"\"test\" VALUES ('first', zeroblob(100000)), ('second', zeroblob(100000))",
        )
        .execute(&database.pool)
        .await
        .unwrap();

        let info = BackupArchive::storage_info(&ctx).await.unwrap();
        let table = info.tables.iter().find(|t| t.name == "size\"test").unwrap();
        assert_eq!(table.rows, 2);
        assert!(table.table_size_bytes >= 200000);
        assert!(table.index_size_bytes >= 200000);
        let empty = info.tables.iter().find(|t| t.name == "contacts").unwrap();
        assert_eq!(empty.rows, 0);
        assert!(empty.table_size_bytes > 0);
        assert!(info.tables.windows(2).all(|pair| {
            pair[0].table_size_bytes + pair[0].index_size_bytes
                >= pair[1].table_size_bytes + pair[1].index_size_bytes
        }));
        let used_bytes: i64 = info
            .tables
            .iter()
            .map(|t| t.table_size_bytes + t.index_size_bytes)
            .sum();
        assert!(used_bytes + info.free_size_bytes <= info.database_size_bytes);
        let main_file = info
            .files
            .iter()
            .find(|f| f.name == APP_DATABASE_FILE)
            .unwrap();
        assert_eq!(main_file.size_bytes, Some(info.database_size_bytes));
        assert_eq!(info.files.len(), 5);
        for (name, size) in [
            ("twonly.sqlite", None),
            ("user.json", Some(12)),
            ("user_discovery_config.json", Some(2)),
        ] {
            assert_eq!(
                info.files
                    .iter()
                    .find(|f| f.name == name)
                    .unwrap()
                    .size_bytes,
                size
            );
        }
        assert!(!data_dir.join("temp_backup_dir").exists());
        assert!(!data_dir.join("temp_backup.zip").exists());

        sqlx::query("DELETE FROM \"size\"\"test\" WHERE 1")
            .execute(&database.pool)
            .await
            .unwrap();
        let after_delete = BackupArchive::storage_info(&ctx).await.unwrap();
        assert_eq!(after_delete.database_size_bytes, info.database_size_bytes);
        assert!(after_delete.free_size_bytes > info.free_size_bytes);
        assert_eq!(
            after_delete
                .tables
                .iter()
                .find(|t| t.name == "size\"test")
                .unwrap()
                .rows,
            0
        );
    }

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
            let config = &ctx.config;
            let key_manager = ctx.key_manager.lock().await;
            key_manager.store_to_keychain(&secure_storage).unwrap();

            // Add a file
            let config_file = PathBuf::from(&config.data_dir).join("user_discovery_config.json");
            std::fs::write(config_file, "original config").unwrap();
            key_manager.main_key.get_login_token()
        };
        {
            let app_db = ctx.app_db.read().await.clone();
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
        {
            let rust_db = ctx.rust_db.read().await.clone();
            sqlx::query!(
                r#"
                INSERT INTO signal_identities(name, identity_key, timestamp)
                VALUES('restored-peer', x'040506', 1)
                "#
            )
            .execute(&rust_db.pool)
            .await
            .unwrap();
            sqlx::query!(
                r#"
                INSERT INTO signal_sessions(name, device_id, record_bytes)
                VALUES('restored-peer', 1, x'010203')
                "#
            )
            .execute(&rust_db.pool)
            .await
            .unwrap();
            sqlx::query!(
                r#"
                INSERT INTO signal_session_resets(
                    name, device_id, last_reset_at, window_started_at, resets_in_window
                ) VALUES('restored-peer', 1, 1, 1, 1)
                "#
            )
            .execute(&rust_db.pool)
            .await
            .unwrap();
        }

        // 2. Create backup
        let backup_path = BackupArchive::create_backup(&ctx).await.unwrap();
        assert!(backup_path.exists());

        // 3. Modify data (to simulate state before restore)
        {
            let config = &ctx.config;

            let config_file = PathBuf::from(&config.data_dir).join("user_discovery_config.json");
            std::fs::write(config_file, "new config").unwrap();

            let app_db = ctx.app_db.read().await.clone();
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
            let config = &ctx.config;
            let key_manager = ctx.key_manager.lock().await;

            let config_file = PathBuf::from(&config.data_dir).join("user_discovery_config.json");
            let config_content = std::fs::read_to_string(config_file).unwrap();
            assert_eq!(config_content, "original config");

            assert_eq!(key_manager.main_key.get_login_token(), original_login_token);

            let app_db = ctx.app_db.read().await.clone();
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

            let rust_db = ctx.rust_db.read().await.clone();
            let session_count =
                sqlx::query_scalar!(r#"SELECT COUNT(*) AS "count!: i64" FROM signal_sessions"#)
                    .fetch_one(&rust_db.pool)
                    .await
                    .unwrap();
            assert_eq!(session_count, 0, "restored peer sessions must be discarded");

            let reset_count = sqlx::query_scalar!(
                r#"SELECT COUNT(*) AS "count!: i64" FROM signal_session_resets"#
            )
            .fetch_one(&rust_db.pool)
            .await
            .unwrap();
            assert_eq!(
                reset_count, 0,
                "reset throttles for discarded sessions must be cleared"
            );

            let identity_key = sqlx::query_scalar!(
                "SELECT identity_key FROM signal_identities WHERE name = 'restored-peer'"
            )
            .fetch_one(&rust_db.pool)
            .await
            .unwrap();
            assert_eq!(
                identity_key,
                vec![4, 5, 6],
                "a contact's trusted identity key must survive archive recovery"
            );
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
        let database_dir = PathBuf::from(&ctx.config.database_dir);
        let legacy_path = database_dir.join("twonly.sqlite");
        let legacy =
            crate::database::app::AppDatabase::new(&legacy_path.display().to_string(), None, false)
                .await
                .unwrap();
        for migration in [
            include_str!("../database/app/migrations/0001_initial.sql"),
            include_str!("../database/app/migrations/0002_api_outbox.sql"),
            include_str!("../database/app/migrations/0003_notification_outbox.sql"),
            include_str!("../database/app/migrations/0004_sealed_sender.sql"),
            include_str!("../database/app/migrations/0005_direct_media_upload.sql"),
            include_str!("../database/app/migrations/0006_defer_receipts_missing_bundle.sql"),
            include_str!("../database/app/migrations/0007_remove_experimental_transport.sql"),
            include_str!("../database/app/migrations/0008_pending_plaintext.sql"),
            include_str!("../database/app/migrations/0009_outbox_dispatch.sql"),
            include_str!("../database/app/migrations/0010_media_trim.sql"),
            include_str!("../database/app/migrations/0011_outgoing_contact_request.sql"),
        ] {
            sqlx::raw_sql(migration)
                .execute(&legacy.pool)
                .await
                .unwrap();
        }
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

        let app_db = ctx.app_db.read().await.clone();
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

        let restored = ctx.app_db.read().await.clone();
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
        let keys = ctx.key_manager.lock().await;
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
