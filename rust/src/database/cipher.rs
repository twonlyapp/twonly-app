/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! How the SQLCipher key is handed to `PRAGMA key`, and the one-time migration
//! between the two forms.
//!
//! Both database keys are 32-byte HKDF outputs of the main key
//! (`MainKey::get_database_key`), hex encoded. They already have full entropy,
//! so nothing is gained by stretching them — but passing them to `PRAGMA key`
//! as a *passphrase*, which is what earlier versions did, makes SQLCipher run
//! PBKDF2-HMAC-SHA512 over 256000 iterations before it can touch the file.
//! That costs roughly 45 ms per connection on a desktop and several times that
//! on a phone, and it is paid by every connection a pool ever opens, not just
//! the first.
//!
//! SQLCipher's raw key form (`x'<hex>'`) uses the bytes as the AES key
//! directly and skips the derivation entirely. The two forms produce different
//! encryption keys, so a database written by an older version has to be
//! re-encrypted once. [`prepare`] does that transparently on the first
//! read-write open and is a no-op afterwards.

use crate::error::Result;
use sqlx::sqlite::SqliteConnectOptions;
use sqlx::{ConnectOptions, Connection, SqliteConnection};
use std::path::Path;
use std::str::FromStr;
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::Duration;

mod rekey;

/// Whether this process may re-encrypt a database it finds on the old key.
///
/// Only the foreground app does. The iOS notification service extension opens
/// the same files out of the shared app group, and it is short-lived and killed
/// aggressively by the OS — a rekey interrupted there would be retried on every
/// push instead of once, and any connection another process holds open across
/// the switch would start failing. Leaving the rewrite to the app means it
/// happens once, while the user is looking at it, and a background process
/// simply keeps opening the database on the key it already has.

static MIGRATION_ENABLED: AtomicBool = AtomicBool::new(true);

/// Set from `Context::init_common` once the runtime mode is known.

pub(crate) fn set_migration_enabled(enabled: bool) {
    MIGRATION_ENABLED.store(enabled, Ordering::Release);
}

/// How a key string is spelled in `PRAGMA key`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]

pub(crate) enum KeyForm {
    /// `x'<hex>'`. The 32 bytes become the AES key with no derivation.
    Raw,
    /// `'<text>'`. SQLCipher stretches the text with PBKDF2-HMAC-SHA512.
    Passphrase,
}

impl KeyForm {
    /// The right-hand side of `PRAGMA key = …` for this form.

    pub(crate) fn pragma_value(self, key: &str) -> String {
        match self {
            // The double quotes are part of SQLCipher's documented raw key
            // syntax: PRAGMA key = "x'2DD29CA8…'".
            Self::Raw => format!("\"x'{key}'\""),
            Self::Passphrase => format!("'{key}'"),
        }
    }
}

/// Only a 64 character hex string is exactly the 32 bytes SQLCipher wants for a
/// raw key. Anything else (test fixtures, a user-chosen password) stays on the
/// passphrase path, where SQLCipher derives a key of the right size itself.

fn can_use_raw_key(key: &str) -> bool {
    key.len() == 64 && key.bytes().all(|byte| byte.is_ascii_hexdigit())
}

/// A path SQLCipher will open as a real file on disk. In-memory databases are
/// created fresh every time and never need migrating.

fn is_file_backed(db_path: &str) -> bool {
    !db_path.contains(":memory:")
}

/// True when the file already holds an encrypted database. A missing or empty
/// file is about to be created, and gets the raw key from the start.

fn has_existing_database(db_path: &str) -> bool {
    Path::new(db_path)
        .metadata()
        .is_ok_and(|metadata| metadata.is_file() && metadata.len() > 0)
}

/// Opens a bare connection to an existing database with `key` in `form`.

async fn connect(
    db_path: &str, key: &str, form: KeyForm, read_only: bool,
) -> Result<SqliteConnection> {
    super::maintenance::initialize()?;

    let operation = crate::database::lifecycle::Operation::current();

    if let Some(operation) = &operation {
        operation.check()?;
    }

    let options = SqliteConnectOptions::from_str(&format!("sqlite://{db_path}"))?
        .create_if_missing(false)
        // SQLx 0.9 leaves journal_mode alone unless explicitly configured.
        // Probes must preserve an existing journal and read committed WAL data.
        .read_only(read_only)
        .busy_timeout(if operation.is_some() {
            Duration::from_millis(50)
        } else {
            Duration::from_secs(30)
        })
        .log_statements(tracing::log::LevelFilter::Off)
        .pragma("key", form.pragma_value(key));

    let mut connection = options.connect().await?;

    let installed = crate::database::lifecycle::pool::PoolOperations::new()
        .connect(&mut connection)
        .await;

    if let Err(error) = installed {
        let _ = connection.close().await;

        return Err(error.into());
    }

    Ok(connection)
}

/// Whether `key` in `form` actually decrypts the database. Reading the schema
/// is the cheapest statement that has to touch the (encrypted) first page.

