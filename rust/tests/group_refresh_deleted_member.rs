//! Runs the real group refresh and API error handler against loopback HTTP and
//! WebSocket fixtures. No development-server accounts or credentials are used.
//!
//! Keep this in its own integration-test binary: the API origin override is
//! process-wide, so it must not race unrelated API tests.

use chacha20poly1305::aead::{Aead, KeyInit};
use chacha20poly1305::{ChaCha20Poly1305, Nonce};
use futures_util::{SinkExt, StreamExt};
use libsignal_protocol::IdentityKeyPair;
use prost::Message;
use rand::SeedableRng;
use rust_lib_twonly::api::proto::{
    client, client_to_server, error, http_requests, server_to_client,
};
use rust_lib_twonly::api::ApiRuntime;
use rust_lib_twonly::bridge::api::ApiConnectionState;
use rust_lib_twonly::context::Context;
use rust_lib_twonly::database::app::groups::native::InsertGroup;
use rust_lib_twonly::services::groups::GroupService;
use std::ffi::OsString;
use std::sync::Arc;
use std::time::Duration;
use stream_tungstenite::tokio_tungstenite::{accept_async, tungstenite};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};
use tokio::sync::{mpsc, oneshot};
use tokio::time::timeout;

const GROUP_ID: &str = "deleted-member-repro";
const LOCAL_USER: i64 = 42;
const DELETED_MEMBER: i64 = 7;
const STATE_KEY: [u8; 32] = [19; 32];

struct ApiOrigin(Option<OsString>);

impl Drop for ApiOrigin {
    fn drop(&mut self) {
        match self.0.take() {
            Some(previous) => std::env::set_var("TWONLY_TEST_API_ORIGIN", previous),
            None => std::env::remove_var("TWONLY_TEST_API_ORIGIN"),
        }
    }
}

fn remote_group_state() -> anyhow::Result<Vec<u8>> {
    let state = client::EncryptedGroupState {
        member_ids: vec![LOCAL_USER, DELETED_MEMBER],
        admin_ids: vec![LOCAL_USER],
        group_name: "Deleted member reproduction".into(),
        ..Default::default()
    };
    let nonce = Nonce::try_from(&[3; 12][..]).unwrap();
    let mut sealed = ChaCha20Poly1305::new_from_slice(&STATE_KEY)
        .unwrap()
        .encrypt(&nonce, state.encode_to_vec().as_ref())
        .map_err(|_| anyhow::anyhow!("could not encrypt fixture group state"))?;
    let mac = sealed.split_off(sealed.len() - 16);
    Ok(http_requests::GroupState {
        version_id: 2,
        encrypted_group_state: client::EncryptedGroupStateEnvelop {
            nonce: vec![3; 12],
            encrypted_group_state: sealed,
            mac,
        }
        .encode_to_vec(),
        appended_group_states: vec![],
    }
    .encode_to_vec())
}

