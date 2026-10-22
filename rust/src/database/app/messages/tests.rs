use super::table::*;
use super::{queries, writes};
use crate::database::app::AppDatabase;
use crate::error::TwonlyError;
use std::sync::atomic::{AtomicUsize, Ordering};

async fn open(path: &str) -> AppDatabase {
    let db = AppDatabase::new(path, None, false).await.unwrap();

    db.run_migrations().await.unwrap();

    db
}

fn input(filter: MessageFilter) -> MessageQuery {
    MessageQuery {
        filter,
        group_id: None,
        ids: vec![],
        limit: 2,
        before: None,
        before_message_id: None,
        now_ms: 100000,
    }
}

async fn seed(tx: &mut sqlx::Transaction<'_, sqlx::Sqlite>) {
    sqlx::query("INSERT INTO contacts(user_id,username) VALUES (7,'alice')")
        .execute(&mut **tx)
        .await
        .unwrap();

    sqlx::query("INSERT INTO groups(group_id,group_name) VALUES ('g','G')")
        .execute(&mut **tx)
        .await
        .unwrap();

    sqlx::query(
        "INSERT INTO media_files(media_id,type,download_state) VALUES ('media','image','ready')",
    )
    .execute(&mut **tx)
    .await
    .unwrap();

    sqlx::query(
        r#"
            INSERT INTO messages(message_id,group_id,sender_id,type,content,created_at)
            VALUES ('a','g',7,'text','A',10),
                ('b','g',7,'text','B',10),
                ('c','g',7,'text','C',11)
        "#,
    )
    .execute(&mut **tx)
    .await
    .unwrap();

    sqlx::query(
        r#"
            INSERT INTO messages(message_id,group_id,sender_id,type,media_id,created_at)
            VALUES ('image','g',7,'media','media',12)
        "#,
    )
    .execute(&mut **tx)
    .await
    .unwrap();
}

#[tokio::test]

async fn message_queries_use_stable_pagination_and_native_edits_are_atomic() {
    let directory = tempfile::tempdir().unwrap();

    let path = directory.path().join("app.sqlite");

    let database = open(path.to_str().unwrap()).await;

    let mut tx = database.pool.begin().await.unwrap();

    seed(&mut tx).await;

    let mut page = input(MessageFilter::Page);

    page.group_id = Some("g".into());

    assert_eq!(
        queries::list(&mut tx, &page)
            .await
            .unwrap()
            .iter()
            .map(|r| r.message_id.as_str())
            .collect::<Vec<_>>(),
        vec!["c", "image"]
    );

    page.before = Some(11);

    page.before_message_id = Some("c".into());

    assert_eq!(
        queries::list(&mut tx, &page)
            .await
            .unwrap()
            .iter()
            .map(|r| r.message_id.as_str())
            .collect::<Vec<_>>(),
        vec!["a", "b"]
    );

    writes::edit(&mut tx, Some(8), "a", "wrong", 20)
        .await
        .unwrap();

    assert!(queries::history(&mut tx, "a").await.unwrap().is_empty());

    writes::edit(&mut tx, Some(7), "a", "new", 20)
        .await
        .unwrap();

    assert_eq!(
        queries::history(&mut tx, "a").await.unwrap()[0]
            .content
            .as_deref(),
        Some("A")
    );

    assert_eq!(
        queries::get(&mut tx, "a")
            .await
            .unwrap()
            .unwrap()
            .content
            .as_deref(),
        Some("new")
    );

    for filter in [
        MessageFilter::Unopened,
        MessageFilter::MediaUnopened,
        MessageFilter::Last,
        MessageFilter::LatestByGroup,
        MessageFilter::Ids,
        MessageFilter::MediaIds,
    ] {
        queries::list(&mut tx, &input(filter)).await.unwrap();
    }

    assert_eq!(queries::unopened_media(&mut tx).await.unwrap().len(), 1);

    queries::actions(&mut tx, "a").await.unwrap();

    queries::delivery_actions(&mut tx, &["a".into()])
        .await
        .unwrap();

    writes::purge(&mut tx, 100000).await.unwrap();

    writes::clear_chat(&mut tx, "g").await.unwrap();

    assert!(queries::get(&mut tx, "a").await.unwrap().is_none());
}

