use super::{init_tracing, Tester};
use prost::Message as _;
use rust_lib_twonly::api::messages::outgoing::send_c2c_message_to_contact;
use rust_lib_twonly::api::proto::client::{encrypted_content, EncryptedContent};
use rust_lib_twonly::bridge::api::ApiConnectionState;
use rust_lib_twonly::database::app::tables::Group;
use rust_lib_twonly::services::contacts::ContactService;
use rust_lib_twonly::services::media_upload::MediaUploadService;
use rust_lib_twonly::services::messages::MessageService;
use rust_lib_twonly::services::stories::{self, StoryAudience, STORY_LIFETIME_SECONDS};
use tokio::time::{sleep, Duration};

async fn create_authenticated_tester() -> anyhow::Result<Tester> {
    let mut tester = Tester::new().await?;
    tester.wait_until(ApiConnectionState::Connected).await?;
    tester.register_and_authenticate().await?;
    tester.wait_until(ApiConnectionState::Authenticated).await?;
    Ok(tester)
}

async fn connect(requester: &Tester, accepter: &Tester) -> anyhow::Result<()> {
    ContactService::new(&requester.context)
        .request_by_username(accepter.username.clone(), true)
        .await?;
    accepter
        .wait_for_contact_state(requester.user_id, false, true)
        .await?;
    ContactService::new(&accepter.context)
        .accept_request(requester.user_id, true)
        .await?;
    requester
        .wait_for_contact_state(accepter.user_id, true, false)
        .await?;
    Ok(())
}

async fn scalar(tester: &Tester, sql: &str, bind: &str) -> anyhow::Result<i64> {
    let database = tester.context.app_db.read().await.clone();
    Ok(
        sqlx::query_scalar::<_, i64>(sqlx::AssertSqlSafe(sql.to_owned()))
            .bind(bind)
            .fetch_one(&database.pool)
            .await?,
    )
}

/// Polls until `sql` (with one bound value) returns something other than 0.
async fn wait_for(tester: &Tester, what: &str, sql: &str, bind: &str) -> anyhow::Result<()> {
    for _ in 0..100 {
        if scalar(tester, sql, bind).await? != 0 {
            return Ok(());
        }
        sleep(Duration::from_millis(100)).await;
    }
    Err(anyhow::anyhow!("{what} did not happen"))
}

/// Files a story row for `recipient` on `sender`, as `insert_into_messages`
/// does, and sends the envelope `prepare_media` builds for it. Only the
/// envelope travels: on this host a media upload stops before the native
/// transfer, so the attachment itself never reaches the server.
async fn post_story(
    sender: &Tester,
    recipient: &Tester,
    message_id: &str,
    media_id: &str,
    posted_at: i64,
    notify: bool,
) -> anyhow::Result<()> {
    let group_id = Group::direct_chat_id(sender.user_id, recipient.user_id);
    {
        let database = sender.context.app_db.read().await.clone();
        sqlx::query(
            "INSERT OR IGNORE INTO media_files(media_id, type, upload_state) VALUES (?, 'image', 'uploaded')",
        )
        .bind(media_id)
        .execute(&database.pool)
        .await?;
        sqlx::query(
            "INSERT INTO messages(group_id, message_id, type, media_id, is_story, created_at) VALUES (?, ?, 'media', ?, 1, ?)",
        )
        .bind(&group_id)
        .bind(message_id)
        .bind(media_id)
        .bind(posted_at)
        .execute(&database.pool)
        .await?;
    }
    let content = EncryptedContent {
        story: Some(encrypted_content::Story {
            media: Some(encrypted_content::Media {
                sender_message_id: message_id.to_owned(),
                r#type: encrypted_content::media::Type::Image as i32,
                timestamp: posted_at * 1_000,
                download_token: Some(vec![1; 32]),
                encryption_key: Some(vec![2; 32]),
                encryption_mac: Some(vec![3; 16]),
                encryption_nonce: Some(vec![4; 12]),
                ..Default::default()
            }),
            notify,
        }),
        ..Default::default()
    };
    send_c2c_message_to_contact()
        .ctx(&sender.context)
        .contact_id(recipient.user_id)
        .encrypted_content(content.encode_to_vec())
        .message_id(message_id.to_owned())
        .call()
        .await?;
    Ok(())
}

const STORY_ROW: &str = "SELECT COUNT(*) FROM messages WHERE message_id = ? AND is_story = 1";
const STORY_OUTBOX: &str =
    "SELECT COUNT(*) FROM notification_outbox WHERE kind = 'story' AND message_id = ?";

