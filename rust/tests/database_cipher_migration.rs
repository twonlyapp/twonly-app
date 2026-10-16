//! An installed app has its databases encrypted with the PBKDF2-derived key
//! that older versions used. Opening one read-write now re-encrypts it with the
//! raw key form; everything in it has to survive that untouched.

use rust_lib_twonly::database::app::AppDatabase;
use rust_lib_twonly::database::signal::Database;
use sqlx::sqlite::SqliteConnectOptions;
use sqlx::{ConnectOptions, Connection, Executor, Row};
use std::path::Path;
use std::str::FromStr;
use std::time::Instant;

/// A database key is always `hex::encode` of a 32-byte HKDF output, so it is
/// exactly 64 hex characters. `database::cipher` only uses the raw key form for
/// keys of that shape, so a fixture of the wrong length would silently test the
/// passphrase path instead.
const KEY: &str = "5b1f8c2d3e4a596877a8b9c0d1e2f30415263748596a7b8c9d0e1f2a3b4c5d6e";

/// Writes a database keyed the way every released version keyed it: the hex
/// string handed to `PRAGMA key` as a passphrase.
async fn create_legacy_database(path: &Path) {
    let mut connection = SqliteConnectOptions::from_str(&format!("sqlite://{}", path.display()))
        .unwrap()
        .create_if_missing(true)
        .journal_mode(sqlx::sqlite::SqliteJournalMode::Delete)
        .pragma("key", format!("'{KEY}'"))
        .connect()
        .await
        .unwrap();
    connection
        .execute("CREATE TABLE notes(id INTEGER PRIMARY KEY, body TEXT)")
        .await
        .unwrap();
    connection
        .execute("INSERT INTO notes(id, body) VALUES (1, 'kept'), (2, 'also kept')")
        .await
        .unwrap();
    connection
        .execute("PRAGMA user_version = 42")
        .await
        .unwrap();
    connection.close().await.unwrap();
}

/// True when the file opens with the raw key form and no key derivation.
async fn opens_with_raw_key(path: &Path) -> bool {
    let Ok(mut connection) =
        SqliteConnectOptions::from_str(&format!("sqlite://{}", path.display()))
            .unwrap()
            .create_if_missing(false)
            .journal_mode(sqlx::sqlite::SqliteJournalMode::Delete)
            .pragma("key", format!("\"x'{KEY}'\""))
            .connect()
            .await
    else {
        return false;
    };
    let readable = connection
        .execute("SELECT count(*) FROM sqlite_master")
        .await
        .is_ok();
    let _ = connection.close().await;
    readable
}

#[tokio::test]
async fn legacy_signal_database_is_migrated_and_keeps_its_contents() {
    let dir = tempfile::tempdir().unwrap();
    let path = dir.path().join("rust_db.sqlite");
    create_legacy_database(&path).await;
    assert!(
        !opens_with_raw_key(&path).await,
        "the fixture must start out passphrase-keyed"
    );

    let database = Database::new(&path.display().to_string(), Some(KEY), false)
        .await
        .expect("a legacy database must still open");

    let bodies: Vec<String> = sqlx::query("SELECT body FROM notes ORDER BY id")
        .fetch_all(&database.pool)
        .await
        .unwrap()
        .into_iter()
        .map(|row| row.get::<String, _>("body"))
        .collect();
    assert_eq!(bodies, vec!["kept", "also kept"]);

    let user_version: i64 = sqlx::query("PRAGMA user_version")
        .fetch_one(&database.pool)
        .await
        .unwrap()
        .get(0);
    assert_eq!(user_version, 42, "user_version must survive the rekey");

    // Migrations still apply on top of the re-encrypted file.
    database.run_migrations().await.unwrap();
    database.pool.close().await;

    assert!(
        opens_with_raw_key(&path).await,
        "the database must be re-encrypted with the raw key"
    );
}

#[tokio::test]
async fn legacy_app_database_is_migrated_and_keeps_its_contents() {
    let dir = tempfile::tempdir().unwrap();
    let path = dir.path().join("app_db.sqlite");
    create_legacy_database(&path).await;

    let database = AppDatabase::new(&path.display().to_string(), Some(KEY), false)
        .await
        .expect("a legacy database must still open");
    let count: i64 = sqlx::query("SELECT count(*) FROM notes")
        .fetch_one(&database.pool)
        .await
        .unwrap()
        .get(0);
    assert_eq!(count, 2);
    database.run_migrations().await.unwrap();
    database.pool.close().await;

    assert!(opens_with_raw_key(&path).await);
}

