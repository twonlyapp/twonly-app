use super::messages::native::{MessageType, NewMessage};
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
        "INSERT INTO contacts(user_id, username) VALUES (7, 'sender');
         INSERT INTO groups(group_id, group_name, last_message_exchange)
         VALUES ('chat', 'Chat', 100), ('other', 'Other', 200);",
    )
    .execute(&db.pool)
    .await?;

    Ok((temp, db))
}

async fn activity(db: &AppDatabase) -> anyhow::Result<i64> {
    Ok(
        sqlx::query_scalar("SELECT last_message_exchange FROM groups WHERE group_id = 'chat'")
            .fetch_one(&db.pool)
            .await?,
    )
}

#[tokio::test]

async fn every_incoming_and_outgoing_entry_reorders_the_chat_list() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;

    for sender in [Some(7_i64), None] {
        for message_type in ["text", "media", "webxdcApp", "contacts", "futureEntry"] {
            sqlx::query("UPDATE groups SET last_message_exchange = 100 WHERE group_id = 'chat'")
                .execute(&db.pool)
                .await?;

            let mut tx = db.pool.begin().await?;

            let mut changes = db.subscribe();

            NewMessage::builder()
                .group_id("chat")
                .message_id(&format!("{sender:?}-{message_type}"))
                .maybe_sender_id(sender)
                .message_type(MessageType::Other(message_type))
                .created_at(300)
                .build()
                .insert(&mut tx)
                .await?;

            tx.commit().await?;

            let ordered: Vec<String> = sqlx::query_scalar(
                "SELECT group_id FROM groups ORDER BY last_message_exchange DESC",
            )
            .fetch_all(&db.pool)
            .await?;

            assert_eq!(ordered, ["chat", "other"]);

            assert_eq!(activity(&db).await?, 300);

            let changed =
                tokio::time::timeout(std::time::Duration::from_secs(1), changes.recv()).await??;

            assert!(changed.tables.contains("groups"));

            assert!(changed.tables.contains("messages"));
        }
    }

    Ok(())
}

#[tokio::test]

async fn widget_entries_count_but_unsaved_stories_do_not() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;

    for sender in [Some(7_i64), None] {
        sqlx::query(
            "INSERT INTO messages(message_id, group_id, sender_id, type, is_widget_media, \
             created_at) VALUES (?, 'chat', ?, 'media', 1, 300)",
        )
        .bind(format!("widget-{sender:?}"))
        .bind(sender)
        .execute(&db.pool)
        .await?;

        assert_eq!(activity(&db).await?, 300);

        sqlx::query(
            "INSERT INTO messages(message_id, group_id, sender_id, type, is_story, created_at) \
             VALUES (?, 'chat', ?, 'media', 1, 400)",
        )
        .bind(format!("story-{sender:?}"))
        .bind(sender)
        .execute(&db.pool)
        .await?;

        assert_eq!(activity(&db).await?, 300);
    }

    Ok(())
}

#[tokio::test]

async fn older_messages_duplicates_edits_and_expiration_preserve_activity() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;

    sqlx::raw_sql(
        "INSERT INTO messages(message_id, group_id, type, created_at)
         VALUES ('latest', 'chat', 'text', 300), ('old', 'chat', 'text', 150);
         INSERT INTO messages(message_id, group_id, type, created_at)
         VALUES ('latest', 'chat', 'text', 500) ON CONFLICT(message_id) DO NOTHING;
         UPDATE messages SET content = 'Edited', modified_at = 600 WHERE message_id = 'old';
         DELETE FROM messages WHERE group_id = 'chat';",
    )
    .execute(&db.pool)
    .await?;

    assert_eq!(activity(&db).await?, 300);

    Ok(())
}

#[tokio::test]

async fn rolled_back_entry_does_not_reorder_or_notify() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;

    let mut tx = db.pool.begin().await?;

    let mut changes = db.subscribe();

    sqlx::query(
        "INSERT INTO messages(message_id, group_id, type, created_at) VALUES ('failed', 'chat', \
         'text', 300)",
    )
    .execute(&mut *tx)
    .await?;

    tx.rollback().await?;

    assert_eq!(activity(&db).await?, 100);

    assert!(matches!(
        changes.try_recv(),
        Err(tokio::sync::broadcast::error::TryRecvError::Empty)
    ));

    Ok(())
}

#[tokio::test]

async fn migration_repairs_existing_entries_and_clamps_future_timestamps() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;

    sqlx::raw_sql(
        "DROP TRIGGER chat_message_activity;
         INSERT INTO messages(message_id, group_id, type, created_at, is_story)
         VALUES ('announcement', 'chat', 'text', 300, 0),
                ('story', 'chat', 'media', 500, 1);",
    )
    .execute(&db.pool)
    .await?;

    assert_eq!(activity(&db).await?, 100);

    sqlx::raw_sql(include_str!("migrations/0040_chat_message_activity.sql"))
        .execute(&db.pool)
        .await?;

    assert_eq!(activity(&db).await?, 300);

    let now = chrono::Utc::now().timestamp();

    sqlx::query(
        "INSERT INTO messages(message_id, group_id, type, created_at) VALUES ('future', 'chat', \
         'text', ?)",
    )
    .bind(now + 1000000)
    .execute(&db.pool)
    .await?;

    let latest = activity(&db).await?;

    assert!(latest >= now && latest <= chrono::Utc::now().timestamp());

    Ok(())
}
