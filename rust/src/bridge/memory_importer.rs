/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! The memories importer for Flutter: pairing a page, the connected and past
//! imports in Settings, and discovering imported memories.

use crate::api::Server;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::error::{Result, TwonlyError};
use crate::frb_generated::StreamSink;
use crate::services::memory_import_progress;
use crate::services::memory_importer as service;
use flutter_rust_bridge::frb;

pub struct RustMemoryImporter();

/// A connected (or recently ended) importer page, as the server lists it.
#[derive(Debug, Clone)]
pub struct ImporterInfo {
    pub id: String,
    pub created_at: i64,
    pub last_used_at: Option<i64>,
    pub expires_at: i64,
    pub revoked_at: Option<i64>,
    pub uploaded_count: i64,
    pub uploaded_bytes: i64,
    pub idle_expires_at: i64,
    pub active: bool,
}

/// Memories from one import on this device.
#[derive(Debug, Clone)]
pub struct PastImportInfo {
    pub importer_id: String,
    /// Already mapped to a display name; an unknown source reads "another app".
    pub source_name: String,
    pub count: i64,
    pub first_created_at: i64,
    pub last_created_at: i64,
}

#[derive(Debug, Clone)]
pub struct UnreadableImportInfo {
    pub media_id: String,
    pub importer_id: Option<String>,
    pub reason: String,
}

/// How far this device is with adding memories an importer page uploaded.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MemoryImportProgress {
    pub active: bool,
    /// Imported memories this device lacked when the download started,
    /// raised when more arrive meanwhile.
    pub total: i64,
    /// Of those, handled so far, including ones that could not be added.
    pub done: i64,
    /// Every memory announced so far is handled. An import page uploads in
    /// batches, so the bar stays a little while for the next one.
    pub waiting: bool,
}

fn api<T>(result: ServerResult<T>) -> Result<T> {
    match result {
        ServerResult::Ok(value) => Ok(value),
        ServerResult::ErrorCode(code) => Err(TwonlyError::Api(code)),
    }
}

impl RustMemoryImporter {
    /// Whether `link` is an importer pairing link. Only the in-app scanner
    /// and system-camera opens may lead to the connect screen.
    #[frb(sync)]
    pub fn is_pairing_link(link: String) -> bool {
        service::parse_pairing_link(&link).is_ok()
    }

    /// Claims the pairing for this account and returns the import id. Fails
    /// with `API error code 1040` when someone else scanned the code first.
    pub async fn claim(link: String) -> Result<String> {
        let ctx = Context::get_static()?;
        Ok(api(service::claim(ctx, &link).await?)?.import_id)
    }

    pub async fn list() -> Result<Vec<ImporterInfo>> {
        let ctx = Context::get_static()?;
        let importers = api(Server::list_memory_importers(ctx).await?)?;
        Ok(importers
            .importers
            .into_iter()
            .map(|i| ImporterInfo {
                id: i.id,
                created_at: i.created_at,
                last_used_at: i.last_used_at,
                expires_at: i.expires_at,
                revoked_at: i.revoked_at,
                uploaded_count: i.uploaded_count,
                uploaded_bytes: i.uploaded_bytes,
                idle_expires_at: i.idle_expires_at,
                active: i.active,
            })
            .collect())
    }

    /// "Remove and keep its memories".
    pub async fn revoke(importer_id: String) -> Result<()> {
        let ctx = Context::get_static()?;
        api(Server::revoke_memory_importer(ctx, importer_id).await?)
    }

    /// "Remove and delete everything it uploaded", also for past imports.
    pub async fn delete_import(importer_id: String) -> Result<()> {
        service::delete_import(Context::get_static()?, &importer_id).await
    }

    pub async fn past_imports() -> Result<Vec<PastImportInfo>> {
        let imports = service::past_imports(Context::get_static()?).await?;
        Ok(imports
            .into_iter()
            .map(|i| PastImportInfo {
                source_name: service::source_display_name(&i.source).to_owned(),
                importer_id: i.importer_id,
                count: i.count,
                first_created_at: i.first_created_at,
                last_created_at: i.last_created_at,
            })
            .collect())
    }

    pub async fn unreadable() -> Result<Vec<UnreadableImportInfo>> {
        let items = service::unreadable_imports(Context::get_static()?).await?;
        Ok(items
            .into_iter()
            .map(|i| UnreadableImportInfo {
                media_id: i.media_id,
                importer_id: i.importer_id,
                reason: i.reason,
            })
            .collect())
    }

    pub async fn delete_unreadable(media_id: String) -> Result<()> {
        service::delete_unreadable(Context::get_static()?, &media_id).await
    }

    /// Looks for imported memories this device does not have yet; cheap when
    /// nothing changed. Returns whether a scan was started.
    pub async fn reconcile(force: bool) -> Result<bool> {
        service::reconcile_if_needed(Context::get_static()?, force).await
    }

    /// Streams the progress of downloading imported memories, starting with
    /// the current state.
    pub async fn progress(sink: StreamSink<MemoryImportProgress>) -> Result<()> {
        memory_import_progress::stream(sink).await
    }

    /// Developer option: shows the import bar with made-up numbers.
    pub async fn preview_progress() -> Result<()> {
        memory_import_progress::preview().await;
        Ok(())
    }
}
