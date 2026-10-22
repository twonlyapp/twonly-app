use super::table::UserDiscoveryAnnouncedUserPatch;
use super::{queries, writes};
use crate::database::app::patch::NullableText;
use crate::database::app::AppDatabase;

#[tokio::test]

async fn suggestions_count_only_eligible_friends_and_honor_thresholds_and_visibility() {
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

    sqlx::query(
        r#"
        INSERT INTO contacts(user_id,username,accepted)
        VALUES (1,'a',1),
            (2,'b',1),
            (3,'c',1),
            (4,'d',1)
        "#,
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    sqlx::query(
        r#"
        INSERT INTO user_discovery_announced_users(announced_user_id,announced_public_key,public_id,
                username
        )
        VALUES (99,X'01',99,'new'),
            (100,X'02',100,NULL)
        "#,
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    for id in 1..=4 {
        sqlx::query(
            r#"
            INSERT INTO user_discovery_user_relations(announced_user_id,from_contact_id)
            VALUES (99,?)
            "#,
        )
        .bind(id)
        .execute(&mut *tx)
        .await
        .unwrap();
    }

    assert_eq!(queries::count_suggestions(&mut tx, 1).await.unwrap(), 1);

    assert_eq!(queries::count_suggestions(&mut tx, 5).await.unwrap(), 0);

    let suggestions = queries::suggestions(&mut tx, true, 3).await.unwrap();

    assert_eq!(
        (
            suggestions.users.len(),
            suggestions.relations.len(),
            suggestions.contacts.len()
        ),
        (1, 4, 4)
    );

    sqlx::query("UPDATE contacts SET blocked = 1 WHERE user_id IN (3,4)")
        .execute(&mut *tx)
        .await
        .unwrap();

    assert_eq!(queries::count_suggestions(&mut tx, 1).await.unwrap(), 0);

    sqlx::query("UPDATE contacts SET blocked = 0")
        .execute(&mut *tx)
        .await
        .unwrap();

    writes::mark_shown(&mut tx).await.unwrap();

    assert_eq!(queries::count_suggestions(&mut tx, 3).await.unwrap(), 0);

    assert_eq!(
        queries::suggestions(&mut tx, true, 3)
            .await
            .unwrap()
            .users
            .len(),
        1
    );

    writes::update(
        &mut tx,
        99,
        UserDiscoveryAnnouncedUserPatch {
            is_hidden: Some(true),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    assert!(queries::suggestions(&mut tx, true, 3)
        .await
        .unwrap()
        .users
        .is_empty());

    assert_eq!(
        queries::suggestions(&mut tx, false, 3)
            .await
            .unwrap()
            .users
            .len(),
        1
    );

    writes::update(
        &mut tx,
        99,
        UserDiscoveryAnnouncedUserPatch {
            username: Some(NullableText { value: None }),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    assert_eq!(queries::missing_data(&mut tx).await.unwrap().len(), 2);

    assert_eq!(queries::announcements(&mut tx).await.unwrap().len(), 2);

    assert_eq!(queries::relations(&mut tx).await.unwrap().len(), 4);

    assert!(
        !queries::get(&mut tx, 100)
            .await
            .unwrap()
            .unwrap()
            .was_shown_to_the_user
    );

    assert!(queries::own_promotions(&mut tx).await.unwrap().is_empty());

    assert!(queries::other_promotions(&mut tx).await.unwrap().is_empty());

    assert!(queries::shares(&mut tx).await.unwrap().is_empty());
}
