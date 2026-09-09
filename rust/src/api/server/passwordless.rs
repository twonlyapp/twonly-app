/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::Server;
use crate::api::proto::server_to_client::response::ok::Ok as ResponseOk;
use crate::api::proto::{self, client_to_server};
use crate::api::runtime::helpers::decode_ok_value;
use crate::api::server::server_ok;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::error::Result;
use std::sync::Arc;

impl Server {
    pub async fn register_passwordless_recovery(
        ctx: &Arc<Context>,
        encrypted_server_key: Vec<u8>,
        pin_unlock_token: Option<Vec<u8>>,
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
        ctx: &Arc<Context>,
        user_id: i64,
        server_key_protection: Vec<u8>,
        pin_unlock_token: Option<Vec<u8>>,
        pin_protection_key: Option<Vec<u8>>,
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
        ctx: &Arc<Context>,
        notification_id: String,
        encrypted_message: Vec<u8>,
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
        ctx: &Arc<Context>,
        notification_id: String,
        download_auth_token: Vec<u8>,
        lang_code: String,
        google_fcm: Option<String>,
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
        ctx: &Arc<Context>,
        notification_id: String,
        download_auth_token: Vec<u8>,
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
}
