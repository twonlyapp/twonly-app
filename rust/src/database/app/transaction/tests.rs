use super::*;
use crate::bridge::database::transaction::CommandTransaction;
use crate::bridge::database::DatabaseSession;
use crate::database::app::AppDatabase;
use tokio::sync::broadcast::error::TryRecvError;

#[tokio::test]

async fn cancellation_rolls_back_retained_scopes_and_never_revives_them_after_reuse() {
    let (_directory, database) = open().await;

    let operation = Operation::foreground();

    let root = operation
        .scope(TransactionScope::begin(&database.pool))
        .await
        .unwrap();

    let child = root.begin_nested().await.unwrap();

    insert(&child, "aborted child").await.unwrap();

    operation.cancel();

    tokio::time::timeout(
        std::time::Duration::from_secs(2),
        abort_for_operation(&operation),
    )
    .await
    .unwrap();

    operation.drain().await;

    assert!(root.commit().await.is_err());

    assert!(child.commit().await.is_err());

    assert!(child.begin_nested().await.is_err());

    assert!(keys(&database).await.is_empty());

    let next = TransactionScope::begin(&database.pool).await.unwrap();

    insert(&next, "next owner").await.unwrap();

    next.commit().await.unwrap();

    assert_eq!(keys(&database).await, ["next owner"]);

    database.pool.close().await;
}

async fn open() -> (tempfile::TempDir, AppDatabase) {
    let directory = tempfile::tempdir().unwrap();

    let database = AppDatabase::new(
        directory
            .path()
            .join("transactions.sqlite")
            .to_str()
            .unwrap(),
        None,
        false,
    )
    .await
    .unwrap();

    database.run_migrations().await.unwrap();

    // Flush the final migration's release hooks before subscribing.
    {
        let _connection = database.pool.acquire().await.unwrap();
    }

    (directory, database)
}

async fn insert(scope: &TransactionScope, value: &str) -> Result<()> {
    let mut guard = scope.lock().await?;

    sqlx::query("INSERT INTO app_metadata(key, value) VALUES (?, 'test')")
        .bind(value)
        .execute(&mut **guard.as_mut().unwrap())
        .await?;

    Ok(())
}

async fn keys(database: &AppDatabase) -> Vec<String> {
    sqlx::query_scalar("SELECT key FROM app_metadata WHERE value = 'test' ORDER BY key")
        .fetch_all(&database.pool)
        .await
        .unwrap()
}

#[tokio::test]
async fn automatic_rollback_preserves_the_command_error_and_releases_the_connection() {
    let (_directory, database) = open().await;

    for borrowed in [false, true] {
        let root = if borrowed {
            Some(Arc::new(
                TransactionScope::begin(&database.pool).await.unwrap(),
            ))
        } else {
            None
        };
        let session = DatabaseSession {
            transaction: root.clone(),
        };
        let mut command = if borrowed {
            CommandTransaction::begin(&session).await.unwrap()
        } else {
            CommandTransaction::Owned(database.pool.begin().await.unwrap())
        };
        sqlx::query("INSERT INTO app_metadata(key, value) VALUES ('duplicate', 'test')")
            .execute(&mut **command.transaction())
            .await
            .unwrap();

        // SQLITE_INTERRUPT during a write can also roll back the transaction
        // inside SQLite. Use a deterministic engine rollback to exercise the
        // same cleanup path without depending on cancellation timing.
        let error = sqlx::query(
            "INSERT OR ROLLBACK INTO app_metadata(key, value) VALUES ('duplicate', 'test')",
        )
        .execute(&mut **command.transaction())
        .await
        .unwrap_err();
        let original = error.to_string();
        let result: Result<()> = command.finish(Err(error.into())).await;
        assert_eq!(result.unwrap_err().to_string(), original);
        if let Some(root) = root {
            assert!(root.commit().await.is_err());
        }
        assert!(keys(&database).await.is_empty());

        let next = TransactionScope::begin(&database.pool).await.unwrap();
        insert(&next, "next owner").await.unwrap();
        next.rollback().await.unwrap();
        assert!(keys(&database).await.is_empty());
    }
    database.close().await;
}

#[tokio::test]

