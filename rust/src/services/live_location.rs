//! Live sharing owns one text card per active chat and only its latest fix.

use crate::api::messages::incoming::messages::{queue_encrypted_content, send_queued_receipt};
use crate::api::messages::outgoing::decorate_content;
use crate::api::proto::client::{self as proto, additional_message_data, encrypted_content};
use crate::bridge::live_location::LiveLocationSession;
use crate::context::Context;
use crate::database::app::groups::native::Group;
use crate::error::{Result, TwonlyError};
use prost::Message as _;
use sqlx::{Sqlite, Transaction};
use std::sync::{Arc, LazyLock};
use tokio::sync::Mutex;

static SHARING: LazyLock<Mutex<()>> = LazyLock::new(|| Mutex::new(()));

pub const DURATIONS: &[i64] = &[600, 1200, 3600, 7200, 28800];

/// A restored chat archive must never restart sharing on another device.
pub(crate) async fn discard_sessions(pool: &sqlx::SqlitePool) -> Result<()> {
    let mut connection = pool.acquire().await?;

    discard_sessions_on(&mut connection).await
}

pub(crate) async fn discard_sessions_on(connection: &mut sqlx::SqliteConnection) -> Result<()> {
    let mut t = sqlx::Connection::begin(connection).await?;

    sqlx::query!(
        "DELETE FROM receipts WHERE receipt_id IN (SELECT receipt_id FROM live_location_outbox)",
    )
    .execute(&mut *t)
    .await?;

    sqlx::query!("DELETE FROM live_location_targets WHERE 1")
        .execute(&mut *t)
        .await?;

    sqlx::query!("DELETE FROM live_location_sessions WHERE 1")
        .execute(&mut *t)
        .await?;

    sqlx::query!("DELETE FROM live_location_pending WHERE 1")
        .execute(&mut *t)
        .await?;

    t.commit().await?;

    Ok(())
}

fn now() -> i64 {
    chrono::Utc::now().timestamp_millis()
}

fn invalid() -> TwonlyError {
    TwonlyError::Generic("Invalid live location data".into())
}

