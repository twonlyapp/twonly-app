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
        ctx: &Arc<Context>, size: i64, original_date: i64, media_id: String,
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
        ctx: &Arc<Context>, media_id: String, thumbnail: bool,
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
        ctx: &Arc<Context>, media_id: String,
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

    /// One page of confirmed memories, newest first. Pass the last item's
    /// date and id to continue; equal dates are never skipped.
    pub async fn get_memories_list(
        ctx: &Arc<Context>, offset_date: i64, offset_media_id: Option<String>, limit: i64,
    ) -> Result<ServerResult<proto::server_to_client::response::MemoriesList>> {
        let bytes = Self::application(
            ctx,
            client_to_server::application_data::ApplicationData::GetMemoriesList(
                client_to_server::application_data::GetMemoriesList {
                    offset_date,
                    limit,
                    offset_media_id,
                },
            ),
        )
        .await?;

        decode_ok_value(bytes, |value| match value {
            ResponseOk::MemoriesList(list) => Some(list),
            _ => None,
        })
    }

    pub async fn claim_importer_pairing(
        ctx: &Arc<Context>, pairing_id: String, envelope: Vec<u8>, import_id: String,
        token_hash: Vec<u8>,
    ) -> Result<ServerResult<()>> {
        server_ok!(
            Self::application(
                ctx,
                client_to_server::application_data::ApplicationData::ClaimImporterPairing(
                    client_to_server::application_data::ClaimImporterPairing {
                        pairing_id,
                        envelope,
                        import_id,
                        token_hash,
                    },
                ),
            )
            .await?
        )
    }

    pub async fn list_memory_importers(
        ctx: &Arc<Context>,
    ) -> Result<ServerResult<proto::server_to_client::response::MemoryImporters>> {
        let bytes = Self::application(
            ctx,
            client_to_server::application_data::ApplicationData::ListMemoryImporters(
                client_to_server::application_data::ListMemoryImporters {},
            ),
        )
        .await?;

        decode_ok_value(bytes, |value| match value {
            ResponseOk::MemoryImporters(importers) => Some(importers),
            _ => None,
        })
    }

    pub async fn revoke_memory_importer(
        ctx: &Arc<Context>, importer_id: String,
    ) -> Result<ServerResult<()>> {
        server_ok!(
            Self::application(
                ctx,
                client_to_server::application_data::ApplicationData::RevokeMemoryImporter(
                    client_to_server::application_data::RevokeMemoryImporter { importer_id },
                ),
            )
            .await?
        )
    }

    pub async fn delete_memory_importer_uploads(
        ctx: &Arc<Context>, importer_id: String,
    ) -> Result<ServerResult<()>> {
        server_ok!(
            Self::application(
                ctx,
                client_to_server::application_data::ApplicationData::DeleteMemoryImporterUploads(
                    client_to_server::application_data::DeleteMemoryImporterUploads {
                        importer_id,
                    },
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
