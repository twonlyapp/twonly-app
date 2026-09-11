/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Optional, device-local location metadata for Memories.

use crate::context::Context;
use crate::error::{Result, TwonlyError};
use crate::native::location::{self, LocationFix};
use crate::services::media_upload::MediaUploadService;
use crate::user_config::UserConfig;
use sqlx::FromRow;
use std::collections::HashSet;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Mutex as SyncMutex;
use std::sync::{Arc, LazyLock};
use std::time::{Duration, SystemTime, UNIX_EPOCH};
use tokio::sync::Mutex;

pub(crate) const LOCATION_WINDOW_SECONDS: i64 = 3 * 60;

static LOCATION_REQUEST: LazyLock<Mutex<Option<(SystemTime, LocationFix)>>> =
    LazyLock::new(|| Mutex::new(None));
static LOCATION_IN_FLIGHT: LazyLock<SyncMutex<HashSet<String>>> = LazyLock::new(Default::default);
static CAMERA_WARMUP_IN_FLIGHT: AtomicBool = AtomicBool::new(false);

struct CameraWarmup;

impl Drop for CameraWarmup {
    fn drop(&mut self) {
        CAMERA_WARMUP_IN_FLIGHT.store(false, Ordering::Release);
    }
}

struct InFlight(String);

impl Drop for InFlight {
    fn drop(&mut self) {
        if let Ok(mut active) = LOCATION_IN_FLIGHT.lock() {
            active.remove(&self.0);
        }
    }
}

#[derive(FromRow)]
struct PendingLocation {
    media_id: String,
    location_deadline_at: i64,
}

/// Starts acquiring a fix as soon as the user opens a real capture camera.
/// Nothing is persisted until a media row exists; the result only warms the
/// in-process cache consumed by `initialize_for_media`.
pub(crate) fn prewarm(ctx: &Arc<Context>) -> Result<()> {
    if !UserConfig::load_required_from(ctx)?.store_location_in_memories
        || CAMERA_WARMUP_IN_FLIGHT.swap(true, Ordering::AcqRel)
    {
        return Ok(());
    }
    tokio::spawn(async move {
        let _warmup = CameraWarmup;
        let mut request = LOCATION_REQUEST.lock().await;
        if request.as_ref().is_some_and(|(captured_at, _)| {
            captured_at.elapsed().unwrap_or(Duration::MAX)
                < Duration::from_secs(LOCATION_WINDOW_SECONDS as u64)
        }) {
            return;
        }
        let timeout = Duration::from_secs(LOCATION_WINDOW_SECONDS as u64);
        match tokio::task::spawn_blocking(move || location::current(timeout)).await {
            Ok(Ok(Some(location))) => {
                *request = Some((SystemTime::now(), location));
            }
            Ok(Ok(None)) => {}
            Ok(Err(error)) => tracing::warn!(%error, "camera location warm-up failed"),
            Err(error) => tracing::warn!(%error, "camera location worker failed"),
        }
    });
    Ok(())
}

pub(crate) async fn initialize_for_media(ctx: &Arc<Context>, media_id: &str) -> Result<()> {
    let config = UserConfig::load_required_from(ctx)?;
    if !config.store_location_in_memories {
        return Ok(());
    }
    let deadline = chrono::Utc::now().timestamp() + LOCATION_WINDOW_SECONDS;
    let database = ctx.app_db.read().await.clone();
    sqlx::query(
        r#"UPDATE media_files
           SET location_status = 'pending', location_deadline_at = ?,
               location_latitude = NULL, location_longitude = NULL,
               location_accuracy = NULL
           WHERE media_id = ?"#,
    )
    .bind(deadline)
    .bind(media_id)
    .execute(&database.pool)
    .await?;
    drop(database);
    schedule(ctx, media_id.to_owned(), deadline);
    Ok(())
}

pub(crate) fn schedule(ctx: &Arc<Context>, media_id: String, deadline: i64) {
    let Ok(mut active) = LOCATION_IN_FLIGHT.lock() else {
        return;
    };
    if !active.insert(media_id.clone()) {
        return;
    }
    drop(active);
    let ctx = ctx.clone();
    tokio::spawn(async move {
        let _in_flight = InFlight(media_id.clone());
        if let Err(error) = capture(&ctx, &media_id, deadline).await {
            tracing::warn!(media_id, %error, "could not capture Memory location");
        }
    });
}

