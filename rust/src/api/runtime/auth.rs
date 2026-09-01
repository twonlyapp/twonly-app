/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::client::ApiClient;
use super::helpers::{decode_ok, schedule_post_authentication};
use super::request::permanent_rejection_kind;
use crate::api::proto::{client_to_server, server_to_client};
use crate::bridge::api::{ApiConnectionState, ApiEvent, ApiEventKind, ServerResult};
use crate::context::Context;
use crate::error::{Result, TwonlyError};
use crate::user_config::UserConfig;
use async_trait::async_trait;
use prost::Message;
use rand::SeedableRng;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Weak};
use stream_tungstenite::context::ConnectionContext;
use stream_tungstenite::error::HandshakeError;
use stream_tungstenite::handshake::{HandshakeReceiver, HandshakeSender, Handshaker};
use stream_tungstenite::tokio_tungstenite::tungstenite;
use tokio::sync::broadcast;

/// The app version from `pubspec.yaml` without the build number, baked in by
/// `build.rs`. This is what the handshake reports to the server, which compares
/// it against its configured minimum version.
///
/// Not to be confused with `UserConfig::app_version`, which is the local
/// migration id and stays a purely client side concern.
pub(crate) const APP_VERSION: &str = env!("TWONLY_APP_VERSION");

pub(crate) struct ApiAuthHandshaker {
    pub context: Arc<Context>,
    pub api_client: Weak<ApiClient>,
    pub is_authenticated: Arc<AtomicBool>,
    pub in_background: bool,
    pub events: broadcast::Sender<ApiEvent>,
}

impl ApiAuthHandshaker {
    async fn get_identity(&self) -> Result<(Option<i64>, i64, String)> {
        let user = UserConfig::load_from(&self.context)?
            .ok_or_else(|| TwonlyError::Generic("User configuration not found".into()))?;
        let device_id = user.device_id;
        Ok((Some(user.user_id), device_id, APP_VERSION.to_string()))
    }

    async fn request_handshake(
        &self,
        sender: &mut dyn HandshakeSender,
        receiver: &mut dyn HandshakeReceiver,
        handshake: client_to_server::handshake::Handshake,
    ) -> std::result::Result<server_to_client::response::ok::Ok, HandshakeError> {
        let request = client_to_server::ClientToServer {
            v: Some(client_to_server::client_to_server::V::V0(
                client_to_server::V0 {
                    seq: 0,
                    kind: Some(client_to_server::v0::Kind::Handshake(
                        client_to_server::Handshake {
                            handshake: Some(handshake),
                        },
                    )),
                },
            )),
        };

        sender
            .send_msg(tungstenite::Message::Binary(request.encode_to_vec().into()))
            .await?;

        let msg = receiver
            .recv_msg()
            .await?
            .ok_or_else(|| HandshakeError::Protocol("Connection closed during handshake".into()))?;

        let bytes = match msg {
            tungstenite::Message::Binary(b) => b,
            _ => return Err(HandshakeError::Protocol("Expected binary message".into())),
        };

        let ok_res =
            decode_ok(bytes.to_vec()).map_err(|e| HandshakeError::Protocol(e.to_string()))?;
        let ok = match ok_res {
            ServerResult::Ok(val) => val,
            ServerResult::ErrorCode(code) => {
                // The handshake never reaches `handle_api_error`, so a rejection
                // that no reconnect can fix has to be published here — otherwise
                // the app just keeps failing to connect without telling the user
                // that it is outdated or was logged out.
                if let Some(kind) = permanent_rejection_kind(code) {
                    if let Some(client) = self.api_client.upgrade() {
                        // Closing the socket has to wait for this handshake to
                        // return, so it cannot be awaited from inside it.
                        tokio::spawn(async move { client.reject_permanently(kind).await });
                    }
                }
                return Err(HandshakeError::Protocol(format!(
                    "Server returned error code: {}",
                    code
                )));
            }
        };

        if let server_to_client::response::ok::Ok::Authenticated(authenticated) = &ok {
            persist_plan(&self.context, &authenticated.plan).await;
            let _ = self.events.send(ApiEvent {
                kind: ApiEventKind::PlanUpdated,
                state: None,
                message: Some(authenticated.plan.clone()),
            });
        }
        Ok(ok)
    }

