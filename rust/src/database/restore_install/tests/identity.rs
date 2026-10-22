use super::*;
use crate::keys::{restore, DatabaseKey, KeyManager};
use sqlx::{ConnectOptions, Connection};
use std::panic::{catch_unwind, AssertUnwindSafe};

fn storage(config: &InitConfig) -> SecureStorage {
    SecureStorage::init().unwrap();

    SecureStorage::new(&uuid::Uuid::new_v4().to_string()).with_database_dir(&config.database_dir)
}

fn stage(storage: &SecureStorage, old: &KeyManager, new: &KeyManager) -> String {
    old.store_to_keychain(storage).unwrap();

    restore::stage(
        storage,
        KeyManager::from_bytes(&new.to_bytes().unwrap()).unwrap(),
    )
    .unwrap();

    assert_eq!(KeyManager::try_from_keychain(storage).unwrap(), *old);

    restore::pending(storage).unwrap().unwrap().id.clone()
}

fn interrupt_install(
    config: &InitConfig, staging: &Path, storage: &SecureStorage, id: &str, point: &str,
) {
    let stopped = catch_unwind(AssertUnwindSafe(|| {
        install_coordinated(config, staging, None, Some(storage), Some(id), &mut |at| {
            if at == point {
                panic!("injected interruption at {at}");
            }

            Ok(())
        })
        .unwrap();
    }));

    assert!(stopped.is_err());
}

async fn cipher_connection(
    path: &Path, keys: &KeyManager, target: Target,
) -> sqlx::SqliteConnection {
    let database = match target {
        Target::App => DatabaseKey::AppDb,
        Target::Signal => DatabaseKey::RustDb,
        _ => unreachable!(),
    };

    let key = zeroize::Zeroizing::new(keys.main_key.get_database_key(database));

    sqlx::sqlite::SqliteConnectOptions::new()
        .filename(path)
        .create_if_missing(!path.exists())
        .pragma(
            "key",
            crate::database::cipher::KeyForm::Raw.pragma_value(&key),
        )
        .connect()
        .await
        .unwrap()
}

#[tokio::test]

async fn every_identity_installation_boundary_recovers_the_keys_that_open_both_databases() {
    maintenance::initialize().unwrap();

    let templates = tempfile::tempdir().unwrap();

    let old = KeyManager::generate().unwrap();

    let new = KeyManager::generate().unwrap();

    for (generation, keys) in [("old", &old), ("new", &new)] {
        for target in DATABASES {
            let path = templates
                .path()
                .join(format!("{generation}-{}", target.name()));

            let mut connection = cipher_connection(&path, keys, *target).await;

            if generation == "old" {
                sqlx::query!("PRAGMA user_version = 42")
                    .execute(&mut connection)
                    .await
                    .unwrap();
            } else {
                sqlx::query!("PRAGMA user_version = 77")
                    .execute(&mut connection)
                    .await
                    .unwrap();
            }

            connection.close().await.unwrap();
        }
    }

    let (_directory, config, staging) = fixture();

    let secure = storage(&config);

    let id = stage(&secure, &old, &new);

    let mut trace = Vec::new();

    install_coordinated(
        &config,
        &staging,
        None,
        Some(&secure),
        Some(&id),
        &mut |at| {
            trace.push(at.to_owned());

            Ok(())
        },
    )
    .unwrap();

    let committed = trace
        .iter()
        .position(|at| at == "commit published")
        .unwrap();

    assert!(trace.iter().any(|at| at == "identity stored"));

    assert!(trace.iter().any(|at| at == "identity acknowledged"));

    for failure in 0..trace.len() {
        let (_directory, config, staging) = fixture();

        let roots = Roots::new(&config).unwrap();

        for target in DATABASES {
            fs::copy(
                templates.path().join(format!("old-{}", target.name())),
                roots.target(*target),
            )
            .unwrap();

            fs::copy(
                templates.path().join(format!("new-{}", target.name())),
                staging.join(target.name()),
            )
            .unwrap();
        }

        for target in REQUIRED.iter().filter(|target| !DATABASES.contains(target)) {
            fs::remove_file(roots.target(*target)).unwrap();
        }

        let secure = storage(&config);

        let id = stage(&secure, &old, &new);

        let mut step = 0;

        let stopped = catch_unwind(AssertUnwindSafe(|| {
            install_coordinated(
                &config,
                &staging,
                None,
                Some(&secure),
                Some(&id),
                &mut |_| {
                    let current = step;

                    step += 1;

                    if current == failure {
                        panic!("injected interruption at {}", trace[failure]);
                    }

                    Ok(())
                },
            )
            .unwrap();
        }));

        assert!(stopped.is_err(), "{}", trace[failure]);

        if roots.journal().exists() {
            // Ordinary identity mutations must not bypass an incomplete restore.
            assert!(old.store_to_keychain(&secure).is_err());
        }

        recover_with_storage(&config, secure.clone()).await.unwrap();

        let active = KeyManager::try_from_keychain(&secure).unwrap();

        let expected = if failure >= committed { &new } else { &old };

        assert_eq!(active, *expected, "{}", trace[failure]);

        for target in DATABASES {
            let mut connection = cipher_connection(&roots.target(*target), &active, *target).await;

            assert_eq!(
                sqlx::query_scalar!("PRAGMA user_version")
                    .fetch_one(&mut connection)
                    .await
                    .unwrap(),
                Some(if failure >= committed { 77 } else { 42 }),
                "{}",
                trace[failure]
            );

            connection.close().await.unwrap();
        }

        assert!(!roots.journal().exists());

        assert_eq!(
            restore::pending(&secure).unwrap().is_none(),
            failure >= committed
        );

        recover_with_storage(&config, secure).await.unwrap();
    }
}