async fn nested_rollback_preserves_outer_and_siblings_and_rejects_stale_scopes() {
    let (_directory, database) = open().await;

    let root = TransactionScope::begin(&database.pool).await.unwrap();

    insert(&root, "outer").await.unwrap();

    let child = root.begin_nested().await.unwrap();

    insert(&child, "child").await.unwrap();

    let grandchild = child.begin_nested().await.unwrap();

    insert(&grandchild, "discard-grandchild").await.unwrap();

    grandchild.rollback().await.unwrap();

    insert(&child, "child-after-rollback").await.unwrap();

    child.commit().await.unwrap();

    assert!(insert(&child, "stale-child").await.is_err());

    assert!(insert(&grandchild, "stale-grandchild").await.is_err());

    let sibling = root.begin_nested().await.unwrap();

    insert(&sibling, "discard-sibling").await.unwrap();

    assert!(child.commit().await.is_err());

    assert!(grandchild.rollback().await.is_err());

    sibling.rollback().await.unwrap();

    insert(&root, "outer-after-rollback").await.unwrap();

    root.commit().await.unwrap();

    assert_eq!(
        keys(&database).await,
        [
            "child",
            "child-after-rollback",
            "outer",
            "outer-after-rollback"
        ]
    );

    assert!(insert(&root, "stale-root").await.is_err());

    assert!(root.commit().await.is_err());
}

#[tokio::test]

async fn committed_child_is_neither_durable_nor_published_before_root_commit() {
    let (_directory, database) = open().await;

    let mut changes = database.subscribe();

    let root = TransactionScope::begin(&database.pool).await.unwrap();

    let child = root.begin_nested().await.unwrap();

    insert(&child, "child").await.unwrap();

    child.commit().await.unwrap();

    assert!(database.pool.try_acquire().is_none());

    assert_eq!(changes.try_recv().unwrap_err(), TryRecvError::Empty);

    root.rollback().await.unwrap();

    assert!(keys(&database).await.is_empty());

    assert_eq!(changes.try_recv().unwrap_err(), TryRecvError::Empty);
}

#[tokio::test]

async fn parent_commands_and_parallel_siblings_cannot_enter_an_active_child() {
    let (_directory, database) = open().await;

    let root = TransactionScope::begin(&database.pool).await.unwrap();

    let child = root.begin_nested().await.unwrap();

    assert!(insert(&root, "wrong-scope").await.is_err());

    assert!(root.begin_nested().await.is_err());

    assert!(root.commit().await.is_err());

    insert(&child, "child").await.unwrap();

    child.rollback().await.unwrap();

    insert(&root, "outer").await.unwrap();

    root.commit().await.unwrap();

    assert_eq!(keys(&database).await, ["outer"]);
}

#[tokio::test]

async fn root_rollback_invalidates_all_descendants_and_releases_the_connection() {
    let (_directory, database) = open().await;

    let root = TransactionScope::begin(&database.pool).await.unwrap();

    let child = root.begin_nested().await.unwrap();

    let grandchild = child.begin_nested().await.unwrap();

    insert(&grandchild, "discard").await.unwrap();

    root.rollback().await.unwrap();

    assert!(insert(&grandchild, "late").await.is_err());

    assert!(child.begin_nested().await.is_err());

    assert!(grandchild.commit().await.is_err());

    assert!(keys(&database).await.is_empty());

    root.rollback().await.unwrap();
}

#[tokio::test]

async fn failed_typed_command_rolls_back_only_its_work_inside_a_nested_scope() {
    let (_directory, database) = open().await;

    let root = TransactionScope::begin(&database.pool).await.unwrap();

    let child = Arc::new(root.begin_nested().await.unwrap());

    insert(&child, "before").await.unwrap();

    let session = DatabaseSession {
        transaction: Some(child.clone()),
    };

    let mut command = CommandTransaction::begin(&session).await.unwrap();

    sqlx::query("INSERT INTO app_metadata(key, value) VALUES ('discard', 'test')")
        .execute(&mut **command.transaction())
        .await
        .unwrap();

    let result: Result<()> = command
        .finish(Err(TwonlyError::Generic("command failed".into())))
        .await;

    assert!(result.is_err());

    insert(&child, "after").await.unwrap();

    child.commit().await.unwrap();

    assert!(CommandTransaction::begin(&session).await.is_err());

    root.commit().await.unwrap();

    assert_eq!(keys(&database).await, ["after", "before"]);
}