async fn capture(ctx: &Arc<Context>, media_id: &str, deadline: i64) -> Result<()> {
    // One native request serves captures made close together. Besides saving
    // battery, this avoids multiple CLLocationManager/LocationManager sessions
    // racing for identical coordinates.
    let mut request = LOCATION_REQUEST.lock().await;
    if let Some((captured_at, location)) = *request {
        let captured_before_deadline = captured_at
            .duration_since(UNIX_EPOCH)
            .map(|value| value.as_secs() <= deadline.max(0) as u64)
            .unwrap_or(false);
        if captured_before_deadline
            && captured_at.elapsed().unwrap_or(Duration::MAX)
                < Duration::from_secs(LOCATION_WINDOW_SECONDS as u64)
        {
            drop(request);
            finish(ctx, media_id, Some(location)).await?;
            return Ok(());
        }
    }
    // Recalculate only after waiting for another Memory's request. Otherwise
    // that wait would accidentally extend this Memory's three-minute window.
    let remaining = deadline.saturating_sub(chrono::Utc::now().timestamp());
    if remaining <= 0 {
        drop(request);
        finish(ctx, media_id, None).await?;
        return Ok(());
    }
    let timeout = Duration::from_secs(remaining as u64);
    let location = tokio::task::spawn_blocking(move || location::current(timeout))
        .await
        .map_err(|error| TwonlyError::Generic(format!("location worker failed: {error}")))??;
    if let Some(location) = location {
        *request = Some((SystemTime::now(), location));
    }
    drop(request);
    finish(ctx, media_id, location).await
}

async fn finish(ctx: &Arc<Context>, media_id: &str, location: Option<LocationFix>) -> Result<()> {
    let database = ctx.app_db.read().await.clone();
    if let Some(location) = location {
        sqlx::query(
            r#"UPDATE media_files
               SET location_status = 'resolved', location_latitude = ?,
                   location_longitude = ?, location_accuracy = ?
               WHERE media_id = ? AND location_status = 'pending'"#,
        )
        .bind(location.latitude)
        .bind(location.longitude)
        .bind(location.accuracy)
        .bind(media_id)
        .execute(&database.pool)
        .await?;
    } else {
        sqlx::query(
            "UPDATE media_files SET location_status = 'timedOut' WHERE media_id = ? AND location_status = 'pending'",
        )
        .bind(media_id)
        .execute(&database.pool)
        .await?;
    }
    drop(database);
    MediaUploadService::new(ctx)
        .finish_pending_gallery_export(media_id)
        .await
}

/// Resumes pending foreground requests and releases exports whose three-minute
/// deadline elapsed while the app was not running.
pub(crate) async fn resume(ctx: &Arc<Context>) -> Result<()> {
    let database = ctx.app_db.read().await.clone();
    let pending = sqlx::query_as::<_, PendingLocation>(
        r#"SELECT media_id, location_deadline_at
           FROM media_files WHERE location_status = 'pending'"#,
    )
    .fetch_all(&database.pool)
    .await?;
    drop(database);
    let now = chrono::Utc::now().timestamp();
    for item in pending {
        if item.location_deadline_at <= now {
            finish(ctx, &item.media_id, None).await?;
        } else if ctx.is_flutter_runtime() {
            schedule(ctx, item.media_id, item.location_deadline_at);
        }
    }
    Ok(())
}

/// Turning the option off must not leave already requested gallery exports in
/// limbo. Existing coordinates remain attached to their Memories.
pub(crate) async fn disable_pending(ctx: &Arc<Context>) -> Result<()> {
    let database = ctx.app_db.read().await.clone();
    let media_ids = sqlx::query_scalar::<_, String>(
        "SELECT media_id FROM media_files WHERE location_status = 'pending'",
    )
    .fetch_all(&database.pool)
    .await?;
    sqlx::query(
        "UPDATE media_files SET location_status = 'timedOut' WHERE location_status = 'pending'",
    )
    .execute(&database.pool)
    .await?;
    drop(database);
    for media_id in media_ids {
        MediaUploadService::new(ctx)
            .finish_pending_gallery_export(&media_id)
            .await?;
    }
    Ok(())
}