#[tokio::test]

async fn file_removal_waits_for_commit_survives_reopen_and_respects_recreated_media() {
    let directory = tempfile::tempdir().unwrap();

    let path = directory.path().join("app.sqlite");

    let database = open(path.to_str().unwrap()).await;

    let mut tx = database.pool.begin().await.unwrap();

    seed(&mut tx).await;

    tx.commit().await.unwrap();

    let calls = AtomicUsize::new(0);

    let mut tx = database.pool.begin().await.unwrap();

    writes::delete_from_sender(&mut tx, Some(8), "image")
        .await
        .unwrap();

    assert!(queries::get(&mut tx, "image")
        .await
        .unwrap()
        .unwrap()
        .media_id
        .is_some());

    writes::delete_from_sender(&mut tx, Some(7), "image")
        .await
        .unwrap();

    tx.rollback().await.unwrap();

    writes::drain_file_removals(&database, |_, _| {
        calls.fetch_add(1, Ordering::SeqCst);

        Ok(())
    })
    .await
    .unwrap();

    assert_eq!(calls.load(Ordering::SeqCst), 0);

    let mut tx = database.pool.begin().await.unwrap();

    writes::delete_from_sender(&mut tx, Some(7), "image")
        .await
        .unwrap();

    tx.commit().await.unwrap();

    database.pool.close().await;

    let database = open(path.to_str().unwrap()).await;

    assert!(
        writes::drain_file_removals(&database, |_, _| Err(TwonlyError::Generic(
            "disk error".into()
        )))
        .await
        .is_err()
    );

    assert_eq!(
        sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM pending_media_file_removals")
            .fetch_one(&database.pool)
            .await
            .unwrap(),
        1
    );

    sqlx::query("INSERT INTO media_files(media_id,type) VALUES ('media','image')")
        .execute(&database.pool)
        .await
        .unwrap();

    writes::drain_file_removals(&database, |_, _| {
        calls.fetch_add(1, Ordering::SeqCst);

        Ok(())
    })
    .await
    .unwrap();

    assert_eq!(calls.load(Ordering::SeqCst), 0);

    assert_eq!(
        sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM pending_media_file_removals")
            .fetch_one(&database.pool)
            .await
            .unwrap(),
        0
    );

    // A committed deletion with no replacement removes its files exactly once.
    let file = directory.path().join("removed-media.webp");

    std::fs::write(&file, [1, 2, 3]).unwrap();

    sqlx::query(
        r#"
            INSERT INTO pending_media_file_removals(media_id, media_type)
            VALUES ('removed-media', 'image')
        "#,
    )
    .execute(&database.pool)
    .await
    .unwrap();

    writes::drain_file_removals(&database, |id, media_type| {
        assert_eq!(id, "removed-media");

        assert_eq!(media_type, "image");

        calls.fetch_add(1, Ordering::SeqCst);

        std::fs::remove_file(&file).unwrap();

        Ok(())
    })
    .await
    .unwrap();

    assert!(!file.exists());

    writes::drain_file_removals(&database, |_, _| {
        panic!("successful file cleanup must not be repeated")
    })
    .await
    .unwrap();

    assert_eq!(calls.load(Ordering::SeqCst), 1);
}

// Storage regressions formerly run through the Flutter/Drift DAO suite.
#[tokio::test]

async fn removing_media_keeps_message_history_but_excludes_broken_chat_previews() {
    let directory = tempfile::tempdir().unwrap();

    let database = open(directory.path().join("app.sqlite").to_str().unwrap()).await;

    let mut tx = database.pool.begin().await.unwrap();

    seed(&mut tx).await;

    crate::database::app::mediafiles::writes::delete(&mut tx, "media")
        .await
        .unwrap();

    assert_eq!(
        queries::get(&mut tx, "image")
            .await
            .unwrap()
            .unwrap()
            .media_id,
        None
    );

    for filter in [
        MessageFilter::Unopened,
        MessageFilter::Last,
        MessageFilter::LatestByGroup,
    ] {
        let mut query = input(filter);

        query.group_id = Some("g".into());

        query.limit = 100;

        let rows = queries::list(&mut tx, &query).await.unwrap();

        assert!(!rows.is_empty());

        assert!(!rows.iter().any(|row| row.message_id == "image"));
    }

    assert!(queries::list(&mut tx, &input(MessageFilter::MediaUnopened))
        .await
        .unwrap()
        .is_empty());

    tx.commit().await.unwrap();

    database.pool.close().await;
}

