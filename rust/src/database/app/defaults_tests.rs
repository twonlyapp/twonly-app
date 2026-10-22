//! Checked fixed INSERT statements must retain SQLite's schema defaults.

use super::{contacts, groups, mediafiles, messages, AppDatabase};

#[tokio::test]

async fn checked_upserts_match_database_defaults_for_omitted_fields() {
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

    let before =
        sqlx::query_scalar!("SELECT CAST(strftime('%s', 'now') AS INTEGER) AS \"now!: i64\"")
            .fetch_one(&mut *tx)
            .await
            .unwrap();

    contacts::writes::upsert(
        &mut tx,
        contacts::table::ContactPatch {
            user_id: Some(1),
            username: Some("defaults".into()),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    sqlx::query!("INSERT INTO contacts(user_id, username) VALUES (2, 'defaults')")
        .execute(&mut *tx)
        .await
        .unwrap();

    let actual = contacts::queries::get(&mut tx, 1).await.unwrap().unwrap();

    let mut expected = contacts::queries::get(&mut tx, 2).await.unwrap().unwrap();

    expected.user_id = actual.user_id;

    expected.created_at = actual.created_at;

    let mut timestamps = vec![actual.created_at];

    assert_eq!(actual, expected);

    let actual = groups::writes::upsert(
        &mut tx,
        groups::table::GroupPatch {
            group_id: Some("actual".into()),
            group_name: Some("defaults".into()),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    sqlx::query!("INSERT INTO groups(group_id, group_name) VALUES ('expected', 'defaults')")
        .execute(&mut *tx)
        .await
        .unwrap();

    let mut expected = groups::queries::get(&mut tx, "expected")
        .await
        .unwrap()
        .unwrap();

    expected.group_id = actual.group_id.clone();

    expected.created_at = actual.created_at;

    expected.last_message_exchange = actual.last_message_exchange;

    timestamps.extend([actual.created_at, actual.last_message_exchange]);

    assert_eq!(actual, expected);

    let actual = mediafiles::writes::upsert(
        &mut tx,
        mediafiles::table::MediaFilePatch {
            media_id: Some("actual".into()),
            r#type: Some("image".into()),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    sqlx::query!("INSERT INTO media_files(media_id, type) VALUES ('expected', 'image')")
        .execute(&mut *tx)
        .await
        .unwrap();

    let mut expected = mediafiles::queries::get(&mut tx, "expected")
        .await
        .unwrap()
        .unwrap();

    expected.media_id = actual.media_id.clone();

    expected.created_at = actual.created_at;

    timestamps.push(actual.created_at);

    assert_eq!(actual, expected);

    let actual = messages::writes::upsert(
        &mut tx,
        messages::table::MessagePatch {
            message_id: Some("actual".into()),
            group_id: Some("actual".into()),
            r#type: Some("text".into()),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    sqlx::query!(
        "INSERT INTO messages(message_id, group_id, type) VALUES ('expected', 'actual', 'text')"
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    let mut expected = messages::queries::get(&mut tx, "expected")
        .await
        .unwrap()
        .unwrap();

    expected.message_id = actual.message_id.clone();

    expected.created_at = actual.created_at;

    timestamps.push(actual.created_at);

    assert_eq!(actual, expected);

    groups::writes::upsert_member(
        &mut tx,
        groups::table::GroupMemberPatch {
            group_id: Some("actual".into()),
            contact_id: Some(1),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    sqlx::query!("INSERT INTO group_members(group_id, contact_id) VALUES ('actual', 2)")
        .execute(&mut *tx)
        .await
        .unwrap();

    let mut rows = groups::queries::members(
        &mut tx,
        &groups::table::GroupMembersQuery {
            group_id: Some("actual".into()),
            contact_id: None,
            active_only: false,
            typing_only: false,
            order_for_chats: false,
        },
    )
    .await
    .unwrap();

    let actual = rows.remove(0);

    let mut expected = rows.remove(0);

    expected.contact_id = actual.contact_id;

    expected.created_at = actual.created_at;

    timestamps.push(actual.created_at);

    assert_eq!(actual, expected);

    let after =
        sqlx::query_scalar!("SELECT CAST(strftime('%s', 'now') AS INTEGER) AS \"now!: i64\"")
            .fetch_one(&mut *tx)
            .await
            .unwrap();

    assert!(timestamps
        .into_iter()
        .all(|timestamp| (before..=after).contains(&timestamp)));

    tx.rollback().await.unwrap();

    database.pool.close().await;
}
