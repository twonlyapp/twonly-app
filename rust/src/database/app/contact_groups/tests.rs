use super::table::*;
use super::{queries, writes};
use crate::database::app::transaction::TransactionScope;
use crate::database::app::AppDatabase;
use std::sync::Arc;

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

    sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'alice'), (8, 'bob')")
        .execute(&database.pool)
        .await
        .unwrap();

    sqlx::query(
        r#"
        INSERT INTO groups(group_id, group_name, is_direct_chat)
        VALUES ('direct', 'Alice', 1),
            ('group', 'Friends', 0)
        "#,
    )
    .execute(&database.pool)
    .await
    .unwrap();

    {
        let _connection = database.pool.acquire().await.unwrap();
    }

    (directory, database)
}

fn input(name: &str) -> ContactGroupInput {
    ContactGroupInput {
        name: name.into(),
        emoji: Some(" ⭐ ".into()),
        text_color: 0xff000000,
        background_color: 0,
        show_as_shortcut: true,
        show_as_label: true,
        share_stories: false,
    }
}

async fn create(database: &AppDatabase, input: ContactGroupInput) -> i64 {
    let mut transaction = database.pool.begin().await.unwrap();

    let id = writes::create(&mut transaction, &input).await.unwrap();

    transaction.commit().await.unwrap();

    id
}

#[tokio::test]

async fn list_get_and_update_preserve_filters_styles_nulls_and_dates() {
    let (_directory, database) = open().await;

    let id = create(&database, input("  Favorites  ")).await;

    let original = queries::get(&mut database.pool.acquire().await.unwrap(), id)
        .await
        .unwrap()
        .unwrap();

    assert_eq!(original.name, "Favorites");

    assert_eq!(original.emoji.as_deref(), Some("⭐"));

    assert_eq!(original.text_color, 0xff000000);

    let mut changed = input("Z".repeat(30).as_str());

    changed.emoji = Some(" \u{feff} ".into());

    changed.show_as_shortcut = false;

    changed.share_stories = true;

    let mut transaction = database.pool.begin().await.unwrap();

    assert!(writes::update(&mut transaction, id, &changed)
        .await
        .unwrap());

    assert!(!writes::update(&mut transaction, -1, &changed)
        .await
        .unwrap());

    transaction.commit().await.unwrap();

    let mut connection = database.pool.acquire().await.unwrap();

    let group = queries::get(&mut connection, id).await.unwrap().unwrap();

    assert_eq!(group.name, "Z".repeat(24));

    assert_eq!(group.emoji, None);

    assert_eq!(group.created_at, original.created_at);

    assert!(queries::get(&mut connection, -1).await.unwrap().is_none());

    assert_eq!(
        queries::list(&mut connection, ContactGroupFilter::All, None, None)
            .await
            .unwrap(),
        vec![group.clone()]
    );

    assert!(
        queries::list(&mut connection, ContactGroupFilter::Shortcuts, None, None)
            .await
            .unwrap()
            .is_empty()
    );

    assert_eq!(
        queries::list(&mut connection, ContactGroupFilter::Stories, None, None)
            .await
            .unwrap(),
        vec![group]
    );

    assert!(
        queries::list(&mut connection, ContactGroupFilter::User, None, None)
            .await
            .is_err()
    );

    assert!(
        queries::list(&mut connection, ContactGroupFilter::Group, None, None)
            .await
            .is_err()
    );
}

#[tokio::test]

async fn membership_replacement_deduplicates_and_excludes_direct_and_missing_chats() {
    let (_directory, database) = open().await;

    let id = create(&database, input("Favorites")).await;

    let mut transaction = database.pool.begin().await.unwrap();

    writes::replace_members(
        &mut transaction,
        id,
        vec![7, 7, 8],
        vec![
            "direct".into(),
            "group".into(),
            "group".into(),
            "missing".into(),
        ],
    )
    .await
    .unwrap();

    transaction.commit().await.unwrap();

    let mut connection = database.pool.acquire().await.unwrap();

    let members = queries::members(&mut connection, id).await.unwrap();

    assert_eq!(members.len(), 3);

    assert_eq!(
        members.iter().filter_map(|m| m.user_id).collect::<Vec<_>>(),
        vec![7, 8]
    );

    assert_eq!(
        members
            .iter()
            .filter_map(|m| m.group_id.as_deref())
            .collect::<Vec<_>>(),
        vec!["group"]
    );

    assert_eq!(
        queries::membership_ids(&mut connection, Some(7), None)
            .await
            .unwrap(),
        vec![id]
    );

    assert_eq!(
        queries::membership_ids(&mut connection, None, Some("group"))
            .await
            .unwrap(),
        vec![id]
    );

    assert_eq!(
        queries::list(&mut connection, ContactGroupFilter::User, Some(7), None)
            .await
            .unwrap()
            .len(),
        1
    );

    assert_eq!(
        queries::list(
            &mut connection,
            ContactGroupFilter::Group,
            None,
            Some("group")
        )
        .await
        .unwrap()
        .len(),
        1
    );

    let labels = queries::labels(&mut connection, true).await.unwrap();

    assert_eq!(
        labels.groups.len(),
        1,
        "the group's style is transmitted only once"
    );

    assert_eq!(labels.members.len(), 2);

    assert_eq!(
        queries::labels(&mut connection, false)
            .await
            .unwrap()
            .members
            .len(),
        1
    );
}

