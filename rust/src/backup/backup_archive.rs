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
#[cfg(test)]
use std::io::copy;
use std::io::Cursor;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use walkdir::WalkDir;
use zeroize::Zeroize;
use zip::write::SimpleFileOptions;
use zip::{CompressionMethod, ZipArchive, ZipWriter};

static BACKUP_OPERATIONS: tokio::sync::Mutex<()> = tokio::sync::Mutex::const_new(());

struct BackupStaging(PathBuf);

impl BackupStaging {
    fn new(parent: &Path) -> Result<Self> {
        let path = parent.join(format!(".backup-{}", uuid::Uuid::new_v4()));

        std::fs::create_dir(&path)?;

        Ok(Self(path))
    }
}

impl Drop for BackupStaging {
    fn drop(&mut self) {
        if let Err(error) = std::fs::remove_dir_all(&self.0) {
            tracing::warn!(%error, "Could not remove backup staging directory");
        }
    }
}

fn copy_cancellable(
    source: &mut impl std::io::Read, destination: &mut impl std::io::Write,
    operation: &crate::database::lifecycle::Operation,
) -> Result<()> {
    let mut buffer = [0; 64 * 1024];

    loop {
        operation.check()?;

        let read = source.read(&mut buffer)?;

        if read == 0 {
            return Ok(());
        }

        destination.write_all(&buffer[..read])?;
    }
}

/// A timeout aborts restore; it never permits replacing a live database.
const POOL_CLOSE_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(10);

