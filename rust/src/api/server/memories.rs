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
    pub async fn request_memories_upload(
        ctx: &Arc<Context>,
        size: i64,
        original_date: i64,
        media_id: String,
    ) -> Result<ServerResult<proto::server_to_client::response::MemoriesUploadUrls>> {
        let bytes = Self::application(
            ctx,
            client_to_server::application_data::ApplicationData::RequestMemoriesUpload(
                client_to_server::application_data::RequestMemoriesUpload {
                    size,
                    original_date,
                    media_id,
                },
            ),
        )
        .await?;

        decode_ok_value(bytes, |value| match value {
            ResponseOk::MemoriesUploadUrls(urls) => Some(urls),
            _ => None,
        })
    }

    pub async fn get_memories_usage(
        ctx: &Arc<Context>,
    ) -> Result<ServerResult<proto::server_to_client::response::MemoriesUsage>> {
        let bytes = Self::application(
            ctx,
            client_to_server::application_data::ApplicationData::GetMemoriesUsage(
                client_to_server::application_data::GetMemoriesUsage {},
            ),
        )
        .await?;

        decode_ok_value(bytes, |value| match value {
            ResponseOk::MemoriesUsage(usage) => Some(usage),
            _ => None,
        })
    }

    pub async fn get_memories_url(
        ctx: &Arc<Context>,
        media_id: String,
        thumbnail: bool,
    ) -> Result<ServerResult<proto::server_to_client::response::MemoriesUrl>> {
        let bytes = Self::application(
            ctx,
            client_to_server::application_data::ApplicationData::GetMemoriesUrl(
                client_to_server::application_data::GetMemoriesUrl {
                    media_id,
                    thumbnail,
                },
            ),
        )
        .await?;

        decode_ok_value(bytes, |value| match value {
            ResponseOk::MemoriesUrl(url) => Some(url),
            _ => None,
        })
    }

    pub async fn confirm_memories_upload(
        ctx: &Arc<Context>,
        media_id: String,
    ) -> Result<ServerResult<()>> {
        server_ok!(
            Self::application(
                ctx,
                client_to_server::application_data::ApplicationData::ConfirmMemoriesUpload(
                    client_to_server::application_data::ConfirmMemoriesUpload { media_id },
                ),
            )
            .await?
        )
    }

    pub async fn delete_memory(ctx: &Arc<Context>, media_id: String) -> Result<ServerResult<()>> {
        server_ok!(
            Self::application(
                ctx,
                client_to_server::application_data::ApplicationData::DeleteMemory(
                    client_to_server::application_data::DeleteMemory { media_id },
                ),
            )
            .await?
        )
    }

    pub async fn disable_memories_backup(ctx: &Arc<Context>) -> Result<ServerResult<()>> {
        server_ok!(
            Self::application(
                ctx,
                client_to_server::application_data::ApplicationData::DisableMemoriesBackup(
                    client_to_server::application_data::DisableMemoriesBackup {},
                ),
            )
            .await?
        )
    }
}
