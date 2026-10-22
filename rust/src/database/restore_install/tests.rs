use super::*;
use crate::database::maintenance;
use std::process::Command;

mod identity;

fn fixture() -> (tempfile::TempDir, InitConfig, PathBuf) {
    let directory = tempfile::tempdir().unwrap();

    let config = InitConfig {
        database_dir: directory.path().join("db").display().to_string(),
        data_dir: directory.path().join("data").display().to_string(),
    };

    let staging = directory.path().join("staging");

    for path in [
        Path::new(&config.database_dir),
        Path::new(&config.data_dir),
        &Path::new(&config.data_dir).join("keyvalue"),
        &staging,
    ] {
        fs::create_dir_all(path).unwrap();
    }

    let roots = Roots::new(&config).unwrap();

    for target in REQUIRED.iter().chain([Target::Discovery].iter()) {
        fs::write(roots.target(*target), format!("old:{}", target.name())).unwrap();
    }

    for target in [Target::App, Target::Signal, Target::Discovery] {
        fs::write(
            staging.join(target.name()),
            format!("new:{}", target.name()),
        )
        .unwrap();
    }

    fs::write(roots.target(Target::User), br#"{"tag":"old","signalLastSignedPreKeyUpdated":"old","signalLastPqcPreKeysUploaded":"old"}"#).unwrap();

    fs::write(staging.join(Target::User.name()), br#"{"tag":"new","signalLastSignedPreKeyUpdated":"new","signalLastPqcPreKeysUploaded":"new"}"#).unwrap();

    (directory, config, staging)
}

fn assert_generation(config: &InitConfig, new: bool) {
    let roots = Roots::new(config).unwrap();

    for target in [Target::App, Target::Signal, Target::Discovery] {
        assert_eq!(
            fs::read_to_string(roots.target(target)).unwrap(),
            format!("{}:{}", if new { "new" } else { "old" }, target.name())
        );
    }

    for target in REQUIRED.iter().filter(|target| !DATABASES.contains(target)) {
        if new {
            assert!(!roots.target(*target).exists());
        } else if !target.shm() || roots.target(*target).exists() {
            assert_eq!(
                fs::read_to_string(roots.target(*target)).unwrap(),
                format!("old:{}", target.name())
            );
        }
    }

    let user: serde_json::Value =
        serde_json::from_reader(File::open(roots.target(Target::User)).unwrap()).unwrap();

    assert_eq!(user["tag"], if new { "new" } else { "old" });

    if new {
        assert!(user["signalLastSignedPreKeyUpdated"].is_null());

        assert!(user["signalLastPqcPreKeysUploaded"].is_null());
    } else {
        assert_eq!(user["signalLastSignedPreKeyUpdated"], "old");
    }

    assert!(!roots.journal().exists());
}

fn trace() -> Vec<String> {
    let (_directory, config, staging) = fixture();

    let mut trace = Vec::new();

    install_with(&config, &staging, None, &mut |point| {
        trace.push(point.to_owned());

        Ok(())
    })
    .unwrap();

    assert_generation(&config, true);

    trace
}

#[test]

fn every_single_installation_error_resolves_to_one_complete_generation() {
    let trace = trace();

    let committed = trace
        .iter()
        .position(|point| point == "commit published")
        .unwrap();

    for failure in 0..trace.len() {
        let (_directory, config, staging) = fixture();

        let mut step = 0;

        let result = install_with(&config, &staging, None, &mut |_| {
            let current = step;

            step += 1;

            if current == failure {
                Err(invalid("injected I/O error"))
            } else {
                Ok(())
            }
        });

        assert_eq!(
            result.is_ok(),
            failure >= committed,
            "step {failure}: {}",
            trace[failure]
        );

        assert_generation(&config, failure >= committed);
    }
}

#[test]

fn process_exit_at_every_installation_boundary_is_recovered_before_access() {
    let trace = trace();

    let committed = trace
        .iter()
        .position(|point| point == "commit published")
        .unwrap();

    for failure in 0..trace.len() {
        let (_directory, config, staging) = fixture();

        let status = Command::new(std::env::current_exe().unwrap())
            .args([
                "--exact",
                "database::restore_install::tests::restore_child",
                "--ignored",
            ])
            .env("TWONLY_RESTORE_DB", &config.database_dir)
            .env("TWONLY_RESTORE_DATA", &config.data_dir)
            .env("TWONLY_RESTORE_STAGE", &staging)
            .env("TWONLY_RESTORE_FAIL", failure.to_string())
            .output()
            .unwrap()
            .status;

        assert_eq!(
            status.code(),
            Some(88),
            "step {failure}: {}",
            trace[failure]
        );

        let roots = Roots::new(&config).unwrap();

        if roots.journal().exists() {
            assert!(maintenance::settings_access(&roots.database).is_err());
        }

        let runtime = tokio::runtime::Runtime::new().unwrap();

        runtime.block_on(recover_before_open(&config)).unwrap();

        // Before publication the volatile SHM files are unchanged; after a
        // journal was published recovery deliberately discards their indices.
        if failure
            >= trace
                .iter()
                .position(|point| point == "pending published")
                .unwrap()
        {
            for target in [Target::AppShm, Target::SignalShm] {
                assert!(!roots.target(target).exists());
            }
        }

        assert_generation(&config, failure >= committed);

        runtime.block_on(recover_before_open(&config)).unwrap();
    }
}

#[test]
#[ignore = "crash helper invoked by the restore recovery matrix"]

fn restore_child() {
    let config = InitConfig {
        database_dir: std::env::var("TWONLY_RESTORE_DB").unwrap(),
        data_dir: std::env::var("TWONLY_RESTORE_DATA").unwrap(),
    };

    if std::env::var_os("TWONLY_RESTORE_WAL").is_some() {
        use sqlx::sqlite::{SqliteConnectOptions, SqliteJournalMode};
        use sqlx::ConnectOptions;

        maintenance::initialize().unwrap();

        let roots = Roots::new(&config).unwrap();

        tokio::runtime::Runtime::new().unwrap().block_on(async {
            let mut connection = SqliteConnectOptions::new()
                .filename(roots.target(Target::App))
                .create_if_missing(true)
                .journal_mode(SqliteJournalMode::Wal)
                .pragma("wal_autocheckpoint", "0")
                .connect()
                .await
                .unwrap();

            sqlx::query!("PRAGMA user_version = 42")
                .execute(&mut connection)
                .await
                .unwrap();

            std::process::exit(89);
        });
    }

    let staging = PathBuf::from(std::env::var("TWONLY_RESTORE_STAGE").unwrap());

    let failure: usize = std::env::var("TWONLY_RESTORE_FAIL")
        .unwrap()
        .parse()
        .unwrap();

    let mut step = 0;

    let mut hook = |_: &str| -> Result<()> {
        let current = step;

        step += 1;

        if current == failure {
            std::process::exit(88);
        }

        Ok(())
    };

    if std::env::var_os("TWONLY_RESTORE_RECOVER").is_some() {
        let roots = Roots::new(&config).unwrap();

        let _admission = roots.admission().unwrap();

        recover_locked(&roots, None, &mut hook).unwrap();
    } else {
        install_with(&config, &staging, None, &mut hook).unwrap();
    }
}

fn crash(config: &InitConfig, staging: &Path, failure: usize, recover: bool) {
    let mut child = Command::new(std::env::current_exe().unwrap());

    child
        .args([
            "--exact",
            "database::restore_install::tests::restore_child",
            "--ignored",
        ])
        .env("TWONLY_RESTORE_DB", &config.database_dir)
        .env("TWONLY_RESTORE_DATA", &config.data_dir)
        .env("TWONLY_RESTORE_STAGE", staging)
        .env("TWONLY_RESTORE_FAIL", failure.to_string());

    if recover {
        child.env("TWONLY_RESTORE_RECOVER", "1");
    }

    let result = child.output().unwrap();

    assert_eq!(
        result.status.code(),
        Some(88),
        "{}",
        String::from_utf8_lossy(&result.stdout)
    );
}

#[test]

fn process_exit_at_every_rollback_boundary_is_idempotently_recovered() {
    let installation = trace()
        .iter()
        .position(|point| point == "target installed")
        .unwrap();

    let (_directory, config, staging) = fixture();

    crash(&config, &staging, installation, false);

    let roots = Roots::new(&config).unwrap();

    let mut points = Vec::new();

    {
        let _admission = roots.admission().unwrap();

        recover_locked(&roots, None, &mut |point| {
            points.push(point.to_owned());

            Ok(())
        })
        .unwrap();
    }

    for point in 0..points.len() {
        let (_directory, config, staging) = fixture();

        crash(&config, &staging, installation, false);

        crash(&config, &staging, point, true);

        let runtime = tokio::runtime::Runtime::new().unwrap();

        runtime.block_on(recover_before_open(&config)).unwrap();

        assert_generation(&config, false);
    }
}

#[tokio::test]

async fn rollback_preserves_committed_wal_only_data_and_refuses_sqlite_before_recovery() {
    use sqlx::{ConnectOptions, Connection};

    let (_directory, config, staging) = fixture();

    let roots = Roots::new(&config).unwrap();

    for target in [
        Target::App,
        Target::AppWal,
        Target::AppShm,
        Target::AppJournal,
    ] {
        fs::remove_file(roots.target(target)).unwrap();
    }

    let result = Command::new(std::env::current_exe().unwrap())
        .args([
            "--exact",
            "database::restore_install::tests::restore_child",
            "--ignored",
        ])
        .env("TWONLY_RESTORE_DB", &config.database_dir)
        .env("TWONLY_RESTORE_DATA", &config.data_dir)
        .env("TWONLY_RESTORE_WAL", "1")
        .output()
        .unwrap();

    assert_eq!(result.status.code(), Some(89));

    assert!(fs::metadata(roots.target(Target::AppWal)).unwrap().len() > 32);

    assert_eq!(
        &fs::read(roots.target(Target::App)).unwrap()[60..64],
        &[0, 0, 0, 0]
    );

    // The candidate is another valid SQLite database, so denial is due to the
    // restore marker rather than a corrupt-file error from a fake fixture.
    fs::remove_file(staging.join(Target::App.name())).unwrap();

    let candidate = super::super::app::AppDatabase::new(
        staging.join(Target::App.name()).to_str().unwrap(),
        None,
        false,
    )
    .await
    .unwrap();

    candidate.run_migrations().await.unwrap();

    candidate.pool.close().await;

    crash(
        &config,
        &staging,
        trace()
            .iter()
            .position(|point| point == "target installed")
            .unwrap(),
        false,
    );

    assert!(super::super::app::AppDatabase::new(
        roots.target(Target::App).to_str().unwrap(),
        None,
        false
    )
    .await
    .err()
    .unwrap()
    .to_string()
    .contains("maintenance protection unavailable"));

    recover_before_open(&config).await.unwrap();

    let mut restored = sqlx::sqlite::SqliteConnectOptions::new()
        .filename(roots.target(Target::App))
        .read_only(true)
        .connect()
        .await
        .unwrap();

    assert_eq!(
        sqlx::query_scalar!("PRAGMA user_version")
            .fetch_one(&mut restored)
            .await
            .unwrap(),
        Some(42)
    );

    restored.close().await.unwrap();
}

#[tokio::test]

async fn corrupt_metadata_or_missing_originals_refuses_recovery_without_touching_targets() {
    let (_directory, config, staging) = fixture();

    crash(
        &config,
        &staging,
        trace()
            .iter()
            .position(|point| point == "target installed")
            .unwrap(),
        false,
    );

    let roots = Roots::new(&config).unwrap();

    let correct = fs::read(roots.journal()).unwrap();

    let before = fs::read(roots.target(Target::App)).unwrap();

    let mut envelope: Envelope = serde_json::from_slice(&correct).unwrap();

    envelope.journal.entries[0].original = false;

    fs::write(roots.journal(), serde_json::to_vec(&envelope).unwrap()).unwrap();

    assert!(recover_before_open(&config)
        .await
        .unwrap_err()
        .to_string()
        .contains("checksum mismatch"));

    assert_eq!(fs::read(roots.target(Target::App)).unwrap(), before);

    fs::write(roots.journal(), correct).unwrap();

    let journal = read_journal(&roots).unwrap();

    let original = roots.shadow(&journal, Target::Signal, "old");

    let temporary = original.with_extension("hold");

    fs::rename(&original, &temporary).unwrap();

    assert!(recover_before_open(&config)
        .await
        .unwrap_err()
        .to_string()
        .contains("rollback file is missing"));

    assert_eq!(fs::read(roots.target(Target::App)).unwrap(), before);

    assert!(maintenance::settings_access(&roots.database).is_err());

    fs::rename(temporary, original).unwrap();

    recover_before_open(&config).await.unwrap();

    assert_generation(&config, false);
}

#[test]

fn repeated_recovery_failures_keep_the_journal_and_do_not_consume_originals() {
    let (_directory, config, staging) = fixture();

    // Simulate a crash after replacing the first target, without allowing the
    // installer's ordinary error handling to run its recovery path.
    let status = Command::new(std::env::current_exe().unwrap())
        .args([
            "--exact",
            "database::restore_install::tests::restore_child",
            "--ignored",
        ])
        .env("TWONLY_RESTORE_DB", &config.database_dir)
        .env("TWONLY_RESTORE_DATA", &config.data_dir)
        .env("TWONLY_RESTORE_STAGE", &staging)
        .env(
            "TWONLY_RESTORE_FAIL",
            trace()
                .iter()
                .position(|point| point == "target installed")
                .unwrap()
                .to_string(),
        )
        .output()
        .unwrap()
        .status;

    assert_eq!(status.code(), Some(88));

    let roots = Roots::new(&config).unwrap();

    for _ in 0..3 {
        let _admission = roots.admission().unwrap();

        assert!(
            recover_locked(&roots, None, &mut |point| if point == "original restored" {
                Err(invalid("interrupted recovery"))
            } else {
                Ok(())
            })
            .is_err()
        );

        assert!(maintenance::settings_access(&roots.database).is_err());

        assert!(roots.journal().exists());
    }

    let _admission = roots.admission().unwrap();

    recover_locked(&roots, None, &mut |_| Ok(())).unwrap();

    assert_generation(&config, false);
}

#[tokio::test]

async fn abandoned_callers_keep_installation_owned_until_the_committed_set_and_locks_are_settled() {
    let (_directory, config, staging) = fixture();

    let operation = Operation::foreground();

    let (entered, waiting) = tokio::sync::oneshot::channel();

    let (release, allowed) = std::sync::mpsc::channel();

    let configuration = InitConfig {
        database_dir: config.database_dir.clone(),
        data_dir: config.data_dir.clone(),
    };

    let owner = operation.clone();

    let caller = tokio::spawn(async move {
        owner
            .scope(async move {
                super::super::lifecycle::spawn_blocking(move || {
                    let mut entered = Some(entered);

                    install_with(&configuration, &staging, None, &mut |point| {
                        if point == "pending published" {
                            entered.take().unwrap().send(()).unwrap();

                            allowed.recv().unwrap();
                        }

                        Ok(())
                    })
                })
                .await
                .unwrap()
            })
            .await
    });

    waiting.await.unwrap();

    caller.abort();

    assert!(caller.await.is_err());

    operation.cancel();

    assert!(
        tokio::time::timeout(std::time::Duration::from_millis(20), operation.drain())
            .await
            .is_err()
    );

    assert!(maintenance::settings_access(Path::new(&config.database_dir)).is_err());

    release.send(()).unwrap();

    tokio::time::timeout(std::time::Duration::from_secs(5), operation.drain())
        .await
        .unwrap();

    assert_generation(&config, true);

    let _admission = Roots::new(&config).unwrap().admission().unwrap();
}

#[test]

fn cancellation_before_publication_preserves_files_and_a_later_restore_reclaims_crash_shadows() {
    let (_directory, config, staging) = fixture();

    let operation = Operation::foreground();

    assert!(
        install_with(&config, &staging, Some(&operation), &mut |point| {
            if point == "target prepared" {
                operation.cancel();
            }

            Ok(())
        })
        .is_err()
    );

    assert_generation(&config, false);

    crash(&config, &staging, 0, false);

    let roots = Roots::new(&config).unwrap();

    assert!(fs::read_dir(&roots.database).unwrap().any(|entry| entry
        .unwrap()
        .file_name()
        .to_string_lossy()
        .starts_with(".twonly-restore-")));

    install_with(&config, &staging, None, &mut |_| Ok(())).unwrap();

    assert_generation(&config, true);

    for directory in [&roots.database, &roots.data, &roots.data.join("keyvalue")] {
        assert!(!fs::read_dir(directory).unwrap().any(|entry| entry
            .unwrap()
            .file_name()
            .to_string_lossy()
            .starts_with(".twonly-restore-")));
    }
}
