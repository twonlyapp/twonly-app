use super::*;
use crate::api::runtime::client::ApiClient;
use crate::bridge::api::{ApiConfig, ApiConnectionState};
use crate::database::app::messages::{table::MessageFilter, table::MessageQuery, watches};
use crate::signal::engine::{FrbPreKeyBundle, RustSignalEngine};
use futures_util::{SinkExt, StreamExt};
use rand::SeedableRng;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::Duration;
use stream_tungstenite::tokio_tungstenite::{accept_async, tungstenite};
use tokio::time::timeout;

async fn context(id: i64) -> anyhow::Result<(Arc<Context>, tempfile::TempDir)> {
    let directory = tempfile::tempdir()?;
    let ctx = Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
        .await?;
    crate::api::ApiRuntime::close(&ctx).await?;
    let identity =
        libsignal_protocol::IdentityKeyPair::generate(&mut rand::rngs::StdRng::from_os_rng());
    let pool = ctx.rust_db.read().await.pool.clone();
    *ctx.signal_engine.lock().await = Some(RustSignalEngine::new_with_pool(
        pool,
        identity.serialize().to_vec(),
        123,
        id.to_string(),
    )?);
    // No user config yet: a loopback fixture can connect without starting
    // authentication maintenance, which is outside these recovery tests.
    Ok((ctx, directory))
}

fn configure(ctx: &Context, id: i64) -> anyhow::Result<()> {
    crate::user_config::UserConfig::save_json(
        ctx,
        &serde_json::to_string(&crate::user_config::UserConfig {
            user_id: id,
            username: format!("user{id}"),
            is_user_discovery_enabled: false,
            ..Default::default()
        })?,
    )?;
    Ok(())
}

async fn close(ctx: &Arc<Context>) -> anyhow::Result<()> {
    crate::api::ApiRuntime::close(ctx).await?;
    ctx.app_db.read().await.close().await;
    ctx.rust_db.read().await.pool.close().await;
    Ok(())
}

fn published(id: i64, bundle: FrbPreKeyBundle) -> server_to_client::response::UserData {
    let prekey = bundle
        .pre_key_id
        .map(|id| server_to_client::response::PqcPreKey {
            ecc_pre_key_id: id as i64,
            ecc_pre_key: bundle.pre_key_public.clone().unwrap(),
            kyber_pre_key_id: bundle.kyber_pre_key_id as i64,
            kyber_pre_key: bundle.kyber_pre_key_public.clone(),
            kyber_pre_key_signature: bundle.kyber_pre_key_signature.clone(),
        });
    server_to_client::response::UserData {
        user_id: id,
        username: Some(format!("user{id}").into_bytes()),
        public_identity_key: Some(bundle.identity_key),
        registration_id: Some(bundle.registration_id as i64),
        pqc_bundle: Some(server_to_client::response::PqcBundle {
            ecc_signed_prekey_id: bundle.signed_pre_key_id as i64,
            ecc_signed_prekey: bundle.signed_pre_key_public,
            ecc_signed_prekey_signature: bundle.signed_pre_key_signature,
            kyber_signed_prekey_id: bundle.kyber_pre_key_id as i64,
            kyber_signed_prekey: bundle.kyber_pre_key_public,
            kyber_signed_prekey_signature: bundle.kyber_pre_key_signature,
            prekey,
        }),
        ..Default::default()
    }
}

