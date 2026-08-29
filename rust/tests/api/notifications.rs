//! Integration coverage for the native notification path.
//!
//! Messages travel through the real dev server, are decrypted and committed by
//! the normal incoming pipeline, and are then asserted through the exact
//! `services::notifications` API that the iOS Notification Service Extension
//! and the Android WorkManager job call. Nothing here writes outbox rows by
//! hand, so classification, deduplication, claiming and clearing are all
//! exercised end to end.

use crate::{init_tracing, Tester};
use rust_lib_twonly::bridge::api::ApiConnectionState;
use rust_lib_twonly::database::app::tables::Group;
use rust_lib_twonly::services::contacts::ContactService;
use rust_lib_twonly::services::groups::GroupService;
use rust_lib_twonly::services::messages::MessageService;

async fn ready_tester() -> anyhow::Result<Tester> {
    let mut tester = Tester::new().await?;
    tester.wait_until(ApiConnectionState::Connected).await?;
    tester.register_and_authenticate().await?;
    tester.wait_until(ApiConnectionState::Authenticated).await?;
    Ok(tester)
}

#[tokio::test]
async fn test_notification_outbox_end_to_end() -> anyhow::Result<()> {
    init_tracing();

    let mut tester_a = ready_tester().await?;
    let tester_b = ready_tester().await?;
    tracing::info!(
        a = tester_a.user_id,
        b = tester_b.user_id,
        "Notification testers are ready"
    );

    let group_id = Group::direct_chat_id(tester_a.user_id, tester_b.user_id);

    //
    // Contact requests are user visible, so they must reach the outbox before
    // any message has been exchanged.
    //
    {
        ContactService::new(&tester_a.context)
            .request_by_username(tester_b.username.clone(), true)
            .await?;

        let request = tester_b
            .wait_for_notification("contact_request", tester_a.user_id)
            .await?;
        assert_eq!(request.title, tester_a.username);
        assert_eq!(request.body, "wants to connect with you.");
        assert_eq!(request.sender_name, tester_a.username);
        assert!(!request.is_group);
        assert!(request.message_id.is_none());
        // No avatar has been shared yet, so the native layer must fall back to
        // a notification without an image instead of failing.
        assert!(request.avatar_path.is_none());

        ContactService::new(&tester_b.context)
            .accept_request(tester_a.user_id, true)
            .await?;
        let accepted = tester_a
            .wait_for_notification("accept_request", tester_b.user_id)
            .await?;
        assert_eq!(accepted.body, "is now connected with you.");

        tester_a
            .wait_for_contact_state(tester_b.user_id, true, false)
            .await?;
    }

    //
    // Claiming a batch: acknowledgement removes rows from the pending set but
    // leaves the badge alone, and repeating it is a no-op. Duplicate FCM
    // deliveries rely on both properties.
    //
    {
        let batch = tester_b.notification_batch("en").await?;
        assert!(!batch.additions.is_empty());
        let badge_before = batch.badge_count;
        assert_eq!(
            badge_before,
            batch.additions.len() as i64,
            "every pending event counts toward the badge"
        );

        let event_ids: Vec<String> = batch
            .additions
            .iter()
            .map(|addition| addition.event_id.clone())
            .collect();
        tester_b.acknowledge_notifications(&event_ids).await?;

        let after = tester_b.notification_batch("en").await?;
        assert!(
            after.additions.is_empty(),
            "acknowledged events must not be offered again"
        );
        assert_eq!(
            after.badge_count, badge_before,
            "delivery is not the same as the user having read the message"
        );

        // Acknowledging the same batch twice happens whenever the native layer
        // is killed between scheduling and acknowledging.
        tester_b.acknowledge_notifications(&event_ids).await?;
        assert!(tester_b
            .notification_batch("en")
            .await?
            .additions
            .is_empty());
        tester_b.acknowledge_notifications(&[]).await?;
    }

    //
    // A plain text message, and the stable identifiers the native layer needs
    // to make retries idempotent.
    //
    let first_message_id = {
        let message_id = MessageService::new(&tester_a.context)
            .insert_and_send_text(group_id.clone(), "Notify me".into(), None)
            .await?;

        let text = tester_b
            .wait_for_notification("text", tester_a.user_id)
            .await?;
        assert_eq!(text.body, "sent a message.");
        assert_eq!(text.message_id.as_deref(), Some(message_id.as_str()));
        assert_eq!(
            text.notification_id, message_id,
            "the notification id must be derived from the message so a redelivery replaces it"
        );
        assert_eq!(text.conversation_id.as_deref(), Some(group_id.as_str()));
        assert!(
            !text.is_group,
            "a direct chat must not be rendered as a group"
        );

        // The envelope produced exactly one outbox row; a redelivered receipt
        // is ignored by the primary key.
        assert_eq!(
            tester_b.notification_rows_for_event(&text.event_id).await?,
            1
        );

        tester_b
            .acknowledge_notifications(&[text.event_id.clone()])
            .await?;
        message_id
    };

    //
    // If the foreground chat opens a message before (or after) the native
    // worker runs, that message must disappear from the durable batch and the
    // badge. Its stable notification id lets the platform also withdraw an
    // alert that was already displayed.
    //
    {
        let message_id = MessageService::new(&tester_a.context)
            .insert_and_send_text(group_id.clone(), "Open before alert".into(), None)
            .await?;
        let notification = tester_b
            .wait_for_notification("text", tester_a.user_id)
            .await?;
        assert_eq!(notification.notification_id, message_id);
        let badge_before = tester_b.notification_batch("en").await?.badge_count;

        MessageService::new(&tester_b.context)
            .notify_opened(tester_a.user_id, vec![message_id.clone()])
            .await?;

        let after = tester_b.notification_batch("en").await?;
        assert!(
            after
                .additions
                .iter()
                .all(|addition| addition.message_id.as_deref() != Some(message_id.as_str())),
            "an opened message must not be rendered as a notification"
        );
        assert_eq!(
            after.badge_count,
            badge_before - 1,
            "opening a message must reduce the notification badge"
        );
    }

    //
    // Localization is owned by Rust: the same row renders in the caller's
    // language, and an unsupported locale falls back to English.
    //
    {
        MessageService::new(&tester_a.context)
            .insert_and_send_text(group_id.clone(), "Zweite Nachricht".into(), None)
            .await?;
        let pending = tester_b
            .wait_for_notification("text", tester_a.user_id)
            .await?;

        let german = tester_b.notification_batch("de-DE").await?;
        let german = german
            .additions
            .iter()
            .find(|addition| addition.event_id == pending.event_id)
            .expect("the pending event is rendered in every locale");
        assert_eq!(german.body, "hat eine Nachricht gesendet.");

        let unsupported = tester_b.notification_batch("fr").await?;
        let unsupported = unsupported
            .additions
            .iter()
            .find(|addition| addition.event_id == pending.event_id)
            .expect("an unsupported locale still yields a notification");
        assert_eq!(unsupported.body, "sent a message.");

        tester_b
            .acknowledge_notifications(&[pending.event_id.clone()])
            .await?;
    }

    //
    // Once the sender has shared an avatar, Rust rasterizes it and hands the
    // native layer a real file instead of a callback into Flutter.
    //
    {
        tester_a.update_profile(
            None,
            Some("Alice Notify".into()),
            Some("<svg height='100' width='100'><circle cx='50' cy='50' r='40'/></svg>".into()),
        )?;
        MessageService::new(&tester_a.context)
            .insert_and_send_text(group_id.clone(), "Now with avatar".into(), None)
            .await?;
        tester_b
            .wait_for_contact_avatar_exists(tester_a.user_id)
            .await?;
        tester_b
            .wait_for_contact_display_name(tester_a.user_id, "Alice Notify")
            .await?;

        // The avatar is resolved when the batch is read, so it also decorates
        // events that were recorded before the profile arrived.
        let mut with_avatar = None;
        for _ in 0..100 {
            let batch = tester_b.notification_batch("en").await?;
            if let Some(addition) = batch
                .additions
                .into_iter()
                .find(|addition| addition.sender_id == tester_a.user_id)
            {
                if addition.avatar_path.is_some() {
                    with_avatar = Some(addition);
                    break;
                }
            }
            tokio::time::sleep(std::time::Duration::from_millis(100)).await;
        }
        let with_avatar = with_avatar.expect("a shared avatar must reach the notification batch");
        assert_eq!(with_avatar.title, "Alice Notify");
        let avatar_path = with_avatar.avatar_path.clone().unwrap();
        assert!(
            std::path::Path::new(&avatar_path).is_file(),
            "the rendered avatar must exist on disk at {avatar_path}"
        );

        tester_b
            .acknowledge_notifications(&[with_avatar.event_id.clone()])
            .await?;
    }

    //
    // Classification: a quoted reply and a reaction must not read like a plain
    // message, and the reaction body carries the emoji.
    //
    {
        MessageService::new(&tester_a.context)
            .insert_and_send_text(
                group_id.clone(),
                "Quoting you".into(),
                Some(first_message_id.clone()),
            )
            .await?;
        let reply = tester_b
            .wait_for_notification("response", tester_a.user_id)
            .await?;
        assert_eq!(reply.body, "has responded.");
        tester_b
            .acknowledge_notifications(&[reply.event_id.clone()])
            .await?;

        // B owns a message that A can react to.
        let owned_by_b = MessageService::new(&tester_b.context)
            .insert_and_send_text(group_id.clone(), "React to this".into(), None)
            .await?;
        tester_a
            .wait_for_text_message(&owned_by_b, tester_b.user_id, "React to this")
            .await?;
        tester_a
            .acknowledge_notifications(
                &tester_a
                    .notification_batch("en")
                    .await?
                    .additions
                    .iter()
                    .map(|addition| addition.event_id.clone())
                    .collect::<Vec<_>>(),
            )
            .await?;

        MessageService::new(&tester_a.context)
            .react(group_id.clone(), owned_by_b.clone(), "👍".into(), false)
            .await?;
        let reaction = tester_b
            .wait_for_notification("reaction", tester_a.user_id)
            .await?;
        assert_eq!(reaction.body, "has reacted with 👍 to your message.");
        assert_eq!(reaction.message_id.as_deref(), Some(owned_by_b.as_str()));
        tester_b
            .acknowledge_notifications(&[reaction.event_id.clone()])
            .await?;

        // Removing a reaction is not user visible and must stay silent.
        MessageService::new(&tester_a.context)
            .react(group_id.clone(), owned_by_b.clone(), "👍".into(), true)
            .await?;
        tester_b
            .wait_for_reaction_deleted(&owned_by_b, tester_a.user_id, "👍")
            .await?;
        MessageService::new(&tester_a.context)
            .insert_and_send_text(group_id.clone(), "After the removal".into(), None)
            .await?;
        let next = tester_b
            .wait_for_notification("text", tester_a.user_id)
            .await?;
        let pending_kinds: Vec<String> = tester_b
            .notification_batch("en")
            .await?
            .additions
            .into_iter()
            .map(|addition| addition.kind)
            .collect();
        assert!(
            !pending_kinds.contains(&"reaction".to_owned()),
            "removing a reaction must not raise a notification, got {pending_kinds:?}"
        );
        tester_b
            .acknowledge_notifications(&[next.event_id.clone()])
            .await?;
    }

    //
    // Group messages carry the conversation name so the native layer can render
    // "sent a message in <group>".
    //
    let group_conversation_id = {
        let group_name = "Notify Group";
        GroupService::new(&tester_a.context)
            .create_group(group_name.into(), vec![tester_b.user_id])
            .await?;
        let group_conversation_id = {
            let database = tester_a.context.app_db.read().await.clone();
            sqlx::query_scalar!(
                "SELECT group_id FROM groups WHERE is_direct_chat = 0 ORDER BY rowid DESC LIMIT 1"
            )
            .fetch_one(&database.pool)
            .await?
        };
        tester_b
            .wait_for_group_exists(&group_conversation_id, group_name)
            .await?;

        let added = tester_b
            .wait_for_notification("added_to_group", tester_a.user_id)
            .await?;
        assert_eq!(added.body, format!("has added you to \"{group_name}\""));

        MessageService::new(&tester_a.context)
            .insert_and_send_text(group_conversation_id.clone(), "Hello group".into(), None)
            .await?;
        let group_text = tester_b
            .wait_for_notification("text", tester_a.user_id)
            .await?;
        assert_eq!(group_text.body, format!("sent a message in {group_name}."));
        assert!(group_text.is_group);
        assert_eq!(
            group_text.conversation_id.as_deref(),
            Some(group_conversation_id.as_str())
        );
        assert_eq!(group_text.conversation_name.as_deref(), Some(group_name));

        group_conversation_id
    };

    //
    // Opening a conversation clears it: the native layer is told which
    // notifications to withdraw, and the badge drops.
    //
    {
        let before = tester_b.notification_batch("en").await?;
        let group_events: Vec<String> = before
            .additions
            .iter()
            .filter(|addition| addition.conversation_id.as_deref() == Some(&group_conversation_id))
            .map(|addition| addition.notification_id.clone())
            .collect();
        assert!(
            !group_events.is_empty(),
            "the group conversation must have pending notifications to clear"
        );

        let removed = tester_b
            .clear_notification_conversation(&group_conversation_id)
            .await?;
        for notification_id in &group_events {
            assert!(
                removed.contains(notification_id),
                "cleared conversation must report {notification_id} for withdrawal"
            );
        }

        let after = tester_b.notification_batch("en").await?;
        assert!(
            after
                .additions
                .iter()
                .all(|addition| addition.conversation_id.as_deref()
                    != Some(&group_conversation_id)),
            "a cleared conversation must not be offered again"
        );
        assert_eq!(
            after.badge_count,
            before.badge_count - removed.len() as i64,
            "clearing a conversation must reduce the badge"
        );

        // Clearing twice must not report the same notifications again.
        assert!(tester_b
            .clear_notification_conversation(&group_conversation_id)
            .await?
            .is_empty());
    }

    //
    // A blocked contact is still decrypted and committed, but must never
    // produce a notification.
    //
    {
        let acknowledge: Vec<String> = tester_b
            .notification_batch("en")
            .await?
            .additions
            .iter()
            .map(|addition| addition.event_id.clone())
            .collect();
        tester_b.acknowledge_notifications(&acknowledge).await?;
        let badge_before = tester_b.notification_batch("en").await?.badge_count;

        tester_b.set_contact_blocked(tester_a.user_id, true).await?;

        let blocked_message_id = MessageService::new(&tester_a.context)
            .insert_and_send_text(group_id.clone(), "You blocked me".into(), None)
            .await?;
        tester_b
            .wait_for_text_message(&blocked_message_id, tester_a.user_id, "You blocked me")
            .await?;

        assert_eq!(
            tester_b
                .notification_rows_for_message(&blocked_message_id)
                .await?,
            0,
            "a blocked contact must not reach the notification outbox"
        );
        let after = tester_b.notification_batch("en").await?;
        assert!(after.additions.is_empty());
        assert_eq!(after.badge_count, badge_before);

        // Unblocking restores notifications for later messages.
        tester_b
            .set_contact_blocked(tester_a.user_id, false)
            .await?;
        let unblocked_message_id = MessageService::new(&tester_a.context)
            .insert_and_send_text(group_id.clone(), "Unblocked again".into(), None)
            .await?;
        let unblocked = tester_b
            .wait_for_notification("text", tester_a.user_id)
            .await?;
        assert_eq!(
            unblocked.message_id.as_deref(),
            Some(unblocked_message_id.as_str())
        );
    }

    Ok(())
}
