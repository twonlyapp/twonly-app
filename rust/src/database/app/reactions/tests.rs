use super::{queries, writes};
use crate::database::app::AppDatabase;

#[tokio::test]

async fn latest_reactions_filter_hidden_stories_and_normalize_contacts() {
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

    sqlx::query("INSERT INTO contacts(user_id,username) VALUES (7,'alice')")
        .execute(&mut *tx)
        .await
        .unwrap();

    sqlx::query("INSERT INTO groups(group_id,group_name) VALUES ('g','g')")
        .execute(&mut *tx)
        .await
        .unwrap();

    sqlx::query(
        r#"
        INSERT INTO messages(message_id,group_id,type,created_at,is_story,media_stored)
        VALUES ('m','g','text',10,0,0),
            ('story','g','media',20,1,0)
        "#,
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    sqlx::query(
        r#"
        INSERT INTO reactions(message_id,emoji,sender_id,created_at)
        VALUES ('m','👍',7,11),
            ('m','❤️',7,12),
            ('story','👀',7,30)
        "#,
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    let reactions = queries::with_contacts(&mut tx, "m").await.unwrap();

    assert_eq!(
        (reactions.reactions.len(), reactions.contacts.len()),
        (2, 1)
    );

    assert_eq!(
        queries::last(&mut tx, "g").await.unwrap().unwrap().emoji,
        "❤️"
    );

    assert_eq!(
        queries::latest_by_group(&mut tx).await.unwrap()[0]
            .reaction
            .emoji,
        "❤️"
    );

    sqlx::query("UPDATE messages SET media_stored = 1 WHERE message_id = 'story'")
        .execute(&mut *tx)
        .await
        .unwrap();

    assert_eq!(
        queries::latest_by_group(&mut tx).await.unwrap()[0]
            .reaction
            .emoji,
        "👀"
    );

    writes::update_own(&mut tx, "m", "👍", false).await.unwrap();

    writes::update_own(&mut tx, "m", "👍", false).await.unwrap();

    assert_eq!(
        queries::list(&mut tx, &["m".into()]).await.unwrap().len(),
        3
    );

    writes::update_own(&mut tx, "m", "👍", true).await.unwrap();

    writes::update_own(&mut tx, "missing", "👍", false)
        .await
        .unwrap();

    assert_eq!(
        queries::list(&mut tx, &["m".into()]).await.unwrap().len(),
        2
    );

    assert!(queries::list(&mut tx, &[]).await.unwrap().is_empty());
}
