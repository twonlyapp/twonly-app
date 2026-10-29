use super::{init_tracing, Tester};
use anyhow::Context as _;
use prost::Message as _;
use rust_lib_twonly::bridge::api::ApiConnectionState;
use rust_lib_twonly::database::app::groups::native::Group;
use rust_lib_twonly::services::contacts::ContactService;
use rust_lib_twonly::services::direct_media_upload::DirectMediaUploadService;
use rust_lib_twonly::services::media_upload::MediaUploadService;

async fn create_authenticated_tester() -> anyhow::Result<Tester> {
    let mut tester = Tester::new().await?;

    tester.wait_until(ApiConnectionState::Connected).await?;

    tester.register_and_authenticate().await?;

    tester.wait_until(ApiConnectionState::Authenticated).await?;

    Ok(tester)
}

/// A native background transfer cannot report into a process that is not
/// running, so the client asks the server what happened to each attachment it
/// still believes is in flight. This drives that path against the live API.
#[tokio::test]

async fn test_direct_media_upload_reconciliation() -> anyhow::Result<()> {
    init_tracing();

    let tester = create_authenticated_tester().await?;

    let service = DirectMediaUploadService::new(&tester.context);

    // The client fills its slot cache on its own the moment it authenticates,
    // and the server issues no more than one account's worth, so this call is
    // just as likely to be answered with nothing left to hand out. What has to
    // hold is that the account ends up holding slots to send against.
    service.preload_slots().await?;

    let (attachment_id, capability) = {
        let database = tester.context.app_db.read().await.clone();

        sqlx::query_as::<_, (String, Vec<u8>)>(
            "SELECT attachment_id, capability FROM direct_media_upload_slots WHERE state = \
             'cached' LIMIT 1",
        )
        .fetch_optional(&database.pool)
        .await?
        .context("the server must issue direct-media slots")?
    };

    // Stand in for a media send whose native transfer was handed off but never
    // reported back.
    let media_id = uuid::Uuid::new_v4().to_string();

    let job_directory = std::path::PathBuf::from(&tester.context.config.data_dir)
        .join("direct-media-upload")
        .join(&attachment_id);

    std::fs::create_dir_all(&job_directory)?;

    let multipart_path = job_directory.join("media.multipart");

    let manifest_path = job_directory.join("manifest.pb");

    let complete_path = job_directory.join("complete.pb");

    for path in [&multipart_path, &manifest_path, &complete_path] {
        std::fs::write(path, b"")?;
    }

    {
        let database = tester.context.app_db.read().await.clone();

        sqlx::query!(
            "INSERT INTO media_files(media_id, type, upload_state) VALUES (?, 'image', \
             'backgroundUploadTaskStarted')",
            media_id,
        )
        .execute(&database.pool)
        .await?;

        let multipart = multipart_path.to_string_lossy().into_owned();

        let manifest = manifest_path.to_string_lossy().into_owned();

        let complete = complete_path.to_string_lossy().into_owned();

        sqlx::query!(
            r#"INSERT INTO direct_media_upload_jobs
               (attachment_id, media_id, multipart_path, manifest_path,
                complete_body_path, native_descriptor_json, state, expires_at)
               SELECT ?, ?, ?, ?, ?, '{}', 'scheduled', expires_at
               FROM direct_media_upload_slots WHERE attachment_id = ?"#,
            attachment_id,
            media_id,
            multipart,
            manifest,
            complete,
            attachment_id,
        )
        .execute(&database.pool)
        .await?;

        sqlx::query!(
            "UPDATE direct_media_upload_slots SET state = 'reserved' WHERE attachment_id = ?",
            attachment_id,
        )
        .execute(&database.pool)
        .await?;
    }

    // Nothing has been uploaded, so the attachment is still reserved and the
    // job must survive: giving up here would drop a transfer the OS may still
    // be running.
    service.reconcile().await?;

    {
        let database = tester.context.app_db.read().await.clone();

        let jobs = sqlx::query_scalar!(
            "SELECT COUNT(*) FROM direct_media_upload_jobs WHERE attachment_id = ?",
            attachment_id,
        )
        .fetch_one(&database.pool)
        .await?;

        assert_eq!(jobs, 1, "a reserved attachment must not be settled");
    }

    assert!(multipart_path.exists(), "request files must be kept");

    // The server now reports the attachment as abandoned. Reconciliation has to
    // release the slot and the files, and requeue the media for another try.
    abandon_attachment(&attachment_id, &capability).await?;

    service.reconcile().await?;

    {
        let database = tester.context.app_db.read().await.clone();

        let jobs = sqlx::query_scalar!(
            "SELECT COUNT(*) FROM direct_media_upload_jobs WHERE attachment_id = ?",
            attachment_id,
        )
        .fetch_one(&database.pool)
        .await?;

        assert_eq!(jobs, 0, "an abandoned attachment must settle its job");

        let slot_state = sqlx::query_scalar!(
            "SELECT state FROM direct_media_upload_slots WHERE attachment_id = ?",
            attachment_id,
        )
        .fetch_one(&database.pool)
        .await?;

        assert_eq!(slot_state, "abandoned");

        let upload_state = sqlx::query_scalar!(
            "SELECT upload_state FROM media_files WHERE media_id = ?",
            media_id,
        )
        .fetch_one(&database.pool)
        .await?;

        assert_eq!(
            upload_state.as_deref(),
            Some("preprocessing"),
            "an abandoned upload has to be retried, not lost"
        );
    }

    assert!(
        !multipart_path.exists(),
        "settling must delete the request files"
    );

    Ok(())
}

