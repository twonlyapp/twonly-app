/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::{self as proto, encrypted_content};
use crate::api::runtime::ApiRuntime;
use crate::bridge::InitConfig;
use crate::context::Context;
use crate::database::app::AppDatabase;
use crate::error::Result;
use crate::user_config::UserConfig;
use crate::utils::{current_time, milliseconds_to_seconds};
use serde::{Deserialize, Serialize};
use sqlx::{Sqlite, Transaction};
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::{Arc, LazyLock};

const MAX_BATCH_SIZE: i64 = 100;
const EN_ARB: &str = include_str!("../../../lib/src/localization/translations/en.arb");
const DE_ARB: &str = include_str!("../../../lib/src/localization/translations/de.arb");

static EN_TRANSLATIONS: LazyLock<HashMap<String, String>> =
    LazyLock::new(|| parse_arb(EN_ARB, "en"));
static DE_TRANSLATIONS: LazyLock<HashMap<String, String>> =
    LazyLock::new(|| parse_arb(DE_ARB, "de"));

/// The announcement a webxdc update carries, if it has one.
///
/// The update itself is hidden -- app state rather than something a person
/// sent -- but an `info` is written to be read, and becomes a chat row of its
/// own on arrival. That row is what the receiver is woken and notified for.
fn webxdc_announcement(
    message: &encrypted_content::AdditionalDataMessage,
    user_id: i64,
) -> Option<String> {
    let data = <proto::AdditionalMessageData as prost::Message>::decode(
        message.additional_message_data.as_deref()?,
    )
    .ok()?;
    let update = data.webxdc_update?;
    // Keep chat announcements shared, but only wake recipients selected by the app.
    let announcement = crate::services::webxdc::announcement(&update)?;
    match update.notify.as_deref() {
        None => Some(announcement),
        Some(raw) => {
            let recipients: std::collections::BTreeMap<String, String> =
                serde_json::from_str(raw).ok()?;
            let address =
                crate::services::webxdc::WebxdcService::address_for(&update.instance_id, user_id);
            let text = recipients.get(&address)?;
            let mut notification = update;
            notification.info = Some(text.clone());
            crate::services::webxdc::announcement(&notification)
        }
    }
}

/// Who wrote the message with this id, as this device has it.
///
/// The two layers say different things and both matter here: the outer `None`
/// means this device has no such message, while an inner `None` means this
/// device wrote it, which is how an own message is stored.
async fn message_sender(
    transaction: &mut Transaction<'_, Sqlite>,
    message_id: &str,
) -> Result<Option<Option<i64>>> {
    Ok(sqlx::query_scalar!(
        "SELECT sender_id FROM messages WHERE message_id = ?",
        message_id
    )
    .fetch_optional(&mut **transaction)
    .await?)
}

