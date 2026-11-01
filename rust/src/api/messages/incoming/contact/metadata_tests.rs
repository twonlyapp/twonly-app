use super::*;
use crate::api::proto::client::message::Type as MessageType;
use crate::api::proto::client::Message;
use crate::api::proto::{client_to_server, server_to_client};
use crate::api::runtime::client::ApiClient;
use crate::bridge::api::{ApiConfig, ApiConnectionState};
use crate::database::app::receipts::table::Receipt;
use crate::database::app::AppDatabase;
use futures_util::{SinkExt, StreamExt};
use prost::Message as _;
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
use std::time::Duration;
use stream_tungstenite::tokio_tungstenite::{accept_async, tungstenite};
use tokio::sync::Semaphore;

struct Fixture {
    _directory: tempfile::TempDir,
    ctx: Arc<Context>,
    database: Arc<AppDatabase>,
    username: Arc<Mutex<String>>,
    lookups: Arc<AtomicUsize>,
    responses: Arc<AtomicUsize>,
    replies: Arc<Semaphore>,
    fail: Arc<AtomicBool>,
}

impl Fixture {
    async fn new(reply_count: usize) -> anyhow::Result<Self> {
        let directory = tempfile::tempdir()?;
        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;
        let username = Arc::new(Mutex::new("mallory".to_owned()));
        let lookups = Arc::new(AtomicUsize::new(0));
        let responses = Arc::new(AtomicUsize::new(0));
        let replies = Arc::new(Semaphore::new(reply_count));
        let fail = Arc::new(AtomicBool::new(false));
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await?;
        let address = listener.local_addr()?;

        let server_username = username.clone();
        let server_lookups = lookups.clone();
        let server_responses = responses.clone();
        let server_replies = replies.clone();
        let server_fail = fail.clone();

        tokio::spawn(async move {
            let (socket, _) = listener.accept().await.unwrap();
            let mut socket = accept_async(socket).await.unwrap();

            while let Some(Ok(message)) = socket.next().await {
                if !message.is_binary() {
                    continue;
                }
                let request =
                    client_to_server::ClientToServer::decode(message.into_data()).unwrap();
                let Some(client_to_server::client_to_server::V::V0(request)) = request.v else {
                    continue;
                };
                let lookup = match request.kind {
                    Some(client_to_server::v0::Kind::Applicationdata(application)) => {
                        match application.application_data {
                            Some(
                                client_to_server::application_data::ApplicationData::GetUserById(
                                    request,
                                ),
                            ) => {
                                assert!(
                                    request.metadata_only,
                                    "profile verification must not request prekeys"
                                );
                                Some(request.user_id)
                            }
                            _ => None,
                        }
                    }
                    _ => None,
                };

                let response = if let Some(user_id) = lookup {
                    server_lookups.fetch_add(1, Ordering::SeqCst);
                    server_replies.acquire().await.unwrap().forget();
                    if server_fail.load(Ordering::SeqCst) {
                        server_to_client::response::Response::Error(
                            crate::api::proto::error::ErrorCode::InternalError as i32,
                        )
                    } else {
                        server_to_client::response::Response::Ok(server_to_client::response::Ok {
                            ok: Some(server_to_client::response::ok::Ok::Userdata(
                                server_to_client::response::UserData {
                                    user_id,
                                    username: Some(
                                        server_username.lock().unwrap().clone().into_bytes(),
                                    ),
                                    joined_at: Some(123),
                                    ..Default::default()
                                },
                            )),
                        })
                    }
                } else {
                    server_to_client::response::Response::Ok(server_to_client::response::Ok {
                        ok: Some(server_to_client::response::ok::Ok::None(true)),
                    })
                };

                let response = server_to_client::ServerToClient {
                    v: Some(server_to_client::server_to_client::V::V0(
                        server_to_client::V0 {
                            seq: request.seq,
                            kind: Some(server_to_client::v0::Kind::Response(
                                server_to_client::Response {
                                    response: Some(response),
                                },
                            )),
                        },
                    )),
                };
                if socket
                    .send(tungstenite::Message::Binary(
                        response.encode_to_vec().into(),
                    ))
                    .await
                    .is_err()
                {
                    break;
                }
                if lookup.is_some() {
                    server_responses.fetch_add(1, Ordering::SeqCst);
                }
            }
        });

        let client = ApiClient::new(
            &ctx,
            ApiConfig {
                websocket_url: format!("ws://{address}"),
                legacy_user_app_version: 0,
                in_background: true,
                can_use_login_token_for_auth: true,
            },
        );
        *ctx.api_client.get().unwrap().write().await = client.clone();
        // Connect before installing a user, avoiding unrelated authentication
        // maintenance.
        client.connect().await?;
        tokio::time::timeout(Duration::from_secs(3), async {
            while *client.state.read().await != ApiConnectionState::Connected {
                tokio::task::yield_now().await;
            }
        })
        .await?;
        UserConfig::save_json(&ctx, r#"{"userId":42,"username":"me","displayName":"Me"}"#)?;
        ctx.inject_test_user_id(42).await?;

        let database = ctx.app_db.read().await.clone();
        sqlx::query(
            "INSERT INTO contacts(user_id, username, deleted_by_user) VALUES (8, 'mallory', 1)",
        )
        .execute(&database.pool)
        .await?;
        sqlx::query("INSERT INTO groups(group_id, group_name) VALUES ('shared', 'Shared group')")
            .execute(&database.pool)
            .await?;
        sqlx::query("INSERT INTO group_members(group_id, contact_id) VALUES ('shared', 8)")
            .execute(&database.pool)
            .await?;

        Ok(Self {
            _directory: directory,
            ctx,
            database,
            username,
            lookups,
            responses,
            replies,
            fail,
        })
    }

    async fn deliver(
        &self, receipt_id: &str, username: &str, counter: Option<i64>,
    ) -> anyhow::Result<()> {
        self.deliver_content(
            receipt_id,
            EncryptedContent {
                contact_update: Some(encrypted_content::ContactUpdate {
                    r#type: encrypted_content::contact_update::Type::Update as i32,
                    username: Some(username.into()),
                    display_name: Some("Alice".into()),
                    ..Default::default()
                }),
                sender_profile_counter: counter,
                ..Default::default()
            },
        )
        .await
    }

    async fn deliver_content(
        &self, receipt_id: &str, content: EncryptedContent,
    ) -> anyhow::Result<()> {
        let mut t = self.database.pool.begin().await?;
        Receipt::claim_received(&mut t, receipt_id).await?;
        Receipt::store_pending_plaintext(&mut t, receipt_id, 8, &content.encode_to_vec()).await?;
        t.commit().await?;
        super::super::handle_decoded_server_message(
            &self.ctx,
            8,
            Message {
                receipt_id: receipt_id.into(),
                r#type: MessageType::CiphertextV2 as i32,
                ..Default::default()
            },
        )
        .await?;

        let pending = sqlx::query_scalar::<_, Option<Vec<u8>>>(
            "SELECT pending_plaintext FROM received_receipts WHERE receipt_id = ?",
        )
        .bind(receipt_id)
        .fetch_one(&self.database.pool)
        .await?;
        assert!(
            pending.is_none(),
            "metadata verification must not park the mailbox message"
        );
        Ok(())
    }

    async fn stored_username(&self) -> anyhow::Result<String> {
        Ok(
            sqlx::query_scalar("SELECT username FROM contacts WHERE user_id = 8")
                .fetch_one(&self.database.pool)
                .await?,
        )
    }

    async fn wait_for_count(counter: &AtomicUsize, expected: usize) -> anyhow::Result<()> {
        tokio::time::timeout(Duration::from_secs(3), async {
            while counter.load(Ordering::SeqCst) < expected {
                tokio::task::yield_now().await;
            }
        })
        .await?;
        Ok(())
    }

    async fn wait_until_refreshed(&self) -> anyhow::Result<()> {
        tokio::time::timeout(Duration::from_secs(3), async {
            loop {
                let pending = sqlx::query_scalar::<_, i64>(
                    "SELECT pending FROM contact_metadata_refreshes WHERE contact_id = 8",
                )
                .fetch_one(&self.database.pool)
                .await?;
                if pending == 0 {
                    return Ok::<_, sqlx::Error>(());
                }
                tokio::task::yield_now().await;
            }
        })
        .await??;
        Ok(())
    }

    async fn expire_cooldown(&self) -> anyhow::Result<()> {
        sqlx::query("UPDATE contact_metadata_refreshes SET next_attempt_at = 0")
            .execute(&self.database.pool)
            .await?;
        sqlx::query("UPDATE contact_metadata_refresh_budget SET next_attempt_at = 0")
            .execute(&self.database.pool)
            .await?;
        metadata::schedule(&self.ctx);
        Ok(())
    }
}

#[tokio::test]
async fn claims_are_bounded_and_a_deferred_rename_eventually_applies() -> anyhow::Result<()> {
    let fixture = Fixture::new(100).await?;

    // Matching claims do not cause a lookup, and cannot overwrite a concurrent
    // refresh.
    fixture.deliver("same", "mallory", Some(0)).await?;
    assert_eq!(fixture.lookups.load(Ordering::SeqCst), 0);

    fixture.deliver("spoof", "alice", Some(1)).await?;
    fixture.wait_until_refreshed().await?;
    assert_eq!(fixture.stored_username().await?, "mallory");
    assert_eq!(fixture.lookups.load(Ordering::SeqCst), 1);

    for i in 0..24 {
        let counter = match i % 3 {
            0 => None,
            1 => Some(i64::MAX - i),
            _ => Some(-i),
        };
        fixture
            .deliver(&format!("spoof-{i}"), &format!("name-{i}"), counter)
            .await?;
    }
    assert_eq!(fixture.lookups.load(Ordering::SeqCst), 1);
    assert_eq!(fixture.stored_username().await?, "mallory");
    let display_name: String =
        sqlx::query_scalar("SELECT display_name FROM contacts WHERE user_id = 8")
            .fetch_one(&fixture.database.pool)
            .await?;
    assert_eq!(display_name, "Alice");
    let display_history: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM group_histories WHERE type = 'updatedContactDisplayName'",
    )
    .fetch_one(&fixture.database.pool)
    .await?;
    assert_eq!(
        display_history, 1,
        "discarding the username must preserve display-name history"
    );

