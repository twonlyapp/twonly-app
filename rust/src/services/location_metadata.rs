/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Shared opt-in location acquisition for Memories and city stickers.

use crate::context::Context;
use crate::error::Result;
use crate::native::location::{self, LocationFix};
use crate::services::media_upload::MediaUploadService;
use crate::user_config::UserConfig;
use sqlx::FromRow;
use std::collections::HashSet;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, LazyLock, Mutex as SyncMutex};
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

/// Starts acquiring a fix at foreground app startup or when the camera opens.
/// Nothing is persisted until a media row exists; the result only warms the
/// in-process cache consumed by `initialize_for_media`.

pub(crate) fn prewarm(ctx: &Arc<Context>) -> Result<()> {
    let config = UserConfig::load_required_from(ctx)?;

    if !(config.store_location_in_memories || config.enable_location_sticker)
        || CAMERA_WARMUP_IN_FLIGHT.swap(true, Ordering::AcqRel)
    {
        return Ok(());
    }

    crate::database::lifecycle::spawn(async move {
        let _warmup = CameraWarmup;

        let mut request = LOCATION_REQUEST.lock().await;

        if request.as_ref().is_some_and(|(captured_at, _)| {
            captured_at.elapsed().unwrap_or(Duration::MAX)
                < Duration::from_secs(LOCATION_WINDOW_SECONDS as u64)
        }) {
            return;
        }

        let timeout = Duration::from_secs(LOCATION_WINDOW_SECONDS as u64);

        match crate::database::lifecycle::spawn_blocking(move || location::current(timeout)).await {
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

/// Reuses the same native request/cache as Memories without creating or
/// modifying a media row. The editor never waits for the full Memory window.

pub(crate) async fn current_for_sticker(ctx: &Arc<Context>) -> Result<Option<LocationFix>> {
    if !UserConfig::load_required_from(ctx)?.enable_location_sticker {
        return Ok(None);
    }

    let Ok(mut request) =
        tokio::time::timeout(Duration::from_secs(15), LOCATION_REQUEST.lock()).await
    else {
        return Ok(None);
    };

    // Recheck after waiting for another request or a settings change.
    if !UserConfig::load_required_from(ctx)?.enable_location_sticker {
        return Ok(None);
    }

    if let Some((captured_at, location)) = *request {
        if captured_at.elapsed().unwrap_or(Duration::MAX)
            < Duration::from_secs(LOCATION_WINDOW_SECONDS as u64)
        {
            return Ok(Some(location));
        }
    }

    // Keep the mutex until the blocking native request has stopped. Cancelling
    // its JoinHandle would leave that request racing a second native session.
    let location =
        crate::database::lifecycle::spawn_blocking(|| location::current(Duration::from_secs(12)))
            .await
            .map_err(|error| crate::error::TwonlyError::Generic(error.to_string()))??;

    if let Some(location) = location {
        *request = Some((SystemTime::now(), location));
    }

    // Disabling stickers while a native lookup runs must discard its result.
    if !UserConfig::load_required_from(ctx)?.enable_location_sticker {
        return Ok(None);
    }

    Ok(location)
}

pub(crate) async fn initialize_for_media(ctx: &Arc<Context>, media_id: &str) -> Result<()> {
    let config = UserConfig::load_required_from(ctx)?;

    if !config.store_location_in_memories {
        return Ok(());
    }

    let deadline = chrono::Utc::now().timestamp() + LOCATION_WINDOW_SECONDS;

    let database = ctx.app_db.read().await.clone();

    // Saving an editor capture creates a second row for its Memory. Carry its
    // original fix/window through, rather than restarting capture at save time.
    let existing: Option<(Option<String>, Option<i64>)> = sqlx::query_as(
        "SELECT location_status, location_deadline_at FROM media_files WHERE media_id = ?",
    )
    .bind(media_id)
    .fetch_optional(&database.pool)
    .await?;

    if let Some((Some(status), existing_deadline)) = existing {
        if status == "pending" {
            schedule(
                ctx,
                media_id.to_owned(),
                existing_deadline.unwrap_or(deadline),
            );
        }

        return Ok(());
    }

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

    crate::database::lifecycle::spawn(async move {
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

    let location = match crate::database::lifecycle::spawn_blocking(move || {
        location::current(timeout)
    })
    .await
    {
        Ok(Ok(location)) => location,
        Ok(Err(error)) => {
            tracing::warn!(%error, "Memory location request failed");

            None
        }
        Err(error) => {
            tracing::warn!(%error, "Memory location worker failed");

            None
        }
    };

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
            "UPDATE media_files SET location_status = 'timedOut' WHERE media_id = ? AND \
             location_status = 'pending'",
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

#[cfg(test)]

mod tests {

    use super::*;

    #[tokio::test]

    async fn sticker_opt_in_does_not_enable_memory_metadata() -> anyhow::Result<()> {
        let temp = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(temp.path().join("database"), temp.path().join("data"))
            .await?;

        UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"me","displayName":"Me","enableLocationSticker":true}"#,
        )?;

        let db = ctx.app_db.read().await.clone();

        sqlx::query("INSERT INTO media_files(media_id, type) VALUES ('sticker-only', 'image')")
            .execute(&db.pool)
            .await?;

        initialize_for_media(&ctx, "sticker-only").await?;

        let actual: (Option<String>, Option<f64>, Option<f64>) = sqlx::query_as(
            "SELECT location_status, location_latitude, location_longitude FROM media_files WHERE \
             media_id = 'sticker-only'",
        )
        .fetch_one(&db.pool)
        .await?;

        assert_eq!(actual, (None, None, None));

        Ok(())
    }

    #[tokio::test]

    async fn memory_opt_in_does_not_expose_sticker_coordinates() -> anyhow::Result<()> {
        let temp = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(temp.path().join("database"), temp.path().join("data"))
            .await?;

        UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"me","displayName":"Me","storeLocationInMemories":true}"#,
        )?;

        assert!(current_for_sticker(&ctx).await?.is_none());

        Ok(())
    }

    #[tokio::test]

    async fn initializing_a_saved_capture_preserves_its_original_fix_and_time() -> anyhow::Result<()>
    {
        let temp = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(temp.path().join("database"), temp.path().join("data"))
            .await?;

        UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"me","displayName":"Me","storeLocationInMemories":true}"#,
        )?;

        let db = ctx.app_db.read().await.clone();

        sqlx::query(
            "INSERT INTO media_files(media_id, type, created_at, location_status, \
             location_deadline_at, location_latitude, location_longitude, location_accuracy) \
             VALUES ('saved-capture', 'image', 1700000000, 'resolved', 1700000180, 52.52, 13.405, \
             8.5)",
        )
        .execute(&db.pool)
        .await?;

        initialize_for_media(&ctx, "saved-capture").await?;

        let actual: (String, i64, f64, f64, f64, i64) = sqlx::query_as(
            "SELECT location_status, location_deadline_at, location_latitude, location_longitude, \
             location_accuracy, created_at FROM media_files WHERE media_id = 'saved-capture'",
        )
        .fetch_one(&db.pool)
        .await?;

        assert_eq!(
            actual,
            (
                "resolved".into(),
                1700000180,
                52.52,
                13.405,
                8.5,
                1700000000
            )
        );

        Ok(())
    }

    #[tokio::test]

    async fn pending_saved_capture_keeps_its_original_location_deadline() -> anyhow::Result<()> {
        let temp = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(temp.path().join("database"), temp.path().join("data"))
            .await?;

        UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"me","displayName":"Me","storeLocationInMemories":true}"#,
        )?;

        let db = ctx.app_db.read().await.clone();

        sqlx::query(
            "INSERT INTO media_files(media_id, type, location_status, location_deadline_at) \
             VALUES ('pending-saved-capture', 'image', 'pending', 1700000180)",
        )
        .execute(&db.pool)
        .await?;

        initialize_for_media(&ctx, "pending-saved-capture").await?;

        let deadline: i64 = sqlx::query_scalar(
            "SELECT location_deadline_at FROM media_files WHERE media_id = 'pending-saved-capture'",
        )
        .fetch_one(&db.pool)
        .await?;

        assert_eq!(deadline, 1700000180);

        Ok(())
    }

    #[tokio::test]

    async fn expired_capture_is_not_given_another_location_window() -> anyhow::Result<()> {
        let temp = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(temp.path().join("database"), temp.path().join("data"))
            .await?;

        UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"me","displayName":"Me","storeLocationInMemories":true}"#,
        )?;

        let db = ctx.app_db.read().await.clone();

        sqlx::query(
            "INSERT INTO media_files(media_id, type, location_status, location_deadline_at) \
             VALUES ('expired-capture', 'image', 'timedOut', 1700000180)",
        )
        .execute(&db.pool)
        .await?;

        initialize_for_media(&ctx, "expired-capture").await?;

        let actual: (String, i64) = sqlx::query_as(
            "SELECT location_status, location_deadline_at FROM media_files WHERE media_id = \
             'expired-capture'",
        )
        .fetch_one(&db.pool)
        .await?;

        assert_eq!(actual, ("timedOut".into(), 1700000180));

        Ok(())
    }
}