pub(crate) fn decode(bytes: &[u8]) -> Option<proto::LiveLocationData> {
    let data = proto::AdditionalMessageData::decode(bytes).ok()?;

    (data.r#type == additional_message_data::Type::LiveLocation as i32)
        .then_some(data.live_location)
        .flatten()
}

fn encode(location: &proto::LiveLocationData) -> Vec<u8> {
    proto::AdditionalMessageData {
        r#type: additional_message_data::Type::LiveLocation as i32,
        live_location: Some(location.clone()),
        ..Default::default()
    }
    .encode_to_vec()
}

pub(crate) fn validate(location: &proto::LiveLocationData) -> Result<()> {
    if uuid::Uuid::parse_str(&location.session_id).is_err()
        || uuid::Uuid::parse_str(&location.message_id).is_err()
        || location.updated_at_ms <= 0
        || location.expires_at_ms <= 0
        || location.updated_at_ms > now() + 300_000
        || location.expires_at_ms > location.updated_at_ms + 28_800_000
        || (!location.stopped && location.updated_at_ms > location.expires_at_ms)
    {
        return Err(invalid());
    }

    match (
        location.latitude,
        location.longitude,
        location.accuracy,
        location.fix_timestamp_ms,
    ) {
        (None, None, None, None) => {}
        (Some(lat), Some(lon), Some(accuracy), Some(time))
            if lat.is_finite()
                && lon.is_finite()
                && accuracy.is_finite()
                && (-90.0..=90.0).contains(&lat)
                && (-180.0..=180.0).contains(&lon)
                && (0.0..=100_000.0).contains(&accuracy)
                && time > 0
                && time <= location.updated_at_ms + 300_000 => {}
        _ => return Err(invalid()),
    }

    Ok(())
}

pub(crate) async fn active(ctx: &Arc<Context>) -> Result<Option<LiveLocationSession>> {
    let db = ctx.app_db.read().await.clone();

    let row: Option<(String, i64)> =
        sqlx::query_as("SELECT session_id, expires_at_ms FROM live_location_sessions LIMIT 1")
            .fetch_optional(&db.pool)
            .await?;

    let Some((session_id, expires_at_ms)) = row else {
        return Ok(None);
    };

    let group_ids = sqlx::query_scalar(
        "SELECT group_id FROM live_location_targets WHERE session_id = ? ORDER BY group_id",
    )
    .bind(&session_id)
    .fetch_all(&db.pool)
    .await?;

    Ok(Some(LiveLocationSession {
        session_id,
        expires_at_ms,
        group_ids,
    }))
}

pub(crate) async fn state(ctx: &Arc<Context>) -> Result<Option<LiveLocationSession>> {
    let session = active(ctx).await?;

    if let Some(session) = session.as_ref() {
        if session.expires_at_ms <= now() {
            stop(ctx, &session.session_id).await?;

            return Ok(None);
        }

        let db = ctx.app_db.read().await.clone();

        let cards: Vec<(Vec<u8>, bool)> = sqlx::query_as(
            "SELECT m.additional_message_data, m.is_deleted_from_sender FROM \
             live_location_targets lt JOIN messages m ON m.message_id = lt.message_id WHERE \
             lt.session_id = ?",
        )
        .bind(&session.session_id)
        .fetch_all(&db.pool)
        .await?;

        if cards.iter().any(|(bytes, deleted)| {
            *deleted || decode(bytes).is_none_or(|card| card.stopped || card.expires_at_ms <= now())
        }) {
            update(ctx, &session.session_id, None, false).await?;

            return active(ctx).await;
        }
    }

    Ok(session)
}

pub(crate) async fn start(
    ctx: &Arc<Context>, mut group_ids: Vec<String>, duration: i64, text: String,
) -> Result<LiveLocationSession> {
    let _sharing = SHARING.lock().await;

    group_ids.sort();

    group_ids.dedup();

    if !DURATIONS.contains(&duration) || group_ids.is_empty() || group_ids.len() > 50 {
        return Err(invalid());
    }

    let previous = active(ctx).await?;

    if previous.as_ref().is_some_and(|session| {
        group_ids
            .iter()
            .any(|group| session.group_ids.contains(group))
    }) {
        return Err(TwonlyError::Generic(
            "Location is already being shared in this chat".into(),
        ));
    }

    if previous
        .as_ref()
        .is_some_and(|session| session.group_ids.len() + group_ids.len() > 50)
    {
        return Err(invalid());
    }

    let session_id = previous
        .as_ref()
        .map(|session| session.session_id.clone())
        .unwrap_or_else(|| uuid::Uuid::new_v4().to_string());

    let timestamp = now();

    let expires_at_ms = timestamp + duration * 1000;

    let worker_deadline = previous.as_ref().map_or(expires_at_ms, |session| {
        session.expires_at_ms.max(expires_at_ms)
    });

    let db = ctx.app_db.read().await.clone();

    let mut t = db.pool.begin().await?;

    sqlx::query(
        "INSERT INTO live_location_sessions(session_id, expires_at_ms) VALUES (?, ?) ON \
         CONFLICT(session_id) DO UPDATE SET expires_at_ms = excluded.expires_at_ms",
    )
    .bind(&session_id)
    .bind(worker_deadline)
    .execute(&mut *t)
    .await?;

    let mut queued = Vec::new();

    for group_id in &group_ids {
        let allowed: bool = sqlx::query_scalar(
            "SELECT EXISTS(SELECT 1 FROM groups WHERE group_id = ? AND left_group = 0)",
        )
        .bind(group_id)
        .fetch_one(&mut *t)
        .await?;

        if !allowed {
            return Err(invalid());
        }

        let recipients: Vec<i64> = sqlx::query_scalar(
            "SELECT gm.contact_id FROM group_members gm JOIN contacts c ON c.user_id = \
             gm.contact_id WHERE gm.group_id = ? AND (gm.member_state IS NULL OR gm.member_state \
             != 'leftGroup') AND c.blocked = 0 AND c.accepted = 1",
        )
        .bind(group_id)
        .fetch_all(&mut *t)
        .await?;

        if recipients.is_empty() {
            return Err(invalid());
        }

        let message_id = uuid::Uuid::new_v4().to_string();

        let location = proto::LiveLocationData {
            session_id: session_id.clone(),
            message_id: message_id.clone(),
            expires_at_ms,
            updated_at_ms: timestamp,
            ..Default::default()
        };

        let bytes = encode(&location);

        sqlx::query(
            "INSERT INTO messages(message_id, group_id, type, content, additional_message_data, \
             created_at) VALUES (?, ?, 'text', ?, ?, ?)",
        )
        .bind(&message_id)
        .bind(group_id)
        .bind(&text)
        .bind(&bytes)
        .bind(timestamp / 1000)
        .execute(&mut *t)
        .await?;

        Group::record_text_or_media(&mut t, group_id, timestamp / 1000).await?;

        sqlx::query(
            "INSERT INTO live_location_targets(session_id, group_id, message_id, recipient_ids) \
             VALUES (?, ?, ?, ?)",
        )
        .bind(&session_id)
        .bind(group_id)
        .bind(&message_id)
        .bind(serde_json::to_string(&recipients)?)
        .execute(&mut *t)
        .await?;

        let content = proto::EncryptedContent {
            group_id: Some(group_id.clone()),
            text_message: Some(encrypted_content::TextMessage {
                sender_message_id: message_id.clone(),
                text: text.clone(),
                timestamp,
                quote_message_id: None,
                additional_message_data: Some(bytes),
            }),
            ..Default::default()
        };

        queued.extend(queue(ctx, &mut t, &recipients, &message_id, content, false, false).await?);
    }

    t.commit().await?;

    dispatch(ctx, queued);

    if let Some(previous) = previous {
        group_ids.extend(previous.group_ids);

        group_ids.sort();
    }

    Ok(LiveLocationSession {
        session_id,
        expires_at_ms: worker_deadline,
        group_ids,
    })
}

async fn queue(
    ctx: &Arc<Context>, t: &mut Transaction<'_, Sqlite>, recipients: &[i64], message_id: &str,
    content: proto::EncryptedContent, update: bool, terminal: bool,
) -> Result<Vec<String>> {
    if update {
        sqlx::query(
            "DELETE FROM receipts WHERE receipt_id IN (SELECT receipt_id FROM \
             live_location_outbox WHERE message_id = ?)",
        )
        .bind(message_id)
        .execute(&mut **t)
        .await?;
    }

    let mut queued = Vec::new();

    for &recipient in recipients {
        let eligible: bool = sqlx::query_scalar(
            "SELECT EXISTS(SELECT 1 FROM contacts c JOIN group_members gm ON gm.contact_id = \
             c.user_id JOIN groups g ON g.group_id = gm.group_id WHERE c.user_id = ? AND \
             c.blocked = 0 AND gm.group_id = ? AND g.left_group = 0 AND (gm.member_state IS NULL \
             OR gm.member_state != 'leftGroup'))",
        )
        .bind(recipient)
        .bind(content.group_id.as_deref())
        .fetch_one(&mut **t)
        .await?;

        if !eligible {
            continue;
        }

        let mut envelope = content.clone();

        decorate_content(ctx, t, recipient, &mut envelope, false).await?;

        let receipt = queue_encrypted_content(t, recipient, envelope, !update).await?;

        if update && !terminal {
            sqlx::query("INSERT INTO live_location_outbox(receipt_id, message_id) VALUES (?, ?)")
                .bind(&receipt)
                .bind(message_id)
                .execute(&mut **t)
                .await?;
        } else if !update {
            sqlx::query("UPDATE receipts SET message_id = ? WHERE receipt_id = ?")
                .bind(message_id)
                .bind(&receipt)
                .execute(&mut **t)
                .await?;
        }

        queued.push(receipt);
    }

    Ok(queued)
}

fn dispatch(ctx: &Arc<Context>, receipts: Vec<String>) {
    let ctx = ctx.clone();

    crate::database::lifecycle::spawn(async move {
        // Network connection must not block persisting a fix or stopping the
        // native worker when the device is offline.
        if let Err(error) = crate::api::runtime::ApiRuntime::connect_for_live_location(&ctx).await {
            tracing::warn!(%error, "could not connect live location socket");
        } else {
            for receipt in receipts {
                if let Err(error) = send_queued_receipt(&ctx, &receipt).await {
                    tracing::warn!(%error, "could not send live location; latest update remains queued");
                }
            }
        }

        if let Err(error) = crate::api::runtime::ApiRuntime::restore_background_policy(&ctx).await {
            tracing::warn!(%error, "could not restore transport background policy");
        }
    });
}

pub(crate) async fn update(
    ctx: &Arc<Context>, session_id: &str, fix: Option<(f64, f64, f64, i64)>, stopped: bool,
) -> Result<bool> {
    update_targets(ctx, session_id, fix, stopped, None).await
}

async fn update_targets(
    ctx: &Arc<Context>, session_id: &str, fix: Option<(f64, f64, f64, i64)>, stopped: bool,
    stop_group: Option<&str>,
) -> Result<bool> {
    let _sharing = SHARING.lock().await;

    let Some(session) = active(ctx).await? else {
        return Ok(false);
    };

    if session.session_id != session_id {
        return Ok(false);
    }

    let stopped = stopped || now() >= session.expires_at_ms;

    let db = ctx.app_db.read().await.clone();

    let mut t = db.pool.begin().await?;

    sqlx::query(
        "DELETE FROM live_location_targets WHERE session_id = ? AND message_id IN (SELECT \
         message_id FROM messages WHERE is_deleted_from_sender = 1)",
    )
    .bind(session_id)
    .execute(&mut *t)
    .await?;

    let rows: Vec<(String, String, String, Vec<u8>)> = sqlx::query_as(
        "SELECT lt.group_id, lt.message_id, lt.recipient_ids, m.additional_message_data FROM \
         live_location_targets lt JOIN messages m ON m.message_id = lt.message_id WHERE \
         lt.session_id = ? AND m.is_deleted_from_sender = 0",
    )
    .bind(session_id)
    .fetch_all(&mut *t)
    .await?;

    let stopped = stopped || rows.is_empty();

    let mut queued = Vec::new();

    let mut remaining_deadline = 0;

    let mut sent_stop = false;

    for (group_id, message_id, recipients, bytes) in rows {
        let Some(mut location) = decode(&bytes) else {
            sqlx::query("DELETE FROM live_location_targets WHERE session_id = ? AND group_id = ?")
                .bind(session_id)
                .bind(&group_id)
                .execute(&mut *t)
                .await?;

            continue;
        };

        location.updated_at_ms = now().max(location.updated_at_ms + 1);

        let target_stopped = stopped
            || location.stopped
            || location.updated_at_ms >= location.expires_at_ms
            || stop_group == Some(group_id.as_str());

        location.stopped = target_stopped;

        if target_stopped {
            sent_stop = true;

            sqlx::query("DELETE FROM live_location_targets WHERE session_id = ? AND group_id = ?")
                .bind(session_id)
                .bind(&group_id)
                .execute(&mut *t)
                .await?;
        } else {
            remaining_deadline = remaining_deadline.max(location.expires_at_ms);
        }

        if !target_stopped {
            if let Some((lat, lon, accuracy, timestamp)) = fix {
                if now().saturating_sub(timestamp) <= 120_000 && timestamp <= now() + 5000 {
                    location.latitude = Some(lat);

                    location.longitude = Some(lon);

                    location.accuracy = Some(accuracy);

                    location.fix_timestamp_ms = Some(timestamp);
                }
            }
        }

        validate(&location)?;

        let bytes = encode(&location);

        sqlx::query("UPDATE messages SET additional_message_data = ? WHERE message_id = ?")
            .bind(&bytes)
            .bind(&message_id)
            .execute(&mut *t)
            .await?;

        let content = proto::EncryptedContent {
            group_id: Some(group_id),
            additional_data_message: Some(encrypted_content::AdditionalDataMessage {
                sender_message_id: uuid::Uuid::new_v4().to_string(),
                timestamp: location.updated_at_ms,
                additional_message_data: Some(bytes),
                r#type: "liveLocation".into(),
                hidden: true,
            }),
            ..Default::default()
        };

        let recipients: Vec<i64> = serde_json::from_str(&recipients)?;

        queued.extend(
            queue(
                ctx,
                &mut t,
                &recipients,
                &message_id,
                content,
                true,
                target_stopped,
            )
            .await?,
        );
    }

    let finished = remaining_deadline == 0;

    if finished {
        sqlx::query("DELETE FROM live_location_sessions WHERE session_id = ?")
            .bind(session_id)
            .execute(&mut *t)
            .await?;
    } else {
        sqlx::query("UPDATE live_location_sessions SET expires_at_ms = ? WHERE session_id = ?")
            .bind(remaining_deadline)
            .bind(session_id)
            .execute(&mut *t)
            .await?;
    }

    t.commit().await?;

    dispatch(ctx, queued);

    if sent_stop {
        // A stop sent offline still deserves the usual OS outbox handover.
        // Running-point updates are excluded because they become obsolete.
        let ctx = ctx.clone();

        crate::database::lifecycle::spawn(async move {
            if let Err(error) = crate::services::outbox_dispatch::OutboxDispatchService::new(&ctx)
                .hand_pending_to_os()
                .await
            {
                tracing::warn!(%error, "could not hand location stop to OS outbox");
            }
        });
    }

    Ok(!finished)
}

pub(crate) async fn stop_chat(ctx: &Arc<Context>, session_id: &str, group_id: &str) -> Result<()> {
    update_targets(ctx, session_id, None, false, Some(group_id)).await?;

    Ok(())
}

pub(crate) async fn stop(ctx: &Arc<Context>, session_id: &str) -> Result<()> {
    update(ctx, session_id, None, true).await?;

    Ok(())
}

/// Authenticated sender, chat, session and deadline must all match the card.
/// Out-of-order updates cannot revive a stopped share or rewind its point.
pub(crate) async fn incoming(
    t: &mut Transaction<'_, Sqlite>, group_id: &str, sender_id: i64,
    location: &proto::LiveLocationData,
) -> Result<()> {
    if validate(location).is_err() {
        return Ok(());
    }

    #[allow(clippy::type_complexity)]
    let row: Option<(String, Option<i64>, Option<Vec<u8>>, bool)> = sqlx::query_as(
        "SELECT group_id, sender_id, additional_message_data, is_deleted_from_sender FROM \
         messages WHERE message_id = ?",
    )
    .bind(&location.message_id)
    .fetch_optional(&mut **t)
    .await?;

    if let Some((group, sender, bytes, deleted)) = row {
        if group != group_id || sender != Some(sender_id) || deleted {
            return Ok(());
        }

        let Some(previous) = bytes.as_deref().and_then(decode) else {
            return Ok(());
        };

        if previous.session_id != location.session_id
            || previous.expires_at_ms != location.expires_at_ms
            || previous.stopped
            || previous.updated_at_ms >= location.updated_at_ms
        {
            return Ok(());
        }

        sqlx::query("UPDATE messages SET additional_message_data = ? WHERE message_id = ?")
            .bind(encode(location))
            .bind(&location.message_id)
            .execute(&mut **t)
            .await?;
    } else {
        // Only the newest pending payload is retained, with a bounded lifetime.
        sqlx::query("DELETE FROM live_location_pending WHERE expires_at_ms < ?")
            .bind(now() - 86_400_000)
            .execute(&mut **t)
            .await?;

        let pending: Option<Vec<u8>> =
            sqlx::query_scalar("SELECT data FROM live_location_pending WHERE message_id = ?")
                .bind(&location.message_id)
                .fetch_optional(&mut **t)
                .await?;

        if let Some(previous) = pending.as_deref().and_then(decode) {
            if previous.stopped
                || previous.session_id != location.session_id
                || previous.expires_at_ms != location.expires_at_ms
            {
                return Ok(());
            }
        }

        sqlx::query(
            "INSERT INTO live_location_pending(message_id, group_id, sender_id, updated_at_ms, \
             expires_at_ms, data) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT(message_id) DO UPDATE SET \
             updated_at_ms = excluded.updated_at_ms, data = excluded.data WHERE \
             live_location_pending.sender_id = excluded.sender_id AND \
             live_location_pending.group_id = excluded.group_id AND \
             live_location_pending.updated_at_ms < excluded.updated_at_ms",
        )
        .bind(&location.message_id)
        .bind(group_id)
        .bind(sender_id)
        .bind(location.updated_at_ms)
        .bind(location.expires_at_ms)
        .bind(encode(location))
        .execute(&mut **t)
        .await?;
    }

    Ok(())
}

pub(crate) async fn apply_pending(
    t: &mut Transaction<'_, Sqlite>, group_id: &str, sender_id: i64, message_id: &str,
) -> Result<()> {
    let bytes: Option<Vec<u8>> = sqlx::query_scalar(
        "SELECT data FROM live_location_pending WHERE message_id = ? AND group_id = ? AND \
         sender_id = ?",
    )
    .bind(message_id)
    .bind(group_id)
    .bind(sender_id)
    .fetch_optional(&mut **t)
    .await?;

    if let Some(location) = bytes.as_deref().and_then(decode) {
        incoming(t, group_id, sender_id, &location).await?;
    }

    sqlx::query("DELETE FROM live_location_pending WHERE message_id = ?")
        .bind(message_id)
        .execute(&mut **t)
        .await?;

    Ok(())
}

#[cfg(test)]
mod tests {

    use super::*;

    async fn close_fixture(ctx: &Arc<Context>) -> anyhow::Result<()> {
        crate::api::runtime::ApiRuntime::close(ctx).await?;

        let app = ctx.app_db.read().await.pool.clone();

        let signal = ctx.rust_db.read().await.pool.clone();

        tokio::join!(app.close(), signal.close());

        Ok(())
    }

    async fn fixture() -> anyhow::Result<(tempfile::TempDir, Arc<Context>)> {
        let temp = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(temp.path().join("database"), temp.path().join("data"))
            .await?;

        crate::user_config::UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"me","displayName":"Me"}"#,
        )?;

        let db = ctx.app_db.read().await.clone();

        sqlx::query("INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'friend', 1)")
            .execute(&db.pool)
            .await?;

        for group in ["chat-a", "chat-b"] {
            sqlx::query("INSERT INTO groups(group_id, group_name) VALUES (?, ?)")
                .bind(group)
                .bind(group)
                .execute(&db.pool)
                .await?;

            sqlx::query("INSERT INTO group_members(group_id, contact_id) VALUES (?, 7)")
                .bind(group)
                .execute(&db.pool)
                .await?;
        }

        Ok((temp, ctx))
    }

    async fn cards(ctx: &Arc<Context>) -> anyhow::Result<Vec<proto::LiveLocationData>> {
        let db = ctx.app_db.read().await.clone();

        let bytes: Vec<Vec<u8>> =
            sqlx::query_scalar("SELECT additional_message_data FROM messages ORDER BY group_id")
                .fetch_all(&db.pool)
                .await?;

        Ok(bytes.iter().map(|bytes| decode(bytes).unwrap()).collect())
    }

    #[tokio::test]

    async fn multiple_chats_replace_points_and_bound_the_offline_queue() -> anyhow::Result<()> {
        let (_temp, ctx) = fixture().await?;

        let session = start(
            &ctx,
            vec!["chat-b".into(), "chat-a".into(), "chat-a".into()],
            600,
            "Live location".into(),
        )
        .await?;

        assert_eq!(session.group_ids, ["chat-a", "chat-b"]);

        assert_eq!(cards(&ctx).await?.len(), 2);

        let db = ctx.app_db.read().await.clone();

        let wakes: i64 =
            sqlx::query_scalar("SELECT COUNT(*) FROM receipts WHERE wake_receiver = 1")
                .fetch_one(&db.pool)
                .await?;

        assert_eq!(wakes, 2, "each initial share requests a receiver push");

        assert!(
            start(&ctx, vec!["chat-a".into()], 600, "Live location".into())
                .await
                .is_err()
        );

        for latitude in [52.5, 52.6, 52.7] {
            assert!(
                update(
                    &ctx,
                    &session.session_id,
                    Some((latitude, 13.4, 8.0, now())),
                    false
                )
                .await?
            );
        }

        for card in cards(&ctx).await? {
            assert_eq!(card.latitude, Some(52.7));

            assert_eq!(card.session_id, session.session_id);
        }

        let db = ctx.app_db.read().await.clone();

        let updates: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM live_location_outbox")
            .fetch_one(&db.pool)
            .await?;

        assert_eq!(updates, 2);

        let update_wakes: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM receipts r JOIN live_location_outbox l ON l.receipt_id = \
             r.receipt_id WHERE r.wake_receiver = 1",
        )
        .fetch_one(&db.pool)
        .await?;

        assert_eq!(
            update_wakes, 0,
            "periodic points must not trigger more pushes"
        );

        let messages: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM messages")
            .fetch_one(&db.pool)
            .await?;

        assert_eq!(messages, 2);

        stop(&ctx, &session.session_id).await?;

        assert!(active(&ctx).await?.is_none());

        assert!(
            !update(
                &ctx,
                &session.session_id,
                Some((53.0, 13.4, 8.0, now())),
                false
            )
            .await?
        );

        for card in cards(&ctx).await? {
            assert!(card.stopped);

            assert_eq!(card.latitude, Some(52.7));
        }

        let updates: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM live_location_outbox")
            .fetch_one(&db.pool)
            .await?;

        assert_eq!(updates, 0);

        close_fixture(&ctx).await?;

        Ok(())
    }

    #[tokio::test]

    async fn invalid_selection_rolls_back_and_removed_members_receive_no_fixes(
    ) -> anyhow::Result<()> {
        let (_temp, ctx) = fixture().await?;

        assert!(start(&ctx, vec!["chat-a".into()], 601, "Location".into())
            .await
            .is_err());

        assert!(start(
            &ctx,
            vec!["chat-a".into(), "missing".into()],
            600,
            "Location".into()
        )
        .await
        .is_err());

        assert!(active(&ctx).await?.is_none());

        assert!(cards(&ctx).await?.is_empty());

        let session = start(&ctx, vec!["chat-a".into()], 600, "Location".into()).await?;

        let db = ctx.app_db.read().await.clone();

        sqlx::query("UPDATE group_members SET member_state = 'leftGroup'")
            .execute(&db.pool)
            .await?;

        update(
            &ctx,
            &session.session_id,
            Some((52.5, 13.4, 8.0, now())),
            false,
        )
        .await?;

        let updates: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM live_location_outbox")
            .fetch_one(&db.pool)
            .await?;

        assert_eq!(updates, 0);

        close_fixture(&ctx).await?;

        Ok(())
    }

    #[tokio::test]

    async fn chats_started_separately_share_one_worker_with_independent_durations(
    ) -> anyhow::Result<()> {
        let (_temp, ctx) = fixture().await?;

        let first = start(&ctx, vec!["chat-a".into()], 600, "Location".into()).await?;

        let second = start(&ctx, vec!["chat-b".into()], 7200, "Location".into()).await?;

        assert_eq!(first.session_id, second.session_id);

        assert_eq!(second.group_ids, ["chat-a", "chat-b"]);

        let stored = cards(&ctx).await?;

        assert_eq!(stored[0].expires_at_ms, first.expires_at_ms);

        assert_eq!(stored[1].expires_at_ms, second.expires_at_ms);

        assert!(stored[1].expires_at_ms - stored[0].expires_at_ms >= 6_600_000);

        stop_chat(&ctx, &first.session_id, "chat-a").await?;

        assert_eq!(active(&ctx).await?.unwrap().group_ids, ["chat-b"]);

        update(
            &ctx,
            &second.session_id,
            Some((52.5, 13.4, 8.0, now())),
            false,
        )
        .await?;

        let latest = cards(&ctx).await?;

        assert!(latest[0].stopped);

        assert_eq!(latest[0].latitude, None);

        assert!(!latest[1].stopped);

        assert_eq!(latest[1].latitude, Some(52.5));

        stop_chat(&ctx, &second.session_id, "chat-b").await?;

        assert!(active(&ctx).await?.is_none());

        close_fixture(&ctx).await?;

        Ok(())
    }

    #[tokio::test]

    async fn expiry_in_one_chat_does_not_end_another_chat() -> anyhow::Result<()> {
        let (_temp, ctx) = fixture().await?;

        let session = start(&ctx, vec!["chat-a".into()], 600, "Location".into()).await?;

        start(&ctx, vec!["chat-b".into()], 7200, "Location".into()).await?;

        let db = ctx.app_db.read().await.clone();

        let mut ended = cards(&ctx).await?[0].clone();

        ended.expires_at_ms = now() - 1;

        sqlx::query("UPDATE messages SET additional_message_data = ? WHERE message_id = ?")
            .bind(encode(&ended))
            .bind(&ended.message_id)
            .execute(&db.pool)
            .await?;

        assert_eq!(state(&ctx).await?.unwrap().group_ids, ["chat-b"]);

        assert!(cards(&ctx).await?[0].stopped);

        assert!(
            update(
                &ctx,
                &session.session_id,
                Some((52.5, 13.4, 8.0, now())),
                false
            )
            .await?
        );

        assert!(!cards(&ctx).await?[1].stopped);

        close_fixture(&ctx).await?;

        Ok(())
    }

    #[tokio::test]

    async fn expiry_and_stale_native_callbacks_cannot_restart_a_session() -> anyhow::Result<()> {
        let (_temp, ctx) = fixture().await?;

        let old = start(&ctx, vec!["chat-a".into()], 600, "Location".into()).await?;

        let db = ctx.app_db.read().await.clone();

        sqlx::query("UPDATE live_location_sessions SET expires_at_ms = ?")
            .bind(now() - 1)
            .execute(&db.pool)
            .await?;

        assert!(state(&ctx).await?.is_none());

        assert!(cards(&ctx).await?[0].stopped);

        let new = start(&ctx, vec!["chat-a".into()], 600, "Location".into()).await?;

        stop(&ctx, &old.session_id).await?;

        assert_eq!(active(&ctx).await?.unwrap().session_id, new.session_id);

        close_fixture(&ctx).await?;

        Ok(())
    }

    #[tokio::test]

    async fn backup_discards_live_workers_and_queued_points_but_preserves_chat_cards(
    ) -> anyhow::Result<()> {
        let (temp, ctx) = fixture().await?;

        let session = start(&ctx, vec!["chat-a".into()], 600, "Location".into()).await?;

        update(
            &ctx,
            &session.session_id,
            Some((52.5, 13.4, 8.0, now())),
            false,
        )
        .await?;

        let archive = crate::backup::backup_archive::BackupArchive::create_backup(&ctx).await?;

        let output = temp.path().join("export.sqlite");

        let keys = ctx.key_manager.lock().await;

        let archive_bytes = keys.main_key.decrypt_backup(&std::fs::read(archive)?)?;

        let key = keys
            .main_key
            .get_database_key(crate::keys::DatabaseKey::AppDb);

        drop(keys);

        let mut zip = zip::ZipArchive::new(std::io::Cursor::new(archive_bytes))?;

        std::io::copy(
            &mut zip.by_name(crate::database::app::APP_DATABASE_FILE)?,
            &mut std::fs::File::create(&output)?,
        )?;

        let backup =
            crate::database::app::AppDatabase::new(&output.to_string_lossy(), Some(&key), true)
                .await?;

        for table in [
            "live_location_sessions",
            "live_location_targets",
            "live_location_outbox",
            "live_location_pending",
        ] {
            let query = format!("SELECT COUNT(*) FROM {table}");

            let count: i64 = sqlx::query_scalar(sqlx::AssertSqlSafe(query.as_str()))
                .fetch_one(&backup.pool)
                .await?;

            assert_eq!(count, 0, "{table} must not be restored");
        }

        let bytes: Vec<u8> =
            sqlx::query_scalar("SELECT additional_message_data FROM messages LIMIT 1")
                .fetch_one(&backup.pool)
                .await?;

        assert_eq!(decode(&bytes).unwrap().latitude, Some(52.5));

        assert!(
            active(&ctx).await?.is_some(),
            "making a backup must not stop the live device"
        );

        backup.pool.close().await;

        close_fixture(&ctx).await?;

        Ok(())
    }

    #[tokio::test]

    async fn stale_fixes_and_invalid_new_points_do_not_replace_the_current_point(
    ) -> anyhow::Result<()> {
        let (_temp, ctx) = fixture().await?;

        let session = start(&ctx, vec!["chat-a".into()], 600, "Location".into()).await?;

        update(
            &ctx,
            &session.session_id,
            Some((52.5, 13.4, 8.0, now())),
            false,
        )
        .await?;

        update(
            &ctx,
            &session.session_id,
            Some((53.0, 13.4, 8.0, now() - 121_000)),
            false,
        )
        .await?;

        assert_eq!(cards(&ctx).await?[0].latitude, Some(52.5));

        assert!(update(
            &ctx,
            &session.session_id,
            Some((91.0, 13.4, 8.0, now())),
            false
        )
        .await
        .is_err());

        assert_eq!(cards(&ctx).await?[0].latitude, Some(52.5));

        close_fixture(&ctx).await?;

        Ok(())
    }

    fn payload() -> proto::LiveLocationData {
        proto::LiveLocationData {
            session_id: uuid::Uuid::new_v4().to_string(),
            message_id: uuid::Uuid::new_v4().to_string(),
            expires_at_ms: now() + 600_000,
            updated_at_ms: now(),
            ..Default::default()
        }
    }

    #[test]

    fn rejects_partial_nonfinite_and_out_of_range_coordinates() {
        let mut data = payload();

        assert!(validate(&data).is_ok());

        data.latitude = Some(52.5);

        assert!(validate(&data).is_err());

        data.longitude = Some(13.4);

        data.accuracy = Some(8.0);

        data.fix_timestamp_ms = Some(now());

        assert!(validate(&data).is_ok());

        for latitude in [f64::NAN, f64::INFINITY, 90.01, -90.01] {
            data.latitude = Some(latitude);

            assert!(validate(&data).is_err());
        }

        data.latitude = Some(52.5);

        data.accuracy = Some(-1.0);

        assert!(validate(&data).is_err());
    }

    #[tokio::test]

    async fn incoming_checks_ownership_order_and_the_stopped_latch() -> anyhow::Result<()> {
        let (_temp, ctx) = fixture().await?;

        let db = ctx.app_db.read().await.clone();

        let initial = payload();

        sqlx::query(
            "INSERT INTO messages(message_id, group_id, sender_id, type, content, \
             additional_message_data) VALUES (?, 'chat-a', 7, 'text', 'Location', ?)",
        )
        .bind(&initial.message_id)
        .bind(encode(&initial))
        .execute(&db.pool)
        .await?;

        let mut newer = initial.clone();

        newer.updated_at_ms += 1;

        newer.latitude = Some(52.5);

        newer.longitude = Some(13.4);

        newer.accuracy = Some(8.0);

        newer.fix_timestamp_ms = Some(now());

        let mut t = db.pool.begin().await?;

        incoming(&mut t, "chat-b", 7, &newer).await?;

        incoming(&mut t, "chat-a", 8, &newer).await?;

        t.commit().await?;

        assert_eq!(cards(&ctx).await?[0].latitude, None);

        let mut t = db.pool.begin().await?;

        incoming(&mut t, "chat-a", 7, &newer).await?;

        incoming(&mut t, "chat-a", 7, &initial).await?;

        newer.stopped = true;

        newer.updated_at_ms += 1;

        incoming(&mut t, "chat-a", 7, &newer).await?;

        newer.stopped = false;

        newer.updated_at_ms += 1;

        newer.latitude = Some(53.0);

        incoming(&mut t, "chat-a", 7, &newer).await?;

        t.commit().await?;

        let card = &cards(&ctx).await?[0];

        assert!(card.stopped);

        assert_eq!(card.latitude, Some(52.5));

        close_fixture(&ctx).await?;

        Ok(())
    }

    #[tokio::test]

    async fn stop_arriving_before_the_card_is_applied_without_resurrection() -> anyhow::Result<()> {
        let (_temp, ctx) = fixture().await?;

        let db = ctx.app_db.read().await.clone();

        let initial = payload();

        let mut stopped = initial.clone();

        stopped.updated_at_ms += 1;

        stopped.stopped = true;

        let mut t = db.pool.begin().await?;

        incoming(&mut t, "chat-a", 7, &stopped).await?;

        let mut stale = stopped.clone();

        stale.stopped = false;

        stale.updated_at_ms += 1;

        incoming(&mut t, "chat-a", 7, &stale).await?;

        sqlx::query(
            "INSERT INTO messages(message_id, group_id, sender_id, type, content, \
             additional_message_data) VALUES (?, 'chat-a', 7, 'text', 'Location', ?)",
        )
        .bind(&initial.message_id)
        .bind(encode(&initial))
        .execute(&mut *t)
        .await?;

        apply_pending(&mut t, "chat-a", 7, &initial.message_id).await?;

        t.commit().await?;

        assert!(cards(&ctx).await?[0].stopped);

        let pending: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM live_location_pending")
            .fetch_one(&db.pool)
            .await?;

        assert_eq!(pending, 0);

        close_fixture(&ctx).await?;

        Ok(())
    }
}
