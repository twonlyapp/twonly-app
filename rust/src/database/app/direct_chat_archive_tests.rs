use super::tables::{MessageType, NewMessage};
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
         INSERT INTO groups(group_id, group_name, is_direct_chat, archived, deleted_content)
         VALUES ('direct', 'Sender', 1, 1, 1), ('group', 'Group', 0, 1, 1);
         INSERT INTO group_members(group_id, contact_id) VALUES ('direct', 7);",
    )
    .execute(&db.pool)
    .await?;
    Ok((temp, db))
}

async fn chat_state(db: &AppDatabase, group_id: &str) -> anyhow::Result<(i64, i64)> {
    Ok(
        sqlx::query_as("SELECT archived, deleted_content FROM groups WHERE group_id = ?")
            .bind(group_id)
            .fetch_one(&db.pool)
            .await?,
    )
}

#[tokio::test]
async fn received_text_unarchives_direct_chat_and_notifies_chat_list() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;
    let mut changes = db.subscribe();
    let mut tx = db.pool.begin().await?;
    // Use the same Rust insertion helper as the incoming text handler.
    NewMessage::builder()
        .group_id("direct")
        .message_id("received")
        .sender_id(7)
        .message_type(MessageType::Text)
        .content("Hello")
        .created_at(1700000200)
        .build()
        .insert(&mut tx)
        .await?;
    tx.commit().await?;
    assert_eq!(chat_state(&db, "direct").await?, (0, 0));
    let changed = tokio::time::timeout(std::time::Duration::from_secs(1), changes.recv()).await??;
    assert!(changed.tables.contains("groups"));
    assert!(changed.tables.contains("messages"));
    Ok(())
}

#[tokio::test]
async fn incoming_and_outgoing_chat_messages_unarchive_direct_chats() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;
    for sender in [Some(7_i64), None] {
        // Stickers are text rows; app cards and additional-data messages also
        // take the shared insertion path.
        for message_type in ["text", "media", "webxdcApp", "contacts"] {
            sqlx::query(
                "UPDATE groups SET archived = 1, deleted_content = 1 WHERE group_id = 'direct'",
            )
            .execute(&db.pool)
            .await?;
            sqlx::query("INSERT INTO messages(message_id, group_id, sender_id, type) VALUES (?, 'direct', ?, ?)")
                .bind(format!("{sender:?}-{message_type}"))
                .bind(sender)
                .bind(message_type)
                .execute(&db.pool).await?;
            assert_eq!(chat_state(&db, "direct").await?, (0, 0));
        }
    }
    Ok(())
}

#[tokio::test]
async fn stories_widgets_and_group_messages_preserve_archive_state() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;
    sqlx::raw_sql(
        "INSERT INTO messages(message_id, group_id, sender_id, type, is_story, is_widget_media)
         VALUES ('story', 'direct', 7, 'media', 1, 0),
                ('widget', 'direct', 7, 'media', 0, 1),
                ('group', 'group', 7, 'text', 0, 0);",
    )
    .execute(&db.pool)
    .await?;
    assert_eq!(chat_state(&db, "direct").await?, (1, 1));
    assert_eq!(chat_state(&db, "group").await?, (1, 1));
    Ok(())
}

#[tokio::test]
async fn duplicate_deliveries_and_edits_do_not_unarchive_again() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;
    sqlx::raw_sql(
        "INSERT INTO messages(message_id, group_id, sender_id, type, content)
         VALUES ('received', 'direct', 7, 'text', 'Hello');
         UPDATE groups SET archived = 1 WHERE group_id = 'direct';
         INSERT INTO messages(message_id, group_id, sender_id, type)
         VALUES ('received', 'direct', 7, 'text') ON CONFLICT(message_id) DO NOTHING;
         UPDATE messages SET content = 'Edited' WHERE message_id = 'received';",
    )
    .execute(&db.pool)
    .await?;
    assert_eq!(chat_state(&db, "direct").await?, (1, 0));
    Ok(())
}

#[tokio::test]
async fn rolled_back_message_preserves_archive_state() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;
    let mut changes = db.subscribe();
    let mut tx = db.pool.begin().await?;
    sqlx::query(
        "INSERT INTO messages(message_id, group_id, type) VALUES ('failed', 'direct', 'text')",
    )
    .execute(&mut *tx)
    .await?;
    tx.rollback().await?;
    assert_eq!(chat_state(&db, "direct").await?, (1, 1));
    assert!(matches!(
        changes.try_recv(),
        Err(tokio::sync::broadcast::error::TryRecvError::Empty)
    ));
    Ok(())
}