#[tokio::test]

async fn abandoning_nested_handles_rolls_back_everything_when_last_owner_drops() {
    let (_directory, database) = open().await;

    let mut changes = database.subscribe();

    {
        let root = TransactionScope::begin(&database.pool).await.unwrap();

        let child = root.begin_nested().await.unwrap();

        insert(&child, "abandoned").await.unwrap();

        drop(child);

        assert!(root.commit().await.is_err());
    }

    assert!(keys(&database).await.is_empty());

    assert_eq!(changes.try_recv().unwrap_err(), TryRecvError::Empty);
}

#[tokio::test]

async fn nested_commit_publishes_only_after_successful_root_commit() {
    let (_directory, database) = open().await;

    let mut changes = database.subscribe();

    let root = TransactionScope::begin(&database.pool).await.unwrap();

    let child = root.begin_nested().await.unwrap();

    insert(&child, "committed").await.unwrap();

    child.commit().await.unwrap();

    assert_eq!(changes.try_recv().unwrap_err(), TryRecvError::Empty);

    root.commit().await.unwrap();

    assert_eq!(keys(&database).await, ["committed"]);

    let change = tokio::time::timeout(std::time::Duration::from_secs(2), changes.recv())
        .await
        .unwrap()
        .unwrap();

    assert!(change.tables.contains("app_metadata"));

    assert_eq!(changes.try_recv().unwrap_err(), TryRecvError::Empty);
}

#[tokio::test]

async fn failed_root_commit_reverts_rows_and_never_publishes_them() {
    let (_directory, database) = open().await;

    let mut changes = database.subscribe();

    let root = TransactionScope::begin(&database.pool).await.unwrap();

    {
        let mut guard = root.lock().await.unwrap();

        let connection = &mut **guard.as_mut().unwrap();

        sqlx::query("PRAGMA defer_foreign_keys = ON")
            .execute(&mut *connection)
            .await
            .unwrap();

        sqlx::query(
            "INSERT INTO contact_group_members(contact_group_id, user_id) VALUES (999, 999)",
        )
        .execute(connection)
        .await
        .unwrap();
    }

    insert(&root, "discard-on-failed-commit").await.unwrap();

    assert!(root.commit().await.is_err());

    root.rollback().await.unwrap();

    assert!(keys(&database).await.is_empty());

    let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM contact_group_members")
        .fetch_one(&database.pool)
        .await
        .unwrap();

    assert_eq!(count, 0);

    assert_eq!(changes.try_recv().unwrap_err(), TryRecvError::Empty);
}

#[tokio::test]

async fn savepoint_cleanup_failure_aborts_the_entire_transaction() {
    let (_directory, database) = open().await;

    let mut changes = database.subscribe();

    let root = Arc::new(TransactionScope::begin(&database.pool).await.unwrap());

    insert(&root, "must-not-commit").await.unwrap();

    let session = DatabaseSession {
        transaction: Some(root.clone()),
    };

    let mut command = CommandTransaction::begin(&session).await.unwrap();

    // Simulate engine/savepoint desynchronization. Production callers cannot
    // send this SQL through the typed command API.
    sqlx::query("RELEASE rust_domain_command")
        .execute(&mut **command.transaction())
        .await
        .unwrap();

    let failed: Result<()> = command
        .finish(Err(TwonlyError::Generic("failure".into())))
        .await;

    assert!(failed.is_err());

    assert!(root.commit().await.is_err());

    assert!(insert(&root, "late").await.is_err());

    assert!(keys(&database).await.is_empty());

    assert_eq!(changes.try_recv().unwrap_err(), TryRecvError::Empty);

    let root = TransactionScope::begin(&database.pool).await.unwrap();

    insert(&root, "also-must-not-commit").await.unwrap();

    let child = root.begin_nested().await.unwrap();

    {
        let mut guard = child.lock().await.unwrap();

        sqlx::query!("RELEASE app_scope")
            .execute(&mut **guard.as_mut().unwrap())
            .await
            .unwrap();
    }

    assert!(child.rollback().await.is_err());

    assert!(root.commit().await.is_err());

    assert!(keys(&database).await.is_empty());

    assert_eq!(changes.try_recv().unwrap_err(), TryRecvError::Empty);
}
