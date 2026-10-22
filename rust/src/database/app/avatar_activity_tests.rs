use super::AppDatabase;

async fn database() -> anyhow::Result<(tempfile::TempDir, AppDatabase)> {
    let temp = tempfile::tempdir()?;

    let db = AppDatabase::new(
        temp.path().join("app.sqlite").to_str().unwrap(),
        None,
        false,
    )
    .await?;

    db.run_migrations().await?;

    sqlx::raw_sql(
        "INSERT INTO contacts(user_id, username) VALUES (1, 'Zebra'), (2, 'Alpha');
      INSERT INTO groups(group_id, group_name) VALUES ('chat', 'Group');
      INSERT INTO group_members(group_id, contact_id) VALUES ('chat', 1), ('chat', 2);",
    )
    .execute(&db.pool)
    .await?;

    Ok((temp, db))
}

async fn activity(db: &AppDatabase, id: i64) -> anyhow::Result<Option<i64>> {
    Ok(sqlx::query_scalar(
        "SELECT last_message FROM group_members WHERE group_id = 'chat' AND contact_id = ?",
    )
    .bind(id)
    .fetch_one(&db.pool)
    .await?)
}

#[tokio::test]

async fn received_messages_update_member_activity_without_regressing() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;

    let mut changes = db.subscribe();

    sqlx::query(
        "INSERT INTO messages(message_id, group_id, sender_id, type, created_at) VALUES ('text', \
         'chat', 1, 'text', 1700000200)",
    )
    .execute(&db.pool)
    .await?;

    assert_eq!(activity(&db, 1).await?, Some(1700000200));

    assert!(changes.recv().await?.tables.contains("group_members"));

    sqlx::raw_sql(
        "INSERT INTO messages(message_id, group_id, sender_id, type, created_at) VALUES
      ('old', 'chat', 1, 'text', 1700000100),
      ('media', 'chat', 2, 'media', 1700000300);",
    )
    .execute(&db.pool)
    .await?;

    assert_eq!(activity(&db, 1).await?, Some(1700000200));

    assert_eq!(activity(&db, 2).await?, Some(1700000300));

    // Expiring messages must not change who last spoke.
    sqlx::query("DELETE FROM messages")
        .execute(&db.pool)
        .await?;

    assert_eq!(activity(&db, 2).await?, Some(1700000300));

    Ok(())
}

#[tokio::test]

async fn stories_widgets_and_own_messages_do_not_reorder_group_avatars() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;

    sqlx::raw_sql(
        "INSERT INTO messages(message_id, group_id, sender_id, type, created_at, is_story, \
         is_widget_media) VALUES
      ('story', 'chat', 1, 'media', 1700000400, 1, 0),
      ('widget', 'chat', 2, 'media', 1700000500, 0, 1),
      ('own', 'chat', NULL, 'text', 1700000600, 0, 0);",
    )
    .execute(&db.pool)
    .await?;

    assert_eq!(activity(&db, 1).await?, None);

    assert_eq!(activity(&db, 2).await?, None);

    Ok(())
}

#[tokio::test]

async fn migration_repairs_existing_activity_and_clamps_future_timestamps() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;

    sqlx::raw_sql(
        "DROP TRIGGER group_member_message_activity;
      INSERT INTO messages(message_id, group_id, sender_id, type, created_at) VALUES ('historic', \
         'chat', 1, 'text', 1700000200);",
    )
    .execute(&db.pool)
    .await?;

    assert_eq!(activity(&db, 1).await?, None);

    sqlx::raw_sql(include_str!("migrations/0034_group_avatar_activity.sql"))
        .execute(&db.pool)
        .await?;

    assert_eq!(activity(&db, 1).await?, Some(1700000200));

    let now = chrono::Utc::now().timestamp();

    sqlx::query(
        "INSERT INTO messages(message_id, group_id, sender_id, type, created_at) VALUES \
         ('future', 'chat', 2, 'text', ?)",
    )
    .bind(now + 1000000)
    .execute(&db.pool)
    .await?;

    let latest = activity(&db, 2).await?.unwrap();

    assert!(latest >= now && latest <= chrono::Utc::now().timestamp());

    Ok(())
}