    *fixture.username.lock().unwrap() = "mallory2".into();
    fixture.deliver("rename", "mallory2", Some(2)).await?;
    assert_eq!(fixture.stored_username().await?, "mallory");
    fixture.expire_cooldown().await?;
    fixture.wait_until_refreshed().await?;
    assert_eq!(fixture.stored_username().await?, "mallory2");
    assert_eq!(fixture.lookups.load(Ordering::SeqCst), 2);
    let rename_history: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM group_histories WHERE type = 'updatedContactUsername' AND \
         new_group_name = 'mallory2'",
    )
    .fetch_one(&fixture.database.pool)
    .await?;
    assert_eq!(rename_history, 1);
    Ok(())
}

#[tokio::test]
async fn stalled_lookup_does_not_hold_inbound_messages_or_create_more_lookups() -> anyhow::Result<()>
{
    let fixture = Fixture::new(0).await?;
    tokio::time::timeout(
        Duration::from_secs(2),
        fixture.deliver("stalled", "alice", Some(1)),
    )
    .await??;
    Fixture::wait_for_count(&fixture.lookups, 1).await?;

    let deliveries = (0..12).map(|i| {
        let fixture = &fixture;
        async move {
            fixture
                .deliver(
                    &format!("concurrent-{i}"),
                    &format!("claim-{i}"),
                    Some(i + 2),
                )
                .await
        }
    });
    for result in tokio::time::timeout(
        Duration::from_secs(3),
        futures_util::future::join_all(deliveries),
    )
    .await?
    {
        result?;
    }
    assert_eq!(fixture.lookups.load(Ordering::SeqCst), 1);
    assert_eq!(fixture.stored_username().await?, "mallory");
    fixture.replies.add_permits(1);
    Fixture::wait_for_count(&fixture.responses, 1).await?;
    // An update arriving during the lookup remains pending for a later refresh.
    let pending: i64 =
        sqlx::query_scalar("SELECT pending FROM contact_metadata_refreshes WHERE contact_id = 8")
            .fetch_one(&fixture.database.pool)
            .await?;
    assert_eq!(pending, 1);
    Ok(())
}

