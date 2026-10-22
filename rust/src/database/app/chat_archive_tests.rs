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
async fn received_text_unarchives_chats_and_notifies_chat_list() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;
    for group_id in ["direct", "group"] {
        let mut changes = db.subscribe();
        let mut tx = db.pool.begin().await?;
        // Use the same Rust insertion helper as the incoming text handler.
        NewMessage::builder()
            .group_id(group_id)
            .message_id(&format!("received-{group_id}"))
            .sender_id(7)
            .message_type(MessageType::Text)
            .content("Hello")
            .created_at(1700000200)
            .build()
            .insert(&mut tx)
            .await?;
        tx.commit().await?;
        assert_eq!(chat_state(&db, group_id).await?, (0, 0));
        let changed =
            tokio::time::timeout(std::time::Duration::from_secs(1), changes.recv()).await??;
        assert!(changed.tables.contains("groups"));
        assert!(changed.tables.contains("messages"));
    }
    Ok(())
}

#[tokio::test]
async fn incoming_and_outgoing_chat_messages_unarchive_chats() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;
    for group_id in ["direct", "group"] {
        for sender in [Some(7_i64), None] {
            // Stickers are text rows; app cards and additional-data messages also
            // take the shared insertion path.
            for message_type in ["text", "media", "webxdcApp", "contacts"] {
                sqlx::query(
                    "UPDATE groups SET archived = 1, deleted_content = 1 WHERE group_id = ?",
                )
                .bind(group_id)
                .execute(&db.pool)
                .await?;
                sqlx::query("INSERT INTO messages(message_id, group_id, sender_id, type) VALUES (?, ?, ?, ?)")
                .bind(format!("{group_id}-{sender:?}-{message_type}"))
                .bind(group_id)
                .bind(sender)
                .bind(message_type)
                .execute(&db.pool).await?;
                assert_eq!(chat_state(&db, group_id).await?, (0, 0));
            }
        }
    }
    Ok(())
}

#[tokio::test]
async fn unsaved_stories_preserve_archive_state() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;
    for sender in [Some(7_i64), None] {
        sqlx::query(
            "INSERT INTO messages(message_id, group_id, sender_id, type, is_story)
             VALUES (?, 'direct', ?, 'media', 1)",
        )
        .bind(format!("story-{sender:?}"))
        .bind(sender)
        .execute(&db.pool)
        .await?;
        assert_eq!(chat_state(&db, "direct").await?, (1, 1));
    }
    Ok(())
}

#[tokio::test]
async fn widget_media_and_saved_stories_unarchive_chats() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;
    for group_id in ["direct", "group"] {
        for sender in [Some(7_i64), None] {
            for is_story in [false, true] {
                sqlx::query(
                    "UPDATE groups SET archived = 1, deleted_content = 1 WHERE group_id = ?",
                )
                .bind(group_id)
                .execute(&db.pool)
                .await?;
                sqlx::query("INSERT INTO messages(message_id, group_id, sender_id, type, is_widget_media, is_story, media_stored) VALUES (?, ?, ?, 'media', ?, ?, ?)")
                    .bind(format!("{group_id}-{sender:?}-{is_story}"))
                    .bind(group_id).bind(sender).bind(!is_story).bind(is_story).bind(is_story)
                    .execute(&db.pool).await?;
                assert_eq!(chat_state(&db, group_id).await?, (0, 0));
            }
        }
    }
    Ok(())
}

#[tokio::test]
async fn duplicate_deliveries_and_edits_do_not_unarchive_again() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;
    for group_id in ["direct", "group"] {
        sqlx::query("INSERT INTO messages(message_id, group_id, sender_id, type, content) VALUES (?, ?, 7, 'text', 'Hello')")
            .bind(group_id).bind(group_id).execute(&db.pool).await?;
        sqlx::query("UPDATE groups SET archived = 1 WHERE group_id = ?")
            .bind(group_id)
            .execute(&db.pool)
            .await?;
        sqlx::query("INSERT INTO messages(message_id, group_id, sender_id, type) VALUES (?, ?, 7, 'text') ON CONFLICT(message_id) DO NOTHING")
            .bind(group_id).bind(group_id).execute(&db.pool).await?;
        sqlx::query("UPDATE messages SET content = 'Edited' WHERE message_id = ?")
            .bind(group_id)
            .execute(&db.pool)
            .await?;
        assert_eq!(chat_state(&db, group_id).await?, (1, 0));
    }
    Ok(())
}

#[tokio::test]
async fn rolled_back_message_preserves_archive_state() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;
    for group_id in ["direct", "group"] {
        let mut changes = db.subscribe();
        let mut tx = db.pool.begin().await?;
        sqlx::query(
            "INSERT INTO messages(message_id, group_id, type) VALUES ('failed', ?, 'text')",
        )
        .bind(group_id)
        .execute(&mut *tx)
        .await?;
        tx.rollback().await?;
        assert_eq!(chat_state(&db, group_id).await?, (1, 1));
        assert!(matches!(
            changes.try_recv(),
            Err(tokio::sync::broadcast::error::TryRecvError::Empty)
        ));
    }
    Ok(())
}

#[tokio::test]
async fn upgrading_preserves_archived_history_until_a_new_message() -> anyhow::Result<()> {
    let (_temp, db) = database().await?;
    sqlx::raw_sql("DROP TRIGGER chat_message_unarchive;")
        .execute(&db.pool)
        .await?;
    sqlx::raw_sql(include_str!(
        "migrations/0035_direct_chat_message_unarchive.sql"
    ))
    .execute(&db.pool)
    .await?;
    sqlx::raw_sql(
        "INSERT INTO messages(message_id, group_id, type) VALUES
         ('old-direct', 'direct', 'text'), ('old-group', 'group', 'media');
         UPDATE groups SET archived = 1, deleted_content = 1;",
    )
    .execute(&db.pool)
    .await?;
    sqlx::raw_sql(include_str!("migrations/0043_chat_message_unarchive.sql"))
        .execute(&db.pool)
        .await?;
    for group_id in ["direct", "group"] {
        assert_eq!(chat_state(&db, group_id).await?, (1, 1));
        sqlx::query("INSERT INTO messages(message_id, group_id, type) VALUES (?, ?, 'media')")
            .bind(group_id)
            .bind(group_id)
            .execute(&db.pool)
            .await?;
        assert_eq!(chat_state(&db, group_id).await?, (0, 0));
    }
    Ok(())
}
