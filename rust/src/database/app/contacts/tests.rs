use super::table::*;
use super::{queries, writes};
use crate::database::app::patch::{NullableInt, NullableText};
use crate::database::app::AppDatabase;

async fn open() -> (tempfile::TempDir, AppDatabase) {
    let directory = tempfile::tempdir().unwrap();

    let database = AppDatabase::new(
        directory.path().join("app.sqlite").to_str().unwrap(),
        None,
        false,
    )
    .await
    .unwrap();

    database.run_migrations().await.unwrap();

    (directory, database)
}

fn input(id: i64, username: &str) -> ContactPatch {
    ContactPatch {
        user_id: Some(id),
        username: Some(username.into()),
        ..Default::default()
    }
}

fn query(filter: ContactFilter) -> ContactQuery {
    ContactQuery {
        filter,
        ids: vec![],
        username: None,
        username2: None,
        required_send_images: 0,
        manual_approval: false,
    }
}

#[tokio::test]
async fn direct_chat_repair_restores_friends_without_reviving_removed_contacts() {
    let (_directory, database) = open().await;
    for statement in [
        "INSERT INTO contacts(user_id, username, requested, requested_by_user, blocked, deleted_by_user, account_deleted) VALUES
         (1, 'friend', 1, 1, 0, 0, 0), (2, 'group-only', 1, 0, 0, 0, 0),
         (3, 'blocked', 1, 0, 1, 0, 0), (4, 'removed', 1, 0, 0, 1, 0),
         (5, 'deleted-account', 1, 0, 0, 0, 1), (6, 'outgoing', 0, 1, 0, 0, 0),
         (7, 'incidental-contact', 0, 0, 0, 0, 0)",
        "INSERT INTO groups(group_id, group_name, is_direct_chat, flame_counter) VALUES ('direct', 'Friend', 1, 65), ('group', 'Group', 0, 0)",
        "INSERT INTO group_members(group_id, contact_id) VALUES ('direct', 1), ('direct', 3), ('direct', 4), ('direct', 5), ('group', 2)",
        "INSERT INTO receipts(receipt_id, contact_id, message, mark_for_retry_after_accepted) VALUES ('friend', 1, x'00', 1), ('blocked', 3, x'00', 1)",
    ] {
        sqlx::query(statement).execute(&database.pool).await.unwrap();
    }
    database.repair_direct_chat_contacts().await.unwrap();
    database.repair_direct_chat_contacts().await.unwrap();
    let mut tx = database.pool.begin().await.unwrap();
    let friend = queries::get(&mut tx, 1).await.unwrap().unwrap();
    assert_eq!(
        (friend.accepted, friend.requested, friend.requested_by_user),
        (1, 0, 0)
    );
    for id in 2..=7 {
        assert_eq!(
            queries::get(&mut tx, id).await.unwrap().unwrap().accepted,
            0
        );
    }
    let visible = queries::list(&mut tx, &query(ContactFilter::NotAccepted))
        .await
        .unwrap();
    assert_eq!(
        visible.iter().map(|c| c.user_id).collect::<Vec<_>>(),
        vec![2, 6]
    );
    assert_eq!(
        queries::count(&mut tx, ContactCount::Requested)
            .await
            .unwrap(),
        1
    );
    let parked: Vec<String> = sqlx::query_scalar(
        "SELECT receipt_id FROM receipts WHERE mark_for_retry_after_accepted IS NOT NULL",
    )
    .fetch_all(&mut *tx)
    .await
    .unwrap();
    assert_eq!(parked, vec!["blocked"]);
    let flames: i64 =
        sqlx::query_scalar("SELECT flame_counter FROM groups WHERE group_id = 'direct'")
            .fetch_one(&mut *tx)
            .await
            .unwrap();
    assert_eq!(flames, 65);
}

#[tokio::test]

async fn native_upsert_preserves_defaults_null_patches_and_photo_preference() {
    let (_directory, database) = open().await;

    let mut tx = database.pool.begin().await.unwrap();

    assert_eq!(writes::upsert(&mut tx, input(7, "alice")).await.unwrap(), 7);

    writes::update(
        &mut tx,
        7,
        ContactPatch {
            display_name: Some(NullableText {
                value: Some("Alice".into()),
            }),
            prefer_photo_avatar: Some(NullableInt { value: Some(0) }),
            accepted: Some(true),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    let row = queries::get(&mut tx, 7).await.unwrap().unwrap();

    assert_eq!(
        (
            row.display_name.as_deref(),
            row.prefer_photo_avatar,
            row.accepted
        ),
        (Some("Alice"), Some(0), 1)
    );

    writes::upsert(&mut tx, input(7, "updated")).await.unwrap();

    writes::update(
        &mut tx,
        7,
        ContactPatch {
            display_name: Some(NullableText { value: None }),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    let row = queries::get(&mut tx, 7).await.unwrap().unwrap();

    assert_eq!(
        (row.username.as_str(), row.display_name, row.accepted),
        ("updated", None, 1)
    );

    writes::update(&mut tx, 7, ContactPatch::default())
        .await
        .unwrap();
}

#[tokio::test]

async fn filters_counts_and_direct_chat_name_are_computed_in_rust() {
    let (_directory, database) = open().await;

    let mut tx = database.pool.begin().await.unwrap();

    writes::upsert(&mut tx, input(7, "alice")).await.unwrap();

    writes::upsert(&mut tx, input(8, "bob")).await.unwrap();

    sqlx::query!(
        r#"
            INSERT INTO groups(group_id, group_name, is_direct_chat)
            VALUES ('g', 'old', 1)
        "#
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    sqlx::query!(
        r#"
            INSERT INTO group_members(group_id, contact_id)
            VALUES ('g', 7)
        "#
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    writes::update(
        &mut tx,
        7,
        ContactPatch {
            nick_name: Some(NullableText {
                value: Some("Nickname".into()),
            }),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    let name = sqlx::query_scalar!(
        "SELECT group_name AS \"group_name!\" FROM groups WHERE group_id = 'g'"
    )
    .fetch_one(&mut *tx)
    .await
    .unwrap();

    assert_eq!(name, "Nickname");

    for id in [7, 8] {
        writes::update(
            &mut tx,
            id,
            ContactPatch {
                requested: Some(true),
                ..Default::default()
            },
        )
        .await
        .unwrap();
    }

    assert_eq!(
        queries::count(&mut tx, ContactCount::Requested)
            .await
            .unwrap(),
        2
    );

    writes::update(
        &mut tx,
        7,
        ContactPatch {
            blocked: Some(true),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    assert_eq!(
        queries::count(&mut tx, ContactCount::Requested)
            .await
            .unwrap(),
        1
    );

    assert_eq!(
        queries::count(&mut tx, ContactCount::Blocked)
            .await
            .unwrap(),
        1
    );

    assert_eq!(
        queries::list(&mut tx, &query(ContactFilter::NotAccepted))
            .await
            .unwrap()
            .len(),
        1
    );

    let mut ids = query(ContactFilter::Ids);

    ids.ids = (0..2000).collect();

    assert_eq!(queries::list(&mut tx, &ids).await.unwrap().len(), 2);

    writes::update(
        &mut tx,
        8,
        ContactPatch {
            accepted: Some(true),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    assert_eq!(
        queries::count(&mut tx, ContactCount::Requested)
            .await
            .unwrap(),
        0
    );

    writes::reset_recovery(&mut tx).await.unwrap();

    tx.rollback().await.unwrap();
}