    async fn authenticate_with_login_token(
        &self,
        sender: &mut dyn HandshakeSender,
        receiver: &mut dyn HandshakeReceiver,
        user_id: i64,
    ) -> Result<()> {
        let login_token = self
            .context
            .key_manager
            .lock()
            .await
            .main_key
            .get_login_token()
            .to_vec();
        let (_, device_id, app_version) = self.get_identity().await?;
        let handshake = client_to_server::handshake::Handshake::AuthenticateWithLoginToken(
            client_to_server::handshake::AuthenticateWithLoginToken {
                user_id,
                secret_login_token: login_token,
                app_version,
                device_id,
                in_background: self.in_background,
                supports_mailbox_v2: Some(true),
            },
        );
        self.request_handshake(sender, receiver, handshake)
            .await
            .map(|_| ())
            .map_err(|e| TwonlyError::Generic(e.to_string()))
    }

    async fn authenticate_with_legacy_token(
        &self,
        sender: &mut dyn HandshakeSender,
        receiver: &mut dyn HandshakeReceiver,
        user_id: i64,
    ) -> Result<bool> {
        use base64::Engine as _;
        let Some(encoded) = self.context.secure_storage.read("api_auth_token")? else {
            return Ok(false);
        };
        let auth_token = base64::engine::general_purpose::STANDARD
            .decode(encoded)
            .map_err(|error| TwonlyError::Generic(format!("invalid stored auth token: {error}")))?;
        let (_, device_id, app_version) = self.get_identity().await?;
        let handshake = client_to_server::handshake::Handshake::Authenticate(
            client_to_server::handshake::Authenticate {
                user_id,
                auth_token,
                app_version: Some(app_version),
                device_id: Some(device_id),
                in_background: Some(self.in_background),
                supports_mailbox_v2: Some(true),
            },
        );
        match self.request_handshake(sender, receiver, handshake).await {
            Ok(_) => Ok(true),
            Err(error) => {
                if error.to_string().contains("AuthTokenNotValid") {
                    // simple approximation
                    Ok(false)
                } else {
                    Err(TwonlyError::Generic(error.to_string()))
                }
            }
        }
    }

    async fn obtain_legacy_auth_token(
        &self,
        sender: &mut dyn HandshakeSender,
        receiver: &mut dyn HandshakeReceiver,
        user_id: i64,
    ) -> Result<()> {
        use base64::Engine as _;
        use libsignal_protocol::IdentityKeyPair;

        let challenge = self
            .request_handshake(
                sender,
                receiver,
                client_to_server::handshake::Handshake::GetAuthChallenge(
                    client_to_server::handshake::GetAuthChallenge {},
                ),
            )
            .await
            .map_err(|e| TwonlyError::Generic(e.to_string()))?;
        let server_to_client::response::ok::Ok::Authchallenge(challenge) = challenge else {
            return Err(TwonlyError::Generic(
                "auth challenge response has unexpected payload".into(),
            ));
        };
        let serialized_identity = self
            .context
            .key_manager
            .lock()
            .await
            .signal_identity
            .as_ref()
            .ok_or(TwonlyError::SignalIdentityNotFound)?
            .identity_key_pair_structure
            .clone();
        let identity = IdentityKeyPair::try_from(serialized_identity.as_slice())
            .map_err(|error| TwonlyError::Signal(error.to_string()))?;
        let mut rng = rand::rngs::StdRng::from_os_rng();
        let signature = identity
            .private_key()
            .calculate_signature_for_multipart_message(&[challenge.as_slice()], &mut rng)
            .map_err(|error| TwonlyError::Signal(error.to_string()))?;
        let token = self
            .request_handshake(
                sender,
                receiver,
                client_to_server::handshake::Handshake::GetAuthToken(
                    client_to_server::handshake::GetAuthToken {
                        user_id,
                        response: signature.to_vec(),
                    },
                ),
            )
            .await
            .map_err(|e| TwonlyError::Generic(e.to_string()))?;
        let server_to_client::response::ok::Ok::Authtoken(token) = token else {
            return Err(TwonlyError::Generic(
                "auth-token response has unexpected payload".into(),
            ));
        };
        self.context.secure_storage.write(
            "api_auth_token",
            &base64::engine::general_purpose::STANDARD.encode(token),
        )?;
        Ok(())
    }

