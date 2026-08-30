/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::{self as proto, encrypted_content};
use crate::api::runtime::ApiRuntime;
use crate::bridge::InitConfig;
use crate::context::{Context, RuntimeMode};
use crate::database::app::AppDatabase;
use crate::error::Result;
use crate::user_config::UserConfig;
use crate::utils::{current_time, milliseconds_to_seconds};
use serde::{Deserialize, Serialize};
use sqlx::{Sqlite, Transaction};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::{Arc, LazyLock};

const MAX_BATCH_SIZE: i64 = 100;
const EN_ARB: &str = include_str!("../../../lib/src/localization/translations/en.arb");
const DE_ARB: &str = include_str!("../../../lib/src/localization/translations/de.arb");

static EN_TRANSLATIONS: LazyLock<HashMap<String, String>> =
    LazyLock::new(|| parse_arb(EN_ARB, "en"));
static DE_TRANSLATIONS: LazyLock<HashMap<String, String>> =
    LazyLock::new(|| parse_arb(DE_ARB, "de"));

pub(crate) fn should_wake_receiver(content: &proto::EncryptedContent) -> bool {
    content.text_message.is_some()
        || content.additional_data_message.is_some()
        || content.group_create.is_some()
        || content
            .media
            .as_ref()
            .and_then(|value| encrypted_content::media::Type::try_from(value.r#type).ok())
            .is_some_and(|kind| kind != encrypted_content::media::Type::Reupload)
        || content.reaction.as_ref().is_some_and(|value| !value.remove)
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
            })
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
        body: translation(locale, "notificationCategoryMessageDesc").to_owned(),
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
    transaction: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    receipt_id: &str,
    content: &proto::EncryptedContent,
) -> Result<()> {
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
        Some(NotificationDraft {
            event_id: receipt_id.to_owned(),
            notification_id: message.sender_message_id.clone(),
            conversation_id,
            sender_id: from_user_id,
            message_id: Some(message.sender_message_id.clone()),
            kind: "text",
            content: None,
            created_at: milliseconds_to_seconds(message.timestamp),
        })
    } else if let Some(reaction) = content.reaction.as_ref().filter(|value| !value.remove) {
        Some(NotificationDraft {
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
    let cleared = sqlx::query(
        r#"
        UPDATE notification_outbox
        SET cleared_at = ?
        WHERE cleared_at IS NULL
          AND kind IN ('text', 'response', 'image', 'video', 'audio', 'twonly')
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
    if cleared.rows_affected() != 0 {
        database.notify_committed(["notification_outbox"]);
    }
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

/// Runs the bounded native notification lifecycle. In a dedicated extension or
/// killed-app process this owns a short-lived background WebSocket. If Flutter
/// is already alive, it waits for the existing foreground connection to commit
/// the incoming message instead of opening a competing session.
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

    let completed = if ctx.runtime_mode == RuntimeMode::Notification {
        let generation = ctx.mailbox_generation();
        ApiRuntime::connect(&ctx).await?;
        tokio::time::timeout(deadline, ctx.wait_for_mailbox_after(generation))
            .await
            .is_ok()
    } else {
        let initial = pending_batch(&ctx, locale).await?;
        if !initial.additions.is_empty() {
            return Ok(initial);
        }
        // Flutter already owns the socket. Nudge the server to redeliver in
        // case the push raced a drain that had already finished.
        if let Ok(client) = ApiRuntime::client(&ctx).await {
            client.request_catch_up().await;
        }
        let generation = ctx.incoming_generation();
        tokio::time::timeout(deadline, ctx.wait_for_incoming_after(generation))
            .await
            .is_ok()
    };

    // Give concurrently acknowledged batches a small window to commit their
    // durable notification rows before the native caller renders the result.
    tokio::time::sleep(std::time::Duration::from_millis(100)).await;
    let mut batch = pending_batch(&ctx, locale).await?;
    batch.completed = completed;

    if ctx.runtime_mode == RuntimeMode::Notification {
        ApiRuntime::close(&ctx).await?;
    }
    Ok(batch)
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
    database.notify_committed(["notification_outbox"]);
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
    database.notify_committed(["notification_outbox"]);
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
    if !notification_ids.is_empty() {
        database.notify_committed(["notification_outbox"]);
    }
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
              AND kind IN ('text', 'response', 'image', 'video', 'audio', 'twonly')
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

fn notification_avatar_path(
    ctx: &Context,
    sender_id: i64,
    profile_counter: i64,
    svg: Option<&[u8]>,
) -> Result<Option<PathBuf>> {
    let Some(svg) = svg else {
        return Ok(None);
    };
    let directory = Path::new(&ctx.config.data_dir).join("notification_avatars");
    std::fs::create_dir_all(&directory)?;
    let output = directory.join(format!("{sender_id}-{profile_counter}.png"));
    if output.exists() {
        return Ok(Some(output));
    }

    let options = resvg::usvg::Options::default();
    let tree = resvg::usvg::Tree::from_data(svg, &options).map_err(|error| {
        crate::error::TwonlyError::Generic(format!("invalid avatar SVG: {error}"))
    })?;
    let original = tree.size();
    let max_dimension = original.width().max(original.height());
    let scale = (256.0 / max_dimension).min(1.0);
    let width = (original.width() * scale).round().max(1.0) as u32;
    let height = (original.height() * scale).round().max(1.0) as u32;
    let mut pixmap = resvg::tiny_skia::Pixmap::new(width, height)
        .ok_or_else(|| crate::error::TwonlyError::Generic("invalid avatar dimensions".into()))?;
    resvg::render(
        &tree,
        resvg::tiny_skia::Transform::from_scale(scale, scale),
        &mut pixmap.as_mut(),
    );
    let png = pixmap.encode_png().map_err(|error| {
        crate::error::TwonlyError::Generic(format!("avatar PNG encoding failed: {error}"))
    })?;
    let temporary = directory.join(format!(".{sender_id}-{profile_counter}.tmp"));
    std::fs::write(&temporary, png)?;
    std::fs::rename(&temporary, &output)?;
    Ok(Some(output))
}

#[cfg(test)]
mod tests {
    use super::*;

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
