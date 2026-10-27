/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::Server;
use crate::api::proto;
use crate::api::proto::client_to_server;
use crate::api::proto::server_to_client::response::ok::Ok as ResponseOk;
use crate::api::runtime::helpers::decode_ok_value;
use crate::api::server::server_ok;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::error::Result;
use std::sync::Arc;

impl Server {
    pub async fn get_user_by_id_response(ctx: &Arc<Context>, user_id: i64) -> Result<Vec<u8>> {
        // Sent for the contact so that a `UserIdNotFound` answer marks the
        // account as deleted instead of failing every prekey bundle fetch.
        Self::application_for_contact(
            ctx,
            client_to_server::application_data::ApplicationData::GetUserById(
                client_to_server::application_data::GetUserById { user_id },
            ),
            user_id,
        )
        .await
    }

    pub async fn get_user_by_id(
        ctx: &Arc<Context>, user_id: i64,
    ) -> Result<ServerResult<proto::server_to_client::response::UserData>> {
        let bytes = Self::get_user_by_id_response(ctx, user_id).await?;

        decode_ok_value(bytes, |value| match value {
            proto::server_to_client::response::ok::Ok::Userdata(user) => Some(user),
            _ => None,
        })
    }

    /// Loads the immutable account creation date for contacts that do not
    /// already have it. Server-deleted contacts are deliberately excluded.
    pub async fn refresh_contact_joined_dates(ctx: &Arc<Context>) -> Result<()> {
        let database = ctx.app_db.read().await.clone();

        let contact_ids = sqlx::query_scalar!(
            r#"
                SELECT user_id
                FROM contacts
                WHERE account_deleted = 0 AND joined_at IS NULL
            "#,
        )
        .fetch_all(&database.read_pool)
        .await?;

        for contact_id in contact_ids {
            let user = match Self::get_user_by_id(ctx, contact_id).await? {
                ServerResult::Ok(user) => user,
                // The shared API error handler marks UserIdNotFound contacts
                // as deleted. Other per-contact errors should not prevent the
                // remaining contacts from being refreshed.
                ServerResult::ErrorCode(_) => continue,
            };

            let Some(joined_at) = user.joined_at else {
                // Backwards compatibility while an older server is still
                // running: leave the value NULL so a later startup retries it.
                continue;
            };

            sqlx::query!(
                "UPDATE contacts SET joined_at = ? WHERE user_id = ?",
                joined_at,
                contact_id,
            )
            .execute(&database.pool)
            .await?;
        }

        Ok(())
    }

    pub async fn check_for_deleted_usernames(ctx: &Arc<Context>) -> Result<()> {
        let database = ctx.app_db.read().await.clone();

        let contacts = sqlx::query_scalar!(
            "SELECT user_id FROM contacts WHERE username IN ('[deleted]', '[Unknown]') AND \
             account_deleted = 0"
        )
        .fetch_all(&database.pool)
        .await?;

        Self::refresh_usernames(ctx, contacts).await
    }

    /// Looks up the usernames of contacts that were stored without one. An
    /// account the server no longer knows is marked deleted by the API error
    /// handler and skipped.
    ///
    /// Never call this inside a transaction: that error handler writes through
    /// the pool, and the app database has a single write connection.
    pub(crate) async fn refresh_usernames(ctx: &Arc<Context>, user_ids: Vec<i64>) -> Result<()> {
        let database = ctx.app_db.read().await.clone();

        for user_id in user_ids {
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

        Ok(())
    }

    pub async fn get_user_id_from_username(
        ctx: &Arc<Context>, username: String,
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
        ctx: &Arc<Context>, username: String,
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
        ctx: &Arc<Context>, user_id: i64,
    ) -> Result<ServerResult<()>> {
        // Not sent for the contact: the server checks the plan here too, and
        // its `UserIdNotFound` must not mark the user deleted.
        server_ok!(
            Self::application(
                ctx,
                client_to_server::application_data::ApplicationData::RemoveAdditionalUser(
                    client_to_server::application_data::RemoveAdditionalUser { user_id },
                ),
            )
            .await?
        )
    }

    pub async fn report_user(
        ctx: &Arc<Context>, reported_user_id: i64, reason: String,
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
        ctx: &Arc<Context>, user_id: i64, body: Vec<u8>, wake_receiver: bool,
    ) -> Result<ServerResult<()>> {
        server_ok!(
            Self::application_for_contact(
                ctx,
                client_to_server::application_data::ApplicationData::TextMessage(
                    client_to_server::application_data::TextMessage {
                        user_id,
                        body,
                        wake_receiver,
                    },
                ),
                user_id,
            )
            .await?
        )
    }
}