#[tokio::test]

async fn failed_replacement_rolls_back_existing_members_and_emits_no_change() {
    let (_directory, database) = open().await;

    let id = create(&database, input("Favorites")).await;

    let mut transaction = database.pool.begin().await.unwrap();

    writes::set_user_membership(&mut transaction, id, 7, true)
        .await
        .unwrap();

    transaction.commit().await.unwrap();

    let original = queries::members(&mut database.pool.acquire().await.unwrap(), id)
        .await
        .unwrap();

    let mut changes = database.subscribe();

    let mut transaction = database.pool.begin().await.unwrap();

    assert!(
        writes::replace_members(&mut transaction, id, vec![8, 999], vec![])
            .await
            .is_err()
    );

    transaction.rollback().await.unwrap();

    assert_eq!(
        queries::members(&mut database.pool.acquire().await.unwrap(), id)
            .await
            .unwrap(),
        original
    );

    assert!(changes.try_recv().is_err());
}

#[tokio::test]

async fn toggles_visibility_usage_sorting_and_delete_cascades() {
    let (_directory, database) = open().await;

    let a = create(&database, input("A")).await;

    let b = create(&database, input("B")).await;

    let mut transaction = database.pool.begin().await.unwrap();

    writes::set_user_membership(&mut transaction, a, 7, true)
        .await
        .unwrap();

    writes::set_user_membership(&mut transaction, a, 7, false)
        .await
        .unwrap();

    writes::set_group_membership(&mut transaction, a, "direct", true)
        .await
        .unwrap();

    writes::set_group_membership(&mut transaction, a, "missing", true)
        .await
        .unwrap();

    writes::set_group_membership(&mut transaction, a, "group", true)
        .await
        .unwrap();

    writes::set_group_membership(&mut transaction, a, "group", false)
        .await
        .unwrap();

    writes::set_user_membership(&mut transaction, a, 8, true)
        .await
        .unwrap();

    writes::increment_usage(&mut transaction, b).await.unwrap();

    let mut hidden = input("A");

    hidden.show_as_label = false;

    writes::update(&mut transaction, a, &hidden).await.unwrap();

    transaction.commit().await.unwrap();

    {
        let mut connection = database.pool.acquire().await.unwrap();

        assert_eq!(queries::members(&mut connection, a).await.unwrap().len(), 1);

        assert!(queries::labels(&mut connection, true)
            .await
            .unwrap()
            .groups
            .is_empty());

        assert!(
            queries::list(&mut connection, ContactGroupFilter::User, Some(8), None)
                .await
                .unwrap()
                .is_empty()
        );

        assert_eq!(
            queries::list(&mut connection, ContactGroupFilter::Shortcuts, None, None)
                .await
                .unwrap()
                .iter()
                .map(|g| g.id)
                .collect::<Vec<_>>(),
            vec![b, a]
        );
    }

    let mut transaction = database.pool.begin().await.unwrap();

    assert_eq!(writes::delete(&mut transaction, a).await.unwrap(), 1);

    assert_eq!(writes::delete(&mut transaction, a).await.unwrap(), 0);

    transaction.commit().await.unwrap();

    assert!(
        queries::members(&mut database.pool.acquire().await.unwrap(), a)
            .await
            .unwrap()
            .is_empty()
    );
}

#[tokio::test]

async fn legacy_transaction_excludes_native_jobs_and_cannot_lose_their_writes_on_rollback() {
    let (_directory, database) = open().await;

    let database = Arc::new(database);

    let transaction = TransactionScope::begin(&database.pool).await.unwrap();

    transaction
        .execute(
            "INSERT INTO app_metadata(key, value) VALUES ('legacy', 'discard')".into(),
            vec![],
        )
        .await
        .unwrap();

    assert!(database.pool.try_acquire().is_none());

    let native = database.clone();

    let job = tokio::spawn(async move { create(&native, input("Native")).await });

    transaction.rollback().await.unwrap();

    let id = tokio::time::timeout(std::time::Duration::from_secs(2), job)
        .await
        .unwrap()
        .unwrap();

    assert_eq!(
        queries::get(&mut database.pool.acquire().await.unwrap(), id)
            .await
            .unwrap()
            .unwrap()
            .name,
        "Native"
    );

    assert_eq!(
        sqlx::query_scalar::<_, i64>("SELECT count(*) FROM app_metadata WHERE key = 'legacy'")
            .fetch_one(&database.pool)
            .await
            .unwrap(),
        0
    );

    assert!(transaction.select("SELECT 1".into(), vec![]).await.is_err());
}

