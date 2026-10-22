//! Run against the production baseline and the opt-in sqlite-wal configuration.

use rust_lib_twonly::database::app::contact_groups::table::ContactGroupInput;
use rust_lib_twonly::database::app::contact_groups::{queries, writes};
use rust_lib_twonly::database::app::AppDatabase;
use std::io::{BufRead, BufReader, Write};
use std::process::{Command, Stdio};
use std::sync::Arc;

const KEY: &str = "00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff";

async fn open(directory: &std::path::Path) -> AppDatabase {
    let database = AppDatabase::new(
        directory.join("app.sqlite").to_str().unwrap(),
        Some(KEY),
        false,
    )
    .await
    .unwrap();

    database.run_migrations().await.unwrap();

    assert_eq!(
        sqlx::query_scalar::<_, String>("PRAGMA journal_mode")
            .fetch_one(&database.pool)
            .await
            .unwrap(),
        if cfg!(feature = "sqlite-wal") {
            "wal"
        } else {
            "delete"
        }
    );

    assert_eq!(
        sqlx::query_scalar::<_, i64>("PRAGMA synchronous")
            .fetch_one(&database.pool)
            .await
            .unwrap(),
        2
    );

    database
}

fn input(name: String) -> ContactGroupInput {
    ContactGroupInput {
        name,
        emoji: None,
        text_color: 0xff000000,
        background_color: 0,
        show_as_shortcut: true,
        show_as_label: true,
        share_stories: false,
    }
}

#[tokio::test]

async fn acknowledged_concurrent_domain_updates_and_markers_survive_encrypted_reopen() {
    let directory = tempfile::tempdir().unwrap();

    let database = Arc::new(open(directory.path()).await);

    let mut transaction = database.pool.begin().await.unwrap();

    let shared = writes::create(&mut transaction, &input("Shared".into()))
        .await
        .unwrap();

    transaction.commit().await.unwrap();

    let mut workers = Vec::new();

    for worker in 0..4 {
        let database = database.clone();

        workers.push(tokio::spawn(async move {
            let mut acknowledged = Vec::new();

            for sequence in 0..64 {
                let marker = format!("ack/{worker}/{sequence}");

                let mut transaction = database.pool.begin().await.unwrap();

                writes::increment_usage(&mut transaction, shared)
                    .await
                    .unwrap();

                let id = writes::create(&mut transaction, &input(format!("{worker}/{sequence}")))
                    .await
                    .unwrap();

                sqlx::query("INSERT INTO app_metadata(key, value) VALUES (?, ?)")
                    .bind(&marker)
                    .bind(id.to_string())
                    .execute(&mut *transaction)
                    .await
                    .unwrap();

                transaction.commit().await.unwrap();

                // Only record success outside the transaction after commit.
                acknowledged.push((marker, id, format!("{worker}/{sequence}")));

                assert_eq!(
                    queries::get(&mut *database.pool.acquire().await.unwrap(), id)
                        .await
                        .unwrap()
                        .unwrap()
                        .name,
                    format!("{worker}/{sequence}")
                );
            }

            acknowledged
        }));
    }

    let mut acknowledged = Vec::new();

    for worker in workers {
        acknowledged.extend(worker.await.unwrap());
    }

    database.pool.close().await;

    drop(database);

    let reopened = open(directory.path()).await;

    for (marker, id, expected_name) in acknowledged {
        let stored: String = sqlx::query_scalar("SELECT value FROM app_metadata WHERE key = ?")
            .bind(marker)
            .fetch_one(&reopened.pool)
            .await
            .unwrap();

        assert_eq!(stored, id.to_string());

        assert_eq!(
            queries::get(&mut *reopened.pool.acquire().await.unwrap(), id)
                .await
                .unwrap()
                .unwrap()
                .name,
            expected_name
        );
    }

    assert_eq!(
        queries::get(&mut *reopened.pool.acquire().await.unwrap(), shared)
            .await
            .unwrap()
            .unwrap()
            .usage_counter,
        256
    );

    assert_eq!(
        sqlx::query_scalar::<_, String>("PRAGMA integrity_check")
            .fetch_one(&reopened.pool)
            .await
            .unwrap(),
        "ok"
    );

    assert_eq!(
        sqlx::query_scalar::<_, i64>("SELECT count(*) FROM pragma_foreign_key_check")
            .fetch_one(&reopened.pool)
            .await
            .unwrap(),
        0
    );
}

#[test]

fn committed_changes_survive_process_kill_and_uncommitted_changes_roll_back() {
    for commit in [false, true] {
        let directory = tempfile::tempdir().unwrap();

        let runtime = tokio::runtime::Runtime::new().unwrap();

        runtime.block_on(async {
            let database = open(directory.path()).await;

            sqlx::query("INSERT INTO app_metadata(key, value) VALUES ('baseline', 'original')")
                .execute(&database.pool)
                .await
                .unwrap();

            database.pool.close().await;
        });

        let mut child = Command::new(std::env::current_exe().unwrap())
            .args(["--exact", "durability_worker", "--ignored", "--nocapture"])
            .env("TWONLY_DURABILITY_FIXTURE", directory.path())
            .env("TWONLY_DURABILITY_COMMIT", if commit { "1" } else { "0" })
            .stdout(Stdio::piped())
            .stderr(Stdio::inherit())
            .spawn()
            .unwrap();

        let mut ready = false;

        for line in BufReader::new(child.stdout.take().unwrap()).lines() {
            if line.unwrap() == "READY" {
                ready = true;

                break;
            }
        }

        if !ready {
            let _ = child.kill();

            let _ = child.wait();

            panic!("crash worker did not reach its barrier");
        }

        child.kill().unwrap();

        child.wait().unwrap();

        runtime.block_on(async {
            let database = open(directory.path()).await;

            let value: String =
                sqlx::query_scalar("SELECT value FROM app_metadata WHERE key = 'baseline'")
                    .fetch_one(&database.pool)
                    .await
                    .unwrap();

            assert_eq!(value, if commit { "changed" } else { "original" });

            let marker: i64 =
                sqlx::query_scalar("SELECT count(*) FROM app_metadata WHERE key = 'child-marker'")
                    .fetch_one(&database.pool)
                    .await
                    .unwrap();

            assert_eq!(marker, i64::from(commit));

            database.pool.close().await;
        });
    }
}

#[test]
#[ignore = "test-only subprocess entry; invoked by the parent durability test"]

fn durability_worker() {
    let directory = std::env::var_os("TWONLY_DURABILITY_FIXTURE")
        .expect("worker requires a synthetic fixture directory");

    tokio::runtime::Runtime::new().unwrap().block_on(async {
        let database = open(std::path::Path::new(&directory)).await;

        let mut transaction = database.pool.begin().await.unwrap();

        sqlx::query("UPDATE app_metadata SET value = 'changed' WHERE key = 'baseline'")
            .execute(&mut *transaction)
            .await
            .unwrap();

        sqlx::query("INSERT INTO app_metadata(key, value) VALUES ('child-marker', 'atomic')")
            .execute(&mut *transaction)
            .await
            .unwrap();

        if std::env::var("TWONLY_DURABILITY_COMMIT").unwrap() == "1" {
            transaction.commit().await.unwrap();
        }

        // The parent kills this process without running Rust destructors.
        println!("READY");

        std::io::stdout().flush().unwrap();

        std::future::pending::<()>().await;
    });
}