#[tokio::test]
async fn missing_private_key_keeps_requesting_repair_during_cooldown_and_recovers(
) -> anyhow::Result<()> {
    let (sender, _sender_dir) = context(42).await?;
    let (receiver, _receiver_dir) = context(7).await?;
    let bundle = receiver
        .signal_engine
        .lock()
        .await
        .as_ref()
        .unwrap()
        .generate_bundle()
        .await?;
    sender
        .signal_engine
        .lock()
        .await
        .as_ref()
        .unwrap()
        .process_prekey_bundle("7".into(), 1, bundle)
        .await?;
    let ciphertext = sender
        .signal_engine
        .lock()
        .await
        .as_ref()
        .unwrap()
        .encrypt_message("7".into(), 1, b"retained plaintext".to_vec())
        .await?;
    let pool = receiver.rust_db.read().await.pool.clone();
    sqlx::query("DELETE FROM signal_signed_pre_keys")
        .execute(&pool)
        .await?;
    let error = receiver
        .signal_engine
        .lock()
        .await
        .as_ref()
        .unwrap()
        .decrypt_message("42".into(), 1, ciphertext)
        .await
        .unwrap_err();
    assert!(matches!(error, TwonlyError::SignalPreKeyUnavailable(_)));
    for _ in 0..3 {
        assert_eq!(
            reset_unusable_session(&receiver, 42, &error).await,
            DecryptionErrorType::SessionResetRequired
        );
    }
    let resets: i64 =
        sqlx::query_scalar("SELECT resets_in_window FROM signal_session_resets WHERE name = '42'")
            .fetch_one(&pool)
            .await?;
    assert_eq!(
        resets, 1,
        "redeliveries must preserve the reset instruction without spending more reset budget"
    );

    // Even an exhausted budget must not turn missing private keys into a
    // request to resend the same undecryptable ciphertext/session.
    sqlx::query("UPDATE signal_session_resets SET resets_in_window = 5")
        .execute(&pool)
        .await?;
    assert_eq!(
        reset_unusable_session(&receiver, 42, &error).await,
        DecryptionErrorType::SessionResetRequired
    );
    let repaired = receiver
        .signal_engine
        .lock()
        .await
        .as_ref()
        .unwrap()
        .generate_bundle()
        .await?;
    sender
        .signal_engine
        .lock()
        .await
        .as_ref()
        .unwrap()
        .reset_session("7", 1, false)
        .await?;
    sender
        .signal_engine
        .lock()
        .await
        .as_ref()
        .unwrap()
        .process_prekey_bundle("7".into(), 1, repaired)
        .await?;
    let retry = sender
        .signal_engine
        .lock()
        .await
        .as_ref()
        .unwrap()
        .encrypt_message("7".into(), 1, b"retained plaintext".to_vec())
        .await?;
    let plaintext = receiver
        .signal_engine
        .lock()
        .await
        .as_ref()
        .unwrap()
        .decrypt_message("42".into(), 1, retry)
        .await?;
    assert_eq!(plaintext, b"retained plaintext");
    let resets: i64 =
        sqlx::query_scalar("SELECT COUNT(*) FROM signal_session_resets WHERE name = '42'")
            .fetch_one(&pool)
            .await?;
    assert_eq!(
        resets, 0,
        "authenticated traffic restores the recovery budget"
    );
    close(&sender).await?;
    close(&receiver).await?;
    Ok(())
}