async fn serve_connection(
    mut socket: TcpStream, group_state: Arc<Vec<u8>>, lookup: mpsc::Sender<()>,
    response_gate: Arc<tokio::sync::Mutex<Option<oneshot::Receiver<()>>>>,
) -> anyhow::Result<()> {
    // Peek without consuming the WebSocket upgrade request.
    let mut header = [0; 4096];
    let length = loop {
        let length = socket.peek(&mut header).await?;
        anyhow::ensure!(length > 0, "connection ended before its HTTP request");
        if header[..length].contains(&b'\n') {
            break length;
        }
        tokio::task::yield_now().await;
    };
    if header[..length].starts_with(b"GET /api/group/state/") {
        let mut request = Vec::new();
        while !request.ends_with(b"\r\n\r\n") {
            anyhow::ensure!(request.len() < 4096, "oversized fixture HTTP request");
            request.push(socket.read_u8().await?);
        }
        anyhow::ensure!(
            request.starts_with(format!("GET /api/group/state/{GROUP_ID} ").as_bytes()),
            "unexpected group lookup"
        );
        let response = format!(
            "HTTP/1.1 200 OK\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
            group_state.len()
        );
        socket.write_all(response.as_bytes()).await?;
        socket.write_all(&group_state).await?;
        return Ok(());
    }

    anyhow::ensure!(header[..length].starts_with(b"GET /api/client "));
    let mut socket = accept_async(socket).await?;
    while let Some(message) = socket.next().await {
        let message = message?;
        if message.is_close() {
            break;
        }
        if !message.is_binary() {
            continue;
        }
        let request = client_to_server::ClientToServer::decode(message.into_data())?;
        let Some(client_to_server::client_to_server::V::V0(request)) = request.v else {
            anyhow::bail!("missing request envelope");
        };
        let Some(client_to_server::v0::Kind::Applicationdata(application)) = request.kind else {
            anyhow::bail!("unexpected handshake: fixture connects before installing its user ID");
        };
        let Some(client_to_server::application_data::ApplicationData::GetUserById(user)) =
            application.application_data
        else {
            anyhow::bail!("unexpected application request");
        };
        anyhow::ensure!(user.user_id == DELETED_MEMBER);
        lookup.send(()).await?;
        if let Some(gate) = response_gate.lock().await.take() {
            gate.await?;
        }
        let response = server_to_client::ServerToClient {
            v: Some(server_to_client::server_to_client::V::V0(
                server_to_client::V0 {
                    seq: request.seq,
                    kind: Some(server_to_client::v0::Kind::Response(
                        server_to_client::Response {
                            response: Some(server_to_client::response::Response::Error(
                                error::ErrorCode::UserIdNotFound as i32,
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
            .await?;
    }
    Ok(())
}

#[tokio::test]
async fn deleted_unknown_group_member_does_not_block_the_database_writer() -> anyhow::Result<()> {
    let listener = TcpListener::bind("127.0.0.1:0").await?;
    let _origin = ApiOrigin(std::env::var_os("TWONLY_TEST_API_ORIGIN"));
    std::env::set_var(
        "TWONLY_TEST_API_ORIGIN",
        format!("http://{}", listener.local_addr()?),
    );
    let (lookup, mut lookups) = mpsc::channel(4);
    let (release, response_gate) = oneshot::channel();
    let response_gate = Arc::new(tokio::sync::Mutex::new(Some(response_gate)));
    let group_state = Arc::new(remote_group_state()?);
    let (stop, mut stopped) = oneshot::channel::<()>();
    let server = tokio::spawn(async move {
        let mut connections = tokio::task::JoinSet::new();
        loop {
            tokio::select! {
                _ = &mut stopped => break,
                socket = listener.accept() => {
                    let (socket, _) = socket?;
                    connections.spawn(serve_connection(socket, group_state.clone(), lookup.clone(), response_gate.clone()));
                }
                Some(connection) = connections.join_next() => { connection??; }
            }
        }
        connections.shutdown().await;
        anyhow::Ok(())
    });

    let directory = tempfile::tempdir()?;
    let ctx = Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
        .await?;
    timeout(Duration::from_secs(3), async {
        while ApiRuntime::connection_state(&ctx).await? != ApiConnectionState::Connected {
            tokio::task::yield_now().await;
        }
        anyhow::Ok(())
    })
    .await??;
    let settings = directory.path().join("data/keyvalue");
    std::fs::create_dir_all(&settings)?;
    std::fs::write(
        settings.join("user.json"),
        serde_json::to_vec(&rust_lib_twonly::user_config::UserConfig {
            user_id: LOCAL_USER,
            username: "local".into(),
            is_user_discovery_enabled: false,
            ..Default::default()
        })?,
    )?;
    ctx.inject_test_user_id(LOCAL_USER).await?;
    let database = ctx.app_db.read().await.clone();
    let identity = IdentityKeyPair::generate(&mut rand::rngs::StdRng::from_os_rng());
    let mut transaction = database.pool.begin().await?;
    InsertGroup::builder()
        .group_id(GROUP_ID.into())
        .group_name("Before refresh".into())
        .state_encryption_key(STATE_KEY.to_vec())
        .my_group_private_key(identity.serialize().to_vec())
        .build()
        .execute(&mut transaction)
        .await?;
    transaction.commit().await?;

    let refresh_ctx = ctx.clone();
    let mut refresh = tokio::spawn(async move {
        GroupService::new(&refresh_ctx)
            .fetch_group_state(GROUP_ID.into())
            .await
    });
    timeout(Duration::from_secs(3), lookups.recv())
        .await?
        .ok_or_else(|| anyhow::anyhow!("mock server did not receive member lookup"))?;

    // A network lookup must not retain the writer: sending to an unrelated
    // chat needs it even while this member's response has not arrived.
    let independent_write = timeout(Duration::from_secs(1), async {
        let mut transaction = database.pool.begin().await?;
        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (99, 'unrelated')")
            .execute(&mut *transaction)
            .await?;
        transaction.commit().await
    })
    .await;
    release
        .send(())
        .map_err(|_| anyhow::anyhow!("mock server response gate closed"))?;

    // The real UserIdNotFound handler marks the member deleted. Before the
    // fix it tried to reacquire the writer held by this same refresh.
    let completion = timeout(Duration::from_secs(3), &mut refresh).await;
    if completion.is_err() {
        refresh.abort();
        let _ = refresh.await;
    }
    ApiRuntime::close(&ctx).await?;
    let _ = stop.send(());
    timeout(Duration::from_secs(3), server).await???;

    let completed = completion.expect("group refresh deadlocked after UserIdNotFound; its error handler cannot acquire the writer held by the refresh")??;
    assert!(completed, "remote group state should be applied");
    independent_write
        .expect("group member lookup held the writer, blocking an unrelated local write")?;
    let deleted: (String, i64) =
        sqlx::query_as("SELECT username, account_deleted FROM contacts WHERE user_id = ?")
            .bind(DELETED_MEMBER)
            .fetch_one(&database.pool)
            .await?;
    assert_eq!(deleted, ("[Unknown]".into(), 1));
    let remaining: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM receipts WHERE contact_id = ?")
        .bind(DELETED_MEMBER)
        .fetch_one(&database.pool)
        .await?;
    assert_eq!(
        remaining, 0,
        "deleted member must not keep retrying key requests"
    );
    database.close().await;
    ctx.rust_db.read().await.pool.close().await;
    Ok(())
}
