use super::queries;
use crate::database::app::AppDatabase;

#[tokio::test]

async fn story_payloads_normalize_media_and_distinguish_server_receipt_from_opening() {
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

    for statement in [
        "INSERT INTO contacts(user_id,username,accepted) VALUES (7,'alice',1),(8,'bob',1)",
        "INSERT INTO groups(group_id,group_name) VALUES ('a','A'),('b','B')",
        "INSERT INTO group_members(group_id,contact_id) VALUES ('a',7),('b',8)",
        "INSERT INTO media_files(media_id,type) VALUES ('story','image')",
        r#"
        INSERT INTO messages(message_id,group_id,type,media_id,is_story,created_at)
        VALUES ('own-a','a','media','story',1,100),
            ('own-b','b','media','story',1,100)
        "#,
        r#"
        INSERT INTO messages(message_id,group_id,sender_id,type,media_id,is_story,created_at)
        VALUES ('received-a','a',7,'media','story',1,100),
            ('received-b','b',8,'media','story',1,100)
        "#,
        r#"
        INSERT INTO message_actions(message_id,contact_id,type,action_at)
        VALUES ('own-a',7,'ackByServerAt',200),
            ('own-b',8,'openedAt',201)
        "#,
    ] {
        sqlx::query(sqlx::AssertSqlSafe(statement))
            .execute(&mut *tx)
            .await
            .unwrap();
    }

    let received = queries::received(&mut tx, 99, None, None).await.unwrap();

    assert_eq!((received.messages.len(), received.files.len()), (2, 1));

    assert!(queries::received(&mut tx, 100, None, None)
        .await
        .unwrap()
        .messages
        .is_empty());

    let own = queries::own(&mut tx, 99).await.unwrap();

    assert_eq!(
        (
            own.items.len(),
            own.files.len(),
            own.items[0].recipient_count
        ),
        (1, 1, 2)
    );

    let viewers = queries::viewers(&mut tx, "story").await.unwrap();

    assert_eq!(viewers.links[0].contact_id, 8);

    assert_eq!(viewers.links[0].received_at, Some(201));

    assert_eq!(viewers.links[1].received_at, None);
}