#[tokio::test]
async fn archived_session_recovery_keeps_chat_reads_and_text_and_media_writes_available(
) -> anyhow::Result<()> {
    let (sender, _sender_dir) = context(42).await?;
    let (receiver, _receiver_dir) = context(7).await?;
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await?;
    let address = listener.local_addr()?;
    let (asked, lookup) = tokio::sync::oneshot::channel();
    let (release, resume) = tokio::sync::oneshot::channel();
    let lookups = Arc::new(AtomicUsize::new(0));
    let counted = lookups.clone();
    let serving_receiver = receiver.clone();
    let server = tokio::spawn(async move {
        let (socket, _) = listener.accept().await.unwrap();
        let mut socket = accept_async(socket).await.unwrap();
        let mut first = Some((asked, resume));
        while let Some(Ok(message)) = socket.next().await {
            if !message.is_binary() {
                continue;
            }
            let request = client_to_server::ClientToServer::decode(message.into_data()).unwrap();
            let Some(client_to_server::client_to_server::V::V0(request)) = request.v else {
                panic!("missing request")
            };
            let Some(client_to_server::v0::Kind::Applicationdata(application)) = request.kind
            else {
                panic!("unexpected handshake")
            };
            let Some(client_to_server::application_data::ApplicationData::GetUserById(requested)) =
                application.application_data
            else {
                panic!("unexpected API request")
            };
            assert_eq!(requested.user_id, 7);
            counted.fetch_add(1, Ordering::SeqCst);
            let bundle = serving_receiver
                .signal_engine
                .lock()
                .await
                .as_ref()
                .unwrap()
                .generate_bundle()
                .await
                .unwrap();
            let user = published(7, bundle);
            if let Some((asked, resume)) = first.take() {
                asked.send(()).unwrap();
                resume.await.unwrap();
            }
            let response = server_to_client::ServerToClient {
                v: Some(server_to_client::server_to_client::V::V0(
                    server_to_client::V0 {
                        seq: request.seq,
                        kind: Some(server_to_client::v0::Kind::Response(
                            server_to_client::Response {
                                response: Some(server_to_client::response::Response::Ok(
                                    server_to_client::response::Ok {
                                        ok: Some(server_to_client::response::ok::Ok::Userdata(
                                            user.clone(),
                                        )),
                                    },
                                )),
                            },
                        )),
                    },
                )),
            };
            socket
                .send(tungstenite::Message::Binary(
                    response.encode_to_vec().into(),
                ))
                .await
                .unwrap();
        }
    });
    let client = ApiClient::new(
        &sender,
        ApiConfig {
            websocket_url: format!("ws://{address}"),
            legacy_user_app_version: 0,
            in_background: true,
            can_use_login_token_for_auth: true,
        },
    );
    *sender.api_client.get().unwrap().write().await = client.clone();
    client.connect().await?;
    timeout(Duration::from_secs(3), async {
        while *client.state.read().await != ApiConnectionState::Connected {
            tokio::task::yield_now().await;
        }
    })
    .await?;
    configure(&sender, 42)?;
    sender.key_manager.lock().await.user_id = Some(42);
    let database = sender.app_db.read().await.clone();
    let group = Group::direct_chat_id(42, 7);
    sqlx::query("INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'peer', 1)")
        .execute(&database.pool)
        .await?;
    sqlx::query("INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES (?, 'Chat', 1)")
        .bind(&group)
        .execute(&database.pool)
        .await?;
    sqlx::query("INSERT INTO group_members(group_id, contact_id) VALUES (?, 7)")
        .bind(&group)
        .execute(&database.pool)
        .await?;
    // An empty (archived) record is present, so testing row existence cannot
    // distinguish it from a usable sender session.
    let initial = receiver
        .signal_engine
        .lock()
        .await
        .as_ref()
        .unwrap()
        .generate_bundle()
        .await?;
    sender
        .signal_engine
        .lock()
        .await
        .as_ref()
        .unwrap()
        .process_prekey_bundle("7".into(), 1, initial)
        .await?;
    sender
        .signal_engine
        .lock()
        .await
        .as_ref()
        .unwrap()
        .reset_session("7", 1, false)
        .await?;
    let held_engine = sender.signal_engine.lock().await;
    let operation = crate::database::lifecycle::Operation::foreground();
    let id = operation
        .scope(
            crate::services::messages::MessageService::new(&sender).insert_and_send_text(
                group.clone(),
                "Send after restore".into(),
                None,
                None,
                None,
                None,
            ),
        )
        .await?;
    operation.cancel();
    operation.drain().await;
    drop(held_engine);
    let receipt: String =
        sqlx::query_scalar("SELECT receipt_id FROM receipts WHERE message_id = ?")
            .bind(&id)
            .fetch_one(&database.pool)
            .await?;
    let preparing_ctx = sender.clone();
    let preparing =
        tokio::spawn(
            async move { messages::prepare_queued_receipt(&preparing_ctx, &receipt).await },
        );
    timeout(Duration::from_secs(3), lookup).await??;

    // A slow session fetch must not hold SQLite or prevent the chat's first
    // snapshot, a new outgoing text, or the media editor's durable row.
    let cancellation = tokio_util::sync::CancellationToken::new();
    let (sent, mut snapshots) = tokio::sync::mpsc::unbounded_channel();
    let watch = tokio::spawn(watches::messages(
        sender.app_db.clone(),
        MessageQuery {
            filter: MessageFilter::Page,
            group_id: Some(group.clone()),
            ids: vec![],
            limit: 100,
            before: None,
            before_message_id: None,
            now_ms: chrono::Utc::now().timestamp_millis(),
        },
        cancellation.clone(),
        move |rows| sent.send(rows).is_ok(),
    ));
    let snapshot = timeout(Duration::from_secs(1), snapshots.recv())
        .await?
        .unwrap();
    assert!(snapshot.iter().any(|message| message.message_id == id));
    let held_engine = sender.signal_engine.lock().await;
    let operation = crate::database::lifecycle::Operation::foreground();
    timeout(
        Duration::from_secs(1),
        operation.scope(
            crate::services::messages::MessageService::new(&sender).insert_and_send_text(
                group.clone(),
                "Another queued text".into(),
                None,
                None,
                None,
                None,
            ),
        ),
    )
    .await??;
    operation.cancel();
    operation.drain().await;
    let media = timeout(
        Duration::from_secs(1),
        crate::services::media_upload::MediaUploadService::new(&sender).initialize(
            "image".into(),
            None,
            false,
        ),
    )
    .await??;
    let operation = crate::database::lifecycle::Operation::foreground();
    timeout(
        Duration::from_secs(1),
        operation.scope(
            crate::services::media_upload::MediaUploadService::new(&sender).insert_into_messages(
                media.clone(),
                vec![group.clone()],
                None,
                false,
                None,
            ),
        ),
    )
    .await??;
    operation.cancel();
    operation.drain().await;
    drop(held_engine);
    release.send(()).unwrap();
    let envelope = timeout(Duration::from_secs(3), preparing).await???.unwrap();
    let envelope = proto::Message::decode(envelope.as_slice())?;
    let decrypted = receiver
        .signal_engine
        .lock()
        .await
        .as_ref()
        .unwrap()
        .decrypt_message("42".into(), 1, envelope.encrypted_content.unwrap())
        .await?;
    assert_eq!(
        proto::EncryptedContent::decode(decrypted.as_slice())?
            .text_message
            .unwrap()
            .text,
        "Send after restore"
    );
    assert_eq!(lookups.load(Ordering::SeqCst), 1);
    // Media manifests use the same prepared-receipt encryption path.
    let content = proto::EncryptedContent {
        media: Some(proto::encrypted_content::Media {
            sender_message_id: "media-after-repair".into(),
            ..Default::default()
        }),
        ..Default::default()
    };
    let envelope = crate::api::messages::outgoing::send_c2c_message_to_contact()
        .ctx(&sender)
        .contact_id(7)
        .encrypted_content(content.encode_to_vec())
        .only_return_encrypted_data(true)
        .blocking(true)
        .call()
        .await?
        .unwrap();
    let envelope = proto::Message::decode(envelope.as_slice())?;
    let decrypted = receiver
        .signal_engine
        .lock()
        .await
        .as_ref()
        .unwrap()
        .decrypt_message("42".into(), 1, envelope.encrypted_content.unwrap())
        .await?;
    assert!(proto::EncryptedContent::decode(decrypted.as_slice())?
        .media
        .is_some());

    // An explicit peer reset is retried as soon as the fresh bundle is ready,
    // and repeated controls share the cooldown instead of fetching keys again.
    sqlx::query("UPDATE receipts SET decryption_failures = 1, ack_by_server_at = ?, last_retry = ? WHERE message_id = ?")
        .bind(chrono::Utc::now().timestamp()).bind(chrono::Utc::now().timestamp()).bind(&id)
        .execute(&database.pool).await?;
    rebuild_session_and_release(&sender, 7, SessionRepair::PeerReset).await?;
    let acknowledged: Option<i64> =
        sqlx::query_scalar("SELECT ack_by_server_at FROM receipts WHERE message_id = ?")
            .bind(&id)
            .fetch_one(&database.pool)
            .await?;
    assert_eq!(
        acknowledged, None,
        "fresh-session retries must not retain the two-minute send cooldown"
    );
    rebuild_session_and_release(&sender, 7, SessionRepair::PeerReset).await?;
    assert_eq!(
        lookups.load(Ordering::SeqCst),
        2,
        "a bundle fetch must not clear its own repair cooldown"
    );
    cancellation.cancel();
    watch.await??;
    client.close().await;
    timeout(Duration::from_secs(3), server).await??;
    close(&sender).await?;
    close(&receiver).await?;
    Ok(())
}