/// Rust owns the media row and its key material; Flutter only names the type.
#[tokio::test]

async fn test_media_initialization_is_rust_owned() -> anyhow::Result<()> {
    init_tracing();

    let tester = create_authenticated_tester().await?;

    let service = MediaUploadService::new(&tester.context);

    // A value below one second can only have been meant as seconds.
    let media_id = service.initialize("image".into(), Some(12), false).await?;

    let database = tester.context.app_db.read().await.clone();

    let row = sqlx::query!(
        r#"SELECT upload_state, display_limit_in_milliseconds, encryption_key,
                  encryption_nonce, is_draft_media
           FROM media_files WHERE media_id = ?"#,
        media_id,
    )
    .fetch_one(&database.pool)
    .await?;

    assert_eq!(row.upload_state.as_deref(), Some("initialized"));

    assert_eq!(row.display_limit_in_milliseconds, Some(12_000));

    assert_eq!(row.encryption_key.map(|key| key.len()), Some(32));

    assert_eq!(row.encryption_nonce.map(|nonce| nonce.len()), Some(12));

    assert_eq!(row.is_draft_media, 0);

    // Only one media file may be the draft, so creating a new draft clears the
    // previous one.
    let draft = service.initialize("image".into(), None, true).await?;

    let second_draft = service.initialize("video".into(), None, true).await?;

    let drafts = sqlx::query_scalar!("SELECT COUNT(*) FROM media_files WHERE is_draft_media = 1")
        .fetch_one(&database.pool)
        .await?;

    assert_eq!(drafts, 1, "only the newest draft stays a draft");

    let first_draft_state = sqlx::query_scalar!(
        "SELECT is_draft_media FROM media_files WHERE media_id = ?",
        draft
    )
    .fetch_one(&database.pool)
    .await?;

    assert_eq!(first_draft_state, 0);

    let second_draft_state = sqlx::query_scalar!(
        "SELECT is_draft_media FROM media_files WHERE media_id = ?",
        second_draft
    )
    .fetch_one(&database.pool)
    .await?;

    assert_eq!(second_draft_state, 1);

    Ok(())
}

/// The send pipeline encodes stills itself now. This drives a real media file
/// through `start_upload` and checks that the plaintext handed to encryption is
/// a WebP that Rust produced, with no Flutter involvement.
#[tokio::test]

async fn test_outgoing_images_are_encoded_to_webp_by_rust() -> anyhow::Result<()> {
    init_tracing();

    let tester = create_authenticated_tester().await?;

    let recipient = create_authenticated_tester().await?;
    ContactService::new(&tester.context)
        .request_by_username(recipient.username.clone(), true)
        .await?;
    recipient
        .wait_for_contact_state(tester.user_id, false, true)
        .await?;
    ContactService::new(&recipient.context)
        .accept_request(tester.user_id, true)
        .await?;
    tester
        .wait_for_contact_state(recipient.user_id, true, false)
        .await?;

    let service = MediaUploadService::new(&tester.context);

    let media_id = service.initialize("image".into(), None, false).await?;

    let media_root = std::path::PathBuf::from(&tester.context.config.data_dir).join("mediafiles");

    let original = media_root
        .join("tmp")
        .join(format!("{media_id}.original.webp"));

    std::fs::create_dir_all(original.parent().expect("tmp directory"))?;

    // A PNG carrying an alpha channel, so the encoder has to preserve it.
    let mut source = image::RgbaImage::from_pixel(320, 240, image::Rgba([12, 34, 56, 255]));

    source.put_pixel(0, 0, image::Rgba([0, 0, 0, 0]));

    image::DynamicImage::ImageRgba8(source).save_with_format(&original, image::ImageFormat::Png)?;

    // Give the send a real recipient. An unreferenced image is correctly
    // removed by orphan cleanup after preparation reports no recipients.
    service
        .insert_into_messages(
            media_id.clone(),
            vec![Group::direct_chat_id(tester.user_id, recipient.user_id)],
            None,
            false,
            None,
        )
        .await?;
    service.start_upload(&media_id).await?;

    let plaintext = media_root.join("tmp").join(format!("{media_id}.webp"));

    let bytes = std::fs::read(&plaintext)?;

    assert_eq!(&bytes[0..4], b"RIFF", "the send plaintext must be a WebP");

    assert_eq!(&bytes[8..12], b"WEBP");

    let decoded = image::load_from_memory(&bytes)?;

    assert_eq!((decoded.width(), decoded.height()), (320, 240));

    assert!(
        bytes.len() < std::fs::metadata(&original)?.len() as usize,
        "the encoded image should be smaller than the PNG original"
    );

    Ok(())
}

