//! A seeded independent content oracle over actual encrypted domain writes.
//! The long cases are explicit release checks; the small oracle case runs in
//! CI.

mod model;

use super::*;
use model::{Model, State};
use rand::rngs::StdRng;
use rand::{Rng, SeedableRng};
use serde_json::json;
use sqlx::sqlite::SqlitePoolOptions;
use sqlx::SqliteConnection;
use std::io::Write;
use std::sync::Arc;
use std::time::Instant;
use tokio_util::sync::CancellationToken;

const KEY: &str = "00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff";

const SEED: u64 = 0x7477_6f6e_6c79_2026;

const BATCH: usize = 16;

struct Checkpoint {
    busy: bool,
    log: i32,
    checkpointed: i32,
}

async fn checkpoint(connection: &mut SqliteConnection, mode: i32) -> Checkpoint {
    let mut handle = connection.lock_handle().await.unwrap();

    let (mut log, mut checkpointed) = (-1, -1);

    // The native API exposes exactly the PRAGMA checkpoint result without
    // SQLx's NULL type inference for PRAGMAs on the preparation database.
    // lock_handle excludes SQLx worker access throughout the native call.
    let result = unsafe {
        libsqlite3_sys::sqlite3_wal_checkpoint_v2(
            handle.as_raw_handle().as_ptr(),
            c"main".as_ptr(),
            mode,
            &mut log,
            &mut checkpointed,
        )
    };

    assert!(
        matches!(
            result,
            libsqlite3_sys::SQLITE_OK | libsqlite3_sys::SQLITE_BUSY
        ),
        "checkpoint returned {result}"
    );

    assert!(checkpointed <= log);

    Checkpoint {
        busy: result == libsqlite3_sys::SQLITE_BUSY,
        log,
        checkpointed,
    }
}

pub(super) struct Fixture(Option<tempfile::TempDir>);

impl Fixture {
    pub(super) fn new() -> Self {
        let directory = if let Some(root) = std::env::var_os("TWONLY_DB_SOAK_REPORT_DIR") {
            std::fs::create_dir_all(&root).unwrap();

            tempfile::tempdir_in(root).unwrap()
        } else {
            tempfile::tempdir().unwrap()
        };

        Self(Some(directory))
    }

    pub(super) fn path(&self) -> &Path {
        self.0.as_ref().unwrap().path()
    }
}

impl Drop for Fixture {
    fn drop(&mut self) {
        if let Some(directory) = self.0.take() {
            if std::thread::panicking() {
                eprintln!(
                    "Failing synthetic database retained at {}",
                    directory.keep().display()
                );
            }
        }
    }
}

async fn read_state(connection: &mut SqliteConnection) -> (u64, State) {
    // The first read pins the transaction. Every table and the expected digest
    // must represent that same revision, including with concurrent writers.
    let marker = sqlx::query_scalar!("SELECT value FROM app_metadata WHERE key = 'soak-oracle'")
        .fetch_one(&mut *connection)
        .await
        .unwrap();

    let marker: (u64, String) = serde_json::from_str(&marker).unwrap();

    let state = State::read(connection).await;

    assert_eq!(
        state.digest(),
        marker.1,
        "snapshot/revision mismatch at revision {}",
        marker.0
    );

    (marker.0, state)
}

async fn store_oracle(tx: &mut sqlx::Transaction<'_, sqlx::Sqlite>, revision: u64, model: &Model) {
    let value = serde_json::to_string(&(revision, model.state().digest())).unwrap();

    sqlx::query!(
        r#"
            INSERT INTO app_metadata(key, value) VALUES ('soak-oracle', ?)
            ON CONFLICT(key) DO UPDATE SET value = excluded.value
        "#,
        value
    )
    .execute(&mut **tx)
    .await
    .unwrap();
}

async fn open(path: &Path) -> AppDatabase {
    let database = AppDatabase::new(path.to_str().unwrap(), Some(KEY), false)
        .await
        .unwrap();

    database.run_migrations().await.unwrap();

    database
}

use std::path::Path;

