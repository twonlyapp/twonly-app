/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::Server;
use crate::api::proto::server_to_client::response::ok::Ok as ResponseOk;
use crate::api::runtime::helpers::decode_ok_value;
use crate::api::server::server_ok;
use crate::api::{proto, proto::client_to_server};
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::error::Result;
use std::sync::Arc;

impl Server {
    pub async fn get_user_by_id_response(ctx: &Arc<Context>, user_id: i64) -> Result<Vec<u8>> {
        Self::application(
            ctx,
            client_to_server::application_data::ApplicationData::GetUserById(
                client_to_server::application_data::GetUserById { user_id },
            ),
        )
        .await
    }

    pub async fn get_user_by_id(
        ctx: &Arc<Context>,
        user_id: i64,
    ) -> Result<ServerResult<proto::server_to_client::response::UserData>> {
        let bytes = Self::get_user_by_id_response(ctx, user_id).await?;
        decode_ok_value(bytes, |value| match value {
            proto::server_to_client::response::ok::Ok::Userdata(user) => Some(user),
            _ => None,
        })
    }

    pub async fn check_for_deleted_usernames(ctx: &Arc<Context>) -> Result<()> {
        let database = ctx.app_db.read().await.clone();
        let contacts = sqlx::query_scalar!(
            "SELECT user_id FROM contacts WHERE username IN ('[deleted]', '[Unknown]')"
        )
        .fetch_all(&database.pool)
        .await?;
        for user_id in contacts {
            let user = match Self::get_user_by_id(ctx, user_id).await? {
                ServerResult::Ok(u) => u,
                ServerResult::ErrorCode(_) => continue,
            };
            if let Some(username) = user.username {
                let username = String::from_utf8(username)?;
                sqlx::query!(
                    "UPDATE contacts SET username = ? WHERE user_id = ?",
                    username,
                    user_id
                )
                .execute(&database.pool)
                .await?;
            }
        }
        database.notify_committed(["contacts"]);
        Ok(())
    }

    pub async fn get_user_id_from_username(
        ctx: &Arc<Context>,
        username: String,
    ) -> Result<ServerResult<i64>> {
        let bytes = Self::handshake(
            ctx,
            client_to_server::handshake::Handshake::GetUseridByUsername(
                client_to_server::handshake::GetUserIdByUsername { username },
            ),
        )
        .await?;
        decode_ok_value(bytes, |value| match value {
            ResponseOk::Userid(id) => Some(id),
            _ => None,
        })
    }

    pub async fn get_user_by_username(
        ctx: &Arc<Context>,
        username: String,
    ) -> Result<ServerResult<proto::server_to_client::response::UserData>> {
        let bytes = Self::application(
            ctx,
            client_to_server::application_data::ApplicationData::GetUserByUsername(
                client_to_server::application_data::GetUserByUsername { username },
            ),
        )
        .await?;

        decode_ok_value(bytes, |value| match value {
            ResponseOk::Userdata(user) => Some(user),
            _ => None,
        })
    }

    pub async fn remove_additional_user(
        ctx: &Arc<Context>,
        user_id: i64,
    ) -> Result<ServerResult<()>> {
        server_ok!(
            Self::application_for_contact(
                ctx,
                client_to_server::application_data::ApplicationData::RemoveAdditionalUser(
                    client_to_server::application_data::RemoveAdditionalUser { user_id },
                ),
                user_id,
            )
            .await?
        )
    }

    pub async fn report_user(
        ctx: &Arc<Context>,
        reported_user_id: i64,
        reason: String,
    ) -> Result<ServerResult<()>> {
        server_ok!(
            Self::application(
                ctx,
                client_to_server::application_data::ApplicationData::ReportUser(
                    client_to_server::application_data::ReportUser {
                        reported_user_id,
                        reason,
                    },
                ),
            )
            .await?
        )
    }

    pub async fn send_text_message(
        ctx: &Arc<Context>,
        user_id: i64,
        body: Vec<u8>,
    ) -> Result<ServerResult<()>> {
        server_ok!(
            Self::application_for_contact(
                ctx,
                client_to_server::application_data::ApplicationData::TextMessage(
                    client_to_server::application_data::TextMessage {
                        user_id,
                        body,
                        push_data: None,
                    },
                ),
                user_id,
            )
            .await?
        )
    }
}