/// A contact who deleted their account must not hold a send back from everyone
/// else. The client only learns about a deletion when it asks the server about
/// that contact, so it still names them in the manifest. The server used to
/// refuse the whole manifest with 400, and the client resent it until the slot
/// expired: nobody received the media and the chat showed a spinner for days.
#[tokio::test]

async fn test_media_reaches_recipients_when_one_deleted_their_account() -> anyhow::Result<()> {
    init_tracing();

    let sender = create_authenticated_tester().await?;

    let active = create_authenticated_tester().await?;

    let deleted = create_authenticated_tester().await?;

    for recipient in [&active, &deleted] {
        ContactService::new(&sender.context)
            .request_by_username(recipient.username.clone(), true)
            .await?;
        recipient
            .wait_for_contact_state(sender.user_id, false, true)
            .await?;
        ContactService::new(&recipient.context)
            .accept_request(sender.user_id, true)
            .await?;
        sender
            .wait_for_contact_state(recipient.user_id, true, false)
            .await?;
    }

    let rust_lib_twonly::bridge::api::ServerResult::Ok(()) =
        rust_lib_twonly::api::Server::delete_account(&deleted.context).await?
    else {
        anyhow::bail!("the server refused to delete the account");
    };

    let service = MediaUploadService::new(&sender.context);

    let media_id = service.initialize("image".into(), None, false).await?;

    let original = std::path::PathBuf::from(&sender.context.config.data_dir)
        .join("mediafiles/tmp")
        .join(format!("{media_id}.original.webp"));

    std::fs::create_dir_all(original.parent().expect("tmp directory"))?;

    image::DynamicImage::ImageRgb8(image::RgbImage::from_pixel(
        64,
        48,
        image::Rgb([12, 34, 56]),
    ))
    .save_with_format(&original, image::ImageFormat::Png)?;

    let active_chat = Group::direct_chat_id(sender.user_id, active.user_id);

    service
        .insert_into_messages(
            media_id.clone(),
            vec![
                active_chat.clone(),
                Group::direct_chat_id(sender.user_id, deleted.user_id),
            ],
            None,
            false,
            None,
        )
        .await?;

    // Preparation names both recipients, because the sender still believes
    // the deleted one exists. Scheduling needs a mobile uploader, so on this
    // host the prepared job waits for the transfer below.
    service.start_upload(&media_id).await?;

    sender.wait_for_prepared_upload_job(&media_id).await?;

    let (attachment_id, descriptor) = {
        let database = sender.context.app_db.read().await.clone();

        sqlx::query_as::<_, (String, String)>(
            "SELECT attachment_id, native_descriptor_json FROM direct_media_upload_jobs WHERE \
             media_id = ?",
        )
        .bind(&media_id)
        .fetch_one(&database.pool)
        .await?
    };

    let descriptor: serde_json::Value = serde_json::from_str(&descriptor)?;

    let manifest = rust_lib_twonly::api::proto::http_requests::AttachmentManifest::decode(
        std::fs::read(descriptor["manifest"]["body_path"].as_str().unwrap())?.as_slice(),
    )?;

    let mut named: Vec<i64> = manifest
        .dispatches
        .iter()
        .map(|dispatch| dispatch.recipient_user_id)
        .collect();

    named.sort_unstable();

    let mut expected = vec![active.user_id, deleted.user_id];

    expected.sort_unstable();

    assert_eq!(
        named, expected,
        "the manifest must still name the deleted recipient"
    );

    // Do what the Android worker does with the prepared requests.
    for role in ["media", "manifest", "complete"] {
        let status = native_transfer(&descriptor[role]).await?;

        assert!(
            (200..300).contains(&status),
            "{role} request for {attachment_id} returned HTTP {status}"
        );
    }

    DirectMediaUploadService::new(&sender.context)
        .reconcile()
        .await?;

    sender
        .wait_for_media_upload_state(&media_id, "uploaded")
        .await?;

    let sender_message_id = {
        let database = sender.context.app_db.read().await.clone();

        sqlx::query_scalar::<_, String>(
            "SELECT message_id FROM messages WHERE media_id = ? AND group_id = ?",
        )
        .bind(&media_id)
        .bind(&active_chat)
        .fetch_one(&database.pool)
        .await?
    };

    for _ in 0..100 {
        let database = active.context.app_db.read().await.clone();

        let received = sqlx::query_scalar::<_, Option<Vec<u8>>>(
            "SELECT f.download_token FROM messages m JOIN media_files f ON f.media_id = \
             m.media_id WHERE m.message_id = ?",
        )
        .bind(&sender_message_id)
        .fetch_optional(&database.pool)
        .await?
        .flatten();

        if received.is_some() {
            return Ok(());
        }

        tokio::time::sleep(std::time::Duration::from_millis(100)).await;
    }

    anyhow::bail!("the active recipient never received the media")
}