#[tokio::test]
async fn migrating_twice_is_a_no_op() {
    let dir = tempfile::tempdir().unwrap();
    let path = dir.path().join("rust_db.sqlite");
    create_legacy_database(&path).await;

    for _ in 0..3 {
        let database = Database::new(&path.display().to_string(), Some(KEY), false)
            .await
            .unwrap();
        let count: i64 = sqlx::query("SELECT count(*) FROM notes")
            .fetch_one(&database.pool)
            .await
            .unwrap()
            .get(0);
        assert_eq!(count, 2);
        database.pool.close().await;
    }
    assert!(opens_with_raw_key(&path).await);
}

/// A staged backup archive is verified read-only before it replaces anything.
/// It cannot be rewritten at that point, so it has to stay readable as is.
#[tokio::test]
async fn a_legacy_database_opened_read_only_is_not_migrated() {
    let dir = tempfile::tempdir().unwrap();
    let path = dir.path().join("archive.sqlite");
    create_legacy_database(&path).await;

    let database = Database::new(&path.display().to_string(), Some(KEY), true)
        .await
        .expect("a legacy archive must open read-only");
    let count: i64 = sqlx::query("SELECT count(*) FROM notes")
        .fetch_one(&database.pool)
        .await
        .unwrap()
        .get(0);
    assert_eq!(count, 2);
    database.pool.close().await;

    assert!(
        !opens_with_raw_key(&path).await,
        "a read-only open must leave the archive's encryption alone"
    );

    // Opening the same file for writing later does migrate it.
    let database = Database::new(&path.display().to_string(), Some(KEY), false)
        .await
        .unwrap();
    database.pool.close().await;
    assert!(opens_with_raw_key(&path).await);
}

/// A key that is not 32 bytes of hex cannot be a raw key. Those callers have to
/// keep working on the passphrase path.
#[tokio::test]
async fn a_non_hex_key_keeps_working() {
    let dir = tempfile::tempdir().unwrap();
    let path = dir.path().join("passworded.sqlite");
    let database = Database::new(&path.display().to_string(), Some("not-a-hex-key"), false)
        .await
        .unwrap();
    database
        .pool
        .execute("CREATE TABLE t(a); INSERT INTO t VALUES (1)")
        .await
        .unwrap();
    database.pool.close().await;

    let reopened = Database::new(&path.display().to_string(), Some("not-a-hex-key"), false)
        .await
        .unwrap();
    let count: i64 = sqlx::query("SELECT count(*) FROM t")
        .fetch_one(&reopened.pool)
        .await
        .unwrap()
        .get(0);
    assert_eq!(count, 1);
    reopened.pool.close().await;
}

#[tokio::test]
async fn the_wrong_key_still_fails() {
    let dir = tempfile::tempdir().unwrap();
    let path = dir.path().join("rust_db.sqlite");
    create_legacy_database(&path).await;

    let wrong = "0".repeat(64);
    let result = Database::new(&path.display().to_string(), Some(&wrong), false).await;
    let opened_anything = match result {
        Err(_) => false,
        Ok(database) => {
            let readable = sqlx::query("SELECT count(*) FROM notes")
                .fetch_one(&database.pool)
                .await
                .is_ok();
            database.pool.close().await;
            readable
        }
    };
    assert!(!opened_anything, "a wrong key must not read the database");
}

/// The whole point of the change: a fresh database opens without spending a
/// quarter of a second on PBKDF2, and so does every further connection.
#[tokio::test]
async fn opening_a_migrated_database_skips_key_derivation() {
    let dir = tempfile::tempdir().unwrap();
    let path = dir.path().join("rust_db.sqlite");
    create_legacy_database(&path).await;

    let database = Database::new(&path.display().to_string(), Some(KEY), false)
        .await
        .unwrap();
    database.pool.close().await;

    let started = Instant::now();
    let database = Database::new(&path.display().to_string(), Some(KEY), false)
        .await
        .unwrap();
    // Force the pool to grow past its first connection.
    let mut held = Vec::new();
    for _ in 0..8 {
        held.push(database.pool.acquire().await.unwrap());
    }
    let elapsed = started.elapsed();
    drop(held);
    database.pool.close().await;

    // Eight passphrase-keyed connections cost ~350 ms on a desktop and far more
    // on a phone. The bound is loose so a slow CI machine cannot flake it while
    // still failing loudly if key derivation comes back.
    assert!(
        elapsed.as_millis() < 150,
        "opening 8 connections took {elapsed:?}, which suggests key derivation is still running"
    );
}

#[test]
fn the_fixture_key_has_the_shape_of_a_real_database_key() {
    assert_eq!(KEY.len(), 64);
    assert!(KEY.bytes().all(|byte| byte.is_ascii_hexdigit()));
}
