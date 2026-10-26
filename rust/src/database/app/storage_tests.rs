//! Real SQLCipher file I/O failures, scoped to disposable encrypted fixtures.

mod fault_vfs;

use super::*;
use fault_vfs::{Fault, FaultVfs};
use sqlx::{Connection, SqliteConnection};
use std::path::Path;

const KEY: &str = "00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff";

async fn open(path: &Path, vfs: &FaultVfs) -> AppDatabase {
    crate::database::maintenance::initialize().unwrap();

    let options = SqliteConnectOptions::new()
        .filename(path)
        .create_if_missing(true)
        .vfs(vfs.name())
        .pragma("key", format!("\"x'{KEY}'\""))
        .journal_mode(if cfg!(feature = "sqlite-wal") {
            sqlx::sqlite::SqliteJournalMode::Wal
        } else {
            sqlx::sqlite::SqliteJournalMode::Delete
        })
        .foreign_keys(true)
        .pragma("synchronous", "NORMAL")
        .pragma("mmap_size", "0");

    let (changes, _) = broadcast::channel(256);

    let database = AppDatabase::open(
        options,
        changes,
        super::super::Source::new(path.to_str().unwrap(), Some(KEY), false),
    )
    .await
    .unwrap();

    database.run_migrations().await.unwrap();

    database
}

async fn contents(connection: &mut SqliteConnection) -> Vec<(String, String)> {
    sqlx::query!(
        r#"
            SELECT key, value
            FROM app_metadata
            WHERE key IN ('io-baseline', 'io-payload', 'io-marker')
            ORDER BY key
        "#
    )
    .fetch_all(connection)
    .await
    .unwrap()
    .into_iter()
    .map(|row| (row.key, row.value))
    .collect()
}

async fn integrity(connection: &mut SqliteConnection) {
    assert_eq!(
        sqlx::query_scalar!("PRAGMA integrity_check")
            .fetch_all(&mut *connection)
            .await
            .unwrap(),
        [Some("ok".to_owned())]
    );

    assert!(sqlx::query!("PRAGMA foreign_key_check")
        .fetch_all(&mut *connection)
        .await
        .unwrap()
        .is_empty());

    assert!(sqlx::query!("PRAGMA cipher_integrity_check")
        .fetch_all(connection)
        .await
        .unwrap()
        .is_empty());
}

#[tokio::test]

async fn storage_write_sync_and_full_failures_preserve_acknowledged_data_and_transaction_atomicity()
{
    for kind in [Fault::Write, Fault::Sync, Fault::Full] {
        let positions = if kind == Fault::Sync {
            // Both journal modes sync twice; with WAL these are the WAL sync and
            // the database sync during a NORMAL checkpoint.
            2
        } else {
            12
        };

        for nth in 1..=positions {
            let directory = super::durability_tests::Fixture::new();

            let path = directory.path().join("app.sqlite");

            let vfs = FaultVfs::new();

            let database = open(&path, &vfs).await;

            let mut connection = database.pool.acquire().await.unwrap();

            sqlx::query!(
                "INSERT INTO app_metadata(key, value) VALUES ('io-baseline', 'acknowledged')"
            )
            .execute(&mut *connection)
            .await
            .unwrap();

            let mut tx = connection.begin().await.unwrap();

            vfs.arm(kind, nth);

            let payload = "new-content-".repeat(16384);

            let written = async {
                sqlx::query!(
                    "INSERT INTO app_metadata(key, value) VALUES ('io-payload', ?)",
                    payload
                )
                .execute(&mut *tx)
                .await?;

                sqlx::query!(
                    "INSERT INTO app_metadata(key, value) VALUES ('io-marker', 'same-transaction')"
                )
                .execute(&mut *tx)
                .await?;

                Ok::<_, sqlx::Error>(())
            }
            .await;

            let result = match written {
                Ok(()) => tx.commit().await,
                Err(error) => {
                    let _ = tx.rollback().await;

                    Err(error)
                }
            };

            // NORMAL WAL commits do not fsync individually. Exercise the two
            // real synchronization points at checkpoint time instead, without
            // weakening the data/integrity assertions or silently skipping it.
            let checkpoint_sync = cfg!(feature = "sqlite-wal") && kind == Fault::Sync;
            let result = if checkpoint_sync {
                result.expect("NORMAL commit should precede the injected checkpoint sync fault");
                sqlx::query("PRAGMA wal_checkpoint(TRUNCATE)")
                    .execute(&mut *connection)
                    .await
                    .map(|_| ())
            } else {
                result
            };

            let triggered = vfs.disarm();

            assert_eq!(triggered, Some(kind), "unexercised fault: {kind:?}/{nth}");

            let error = result.expect_err("the injected storage failure must be returned");

            let error = error.as_database_error().expect("native SQLite error");

            let code: i32 = error.code().unwrap().parse().unwrap();

            assert!(
                matches!(
                    code & 255,
                    libsqlite3_sys::SQLITE_IOERR | libsqlite3_sys::SQLITE_FULL
                ),
                "{kind:?}/{nth}: {error}"
            );

            connection.close().await.unwrap();

            database.close().await;

            // A failed commit may have completed before its error. A successful
            // NORMAL commit followed by a checkpoint error must still survive
            // ordinary reopen; this does not simulate OS/power loss.
            let reopened = open(&path, &vfs).await;

            let mut connection = reopened.pool.acquire().await.unwrap();

            let actual = contents(&mut connection).await;

            if checkpoint_sync {
                assert_eq!(
                    actual,
                    vec![
                        ("io-baseline".into(), "acknowledged".into()),
                        ("io-marker".into(), "same-transaction".into()),
                        ("io-payload".into(), payload.clone()),
                    ],
                    "checkpoint failure lost acknowledged data at {nth}"
                );
            }

            assert!(
                actual == vec![("io-baseline".into(), "acknowledged".into())]
                    || actual
                        == vec![
                            ("io-baseline".into(), "acknowledged".into()),
                            ("io-marker".into(), "same-transaction".into()),
                            ("io-payload".into(), payload)
                        ],
                "non-atomic recovery at {kind:?}/{nth}"
            );

            integrity(&mut connection).await;

            drop(connection);

            reopened.close().await;

            vfs.assert_closed();
        }
    }
}

#[tokio::test]

async fn storage_read_failure_returns_an_error_and_reopening_preserves_the_encrypted_contents() {
    let directory = super::durability_tests::Fixture::new();

    let path = directory.path().join("app.sqlite");

    let vfs = FaultVfs::new();

    let database = open(&path, &vfs).await;

    let payload = "cold-page-".repeat(16384);

    sqlx::query!(
        "INSERT INTO app_metadata(key, value) VALUES ('io-payload', ?)",
        payload
    )
    .execute(&database.pool)
    .await
    .unwrap();

    let mut connection = database.pool.acquire().await.unwrap();

    sqlx::query!("PRAGMA shrink_memory")
        .execute(&mut *connection)
        .await
        .unwrap();

    vfs.arm(Fault::Read, 1);

    let result = sqlx::query_scalar!("SELECT value FROM app_metadata WHERE key = 'io-payload'")
        .fetch_one(&mut *connection)
        .await;

    assert_eq!(vfs.disarm(), Some(Fault::Read));

    assert!(result.is_err());

    connection.close().await.unwrap();

    database.close().await;

    let reopened = open(&path, &vfs).await;

    let mut connection = reopened.pool.acquire().await.unwrap();

    assert_eq!(
        contents(&mut connection).await,
        vec![("io-payload".into(), payload)]
    );

    integrity(&mut connection).await;

    drop(connection);

    reopened.close().await;

    vfs.assert_closed();
}