async fn verify(database: &AppDatabase, model: &Model, revision: u64) {
    let mut tx = database.pool.begin().await.unwrap();

    let (actual_revision, actual) = read_state(&mut tx).await;

    assert_eq!(actual_revision, revision);

    assert_eq!(
        actual,
        model.state(),
        "acknowledged content lost at revision {revision}"
    );

    // Check production projections separately from the bulk content oracle.
    let groups = contact_groups::queries::list(
        &mut tx,
        contact_groups::table::ContactGroupFilter::All,
        None,
        None,
    )
    .await
    .unwrap();

    assert_eq!(groups.len(), actual.groups.len());

    for expected in &actual.messages {
        let message = messages::queries::get(&mut tx, &expected.id)
            .await
            .unwrap()
            .unwrap();

        assert_eq!(message.content, expected.content);

        assert_eq!(message.additional_message_data, expected.payload);

        assert_eq!(message.ack_by_server, expected.ack);
    }

    tx.commit().await.unwrap();
}

async fn integrity(database: &AppDatabase) {
    assert_eq!(
        sqlx::query_scalar!("PRAGMA integrity_check")
            .fetch_all(&database.pool)
            .await
            .unwrap(),
        [Some("ok".into())]
    );

    assert!(sqlx::query!("PRAGMA foreign_key_check")
        .fetch_all(&database.pool)
        .await
        .unwrap()
        .is_empty());

    assert!(sqlx::query!("PRAGMA cipher_integrity_check")
        .fetch_all(&database.pool)
        .await
        .unwrap()
        .is_empty());
}

