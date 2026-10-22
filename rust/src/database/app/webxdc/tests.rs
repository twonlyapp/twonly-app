use super::queries;
use crate::database::app::AppDatabase;

#[tokio::test]

async fn card_queries_select_exact_version_and_update_serial_is_scoped() {
    let directory = tempfile::tempdir().unwrap();

    let database = AppDatabase::new(
        directory.path().join("app.sqlite").to_str().unwrap(),
        None,
        false,
    )
    .await
    .unwrap();

    database.run_migrations().await.unwrap();

    let mut tx = database.pool.begin().await.unwrap();

    sqlx::query("INSERT INTO groups(group_id, group_name) VALUES ('g', 'G')")
        .execute(&mut *tx)
        .await
        .unwrap();

    sqlx::query(
        r#"
        INSERT INTO messages(message_id, group_id, type)
        VALUES ('one', 'g', 'webxdcApp'), ('two', 'g', 'webxdcApp')
        "#,
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    sqlx::query(
        r#"
        INSERT INTO webxdc_apps(app_id, version, name, name_translations, icon, bundle_sha256, bundle_bytes, cached_at)
        VALUES ('game', 1, 'Old', '{"de":"Spiel"}', X'01FF', 'old', 10, 0),
            ('game', 2, 'New', '{}', NULL, 'new', 20, 0)
        "#,
    ).execute(&mut *tx).await.unwrap();

    sqlx::query(
        r#"
        INSERT INTO webxdc_instances(instance_id, group_id, app_id, version, origin_token, summary)
        VALUES ('one', 'g', 'game', 1, 'one', 'hello'), ('two', 'g', 'game', 2, 'two', NULL)
        "#,
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    sqlx::query(
        r#"
        INSERT INTO webxdc_updates(instance_id, serial, message_id, payload)
        VALUES ('one', 1, 'u1', '{}'), ('two', 9, 'u2', '{}')
        "#,
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    let app = queries::app(&mut tx, "game", 1).await.unwrap().unwrap();

    assert_eq!(app.name, "Old");

    assert_eq!(app.icon, Some(vec![1, 255]));

    assert!(queries::app(&mut tx, "game", 3).await.unwrap().is_none());

    assert_eq!(
        queries::instance(&mut tx, "one")
            .await
            .unwrap()
            .unwrap()
            .summary
            .as_deref(),
        Some("hello")
    );

    assert!(queries::instance(&mut tx, "missing")
        .await
        .unwrap()
        .is_none());

    assert_eq!(queries::serial(&mut tx, "one").await.unwrap(), 1);

    assert_eq!(queries::serial(&mut tx, "two").await.unwrap(), 9);

    assert_eq!(queries::serial(&mut tx, "missing").await.unwrap(), 0);
}