/// A manifest the server refuses used to be resent by the native uploader until
/// the slot expired, while the chat showed the send as in progress. Recovery now
/// asks the server itself: a refusal first looks for recipients who deleted
/// their account (older servers refuse the whole manifest for one) and prepares
/// again without them, and fails the send when there is nobody to leave out.
#[tokio::test]

async fn test_refused_manifest_ends_the_send_instead_of_looping() -> anyhow::Result<()> {
    init_tracing();

    let sender = create_authenticated_tester().await?;

    let active = create_authenticated_tester().await?;

    let deleted = create_authenticated_tester().await?;

    for recipient in [&active, &deleted] {
        ContactService::new(&sender.context)
            .request_by_username(recipient.username.clone(), true)
            .await?;
        recipient
            .wait_for_contact_state(sender.user_id, false, true)
            .await?;
        ContactService::new(&recipient.context)
            .accept_request(sender.user_id, true)
            .await?;
        sender
            .wait_for_contact_state(recipient.user_id, true, false)
            .await?;
    }

    let rust_lib_twonly::bridge::api::ServerResult::Ok(()) =
        rust_lib_twonly::api::Server::delete_account(&deleted.context).await?
    else {
        anyhow::bail!("the server refused to delete the account");
    };

    let service = MediaUploadService::new(&sender.context);

    let media_id = service.initialize("image".into(), None, false).await?;

    let original = std::path::PathBuf::from(&sender.context.config.data_dir)
        .join("mediafiles/tmp")
        .join(format!("{media_id}.original.webp"));

    std::fs::create_dir_all(original.parent().expect("tmp directory"))?;

    image::DynamicImage::ImageRgb8(image::RgbImage::from_pixel(
        64,
        48,
        image::Rgb([12, 34, 56]),
    ))
    .save_with_format(&original, image::ImageFormat::Png)?;

    let active_chat = Group::direct_chat_id(sender.user_id, active.user_id);

    service
        .insert_into_messages(
            media_id.clone(),
            vec![
                active_chat.clone(),
                Group::direct_chat_id(sender.user_id, deleted.user_id),
            ],
            None,
            false,
            None,
        )
        .await?;

    // 1. The deleted recipient is still named, and the server refuses the
    //    manifest. Recovery has to find that account and prepare again.
    service.start_upload(&media_id).await?;

    sender.wait_for_prepared_upload_job(&media_id).await?;

    let first = refuse_prepared_manifest(&sender, &media_id).await?;

    assert_eq!(first.len(), 2, "both recipients are named at first");

    wait_until_settled(&sender, &media_id).await?;

    {
        let database = sender.context.app_db.read().await.clone();

        let marked =
            sqlx::query_scalar::<_, i64>("SELECT account_deleted FROM contacts WHERE user_id = ?")
                .bind(deleted.user_id)
                .fetch_one(&database.pool)
                .await?;

        assert_eq!(marked, 1, "the refusal must reveal the deleted account");
    }

    // 2. Prepared again, only the active recipient is left, and the server
    //    still refuses. Nothing is left to leave out, so the send fails.
    sender
        .wait_for_media_upload_state(&media_id, "preprocessing")
        .await?;

    service.start_upload(&media_id).await?;

    sender.wait_for_prepared_upload_job(&media_id).await?;

    let second = refuse_prepared_manifest(&sender, &media_id).await?;

    assert_eq!(
        second,
        vec![active.user_id],
        "the deleted recipient must be left out of the new preparation"
    );

    wait_until_settled(&sender, &media_id).await?;

    let database = sender.context.app_db.read().await.clone();

    let failed = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM message_actions a JOIN messages m ON m.message_id = a.message_id \
         WHERE m.media_id = ? AND m.group_id = ? AND a.contact_id = ? AND a.type = 'sendFailed'",
    )
    .bind(&media_id)
    .bind(&active_chat)
    .bind(active.user_id)
    .fetch_one(&database.pool)
    .await?;

    assert_eq!(failed, 1, "the remaining recipient must see a failed send");

    Ok(())
}