async fn run(operations: usize, readers: bool, seed: u64) {
    let mut fixture = Fixture::new();

    let directory = fixture.path().to_owned();

    let path = directory.join("app.sqlite");

    let config = if !cfg!(feature = "sqlite-wal") {
        "delete"
    } else if readers {
        "wal-readers"
    } else {
        "wal-single"
    };

    let configuration = json!({"configuration": config, "seed": seed, "operations": operations, "batch_size": BATCH});

    std::fs::write(
        directory.join("configuration.json"),
        configuration.to_string(),
    )
    .unwrap();

    let trace_path = directory.join("acknowledgements.jsonl");

    let mut trace = std::fs::File::create(&trace_path).unwrap();

    eprintln!("{configuration}");

    let mut database = Arc::new(open(&path).await);

    let mut setup = database.pool.begin().await.unwrap();

    sqlx::query!("INSERT INTO contacts(user_id, username) VALUES (7, 'seven'), (8, 'eight')")
        .execute(&mut *setup)
        .await
        .unwrap();

    sqlx::query!("INSERT INTO groups(group_id, group_name) VALUES ('soak-chat', 'Soak')")
        .execute(&mut *setup)
        .await
        .unwrap();

    let mut rng = StdRng::seed_from_u64(seed);

    let mut model = Model::default();

    model.change(&mut setup, 0, 0, 0, &mut rng).await;

    store_oracle(&mut setup, 0, &model).await;

    setup.commit().await.unwrap();

    let sentinel = model.state();

    let mut revision = 0;

    let mut rolled_back = 0;

    let started = Instant::now();

    let mut commit_micros = Vec::new();

    let mut reader_checks = 0;

    let mut checkpoints = 0;

    let mut busy_checkpoints = 0;

    let mut max_wal_bytes = 0;

    // Reopen between epochs while the external model and acknowledgements
    // survive independently. Readers and maintenance are fully joined first.
    for epoch_start in (0..operations).step_by(4096) {
        let stop = CancellationToken::new();

        let mut tasks = Vec::new();

        let (watch_sender, mut watch_receiver) = tokio::sync::watch::channel(None);

        let watching = if !cfg!(feature = "sqlite-wal") || readers {
            let databases = Arc::new(tokio::sync::RwLock::new(database.clone()));

            let stop = stop.clone();

            Some(tokio::spawn(async move {
                contact_groups::watches::groups(
                    databases,
                    contact_groups::table::ContactGroupFilter::All,
                    None,
                    None,
                    stop,
                    move |groups| {
                        watch_sender.send_replace(Some(State::groups(groups)));

                        true
                    },
                )
                .await
                .unwrap();
            }))
        } else {
            None
        };

        if readers {
            for _ in 0..2 {
                let pool = database.read_pool.clone();

                let stop = stop.clone();

                tasks.push(tokio::spawn(async move {
                    let mut checks = 0u64;

                    while !stop.is_cancelled() {
                        let mut tx = pool.begin().await.unwrap();

                        read_state(&mut tx).await;

                        // Hold older WAL snapshots periodically while commits
                        // and checkpoint attempts continue on other handles.
                        if checks.is_multiple_of(32) {
                            tokio::time::sleep(Duration::from_millis(10)).await;
                        }

                        tx.commit().await.unwrap();

                        checks += 1;

                        tokio::task::yield_now().await;
                    }

                    checks
                }));
            }
        }

        let checkpoint_task = if cfg!(feature = "sqlite-wal") {
            let own_pool = readers;

            let pool = if own_pool {
                SqlitePoolOptions::new()
                    .max_connections(1)
                    .connect_with(
                        database
                            .pool
                            .connect_options()
                            .as_ref()
                            .clone()
                            .busy_timeout(Duration::from_millis(50)),
                    )
                    .await
                    .unwrap()
            } else {
                database.pool.clone()
            };

            let stop = stop.clone();

            Some(tokio::spawn(async move {
                let (mut completed, mut busy) = (0u64, 0u64);

                while !stop.is_cancelled() {
                    let mut connection = pool.acquire().await.unwrap();

                    let result =
                        checkpoint(&mut connection, libsqlite3_sys::SQLITE_CHECKPOINT_PASSIVE)
                            .await;

                    completed += 1;

                    busy += u64::from(result.busy);

                    drop(connection);

                    tokio::time::sleep(Duration::from_millis(10)).await;
                }

                if own_pool {
                    pool.close().await;
                }

                (completed, busy)
            }))
        } else {
            None
        };

        let end = (epoch_start + 4096).min(operations);

        for first in (epoch_start..end).step_by(BATCH) {
            let mut candidate = model.clone();

            let mut tx = database.pool.begin().await.unwrap();

            for ordinal in first..(first + BATCH).min(end) {
                let slot = rng.random_range(1..33);

                let kind = rng.random_range(0..8);

                candidate
                    .change(&mut tx, slot, kind, ordinal as i64 + 1, &mut rng)
                    .await;
            }

            let rollback = rng.random_ratio(1, 11);

            store_oracle(&mut tx, revision + 1, &candidate).await;

            if rollback {
                tx.rollback().await.unwrap();

                rolled_back += 1;
            } else {
                let commit = Instant::now();

                tx.commit().await.unwrap();

                commit_micros.push(commit.elapsed().as_micros() as u64);

                // This is the acknowledgement boundary. Never advance the
                // external model after failed or deliberately rolled-back work.
                model = candidate;

                revision += 1;
            }

            let event = json!({
                "attempted_through": (first + BATCH).min(end),
                "outcome": if rollback { "rollback" } else { "commit" },
                "acknowledged_revision": revision,
                "digest": model.state().digest(),
            });

            writeln!(trace, "{event}").unwrap();

            if first % 512 == 0 {
                verify(&database, &model, revision).await;
            }

            if let Ok(wal) = path.with_extension("sqlite-wal").metadata() {
                max_wal_bytes = max_wal_bytes.max(wal.len());
            }
        }

        if watching.is_some() {
            tokio::time::timeout(Duration::from_secs(5), async {
                loop {
                    if watch_receiver.borrow_and_update().as_ref() == Some(&model.state().groups) {
                        break;
                    }

                    watch_receiver.changed().await.unwrap();
                }
            })
            .await
            .expect("native watch did not reach the acknowledged state");
        }

        stop.cancel();

        if let Some(task) = watching {
            task.await.unwrap();
        }

        for task in tasks {
            reader_checks += task.await.unwrap();
        }

        if let Some(task) = checkpoint_task {
            let (completed, busy) = task.await.unwrap();

            checkpoints += completed;

            busy_checkpoints += busy;
        }

        verify(&database, &model, revision).await;

        integrity(&database).await;

        trace.sync_data().unwrap();

        eprintln!(
            "{}",
            json!({"configuration": config, "attempted_through": end, "acknowledged_revision": revision})
        );

        if cfg!(feature = "sqlite-wal") {
            let mut connection = database.pool.acquire().await.unwrap();

            let result =
                checkpoint(&mut connection, libsqlite3_sys::SQLITE_CHECKPOINT_TRUNCATE).await;

            assert!(!result.busy);

            assert_eq!(result.log, 0);

            assert_eq!(result.checkpointed, 0);
        }

        database.close().await;

        database = Arc::new(open(&path).await);

        verify(&database, &model, revision).await;
    }

    drop(trace);

    let final_state = model.state();

    assert_eq!(
        final_state
            .groups
            .iter()
            .find(|value| value.id == sentinel.groups[0].id),
        Some(&sentinel.groups[0])
    );

    assert_eq!(
        final_state
            .messages
            .iter()
            .find(|value| value.id == sentinel.messages[0].id),
        Some(&sentinel.messages[0])
    );

    if readers {
        assert!(reader_checks > 0);
    }

    if cfg!(feature = "sqlite-wal") && !readers {
        assert_eq!(database.read_pool.size(), 0);
    }

    if cfg!(feature = "sqlite-wal") {
        assert!(checkpoints > 0);
    }

    commit_micros.sort_unstable();

    let report = json!({
        "configuration": config, "seed": seed, "operations": operations,
        "acknowledged_transactions": revision, "rolled_back_transactions": rolled_back,
        "reader_snapshots": reader_checks, "checkpoints": checkpoints, "busy_checkpoints": busy_checkpoints,
        "max_wal_bytes": max_wal_bytes, "elapsed_ms": started.elapsed().as_millis(),
        "commit_p50_us": commit_micros[commit_micros.len() / 2],
        "commit_p99_us": commit_micros[commit_micros.len() * 99 / 100],
        "sqlite_version": unsafe { std::ffi::CStr::from_ptr(libsqlite3_sys::sqlite3_libversion()).to_str().unwrap() },
        "synchronous": sqlx::query_scalar!("PRAGMA synchronous").fetch_one(&database.pool).await.unwrap(),
        "journal_mode": sqlx::query_scalar!("SELECT CAST((SELECT * FROM pragma_journal_mode) AS TEXT) AS \"mode!: String\"").fetch_one(&database.pool).await.unwrap(),
        "final_digest": model.state().digest(),
    });

    eprintln!("{report}");

    if let Some(destination) = std::env::var_os("TWONLY_DB_SOAK_REPORT_DIR") {
        let destination = Path::new(&destination);

        std::fs::create_dir_all(destination).unwrap();

        std::fs::write(
            destination.join(format!("{config}-{seed}.json")),
            serde_json::to_vec_pretty(&report).unwrap(),
        )
        .unwrap();

        std::fs::copy(
            trace_path,
            destination.join(format!("{config}-{seed}.jsonl")),
        )
        .unwrap();
    }

    database.close().await;

    drop(fixture.0.take());
}

