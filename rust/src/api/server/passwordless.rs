/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::Server;
use crate::api::proto::error::ErrorCode;
use crate::api::proto::server_to_client::response::ok::Ok as ResponseOk;
use crate::api::proto::{self, client_to_server};
use crate::api::runtime::helpers::{decode_empty_ok, decode_ok_value};
use crate::api::server::server_ok;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::error::{Result, TwonlyError};
use crate::keys::KeyManager;
use std::sync::Arc;

impl Server {
    pub async fn register_passwordless_recovery(
        ctx: &Arc<Context>, encrypted_server_key: Vec<u8>, pin_unlock_token: Option<Vec<u8>>,
    ) -> Result<ServerResult<()>> {
        server_ok!(
            Self::application(
                ctx,
                client_to_server::application_data::ApplicationData::RegisterPasswordlessRecovery(
                    client_to_server::application_data::RegisterPasswordLessRecovery {
                        encrypted_server_key,
                        pin_unlock_token,
                    },
                ),
            )
            .await?
        )
    }

    pub async fn get_server_key_for_passwordless_recovery(
        ctx: &Arc<Context>, user_id: i64, server_key_protection: Vec<u8>,
        pin_unlock_token: Option<Vec<u8>>, pin_protection_key: Option<Vec<u8>>,
        email: Option<String>,
    ) -> Result<ServerResult<Vec<u8>>> {
        let bytes = Self::handshake(
            ctx,
            client_to_server::handshake::Handshake::GetServerKeyForPasswordlessRecovery(
                client_to_server::handshake::GetServerKeyForPasswordLessRecovery {
                    user_id,
                    server_key_protection,
                    pin_unlock_token,
                    pin_protection_key,
                    email,
                },
            ),
        )
        .await?;

        decode_ok_value(bytes, |value| match value {
            ResponseOk::PasswordlessRecoveryServerKey(key) => Some(key),
            _ => None,
        })
    }

    pub async fn submit_recovery_share(
        ctx: &Arc<Context>, notification_id: String, encrypted_message: Vec<u8>,
    ) -> Result<ServerResult<()>> {
        server_ok!(
            Self::application(
                ctx,
                client_to_server::application_data::ApplicationData::PasswordlessNotification(
                    client_to_server::application_data::PasswordlessNotification {
                        notification_id,
                        encrypted_message,
                    },
                ),
            )
            .await?
        )
    }

    pub async fn register_passwordless_notification(
        ctx: &Arc<Context>, notification_id: String, download_auth_token: Vec<u8>,
        lang_code: String, google_fcm: Option<String>,
    ) -> Result<ServerResult<()>> {
        server_ok!(
            Self::handshake(
                ctx,
                client_to_server::handshake::Handshake::RegisterPasswordlessNotification(
                    client_to_server::handshake::RegisterPasswordlessNotification {
                        notification_id,
                        download_auth_token,
                        lang_code,
                        google_fcm,
                    },
                ),
            )
            .await?
        )
    }

    pub async fn check_for_passwordless_notification(
        ctx: &Arc<Context>, notification_id: String, download_auth_token: Vec<u8>,
        already_received_message_ids: Vec<i64>,
    ) -> Result<ServerResult<proto::server_to_client::response::PasswordlessNotificationMessages>>
    {
        let bytes = Self::handshake(
            ctx,
            client_to_server::handshake::Handshake::CheckForPasswordlessNotification(
                client_to_server::handshake::CheckForPasswordlessNotification {
                    notification_id,
                    download_auth_token,
                    already_received_message_ids,
                },
            ),
        )
        .await?;

        decode_ok_value(bytes, |value| match value {
            ResponseOk::PasswordlessNotificationMessages(msgs) => Some(msgs),
            // The server answers with `None` whenever the poll finds no unseen
            // message, which is the normal outcome once every share arrived.
            ResponseOk::None(_) => {
                Some(proto::server_to_client::response::PasswordlessNotificationMessages::default())
            }
            _ => None,
        })
    }

    /// Whether `serialized_key_manager` holds the login token the server has
    /// for `user_id`. A recovery checks this before staging keys, so shares
    /// that pair one account's id with other keys stop here.
    ///
    /// `VerifyLoginToken` checks the token like a login does but leaves the
    /// session logged out.
    pub async fn verify_recovered_identity(
        ctx: &Arc<Context>, user_id: i64, serialized_key_manager: &[u8],
    ) -> Result<bool> {
        let key_manager = KeyManager::from_bytes(serialized_key_manager)?;

        if key_manager.user_id.is_some_and(|id| id != user_id) {
            return Ok(false);
        }

        let bytes = Self::handshake(
            ctx,
            client_to_server::handshake::Handshake::VerifyLoginToken(
                client_to_server::handshake::VerifyLoginToken {
                    user_id,
                    secret_login_token: key_manager.main_key.get_login_token().to_vec(),
                },
            ),
        )
        .await?;

        match decode_empty_ok(bytes)? {
            ServerResult::Ok(()) => Ok(true),
            ServerResult::ErrorCode(code)
                if code == ErrorCode::AuthTokenNotValid as i32
                    || code == ErrorCode::UserIdNotFound as i32 =>
            {
                Ok(false)
            }
            ServerResult::ErrorCode(code) => Err(TwonlyError::Api(code)),
        }
    }
}
