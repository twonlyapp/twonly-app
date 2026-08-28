use super::Tester;
use prost::Message as _;
use rust_lib_twonly::api::messages::outgoing::send_c2c_message_to_contact;
use rust_lib_twonly::api::proto::client::{self as proto, encrypted_content};
use rust_lib_twonly::bridge::api::ApiConnectionState;
use rust_lib_twonly::database::app::tables::Group;
use rust_lib_twonly::services::contacts::ContactService;
use rust_lib_twonly::services::mediafiles::MediaFileService;
use rust_lib_twonly::services::messages::MessageService;

async fn create_authenticated_tester() -> anyhow::Result<Tester> {
    let mut tester = Tester::new().await?;
    tester.wait_until(ApiConnectionState::Connected).await?;
    tester.register_and_authenticate().await?;
    tester.wait_until(ApiConnectionState::Authenticated).await?;
    Ok(tester)
}

#[tokio::test]
async fn test_media_lifecycle_actions_and_reupload() -> anyhow::Result<()> {
    let _ = tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .with_ansi(true)
        .event_format(rust_lib_twonly::log::ShortEventFormatter::ansi())
        .try_init();

    let tester_a = create_authenticated_tester().await?;
    let tester_b = create_authenticated_tester().await?;

    // Connect contacts A and B
    ContactService::new(&tester_a.context)
        .request_by_username(tester_b.username.clone(), true)
        .await?;
    tester_b
        .wait_for_contact_state(tester_a.user_id, false, true)
        .await?;
    ContactService::new(&tester_b.context)
        .accept_request(tester_a.user_id, true)
        .await?;
    tester_a
        .wait_for_contact_state(tester_b.user_id, true, false)
        .await?;

    let group_id = Group::direct_chat_id(tester_a.user_id, tester_b.user_id);
    let sender_message_id = uuid::Uuid::new_v4().to_string();
    let download_token = vec![1u8; 32];
    let encryption_key = vec![2u8; 32];
    let encryption_mac = vec![3u8; 16];
    let encryption_nonce = vec![4u8; 12];
    let timestamp = chrono::Utc::now().timestamp_millis();

    // 1. Tester A inserts local message and sends an encrypted media message to Tester B
    let local_media_id = uuid::Uuid::new_v4().to_string();
    {
        let db_a = tester_a.context.app_db.read().await.clone();
        sqlx::query!(
            "INSERT INTO media_files(media_id, type, download_state, upload_state) VALUES (?, 'image', 'ready', 'uploaded')",
            local_media_id,
        )
        .execute(&db_a.pool)
        .await?;
        sqlx::query!(
            "INSERT INTO messages(group_id, message_id, type, media_id, created_at) VALUES (?, ?, 'media', ?, CAST(strftime('%s','now') AS INTEGER))",
            group_id,
            sender_message_id,
            local_media_id,
        )
        .execute(&db_a.pool)
        .await?;
    }

    let media_content = proto::EncryptedContent {
        group_id: Some(group_id.clone()),
        media: Some(encrypted_content::Media {
            sender_message_id: sender_message_id.clone(),
            r#type: encrypted_content::media::Type::Image as i32,
            download_token: Some(download_token.clone()),
            encryption_key: Some(encryption_key.clone()),
            encryption_mac: Some(encryption_mac.clone()),
            encryption_nonce: Some(encryption_nonce.clone()),
            timestamp,
            requires_authentication: false,
            display_limit_in_milliseconds: Some(0),
            additional_message_data: None,
            quote_message_id: None,
        }),
        ..Default::default()
    };

    send_c2c_message_to_contact()
        .ctx(&tester_a.context)
        .contact_id(tester_b.user_id)
        .encrypted_content(media_content.encode_to_vec())
        .call()
        .await?;

    // Wait until Tester B has the message and media record in DB
    let mut media_id_on_b = String::new();
    for _ in 0..100 {
        let db_b = tester_b.context.app_db.read().await.clone();
        let row = sqlx::query!(
            "SELECT media_id FROM messages WHERE message_id = ?",
            sender_message_id
        )
        .fetch_optional(&db_b.pool)
        .await?;
        if let Some(r) = row {
            if let Some(mid) = r.media_id {
                media_id_on_b = mid;
                break;
            }
        }
        tokio::time::sleep(std::time::Duration::from_millis(100)).await;
    }
    assert!(!media_id_on_b.is_empty(), "media_id must be generated on receiver");
    tester_b
        .wait_for_media_download_state(&media_id_on_b, "pending")
        .await?;

    // 2. Tester B marks media as stored
    let stored_update = proto::EncryptedContent {
        media_update: Some(encrypted_content::MediaUpdate {
            r#type: encrypted_content::media_update::Type::Stored as i32,
            target_message_id: sender_message_id.clone(),
        }),
        ..Default::default()
    };
    send_c2c_message_to_contact()
        .ctx(&tester_b.context)
        .contact_id(tester_a.user_id)
        .encrypted_content(stored_update.encode_to_vec())
        .call()
        .await?;

    tester_a.wait_for_media_stored(&sender_message_id).await?;

    // 3. Tester B marks media as reopened
    let reopened_update = proto::EncryptedContent {
        media_update: Some(encrypted_content::MediaUpdate {
            r#type: encrypted_content::media_update::Type::Reopened as i32,
            target_message_id: sender_message_id.clone(),
        }),
        ..Default::default()
    };
    send_c2c_message_to_contact()
        .ctx(&tester_b.context)
        .contact_id(tester_a.user_id)
        .encrypted_content(reopened_update.encode_to_vec())
        .call()
        .await?;

    tester_a.wait_for_media_reopened(&sender_message_id).await?;

    // 4. Tester B simulates decryption error & requests reupload
    MediaFileService::new(&tester_b.context)
        .request_reupload(&media_id_on_b)
        .await?;

    tester_a
        .wait_for_media_upload_state(&local_media_id, "reuploadRequested")
        .await?;

    // 5. Tester A responds with MediaType::Reupload
    let reupload_content = proto::EncryptedContent {
        group_id: Some(group_id.clone()),
        media: Some(encrypted_content::Media {
            sender_message_id: sender_message_id.clone(),
            r#type: encrypted_content::media::Type::Reupload as i32,
            download_token: Some(vec![9u8; 32]),
            encryption_key: Some(vec![8u8; 32]),
            encryption_mac: Some(vec![7u8; 16]),
            encryption_nonce: Some(vec![6u8; 12]),
            timestamp: chrono::Utc::now().timestamp_millis(),
            requires_authentication: false,
            display_limit_in_milliseconds: Some(0),
            additional_message_data: None,
            quote_message_id: None,
        }),
        ..Default::default()
    };
    send_c2c_message_to_contact()
        .ctx(&tester_a.context)
        .contact_id(tester_b.user_id)
        .encrypted_content(reupload_content.encode_to_vec())
        .call()
        .await?;

    tester_b
        .wait_for_media_download_state(&media_id_on_b, "pending")
        .await?;

    // 6. Tester A deletes the message
    MessageService::new(&tester_a.context)
        .delete_message(group_id.clone(), sender_message_id.clone())
        .await?;

    tester_b
        .wait_for_message_deleted(&sender_message_id)
        .await?;

    Ok(())
}
