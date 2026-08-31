use super::{init_tracing, Tester};
use rust_lib_twonly::bridge::api::ApiConnectionState;
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

    let issued = service.preload_slots().await?;
    assert!(issued > 0, "the server must issue direct-media slots");

    let (attachment_id, capability) = {
        let database = tester.context.app_db.read().await.clone();
        sqlx::query_as::<_, (String, Vec<u8>)>(
            "SELECT attachment_id, capability FROM direct_media_upload_slots WHERE state = 'cached' LIMIT 1",
        )
        .fetch_one(&database.pool)
        .await?
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
            "INSERT INTO media_files(media_id, type, upload_state) VALUES (?, 'image', 'backgroundUploadTaskStarted')",
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

    // Scheduling the transfer needs a mobile background uploader and a
    // recipient, so preparation stops right after compression on this host.
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

async fn abandon_attachment(attachment_id: &str, capability: &[u8]) -> anyhow::Result<()> {
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