#[tokio::test]

async fn seeded_workload_checks_atomic_snapshots_and_reopen() {
    run(512, cfg!(feature = "sqlite-wal"), SEED).await;
}

#[cfg(feature = "sqlite-wal")]
#[tokio::test]

async fn held_readers_pin_checkpoint_frames_until_their_snapshot_is_released() {
    let directory = tempfile::tempdir().unwrap();

    let database = open(&directory.path().join("app.sqlite")).await;

    let mut tx = database.pool.begin().await.unwrap();

    store_oracle(&mut tx, 0, &Model::default()).await;

    tx.commit().await.unwrap();

    let mut connection = database.pool.acquire().await.unwrap();

    assert!(
        !checkpoint(&mut connection, libsqlite3_sys::SQLITE_CHECKPOINT_TRUNCATE)
            .await
            .busy
    );

    drop(connection);

    let mut reader = database.read_pool.begin().await.unwrap();

    assert_eq!(read_state(&mut reader).await.0, 0);

    let mut writer = database.pool.begin().await.unwrap();

    store_oracle(&mut writer, 1, &Model::default()).await;

    writer.commit().await.unwrap();

    let mut connection = database.pool.acquire().await.unwrap();

    let pinned = checkpoint(&mut connection, libsqlite3_sys::SQLITE_CHECKPOINT_PASSIVE).await;

    assert!(pinned.log > 0);

    assert!(
        pinned.checkpointed < pinned.log,
        "the old reader must pin WAL frames"
    );

    drop(connection);

    assert_eq!(read_state(&mut reader).await.0, 0);

    let mut fresh = database.read_pool.begin().await.unwrap();

    assert_eq!(read_state(&mut fresh).await.0, 1);

    fresh.commit().await.unwrap();

    reader.commit().await.unwrap();

    let mut connection = database.pool.acquire().await.unwrap();

    let released = checkpoint(&mut connection, libsqlite3_sys::SQLITE_CHECKPOINT_TRUNCATE).await;

    assert!(!released.busy);

    assert_eq!((released.log, released.checkpointed), (0, 0));

    drop(connection);

    database.close().await;
}

