use super::table::*;
use super::{queries, writes};
use crate::database::app::AppDatabase;

async fn fixture() -> (tempfile::TempDir, AppDatabase) {
    let directory = tempfile::tempdir().unwrap();

    let database = AppDatabase::new(
        directory.path().join("groups.sqlite").to_str().unwrap(),
        None,
        false,
    )
    .await
    .unwrap();

    database.run_migrations().await.unwrap();

    for statement in [
        "INSERT INTO contacts(user_id, username) VALUES (7, 'Alice'), (8, 'Bob'), (9, 'Carol')",
        r#"
        INSERT INTO groups(group_id, group_name, is_direct_chat)
        VALUES ('friends', 'Friends', 0), ('other', 'Other', 0), ('direct', 'Direct', 1)
        "#,
        r#"
        INSERT INTO group_members(group_id, contact_id, member_state, last_type_indicator)
        VALUES ('friends', 7, NULL, 1), ('friends', 8, 'admin', 1),
               ('friends', 9, 'leftGroup', 1), ('other', 7, NULL, NULL),
               ('direct', 7, NULL, NULL)
        "#,
        r#"
        INSERT INTO messages(message_id, group_id, sender_id, type, content, created_at)
        VALUES ('retained', 'friends', 7, 'text', 'Keep history', 1)
        "#,
        r#"
        INSERT INTO group_histories(group_history_id, group_id, affected_contact_id, type)
        VALUES ('removal', 'friends', 7, 'removedMember')
        "#,
    ] {
        sqlx::query(sqlx::AssertSqlSafe(statement))
            .execute(&database.pool)
            .await
            .unwrap();
    }

    (directory, database)
}

// Former groups_dao_test regressions now exercise the SQLx implementation.
#[tokio::test]

async fn removing_and_rejoining_members_preserves_history_and_other_chats() {
    use crate::database::app::patch::NullableText;

    let (_directory, database) = fixture().await;

    let mut tx = database.pool.begin().await.unwrap();

    let active = GroupMembersQuery {
        group_id: Some("friends".into()),
        contact_id: None,
        active_only: true,
        typing_only: true,
        order_for_chats: true,
    };

    for (state, expected) in [
        (None, vec![7, 8]),
        (Some("leftGroup"), vec![8]),
        (Some("normal"), vec![7, 8]),
        (Some("admin"), vec![7, 8]),
    ] {
        writes::upsert_member(
            &mut tx,
            GroupMemberPatch {
                group_id: Some("friends".into()),
                contact_id: Some(7),
                member_state: Some(NullableText {
                    value: state.map(str::to_owned),
                }),
                ..Default::default()
            },
        )
        .await
        .unwrap();

        let joined = queries::members_with_contacts(&mut tx, &active)
            .await
            .unwrap();

        assert_eq!(
            joined
                .members
                .iter()
                .map(|m| m.contact_id)
                .collect::<Vec<_>>(),
            expected
        );

        assert_eq!(joined.contacts.len(), expected.len());

        let mutual = queries::list(
            &mut tx,
            &GroupQuery {
                filter: GroupFilter::NonDirectForContact,
                group_id: None,
                contact_id: Some(7),
            },
        )
        .await
        .unwrap();

        assert_eq!(
            mutual
                .iter()
                .map(|g| g.group_id.as_str())
                .collect::<Vec<_>>(),
            if state == Some("leftGroup") {
                vec!["other"]
            } else {
                vec!["friends", "other"]
            }
        );

        let all = queries::members(
            &mut tx,
            &GroupMembersQuery {
                active_only: false,
                ..active.clone()
            },
        )
        .await
        .unwrap();

        assert_eq!(all.len(), 3);

        let by_contact = queries::members(
            &mut tx,
            &GroupMembersQuery {
                group_id: None,
                contact_id: Some(7),
                active_only: false,
                typing_only: false,
                order_for_chats: false,
            },
        )
        .await
        .unwrap();

        assert_eq!(by_contact.len(), 3);

        assert_eq!(
            queries::history(&mut tx, "friends", None).await.unwrap()[0].affected_contact_id,
            Some(7)
        );

        assert!(
            crate::database::app::messages::queries::get(&mut tx, "retained")
                .await
                .unwrap()
                .is_some()
        );
    }

    tx.commit().await.unwrap();

    database.pool.close().await;
}

#[tokio::test]

