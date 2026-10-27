use super::*;

#[tokio::test]

async fn snapshots_freeze_both_stores_and_release_their_writer_reservations() {
    let directory = tempfile::tempdir().unwrap();

    let ctx = Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
        .await
        .unwrap();

    let operation = Operation::new(std::time::Duration::from_secs(10));

    let app = operation
        .scope(writer_pool(&ctx.app_db.read().await.pool, &operation))
        .await
        .unwrap();

    let signal = operation
        .scope(writer_pool(&ctx.rust_db.read().await.pool, &operation))
        .await
        .unwrap();

    let foreign_app = writer_pool(&ctx.app_db.read().await.pool, &operation)
        .await
        .unwrap();

    let foreign_signal = writer_pool(&ctx.rust_db.read().await.pool, &operation)
        .await
        .unwrap();

    let output = directory.path().join("snapshot");

    std::fs::create_dir(&output).unwrap();

    operation
        .scope(capture_on(
            &ctx,
            &output,
            &operation,
            &app,
            &signal,
            || async {
                for (pool, is_app) in [(&foreign_app, true), (&foreign_signal, false)] {
                    let mut connection = pool.acquire().await.unwrap();

                    sqlx::query!("PRAGMA busy_timeout = 50")
                        .fetch_optional(&mut *connection)
                        .await
                        .unwrap();

                    let result = if is_app {
                        sqlx::query!("UPDATE app_metadata SET value = value WHERE 0")
                            .execute(&mut *connection)
                            .await
                    } else {
                        sqlx::query!(
                            "UPDATE signal_sessions SET record_bytes = record_bytes WHERE 0"
                        )
                        .execute(&mut *connection)
                        .await
                    };

                    let sqlx::Error::Database(error) = result.unwrap_err() else {
                        panic!("writer should be excluded by SQLite")
                    };

                    assert_eq!(error.code().unwrap().parse::<i32>().unwrap() & 255, 5);
                }

                Ok(())
            },
        ))
        .await
        .unwrap();

    sqlx::query!("UPDATE app_metadata SET value = value WHERE 0")
        .execute(&foreign_app)
        .await
        .unwrap();

    sqlx::query!("UPDATE signal_sessions SET record_bytes = record_bytes WHERE 0")
        .execute(&foreign_signal)
        .await
        .unwrap();

    for path in ["app_db.sqlite", "signal-working.sqlite"] {
        assert!(output.join(path).metadata().unwrap().len() > 0);
    }

    tokio::join!(
        app.close(),
        signal.close(),
        foreign_app.close(),
        foreign_signal.close()
    );

    crate::api::runtime::ApiRuntime::close(&ctx).await.unwrap();

    ctx.app_db.read().await.close().await;

    ctx.rust_db.read().await.pool.close().await;

    operation.cancel();

    operation.drain().await;
}

#[tokio::test]

async fn a_live_writer_waiting_for_the_reservation_does_not_stall_the_snapshot() {
    let directory = tempfile::tempdir().unwrap();

    let ctx = Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
        .await
        .unwrap();

    let operation = Operation::new(std::time::Duration::from_secs(60));

    let app = operation
        .scope(writer_pool(&ctx.app_db.read().await.pool, &operation))
        .await
        .unwrap();

    let signal = operation
        .scope(writer_pool(&ctx.rust_db.read().await.pool, &operation))
        .await
        .unwrap();

    // The app's only write connection, inside a transaction that has not
    // written yet when the capture takes its reservation.
    let mut live = ctx.app_db.read().await.pool.begin().await.unwrap();

    let output = directory.path().join("snapshot");

    std::fs::create_dir(&output).unwrap();

    let (reserved, on_reserved) = tokio::sync::oneshot::channel();

    let capture = operation.scope(capture_on(
        &ctx,
        &output,
        &operation,
        &app,
        &signal,
        || async move {
            reserved.send(()).unwrap();

            Ok(())
        },
    ));

    // Waits in SQLite's busy handler for the reservation, so this connection
    // cannot return to the pool before the capture ends.
    let write = async {
        on_reserved.await.unwrap();

        sqlx::query!("UPDATE app_metadata SET value = value WHERE 0")
            .execute(&mut *live)
            .await
    };

    let (captured, written) = tokio::time::timeout(std::time::Duration::from_secs(10), async {
        tokio::join!(capture, write)
    })
    .await
    .expect("the snapshot waited for the live writer, which waited for the reservation");

    captured.unwrap();

    written.unwrap();

    live.commit().await.unwrap();

    for path in ["app_db.sqlite", "signal-working.sqlite"] {
        assert!(output.join(path).metadata().unwrap().len() > 0);
    }

    tokio::join!(app.close(), signal.close());

    crate::api::runtime::ApiRuntime::close(&ctx).await.unwrap();

    ctx.app_db.read().await.close().await;

    ctx.rust_db.read().await.pool.close().await;

    operation.cancel();

    operation.drain().await;
}

#[tokio::test]

async fn cancelling_capture_releases_lifecycle_before_a_retained_writer_can_rollback() {
    let directory = tempfile::tempdir().unwrap();

    let database = crate::database::app::AppDatabase::new(
        directory.path().join("app.sqlite").to_str().unwrap(),
        None,
        false,
    )
    .await
    .unwrap();

    database.run_migrations().await.unwrap();

    let retained = database.pool.begin().await.unwrap();

    let operation = Operation::new(std::time::Duration::from_secs(10));

    let lifecycle = tokio::sync::Mutex::new(());

    let mut capture = Box::pin(operation.scope(async {
        let _lifecycle = lifecycle.lock().await;

        writer_pool(&database.pool, &operation).await
    }));

    assert!(futures_util::poll!(&mut capture).is_pending());

    assert!(lifecycle.try_lock().is_err());

    operation.cancel();

    let error = tokio::time::timeout(std::time::Duration::from_secs(1), capture)
        .await
        .expect("capture must cancel without waiting for the retained writer")
        .unwrap_err();

    assert!(error.to_string().contains("cancelled"));

    let supervisor = lifecycle
        .try_lock()
        .expect("shutdown must acquire the lifecycle lock");

    retained.rollback().await.unwrap();

    drop(supervisor);

    database.close().await;

    tokio::time::timeout(std::time::Duration::from_secs(1), operation.drain())
        .await
        .unwrap();
}