#[tokio::test]

async fn the_oracle_rejects_missing_related_writes_changed_content_and_early_acknowledgement() {
    let directory = tempfile::tempdir().unwrap();

    let database = open(&directory.path().join("app.sqlite")).await;

    let mut tx = database.pool.begin().await.unwrap();

    sqlx::query!("INSERT INTO contacts(user_id, username) VALUES (7, 'seven'), (8, 'eight')")
        .execute(&mut *tx)
        .await
        .unwrap();

    sqlx::query!("INSERT INTO groups(group_id, group_name) VALUES ('soak-chat', 'Soak')")
        .execute(&mut *tx)
        .await
        .unwrap();

    let mut model = Model::default();

    let mut rng = StdRng::seed_from_u64(SEED);

    model.change(&mut tx, 0, 0, 0, &mut rng).await;

    store_oracle(&mut tx, 0, &model).await;

    tx.commit().await.unwrap();

    let mut tx = database.pool.begin().await.unwrap();

    let original = State::read(&mut tx).await;

    assert_eq!(original, model.state());

    sqlx::query!("DELETE FROM receipts WHERE receipt_id = 'soak-00'")
        .execute(&mut *tx)
        .await
        .unwrap();

    assert_ne!(State::read(&mut tx).await.digest(), model.state().digest());

    tx.rollback().await.unwrap();

    let mut tx = database.pool.begin().await.unwrap();

    sqlx::query!("UPDATE contact_groups SET name = 'wrong content'")
        .execute(&mut *tx)
        .await
        .unwrap();

    assert_ne!(State::read(&mut tx).await.digest(), model.state().digest());

    tx.rollback().await.unwrap();

    let mut early_ack = model.clone();

    let mut tx = database.pool.begin().await.unwrap();

    early_ack.change(&mut tx, 1, 0, 1, &mut rng).await;

    tx.rollback().await.unwrap();

    let mut tx = database.pool.begin().await.unwrap();

    let (_, actual) = read_state(&mut tx).await;

    assert_eq!(actual, original);

    assert_ne!(actual, early_ack.state());

    tx.commit().await.unwrap();

    database.close().await;
}

#[tokio::test]
#[ignore = "release soak: 100,000 seeded domain operations with the writer connection"]

async fn seeded_soak_single_connection() {
    run(100_000, false, SEED).await;
}

#[cfg(feature = "sqlite-wal")]
#[tokio::test]
#[ignore = "release soak: 100,000 seeded domain operations with query-only readers and checkpoint \
            contention"]

async fn seeded_soak_with_readers() {
    run(100_000, true, SEED).await;
}