#[tokio::test]

async fn missing_or_superseded_secure_identity_keeps_a_committed_restore_closed() {
    let (_directory, config, staging) = fixture();

    let secure = storage(&config);

    let old = KeyManager::generate().unwrap();

    let new = KeyManager::generate().unwrap();

    let id = stage(&secure, &old, &new);

    interrupt_install(&config, &staging, &secure, &id, "commit published");

    let record = secure
        .read("twonly_pending_restore_identity_v1")
        .unwrap()
        .unwrap();

    restore::discard(&secure).unwrap();

    let roots = Roots::new(&config).unwrap();

    let files = fs::read(roots.target(Target::App)).unwrap();

    assert!(recover_with_storage(&config, secure.clone()).await.is_err());

    assert!(roots.journal().exists());

    assert_eq!(fs::read(roots.target(Target::App)).unwrap(), files);

    assert_eq!(KeyManager::try_from_keychain(&secure).unwrap(), old);

    assert!(maintenance::settings_access(&roots.database).is_err());

    secure
        .write("twonly_pending_restore_identity_v1", &record)
        .unwrap();

    recover_with_storage(&config, secure.clone()).await.unwrap();

    assert_eq!(KeyManager::try_from_keychain(&secure).unwrap(), new);

    assert_generation(&config, true);
}

#[test]

fn superseding_a_staged_identity_aborts_before_replacing_files() {
    let (_directory, config, staging) = fixture();

    let secure = storage(&config);

    let old = KeyManager::generate().unwrap();

    let id = stage(&secure, &old, &KeyManager::generate().unwrap());

    restore::stage(&secure, KeyManager::generate().unwrap()).unwrap();

    assert!(install(&config, &staging, None, &secure, Some(&id)).is_err());

    assert_generation(&config, false);

    assert_eq!(KeyManager::try_from_keychain(&secure).unwrap(), old);
}

#[tokio::test]

async fn interrupted_identity_recovery_is_idempotent_before_and_after_acknowledgement() {
    for point in ["identity stored", "identity acknowledged"] {
        let (_directory, config, staging) = fixture();

        let secure = storage(&config);

        let old = KeyManager::generate().unwrap();

        let new = KeyManager::generate().unwrap();

        let id = stage(&secure, &old, &new);

        interrupt_install(&config, &staging, &secure, &id, "commit published");

        let roots = Roots::new(&config).unwrap();

        let stopped = catch_unwind(AssertUnwindSafe(|| {
            let _admission = roots.admission().unwrap();

            recover_locked(&roots, Some(&secure), &mut |at| {
                if at == point {
                    panic!("injected recovery interruption at {at}");
                }

                Ok(())
            })
            .unwrap();
        }));

        assert!(stopped.is_err());

        assert!(roots.journal().exists());

        assert_eq!(KeyManager::try_from_keychain(&secure).unwrap(), new);

        recover_with_storage(&config, secure.clone()).await.unwrap();

        assert_generation(&config, true);

        let mut updated = KeyManager::try_from_keychain(&secure).unwrap();

        updated.user_id = Some(123);

        updated.store_to_keychain(&secure).unwrap();

        recover_with_storage(&config, secure.clone()).await.unwrap();

        assert_eq!(KeyManager::try_from_keychain(&secure).unwrap(), updated);
    }
}
