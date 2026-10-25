//! Host process isolation keeps the real app singleton/keyring away from
//! other unit fixtures. Mobile lifecycle/allowance testing remains on device.
#![cfg(all(unix, not(any(target_os = "ios", target_os = "android"))))]

use rust_lib_twonly::bridge::api::RustApi;
use rust_lib_twonly::bridge::database::contact_groups::{self, ContactGroupInput};
use rust_lib_twonly::bridge::database::mediafiles::{self, MediaFilter, MediaQuery};
use rust_lib_twonly::bridge::database::transactions::DatabaseTransaction;
use rust_lib_twonly::bridge::database::DatabaseSession;
use rust_lib_twonly::bridge::user_config::UserConfigApi;
use rust_lib_twonly::bridge::{initialize_twonly_flutter, InitConfig};
use std::ffi::{c_char, CStr, CString};
use std::os::fd::AsRawFd;
use std::path::Path;
use std::process::Command;
use std::time::Duration;

unsafe extern "C" {

    fn twonly_database_set_foreground(active: bool);

    fn twonly_live_location_run(directory: *const c_char, request: *const c_char) -> *mut c_char;

    fn twonly_notification_string_free(pointer: *mut c_char);

    fn twonly_notification_run_create(budget_ms: u64) -> u64;

    fn twonly_notification_process_with_id(
        run: u64, database_dir: *const c_char, data_dir: *const c_char, locale: *const c_char,
        deadline_ms: u64,
    ) -> *mut c_char;

    fn twonly_notification_run_finish(run: u64);

    fn twonly_notification_acknowledge_with_id(run: u64, event_ids: *const c_char) -> *mut c_char;

}

fn input(name: &str) -> ContactGroupInput {
    ContactGroupInput {
        name: name.into(),
        emoji: None,
        text_color: 0,
        background_color: 0,
        show_as_shortcut: true,
        show_as_label: true,
        share_stories: false,
    }
}

fn locks_free(path: &Path) -> bool {
    Command::new(std::env::current_exe().unwrap())
        .args(["--exact", "foreground_lock_probe", "--ignored"])
        .env("TWONLY_FOREGROUND_LOCK_PROBE", path)
        .output()
        .unwrap()
        .status
        .success()
}

#[test]

