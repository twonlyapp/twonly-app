/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::Server;
use crate::api::proto::client_to_server;
use crate::api::proto::server_to_client::response::ok::Ok as ResponseOk;
use crate::api::runtime::helpers::decode_ok_value;
use crate::api::server::server_ok;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::error::Result;
use std::sync::Arc;

impl Server {
    pub async fn get_plan_balance(ctx: &Arc<Context>) -> Result<Vec<u8>> {
        Self::application(
            ctx,
            client_to_server::application_data::ApplicationData::GetCurrentPlanInfos(
                client_to_server::application_data::GetCurrentPlanInfos {},
            ),
        )
        .await
    }

    pub async fn load_plan_balance(ctx: &Arc<Context>, use_cache: bool) -> Result<Vec<u8>> {
        let database = ctx.get_app_database().await;
        match Self::get_plan_balance(ctx).await {
            Ok(response) => {
                sqlx::query!(
                    r#"
                INSERT INTO api_state(key, value) VALUES('plan_balance', ?)
                ON CONFLICT(key) DO UPDATE SET value = excluded.value,
                    updated_at = CAST(strftime('%s', 'now') AS INTEGER)
                "#,
                    response,
                )
                .execute(&database.pool)
                .await?;
                database.notify_committed(["api_state"]);
                Ok(response)
            }
            Err(network_error) if use_cache => {
                sqlx::query_scalar!("SELECT value FROM api_state WHERE key = 'plan_balance'")
                    .fetch_optional(&database.pool)
                    .await?
                    .ok_or(network_error)
            }
            Err(error) => Err(error),
        }
    }

    pub async fn ipa_purchase(
        ctx: &Arc<Context>,
        product_id: String,
        source: String,
        verification_data: String,
    ) -> Result<Vec<u8>> {
        Self::application(
            ctx,
            client_to_server::application_data::ApplicationData::IpaPurchase(
                client_to_server::application_data::IpaPurchase {
                    product_id,
                    source,
                    verification_data,
                },
            ),
        )
        .await
    }

    pub async fn add_additional_user(ctx: &Arc<Context>, user_id: i64) -> Result<ServerResult<()>> {
        server_ok!(
            Self::application_for_contact(
                ctx,
                client_to_server::application_data::ApplicationData::AddAdditionalUser(
                    client_to_server::application_data::AddAdditionalUser { user_id },
                ),
                user_id,
            )
            .await?
        )
    }

    pub async fn force_ipa_check(ctx: &Arc<Context>) -> Result<ServerResult<()>> {
        server_ok!(
            Self::application(
                ctx,
                client_to_server::application_data::ApplicationData::IpaForceCheck(
                    client_to_server::application_data::IpaForceCheck {},
                ),
            )
            .await?
        )
    }
}
