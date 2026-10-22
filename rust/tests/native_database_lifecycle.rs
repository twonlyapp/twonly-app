//! Exercise the actual synchronous native ABI in its own process/context.
//! The subprocess probe checks SQLite's OS lock region without needing keys.
#![cfg(all(unix, not(any(target_os = "ios", target_os = "android"))))]

use rust_lib_twonly::database::app::{AppDatabase, APP_DATABASE_FILE};
use std::ffi::{c_char, CStr, CString};
use std::os::fd::AsRawFd;
use std::path::Path;
use std::process::Command;

unsafe extern "C" {

    fn twonly_live_location_run(directory: *const c_char, request: *const c_char) -> *mut c_char;

    fn twonly_notification_string_free(pointer: *mut c_char);

}

fn probe(path: &Path) -> bool {
    Command::new(std::env::current_exe().unwrap())
        .args([
            "--exact",
            "sqlite_file_lock_probe",
            "--ignored",
            "--nocapture",
        ])
        .env("TWONLY_SQLITE_LOCK_PROBE", path)
        .output()
        .unwrap()
        .status
        .success()
}

#[test]

fn native_callbacks_release_cross_process_locks_and_reopen_both_encrypted_databases() {
    let directory = tempfile::tempdir().unwrap();

    let runtime = tokio::runtime::Runtime::new().unwrap();

    // Positive control: the probe must reject a real SQLite lock, then succeed
    // when that owner closes. A passing child by itself is not enough evidence.
    let control = directory.path().join("control.sqlite");

    runtime.block_on(async {
        let database = AppDatabase::new(control.to_str().unwrap(), None, false)
            .await
            .unwrap();

        database.run_migrations().await.unwrap();

        let transaction = database.pool.begin_with("BEGIN EXCLUSIVE").await.unwrap();

        assert!(!probe(&control));

        transaction.rollback().await.unwrap();

        let mut reader = database.pool.begin().await.unwrap();

        sqlx::query_scalar!(r#"SELECT COUNT(*) AS "count!: i64" FROM sqlite_master"#)
            .fetch_one(&mut *reader)
            .await
            .unwrap();

        assert!(
            !probe(&control),
            "the probe must also detect a retained read lock"
        );

        reader.rollback().await.unwrap();

        database.pool.close().await;

        assert!(probe(&control));
    });

    let native = directory.path().join("native");

    let path = CString::new(native.to_str().unwrap()).unwrap();

    let request = CString::new(r#"{"action":"state"}"#).unwrap();

    for _ in 0..3 {
        // No account or network is required for an empty live-location state.
        let pointer = unsafe { twonly_live_location_run(path.as_ptr(), request.as_ptr()) };

        assert!(!pointer.is_null());

        let json = unsafe { CStr::from_ptr(pointer) }
            .to_str()
            .unwrap()
            .to_owned();

        unsafe { twonly_notification_string_free(pointer) };

        let response: serde_json::Value = serde_json::from_str(&json).unwrap();

        assert_eq!(response["ok"], true, "{json}");

        assert!(response["session"].is_null());

        for filename in [APP_DATABASE_FILE, "rust_db.sqlite"] {
            let database = native.join(filename);

            let bytes = std::fs::read(&database).unwrap();

            assert!(bytes.len() > 16);

            assert_ne!(&bytes[..16], b"SQLite format 3\0");

            assert!(
                probe(&database),
                "native return left SQLite file locks held"
            );
        }
    }
}

#[test]
#[ignore = "test-only subprocess entry, invoked by the parent lifecycle test"]

fn sqlite_file_lock_probe() {
    let path = std::env::var_os("TWONLY_SQLITE_LOCK_PROBE").unwrap();

    let file = std::fs::OpenOptions::new()
        .read(true)
        .write(true)
        .open(path)
        .unwrap();

    // SQLite's unix VFS locks the pending, reserved and shared bytes in this
    // 512-byte region. A foreign write lock conflicts with readers and writers.
    let mut lock: libc::flock = unsafe { std::mem::zeroed() };

    lock.l_type = libc::F_WRLCK as _;

    lock.l_whence = libc::SEEK_SET as _;

    lock.l_start = 0x4000_0000;

    lock.l_len = 512;

    assert_eq!(
        unsafe { libc::fcntl(file.as_raw_fd(), libc::F_SETLK, &lock) },
        0
    );
    // Process exit releases the probe's lock; no SQLite contents are touched.
}