/// Makes the server refuse the prepared manifest, with a size no slot allows,
/// and hands the job to recovery as a scheduled native transfer would be.
/// Returns the recipients the manifest names.
async fn refuse_prepared_manifest(sender: &Tester, media_id: &str) -> anyhow::Result<Vec<i64>> {
    use rust_lib_twonly::api::proto::http_requests::AttachmentManifest;

    let database = sender.context.app_db.read().await.clone();

    let (attachment_id, manifest_path) = sqlx::query_as::<_, (String, String)>(
        "SELECT attachment_id, manifest_path FROM direct_media_upload_jobs WHERE media_id = ?",
    )
    .bind(media_id)
    .fetch_one(&database.pool)
    .await?;

    let mut manifest = AttachmentManifest::decode(std::fs::read(&manifest_path)?.as_slice())?;

    manifest.encrypted_object_size = i64::MAX;

    std::fs::write(&manifest_path, manifest.encode_to_vec())?;

    sqlx::query(
        "UPDATE direct_media_upload_jobs SET state = 'scheduled', updated_at = 0 WHERE \
         attachment_id = ?",
    )
    .bind(&attachment_id)
    .execute(&database.pool)
    .await?;

    let mut recipients: Vec<i64> = manifest
        .dispatches
        .iter()
        .map(|dispatch| dispatch.recipient_user_id)
        .collect();

    recipients.sort_unstable();

    Ok(recipients)
}

/// Runs reconciliation until the media has no upload job left. A watcher may
/// claim the recovery first, so this waits for the outcome rather than
/// expecting this call to be the one that settles it.
async fn wait_until_settled(sender: &Tester, media_id: &str) -> anyhow::Result<()> {
    for _ in 0..50 {
        DirectMediaUploadService::new(&sender.context)
            .reconcile()
            .await?;

        let database = sender.context.app_db.read().await.clone();

        let jobs = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM direct_media_upload_jobs WHERE media_id = ? AND state IN \
             ('scheduled', 'waiting_for_server')",
        )
        .bind(media_id)
        .fetch_one(&database.pool)
        .await?;

        if jobs == 0 {
            return Ok(());
        }

        tokio::time::sleep(std::time::Duration::from_millis(200)).await;
    }

    anyhow::bail!("the refused upload of {media_id} was never settled")
}

/// One prepared request, sent the way `DirectMediaHttpTransfer.kt` sends it.
async fn native_transfer(request: &serde_json::Value) -> anyhow::Result<u16> {
    let _ = rustls::crypto::ring::default_provider().install_default();

    let body = std::fs::read(
        request["body_path"]
            .as_str()
            .context("prepared request has no body")?,
    )?;

    let method =
        reqwest::Method::from_bytes(request["method"].as_str().unwrap_or("POST").as_bytes())?;

    let mut builder = reqwest::Client::new()
        .request(
            method,
            request["url"]
                .as_str()
                .context("prepared request has no URL")?,
        )
        .body(body);

    for (name, value) in request["headers"]
        .as_object()
        .context("prepared request has no headers")?
    {
        builder = builder.header(name, value.as_str().unwrap_or_default());
    }

    Ok(builder.send().await?.status().as_u16())
}

async fn abandon_attachment(attachment_id: &str, capability: &[u8]) -> anyhow::Result<()> {
    // This test constructs its own client rather than the app's configured one.
    let _ = rustls::crypto::ring::default_provider().install_default();

    let url = format!(
        "{}v2/attachments/{attachment_id}/abandon",
        rust_lib_twonly::bridge::api::RustApi::api_base_url("https".into())
    );

    let response = reqwest::Client::new()
        .post(url)
        .header("x-twonly-upload-capability", hex::encode(capability))
        .header("content-length", 0)
        .send()
        .await?;

    anyhow::ensure!(
        response.status().is_success(),
        "abandon returned HTTP {}",
        response.status()
    );

    Ok(())
}
