use super::{Tester, init_tracing};
use anyhow::Context as _;
use chacha20poly1305::{ChaCha20Poly1305, KeyInit, Nonce, aead::AeadInOut};
use prost::Message as _;
use rand::RngCore as _;
use rust_lib_twonly::api::messages::outgoing::send_c2c_message_to_contact;
use rust_lib_twonly::api::proto::client::{EncryptedContent, encrypted_content};
use rust_lib_twonly::api::proto::http_requests::{AttachmentDispatch, AttachmentManifest};
use rust_lib_twonly::bridge::api::ApiConnectionState;
use rust_lib_twonly::database::app::groups::native::Group;
use rust_lib_twonly::services::contacts::ContactService;
use rust_lib_twonly::services::direct_media_upload::DirectMediaUploadService;
use rust_lib_twonly::services::media_upload::MediaUploadService;
use rust_lib_twonly::services::messages::MessageService;
use rust_lib_twonly::services::stories::{self, STORY_LIFETIME_SECONDS, StoryAudience};
use tokio::time::{Duration, sleep};

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

/// Supplies a real encrypted attachment and a deliberately timestamped story
/// envelope. The host performs the same three requests as the mobile uploader;
/// receivers can download it without triggering missing-media recovery.

async fn post_story(
    sender: &Tester, recipient: &Tester, message_id: &str, media_id: &str, posted_at: i64,
    notify: bool,
) -> anyhow::Result<()> {
    let group_id = Group::direct_chat_id(sender.user_id, recipient.user_id);
    let key = vec![2; 32];
    let nonce = vec![4; 12];
    let source = image::RgbImage::from_pixel(8, 6, image::Rgb([12, 34, 56]));
    let plaintext = webp::Encoder::from_rgb(source.as_raw(), source.width(), source.height())
        .encode_simple(false, 80.0)
        .map_err(|error| anyhow::anyhow!("encode story fixture: {error:?}"))?;
    let plaintext_path = std::path::PathBuf::from(&sender.context.config.data_dir)
        .join("mediafiles/tmp")
        .join(format!("{media_id}.webp"));
    std::fs::create_dir_all(plaintext_path.parent().unwrap())?;
    std::fs::write(&plaintext_path, &*plaintext)?;
    let mut ciphertext = plaintext.to_vec();
    let cipher = ChaCha20Poly1305::new_from_slice(&key).unwrap();
    let tag = cipher
        .encrypt_inout_detached(
            &Nonce::try_from(nonce.as_slice()).unwrap(),
            b"",
            ciphertext.as_mut_slice().into(),
        )
        .map_err(|_| anyhow::anyhow!("encrypt story fixture"))?;
    let mut download_token = vec![0; 32];
    rand::rng().fill_bytes(&mut download_token);

    {
        let database = sender.context.app_db.read().await.clone();

        sqlx::query(
            "INSERT OR IGNORE INTO media_files(media_id, type, upload_state) VALUES (?, 'image', \
             'uploaded')",
        )
        .bind(media_id)
        .execute(&database.pool)
        .await?;

        sqlx::query("UPDATE media_files SET encryption_key = ?, encryption_nonce = ?, encryption_mac = ? WHERE media_id = ?")
            .bind(&key).bind(&nonce).bind(tag.as_slice()).bind(media_id)
            .execute(&database.pool).await?;

        sqlx::query(
            "INSERT INTO messages(group_id, message_id, type, media_id, is_story, created_at) \
             VALUES (?, ?, 'media', ?, 1, ?)",
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
                download_token: Some(download_token.clone()),
                encryption_key: Some(key),
                encryption_mac: Some(tag.to_vec()),
                encryption_nonce: Some(nonce),
                ..Default::default()
            }),
            notify,
        }),
        ..Default::default()
    };

    let encrypted_body = send_c2c_message_to_contact()
        .ctx(&sender.context)
        .contact_id(recipient.user_id)
        .encrypted_content(content.encode_to_vec())
        .message_id(message_id.to_owned())
        .only_return_encrypted_data(true)
        .blocking(true)
        .call()
        .await?
        .context("prepare encrypted story envelope")?;

    DirectMediaUploadService::new(&sender.context)
        .preload_slots()
        .await?;
    let database = sender.context.app_db.read().await.clone();
    let (attachment, capability, upload_url, fields): (String, Vec<u8>, String, String) =
        sqlx::query_as("SELECT attachment_id, capability, upload_url, upload_fields_json FROM direct_media_upload_slots WHERE state = 'cached' LIMIT 1")
            .fetch_one(&database.pool).await?;
    sqlx::query("UPDATE direct_media_upload_slots SET state = 'reserved' WHERE attachment_id = ?")
        .bind(&attachment)
        .execute(&database.pool)
        .await?;
    let fields: std::collections::HashMap<String, String> = serde_json::from_str(&fields)?;
    let boundary = format!("twonly-test-{}", uuid::Uuid::new_v4());
    let mut multipart = Vec::new();
    for (name, value) in fields {
        multipart.extend_from_slice(
            format!(
                "--{boundary}\r\nContent-Disposition: form-data; name=\"{name}\"\r\n\r\n{value}\r\n"
            )
            .as_bytes(),
        );
    }
    multipart.extend_from_slice(format!("--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"story.bin\"\r\nContent-Type: application/octet-stream\r\n\r\n").as_bytes());
    multipart.extend_from_slice(&ciphertext);
    multipart.extend_from_slice(format!("\r\n--{boundary}--\r\n").as_bytes());
    let _ = rustls::crypto::ring::default_provider().install_default();
    let client = reqwest::Client::builder()
        .timeout(Duration::from_secs(30))
        .build()?;
    client
        .post(upload_url)
        .header(
            "content-type",
            format!("multipart/form-data; boundary={boundary}"),
        )
        .body(multipart)
        .send()
        .await?
        .error_for_status()?;
    let manifest = AttachmentManifest {
        encrypted_object_size: ciphertext.len() as i64,
        dispatches: vec![AttachmentDispatch {
            recipient_user_id: recipient.user_id,
            encrypted_body,
            push_data: notify.then(|| vec![1]),
            download_token,
        }],
    };
    for (step, body) in [
        ("manifest", manifest.encode_to_vec()),
        ("complete", Vec::new()),
    ] {
        let url = format!(
            "{}v2/attachments/{attachment}/{step}",
            rust_lib_twonly::bridge::api::RustApi::api_base_url("https".into())
        );
        client
            .post(url)
            .header("x-twonly-upload-capability", hex::encode(&capability))
            .header("content-type", "application/x-protobuf")
            .header("content-length", body.len())
            .body(body)
            .send()
            .await?
            .error_for_status()?;
    }
    sqlx::query("UPDATE direct_media_upload_slots SET state = 'consumed' WHERE attachment_id = ?")
        .bind(&attachment)
        .execute(&database.pool)
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

    // "All" requires an exchange in the last month. Seed sender-side history
    // outside the two-week notification window; B still has no exchange yet.
    {
        let database = tester_a.context.app_db.read().await.clone();

        let mut t = database.pool.begin().await?;

        let last_exchange = chrono::Utc::now().timestamp() - 21 * 24 * 60 * 60;

        for chat in [&chat_ab, &chat_ac] {
            Group::record_text_or_media(&mut t, chat, last_exchange).await?;
        }

        t.commit().await?;
    }

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

    std::fs::write(&plaintext_path, &*plaintext)?;

    let all = StoryAudience {
        all: true,
        contact_group_ids: Vec::new(),
    };

    // A widget send cannot also be a story.
    assert!(
        uploads
            .insert_into_messages(media_id.clone(), Vec::new(), None, true, Some(all.clone()))
            .await
            .is_err()
    );

    uploads
        .insert_into_messages(media_id.clone(), Vec::new(), None, false, Some(all))
        .await?;

    {
        let database = tester_a.context.app_db.read().await.clone();

        let mut groups: Vec<String> = sqlx::query_scalar(
            "SELECT group_id FROM messages WHERE media_id = ? AND is_story = 1 AND sender_id IS \
             NULL",
        )
        .bind(&media_id)
        .fetch_all(&database.pool)
        .await?;

        groups.sort();

        let mut expected = vec![chat_ab.clone(), chat_ac.clone()];

        expected.sort();

        assert_eq!(groups, expected, "one hidden story row per contact");
    }

    // Direct service calls in this harness do not enter the foreground bridge
    // operation that normally starts preparation in the application.
    uploads.start_upload(&media_id).await?;
    tester_a.wait_for_media_encryption_mac(&media_id).await?;

    wait_for(
        &tester_a,
        "an envelope for every story recipient",
        "SELECT COUNT(*) = 2 FROM receipts r JOIN messages m ON m.message_id = r.message_id
         WHERE m.media_id = ? AND r.will_be_retried_by_media_upload = 1",
        &media_id,
    )
    .await?;

    tester_a.wait_for_prepared_upload_job(&media_id).await?;

    // This host never hands the upload to a native transfer. Cancelling it
    // takes it down locally without sending deletion messages to anybody.
    stories::delete_item(&tester_a.context, &media_id).await?;

    assert_eq!(
        scalar(
            &tester_a,
            "SELECT COUNT(*) FROM messages WHERE media_id = ?",
            &media_id
        )
        .await?,
        0
    );

    //
    // 2. A story is announced only between people who wrote to each other in the
    //    last two weeks. A and B have not yet: filed, not announced.
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
            .insert_and_send_text(chat, text.into(), None, None, None, None)
            .await?;

        recipient
            .wait_for_text_message(&text_id, tester_a.user_id, text)
            .await?;
    }

    //
    // 3. Only the item the sender woke for is announced, and a muted receiver files
    //    stories without announcing any.
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
    // 4. A story that arrives after its 24 hours is ignored without a receipt; the
    //    sender's purge is what stops it being retried.
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
        .insert_and_send_text(
            chat_ab.clone(),
            "🔥".into(),
            Some("s1-b".into()),
            None,
            None,
            None,
        )
        .await?;

    tester_a
        .wait_for_quoted_text_message(&reaction_id, tester_b.user_id, "🔥", "s1-b")
        .await?;

    let reaction = tester_a
        .wait_for_notification("story_reaction", tester_b.user_id)
        .await?;

    assert_eq!(reaction.body, "has reacted with 🔥 to your story.");

    let reply_id = MessageService::new(&tester_b.context)
        .insert_and_send_text(
            chat_ab.clone(),
            "love it".into(),
            Some("s1-b".into()),
            None,
            None,
            None,
        )
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