#[tokio::test]

async fn retention_preserves_unopened_messages_and_inclusive_history_boundaries() {
    let directory = tempfile::tempdir().unwrap();

    let database = open(directory.path().join("app.sqlite").to_str().unwrap()).await;

    let mut tx = database.pool.begin().await.unwrap();

    for (group, hours) in [("short", 2), ("long", 4), ("direct", 2)] {
        sqlx::query(
            r#"
                INSERT INTO groups(group_id, group_name, is_direct_chat, delete_messages_after_milliseconds)
                VALUES (?, ?, ?, ?)
            "#,
        ).bind(group).bind(group).bind(group == "direct").bind(hours * 3600000)
            .execute(&mut *tx).await.unwrap();

        for kind in [
            "createdGroup",
            "removedMember",
            "addMember",
            "leftGroup",
            "promoteToAdmin",
            "demoteToMember",
            "updatedGroupName",
            "changeDisplayMaxTime",
            "updatedContactUsername",
            "updatedContactDisplayName",
        ] {
            for age in [1, 2, 3, 5] {
                sqlx::query(
                    r#"
                        INSERT INTO group_histories(group_history_id, group_id, type, action_at)
                        VALUES (?, ?, ?, ?)
                    "#,
                )
                .bind(format!("{group}-{kind}-{age}"))
                .bind(group)
                .bind(kind)
                .bind(100000 - age * 3600)
                .execute(&mut *tx)
                .await
                .unwrap();
            }
        }
    }

    sqlx::query(
        r#"
            INSERT INTO messages(message_id, group_id, type, opened_by_all, created_at, is_deleted_from_sender)
            VALUES ('unopened', 'short', 'text', NULL, 80000, 0),
                   ('expired', 'short', 'text', 80000, 80000, 0),
                   ('boundary', 'short', 'text', 92800, 80000, 0),
                   ('recent', 'short', 'text', 95000, 80000, 0),
                   ('deleted', 'short', 'text', NULL, 80000, 1)
        "#,
    ).execute(&mut *tx).await.unwrap();

    writes::purge(&mut tx, 100000000).await.unwrap();

    let remaining: Vec<String> =
        sqlx::query_scalar("SELECT message_id FROM messages ORDER BY message_id")
            .fetch_all(&mut *tx)
            .await
            .unwrap();

    assert_eq!(remaining, vec!["boundary", "recent", "unopened"]);

    for (group, expected) in [("short", 20), ("long", 30), ("direct", 20)] {
        assert_eq!(
            crate::database::app::groups::queries::history(&mut tx, group, None)
                .await
                .unwrap()
                .len(),
            expected
        );
    }

    writes::purge(&mut tx, 100000000).await.unwrap();

    assert_eq!(
        sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM groups")
            .fetch_one(&mut *tx)
            .await
            .unwrap(),
        3
    );

    assert_eq!(
        sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM group_histories")
            .fetch_one(&mut *tx)
            .await
            .unwrap(),
        70
    );

    tx.commit().await.unwrap();

    database.pool.close().await;
}

#[tokio::test]

