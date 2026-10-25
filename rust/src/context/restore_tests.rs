use super::*;

#[tokio::test]

async fn a_restore_finishing_in_background_closes_new_handles_before_its_owner_drains() {
    use crate::database::lifecycle::{foreground, Operation};
    use std::time::Duration;

    struct Visibility(bool);

    impl Drop for Visibility {
        fn drop(&mut self) {
            foreground::set_active_for_test(self.0);
        }
    }

    let directory = tempfile::tempdir().unwrap();

    let context =
        Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
            .await
            .unwrap();

    ApiRuntime::close(&context).await.unwrap();

    context.app_db.read().await.close().await;

    context.rust_db.read().await.pool.close().await;

    let operation = Operation::new(Duration::from_secs(10));

    operation.scope(context.reopen_databases()).await.unwrap();

    let app = context.app_db.read().await.clone();

    operation
        .scope(async {
            sqlx::query_scalar!("SELECT COUNT(*) FROM contacts")
                .fetch_one(&app.read_pool)
                .await
                .unwrap();
        })
        .await;

    let _visibility = Visibility(foreground::active());

    // Only the background branch matters here; the real transition would also
    // cancel native admissions held by tests running in parallel.
    foreground::set_active_for_test(false);

    context.flutter_claimed.store(true, Ordering::Release);

    context.suspended.store(true, Ordering::Release);

    let admission = crate::database::lifecycle::native_admission(&operation)
        .await
        .unwrap();

    operation
        .scope(context.resume_after_restore(admission))
        .await
        .unwrap();

    assert!(app.pool.is_closed());

    assert!(app.read_pool.is_closed());

    assert!(context.rust_db.read().await.pool.is_closed());

    assert!(context.is_suspended());

    operation.cancel();

    tokio::time::timeout(Duration::from_secs(2), operation.drain())
        .await
        .unwrap();
}

#[tokio::test]

async fn reopening_after_an_abandoned_install_reloads_keys_signal_engine_and_watches() {
    let directory = tempfile::tempdir().unwrap();

    let source = Context::init_for_testing(
        directory.path().join("source-db"),
        directory.path().join("source-data"),
    )
    .await
    .unwrap();

    let destination = Context::init_for_testing(
        directory.path().join("destination-db"),
        directory.path().join("destination-data"),
    )
    .await
    .unwrap();

    {
        let mut keys = source.key_manager.lock().await;

        keys.user_id = Some(42);

        keys.signal_identity = Some(crate::keys::SignalIdentityKey::generate().unwrap());

        keys.store_to_keychain(&source.secure_storage).unwrap();
    }

    let expected = source.key_manager.lock().await.to_bytes().unwrap();

    let old = destination.key_manager.lock().await.to_bytes().unwrap();

    assert_ne!(expected, old);

    let old_app = destination.app_db.read().await.clone();

    let mut watches = old_app.subscribe();

    for context in [&source, &destination] {
        ApiRuntime::close(context).await.unwrap();

        context.app_db.read().await.pool.close().await;

        context.rust_db.read().await.pool.close().await;
    }

    crate::keys::restore::stage(
        &destination.secure_storage,
        KeyManager::from_bytes(&expected).unwrap(),
    )
    .unwrap();

    let id = crate::keys::restore::pending(&destination.secure_storage)
        .unwrap()
        .unwrap()
        .id
        .clone();

    // Model an owned installer completing after its async caller disappears:
    // disk/keychain advance, while the caller never updates cached handles.
    crate::database::restore_install::install(
        &destination.config,
        Path::new(&source.config.database_dir),
        None,
        &destination.secure_storage,
        Some(&id),
    )
    .unwrap();

    assert_eq!(
        destination.key_manager.lock().await.to_bytes().unwrap(),
        old
    );

    for _ in 0..2 {
        destination.reopen_databases().await.unwrap();

        assert_eq!(
            destination.key_manager.lock().await.to_bytes().unwrap(),
            expected
        );

        assert!(destination.signal_engine.lock().await.is_some());

        sqlx::query_scalar!("PRAGMA user_version")
            .fetch_one(&destination.app_db.read().await.pool)
            .await
            .unwrap();

        sqlx::query_scalar!("PRAGMA user_version")
            .fetch_one(&destination.rust_db.read().await.pool)
            .await
            .unwrap();

        destination.app_db.read().await.refresh_watches();

        assert!(watches.try_recv().is_ok());

        destination.app_db.read().await.pool.close().await;

        destination.rust_db.read().await.pool.close().await;
    }
}
