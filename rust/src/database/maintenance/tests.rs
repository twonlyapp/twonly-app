use super::*;
use crate::database::app::AppDatabase;
use std::ffi::CString;
use std::io::{BufRead, Write};
use std::process::{Command, Stdio};
use std::time::Duration;

#[tokio::test]

async fn settings_locks_participate_in_drain_and_cancelled_owners_cannot_acquire_them() {
    let directory = tempfile::tempdir().unwrap();

    let operation = crate::database::lifecycle::Operation::foreground();

    let access = operation
        .scope(async { settings_access(directory.path()).unwrap() })
        .await;

    operation.cancel();

    assert!(
        tokio::time::timeout(Duration::from_millis(20), operation.drain())
            .await
            .is_err()
    );

    assert!(
        Exclusive::try_acquire(&directory.path().join("app_db.sqlite"))
            .unwrap()
            .is_none()
    );

    drop(access);

    tokio::time::timeout(Duration::from_secs(1), operation.drain())
        .await
        .unwrap();

    assert!(operation
        .scope(async { settings_access(directory.path()) })
        .await
        .is_err());

    assert!(
        Exclusive::try_acquire(&directory.path().join("app_db.sqlite"))
            .unwrap()
            .is_some()
    );
}

#[tokio::test]

async fn reopening_rechecks_key_form_after_another_owner_migrates_the_closed_file() {
    use sqlx::{ConnectOptions, Connection};

    let directory = tempfile::tempdir().unwrap();

    let path = directory.path().join("key.sqlite");

    let key = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

    initialize().unwrap();

    let original = sqlx::sqlite::SqliteConnectOptions::new()
        .filename(&path)
        .create_if_missing(true)
        .pragma("key", format!("'{key}'"));

    let mut connection = original.connect().await.unwrap();

    // Materialize an encrypted file without adding fixture SQL.
    sqlx::query!("PRAGMA user_version = 42")
        .execute(&mut connection)
        .await
        .unwrap();

    connection.close().await.unwrap();

    let old = AppDatabase::new(path.to_str().unwrap(), Some(key), true)
        .await
        .unwrap();

    // Migration must defer while the other owner's idle connection is alive;
    // both handles remain usable with the passphrase-derived key meanwhile.
    let deferred = AppDatabase::new(path.to_str().unwrap(), Some(key), false)
        .await
        .unwrap();

    assert_eq!(
        sqlx::query_scalar!("PRAGMA user_version")
            .fetch_one(&old.pool)
            .await
            .unwrap(),
        Some(42)
    );

    deferred.pool.close().await;

    old.pool.close().await;

    let native_operation = crate::database::lifecycle::Operation::new(Duration::from_secs(5));

    let native = native_operation
        .scope(AppDatabase::new(path.to_str().unwrap(), Some(key), false))
        .await
        .unwrap();

    let mut passphrase_probe = original.connect().await.unwrap();

    assert_eq!(
        sqlx::query_scalar!("PRAGMA user_version")
            .fetch_one(&mut passphrase_probe)
            .await
            .unwrap(),
        Some(42)
    );

    passphrase_probe.close().await.unwrap();

    native.pool.close().await;

    native_operation.drain().await;

    let migrated = AppDatabase::new(path.to_str().unwrap(), Some(key), false)
        .await
        .unwrap();

    migrated.pool.close().await;

    let reopened = old.reopen().await.unwrap();

    assert_eq!(
        sqlx::query_scalar!("PRAGMA user_version")
            .fetch_one(&reopened.pool)
            .await
            .unwrap(),
        Some(42)
    );

    reopened.pool.close().await;
}

#[tokio::test]