fn retained_transactions_are_rolled_back_native_callbacks_run_and_resume_preserves_commits() {
    let directory = tempfile::tempdir().unwrap();

    let database = directory.path().join("database");

    let config = || InitConfig {
        database_dir: database.display().to_string(),
        data_dir: database.display().to_string(),
    };

    let runtime = tokio::runtime::Runtime::new().unwrap();

    runtime.block_on(async {
        unsafe { twonly_database_set_foreground(true) };

        tokio::time::timeout(Duration::from_secs(10), initialize_twonly_flutter(config()))
            .await
            .unwrap()
            .unwrap();

        let session = DatabaseSession::new();

        let committed = contact_groups::create_contact_group(input("committed"), &session)
            .await
            .unwrap();

        let transaction = DatabaseTransaction::begin().await.unwrap();

        let retained = transaction.session();

        let rolled_back = contact_groups::create_contact_group(input("must roll back"), &retained)
            .await
            .unwrap();

        unsafe { twonly_database_set_foreground(false) };

        tokio::time::timeout(Duration::from_secs(5), RustApi::set_background(true))
            .await
            .unwrap()
            .unwrap();

        assert!(transaction.commit().await.is_err());

        assert!(
            contact_groups::create_contact_group(input("stale callback"), &retained)
                .await
                .is_err()
        );

        for file in ["app_db.sqlite", "rust_db.sqlite"] {
            assert!(locks_free(&database.join(file)));
        }

        // Deferred UI reads retain no SQLite checkout during suspension.
        let deferred = tokio::spawn(async move {
            contact_groups::get_contact_group(committed, &DatabaseSession::new()).await
        });

        tokio::task::yield_now().await;

        assert!(!deferred.is_finished());

        // These facade calls used to bypass admission and fail on the closed
        // pool (or borrow a notification worker's replacement pool).
        let avatar = tokio::spawn(RustApi::ensure_avatar_png(7));
        let own_avatar = tokio::spawn(RustApi::current_user_avatar_path());
        let notifications = tokio::spawn(RustApi::clear_conversation_notifications("chat".into()));
        let requests = tokio::spawn(RustApi::clear_contact_request_notifications());
        let badge = tokio::spawn(RustApi::notification_badge_count());

        tokio::task::yield_now().await;

        assert!(!avatar.is_finished());
        assert!(!notifications.is_finished());
        assert!(!badge.is_finished());

        let native_path = CString::new(database.to_str().unwrap()).unwrap();

        let request = CString::new(r#"{"action":"state"}"#).unwrap();

        for _ in 0..2 {
            let native_path = native_path.clone();

            let request = request.clone();

            let json = tokio::task::spawn_blocking(move || {
                let pointer =
                    unsafe { twonly_live_location_run(native_path.as_ptr(), request.as_ptr()) };

                assert!(!pointer.is_null());

                let json = unsafe { CStr::from_ptr(pointer) }
                    .to_str()
                    .unwrap()
                    .to_owned();

                unsafe { twonly_notification_string_free(pointer) };

                json
            })
            .await
            .unwrap();

            let result: serde_json::Value = serde_json::from_str(&json).unwrap();

            assert_eq!(result["ok"], true, "{json}");

            for file in ["app_db.sqlite", "rust_db.sqlite"] {
                assert!(locks_free(&database.join(file)));
            }
        }

        // Keep a real notification run alive between processing and rendering.
        // Resume must cancel that owner and await its cleanup before adoption.
        let path = native_path.clone();

        let notification = tokio::task::spawn_blocking(move || {
            let run = unsafe { twonly_notification_run_create(30_000) };

            assert_ne!(run, 0);

            let locale = CString::new("en").unwrap();

            let pointer = unsafe {
                twonly_notification_process_with_id(
                    run,
                    path.as_ptr(),
                    path.as_ptr(),
                    locale.as_ptr(),
                    100,
                )
            };

            assert!(!pointer.is_null());

            let json = unsafe { CStr::from_ptr(pointer) }
                .to_str()
                .unwrap()
                .to_owned();

            unsafe { twonly_notification_string_free(pointer) };

            let response: serde_json::Value = serde_json::from_str(&json).unwrap();

            assert_eq!(response["ok"], true, "{json}");

            run
        })
        .await
        .unwrap();

        // Dart may report the same pause after native onStop has already
        // handed ownership to a push. It must not cancel the new worker.
        RustApi::set_background(true).await.unwrap();
        tokio::task::spawn_blocking(move || {
            let ids = CString::new("[]").unwrap();
            let pointer =
                unsafe { twonly_notification_acknowledge_with_id(notification, ids.as_ptr()) };
            let json = unsafe { CStr::from_ptr(pointer) }
                .to_str()
                .unwrap()
                .to_owned();
            unsafe { twonly_notification_string_free(pointer) };
            let response: serde_json::Value = serde_json::from_str(&json).unwrap();
            assert_eq!(
                response["ok"], true,
                "late Dart pause cancelled the push: {json}"
            );
        })
        .await
        .unwrap();

        unsafe { twonly_database_set_foreground(true) };

        tokio::time::timeout(Duration::from_secs(5), RustApi::set_background(false))
            .await
            .unwrap()
            .unwrap();

        // A late platform finish cannot close the newly adopted pools.
        tokio::task::spawn_blocking(move || unsafe {
            twonly_notification_run_finish(notification)
        })
        .await
        .unwrap();

        // A queued Dart pause cannot reverse the newer native resume event.
        RustApi::set_background(true).await.unwrap();

        tokio::time::timeout(Duration::from_secs(5), async {
            assert!(avatar.await.unwrap().unwrap().is_none());
            own_avatar.await.unwrap().unwrap();
            assert!(notifications.await.unwrap().unwrap().is_empty());
            assert!(requests.await.unwrap().unwrap().is_empty());
            assert_eq!(badge.await.unwrap().unwrap(), 0);
        })
        .await
        .unwrap();

        assert_eq!(
            tokio::time::timeout(Duration::from_secs(5), deferred)
                .await
                .unwrap()
                .unwrap()
                .unwrap()
                .unwrap()
                .name,
            "committed"
        );

        assert!(contact_groups::get_contact_group(rolled_back, &session)
            .await
            .unwrap()
            .is_none());

        assert!(transaction.begin_nested().await.is_err());

        let next = contact_groups::create_contact_group(input("after resume"), &session)
            .await
            .unwrap();

        assert!(contact_groups::get_contact_group(next, &session)
            .await
            .unwrap()
            .is_some());

        // Repeated and fast callbacks must converge without reviving the old
        // transaction or closing the replacement foreground pools.
        unsafe {
            twonly_database_set_foreground(false);

            twonly_database_set_foreground(true);

            twonly_database_set_foreground(true);
        }

        tokio::time::timeout(Duration::from_secs(5), RustApi::set_background(false))
            .await
            .unwrap()
            .unwrap();

        assert!(contact_groups::get_contact_group(committed, &session)
            .await
            .unwrap()
            .is_some());

        unsafe { twonly_database_set_foreground(false) };

        tokio::time::timeout(Duration::from_secs(5), RustApi::set_background(true))
            .await
            .unwrap()
            .unwrap();

        for file in ["app_db.sqlite", "rust_db.sqlite"] {
            assert!(locks_free(&database.join(file)));
        }

        // A share intent may reach HomeView after native suspension. Its
        // initializer must wait, then create exactly one usable media row.
        unsafe { twonly_database_set_foreground(true) };
        RustApi::set_background(false).await.unwrap();
        let config = UserConfigApi::create(7, "test".into(), "Test".into(), None, 193)
            .await
            .unwrap();
        UserConfigApi::save(config).await.unwrap();

        unsafe { twonly_database_set_foreground(false) };
        RustApi::set_background(true).await.unwrap();
        let media = tokio::spawn(RustApi::initialize_media_upload(
            "image".into(),
            Some(12),
            true,
        ));
        tokio::time::sleep(Duration::from_millis(20)).await;
        assert!(!media.is_finished());

        unsafe { twonly_database_set_foreground(true) };
        RustApi::set_background(false).await.unwrap();
        let media_id = tokio::time::timeout(Duration::from_secs(5), media)
            .await
            .unwrap()
            .unwrap()
            .unwrap();
        let row = mediafiles::get_media_file(media_id.clone(), &DatabaseSession::new())
            .await
            .unwrap()
            .unwrap();
        assert_eq!(row.upload_state.as_deref(), Some("initialized"));
        assert_eq!(row.display_limit_in_milliseconds, Some(12_000));
        assert_eq!(row.encryption_key.unwrap().len(), 32);
        assert_eq!(row.encryption_nonce.unwrap().len(), 12);
        assert!(row.is_draft_media);
        let rows = mediafiles::list_media_files(
            MediaQuery {
                filter: MediaFilter::All,
                ids: vec![],
                group_id: None,
                hash: None,
                favorites_only: false,
            },
            &DatabaseSession::new(),
        )
        .await
        .unwrap();
        assert_eq!(rows.len(), 1);
        assert_eq!(rows[0].media_id, media_id);

        unsafe { twonly_database_set_foreground(false) };
        RustApi::set_background(true).await.unwrap();
        for file in ["app_db.sqlite", "rust_db.sqlite"] {
            assert!(locks_free(&database.join(file)));
        }
    });
}

#[test]
#[ignore = "test-only subprocess lock probe"]

fn foreground_lock_probe() {
    let path = std::env::var_os("TWONLY_FOREGROUND_LOCK_PROBE").unwrap();

    let file = std::fs::OpenOptions::new()
        .read(true)
        .write(true)
        .open(path)
        .unwrap();

    let mut lock: libc::flock = unsafe { std::mem::zeroed() };

    lock.l_type = libc::F_WRLCK as _;

    lock.l_whence = libc::SEEK_SET as _;

    lock.l_start = 0x4000_0000;

    lock.l_len = 512;

    assert_eq!(
        unsafe { libc::fcntl(file.as_raw_fd(), libc::F_SETLK, &lock) },
        0
    );
}