async fn close_pool_required(
    pool: &sqlx::SqlitePool, name: &str, timeout: std::time::Duration,
) -> Result<()> {
    tokio::time::timeout(timeout, pool.close())
        .await
        .map_err(|_| {
            crate::error::TwonlyError::Generic(format!(
                "Restore aborted: {name} is still in use. Existing database files were preserved. \
                 Restart before retrying."
            ))
        })?;

    Ok(())
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
            "SELECT t.name, COALESCE(SUM(CASE WHEN s.type = 'table' THEN d.pgsize ELSE 0 END), 0) \
             AS table_bytes, COALESCE(SUM(CASE WHEN s.type = 'index' THEN d.pgsize ELSE 0 END), \
             0) AS index_bytes FROM sqlite_schema t LEFT JOIN sqlite_schema s ON s.tbl_name = \
             t.name AND s.type IN ('table', 'index') LEFT JOIN dbstat d ON d.name = s.name WHERE \
             t.type = 'table' AND t.name NOT LIKE 'sqlite_%' GROUP BY t.name ORDER BY table_bytes \
             + index_bytes DESC, t.name",
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
        ctx: &Context, keys: &KeyManager,
    ) -> Result<Vec<(&'static str, PathBuf, bool, Option<String>)>> {
        let config = &ctx.config;

        let database_dir = PathBuf::from(&config.database_dir);

        let data_dir = PathBuf::from(&config.data_dir);

        let rust_db_key = keys.main_key.get_database_key(DatabaseKey::RustDb);

        let app_db_key = keys.main_key.get_database_key(DatabaseKey::AppDb);

        Ok(vec![
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

    #[cfg(test)]
    pub(crate) async fn create_backup(ctx: &Arc<Context>) -> Result<PathBuf> {
        Self::create_backup_with_token(ctx)
            .await
            .map(|(_, path)| path)
    }

    pub(crate) async fn create_backup_with_token(ctx: &Arc<Context>) -> Result<(String, PathBuf)> {
        let ctx = ctx.clone();

        crate::database::lifecycle::run(move |operation| async move {
            Self::create_backup_with_operation(&ctx, operation).await
        })
        .await
    }

    /// A scheduled task already owns an OS execution grant. Reuse its lease
    /// instead of requesting foreground admission from UIKit.
    pub(crate) async fn create_backup_with_operation(
        ctx: &Arc<Context>, operation: crate::database::lifecycle::Operation,
    ) -> Result<(String, PathBuf)> {
        let _exclusive = tokio::select! {
            biased;
            _ = operation.until_cancelled() => return operation.check().map(|_| unreachable!()),
            guard = BACKUP_OPERATIONS.lock() => guard,
        };
        Self::create_backup_owned(ctx, operation).await
    }

    async fn create_backup_owned(
        ctx: &Context, operation: crate::database::lifecycle::Operation,
    ) -> Result<(String, PathBuf)> {
        operation.check()?;

        let _lifecycle = tokio::select! {
            _ = operation.until_cancelled() => return operation.check().map(|_| unreachable!()),
            guard = ctx.database_lifecycle.lock() => guard,
        };

        let data_dir = PathBuf::from(&ctx.config.data_dir);

        let staging = BackupStaging::new(&data_dir)?;

        let backup_data_dir = &staging.0;

        // Do not retain the global key-manager mutex during SQL, compression
        // or file I/O. MainKey and every derived database key zeroize on drop.
        let (files, main_key) = {
            let keys = ctx.key_manager.lock().await;

            let files = Self::get_backup_files(ctx, &keys)?
                .into_iter()
                .map(|(name, path, is_db, key)| {
                    (name, path, is_db, key.map(zeroize::Zeroizing::new))
                })
                .collect::<Vec<_>>();

            (files, keys.main_key.clone())
        };

        // Both database snapshots and settings represent one writer-frozen
        // boundary. The lifecycle lock prevents a root-key replacement too.
        for (name, source, is_db, _) in &files {
            if *is_db && !source.join(name).try_exists()? {
                return Err(crate::error::TwonlyError::Generic(format!(
                    "Required backup database {name} is missing"
                )));
            }
        }

        super::capture::capture(ctx, backup_data_dir, &operation).await?;

        for (file_name, source_dir, is_db, encryption_key) in files {
            operation.check()?;

            let source = source_dir.join(file_name);

            if !source.try_exists()? {
                if is_db {
                    return Err(crate::error::TwonlyError::Generic(format!(
                        "Required backup database {file_name} is missing"
                    )));
                }

                tracing::warn!("Backup source {} is absent", source.display());

                continue;
            }

            let destination = backup_data_dir.join(file_name);

            if is_db {
                let first = if file_name == "rust_db.sqlite" {
                    backup_data_dir.join("signal-working.sqlite")
                } else {
                    destination.clone()
                };

                let database = Database::new(
                    &first.display().to_string(),
                    encryption_key.as_ref().map(|key| key.as_str()),
                    false,
                )
                .await?;

                let mut connection = match database.pool.acquire().await {
                    Ok(connection) => connection,
                    Err(error) => {
                        database.pool.close().await;

                        return Err(error.into());
                    }
                };

                // Always close the staging pool, including mutation/check
                // failure. This pool never owns a live user database.
                let result = async {
                    crate::database::snapshot::watch(&mut connection, &operation).await?;

                    if file_name == "rust_db.sqlite" {
                        let mut tx = sqlx::Connection::begin(&mut *connection).await?;

                        sqlx::query!("DELETE FROM signal_sessions")
                            .execute(&mut *tx)
                            .await?;

                        sqlx::query!("DELETE FROM signal_session_resets")
                            .execute(&mut *tx)
                            .await?;

                        tx.commit().await?;

                        // Rebuild to omit freed ratchet pages as well as rows.
                        crate::database::snapshot::create(&database.pool, &destination, &operation)
                            .await?;
                    } else {
                        crate::services::live_location::discard_sessions_on(&mut connection)
                            .await?;
                    }

                    operation.check()?;

                    let integrity = sqlx::query_scalar!("PRAGMA integrity_check")
                        .fetch_all(&mut *connection)
                        .await?;

                    if integrity != [Some("ok".to_owned())] {
                        return Err(crate::error::TwonlyError::Generic(
                            "Staged backup integrity check failed".into(),
                        ));
                    }

                    Ok::<_, crate::error::TwonlyError>(())
                }
                .await;

                let closed = connection.close().await;

                database.pool.close().await;

                result?;

                closed?;

                if first != destination {
                    remove_file(first)?;
                }
            } else {
                // Settings were copied at the same frozen boundary above.
            }
        }

        drop(_lifecycle);

        operation.check()?;

        let download_token = hex::encode(main_key.get_backup_download_token());

        let directory = backup_data_dir.clone();

        let archive_operation = operation.clone();

        let archive = crate::database::lifecycle::spawn_blocking(move || {
            Self::write_manifest(&directory, Some(&archive_operation))?;

            let mut zip_data = Vec::new();

            {
                let mut zip = ZipWriter::new(Cursor::new(&mut zip_data));

                let options =
                    SimpleFileOptions::default().compression_method(CompressionMethod::Deflated);

                for entry in WalkDir::new(&directory) {
                    archive_operation.check()?;

                    let entry = entry?;

                    let path = entry.path();

                    if path.is_file() && !crate::database::maintenance::is_lock_file(path) {
                        let name = path.strip_prefix(&directory).map_err(|error| {
                            crate::error::TwonlyError::Generic(error.to_string())
                        })?;

                        zip.start_file(name.to_string_lossy(), options)?;

                        copy_cancellable(&mut File::open(path)?, &mut zip, &archive_operation)?;
                    }
                }

                zip.finish()?;
            }

            archive_operation.check()?;

            let encrypted = main_key.encrypt_backup(&zip_data);

            archive_operation.check()?;

            let archive = directory.join("archive.ready");

            let mut file = File::create(&archive)?;

            std::io::Write::write_all(&mut file, &encrypted)?;

            file.sync_all()?;

            Ok::<_, crate::error::TwonlyError>(archive)
        })
        .await
        .map_err(|error| crate::error::TwonlyError::Generic(error.to_string()))??;

        operation.check()?;

        let zip_path = data_dir.join("temp_backup.zip");

        // Atomic publication keeps the previous complete archive on failure.
        std::fs::rename(archive, &zip_path)?;

        Ok((download_token, zip_path))
    }

    pub(crate) async fn restore_from_backup(ctx: &Arc<Context>, file_path: &Path) -> Result<()> {
        let ctx = ctx.clone();

        let file_path = file_path.to_owned();

        crate::database::lifecycle::run(move |operation| async move {
            let admission = crate::database::lifecycle::native_admission(&operation).await?;

            let result = Self::restore_owned(&ctx, &file_path).await;

            ctx.resume_after_restore(admission).await?;

            result
        })
        .await
    }

    async fn restore_owned(ctx: &Arc<Context>, file_path: &Path) -> Result<()> {
        let _exclusive = BACKUP_OPERATIONS.lock().await;

        let _lifecycle = ctx.database_lifecycle.lock().await;

        let data_dir = PathBuf::from(&ctx.config.data_dir);

        let pending_identity = crate::keys::restore::pending(&ctx.secure_storage)?;

        let main_key = if let Some(identity) = &pending_identity {
            identity.key_manager.main_key.clone()
        } else {
            ctx.key_manager.lock().await.main_key.clone()
        };

        let owned_path = file_path.to_owned();

        let decrypt_key = main_key.clone();

        let operation = crate::database::lifecycle::Operation::current().ok_or_else(|| {
            crate::error::TwonlyError::Generic("Restore requires an execution owner".into())
        })?;

        let staging = crate::database::lifecycle::spawn_blocking(move || {
            let staging = BackupStaging::new(&data_dir)?;

            let mut encrypted_zip = Vec::new();

            copy_cancellable(&mut File::open(owned_path)?, &mut encrypted_zip, &operation)?;

            operation.check()?;

            let zip_content = decrypt_key.decrypt_backup(&encrypted_zip)?;

            operation.check()?;

            let mut archive = ZipArchive::new(Cursor::new(zip_content))?;

            for i in 0..archive.len() {
                operation.check()?;

                let mut file = archive.by_index(i)?;

                if file.is_file() {
                    if let Some(name) = file
                        .enclosed_name()
                        .as_ref()
                        .and_then(|path| path.file_name())
                    {
                        copy_cancellable(
                            &mut file,
                            &mut File::create(staging.0.join(name))?,
                            &operation,
                        )?;
                    }
                }
            }

            Self::validate_manifest(&staging.0)?;

            Ok::<_, crate::error::TwonlyError>(staging)
        })
        .await
        .map_err(|error| {
            crate::error::TwonlyError::Generic(format!("Restore validation worker failed: {error}"))
        })??;

        let restore_temp_dir = &staging.0;

        let restored_app_database = restore_temp_dir.join(APP_DATABASE_FILE);

        let has_app_database = restored_app_database.exists();

        let app_database_key =
            zeroize::Zeroizing::new(main_key.get_database_key(DatabaseKey::AppDb));

        let staged_app_database = crate::database::app::AppDatabase::new(
            &restored_app_database.display().to_string(),
            Some(&app_database_key),
            false,
        )
        .await?;

        let app_prepared = async {
            staged_app_database.run_migrations().await?;

            if !has_app_database {
                staged_app_database
                    .import_legacy(&restore_temp_dir.join("twonly.sqlite"))
                    .await?;
            }

            crate::services::live_location::discard_sessions(&staged_app_database.pool).await?;

            let integrity = sqlx::query_scalar!(r#"PRAGMA integrity_check"#)
                .fetch_one(&staged_app_database.pool)
                .await?;

            if integrity.as_deref() != Some("ok") {
                return Err(crate::error::TwonlyError::Generic(
                    "Staged app database integrity check failed".into(),
                ));
            }

            Ok::<_, crate::error::TwonlyError>(())
        }
        .await;

        staged_app_database.close().await;

        app_prepared?;

        let rust_database_key =
            zeroize::Zeroizing::new(main_key.get_database_key(DatabaseKey::RustDb));

        let staged_rust_database_path = restore_temp_dir.join("rust_db.sqlite");

        let staged_rust_database = Database::new(
            &staged_rust_database_path.display().to_string(),
            Some(&rust_database_key),
            false,
        )
        .await?;

        let signal_prepared = async {
            staged_rust_database.run_migrations().await?;

            // Ratchets from an earlier snapshot cannot be resumed safely.
            // Scrub before publication, including reset throttles that could
            // suppress the first repair after the restored app starts.
            let mut transaction = staged_rust_database.pool.begin().await?;

            sqlx::query!("DELETE FROM signal_sessions")
                .execute(&mut *transaction)
                .await?;

            sqlx::query!("DELETE FROM signal_session_resets")
                .execute(&mut *transaction)
                .await?;

            transaction.commit().await?;

            staged_rust_database.check_integrity().await
        }
        .await;

        staged_rust_database.pool.close().await;

        signal_prepared?;

        // app_db.sqlite is owned by a replaceable Rust handle. Close it before
        // replacing the file so subsequent DAO calls cannot continue using an
        // unlinked pre-restore database.
        // `Pool::close` must acknowledge closure of every checked-out native
        // connection. On timeout, fail closed before touching any live file.
        if let Some(operation) = crate::database::lifecycle::Operation::current() {
            operation.check()?;
        }

        let current_app_database = ctx.app_db.read().await.clone();

        // Stop producers before closing handles; their blocking work and
        // native codecs retain lifecycle tickets until they actually stop.
        tokio::time::timeout(POOL_CLOSE_TIMEOUT, ctx.quiesce_for_restore())
            .await
            .map_err(|_| {
                crate::error::TwonlyError::Generic(
                    "Restore quiescence timed out; files were preserved".into(),
                )
            })??;

        close_pool_required(&current_app_database.pool, "app_db", POOL_CLOSE_TIMEOUT).await?;

        let current_rust_database = ctx.rust_db.read().await.clone();

        close_pool_required(&current_rust_database.pool, "rust_db", POOL_CLOSE_TIMEOUT).await?;

        let configuration = crate::bridge::InitConfig {
            database_dir: ctx.config.database_dir.clone(),
            data_dir: ctx.config.data_dir.clone(),
        };

        let operation = crate::database::lifecycle::Operation::current();

        let storage = ctx.secure_storage.clone();

        let identity = pending_identity
            .as_ref()
            .map(|identity| identity.id.clone());

        // Pools are fully closed before taking this mutex. The blocking owner
        // retains it even if its bridge caller disappears, then updates the
        // cached identity before any queued key mutation can run.
        let mut active_keys = ctx.key_manager.clone().lock_owned().await;

        // The owner retains staging and exclusive locks until installation or
        // rollback finishes, even if the bridge future is abandoned.
        let (installed, refreshed) = crate::database::lifecycle::spawn_blocking(move || {
            let staging = staging;

            let installed = crate::database::restore_install::install(
                &configuration,
                &staging.0,
                operation.as_ref(),
                &storage,
                identity.as_deref(),
            );

            let refreshed = if crate::database::maintenance::ensure_no_restore(Path::new(
                &configuration.database_dir,
            ))
            .is_ok()
            {
                KeyManager::try_from_keychain(&storage).map(|keys| *active_keys = keys)
            } else {
                Ok(())
            };

            (installed, refreshed)
        })
        .await
        .map_err(|error| {
            crate::error::TwonlyError::Generic(format!(
                "Restore installation worker failed: {error}"
            ))
        })?;

        // A secure-store read failure after commit must leave pools closed;
        // reopening their old source keys could revive a stale identity.
        refreshed?;

        if let Err(error) = installed {
            if crate::database::maintenance::ensure_no_restore(Path::new(&ctx.config.database_dir))
                .is_ok()
            {
                let app = current_app_database.reopen().await?;

                let signal = current_rust_database.reopen().await?;

                *ctx.app_db.write().await = Arc::new(app);

                let keys = ctx.key_manager.lock().await;

                ctx.replace_rust_database(signal, &keys).await?;
            }

            return Err(error);
        }

        let database_dir = PathBuf::from(&ctx.config.database_dir);

        let app_database = current_app_database
            .reopen_with_key(Some(&app_database_key))
            .await?;

        let rust_database_path = database_dir.join("rust_db.sqlite");

        let rust_database = Database::new(
            &rust_database_path.display().to_string(),
            Some(&rust_database_key),
            false,
        )
        .await?;

        *ctx.app_db.write().await = Arc::new(app_database);

        let mut keys = ctx.key_manager.lock().await;

        *keys = KeyManager::try_from_keychain(&ctx.secure_storage)?;

        ctx.replace_rust_database(rust_database, &keys).await?;

        Ok(())
    }

    fn write_manifest(
        directory: &Path, operation: Option<&crate::database::lifecycle::Operation>,
    ) -> Result<()> {
        let mut files = BTreeMap::new();

        for entry in WalkDir::new(directory).min_depth(1).max_depth(1) {
            let entry = entry?;

            if !entry.path().is_file()
                || entry.file_name() == BACKUP_MANIFEST_FILE
                || crate::database::maintenance::is_lock_file(entry.path())
            {
                continue;
            }

            files.insert(
                entry.file_name().to_string_lossy().to_string(),
                Self::measure_file(entry.path(), operation)?,
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

    fn measure_file(
        path: &Path, operation: Option<&crate::database::lifecycle::Operation>,
    ) -> Result<BackupManifestFile> {
        use std::io::Read;

        let mut file = File::open(path)?;

        let mut buffer = [0; 64 * 1024];

        let mut hash = Sha256::new();

        let mut size = 0;

        loop {
            if let Some(operation) = operation {
                operation.check()?;
            }

            let read = file.read(&mut buffer)?;

            if read == 0 {
                break;
            }

            size += read as u64;

            hash.update(&buffer[..read]);
        }

        Ok(BackupManifestFile {
            size,
            sha256: hex::encode(hash.finalize()),
        })
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

            let actual = Self::measure_file(&file, None)?;

            if actual.size != expected.size || actual.sha256 != expected.sha256 {
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

    async fn restore_refuses_an_idle_other_handle_preserves_files_and_reopens_original_pools() {
        let directory = tempdir().unwrap();

        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await
        .unwrap();

        let archive = BackupArchive::create_backup(&ctx).await.unwrap();

        sqlx::query!("INSERT INTO app_metadata(key, value) VALUES ('active', 'preserved')")
            .execute(&ctx.app_db.read().await.pool)
            .await
            .unwrap();

        let key = ctx
            .key_manager
            .lock()
            .await
            .main_key
            .get_database_key(DatabaseKey::AppDb);

        let path = directory.path().join("database").join(APP_DATABASE_FILE);

        // No active statement/transaction: SQLite's ordinary lock probe would
        // consider this idle handle safe even though its cached key remains live.
        let other = Database::new(&path.display().to_string(), Some(&key), true)
            .await
            .unwrap();

        let app_before = std::fs::read(&path).unwrap();

        let signal_path = directory.path().join("database/rust_db.sqlite");

        let signal_before = std::fs::read(&signal_path).unwrap();

        let error = BackupArchive::restore_from_backup(&ctx, &archive)
            .await
            .unwrap_err();

        assert!(
            error.to_string().contains("maintenance deferred"),
            "{error}"
        );

        assert_eq!(std::fs::read(&path).unwrap(), app_before);

        assert_eq!(std::fs::read(&signal_path).unwrap(), signal_before);

        let app = ctx.app_db.read().await.clone();

        assert_eq!(
            sqlx::query_scalar!("SELECT value FROM app_metadata WHERE key = 'active'")
                .fetch_one(&app.pool)
                .await
                .unwrap(),
            "preserved"
        );

        assert!(!ctx.rust_db.read().await.pool.is_closed());

        other.pool.close().await;

        tokio::join!(app.pool.close(), async {
            ctx.rust_db.read().await.pool.close().await
        });
    }

    #[tokio::test]

    async fn a_missing_live_database_preserves_the_previous_archive_and_cleans_staging() {
        let directory = tempdir().unwrap();

        let ctx = Context::init_for_testing(
            directory.path().join("databases"),
            directory.path().join("data"),
        )
        .await
        .unwrap();

        let archive = BackupArchive::create_backup(&ctx).await.unwrap();

        let previous = std::fs::read(&archive).unwrap();

        ctx.rust_db.read().await.pool.close().await;

        std::fs::remove_file(directory.path().join("databases/rust_db.sqlite")).unwrap();

        assert!(BackupArchive::create_backup(&ctx).await.is_err());

        assert_eq!(std::fs::read(&archive).unwrap(), previous);

        assert!(!std::fs::read_dir(directory.path().join("data"))
            .unwrap()
            .any(|entry| {
                entry
                    .unwrap()
                    .file_name()
                    .to_string_lossy()
                    .starts_with(".backup-")
            }));

        ctx.app_db.read().await.pool.close().await;
    }

    #[tokio::test]

    async fn a_close_timeout_preserves_the_original_database_and_its_active_transaction() {
        let directory = tempdir().unwrap();

        let path = directory.path().join("live.sqlite");

        let database = crate::database::app::AppDatabase::new(path.to_str().unwrap(), None, false)
            .await
            .unwrap();

        database.run_migrations().await.unwrap();

        let mut transaction = database.pool.begin().await.unwrap();

        sqlx::query!("INSERT INTO app_metadata(key, value) VALUES ('active', 'preserved')")
            .execute(&mut *transaction)
            .await
            .unwrap();

        let error = close_pool_required(
            &database.pool,
            "app_db",
            std::time::Duration::from_millis(10),
        )
        .await
        .unwrap_err();

        assert!(error.to_string().contains("Restore aborted"));

        assert!(path.exists());

        transaction.commit().await.unwrap();

        database.pool.close().await;

        let reopened = crate::database::app::AppDatabase::new(path.to_str().unwrap(), None, false)
            .await
            .unwrap();

        assert_eq!(
            sqlx::query_scalar!("SELECT value FROM app_metadata WHERE key = 'active'")
                .fetch_one(&reopened.pool)
                .await
                .unwrap(),
            "preserved"
        );

        reopened.pool.close().await;
    }

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
            "INSERT INTO \"size\"\"test\" VALUES ('first', zeroblob(100000)), ('second', \
             zeroblob(100000))",
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

        assert_eq!(
            main_file.size_bytes,
            Some(
                Path::new(&ctx.config.database_dir)
                    .join(APP_DATABASE_FILE)
                    .metadata()
                    .unwrap()
                    .len() as i64
            )
        );

        if !cfg!(feature = "sqlite-wal") {
            assert_eq!(main_file.size_bytes, Some(info.database_size_bytes));
        }

        assert_eq!(info.files.len(), 4);

        assert!(!info.files.iter().any(|file| file.name == "twonly.sqlite"));

        for (name, size) in [
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

    async fn backup_omits_peer_sessions_without_changing_live_signal_state() {
        let temp_dir = tempdir().unwrap();

        let ctx = Context::init_for_testing(
            temp_dir.path().join("database"),
            temp_dir.path().join("data"),
        )
        .await
        .unwrap();

        let live_db = ctx.rust_db.read().await.clone();

        for statement in [
            "INSERT INTO signal_sessions VALUES ('peer', 1, zeroblob(262144))",
            "INSERT INTO signal_session_resets VALUES ('peer', 1, 1, 1, 1)",
            "INSERT INTO signal_identities VALUES ('peer', x'040506', 1)",
            "INSERT INTO signal_pre_keys VALUES (1, x'010203')",
            "INSERT INTO signal_signed_pre_keys VALUES (1, x'010203')",
            "INSERT INTO signal_kyber_pre_keys VALUES (1, x'010203')",
        ] {
            sqlx::query(AssertSqlSafe(statement))
                .execute(&live_db.pool)
                .await
                .unwrap();
        }

        let live_path = PathBuf::from(&ctx.config.database_dir).join("rust_db.sqlite");

        let live_size = live_path.metadata().unwrap().len();

        let backup_path = BackupArchive::create_backup(&ctx).await.unwrap();

        let keys = ctx.key_manager.lock().await;

        let archive_bytes = keys
            .main_key
            .decrypt_backup(&std::fs::read(&backup_path).unwrap())
            .unwrap();

        let database_key = keys.main_key.get_database_key(DatabaseKey::RustDb);

        drop(keys);

        let mut archive = ZipArchive::new(Cursor::new(archive_bytes)).unwrap();

        let extracted_path = temp_dir.path().join("backup_signal.sqlite");

        copy(
            &mut archive.by_name("rust_db.sqlite").unwrap(),
            &mut File::create(&extracted_path).unwrap(),
        )
        .unwrap();

        let backup_db = Database::new(
            &extracted_path.display().to_string(),
            Some(&database_key),
            true,
        )
        .await
        .unwrap();

        backup_db.check_integrity().await.unwrap();

        for (table, expected_backup_rows) in [
            ("signal_sessions", 0_i64),
            ("signal_session_resets", 0),
            ("signal_identities", 1),
            ("signal_pre_keys", 1),
            ("signal_signed_pre_keys", 1),
            ("signal_kyber_pre_keys", 1),
        ] {
            let query = format!("SELECT COUNT(*) FROM {table}");

            let backup_rows: i64 = sqlx::query_scalar(AssertSqlSafe(query.as_str()))
                .fetch_one(&backup_db.pool)
                .await
                .unwrap();

            assert_eq!(backup_rows, expected_backup_rows, "backup rows in {table}");

            let live_rows: i64 = sqlx::query_scalar(AssertSqlSafe(query.as_str()))
                .fetch_one(&live_db.pool)
                .await
                .unwrap();

            assert_eq!(live_rows, 1, "backup must preserve live rows in {table}");
        }

        let live_session_bytes: i64 =
            sqlx::query_scalar("SELECT length(record_bytes) FROM signal_sessions")
                .fetch_one(&live_db.pool)
                .await
                .unwrap();

        assert_eq!(live_session_bytes, 262144);

        assert_eq!(live_path.metadata().unwrap().len(), live_size);

        assert!(
            extracted_path.metadata().unwrap().len() + 262144 <= live_size,
            "the exported backup must reclaim the discarded session pages"
        );

        backup_db.pool.close().await;
    }

    #[tokio::test]

    async fn staged_identity_installs_only_with_the_matching_encrypted_archive() {
        let directory = tempdir().unwrap();

        let source = Context::init_for_testing(
            directory.path().join("source-db"),
            directory.path().join("source-data"),
        )
        .await
        .unwrap();

        let destination = Context::init_for_testing(
            directory.path().join("destination-db"),
            directory.path().join("destination-data"),
        )
        .await
        .unwrap();

        sqlx::query!(
            r#"
                INSERT INTO contacts(user_id, username)
                VALUES(1, 'original contact')
                "#
        )
        .execute(&source.app_db.read().await.pool)
        .await
        .unwrap();

        let archive = BackupArchive::create_backup(&source).await.unwrap();

        let old = destination.key_manager.lock().await.to_bytes().unwrap();

        let imported = source.key_manager.lock().await.to_bytes().unwrap();

        crate::keys::restore::stage(
            &destination.secure_storage,
            KeyManager::from_bytes(&imported).unwrap(),
        )
        .unwrap();

        assert_eq!(
            destination.key_manager.lock().await.to_bytes().unwrap(),
            old
        );

        assert_eq!(
            KeyManager::try_from_keychain(&destination.secure_storage)
                .unwrap()
                .to_bytes()
                .unwrap(),
            old
        );

        // The existing archive is encrypted under the destination's old key:
        // rejection must keep its current handles and durable identity intact.
        let wrong_archive = BackupArchive::create_backup(&destination).await.unwrap();

        assert!(
            BackupArchive::restore_from_backup(&destination, &wrong_archive)
                .await
                .is_err()
        );

        assert_eq!(
            KeyManager::try_from_keychain(&destination.secure_storage)
                .unwrap()
                .to_bytes()
                .unwrap(),
            old
        );

        assert_eq!(
            sqlx::query_scalar!("SELECT COUNT(*) FROM contacts")
                .fetch_one(&destination.app_db.read().await.pool)
                .await
                .unwrap(),
            0
        );

        BackupArchive::restore_from_backup(&destination, &archive)
            .await
            .unwrap();

        assert_eq!(
            destination.key_manager.lock().await.to_bytes().unwrap(),
            imported
        );

        assert_eq!(
            KeyManager::try_from_keychain(&destination.secure_storage)
                .unwrap()
                .to_bytes()
                .unwrap(),
            imported
        );

        assert!(crate::keys::restore::pending(&destination.secure_storage)
            .unwrap()
            .is_none());

        assert_eq!(
            sqlx::query_scalar!("SELECT COUNT(*) FROM contacts")
                .fetch_one(&destination.app_db.read().await.pool)
                .await
                .unwrap(),
            1
        );

        for context in [source, destination] {
            crate::api::runtime::ApiRuntime::close(&context)
                .await
                .unwrap();

            context.app_db.read().await.pool.close().await;

            context.rust_db.read().await.pool.close().await;
        }
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
        let legacy_file = PathBuf::from(&ctx.config.database_dir).join("twonly.sqlite");

        std::fs::write(&legacy_file, b"obsolete legacy database").unwrap();

        let backup_path = BackupArchive::create_backup(&ctx).await.unwrap();

        assert!(backup_path.exists());

        {
            let keys = ctx.key_manager.lock().await;

            let archive_bytes = keys
                .main_key
                .decrypt_backup(&std::fs::read(&backup_path).unwrap())
                .unwrap();

            let mut archive = ZipArchive::new(Cursor::new(archive_bytes)).unwrap();

            assert!(archive.by_name("twonly.sqlite").is_err());

            assert!(archive.by_name(APP_DATABASE_FILE).is_ok());
        }

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

        assert_eq!(
            std::fs::read(&legacy_file).unwrap(),
            b"obsolete legacy database"
        );

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

        // Build an actual historical archive explicitly; current backups no
        // longer include the old database.
        remove_file_from_encrypted_archive(
            &ctx,
            &archive_path,
            APP_DATABASE_FILE,
            Some(&legacy_path),
        )
        .await;

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
        ctx: &Context, archive_path: &Path, excluded_name: &str, legacy_file: Option<&Path>,
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
                let name = entry.name().unwrap().into_owned();

                if name == excluded_name || name == BACKUP_MANIFEST_FILE || !entry.is_file() {
                    continue;
                }

                writer.start_file(name, options).unwrap();

                copy(&mut entry, &mut writer).unwrap();
            }

            if let Some(path) = legacy_file {
                writer.start_file("twonly.sqlite", options).unwrap();

                copy(&mut File::open(path).unwrap(), &mut writer).unwrap();
            }

            writer.finish().unwrap();
        }

        std::fs::write(archive_path, keys.main_key.encrypt_backup(&rebuilt)).unwrap();
    }
}