    async fn migrate_to_login_token(
        &self,
        sender: &mut dyn HandshakeSender,
        receiver: &mut dyn HandshakeReceiver,
    ) -> Result<()> {
        let token = self
            .context
            .key_manager
            .lock()
            .await
            .main_key
            .get_login_token()
            .to_vec();
        let application = client_to_server::application_data::ApplicationData::SetLoginToken(
            client_to_server::application_data::SetLoginToken { login_token: token },
        );
        let request = client_to_server::ClientToServer {
            v: Some(client_to_server::client_to_server::V::V0(
                client_to_server::V0 {
                    seq: 0,
                    kind: Some(client_to_server::v0::Kind::Applicationdata(
                        client_to_server::ApplicationData {
                            application_data: Some(application),
                        },
                    )),
                },
            )),
        };
        sender
            .send_msg(tungstenite::Message::Binary(request.encode_to_vec().into()))
            .await
            .map_err(|e| TwonlyError::Generic(e.to_string()))?;
        let msg = receiver
            .recv_msg()
            .await
            .map_err(|e| TwonlyError::Generic(e.to_string()))?
            .unwrap();
        let bytes = match msg {
            tungstenite::Message::Binary(b) => b,
            _ => return Err(TwonlyError::Generic("Expected binary message".into())),
        };
        match decode_ok(bytes.to_vec())? {
            ServerResult::Ok(_) => {}
            ServerResult::ErrorCode(code) => return Err(TwonlyError::Api(code)),
        }
        self.context.secure_storage.delete("api_auth_token")?;
        let _ = self.events.send(ApiEvent {
            kind: ApiEventKind::LoginTokenMigrated,
            state: None,
            message: None,
        });

        Ok(())
    }

    fn authentication_succeeded(&self) {
        self.is_authenticated.store(true, Ordering::Release);

        if let Some(client) = self.api_client.upgrade() {
            client.note_authenticated();
            tokio::spawn(async move {
                client.set_state(ApiConnectionState::Authenticated).await;
                // Runs on every (re)connect, so this covers both the initial
                // authentication and reconnection catch-up.
                client.request_catch_up().await;
            });
        }

        let _ = self.events.send(ApiEvent {
            kind: ApiEventKind::Authenticated,
            state: Some(ApiConnectionState::Authenticated),
            message: None,
        });
        schedule_post_authentication(&self.context, self.in_background);
    }
}

#[async_trait]
impl Handshaker for ApiAuthHandshaker {
    async fn handshake(
        &self,
        sender: &mut dyn HandshakeSender,
        receiver: &mut dyn HandshakeReceiver,
        _context: &ConnectionContext,
    ) -> std::result::Result<(), HandshakeError> {
        let user = match UserConfig::load_from(&self.context)
            .map_err(|e| HandshakeError::Protocol(e.to_string()))?
        {
            Some(u) => u,
            None => {
                tracing::info!("ApiAuthHandshaker skipped: user config is not present");
                return Ok(());
            }
        };

        let user_id = self
            .context
            .key_manager
            .lock()
            .await
            .user_id
            .filter(|user_id| *user_id > 0);
        let Some(user_id) = user_id else {
            tracing::info!("ApiAuthHandshaker skipped: KeyManager has no registered user ID");
            return Ok(());
        };
        let can_use_login_token = user.can_use_login_token_for_auth;
        let app_version = user.app_version;

        let _ = self.events.send(ApiEvent {
            kind: ApiEventKind::ConnectionStateChanged,
            state: Some(ApiConnectionState::Authenticating),
            message: None,
        });

        if can_use_login_token {
            match self
                .authenticate_with_login_token(sender, receiver, user_id)
                .await
            {
                Ok(()) => {
                    tracing::info!("ApiAuthHandshaker: authenticated with login token");
                    self.authentication_succeeded();
                    return Ok(());
                }
                Err(error) => {
                    tracing::error!("ApiAuthHandshaker: login token auth failed ({})", error);
                    return Err(HandshakeError::Protocol(error.to_string()));
                }
            }
        } else if app_version >= 62
            && self
                .authenticate_with_legacy_token(sender, receiver, user_id)
                .await
                .unwrap_or(false)
        {
            tracing::info!("ApiAuthHandshaker: authenticated with legacy token");
            self.authentication_succeeded();
            return Ok(());
        }

        tracing::error!(
            "ApiAuthHandshaker: no auth method succeeded. legacy_app_version={}",
            app_version
        );

        if app_version < 62 {
            return Err(HandshakeError::Protocol(
                "legacy user version is too old for API authentication".into(),
            ));
        }

        if let Err(e) = self
            .obtain_legacy_auth_token(sender, receiver, user_id)
            .await
        {
            return Err(HandshakeError::Protocol(e.to_string()));
        }

        let authenticated = self
            .authenticate_with_legacy_token(sender, receiver, user_id)
            .await
            .unwrap_or(false);

        if !authenticated {
            return Err(HandshakeError::Protocol("API authentication failed".into()));
        }

        if !self.in_background {
            if let Err(e) = self.migrate_to_login_token(sender, receiver).await {
                return Err(HandshakeError::Protocol(e.to_string()));
            }
        }

        self.authentication_succeeded();
        Ok(())
    }