/// A posts to B and to C, who muted story notifications. Everything below
/// crosses the dev server between three real clients.
#[tokio::test]
async fn test_story_lifecycle_between_clients() -> anyhow::Result<()> {
    init_tracing();

    let tester_a = create_authenticated_tester().await?;
    let tester_b = create_authenticated_tester().await?;
    let tester_c = create_authenticated_tester().await?;
    tester_c.set_story_notifications(false)?;
    connect(&tester_a, &tester_b).await?;
    connect(&tester_a, &tester_c).await?;
    let chat_ab = Group::direct_chat_id(tester_a.user_id, tester_b.user_id);
    let chat_ac = Group::direct_chat_id(tester_a.user_id, tester_c.user_id);

    //
    // 1. The real send path: "All" becomes one hidden row per contact, and
    //    preparation encrypts one envelope per recipient.
    //
    let uploads = MediaUploadService::new(&tester_a.context);
    let media_id = uploads.initialize("image".into(), None, false).await?;
    let plaintext_path = std::path::PathBuf::from(&tester_a.context.config.data_dir)
        .join("mediafiles/tmp")
        .join(format!("{media_id}.webp"));
    std::fs::create_dir_all(plaintext_path.parent().expect("tmp directory"))?;
    let source = image::RgbImage::from_pixel(8, 6, image::Rgb([12, 34, 56]));
    let plaintext = webp::Encoder::from_rgb(source.as_raw(), source.width(), source.height())
        .encode_simple(false, 80.0)
        .map_err(|error| anyhow::anyhow!("could not encode media fixture: {error:?}"))?;
    std::fs::write(&plaintext_path, plaintext.as_ref())?;

    let all = StoryAudience {
        all: true,
        contact_group_ids: Vec::new(),
    };
    // A widget send cannot also be a story.
    assert!(uploads
        .insert_into_messages(media_id.clone(), Vec::new(), None, true, Some(all.clone()))
        .await
        .is_err());
    uploads
        .insert_into_messages(media_id.clone(), Vec::new(), None, false, Some(all))
        .await?;
    {
        let database = tester_a.context.app_db.read().await.clone();
        let mut groups: Vec<String> = sqlx::query_scalar(
            "SELECT group_id FROM messages WHERE media_id = ? AND is_story = 1 AND sender_id IS NULL",
        )
        .bind(&media_id)
        .fetch_all(&database.pool)
        .await?;
        groups.sort();
        let mut expected = vec![chat_ab.clone(), chat_ac.clone()];
        expected.sort();
        assert_eq!(groups, expected, "one hidden story row per contact");
    }
    tester_a.wait_for_media_encryption_mac(&media_id).await?;
    wait_for(
        &tester_a,
        "an envelope for every story recipient",
        "SELECT COUNT(*) = 2 FROM receipts r JOIN messages m ON m.message_id = r.message_id
         WHERE m.media_id = ? AND r.will_be_retried_by_media_upload = 1",
        &media_id,
    )
    .await?;
    tester_a.wait_for_no_pending_upload_jobs().await?;
    // Still uploading, so it cannot be taken down yet.
    assert!(stories::delete_item(&tester_a.context, &media_id)
        .await
        .is_err());

    //
    // 2. A story is announced only between people who wrote to each other
    //    in the last two weeks. A and B have not yet: filed, not announced.
    //
    let now = chrono::Utc::now().timestamp();
    post_story(&tester_a, &tester_b, "s-quiet-b", "s-quiet", now, true).await?;
    wait_for(
        &tester_b,
        "the quiet story to be filed",
        STORY_ROW,
        "s-quiet-b",
    )
    .await?;
    assert_eq!(scalar(&tester_b, STORY_OUTBOX, "s-quiet-b").await?, 0);

    // One text is enough; C, who muted stories, gets one as well.
    for (recipient, text) in [(&tester_b, "hi b"), (&tester_c, "hi c")] {
        let chat = Group::direct_chat_id(tester_a.user_id, recipient.user_id);
        let text_id = MessageService::new(&tester_a.context)
            .insert_and_send_text(chat, text.into(), None, None)
            .await?;
        recipient
            .wait_for_text_message(&text_id, tester_a.user_id, text)
            .await?;
    }

    //
    // 3. Only the item the sender woke for is announced, and a muted
    //    receiver files stories without announcing any.
    //
    for (recipient, suffix) in [(&tester_b, "b"), (&tester_c, "c")] {
        post_story(
            &tester_a,
            recipient,
            &format!("s1-{suffix}"),
            "s1",
            now,
            true,
        )
        .await?;
        post_story(
            &tester_a,
            recipient,
            &format!("s2-{suffix}"),
            "s2",
            now,
            false,
        )
        .await?;
    }
    for (recipient, suffix) in [(&tester_b, "b"), (&tester_c, "c")] {
        for item in ["s1", "s2"] {
            let message_id = format!("{item}-{suffix}");
            wait_for(recipient, "the story to be filed", STORY_ROW, &message_id).await?;
        }
    }
    tester_b
        .wait_for_notification("story", tester_a.user_id)
        .await?;
    assert_eq!(scalar(&tester_b, STORY_OUTBOX, "s1-b").await?, 1);
    assert_eq!(scalar(&tester_b, STORY_OUTBOX, "s2-b").await?, 0);
    assert_eq!(scalar(&tester_c, STORY_OUTBOX, "s1-c").await?, 0);
    // Filed under the direct chat, and not part of it.
    assert_eq!(
        scalar(
            &tester_b,
            "SELECT COUNT(*) FROM messages WHERE group_id = ? AND is_story = 1",
            &chat_ab
        )
        .await?,
        3
    );

    //
    // 4. A story that arrives after its 24 hours is ignored without a receipt;
    //    the sender's purge is what stops it being retried.
    //
    let expired = now - STORY_LIFETIME_SECONDS - 60;
    post_story(&tester_a, &tester_b, "s0-b", "s0", expired, true).await?;
    post_story(&tester_a, &tester_b, "s3-b", "s3", now, false).await?;
    wait_for(&tester_b, "the later story to be filed", STORY_ROW, "s3-b").await?;
    wait_for(
        &tester_a,
        "the later story to be acknowledged",
        "SELECT COUNT(*) FROM message_actions WHERE message_id = ? AND type = 'ackByUserAt'",
        "s3-b",
    )
    .await?;
    assert_eq!(
        scalar(
            &tester_b,
            "SELECT COUNT(*) FROM messages WHERE message_id = ?",
            "s0-b"
        )
        .await?,
        0
    );
    assert_eq!(
        scalar(
            &tester_a,
            "SELECT COUNT(*) FROM message_actions WHERE message_id = ? AND type = 'ackByUserAt'",
            "s0-b"
        )
        .await?,
        0,
        "an expired story is never acknowledged"
    );
    assert_eq!(
        scalar(
            &tester_a,
            "SELECT COUNT(*) FROM receipts WHERE message_id = ?",
            "s0-b"
        )
        .await?,
        1
    );
    stories::purge_expired(&tester_a.context).await?;
    assert_eq!(
        scalar(
            &tester_a,
            "SELECT COUNT(*) FROM receipts WHERE message_id = ?",
            "s0-b"
        )
        .await?,
        0
    );
    assert_eq!(
        scalar(
            &tester_a,
            "SELECT COUNT(*) FROM messages WHERE message_id = ?",
            "s0-b"
        )
        .await?,
        0
    );

    //
    // 5. What a viewer does comes back to the sender: opening, saving, and a
    //    reaction as a message quoting the story.
    //
    MessageService::new(&tester_b.context)
        .notify_opened(tester_a.user_id, vec!["s1-b".into()])
        .await?;
    wait_for(
        &tester_a,
        "B's view to be recorded",
        "SELECT COUNT(*) FROM message_actions WHERE message_id = ? AND type = 'openedAt'",
        "s1-b",
    )
    .await?;
    // Opening the story clears its announcement on B.
    assert_eq!(
        scalar(
            &tester_b,
            "SELECT COUNT(*) FROM notification_outbox WHERE message_id = ? AND cleared_at IS NULL",
            "s1-b"
        )
        .await?,
        0
    );

    let stored = EncryptedContent {
        media_update: Some(encrypted_content::MediaUpdate {
            r#type: encrypted_content::media_update::Type::Stored as i32,
            target_message_id: "s1-b".into(),
        }),
        ..Default::default()
    };
    send_c2c_message_to_contact()
        .ctx(&tester_b.context)
        .contact_id(tester_a.user_id)
        .encrypted_content(stored.encode_to_vec())
        .call()
        .await?;
    tester_a.wait_for_media_stored("s1-b").await?;
    // Each of these reaches A worded for what it is about: A's story.
    tester_a
        .wait_for_notification("stored_story", tester_b.user_id)
        .await?;

    let reaction_id = MessageService::new(&tester_b.context)
        .insert_and_send_text(chat_ab.clone(), "🔥".into(), Some("s1-b".into()), None)
        .await?;
    tester_a
        .wait_for_quoted_text_message(&reaction_id, tester_b.user_id, "🔥", "s1-b")
        .await?;
    let reaction = tester_a
        .wait_for_notification("story_reaction", tester_b.user_id)
        .await?;
    assert_eq!(reaction.body, "has reacted with 🔥 to your story.");

    let reply_id = MessageService::new(&tester_b.context)
        .insert_and_send_text(chat_ab.clone(), "love it".into(), Some("s1-b".into()), None)
        .await?;
    tester_a
        .wait_for_quoted_text_message(&reply_id, tester_b.user_id, "love it", "s1-b")
        .await?;
    let reply = tester_a
        .wait_for_notification("story_reply", tester_b.user_id)
        .await?;
    assert_eq!(reply.body, "has replied to your story.");

    //
    // 6. Taking an item down removes it for every recipient.
    //
    stories::delete_item(&tester_a.context, "s2").await?;
    tester_b.wait_for_message_deleted("s2-b").await?;
    tester_c.wait_for_message_deleted("s2-c").await?;
    assert_eq!(
        scalar(
            &tester_a,
            "SELECT COUNT(*) FROM messages WHERE media_id = ?",
            "s2"
        )
        .await?,
        0
    );

    Ok(())
}