/// Whether this envelope is worth spending the recipient's push budget on.
///
/// A wake-up is not free to get wrong. iOS renders the alert the push carried
/// no matter what the extension finds behind it, so an envelope that wakes a
/// device without leaving it anything to show reaches the user as a bare "You
/// got a new message" -- which is why every arm here has to match something
/// [`record_incoming_event`] will actually record.
pub(crate) async fn should_wake_receiver(
    transaction: &mut Transaction<'_, Sqlite>,
    target_user_id: i64,
    content: &proto::EncryptedContent,
) -> Result<bool> {
    // A reaction concerns the person who wrote the message it lands on and
    // nobody else: in a group it wakes that one member rather than all of
    // them, and a reaction to one's own message wakes nobody at all.
    let reaction_reaches_author = match content.reaction.as_ref().filter(|value| !value.remove) {
        Some(reaction) => {
            message_sender(transaction, &reaction.target_message_id)
                .await?
                .flatten()
                == Some(target_user_id)
        }
        None => false,
    };

    Ok(content.text_message.is_some()
        || content
            .additional_data_message
            .as_ref()
            .is_some_and(|message| {
                !message.hidden || webxdc_announcement(message, target_user_id).is_some()
            })
        || content.group_create.is_some()
        || content.media.as_ref().is_some_and(|value| {
            // Widget media lands already opened and is deliberately recorded
            // without a notification, so waking for it buys the recipient an
            // alert with nothing behind it.
            value.widget_only != Some(true)
                && encrypted_content::media::Type::try_from(value.r#type)
                    .is_ok_and(|kind| kind != encrypted_content::media::Type::Reupload)
        })
        || reaction_reaches_author
        || content
            .media_update
            .as_ref()
            .and_then(|value| encrypted_content::media_update::Type::try_from(value.r#type).ok())
            .is_some_and(|kind| {
                matches!(
                    kind,
                    encrypted_content::media_update::Type::Stored
                        | encrypted_content::media_update::Type::Reopened
                )
            })
        || content
            .contact_request
            .as_ref()
            .and_then(|value| encrypted_content::contact_request::Type::try_from(value.r#type).ok())
            .is_some_and(|kind| {
                matches!(
                    kind,
                    encrypted_content::contact_request::Type::Request
                        | encrypted_content::contact_request::Type::Accept
                )
            }))
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
pub struct NotificationAddition {
    pub event_id: String,
    pub notification_id: String,
    pub conversation_id: Option<String>,
    pub sender_id: i64,
    pub sender_name: String,
    pub title: String,
    pub body: String,
    pub conversation_name: Option<String>,
    pub is_group: bool,
    pub message_id: Option<String>,
    pub kind: String,
    pub content: Option<String>,
    pub created_at: i64,
    pub avatar_path: Option<String>,
}

#[derive(Clone, Debug, Default, Deserialize, Eq, PartialEq, Serialize)]
pub struct NotificationBatch {
    pub additions: Vec<NotificationAddition>,
    pub removals: Vec<String>,
    pub badge_count: i64,
    pub completed: bool,
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
pub struct NotificationPresentation {
    pub title: String,
    pub body: String,
}

pub fn fallback_presentation(locale: &str) -> NotificationPresentation {
    NotificationPresentation {
        title: translation(locale, "notificationCategoryMessageTitle").to_owned(),
        body: translation(locale, "notificationConnectionFallback").to_owned(),
    }
}

#[derive(Debug)]
struct NotificationDraft {
    event_id: String,
    notification_id: String,
    conversation_id: Option<String>,
    sender_id: i64,
    message_id: Option<String>,
    kind: &'static str,
    content: Option<String>,
    created_at: i64,
}

impl NotificationDraft {
    async fn insert(self, transaction: &mut Transaction<'_, Sqlite>) -> Result<()> {
        sqlx::query!(
            r#"
            INSERT OR IGNORE INTO notification_outbox(
                event_id, notification_id, conversation_id, sender_id,
                message_id, kind, content, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            "#,
            self.event_id,
            self.notification_id,
            self.conversation_id,
            self.sender_id,
            self.message_id,
            self.kind,
            self.content,
            self.created_at,
        )
        .execute(&mut **transaction)
        .await?;
        Ok(())
    }
}

/// Records the user-visible consequence of an encrypted message in the same
/// transaction that commits that message. Transport retries are deduplicated
/// by the receipt-derived event ID.
pub(crate) async fn record_incoming_event(
    ctx: &Context,
    transaction: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    receipt_id: &str,
    content: &proto::EncryptedContent,
) -> Result<()> {
    if content
        .media
        .as_ref()
        .is_some_and(|media| media.widget_only == Some(true))
    {
        return Ok(());
    }
    let blocked = sqlx::query_scalar!(
        "SELECT blocked FROM contacts WHERE user_id = ?",
        from_user_id
    )
    .fetch_optional(&mut **transaction)
    .await?
    .unwrap_or(0)
        != 0;
    if blocked {
        return Ok(());
    }

    let conversation_id = content.group_id.clone();
    let now = current_time().timestamp();
    let draft = if let Some(message) = content.text_message.as_ref() {
        Some(NotificationDraft {
            event_id: receipt_id.to_owned(),
            notification_id: message.sender_message_id.clone(),
            conversation_id,
            sender_id: from_user_id,
            message_id: Some(message.sender_message_id.clone()),
            kind: if message.quote_message_id.is_some() {
                "response"
            } else {
                "text"
            },
            content: None,
            created_at: milliseconds_to_seconds(message.timestamp),
        })
    } else if let Some(media) = content.media.as_ref() {
        let media_type = encrypted_content::media::Type::try_from(media.r#type)?;
        if media_type == encrypted_content::media::Type::Reupload {
            None
        } else {
            let kind = match media_type {
                _ if media.requires_authentication => "twonly",
                encrypted_content::media::Type::Image => "image",
                encrypted_content::media::Type::Video => "video",
                encrypted_content::media::Type::Gif => "image",
                encrypted_content::media::Type::Audio => "audio",
                encrypted_content::media::Type::Reupload => unreachable!(),
            };
            Some(NotificationDraft {
                event_id: receipt_id.to_owned(),
                notification_id: media.sender_message_id.clone(),
                conversation_id,
                sender_id: from_user_id,
                message_id: Some(media.sender_message_id.clone()),
                kind,
                content: None,
                created_at: milliseconds_to_seconds(media.timestamp),
            })
        }
    } else if let Some(message) = content.additional_data_message.as_ref() {
        // A hidden message is state a feature exchanges and leaves no row of
        // its own, so the only thing in one worth an alert is an app's
        // announcement -- and only once the row it materialised into exists,
        // which it does not when the update was dropped for an unknown
        // instance, a mismatched chat, or an app that is over budget.
        let self_id = UserConfig::load_required_from(ctx)?.user_id;
        let announcement = message
            .hidden
            .then(|| webxdc_announcement(message, self_id))
            .flatten();
        let message_id = if message.hidden {
            crate::services::webxdc::WebxdcService::info_message_id(&message.sender_message_id)
        } else {
            message.sender_message_id.clone()
        };
        let worth_an_alert = if message.hidden {
            announcement.is_some() && message_sender(transaction, &message_id).await?.is_some()
        } else {
            true
        };
        worth_an_alert.then(|| NotificationDraft {
            event_id: receipt_id.to_owned(),
            notification_id: message.sender_message_id.clone(),
            conversation_id,
            sender_id: from_user_id,
            message_id: Some(message_id),
            // An app speaks for itself: the alert reads "Alice is on turn"
            // rather than "sent a message", so a game's traffic stays
            // distinguishable from the people in the chat talking.
            kind: if announcement.is_some() {
                "webxdc"
            } else {
                "text"
            },
            content: announcement,
            created_at: milliseconds_to_seconds(message.timestamp),
        })
    } else if let Some(reaction) = content.reaction.as_ref().filter(|value| !value.remove) {
        // Only the author of a message hears about a reaction to it. Everybody
        // else in the group watched it land on somebody else's message and has
        // nothing to be told, and a reaction the sender put on their own
        // message concerns nobody here at all.
        matches!(
            message_sender(transaction, &reaction.target_message_id).await?,
            Some(None)
        )
        .then(|| NotificationDraft {
            event_id: receipt_id.to_owned(),
            notification_id: receipt_id.to_owned(),
            conversation_id,
            sender_id: from_user_id,
            message_id: Some(reaction.target_message_id.clone()),
            kind: "reaction",
            content: Some(reaction.emoji.clone()),
            created_at: now,
        })
    } else if let Some(update) = content.media_update.as_ref() {
        let update_type = encrypted_content::media_update::Type::try_from(update.r#type)?;
        let kind = match update_type {
            encrypted_content::media_update::Type::Stored => Some("stored_media"),
            encrypted_content::media_update::Type::Reopened => Some("reopened_media"),
            encrypted_content::media_update::Type::DecryptionError => None,
        };
        kind.map(|kind| NotificationDraft {
            event_id: receipt_id.to_owned(),
            notification_id: receipt_id.to_owned(),
            conversation_id,
            sender_id: from_user_id,
            message_id: Some(update.target_message_id.clone()),
            kind,
            content: None,
            created_at: now,
        })
    } else if let Some(request) = content.contact_request.as_ref() {
        let request_type = encrypted_content::contact_request::Type::try_from(request.r#type)?;
        let kind = match request_type {
            encrypted_content::contact_request::Type::Request => Some("contact_request"),
            encrypted_content::contact_request::Type::Accept => Some("accept_request"),
            encrypted_content::contact_request::Type::Reject => None,
        };
        kind.map(|kind| NotificationDraft {
            event_id: receipt_id.to_owned(),
            notification_id: receipt_id.to_owned(),
            conversation_id,
            sender_id: from_user_id,
            message_id: None,
            kind,
            content: None,
            created_at: now,
        })
    } else if let Some(create) = content.group_create.as_ref() {
        Some(NotificationDraft {
            event_id: receipt_id.to_owned(),
            notification_id: receipt_id.to_owned(),
            conversation_id,
            sender_id: from_user_id,
            message_id: None,
            kind: "added_to_group",
            content: create.group_name.clone(),
            created_at: now,
        })
    } else {
        None
    };

    if let Some(draft) = draft {
        draft.insert(transaction).await?;
    }
    Ok(())
}

/// A foreground chat can mark a message as opened before the native push
/// worker gets around to rendering its durable outbox row. Clearing those
/// stale rows keeps them from producing an alert or inflating the badge.
async fn clear_stale_opened(database: &Arc<AppDatabase>) -> Result<()> {
    let cleared_at = current_time().timestamp();
    sqlx::query(
        r#"
        UPDATE notification_outbox
        SET cleared_at = ?
        WHERE cleared_at IS NULL
          AND kind IN ('text', 'response', 'image', 'video', 'audio', 'twonly', 'webxdc')
          AND EXISTS (
              SELECT 1
              FROM messages
              WHERE messages.message_id = notification_outbox.message_id
                AND messages.opened_at IS NOT NULL
          )
        "#,
    )
    .bind(cleared_at)
    .execute(&database.pool)
    .await?;
    Ok(())
}

/// The number of events the user has not dealt with yet. iOS has no way to
/// derive an app icon badge from the delivered alerts, so the running app has
/// to push this value into `UNUserNotificationCenter` itself.
pub async fn badge_count(ctx: &Arc<Context>) -> Result<i64> {
    let database = ctx.app_db.read().await.clone();
    clear_stale_opened(&database).await?;
    let count = sqlx::query_scalar!(
        r#"SELECT COUNT(*) AS "count: i64" FROM notification_outbox WHERE cleared_at IS NULL"#
    )
    .fetch_one(&database.pool)
    .await?;
    Ok(count)
}

pub async fn pending_batch(ctx: &Arc<Context>, locale: &str) -> Result<NotificationBatch> {
    let database = ctx.app_db.read().await.clone();
    clear_stale_opened(&database).await?;
    let rows = sqlx::query_as!(
        PendingRow,
        r#"
        SELECT n.event_id, n.notification_id, n.conversation_id, n.sender_id,
               COALESCE(c.display_name, c.username) AS "sender_name!: String",
               c.avatar_svg_compressed, c.sender_profile_counter,
               g.group_name AS conversation_name,
               COALESCE(g.is_direct_chat, 0) AS "is_direct_chat!: i64",
               n.message_id, n.kind, n.content, n.created_at,
               target_message.type AS target_message_type,
               target_media.type AS target_media_type
        FROM notification_outbox n
        JOIN contacts c ON c.user_id = n.sender_id
        LEFT JOIN groups g ON g.group_id = n.conversation_id
        LEFT JOIN messages target_message ON target_message.message_id = n.message_id
        LEFT JOIN media_files target_media ON target_media.media_id = target_message.media_id
        WHERE n.delivered_at IS NULL AND n.cleared_at IS NULL
        ORDER BY n.created_at, n.event_id
        LIMIT ?
        "#,
        MAX_BATCH_SIZE,
    )
    .fetch_all(&database.pool)
    .await?;

    let badge_count = sqlx::query_scalar!(
        r#"SELECT COUNT(*) AS "count: i64" FROM notification_outbox WHERE cleared_at IS NULL"#
    )
    .fetch_one(&database.pool)
    .await?;

    let mut additions = Vec::with_capacity(rows.len());
    for row in rows {
        let title = row.sender_name.clone();
        let body = localized_body(locale, &row);
        let is_group = row.conversation_id.is_some() && row.is_direct_chat == 0;
        let avatar_path = match notification_avatar_path(
            ctx,
            row.sender_id,
            row.sender_profile_counter,
            row.avatar_svg_compressed.as_deref(),
        ) {
            Ok(path) => path.map(|path| path.display().to_string()),
            Err(error) => {
                tracing::warn!(
                    sender_id = row.sender_id,
                    "failed to prepare notification avatar: {error}"
                );
                None
            }
        };
        additions.push(NotificationAddition {
            event_id: row.event_id,
            notification_id: row.notification_id,
            conversation_id: row.conversation_id,
            sender_id: row.sender_id,
            sender_name: row.sender_name,
            title,
            body,
            conversation_name: row.conversation_name,
            is_group,
            message_id: row.message_id,
            kind: row.kind,
            content: row.content,
            created_at: row.created_at,
            avatar_path,
        });
    }

    Ok(NotificationBatch {
        additions,
        removals: Vec::new(),
        badge_count,
        completed: true,
    })
}

/// Drains the mailbox and returns the alert the native caller should render.
///
/// This deliberately stops at the batch: everything the wake-up still owes the
/// app — media downloads, widget upkeep, closing the socket — is deferred to
/// [`finalize_wakeup`] so that none of it sits between the incoming message and
/// the notification the user is waiting for.
pub async fn process_wakeup(
    config: InitConfig,
    locale: &str,
    deadline_ms: u64,
) -> Result<NotificationBatch> {
    Context::init_notification(config).await?;
    let ctx = Context::get_static()?.clone();

    // The FCM health check used to be fed by the Dart background isolate, which
    // no longer runs. Record the wake-up here so both platforms report it.
    if let Err(error) = UserConfig::update(&ctx, |user| {
        user.last_fcm_wakeup_at = Some(current_time().timestamp());
    }) {
        tracing::warn!("could not record the FCM wake-up timestamp: {error}");
    }

    let deadline = std::time::Duration::from_millis(deadline_ms.clamp(1_000, 28_000));

    let owns_connection = ctx.is_notification_runtime();
    let completed = if owns_connection {
        let generation = ctx.mailbox_generation();
        ApiRuntime::connect(&ctx).await?;
        tokio::time::timeout(deadline, ctx.wait_for_mailbox_after(generation))
            .await
            .is_ok()
    } else {
        // The generation has to be sampled before the snapshot. A commit that
        // lands between the two is invisible to both the snapshot, which ran
        // too early, and the wait, whose baseline already counts it — leaving
        // an alert that is durable on disk stalled for the whole deadline.
        let generation = ctx.incoming_generation();
        let initial = pending_batch(&ctx, locale).await?;
        if !initial.additions.is_empty() {
            return Ok(initial);
        }
        // Flutter already owns the socket. Nudge the server to redeliver in
        // case the push raced a drain that had already finished.
        if let Ok(client) = ApiRuntime::client(&ctx).await {
            client.request_catch_up().await;
        }
        tokio::time::timeout(deadline, ctx.wait_for_incoming_after(generation))
            .await
            .is_ok()
    };

    // Give concurrently acknowledged batches a small window to commit their
    // durable notification rows before the native caller renders the result.
    tokio::time::sleep(std::time::Duration::from_millis(100)).await;
    let mut batch = pending_batch(&ctx, locale).await?;
    batch.completed = completed;
    Ok(batch)
}

/// Settles what the wake-up still owes the app once its notification is on
/// screen. The native caller invokes this after rendering the batch, so every
/// step here is off the alert's critical path and the whole run is bounded by
/// `deadline_ms` — an OS that reclaims the worker mid-way costs nothing that
/// the next wake-up or app launch does not redo.
pub async fn finalize_wakeup(deadline_ms: u64) -> Result<()> {
    let ctx = Context::get_static()?.clone();
    let owns_connection = ctx.is_notification_runtime();
    let deadline = std::time::Duration::from_millis(deadline_ms.min(28_000));
    let started = std::time::Instant::now();
    let remaining = || deadline.saturating_sub(started.elapsed());

    // In a killed-app notification process the spawned receive task only lives
    // as long as the shared notification runtime, so this is the last chance to
    // settle widget downloads before the OS reclaims the worker. They get most
    // of the budget but not all of it: a download nothing publishes to the
    // manifest below was not worth making.
    if owns_connection {
        let media_files = crate::services::mediafiles::MediaFileService::new(&ctx);
        match tokio::time::timeout(deadline.mul_f32(0.75), media_files.download_pending()).await {
            Ok(Err(error)) => tracing::warn!(%error, "background media download failed"),
            Err(error) => tracing::info!(%error, "background media download window elapsed"),
            Ok(Ok(())) => {}
        }
    }

    match tokio::time::timeout(
        remaining(),
        crate::services::home_widget::purge_widget_media(&ctx),
    )
    .await
    {
        Ok(Err(error)) => tracing::warn!(%error, "widget-media maintenance failed during wake-up"),
        Err(error) => tracing::info!(%error, "widget-media maintenance window elapsed"),
        Ok(Ok(())) => {}
    }

    if owns_connection && ctx.is_notification_runtime() {
        // Bounded on its own rather than out of what is left: closing costs a
        // round trip at most, and a server that never answers the handshake
        // must not hold the worker open. The socket dies with the process
        // either way.
        if tokio::time::timeout(std::time::Duration::from_secs(1), ApiRuntime::close(&ctx))
            .await
            .is_err()
        {
            tracing::info!("background socket did not close gracefully in time");
        }
    }
    Ok(())
}

/// Persists a token refresh from the native Android FCM callback. The normal
/// authenticated Rust lifecycle uploads it and clears `update_fcm_token`.
pub async fn store_fcm_token(config: InitConfig, token: String) -> Result<()> {
    Context::init_notification(config).await?;
    let ctx = Context::get_static()?;
    UserConfig::update(ctx, |user| {
        user.fcm_token = Some(token);
        user.update_fcm_token = true;
    })?;
    Ok(())
}

pub async fn acknowledge_batch(ctx: &Arc<Context>, event_ids: &[String]) -> Result<()> {
    if event_ids.is_empty() {
        return Ok(());
    }
    let database = ctx.app_db.read().await.clone();
    let mut transaction = database.pool.begin().await?;
    let delivered_at = current_time().timestamp();
    for event_id in event_ids {
        sqlx::query!(
            "UPDATE notification_outbox SET delivered_at = ? WHERE event_id = ? AND delivered_at IS NULL",
            delivered_at,
            event_id,
        )
        .execute(&mut *transaction)
        .await?;
    }
    transaction.commit().await?;
    Ok(())
}

pub async fn clear_conversation(ctx: &Arc<Context>, conversation_id: &str) -> Result<Vec<String>> {
    let database = ctx.app_db.read().await.clone();
    let mut transaction = database.pool.begin().await?;
    let notification_ids = sqlx::query_scalar!(
        "SELECT notification_id FROM notification_outbox WHERE conversation_id = ? AND cleared_at IS NULL",
        conversation_id,
    )
    .fetch_all(&mut *transaction)
    .await?;
    let cleared_at = current_time().timestamp();
    sqlx::query!(
        "UPDATE notification_outbox SET cleared_at = ? WHERE conversation_id = ? AND cleared_at IS NULL",
        cleared_at,
        conversation_id,
    )
    .execute(&mut *transaction)
    .await?;
    transaction.commit().await?;
    Ok(notification_ids)
}

/// Clears the contact-request notifications. They carry no conversation, so
/// opening the request list is the only moment the user acknowledges them.
pub async fn clear_contact_requests(ctx: &Arc<Context>) -> Result<Vec<String>> {
    let database = ctx.app_db.read().await.clone();
    let mut transaction = database.pool.begin().await?;
    let notification_ids = sqlx::query_scalar!(
        r#"
        SELECT notification_id FROM notification_outbox
        WHERE kind IN ('contact_request', 'accept_request') AND cleared_at IS NULL
        "#,
    )
    .fetch_all(&mut *transaction)
    .await?;
    let cleared_at = current_time().timestamp();
    sqlx::query!(
        r#"
        UPDATE notification_outbox SET cleared_at = ?
        WHERE kind IN ('contact_request', 'accept_request') AND cleared_at IS NULL
        "#,
        cleared_at,
    )
    .execute(&mut *transaction)
    .await?;
    transaction.commit().await?;
    Ok(notification_ids)
}

/// Clears only notifications representing the messages that were actually
/// opened. Events that merely refer to the same message, such as reactions or
/// media-status updates, remain independent notifications.
pub(crate) async fn clear_opened_messages(
    transaction: &mut Transaction<'_, Sqlite>,
    message_ids: &[String],
    cleared_at: i64,
) -> Result<()> {
    for message_id in message_ids {
        sqlx::query(
            r#"
            UPDATE notification_outbox
            SET cleared_at = ?
            WHERE message_id = ?
              AND cleared_at IS NULL
              AND kind IN ('text', 'response', 'image', 'video', 'audio', 'twonly', 'webxdc')
            "#,
        )
        .bind(cleared_at)
        .bind(message_id)
        .execute(&mut **transaction)
        .await?;
    }
    Ok(())
}

struct PendingRow {
    event_id: String,
    notification_id: String,
    conversation_id: Option<String>,
    sender_id: i64,
    sender_name: String,
    avatar_svg_compressed: Option<Vec<u8>>,
    sender_profile_counter: i64,
    conversation_name: Option<String>,
    is_direct_chat: i64,
    message_id: Option<String>,
    kind: String,
    content: Option<String>,
    created_at: i64,
    target_message_type: Option<String>,
    target_media_type: Option<String>,
}

fn parse_arb(source: &str, locale: &str) -> HashMap<String, String> {
    let values: HashMap<String, serde_json::Value> = serde_json::from_str(source)
        .unwrap_or_else(|error| panic!("bundled {locale}.arb is invalid: {error}"));
    values
        .into_iter()
        .filter_map(|(key, value)| value.as_str().map(|value| (key, value.to_owned())))
        .collect()
}

fn translation(locale: &str, key: &str) -> &'static str {
    let language = locale
        .split(['-', '_'])
        .next()
        .unwrap_or("en")
        .to_ascii_lowercase();
    let translations = if language == "de" {
        &*DE_TRANSLATIONS
    } else {
        &*EN_TRANSLATIONS
    };
    translations
        .get(key)
        .or_else(|| EN_TRANSLATIONS.get(key))
        .map(String::as_str)
        .unwrap_or_else(|| panic!("notification translation {key} is missing from en.arb"))
}

fn localized_body(locale: &str, row: &PendingRow) -> String {
    let in_group = if row.conversation_id.is_some() && row.is_direct_chat == 0 {
        row.conversation_name
            .as_deref()
            .map(|name| format!(" {} {}", translation(locale, "notificationFillerIn"), name))
            .unwrap_or_default()
    } else {
        String::new()
    };

    // An app's announcement is already a whole sentence written for the
    // reader, so it is shown as it is rather than described.
    if row.kind == "webxdc" {
        if let Some(announcement) = row.content.as_deref().filter(|text| !text.is_empty()) {
            return announcement.to_owned();
        }
    }

    let key = match row.kind.as_str() {
        "text" => "notificationText",
        "response" => "notificationResponse",
        "twonly" => "notificationTwonly",
        "video" => "notificationVideo",
        "image" => "notificationImage",
        "audio" => "notificationAudio",
        "added_to_group" => "notificationAddedToGroup",
        "contact_request" => "notificationContactRequest",
        "accept_request" => "notificationAcceptRequest",
        "stored_media" => "notificationStoredMediaFile",
        "reopened_media" => "notificationReopenedMedia",
        "reaction" => match (
            row.target_message_type.as_deref(),
            row.target_media_type.as_deref(),
        ) {
            (Some("text"), _) => "notificationReactionToText",
            (Some("media"), Some("video")) => "notificationReactionToVideo",
            (Some("media"), Some("audio")) => "notificationReactionToAudio",
            (Some("media"), Some("image")) => "notificationReactionToImage",
            _ => "notificationReaction",
        },
        _ => "notificationText",
    };

    translation(locale, key)
        .replace("{inGroup}", &in_group)
        .replace("{groupname}", row.content.as_deref().unwrap_or_default())
        .replace("{reaction}", row.content.as_deref().unwrap_or_default())
}

pub(crate) fn notification_avatar_path(
    ctx: &Context,
    sender_id: i64,
    profile_counter: i64,
    svg: Option<&[u8]>,
) -> Result<Option<PathBuf>> {
    crate::services::avatars::notification_avatar_path(ctx, sender_id, profile_counter, svg)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn webxdc_update(info: Option<&str>) -> proto::EncryptedContent {
        let data = proto::AdditionalMessageData {
            r#type: proto::additional_message_data::Type::WebxdcUpdate as i32,
            webxdc_update: Some(proto::WebxdcUpdate {
                instance_id: "instance".into(),
                payload: "{}".into(),
                info: info.map(str::to_owned),
                ..Default::default()
            }),
            ..Default::default()
        };
        proto::EncryptedContent {
            additional_data_message: Some(encrypted_content::AdditionalDataMessage {
                sender_message_id: "message".into(),
                timestamp: 0,
                r#type: "webxdcUpdate".into(),
                additional_message_data: Some(prost::Message::encode_to_vec(&data)),
                hidden: true,
            }),
            ..Default::default()
        }
    }

    fn announcement_of(content: &proto::EncryptedContent) -> Option<String> {
        webxdc_announcement(content.additional_data_message.as_ref().unwrap(), 42)
    }

    #[test]
    fn an_app_announcement_is_what_a_hidden_update_is_worth_waking_for() {
        assert_eq!(
            announcement_of(&webxdc_update(Some("Alice is on turn"))).as_deref(),
            Some("Alice is on turn")
        );
        // A move carries no announcement, and neither does one that is only
        // whitespace once the chat row's own bounds are applied to it.
        assert!(announcement_of(&webxdc_update(None)).is_none());
        assert!(announcement_of(&webxdc_update(Some("  \u{200e} "))).is_none());
    }

    fn targeted_update(notify: &str) -> proto::EncryptedContent {
        let mut content = webxdc_update(Some("Dinner added"));
        let message = content.additional_data_message.as_mut().unwrap();
        let mut data = <proto::AdditionalMessageData as prost::Message>::decode(
            message.additional_message_data.as_deref().unwrap(),
        )
        .unwrap();
        data.webxdc_update.as_mut().unwrap().notify = Some(notify.to_owned());
        message.additional_message_data = Some(prost::Message::encode_to_vec(&data));
        content
    }

    #[tokio::test]
    async fn expense_notifications_only_wake_and_record_affected_members() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"ben","displayName":"Ben"}"#,
        )?;
        let database = ctx.app_db.read().await.clone();
        let mut tx = database.pool.begin().await?;
        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'anna')")
            .execute(&mut *tx)
            .await?;
        sqlx::query("INSERT INTO groups(group_id, group_name) VALUES ('g', 'Trip')")
            .execute(&mut *tx)
            .await?;
        sqlx::query("INSERT INTO messages(message_id, group_id, sender_id, type, content) VALUES ('message-info', 'g', 7, 'text', 'Dinner added')").execute(&mut *tx).await?;
        let address = crate::services::webxdc::WebxdcService::address_for("instance", 42);
        let raw = serde_json::json!({address: "You share dinner: €20"}).to_string();
        let content = targeted_update(&raw);
        assert!(should_wake_receiver(&mut tx, 42, &content).await?);
        assert!(!should_wake_receiver(&mut tx, 43, &content).await?);
        record_incoming_event(&ctx, &mut tx, 7, "included", &content).await?;
        record_incoming_event(&ctx, &mut tx, 7, "included", &content).await?;
        for raw in ["{}", "null", "not JSON", r#"{"someone-else":"Dinner"}"#] {
            let content = targeted_update(raw);
            assert!(!should_wake_receiver(&mut tx, 42, &content).await?);
            record_incoming_event(&ctx, &mut tx, 7, "excluded", &content).await?;
        }
        let rows: Vec<(String, String)> =
            sqlx::query_as("SELECT event_id, content FROM notification_outbox")
                .fetch_all(&mut *tx)
                .await?;
        assert_eq!(
            rows,
            vec![("included".into(), "You share dinner: €20".into())]
        );
        // Older apps omit notify and retain their existing announcements.
        assert!(should_wake_receiver(&mut tx, 43, &webxdc_update(Some("Your turn"))).await?);
        Ok(())
    }

    fn pending_row(kind: &str) -> PendingRow {
        PendingRow {
            event_id: "event".into(),
            notification_id: "notification".into(),
            conversation_id: None,
            sender_id: 7,
            sender_name: "Alice".into(),
            avatar_svg_compressed: None,
            sender_profile_counter: 0,
            conversation_name: None,
            is_direct_chat: 1,
            message_id: None,
            kind: kind.into(),
            content: None,
            created_at: 0,
            target_message_type: None,
            target_media_type: None,
        }
    }

    #[test]
    fn loads_notification_strings_from_arb_and_falls_back_to_english() {
        let row = pending_row("contact_request");
        assert_eq!(
            localized_body("de-DE", &row),
            "möchte sich mit dir vernetzen."
        );
        assert_eq!(localized_body("fr-FR", &row), "wants to connect with you.");
    }

    #[test]
    fn localizes_connection_fallback_notification() {
        assert_eq!(
            fallback_presentation("en-US").body,
            "You may have new messages."
        );
        assert_eq!(
            fallback_presentation("de-DE").body,
            "Du könntest neue Nachrichten haben."
        );
    }

    #[test]
    fn an_app_announcement_is_shown_as_the_app_wrote_it() {
        let mut announcement = pending_row("webxdc");
        announcement.content = Some("Alice is on turn".into());
        // Not "sent a message", and not translated either: the app already
        // localised the sentence for the reader.
        assert_eq!(localized_body("en", &announcement), "Alice is on turn");
        assert_eq!(localized_body("de", &announcement), "Alice is on turn");

        // An app that manages to lose its own text still reads like a message
        // rather than an empty alert.
        announcement.content = None;
        assert_eq!(localized_body("en", &announcement), "sent a message.");
    }

    #[test]
    fn interpolates_group_and_reaction_placeholders() {
        let mut group = pending_row("text");
        group.conversation_id = Some("group".into());
        group.conversation_name = Some("Friends".into());
        group.is_direct_chat = 0;
        assert_eq!(localized_body("en", &group), "sent a message in Friends.");

        let mut reaction = pending_row("reaction");
        reaction.content = Some("🔥".into());
        reaction.target_message_type = Some("media".into());
        reaction.target_media_type = Some("audio".into());
        assert_eq!(
            localized_body("de", &reaction),
            "hat mit 🔥 auf deine Sprachnachricht reagiert."
        );
    }
}