#[tokio::test]

async fn utf16_name_limit_never_splits_an_emoji() {
    let (_directory, database) = open().await;

    let id = create(&database, input(&format!("{}🌱", "a".repeat(23)))).await;

    assert_eq!(
        queries::get(&mut database.pool.acquire().await.unwrap(), id)
            .await
            .unwrap()
            .unwrap()
            .name,
        "a".repeat(23)
    );
}

#[tokio::test]

async fn dropped_legacy_handle_rolls_back_and_deferred_commit_failure_never_notifies() {
    let (_directory, database) = open().await;

    assert!(database
        .raw_execute("BEGIN TRANSACTION".into(), vec![])
        .await
        .is_err());

    {
        let transaction = TransactionScope::begin(&database.pool).await.unwrap();

        transaction
            .execute(
                "INSERT INTO app_metadata(key, value) VALUES ('dropped', '1')".into(),
                vec![],
            )
            .await
            .unwrap();
    }

    assert_eq!(
        sqlx::query_scalar::<_, i64>("SELECT count(*) FROM app_metadata WHERE key = 'dropped'")
            .fetch_one(&database.pool)
            .await
            .unwrap(),
        0
    );

    let mut transaction = database.pool.begin().await.unwrap();

    let mut changes = database.subscribe();

    sqlx::query("PRAGMA defer_foreign_keys = ON")
        .execute(&mut *transaction)
        .await
        .unwrap();

    sqlx::query("INSERT INTO contact_group_members(contact_group_id, user_id) VALUES (999, 7)")
        .execute(&mut *transaction)
        .await
        .unwrap();

    assert!(transaction.commit().await.is_err());

    let _connection = database.pool.acquire().await.unwrap();

    assert!(changes.try_recv().is_err());
}

#[tokio::test]

async fn watched_snapshot_tracks_commits_suppresses_equal_results_and_cancels_while_quiet() {
    use std::time::Duration;
    use tokio::sync::{mpsc, RwLock};
    use tokio_util::sync::CancellationToken;

    let (_directory, database) = open().await;

    let database = Arc::new(database);

    let databases = Arc::new(RwLock::new(database.clone()));

    let cancellation = CancellationToken::new();

    let (sender, mut receiver) = mpsc::unbounded_channel();

    let (evaluated, mut evaluations) = mpsc::unbounded_channel();

    let task_cancel = cancellation.clone();

    let task = tokio::spawn(async move {
        crate::database::app::watch::snapshots(
            databases,
            &["contact_groups"],
            task_cancel,
            move |database| {
                let evaluated = evaluated.clone();

                async move {
                    let result = queries::list(
                        &mut *database.pool.acquire().await?,
                        ContactGroupFilter::All,
                        None,
                        None,
                    )
                    .await;

                    evaluated.send(()).unwrap();

                    result
                }
            },
            move |value| sender.send(value).is_ok(),
        )
        .await
    });

    assert!(
        tokio::time::timeout(Duration::from_secs(2), receiver.recv())
            .await
            .unwrap()
            .unwrap()
            .is_empty()
    );

    evaluations.recv().await.unwrap();

    let id = create(&database, input("Live")).await;

    assert_eq!(
        tokio::time::timeout(Duration::from_secs(2), receiver.recv())
            .await
            .unwrap()
            .unwrap()[0]
            .id,
        id
    );

    evaluations.recv().await.unwrap();

    let mut transaction = database.pool.begin().await.unwrap();

    writes::update(&mut transaction, id, &input("Live"))
        .await
        .unwrap();

    transaction.commit().await.unwrap();

    tokio::time::timeout(Duration::from_secs(2), evaluations.recv())
        .await
        .unwrap()
        .unwrap();

    // Cancellation joins the watch, so result comparison/possible emission has
    // finished before testing that the unchanged result was suppressed.
    cancellation.cancel();

    tokio::time::timeout(Duration::from_secs(2), task)
        .await
        .unwrap()
        .unwrap()
        .unwrap();

    assert!(receiver.try_recv().is_err());
}

#[tokio::test]