async fn idle_handles_and_retained_checkouts_block_maintenance_until_native_close() {
    let directory = tempfile::tempdir().unwrap();

    let path = directory.path().join("app.sqlite");

    let database = AppDatabase::new(path.to_str().unwrap(), None, false)
        .await
        .unwrap();

    database.run_migrations().await.unwrap();

    assert!(Exclusive::try_acquire(&path).unwrap().is_none());

    let checkout = database.pool.acquire().await.unwrap();

    assert!(
        tokio::time::timeout(Duration::from_millis(20), database.pool.close())
            .await
            .is_err()
    );

    assert!(Exclusive::try_acquire(&path).unwrap().is_none());

    checkout.close().await.unwrap();

    database.pool.close().await;

    let exclusive = Exclusive::try_acquire(&path).unwrap().unwrap();

    assert!(tokio::time::timeout(
        Duration::from_secs(1),
        AppDatabase::new(path.to_str().unwrap(), None, false)
    )
    .await
    .unwrap()
    .is_err());

    drop(exclusive);

    let reopened = database.reopen().await.unwrap();

    reopened.pool.close().await;
}

#[tokio::test]

async fn sqlite_close_v2_keeps_maintenance_protection_until_zombie_statements_finalize() {
    initialize().unwrap();

    let directory = tempfile::tempdir().unwrap();

    let path = directory.path().join("zombie.sqlite");

    let filename = CString::new(path.to_str().unwrap()).unwrap();

    let operation = crate::database::lifecycle::Operation::foreground();

    unsafe {
        let mut database = std::ptr::null_mut();

        assert_eq!(
            libsqlite3_sys::sqlite3_open(filename.as_ptr(), &mut database),
            0
        );

        set_owner(database, Some(operation.clone()));

        let mut statement = std::ptr::null_mut();

        assert_eq!(
            libsqlite3_sys::sqlite3_prepare_v2(
                database,
                c"SELECT 1".as_ptr(),
                -1,
                &mut statement,
                std::ptr::null_mut()
            ),
            0
        );

        assert_eq!(sqlite3_close_v2(database), 0);

        assert!(Exclusive::try_acquire(&path).unwrap().is_none());

        operation.cancel();

        assert!(
            tokio::time::timeout(Duration::from_millis(20), operation.drain())
                .await
                .is_err()
        );

        assert_eq!(libsqlite3_sys::sqlite3_finalize(statement), 0);

        assert!(Exclusive::try_acquire(&path).unwrap().is_some());

        tokio::time::timeout(Duration::from_secs(1), operation.drain())
            .await
            .unwrap();
    }
}

#[test]

fn foreign_idle_process_blocks_replacement_and_process_death_releases_the_gate() {
    let directory = tempfile::tempdir().unwrap();

    let path = directory.path().join("foreign.sqlite");

    let mut child = Command::new(std::env::current_exe().unwrap())
        .args([
            "--exact",
            "database::maintenance::tests::maintenance_child",
            "--ignored",
            "--nocapture",
        ])
        .env("TWONLY_MAINTENANCE_CHILD", &path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .unwrap();

    let mut output = std::io::BufReader::new(child.stdout.take().unwrap());

    loop {
        let mut line = String::new();

        assert_ne!(
            output.read_line(&mut line).unwrap(),
            0,
            "child failed before opening SQLite"
        );

        if line.contains("MAINTENANCE_READY") {
            break;
        }
    }

    assert!(Exclusive::try_acquire(&path).unwrap().is_none());

    child.kill().unwrap();

    child.wait().unwrap();

    let exclusive = Exclusive::try_acquire(&path).unwrap().unwrap();

    assert!(Exclusive::try_acquire(&path).unwrap().is_none());

    drop(exclusive);

    assert!(Exclusive::try_acquire(&path).unwrap().is_some());
}

#[test]
#[ignore = "subprocess SQLite holder, invoked by maintenance tests"]
fn maintenance_child() {
    initialize().unwrap();

    let filename = CString::new(std::env::var("TWONLY_MAINTENANCE_CHILD").unwrap()).unwrap();

    unsafe {
        let mut database = std::ptr::null_mut();

        assert_eq!(
            libsqlite3_sys::sqlite3_open(filename.as_ptr(), &mut database),
            0
        );

        println!("MAINTENANCE_READY");

        std::io::stdout().flush().unwrap();

        let mut release = String::new();

        std::io::stdin().read_line(&mut release).unwrap();

        assert_eq!(libsqlite3_sys::sqlite3_close(database), 0);
    }
}
