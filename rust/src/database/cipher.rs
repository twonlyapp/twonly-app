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
use sqlx::{AssertSqlSafe, ConnectOptions, Connection, Executor, SqliteConnection};
use std::path::Path;
use std::str::FromStr;
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::Duration;

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
async fn connect(db_path: &str, key: &str, form: KeyForm) -> Result<SqliteConnection> {
    let options = SqliteConnectOptions::from_str(&format!("sqlite://{db_path}"))?
        .create_if_missing(false)
        // Both databases run in DELETE mode. sqlx would otherwise apply its own
        // WAL default here, and journal_mode is persistent — a probe must not
        // leave the file in a different mode than the pool expects.
        .journal_mode(sqlx::sqlite::SqliteJournalMode::Delete)
        .busy_timeout(Duration::from_secs(30))
        .log_statements(tracing::log::LevelFilter::Off)
        .pragma("key", form.pragma_value(key));
    Ok(options.connect().await?)
}

/// Whether `key` in `form` actually decrypts the database. Reading the schema
/// is the cheapest statement that has to touch the (encrypted) first page.
async fn decrypts_with(db_path: &str, key: &str, form: KeyForm) -> bool {
    let Ok(mut connection) = connect(db_path, key, form).await else {
        return false;
    };
    let readable = connection
        .execute(AssertSqlSafe("SELECT count(*) FROM sqlite_master"))
        .await
        .is_ok();
    let _ = connection.close().await;
    readable
}

/// Re-encrypts the database in place with the raw key. SQLCipher performs the
/// rekey inside a transaction, so an interrupted run rolls back to the
/// passphrase key and [`prepare`] simply tries again on the next start.
async fn rekey_to_raw(db_path: &str, key: &str) -> Result<()> {
    let mut connection = connect(db_path, key, KeyForm::Passphrase).await?;
    // `key` is our own hex string, checked by `can_use_raw_key`, so there is
    // nothing here that could carry SQL.
    let statement = format!("PRAGMA rekey = {};", KeyForm::Raw.pragma_value(key));
    let result = connection.execute(AssertSqlSafe(statement)).await;
    let closed = connection.close().await;
    result?;
    closed?;
    Ok(())
}

/// Decides which key form to open `db_path` with, migrating a database still
/// encrypted with the passphrase-derived key when it can be opened read-write.
///
/// Never fails because of a key it cannot place: if neither form decrypts the
/// file, the caller's own connection reports the real error with its own
/// context instead.
pub(crate) async fn prepare(db_path: &str, key: &str, read_only: bool) -> Result<KeyForm> {
    if !can_use_raw_key(key) || !is_file_backed(db_path) {
        return Ok(KeyForm::Passphrase);
    }
    if !has_existing_database(db_path) {
        return Ok(KeyForm::Raw);
    }
    if decrypts_with(db_path, key, KeyForm::Raw).await {
        return Ok(KeyForm::Raw);
    }
    if !decrypts_with(db_path, key, KeyForm::Passphrase).await {
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

    tracing::info!(
        database = %Path::new(db_path)
            .file_name()
            .unwrap_or_default()
            .to_string_lossy(),
        "re-encrypting the database with the raw key form"
    );
    rekey_to_raw(db_path, key).await?;

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