async fn received_widget_images_survive_chat_retention_without_showing_expired_previews() {
    let directory = tempfile::tempdir().unwrap();

    let database = open(directory.path().join("app.sqlite").to_str().unwrap()).await;

    let mut tx = database.pool.begin().await.unwrap();

    sqlx::query("INSERT INTO contacts(user_id, username) VALUES (2, 'sender')")
        .execute(&mut *tx)
        .await
        .unwrap();

    sqlx::query(
        r#"
            INSERT INTO groups(group_id, group_name, delete_messages_after_milliseconds)
            VALUES ('widgets', 'Widgets', 7200000)
        "#,
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    for (id, sender, widget, at) in [
        ("received-widget-expired", Some(2_i64), true, 80000),
        ("sent-widget-expired", None, true, 80000),
        ("received-media-expired", Some(2), false, 80000),
        ("sent-widget-recent", None, true, 95000),
        ("received-widget-recent", Some(2), true, 95000),
    ] {
        sqlx::query(
            r#"
                INSERT INTO media_files(media_id, type, is_widget_media, download_state)
                VALUES (?, 'image', ?, 'ready')
            "#,
        )
        .bind(id)
        .bind(widget)
        .execute(&mut *tx)
        .await
        .unwrap();

        sqlx::query(
            r#"
                INSERT INTO messages(message_id, group_id, sender_id, type, media_id,
                    is_widget_media, opened_at, opened_by_all, created_at)
                VALUES (?, 'widgets', ?, 'media', ?, ?, ?, ?, ?)
            "#,
        )
        .bind(id)
        .bind(sender)
        .bind(id)
        .bind(widget)
        .bind(at)
        .bind(at)
        .bind(at)
        .execute(&mut *tx)
        .await
        .unwrap();
    }

    let mut query = input(MessageFilter::Page);

    query.group_id = Some("widgets".into());

    query.limit = 100;

    query.now_ms = 100000000;

    assert_eq!(
        queries::list(&mut tx, &query)
            .await
            .unwrap()
            .iter()
            .map(|row| row.message_id.as_str())
            .collect::<Vec<_>>(),
        vec!["received-widget-recent", "sent-widget-recent"]
    );

    writes::purge(&mut tx, query.now_ms).await.unwrap();

    let ids: Vec<String> =
        sqlx::query_scalar("SELECT message_id FROM messages ORDER BY message_id")
            .fetch_all(&mut *tx)
            .await
            .unwrap();

    assert_eq!(
        ids,
        vec![
            "received-widget-expired",
            "received-widget-recent",
            "sent-widget-recent"
        ]
    );

    assert_eq!(
        sqlx::query_scalar::<_, String>(
            "SELECT download_state FROM media_files WHERE media_id = 'received-widget-expired'"
        )
        .fetch_one(&mut *tx)
        .await
        .unwrap(),
        "ready"
    );

    tx.commit().await.unwrap();

    database.pool.close().await;
}

#[tokio::test]

async fn clearing_chat_preserves_only_one_time_app_state_and_updates() {
    let directory = tempfile::tempdir().unwrap();

    let database = open(directory.path().join("app.sqlite").to_str().unwrap()).await;

    let mut tx = database.pool.begin().await.unwrap();

    for statement in [
        "INSERT INTO groups(group_id, group_name) VALUES ('chat', 'Trip')",
        r#"
            INSERT INTO messages(message_id, group_id, type)
            VALUES ('text', 'chat', 'text'), ('expenses-card', 'chat', 'webxdcApp'), ('game-card', 'chat',
                'webxdcApp')
        "#,
        r#"
            INSERT INTO webxdc_apps(app_id, version, name, bundle_sha256, bundle_bytes, cached_at, one_time)
            VALUES ('expenses', 1, 'Expenses', 'expense-hash', 1, 0, 1), ('game', 1, 'Game', 'game-hash', 1, 0, 0)
        "#,
        r#"
            INSERT INTO webxdc_instances(instance_id, group_id, app_id, version, origin_token, created_at,
                last_update_at)
            VALUES ('expenses-card', 'chat', 'expenses', 1, 'expenses-origin', 0, 0), ('game-card', 'chat', 'game',
                1, 'game-origin', 0, 0)
        "#,
        r#"
            INSERT INTO webxdc_updates(instance_id, serial, message_id, payload, received_at)
            VALUES ('expenses-card', 1, 'expense-update', '{}', 0)
        "#,
    ] {
        sqlx::query(sqlx::AssertSqlSafe(statement))
            .execute(&mut *tx)
            .await
            .unwrap();
    }

    writes::clear_chat(&mut tx, "chat").await.unwrap();

    assert_eq!(
        sqlx::query_scalar::<_, String>("SELECT message_id FROM messages")
            .fetch_all(&mut *tx)
            .await
            .unwrap(),
        vec!["expenses-card"]
    );

    assert_eq!(
        sqlx::query_scalar::<_, String>("SELECT instance_id FROM webxdc_instances")
            .fetch_all(&mut *tx)
            .await
            .unwrap(),
        vec!["expenses-card"]
    );

    assert_eq!(
        sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM webxdc_updates")
            .fetch_one(&mut *tx)
            .await
            .unwrap(),
        1
    );

    assert!(
        crate::database::app::groups::queries::get(&mut tx, "chat")
            .await
            .unwrap()
            .unwrap()
            .deleted_content
    );

    tx.commit().await.unwrap();

    database.pool.close().await;
}

#[tokio::test]

async fn delivery_status_excludes_group_failures_but_keeps_recipient_details() {
    let directory = tempfile::tempdir().unwrap();

    let database = open(directory.path().join("app.sqlite").to_str().unwrap()).await;

    let mut tx = database.pool.begin().await.unwrap();

    for statement in [
        "INSERT INTO contacts(user_id, username) VALUES (7, 'recipient')",
        r#"
            INSERT INTO groups(group_id, group_name, is_direct_chat)
            VALUES ('direct', 'Direct', 1), ('group', 'Group', 0)
        "#,
        r#"
            INSERT INTO messages(message_id, group_id, type)
            VALUES ('direct', 'direct', 'media'), ('group', 'group', 'media')
        "#,
        r#"
            INSERT INTO message_actions(message_id, contact_id, type)
            VALUES ('direct', 7, 'sendFailed'), ('group', 7, 'sendFailed')
        "#,
    ] {
        sqlx::query(sqlx::AssertSqlSafe(statement))
            .execute(&mut *tx)
            .await
            .unwrap();
    }

    let actions = queries::delivery_actions(&mut tx, &["direct".into(), "group".into()])
        .await
        .unwrap();

    assert_eq!(
        actions
            .iter()
            .map(|row| row.message_id.as_str())
            .collect::<Vec<_>>(),
        vec!["direct"]
    );

    let details = queries::actions(&mut tx, "group").await.unwrap();

    assert_eq!(details.actions[0].r#type, "sendFailed");

    assert_eq!(details.contacts[0].user_id, 7);

    tx.commit().await.unwrap();

    database.pool.close().await;
}

#[tokio::test]

async fn patches_only_fire_sender_deletion_triggers_when_the_flag_is_present() {
    use crate::database::app::patch::NullableText;

    let directory = tempfile::tempdir().unwrap();

    let database = open(directory.path().join("app.sqlite").to_str().unwrap()).await;

    let mut tx = database.pool.begin().await.unwrap();

    seed(&mut tx).await;

    writes::update(
        &mut tx,
        "a",
        MessagePatch {
            is_deleted_from_sender: Some(true),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    sqlx::query!(
        r#"
            INSERT INTO notification_outbox (
                event_id, notification_id, sender_id, message_id, kind, created_at
            ) VALUES ('patch-trigger', 'patch-trigger', 7, 'a', 'message', 1)
        "#
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    writes::update(
        &mut tx,
        "a",
        MessagePatch {
            content: Some(NullableText {
                value: Some("updated".into()),
            }),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    writes::upsert(
        &mut tx,
        MessagePatch {
            group_id: Some("g".into()),
            message_id: Some("a".into()),
            r#type: Some("text".into()),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    assert_eq!(
        sqlx::query_scalar!(
            "SELECT COUNT(*) FROM notification_outbox WHERE event_id = 'patch-trigger' AND \
             cleared_at IS NULL"
        )
        .fetch_one(&mut *tx)
        .await
        .unwrap(),
        1
    );

    writes::update(
        &mut tx,
        "a",
        MessagePatch {
            is_deleted_from_sender: Some(true),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    assert_eq!(
        sqlx::query_scalar!(
            "SELECT COUNT(*) FROM notification_outbox WHERE event_id = 'patch-trigger' AND \
             cleared_at IS NOT NULL"
        )
        .fetch_one(&mut *tx)
        .await
        .unwrap(),
        1
    );

    tx.rollback().await.unwrap();

    database.pool.close().await;
}