async fn watch_rebinds_after_database_replacement_without_holding_old_handles() {
    use std::time::Duration;
    use tokio::sync::{mpsc, RwLock};
    use tokio_util::sync::CancellationToken;

    let (_directory, database) = open().await;

    let (_replacement_dir, replacement) = open().await;

    let id = create(&replacement, input("Restored")).await;

    let databases = Arc::new(RwLock::new(Arc::new(database)));

    let cancellation = CancellationToken::new();

    let (sender, mut receiver) = mpsc::unbounded_channel();

    let task = tokio::spawn(super::watches::groups(
        databases.clone(),
        ContactGroupFilter::All,
        None,
        None,
        cancellation.clone(),
        move |value| sender.send(value).is_ok(),
    ));

    assert!(
        tokio::time::timeout(Duration::from_secs(2), receiver.recv())
            .await
            .unwrap()
            .unwrap()
            .is_empty()
    );

    let original = databases.read().await.clone();

    tokio::time::timeout(Duration::from_secs(2), original.pool.close())
        .await
        .unwrap();

    *databases.write().await = Arc::new(replacement);

    assert_eq!(
        tokio::time::timeout(Duration::from_secs(2), receiver.recv())
            .await
            .unwrap()
            .unwrap()[0]
            .id,
        id
    );

    cancellation.cancel();

    task.await.unwrap().unwrap();
}

#[tokio::test]

async fn rust_queries_match_the_shared_legacy_drift_contract() {
    let expected: serde_json::Value = serde_json::from_str(include_str!(
        "../../../../tests/fixtures/contact_groups_parity.json"
    ))
    .unwrap();

    let (_directory, database) = open().await;

    for label in [" Beta ", "Alpha", "Hidden"] {
        let mut value = input(label);

        value.show_as_shortcut = label != "Hidden";

        value.show_as_label = label != "Hidden";

        value.share_stories = label == "Alpha";

        create(&database, value).await;
    }

    let mut transaction = database.pool.begin().await.unwrap();

    sqlx::query("UPDATE contact_groups SET created_at = 1700000000")
        .execute(&mut *transaction)
        .await
        .unwrap();

    writes::replace_members(
        &mut transaction,
        1,
        vec![7, 7, 8],
        vec![
            "direct".into(),
            "group".into(),
            "group".into(),
            "missing".into(),
        ],
    )
    .await
    .unwrap();

    writes::set_user_membership(&mut transaction, 2, 7, true)
        .await
        .unwrap();

    writes::set_group_membership(&mut transaction, 2, "group", true)
        .await
        .unwrap();

    writes::increment_usage(&mut transaction, 1).await.unwrap();

    writes::increment_usage(&mut transaction, 1).await.unwrap();

    let mut value = input("Beta");

    value.emoji = Some(" ".into());

    value.share_stories = true;

    writes::update(&mut transaction, 1, &value).await.unwrap();

    transaction.commit().await.unwrap();

    let mut connection = database.pool.acquire().await.unwrap();

    for (filter, user, chat, key) in [
        (ContactGroupFilter::All, None, None, "all_ids"),
        (ContactGroupFilter::Shortcuts, None, None, "shortcut_ids"),
        (ContactGroupFilter::Stories, None, None, "story_ids"),
        (ContactGroupFilter::User, Some(7), None, "user_7_ids"),
        (ContactGroupFilter::Group, None, Some("group"), "chat_ids"),
    ] {
        let ids: Vec<_> = queries::list(&mut connection, filter, user, chat)
            .await
            .unwrap()
            .into_iter()
            .map(|g| g.id)
            .collect();

        assert_eq!(serde_json::json!(ids), expected[key], "{key}");
    }

    for for_users in [false, true] {
        let mut links: Vec<_> = queries::labels(&mut connection, for_users)
            .await
            .unwrap()
            .members
            .into_iter()
            .map(|member| {
                format!(
                    "{}:{}",
                    member.contact_group_id,
                    member
                        .user_id
                        .map(|id| id.to_string())
                        .unwrap_or_else(|| member.group_id.unwrap())
                )
            })
            .collect();

        links.sort();

        assert_eq!(
            serde_json::json!(links),
            expected[if for_users {
                "visible_user_links"
            } else {
                "visible_chat_links"
            }]
        );
    }

    let mut members: Vec<_> = queries::members(&mut connection, 1)
        .await
        .unwrap()
        .into_iter()
        .map(|member| {
            member
                .user_id
                .map(|id| format!("user:{id}"))
                .unwrap_or_else(|| format!("group:{}", member.group_id.unwrap()))
        })
        .collect();

    members.sort();

    assert_eq!(serde_json::json!(members), expected["member_targets"]);

    let group = queries::get(&mut connection, 1).await.unwrap().unwrap();

    assert_eq!(
        serde_json::json!({
            "id": group.id, "name": group.name, "emoji": group.emoji, "text_color": group.text_color,
            "background_color": group.background_color, "show_as_shortcut": group.show_as_shortcut,
            "show_as_label": group.show_as_label, "share_stories": group.share_stories,
            "usage_counter": group.usage_counter, "created_at": group.created_at,
        }),
        expected["group"]
    );
}
