use super::*;
use crate::database::lifecycle::Operation;
use std::time::Duration;

#[tokio::test]

async fn native_initialization_requires_a_lease_before_touching_the_filesystem() {
    let directory = tempfile::tempdir().unwrap();

    let path = directory.path().join("unowned");

    let result = Context::init_notification(InitConfig {
        database_dir: path.display().to_string(),
        data_dir: path.display().to_string(),
    })
    .await;

    assert!(result
        .unwrap_err()
        .to_string()
        .contains("requires an operation lease"));

    assert!(!path.exists());
}

#[tokio::test]

async fn cleanup_closes_a_partially_reopened_context() {
    let directory = tempfile::tempdir().unwrap();

    let first = Operation::new(Duration::from_secs(5));

    let context = first
        .scope(Context::test_context(
            directory.path().join("database"),
            directory.path().join("data"),
            RuntimeMode::Notification,
        ))
        .await
        .unwrap();

    context.finish_native_databases(&first).await.unwrap();

    let next = Operation::new(Duration::from_secs(5));

    let old_app = context.app_db.read().await.clone();

    let replacement = Arc::new(next.scope(old_app.reopen()).await.unwrap());

    *context.app_db.write().await = replacement.clone();

    // Models Signal reopen failing after app reopen succeeded.
    assert!(context.rust_db.read().await.pool.is_closed());

    tokio::time::timeout(
        Duration::from_secs(2),
        context.finish_native_databases(&next),
    )
    .await
    .unwrap()
    .unwrap();

    assert!(replacement.pool.is_closed());

    next.drain().await;
}

#[tokio::test]

async fn maintenance_defers_when_an_unscoped_notification_runtime_owns_the_pools() {
    let directory = tempfile::tempdir().unwrap();

    let context = Context::test_context(
        directory.path().join("database"),
        directory.path().join("data"),
        RuntimeMode::Notification,
    )
    .await
    .unwrap();

    let maintenance = Operation::new(Duration::from_secs(5));

    let error = maintenance
        .scope(context.prepare_native_databases())
        .await
        .unwrap_err();

    assert!(error.to_string().contains("defer maintenance"));

    maintenance.cancel();

    context.finish_native_databases(&maintenance).await.unwrap();

    maintenance.drain().await;

    let app = context.app_db.read().await.clone();

    let signal = context.rust_db.read().await.clone();

    assert!(!app.pool.is_closed());

    assert!(!signal.pool.is_closed());

    sqlx::query!("INSERT INTO app_metadata(key, value) VALUES ('notification-owner', 'works')")
        .execute(&app.pool)
        .await
        .unwrap();

    tokio::join!(app.pool.close(), signal.pool.close());
}

#[tokio::test]

async fn a_native_run_closes_both_pools_and_the_next_run_reopens_the_encrypted_data() {
    let directory = tempfile::tempdir().unwrap();

    let first = Operation::new(Duration::from_secs(10));

    let context = first
        .scope(Context::test_context(
            directory.path().join("database"),
            directory.path().join("data"),
            RuntimeMode::Notification,
        ))
        .await
        .unwrap();

    let app = context.app_db.read().await.clone();

    let signal = context.rust_db.read().await.clone();

    assert!(context
        .prepare_native_databases()
        .await
        .unwrap_err()
        .to_string()
        .contains("defer notification"));

    first
        .scope(async {
            sqlx::query!(
                "INSERT INTO app_metadata(key, value) VALUES ('native-reopen', 'preserved')"
            )
            .execute(&app.pool)
            .await
            .unwrap();
        })
        .await;

    tokio::time::timeout(
        Duration::from_secs(2),
        context.finish_native_databases(&first),
    )
    .await
    .unwrap()
    .unwrap();

    assert!(app.pool.is_closed());

    assert!(signal.pool.is_closed());

    first.drain().await;

    let second = Operation::new(Duration::from_secs(10));

    second
        .scope(context.prepare_native_databases())
        .await
        .unwrap();

    let replacement = context.app_db.read().await.clone();

    assert!(!replacement.pool.is_closed());

    assert!(!context.rust_db.read().await.pool.is_closed());

    assert!(!Arc::ptr_eq(&app, &replacement));

    let value = second
        .scope(async {
            sqlx::query_scalar!("SELECT value FROM app_metadata WHERE key = 'native-reopen'")
                .fetch_one(&replacement.pool)
                .await
                .unwrap()
        })
        .await;

    assert_eq!(value, "preserved");

    tokio::time::timeout(
        Duration::from_secs(2),
        context.finish_native_databases(&second),
    )
    .await
    .unwrap()
    .unwrap();
}

#[tokio::test]

async fn native_cleanup_does_not_close_pools_claimed_by_flutter() {
    let directory = tempfile::tempdir().unwrap();

    let operation = Operation::new(Duration::from_secs(10));

    let context = operation
        .scope(Context::test_context(
            directory.path().join("database"),
            directory.path().join("data"),
            RuntimeMode::Notification,
        ))
        .await
        .unwrap();

    Context::claim_for_flutter(&context).await.unwrap();

    operation.cancel();

    tokio::time::timeout(
        Duration::from_secs(2),
        context.finish_native_databases(&operation),
    )
    .await
    .unwrap()
    .unwrap();

    tokio::time::timeout(Duration::from_secs(2), operation.drain())
        .await
        .unwrap();

    let app = context.app_db.read().await.clone();

    let signal = context.rust_db.read().await.clone();

    assert!(!app.pool.is_closed());

    assert!(!signal.pool.is_closed());

    sqlx::query!("INSERT INTO app_metadata(key, value) VALUES ('flutter-owner', 'works')")
        .execute(&app.pool)
        .await
        .unwrap();

    ApiRuntime::close(&context).await.unwrap();

    tokio::join!(app.pool.close(), signal.pool.close());

    let late = Operation::new(Duration::from_secs(5));

    assert!(late
        .scope(context.prepare_native_databases())
        .await
        .unwrap_err()
        .to_string()
        .contains("admission is closed"));

    late.drain().await;
}