async fn member_watch_reacts_to_membership_and_message_activity_after_commit() {
    use std::sync::Arc;
    use std::time::Duration;
    use tokio::sync::{mpsc, RwLock};
    use tokio_util::sync::CancellationToken;

    let (_directory, database) = fixture().await;

    let database = Arc::new(database);

    let databases = Arc::new(RwLock::new(database.clone()));

    let stop = CancellationToken::new();

    let cancellation = stop.clone();

    let (send, mut receive) = mpsc::unbounded_channel();

    let task = tokio::spawn(async move {
        super::watches::contacts(
            databases,
            GroupMembersQuery {
                group_id: Some("friends".into()),
                contact_id: None,
                active_only: true,
                typing_only: false,
                order_for_chats: true,
            },
            cancellation,
            move |rows| {
                send.send(
                    rows.members
                        .iter()
                        .map(|m| m.contact_id)
                        .collect::<Vec<_>>(),
                )
                .is_ok()
            },
        )
        .await
    });

    async fn next(receive: &mut mpsc::UnboundedReceiver<Vec<i64>>) -> Vec<i64> {
        tokio::time::timeout(Duration::from_secs(2), receive.recv())
            .await
            .unwrap()
            .unwrap()
    }

    assert_eq!(next(&mut receive).await, vec![7, 8]);

    let mut tx = database.pool.begin().await.unwrap();

    writes::upsert_member(
        &mut tx,
        GroupMemberPatch {
            group_id: Some("friends".into()),
            contact_id: Some(7),
            member_state: Some(crate::database::app::patch::NullableText {
                value: Some("leftGroup".into()),
            }),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    tx.commit().await.unwrap();

    assert_eq!(next(&mut receive).await, vec![8]);

    let mut tx = database.pool.begin().await.unwrap();

    writes::upsert_member(
        &mut tx,
        GroupMemberPatch {
            group_id: Some("friends".into()),
            contact_id: Some(7),
            member_state: Some(crate::database::app::patch::NullableText {
                value: Some("normal".into()),
            }),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    tx.commit().await.unwrap();

    assert_eq!(next(&mut receive).await, vec![7, 8]);

    sqlx::query(
        r#"
        INSERT INTO messages(message_id, group_id, sender_id, type, created_at)
        VALUES ('newer', 'friends', 8, 'text', 2000000000)
        "#,
    )
    .execute(&database.pool)
    .await
    .unwrap();

    assert_eq!(next(&mut receive).await, vec![8, 7]);

    stop.cancel();

    tokio::time::timeout(Duration::from_secs(2), task)
        .await
        .unwrap()
        .unwrap()
        .unwrap();

    database.pool.close().await;
}

#[tokio::test]

async fn group_commands_membership_filters_and_monotonic_activity() {
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
        INSERT INTO contacts(user_id,username,widget_sharing_allowed)
        VALUES (7,'alice',1),
            (8,'bob',0)
        "#,
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    let group = writes::direct_chat(
        &mut tx,
        7,
        1,
        GroupPatch {
            group_name: Some("Alice".into()),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    assert!(group.is_direct_chat && group.joined_group && group.is_group_admin);

    writes::upsert(
        &mut tx,
        GroupPatch {
            group_id: Some("g".into()),
            group_name: Some("Friends".into()),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    writes::upsert_member(
        &mut tx,
        GroupMemberPatch {
            group_id: Some("g".into()),
            contact_id: Some(7),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    writes::upsert_member(
        &mut tx,
        GroupMemberPatch {
            group_id: Some("g".into()),
            contact_id: Some(8),
            member_state: Some(crate::database::app::patch::NullableText {
                value: Some("leftGroup".into()),
            }),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    let input = GroupMembersQuery {
        group_id: Some("g".into()),
        contact_id: None,
        active_only: true,
        typing_only: false,
        order_for_chats: true,
    };

    let joined = queries::members_with_contacts(&mut tx, &input)
        .await
        .unwrap();

    assert_eq!((joined.members.len(), joined.contacts.len()), (1, 1));

    let widget = queries::list(
        &mut tx,
        &GroupQuery {
            filter: GroupFilter::WidgetShare,
            group_id: None,
            contact_id: None,
        },
    )
    .await
    .unwrap();

    assert_eq!(widget[0].group_id, group.group_id);

    writes::increase_exchange(&mut tx, "g", Some(7), 100, 50)
        .await
        .unwrap();

    writes::increase_exchange(&mut tx, "g", Some(7), 40, 60)
        .await
        .unwrap();

    assert_eq!(
        queries::members(&mut tx, &input).await.unwrap()[0].last_message,
        Some(50)
    );

    writes::insert_history(
        &mut tx,
        GroupHistoryPatch {
            group_id: Some("g".into()),
            r#type: Some("createdGroup".into()),
            action_at: Some(100),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    assert_eq!(
        queries::history(&mut tx, "g", Some(100))
            .await
            .unwrap()
            .len(),
        1
    );

    assert!(queries::history(&mut tx, "g", Some(101))
        .await
        .unwrap()
        .is_empty());

    assert_eq!(queries::total_media(&mut tx).await.unwrap(), 0);

    writes::delete(&mut tx, "g").await.unwrap();

    assert!(queries::get(&mut tx, "g").await.unwrap().is_none());
}