async fn decrypts_with(db_path: &str, key: &str, form: KeyForm) -> bool {
    let Ok(mut connection) = connect(db_path, key, form, true).await else {
        return false;
    };

    let readable = sqlx::query_scalar!(r#"SELECT COUNT(*) AS "count!: i64" FROM sqlite_master"#)
        .fetch_one(&mut connection)
        .await
        .is_ok();

    let _ = connection.close().await;

    readable
}

/// Decides which key form to open `db_path` with, migrating a database still
/// encrypted with the passphrase-derived key when it can be opened read-write.
///
/// Never fails because of a key it cannot place: if neither form decrypts the
/// file, the caller's own connection reports the real error with its own
/// context instead.

pub(crate) async fn prepare(db_path: &str, key: &str, read_only: bool) -> Result<KeyForm> {
    let operation = crate::database::lifecycle::Operation::current();

    if let Some(operation) = &operation {
        operation.check()?;
    }

    if !can_use_raw_key(key) || !is_file_backed(db_path) {
        return Ok(KeyForm::Passphrase);
    }

    if !has_existing_database(db_path) {
        return Ok(KeyForm::Raw);
    }

    let raw = decrypts_with(db_path, key, KeyForm::Raw).await;

    if let Some(operation) = &operation {
        operation.check()?;
    }

    if raw {
        return Ok(KeyForm::Raw);
    }

    let passphrase = decrypts_with(db_path, key, KeyForm::Passphrase).await;

    if let Some(operation) = &operation {
        operation.check()?;
    }

    if !passphrase {
        return Ok(KeyForm::Raw);
    }

    if read_only {
        // Staged backup archives are verified read-only before they replace
        // anything. They get migrated when they are opened for writing.
        return Ok(KeyForm::Passphrase);
    }

    if !MIGRATION_ENABLED.load(Ordering::Acquire) {
        return Ok(KeyForm::Passphrase);
    }

    if operation
        .as_ref()
        .is_some_and(|operation| !operation.is_foreground())
    {
        // The foreground process can later reopen for a bounded native run.
        // Its old process-wide migration flag must not authorize rekey there.
        return Ok(KeyForm::Passphrase);
    }

    tracing::info!(
        database = %Path::new(db_path)
            .file_name()
            .unwrap_or_default()
            .to_string_lossy(),
        "re-encrypting the database with the raw key form"
    );

    let Some(exclusive) = super::maintenance::Exclusive::try_acquire(Path::new(db_path))? else {
        // An idle extension handle is sufficient to defer migration. A SQLite
        // transaction lock alone cannot protect that process's cached key.
        return Ok(KeyForm::Passphrase);
    };

    if let Err(error) = rekey::run(db_path, key, exclusive).await {
        // A competing process may have completed the same migration between
        // our probes and exclusive admission. Recheck after closing our handle.
        if !decrypts_with(db_path, key, KeyForm::Raw).await {
            return Err(error);
        }
    }

    if !decrypts_with(db_path, key, KeyForm::Raw).await {
        // The rekey rolled back. Keep the app usable on the old key and retry
        // on the next start rather than failing to open the database at all.
        tracing::error!("re-encryption did not take effect; staying on the passphrase key");

        return Ok(KeyForm::Passphrase);
    }

    tracing::info!("database re-encrypted with the raw key form");

    Ok(KeyForm::Raw)
}

/// Builds the `PRAGMA key` value for a database, migrating it first if needed.

pub(crate) async fn key_pragma(db_path: &str, key: &str, read_only: bool) -> Result<String> {
    Ok(prepare(db_path, key, read_only).await?.pragma_value(key))
}

#[cfg(test)]

mod tests {

    use super::*;
    use sqlx::Executor;

    #[tokio::test]

    async fn read_only_key_probe_preserves_a_live_encrypted_wal_and_its_committed_rows() {
        let directory = tempfile::tempdir().unwrap();

        let path = directory.path().join("probe.sqlite");

        let path = path.to_str().unwrap();

        let key = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

        let database = crate::database::app::AppDatabase::new(path, Some(key), false)
            .await
            .unwrap();

        database.run_migrations().await.unwrap();

        database.pool.close().await;

        let mut writer = SqliteConnectOptions::from_str(&format!("sqlite://{path}"))
            .unwrap()
            .pragma("key", KeyForm::Raw.pragma_value(key))
            .journal_mode(sqlx::sqlite::SqliteJournalMode::Wal)
            .pragma("wal_autocheckpoint", "0")
            .connect()
            .await
            .unwrap();

        sqlx::query!("INSERT INTO app_metadata(key, value) VALUES ('probe-wal', 'committed')")
            .execute(&mut writer)
            .await
            .unwrap();

        writer.execute("BEGIN IMMEDIATE").await.unwrap();

        assert!(std::fs::metadata(format!("{path}-wal")).unwrap().len() > 32);

        assert_eq!(prepare(path, key, true).await.unwrap(), KeyForm::Raw);

        let mut reader = connect(path, key, KeyForm::Raw, true).await.unwrap();

        assert_eq!(
            sqlx::query_scalar!("SELECT value FROM app_metadata WHERE key = 'probe-wal'")
                .fetch_one(&mut reader)
                .await
                .unwrap(),
            "committed"
        );

        assert_eq!(
            sqlx::query_scalar!(
                r#"SELECT CAST(journal_mode AS TEXT) AS "journal_mode!: String" FROM pragma_journal_mode"#
            )
            .fetch_one(&mut reader)
            .await
            .unwrap()
            .as_str(),
            "wal"
        );

        reader.close().await.unwrap();

        writer.execute("ROLLBACK").await.unwrap();

        writer.close().await.unwrap();
    }
}