    fn name(&self) -> &'static str {
        "ApiAuthHandshaker"
    }
}

/// The server owns the subscription plan, so what it reports has to be written
/// to `user.json` and not only broadcast as a [`ApiEventKind::PlanUpdated`]
/// event. Everything that reads the plan without listening for that event reads
/// the stored value: the premium feature gates, the recording budget, and
/// `PurchasesProvider`, which re-reads it on every connection state change and
/// would otherwise overwrite the plan it was just told about with the `Free`
/// default.
async fn persist_plan(context: &Context, plan: &str) {
    // A reconnect reports the same plan almost every time, and every write
    // pushes a config update into Flutter, so only changes are worth storing.
    if matches!(
        UserConfig::load_from(context),
        Ok(Some(config)) if config.subscription_plan == plan
    ) {
        return;
    }
    let updated = match UserConfig::update(context, |config| {
        config.subscription_plan = plan.to_owned();
    }) {
        Ok(config) => config,
        Err(error) => {
            tracing::warn!("could not persist the subscription plan: {error}");
            return;
        }
    };
    if let Ok(callbacks) = crate::bridge::callbacks::get_callbacks() {
        (callbacks.api.user_config_changed)(updated).await;
    }
}

impl ApiClient {
    // publish_plan method logic moved inside Handshaker temporarily, but ApiClient should still have it if needed.
    pub(crate) async fn publish_plan(&self, plan: String) -> Result<()> {
        if let Some(context) = self.context.upgrade() {
            persist_plan(&context, &plan).await;
        }
        let _ = self.events.send(ApiEvent {
            kind: ApiEventKind::PlanUpdated,
            state: None,
            message: Some(plan),
        });
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::APP_VERSION;

    /// The server splits the reported version on '.' and parses every segment
    /// as a number, so a suffix like "0.5.2-beta" would silently be read as
    /// 0.5.0 and could fall below the configured minimum version.
    #[test]
    fn app_version_is_a_plain_dotted_version() {
        let segments: Vec<&str> = APP_VERSION.split('.').collect();

        assert!(
            !segments.is_empty() && segments.len() <= 3,
            "unexpected app version {APP_VERSION}"
        );
        for segment in segments {
            assert!(
                segment.parse::<u32>().is_ok(),
                "app version {APP_VERSION} has a non numeric segment {segment}"
            );
        }
    }

    /// Guards the `pubspec.yaml` parsing in `build.rs`.
    #[test]
    fn app_version_matches_the_pubspec() {
        let pubspec = std::fs::read_to_string("../pubspec.yaml").expect("read ../pubspec.yaml");
        let version = pubspec
            .lines()
            .find_map(|line| line.strip_prefix("version: "))
            .expect("no `version:` entry in ../pubspec.yaml");

        assert_eq!(
            APP_VERSION,
            version.split('+').next().unwrap_or(version).trim()
        );
    }
}