#[tokio::test]
async fn failed_lookup_spends_the_budget_without_retrying_the_mailbox_message() -> anyhow::Result<()>
{
    let fixture = Fixture::new(100).await?;
    fixture.fail.store(true, Ordering::SeqCst);
    fixture.deliver("failure", "alice", Some(1)).await?;
    Fixture::wait_for_count(&fixture.responses, 1).await?;
    for i in 0..8 {
        fixture
            .deliver(&format!("failed-{i}"), &format!("fake-{i}"), Some(i + 2))
            .await?;
    }
    assert_eq!(fixture.lookups.load(Ordering::SeqCst), 1);
    assert_eq!(fixture.stored_username().await?, "mallory");

    fixture.fail.store(false, Ordering::SeqCst);
    *fixture.username.lock().unwrap() = "renamed".into();
    fixture.expire_cooldown().await?;
    fixture.wait_until_refreshed().await?;
    assert_eq!(fixture.stored_username().await?, "renamed");
    assert_eq!(fixture.lookups.load(Ordering::SeqCst), 2);
    Ok(())
}

#[tokio::test]
async fn contact_requests_share_the_profile_lookup_budget() -> anyhow::Result<()> {
    let fixture = Fixture::new(100).await?;
    fixture.deliver("profile", "alice", Some(1)).await?;
    fixture.wait_until_refreshed().await?;
    for i in 0..8 {
        fixture
            .deliver_content(
                &format!("request-{i}"),
                EncryptedContent {
                    contact_request: Some(encrypted_content::ContactRequest {
                        r#type: Type::Request as i32,
                    }),
                    ..Default::default()
                },
            )
            .await?;
    }
    assert_eq!(fixture.lookups.load(Ordering::SeqCst), 1);
    assert_eq!(fixture.stored_username().await?, "mallory");
    Ok(())
}
