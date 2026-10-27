/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::{self as proto, encrypted_content};
use crate::api::runtime::ApiRuntime;
use crate::context::Context;
use crate::database::app::groups::native::{FlameState, Group};
use crate::database::app::AppDatabase;
use crate::error::Result;
use crate::services::mediafiles::{DownloadAvailability, MediaFileService};
use crate::user_config::UserConfig;
use crate::utils::{current_time, milliseconds_to_seconds};
use futures_util::StreamExt as _;
use serde::{Deserialize, Serialize};
use sqlx::{Sqlite, Transaction};
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::{Arc, LazyLock};

// Temporary companion guard for the server's iOS 0.6.x wake-up workaround.
// The server can bound APNs attempts, but only this device-side query can bound
// events that were already downloaded into the local notification outbox.
// Keep Android's existing batch size unchanged.
#[cfg(target_os = "ios")]
const MAX_BATCH_SIZE: i64 = 40;

#[cfg(not(target_os = "ios"))]
const MAX_BATCH_SIZE: i64 = 100;

const EN_ARB: &str = include_str!("../../../lib/src/localization/translations/en.arb");

const DE_ARB: &str = include_str!("../../../lib/src/localization/translations/de.arb");

const AR_ARB: &str = include_str!("../../../lib/src/localization/translations/ar.arb");

static EN_TRANSLATIONS: LazyLock<HashMap<String, String>> =
    LazyLock::new(|| parse_arb(EN_ARB, "en"));

static DE_TRANSLATIONS: LazyLock<HashMap<String, String>> =
    LazyLock::new(|| parse_arb(DE_ARB, "de"));

static AR_TRANSLATIONS: LazyLock<HashMap<String, String>> =
    LazyLock::new(|| parse_arb(AR_ARB, "ar"));

/// The announcement a webxdc update carries, if it has one.
///
/// The update itself is hidden -- app state rather than something a person
/// sent -- but an `info` is written to be read, and becomes a chat row of its
/// own on arrival. That row is what the receiver is woken and notified for.

#[derive(serde::Serialize, serde::Deserialize)]
#[serde(deny_unknown_fields)]
struct GameNotificationContent {
    webxdc_game: crate::services::webxdc::GameNotification,
    instance_id: String,
}

fn webxdc_announcement(
    message: &encrypted_content::AdditionalDataMessage, user_id: i64,
) -> Option<String> {
    let data = <proto::AdditionalMessageData as prost::Message>::decode(
        message.additional_message_data.as_deref()?,
    )
    .ok()?;

    webxdc_notification_content(&data.webxdc_update?, user_id)
}

/// Shared by push notifications and the game's latest chat activity.
pub(crate) fn webxdc_notification_content(
    update: &proto::WebxdcUpdate, user_id: i64,
) -> Option<String> {
    // Keep chat announcements shared, but only wake recipients selected by the app.
    let announcement = crate::services::webxdc::announcement(update)?;

    match update.notify.as_deref() {
        None => Some(announcement),
        Some(raw) => {
            let recipients: std::collections::BTreeMap<
                String,
                crate::services::webxdc::AppNotification,
            > = serde_json::from_str(raw).ok()?;

            let address =
                crate::services::webxdc::WebxdcService::address_for(&update.instance_id, user_id);

            match recipients.get(&address)? {
                crate::services::webxdc::AppNotification::Text(text) => {
                    let mut notification = update.clone();
                    notification.info = Some(text.clone());
                    crate::services::webxdc::announcement(&notification)
                }
                crate::services::webxdc::AppNotification::Game { game } => {
                    serde_json::to_string(&GameNotificationContent {
                        webxdc_game: *game,
                        instance_id: update.instance_id.clone(),
                    })
                    .ok()
                }
            }
        }
    }
}

/// Who wrote the message with this id, as this device has it.
///
/// The two layers say different things and both matter here: the outer `None`
/// means this device has no such message, while an inner `None` means this
/// device wrote it, which is how an own message is stored.
async fn message_sender(
    transaction: &mut Transaction<'_, Sqlite>, message_id: &str,
) -> Result<Option<Option<i64>>> {
    Ok(sqlx::query_scalar!(
        "SELECT sender_id FROM messages WHERE message_id = ?",
        message_id
    )
    .fetch_optional(&mut **transaction)
    .await?)
}

/// Whether `message_id` is one of this device's own story rows, which is what
/// a reply, reaction or save aimed at the user's story points at.
async fn is_own_story(transaction: &mut Transaction<'_, Sqlite>, message_id: &str) -> Result<bool> {
    Ok(sqlx::query_scalar!(
        r#"SELECT EXISTS(
               SELECT 1 FROM messages
               WHERE message_id = ? AND sender_id IS NULL AND is_story = 1
           ) AS "own_story!: bool""#,
        message_id
    )
    .fetch_one(&mut **transaction)
    .await?)
}

/// Whether `text` is nothing but emoji. A reaction to a story travels as a
/// text quoting it, so this is what tells a reaction from a reply.
fn is_emoji_only(text: &str) -> bool {
    fn pictographic(c: char) -> bool {
        matches!(
            c as u32,
            0x1F000..=0x1FAFF
                | 0x2600..=0x27BF
                | 0x2300..=0x23FF
                | 0x2B00..=0x2BFF
                | 0x2190..=0x21FF
                | 0x25A0..=0x25FF
                | 0x00A9
                | 0x00AE
                | 0x203C
                | 0x2049
                | 0x2122
                | 0x2139
                | 0x3030
                | 0x303D
                | 0x3297
                | 0x3299
        )
    }

    // Joiners, variation selectors, skin tones, tags and keycap bases only
    // ever build an emoji out of the pictographs around them.
    fn component(c: char) -> bool {
        matches!(
            c as u32,
            0x200D | 0xFE0E | 0xFE0F | 0x20E3 | 0x1F3FB..=0x1F3FF | 0xE0020..=0xE007F
        ) || c.is_ascii_digit()
            || c == '#'
            || c == '*'
    }

    let text = text.trim();

    !text.is_empty()
        && text.chars().count() <= 16
        // A keycap is a digit or sign wrapped by U+20E3; that mark is what
        // makes "1\u{fe0f}\u{20e3}" an emoji rather than a number.
        && text.chars().any(|c| pictographic(c) || c == '\u{20E3}')
        && text.chars().all(|c| pictographic(c) || component(c))
}

/// Whether this envelope is worth spending the recipient's push budget on.
///
/// A wake-up is not free to get wrong. iOS renders the alert the push carried
/// no matter what the extension finds behind it, so an envelope that wakes a
/// device without leaving it anything to show reaches the user as a bare "You
/// got a new message" -- which is why every arm here has to match something
/// [`record_incoming_event`] will actually record.
pub(crate) async fn should_wake_receiver(
    transaction: &mut Transaction<'_, Sqlite>, target_user_id: i64,
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

    // Keep broadcasting save updates so group members can retain their copy,
    // but only wake the author of the original media.
    let media_update_wakes_receiver = match content.media_update.as_ref() {
        Some(update) => match encrypted_content::media_update::Type::try_from(update.r#type) {
            Ok(encrypted_content::media_update::Type::Stored) => {
                message_sender(transaction, &update.target_message_id)
                    .await?
                    .flatten()
                    == Some(target_user_id)
            }
            Ok(encrypted_content::media_update::Type::Reopened) => true,
            _ => false,
        },
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
        // The sender decided, and wrote into the story, that this is the first
        // item in a day; `record_incoming_event` announces exactly those.
        || content.story.as_ref().is_some_and(|story| story.notify)
        || media_update_wakes_receiver
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
    /// Display name, with the current flame indicator only for direct chats.
    pub sender_name: String,
    pub title: String,
    pub body: String,
    pub text_messages_body: Option<String>,
    pub conversation_name: Option<String>,
    pub is_group: bool,
    pub message_id: Option<String>,
    pub kind: String,
    pub content: Option<String>,
    pub created_at: i64,
    pub avatar_path: Option<String>,
    #[serde(default)]
    pub conversation_avatar_path: Option<String>,
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
    ctx: &Context, transaction: &mut Transaction<'_, Sqlite>, from_user_id: i64, receipt_id: &str,
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
        let is_live_location = message
            .additional_message_data
            .as_deref()
            .and_then(crate::services::live_location::decode)
            .is_some_and(|location| {
                location.message_id == message.sender_message_id
                    && crate::services::live_location::validate(&location).is_ok()
            });

        let is_sticker = message
            .additional_message_data
            .as_deref()
            .and_then(|data| {
                crate::services::stickers::decode_additional(data)
                    .ok()
                    .flatten()
            })
            .is_some();

        // An answer to the user's own story says so: an emoji is a reaction
        // to it, anything else a reply.
        let about_story = match message.quote_message_id.as_deref() {
            Some(quoted) => is_own_story(transaction, quoted).await?,
            None => false,
        };

        let (mut kind, reaction) = if is_live_location {
            ("live_location", None)
        } else {
            match (about_story, message.quote_message_id.is_some(), is_sticker) {
                (true, _, true) => ("story_reply", None),
                (true, _, false) if is_emoji_only(&message.text) => {
                    ("story_reaction", Some(message.text.trim().to_owned()))
                }
                (true, _, false) => ("story_reply", None),
                (false, _, true) => ("sticker", None),
                (false, true, false) => ("response", None),
                (false, false, false) => ("text", None),
            }
        };

        // Mentions change the description, while retaining the usual blocked,
        // visible-conversation and notification delivery rules. Replies that
        // explicitly mention the receiver use the more specific description.
        if matches!(kind, "text" | "response")
            && message.text.contains("@[user:")
            && crate::services::mentions::mentions_user(&message.text, ctx.user_id().await?)
        {
            let is_direct = sqlx::query_scalar!(
                "SELECT is_direct_chat FROM groups WHERE group_id = ?",
                conversation_id.as_deref()
            )
            .fetch_optional(&mut **transaction)
            .await?;
            if is_direct == Some(0) {
                kind = "mention";
            }
        }

        Some(NotificationDraft {
            event_id: receipt_id.to_owned(),
            notification_id: message.sender_message_id.clone(),
            conversation_id,
            sender_id: from_user_id,
            message_id: Some(message.sender_message_id.clone()),
            kind,
            content: reaction,
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
    } else if let Some(story) = content.story.as_ref() {
        // Only the first story in a day woke this device, and the sender says
        // which one that was. Whether to announce it at all is this device's
        // call alone: muted, or from someone the user has not written with in
        // two weeks, it stays quiet. A wake-up it declines is silenced by the
        // notification extension instead of showing the push's placeholder.
        let config = UserConfig::load_required_from(ctx)?;

        // The same chat `handle_story` filed the story under.
        let chat = crate::database::app::groups::native::Group::direct_chat_id(
            ctx.user_id().await?,
            from_user_id,
        );

        match story.media.as_ref() {
            Some(media) if story.notify && config.story_notifications => {
                let filed = message_sender(transaction, &media.sender_message_id).await?
                    == Some(Some(from_user_id));

                let recent =
                    crate::services::stories::exchanged_recently(transaction, &chat, now).await?;

                (filed && recent).then(|| NotificationDraft {
                    event_id: receipt_id.to_owned(),
                    notification_id: media.sender_message_id.clone(),
                    conversation_id: Some(chat.clone()),
                    sender_id: from_user_id,
                    message_id: Some(media.sender_message_id.clone()),
                    kind: "story",
                    content: None,
                    created_at: milliseconds_to_seconds(media.timestamp).min(now),
                })
            }
            _ => None,
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
            let visible_instance = crate::services::webxdc::visibility::visible_instance(
                std::path::Path::new(&ctx.config.data_dir),
            );

            let is_visible = visible_instance.is_some_and(|instance_id| {
                message
                    .additional_message_data
                    .as_deref()
                    .and_then(|bytes| {
                        <proto::AdditionalMessageData as prost::Message>::decode(bytes).ok()
                    })
                    .and_then(|data| data.webxdc_update)
                    .is_some_and(|update| update.instance_id == instance_id)
            });

            announcement.is_some()
                && !is_visible
                && message_sender(transaction, &message_id).await?.is_some()
        } else {
            true
        };

        worth_an_alert.then(|| NotificationDraft {
            event_id: receipt_id.to_owned(),
            notification_id: message.sender_message_id.clone(),
            conversation_id,
            sender_id: from_user_id,
            message_id: Some(message_id),
            // Games carry an outcome for twonly to localize at presentation;
            // other apps can still provide a plain announcement.
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
        let kind = if is_own_story(transaction, &reaction.target_message_id).await? {
            "story_reaction"
        } else {
            "reaction"
        };

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
            kind,
            content: Some(reaction.emoji.clone()),
            created_at: now,
        })
    } else if let Some(update) = content.media_update.as_ref() {
        let update_type = encrypted_content::media_update::Type::try_from(update.r#type)?;

        // Other group members still process the hidden update and store the
        // media when available, but the save notification concerns its author.
        if update_type == encrypted_content::media_update::Type::Stored
            && !matches!(
                message_sender(transaction, &update.target_message_id).await?,
                Some(None)
            )
        {
            return Ok(());
        }

        // Media status updates can arrive without a group ID. Associate the
        // alert with the original message so opening its chat clears it.
        let conversation_id = match conversation_id {
            Some(id) => Some(id),
            None => {
                sqlx::query_scalar!(
                    "SELECT group_id FROM messages WHERE message_id = ?",
                    update.target_message_id,
                )
                .fetch_optional(&mut **transaction)
                .await?
            }
        };

        let story = is_own_story(transaction, &update.target_message_id).await?;

        let kind = match update_type {
            encrypted_content::media_update::Type::Stored if story => Some("stored_story"),
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
    } else {
        content
            .group_create
            .as_ref()
            .map(|create| NotificationDraft {
                event_id: receipt_id.to_owned(),
                notification_id: receipt_id.to_owned(),
                conversation_id,
                sender_id: from_user_id,
                message_id: None,
                kind: "added_to_group",
                content: create.group_name.clone(),
                created_at: now,
            })
    };

    if let Some(draft) = draft {
        draft.insert(transaction).await?;
    }

    Ok(())
}

/// Reconcile old outbox rows and events recorded after their message was
/// opened or deleted. Deleted messages can no longer be acknowledged in the
/// UI, so their alerts must not keep inflating the badge.
async fn clear_stale_messages(database: &Arc<AppDatabase>) -> Result<()> {
    let cleared_at = current_time().timestamp();

    sqlx::query!(
        r#"
        UPDATE notification_outbox
        SET cleared_at = ?
        WHERE cleared_at IS NULL
          AND message_id IS NOT NULL
          AND (
              NOT EXISTS (
                  SELECT 1 FROM messages
                  WHERE messages.message_id = notification_outbox.message_id
              )
              OR EXISTS (
                  SELECT 1 FROM messages
                  WHERE messages.message_id = notification_outbox.message_id
                    AND (
                        messages.is_deleted_from_sender = 1
                        OR (
                            messages.opened_at IS NOT NULL
                            AND notification_outbox.kind IN ('text', 'response', 'mention', 'sticker', 'live_location', 'image', 'video', 'audio', 'twonly', 'webxdc', 'story', 'story_reply', 'story_reaction')
                        )
                    )
              )
          )
        "#,
        cleared_at
    )
    .execute(&database.pool)
    .await?;

    Ok(())
}

/// A turn update may have been queued before the recipient opened the game.
/// Clear only alerts belonging to the visible instance; chat rows stay intact.
async fn clear_visible_webxdc(ctx: &Context, database: &Arc<AppDatabase>) -> Result<()> {
    let Some(instance_id) = crate::services::webxdc::visibility::visible_instance(
        std::path::Path::new(&ctx.config.data_dir),
    ) else {
        return Ok(());
    };

    sqlx::query!(
        "UPDATE notification_outbox SET cleared_at = ?
         WHERE cleared_at IS NULL AND kind = 'webxdc'
           AND notification_id IN (SELECT message_id FROM webxdc_updates WHERE instance_id = ?)",
        current_time().timestamp(),
        instance_id
    )
    .execute(&database.pool)
    .await?;

    Ok(())
}

/// The number of events the user has not dealt with yet. iOS has no way to
/// derive an app icon badge from the delivered alerts, so the running app has
/// to push this value into `UNUserNotificationCenter` itself.
pub async fn badge_count(ctx: &Arc<Context>) -> Result<i64> {
    let database = ctx.app_db.read().await.clone();

    clear_stale_messages(&database).await?;

    clear_visible_webxdc(ctx, &database).await?;

    open_event_count(&database).await
}

/// Media waiting for its reupload is hidden in the chat, so its alert is held
/// back and does not count either until the reupload has arrived.
async fn open_event_count(database: &Arc<AppDatabase>) -> Result<i64> {
    Ok(sqlx::query_scalar!(
        r#"SELECT COUNT(*) AS "count: i64"
           FROM notification_outbox n
           WHERE n.cleared_at IS NULL
             AND NOT EXISTS (
                 SELECT 1 FROM messages m
                 JOIN media_files f ON f.media_id = m.media_id
                 WHERE m.message_id = n.message_id
                   AND n.kind IN ('image', 'video', 'audio', 'twonly', 'story')
                   AND f.download_state = 'reuploadRequested'
             )"#
    )
    .fetch_one(&database.pool)
    .await?)
}

pub async fn pending_batch(ctx: &Arc<Context>, locale: &str) -> Result<NotificationBatch> {
    let database = ctx.app_db.read().await.clone();

    clear_stale_messages(&database).await?;

    clear_visible_webxdc(ctx, &database).await?;

    let rows = sqlx::query_as!(
        PendingRow,
        r#"
        SELECT n.event_id, n.notification_id, n.conversation_id, n.sender_id,
               COALESCE(NULLIF(c.nick_name, ''), c.display_name, c.username) AS "sender_name!: String",
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
          AND (n.kind NOT IN ('image', 'video', 'audio', 'twonly', 'story')
               OR target_media.download_state IS NOT 'reuploadRequested')
        ORDER BY n.created_at, n.event_id
        LIMIT ?
        "#,
        MAX_BATCH_SIZE,
    )
    .fetch_all(&database.pool)
    .await?;

    let badge_count = open_event_count(&database).await?;

    let flame_states = if rows.is_empty() {
        HashMap::new()
    } else {
        Group::flame_states(
            &database.pool,
            Some(
                rows.iter()
                    .filter_map(|row| row.conversation_id.clone())
                    .collect(),
            ),
        )
        .await?
    };

    let mut additions = Vec::with_capacity(rows.len());

    for mut row in rows {
        localize_game_notification(&database.read_pool, locale, &mut row).await?;
        let flame_state = row
            .conversation_id
            .as_ref()
            .and_then(|id| flame_states.get(id))
            .copied()
            .unwrap_or_default();

        let is_group = row.conversation_id.is_some() && row.is_direct_chat == 0;

        let sender_name = if is_group {
            row.conversation_name = row
                .conversation_name
                .map(|name| notification_display_name(&name, flame_state));

            row.sender_name.clone()
        } else {
            notification_display_name(&row.sender_name, flame_state)
        };

        let title = sender_name.clone();

        let body = localized_body(locale, &row);

        let text_messages_body = matches!(row.kind.as_str(), "text" | "response").then(|| {
            translation(locale, "notificationTextMessages")
                .replace("{inGroup}", &group_suffix(locale, &row))
        });

        // A direct chat's stored name may predate a contact profile update.
        // Every native presentation should use the current resolved name.
        let conversation_name = if is_group {
            row.conversation_name
        } else {
            Some(sender_name.clone())
        };

        let avatar_path =
            match crate::services::avatars::ensure_contact_avatar_png(ctx, row.sender_id).await {
                Ok(path) => path.map(|path| path.display().to_string()),
                Err(error) => {
                    tracing::warn!(
                        sender_id = row.sender_id,
                        "failed to prepare notification avatar: {error}"
                    );

                    None
                }
            };

        let conversation_avatar_path = if is_group {
            match crate::services::avatars::ensure_group_avatar_png(
                ctx,
                row.conversation_id.as_deref().unwrap_or_default(),
            )
            .await
            {
                Ok(path) => path.map(|path| path.display().to_string()),
                Err(error) => {
                    tracing::warn!(%error, "failed to prepare group notification avatar");

                    None
                }
            }
        } else {
            None
        };

        additions.push(NotificationAddition {
            event_id: row.event_id,
            notification_id: row.notification_id,
            conversation_id: row.conversation_id,
            sender_id: row.sender_id,
            sender_name,
            title,
            body,
            text_messages_body,
            conversation_name,
            is_group,
            message_id: row.message_id,
            kind: row.kind,
            content: row.content,
            created_at: row.created_at,
            avatar_path,
            conversation_avatar_path,
        });
    }

    Ok(NotificationBatch {
        additions,
        removals: Vec::new(),
        badge_count,
        completed: true,
    })
}

/// Both native renderers use this for the direct-chat sender or group name.
/// Match FlameCounterWidget, using the same derived state as the app so expired
/// counters disappear even before the next media exchange updates the stored
/// row.
fn notification_display_name(name: &str, state: FlameState) -> String {
    if state.counter < 1 {
        return name.to_owned();
    }

    let emoji = if state.counter % 365 == 0 {
        "🎂"
    } else if state.counter == 100 {
        "💯"
    } else if state.is_best_friend {
        "❤️‍🔥"
    } else {
        "🔥"
    };

    let counter = if state.counter == 100 {
        String::new()
    } else {
        state.counter.to_string()
    };

    let expiry = if state.is_expiring { "⌛" } else { "" };

    format!("{name} {counter}{emoji}{expiry}")
}

/// Drains the mailbox and returns the alert the native caller should render.
///
/// This deliberately stops at the batch: everything the wake-up still owes the
/// app — media downloads, widget upkeep, closing the socket — is deferred to
/// [`finalize_wakeup`] so that none of it sits between the incoming message and
/// the notification the user is waiting for.
pub(crate) async fn process_initialized(
    ctx: &Arc<Context>, locale: &str, deadline_ms: u64,
) -> Result<NotificationBatch> {
    let locale = &app_locale(locale);

    // The FCM health check used to be fed by the Dart background isolate, which
    // no longer runs. Record the wake-up here so both platforms report it.
    if let Err(error) = UserConfig::update(ctx, |user| {
        user.last_fcm_wakeup_at = Some(current_time().timestamp());
    }) {
        tracing::warn!("could not record the FCM wake-up timestamp: {error}");
    }

    let deadline = std::time::Duration::from_millis(deadline_ms.clamp(1_000, 28_000));

    let completed = drain_wakeup_mailbox(ctx, deadline).await?;

    // Give concurrently acknowledged batches a small window to commit their
    // durable notification rows before the native caller renders the result.
    tokio::time::sleep(std::time::Duration::from_millis(100)).await;

    // Bounded on its own rather than out of the drain's deadline, which the
    // drain may have spent in full: the extension still has to render.
    match tokio::time::timeout(
        UNDOWNLOADABLE_MEDIA_CHECK_BUDGET,
        hold_back_undownloadable_media(ctx),
    )
    .await
    {
        Ok(Err(error)) => tracing::warn!(%error, "could not check announced media"),
        Err(_) => tracing::info!("announced media check window elapsed"),
        Ok(Ok(())) => {}
    }

    let mut batch = pending_batch(ctx, locale).await?;

    batch.completed = completed;

    tracing::info!(
        completed,
        additions = batch.additions.len(),
        removals = batch.removals.len(),
        "native push processing finished"
    );

    Ok(batch)
}

const UNDOWNLOADABLE_MEDIA_CHECK_BUDGET: std::time::Duration = std::time::Duration::from_secs(4);

/// Incoming media is announced as soon as its message is stored, while the
/// download runs on its own. A download the server refuses ends in a reupload
/// request, and the chat hides a message waiting for one, so an alert for it
/// promises an image the user cannot find.
///
/// Before the batch is built, the server is asked about every announced media
/// file that has not finished downloading. A refused one is downloaded right
/// away: it fails fast, requests the reupload, and [`pending_batch`] holds its
/// alert back until the reupload has arrived. Fail-open: media the server does
/// not answer for is announced as before.
async fn hold_back_undownloadable_media(ctx: &Arc<Context>) -> Result<()> {
    let database = ctx.app_db.read().await.clone();

    let unsettled = sqlx::query!(
        r#"SELECT DISTINCT f.media_id AS "media_id!", f.download_token AS "download_token!"
           FROM notification_outbox n
           JOIN messages m ON m.message_id = n.message_id
           JOIN media_files f ON f.media_id = m.media_id
           WHERE n.delivered_at IS NULL AND n.cleared_at IS NULL
             AND n.kind IN ('image', 'video', 'audio', 'twonly', 'story')
             AND f.download_state IN ('pending', 'downloading')
             AND f.download_token IS NOT NULL"#
    )
    .fetch_all(&database.pool)
    .await?;

    drop(database);

    let media_files = MediaFileService::new(ctx);

    futures_util::stream::iter(unsettled)
        .for_each_concurrent(4, |row| {
            let media_files = &media_files;

            async move {
                if MediaFileService::download_availability(&row.download_token).await
                    != DownloadAvailability::Gone
                {
                    return;
                }

                // The download takes the per-file lock, so a transfer the
                // message handler already started is not raced, and the
                // refusal requests the reupload exactly once.
                if let Err(error) = media_files.download(&row.media_id).await {
                    tracing::warn!(
                        media_id = row.media_id,
                        %error,
                        "could not settle refused media"
                    );
                }
            }
        })
        .await;

    Ok(())
}

async fn drain_wakeup_mailbox(ctx: &Arc<Context>, deadline: std::time::Duration) -> Result<bool> {
    // Sample before connecting/nudging: even an empty mailbox can drain before
    // connect returns. One incoming message is not proof that the drain ended.
    let generation = ctx.mailbox_generation();

    let client = ApiRuntime::client(ctx).await?;
    let mut events = client.events.subscribe();

    tokio::time::timeout(deadline, async {
        client.catch_up_after_push().await?;
        let mut handoff_retry = std::time::Duration::from_millis(250);
        loop {
            if client.background_deferred() {
                // The old foreground socket may still be closing on the
                // server. Retry inside this wake-up's budget rather than
                // waiting for WorkManager's much longer retry backoff.
                tokio::time::sleep(handoff_retry).await;
                client.retry_deferred_push().await?;
                handoff_retry = (handoff_retry * 2).min(std::time::Duration::from_secs(2));
            }

            tokio::select! {
                _ = ctx.wait_for_mailbox_after(generation) => return Ok::<bool, crate::error::TwonlyError>(true),
                event = events.recv() => {
                    if matches!(event, Err(tokio::sync::broadcast::error::RecvError::Closed)) {
                        return Ok(false);
                    }
                }
            }
        }
    })
    .await
    .unwrap_or(Ok(false))
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

    match tokio::time::timeout(remaining(), crate::services::stories::purge_expired(&ctx)).await {
        Ok(Err(error)) => tracing::warn!(%error, "story purge failed during wake-up"),
        Err(error) => tracing::info!(%error, "story purge window elapsed"),
        Ok(Ok(())) => {}
    }

    if owns_connection && ctx.is_notification_runtime() {
        // Inbound handling schedules receipt delivery asynchronously. Even
        // after the mailbox drained, its last flush may still own requests on
        // this socket. Join it within the remaining notification budget.
        match tokio::time::timeout(
            remaining(),
            crate::api::messages::incoming::messages::retransmit_queued_receipts_and_wait(&ctx),
        )
        .await
        {
            Ok(Ok(())) => {}
            Ok(Err(error)) => tracing::warn!(%error, "notification receipt flush failed"),
            Err(_) => tracing::info!("notification receipt flush window elapsed"),
        }

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
pub fn store_fcm_token(ctx: &Context, token: String) -> Result<()> {
    UserConfig::update(ctx, |user| {
        user.fcm_token = Some(token);

        user.update_fcm_token = true;
    })?;

    Ok(())
}

pub(crate) fn acknowledge_fcm_token(ctx: &Context, token: &str) -> Result<()> {
    UserConfig::update(ctx, |user| {
        // A native onNewToken callback can persist a replacement while an
        // older upload is in flight. Its pending registration must survive.
        if user.fcm_token.as_deref() == Some(token) {
            user.update_fcm_token = false;
        }
    })?;
    Ok(())
}

pub(crate) async fn synchronize_fcm_token(ctx: &Arc<Context>) -> Result<()> {
    let Some(user) = UserConfig::load_from(ctx)? else {
        return Ok(());
    };
    if !user.update_fcm_token {
        return Ok(());
    }
    let Some(token) = user.fcm_token.filter(|token| !token.is_empty()) else {
        return Ok(());
    };
    if let crate::bridge::api::ServerResult::ErrorCode(code) =
        crate::api::Server::update_fcm_token(ctx, token.clone()).await?
    {
        return Err(crate::error::TwonlyError::Api(code));
    }
    acknowledge_fcm_token(ctx, &token)?;
    tracing::info!("native FCM registration confirmed by server");
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
            "UPDATE notification_outbox SET delivered_at = ? WHERE event_id = ? AND delivered_at \
             IS NULL",
            delivered_at,
            event_id,
        )
        .execute(&mut *transaction)
        .await?;
    }

    transaction.commit().await?;

    Ok(())
}

/// Opening a chat acknowledges its activity, but media notifications remain
/// until the corresponding media is actually opened.
pub async fn clear_conversation(ctx: &Arc<Context>, conversation_id: &str) -> Result<Vec<String>> {
    let database = ctx.app_db.read().await.clone();

    let mut transaction = database.pool.begin().await?;

    // Recover the chat association for media status alerts recorded by older
    // versions, including alerts that have already been delivered.
    sqlx::query!(
        r#"
        UPDATE notification_outbox SET conversation_id = ?
        WHERE conversation_id IS NULL AND cleared_at IS NULL
          AND kind IN ('reopened_media', 'stored_media', 'stored_story')
          AND message_id IN (SELECT message_id FROM messages WHERE group_id = ?)
        "#,
        conversation_id,
        conversation_id,
    )
    .execute(&mut *transaction)
    .await?;

    let cleared_at = current_time().timestamp();

    let notification_ids = sqlx::query_scalar!(
        r#"
        UPDATE notification_outbox SET cleared_at = ?
        WHERE conversation_id = ? AND cleared_at IS NULL
          AND (
              kind NOT IN ('twonly', 'image', 'video', 'audio', 'story')
              OR EXISTS (
                  SELECT 1 FROM messages
                  WHERE messages.message_id = notification_outbox.message_id
                    AND messages.opened_at IS NOT NULL
              )
          )
        RETURNING notification_id
        "#,
        cleared_at,
        conversation_id
    )
    .fetch_all(&mut *transaction)
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
    transaction: &mut Transaction<'_, Sqlite>, message_ids: &[String], cleared_at: i64,
) -> Result<()> {
    for message_id in message_ids {
        sqlx::query!(
            r#"
            UPDATE notification_outbox
            SET cleared_at = ?
            WHERE message_id = ?
              AND cleared_at IS NULL
              AND kind IN ('text', 'response', 'mention', 'sticker', 'live_location', 'image', 'video', 'audio', 'twonly', 'webxdc', 'story', 'story_reply', 'story_reaction')
            "#,
            cleared_at,
            message_id
        )
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

/// The language picked in the app's settings, or the device's locale when the
/// user left it on the system default or the configuration is not readable.
pub fn app_locale(device_locale: &str) -> String {
    Context::get_static()
        .ok()
        .and_then(|ctx| UserConfig::load_from(ctx).ok().flatten())
        .and_then(|user| user.language)
        .unwrap_or_else(|| device_locale.to_owned())
}

fn translation(locale: &str, key: &str) -> &'static str {
    let language = locale
        .split(['-', '_'])
        .next()
        .unwrap_or("en")
        .to_ascii_lowercase();

    let translations = match language.as_str() {
        "de" => &*DE_TRANSLATIONS,
        "ar" => &*AR_TRANSLATIONS,
        _ => &*EN_TRANSLATIONS,
    };

    translations
        .get(key)
        .or_else(|| EN_TRANSLATIONS.get(key))
        .map(String::as_str)
        .unwrap_or_else(|| panic!("notification translation {key} is missing from en.arb"))
}

fn group_suffix(locale: &str, row: &PendingRow) -> String {
    if row.conversation_id.is_some() && row.is_direct_chat == 0 {
        row.conversation_name
            .as_deref()
            .map(|name| format!(" {} {}", translation(locale, "notificationFillerIn"), name))
            .unwrap_or_default()
    } else {
        String::new()
    }
}

async fn localize_game_notification(
    pool: &sqlx::SqlitePool, locale: &str, row: &mut PendingRow,
) -> Result<()> {
    if row.kind != "webxdc" {
        return Ok(());
    }
    let Some(content) = row
        .content
        .as_deref()
        .and_then(|content| serde_json::from_str::<GameNotificationContent>(content).ok())
    else {
        return Ok(());
    };
    // Resolve the title from this chat's installed app, never from game text.
    let app: Option<(String, Option<String>, Option<String>)> = sqlx::query!(
        r#"SELECT i.app_id, a.name AS "name?", a.name_translations AS "name_translations?"
           FROM webxdc_instances i
           LEFT JOIN webxdc_apps a ON a.app_id = i.app_id AND a.version = i.version
           WHERE i.instance_id = ? AND i.group_id = ?"#,
        &content.instance_id,
        &row.conversation_id
    )
    .map(|app| (app.app_id, app.name, app.name_translations))
    .fetch_optional(pool)
    .await?;
    let name = app
        .map(|(id, name, translations)| {
            translations
                .and_then(|names| {
                    crate::services::webxdc::store::pick_localized(
                        &names,
                        &[locale.replace('_', "-")],
                    )
                })
                .or(name)
                .unwrap_or(id)
        })
        .unwrap_or_else(|| translation(locale, "notificationGameFallbackName").to_owned());
    let key = match content.webxdc_game {
        crate::services::webxdc::GameNotification::Turn => "notificationGameTurn",
        crate::services::webxdc::GameNotification::Won => "notificationGameWon",
        crate::services::webxdc::GameNotification::Lost => "notificationGameLost",
    };
    row.content = Some(translation(locale, key).replace("{gameName}", &name));
    Ok(())
}

fn localized_body(locale: &str, row: &PendingRow) -> String {
    let in_group = group_suffix(locale, row);

    // Game outcomes were localized above. Other apps' plain announcements
    // remain readable as supplied by those apps.
    if row.kind == "webxdc" {
        if let Some(announcement) = row.content.as_deref().filter(|text| !text.is_empty()) {
            return announcement.to_owned();
        }
    }

    let key = match row.kind.as_str() {
        "text" => "notificationText",
        "mention" => "notificationMention",
        "response" => "notificationResponse",
        "sticker" => "notificationSticker",
        "live_location" => "notificationLiveLocation",
        "twonly" => "notificationTwonly",
        "video" => "notificationVideo",
        "image" => "notificationImage",
        "audio" => "notificationAudio",
        "added_to_group" => "notificationAddedToGroup",
        "contact_request" => "notificationContactRequest",
        "accept_request" => "notificationAcceptRequest",
        "stored_media" => "notificationStoredMediaFile",
        "story" => "notificationStory",
        "story_reply" => "notificationStoryReply",
        "story_reaction" => "notificationStoryReaction",
        "stored_story" => "notificationStoredStory",
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
    ctx: &Context, sender_id: i64, profile_counter: i64, svg: Option<&[u8]>,
) -> Result<Option<PathBuf>> {
    crate::services::avatars::notification_avatar_path(ctx, sender_id, profile_counter, svg)
}

#[cfg(test)]
mod tests {

    use super::*;

    #[tokio::test]
    async fn acknowledging_an_old_fcm_upload_preserves_the_replacement_registration() -> Result<()>
    {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        UserConfig::save_json(&ctx, r#"{"userId":42,"username":"me","displayName":"Me"}"#)?;
        store_fcm_token(&ctx, "old".into())?;
        store_fcm_token(&ctx, "new".into())?;
        acknowledge_fcm_token(&ctx, "old")?;
        let user = UserConfig::load_required_from(&ctx)?;
        assert_eq!(user.fcm_token.as_deref(), Some("new"));
        assert!(user.update_fcm_token);
        acknowledge_fcm_token(&ctx, "new")?;
        assert!(!UserConfig::load_required_from(&ctx)?.update_fcm_token);
        crate::api::runtime::ApiRuntime::close(&ctx).await?;
        Ok(())
    }

    #[tokio::test]
    async fn native_fcm_registration_reaches_the_server_without_flutter() -> Result<()> {
        use crate::api::proto::{client_to_server, server_to_client};
        use crate::api::runtime::ApiClient;
        use crate::bridge::api::{ApiConfig, ApiConnectionState};
        use futures_util::{SinkExt, StreamExt};
        use prost::Message;
        use std::sync::atomic::Ordering;
        use std::time::Duration;
        use stream_tungstenite::tokio_tungstenite::{accept_async, tungstenite};

        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        ApiRuntime::close(&ctx).await?;
        assert!(!ctx.is_flutter_runtime());
        UserConfig::save_json(&ctx, r#"{"userId":42,"username":"me","displayName":"Me"}"#)?;
        store_fcm_token(&ctx, "replacement-token".into())?;

        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await?;
        let address = listener.local_addr()?;
        let peer = tokio::spawn(async move {
            let (socket, _) = listener.accept().await.unwrap();
            let mut socket = accept_async(socket).await.unwrap();
            let message = socket.next().await.unwrap().unwrap();
            let request = client_to_server::ClientToServer::decode(message.into_data()).unwrap();
            let Some(client_to_server::client_to_server::V::V0(request)) = request.v else {
                panic!("missing envelope")
            };
            let Some(client_to_server::v0::Kind::Applicationdata(application)) = request.kind
            else {
                panic!("missing application request")
            };
            let Some(client_to_server::application_data::ApplicationData::UpdateGoogleFcmToken(
                token,
            )) = application.application_data
            else {
                panic!("missing token registration")
            };
            assert_eq!(token.google_fcm, "replacement-token");
            let response = server_to_client::ServerToClient {
                v: Some(server_to_client::server_to_client::V::V0(
                    server_to_client::V0 {
                        seq: request.seq,
                        kind: Some(server_to_client::v0::Kind::Response(
                            server_to_client::Response {
                                response: Some(server_to_client::response::Response::Ok(
                                    server_to_client::response::Ok {
                                        ok: Some(server_to_client::response::ok::Ok::None(true)),
                                    },
                                )),
                            },
                        )),
                    },
                )),
            };
            socket
                .send(tungstenite::Message::Binary(
                    response.encode_to_vec().into(),
                ))
                .await
                .unwrap();
            let _ = socket.next().await;
        });
        let client = ApiClient::new(
            &ctx,
            ApiConfig {
                websocket_url: format!("ws://{address}"),
                legacy_user_app_version: 0,
                in_background: true,
                can_use_login_token_for_auth: true,
            },
        );
        *ctx.api_client.get().unwrap().write().await = client.clone();
        client.connect().await?;
        tokio::time::timeout(Duration::from_secs(2), async {
            while *client.state.read().await != ApiConnectionState::Connected {
                tokio::task::yield_now().await;
            }
        })
        .await
        .unwrap();
        // This fixture tests registration over an established background
        // session; authentication itself has separate integration coverage.
        client.is_authenticated.store(true, Ordering::Release);
        tokio::time::timeout(Duration::from_secs(2), synchronize_fcm_token(&ctx))
            .await
            .unwrap()?;
        assert!(!UserConfig::load_required_from(&ctx)?.update_fcm_token);
        client.close().await;
        tokio::time::timeout(Duration::from_secs(2), peer)
            .await
            .unwrap()
            .unwrap();
        Ok(())
    }

    #[tokio::test]
    async fn group_mentions_notify_the_target_and_keep_message_contents_private() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        UserConfig::save_json(&ctx, r#"{"userId":42,"username":"me","displayName":"Me"}"#)?;
        ctx.inject_test_user_id(42).await?;
        let db = ctx.app_db.read().await.clone();
        let mut tx = db.pool.begin().await?;
        sqlx::query("INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'alice', 1)")
            .execute(&mut *tx)
            .await?;
        sqlx::query(
            "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('group', 'Friends', \
             0), ('direct', 'Alice', 1)",
        )
        .execute(&mut *tx)
        .await?;
        let cases = [
            ("group", "Hi @[user:42]", false, "mention"),
            ("group", "Hi @[user:42] and @[user:42]", false, "mention"),
            ("group", "Hi @[user:7]", false, "text"),
            ("group", "@@[user:42]", false, "text"),
            ("group", "@@@[user:42]", false, "text"),
            ("group", "@[user:042]", false, "text"),
            ("group", "Hi @Me", false, "text"),
            ("direct", "Hi @[user:42]", false, "text"),
            ("group", "Hi @[user:42]", true, "mention"),
            ("group", "Hi @[user:7]", true, "response"),
        ];
        for (index, (group, text, reply, kind)) in cases.iter().enumerate() {
            let id = format!("mention-{index}");
            sqlx::query(
                "INSERT INTO messages(message_id, group_id, sender_id, type, content) VALUES (?, \
                 ?, 7, 'text', ?)",
            )
            .bind(&id)
            .bind(group)
            .bind(text)
            .execute(&mut *tx)
            .await?;
            let content = proto::EncryptedContent {
                group_id: Some((*group).into()),
                text_message: Some(encrypted_content::TextMessage {
                    sender_message_id: id.clone(),
                    text: (*text).into(),
                    timestamp: current_time().timestamp_millis(),
                    quote_message_id: reply.then(|| "earlier-message".into()),
                    ..Default::default()
                }),
                ..Default::default()
            };
            // Retries must produce only one event, including repeated mentions.
            for _ in 0..2 {
                record_incoming_event(&ctx, &mut tx, 7, &id, &content).await?;
            }
            let actual: (String, Option<String>) =
                sqlx::query_as("SELECT kind, content FROM notification_outbox WHERE event_id = ?")
                    .bind(&id)
                    .fetch_one(&mut *tx)
                    .await?;
            assert_eq!(actual, ((*kind).into(), None));
        }
        // Blocked senders remain silent even when mentioning the receiver.
        sqlx::query("UPDATE contacts SET blocked = 1 WHERE user_id = 7")
            .execute(&mut *tx)
            .await?;
        record_incoming_event(
            &ctx,
            &mut tx,
            7,
            "blocked-mention",
            &proto::EncryptedContent {
                group_id: Some("group".into()),
                text_message: Some(encrypted_content::TextMessage {
                    sender_message_id: "blocked-mention".into(),
                    text: "@[user:42]".into(),
                    ..Default::default()
                }),
                ..Default::default()
            },
        )
        .await?;
        sqlx::query("UPDATE contacts SET blocked = 0 WHERE user_id = 7")
            .execute(&mut *tx)
            .await?;
        tx.commit().await?;

        let batch = pending_batch(&ctx, "en").await?;
        assert_eq!(batch.additions.len(), cases.len());
        let mentions: Vec<_> = batch
            .additions
            .iter()
            .filter(|entry| entry.kind == "mention")
            .collect();
        assert_eq!(mentions.len(), 3);
        for mention in mentions {
            assert_eq!(mention.body, "mentioned you in a message in Friends.");
            assert!(mention.text_messages_body.is_none());
            assert!(mention.content.is_none());
        }
        let german = pending_batch(&ctx, "de").await?;
        assert!(german
            .additions
            .iter()
            .filter(|entry| entry.kind == "mention")
            .all(|entry| entry.body == "hat dich in einer Nachricht in Friends erwähnt."));
        assert_eq!(
            clear_conversation(&ctx, "group").await?.len(),
            cases.len() - 1
        );
        assert_eq!(pending_batch(&ctx, "en").await?.additions.len(), 1);
        Ok(())
    }

    #[tokio::test]

    async fn native_push_restores_a_stopped_shared_connection_and_waits_for_mailbox() -> Result<()>
    {
        use crate::api::runtime::ApiClient;
        use crate::bridge::api::{ApiConfig, ApiConnectionState};
        use std::sync::atomic::Ordering;
        use std::time::Duration;

        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        ApiRuntime::close(&ctx).await?;

        // Reproduce the shared-process path: the context is not a dedicated
        // notification runtime, and Flutter's cached reachability is offline.
        assert!(!ctx.is_notification_runtime());

        let client = ApiClient::new(
            &ctx,
            ApiConfig {
                websocket_url: "ws://127.0.0.1:1".into(),
                legacy_user_app_version: 0,
                in_background: true,
                can_use_login_token_for_auth: true,
            },
        );

        *ctx.api_client.get().unwrap().write().await = client.clone();

        client.set_network_available(false).await?;

        ctx.mark_mailbox_drained(); // An old drain must not finish this wake-up.

        let mut drain = Box::pin(drain_wakeup_mailbox(&ctx, Duration::from_secs(1)));

        // Poll the worker until it waits for the server, without running the
        // socket tasks. No external network or live server is needed.
        tokio::select! {
            biased;
            result = &mut drain => panic!("mailbox completed before the server drained it: {result:?}"),
            () = std::future::ready(()) => {}
        }

        assert!(client.ws_client.lock().await.is_some());

        assert_eq!(*client.state.read().await, ApiConnectionState::Connecting);

        assert!(client.network_available.load(Ordering::Acquire));

        assert!(client.in_background.load(Ordering::Acquire));

        assert!(client.requested_background.load(Ordering::Acquire));

        // Empty mailboxes count as completed too; waiting for an incoming chat
        // message used to make duplicate pushes time out and retry needlessly.
        ctx.mark_mailbox_drained();

        assert!(drain.await?);

        client.close().await;

        Ok(())
    }

    #[tokio::test]

    async fn native_push_without_a_mailbox_drain_remains_retryable() -> Result<()> {
        use crate::api::runtime::ApiClient;
        use crate::bridge::api::{ApiConfig, ApiConnectionState};
        use std::time::Duration;

        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        ApiRuntime::close(&ctx).await?;

        let client = ApiClient::new(
            &ctx,
            ApiConfig {
                websocket_url: "ws://127.0.0.1:1".into(),
                legacy_user_app_version: 0,
                in_background: true,
                can_use_login_token_for_auth: true,
            },
        );

        *ctx.api_client.get().unwrap().write().await = client.clone();

        // An inert transport keeps this timeout test entirely offline.
        *client.ws_client.lock().await = Some(Arc::new(
            stream_tungstenite::WebSocketClient::builder("ws://127.0.0.1:1").build(),
        ));

        client.set_state(ApiConnectionState::Authenticated).await;

        ctx.mark_mailbox_drained();

        assert!(!drain_wakeup_mailbox(&ctx, Duration::from_millis(10)).await?);

        client.close().await;

        Ok(())
    }

    #[test]

    fn notification_names_match_the_app_flame_counter() {
        for (counter, is_best_friend, is_expiring, expected) in [
            (0, false, false, "Alice"),
            (0, true, true, "Alice"),
            (12, false, false, "Alice 12🔥"),
            (12, false, true, "Alice 12🔥⌛"),
            (12, true, false, "Alice 12❤️‍🔥"),
            (12, true, true, "Alice 12❤️‍🔥⌛"),
            (100, false, false, "Alice 💯"),
            (100, true, true, "Alice 💯⌛"),
            (365, true, false, "Alice 365🎂"),
            (730, false, true, "Alice 730🎂⌛"),
            (366, false, false, "Alice 366🔥"),
        ] {
            assert_eq!(
                notification_display_name(
                    "Alice",
                    FlameState {
                        counter,
                        is_best_friend,
                        is_expiring
                    },
                ),
                expected,
            );
        }
    }

    #[tokio::test]

    async fn notification_batches_put_flames_on_direct_senders_and_group_names() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let db = ctx.app_db.read().await.clone();

        for statement in [
            "INSERT INTO contacts(user_id, username, display_name, nick_name) VALUES (7, 'alice', \
             'Alice', 'Ali')",
            "INSERT INTO groups(group_id, group_name, is_direct_chat, flame_counter) VALUES \
             ('direct', 'Old name', 1, 12), ('group', 'Friends', 0, 12)",
            "INSERT INTO notification_outbox(event_id, notification_id, conversation_id, \
             sender_id, kind, created_at) VALUES ('direct', 'image', 'direct', 7, 'image', 1), \
             ('group', 'text', 'group', 7, 'text', 2), ('request', 'request', NULL, 7, \
             'contact_request', 3)",
        ] {
            sqlx::query(sqlx::AssertSqlSafe(statement))
                .execute(&db.pool)
                .await?;
        }

        let today = crate::utils::start_of_local_day()?;

        for (age_days, best_friend, expected, expected_group) in [
            (0, false, "Ali 12🔥", "Friends 12🔥"),
            (0, true, "Ali 12❤️‍🔥", "Friends 12🔥"),
            (2, false, "Ali 12🔥⌛", "Friends 12🔥⌛"),
            (3, false, "Ali", "Friends"),
        ] {
            let exchanged = today - age_days * 86_400 + 1;

            sqlx::query(
                "UPDATE groups SET last_message_send = ?, last_message_received = ?, \
                 last_flame_counter_change = ?, also_best_friend = ?, total_media_counter = 100 \
                 WHERE group_id = 'direct'",
            )
            .bind(exchanged)
            .bind(exchanged)
            .bind(exchanged)
            .bind(best_friend)
            .execute(&db.pool)
            .await?;

            sqlx::query(
                "UPDATE groups SET last_message_send = ?, last_message_received = ?, \
                 last_flame_counter_change = ? WHERE group_id = 'group'",
            )
            .bind(exchanged)
            .bind(exchanged)
            .bind(exchanged)
            .execute(&db.pool)
            .await?;

            let batch = pending_batch(&ctx, "en").await?;

            assert_eq!(batch.additions.len(), 3);

            let direct = &batch.additions[0];

            assert_eq!(direct.sender_name, expected);

            assert_eq!(direct.title, expected);

            assert_eq!(direct.conversation_name.as_deref(), Some(expected));

            assert_eq!(direct.body, "sent an image.");

            assert_eq!(direct.event_id, "direct");

            assert_eq!(direct.notification_id, "image");

            let group = &batch.additions[1];

            assert_eq!(group.sender_name, "Ali");

            assert_eq!(group.title, "Ali");

            assert_eq!(group.conversation_name.as_deref(), Some(expected_group));

            assert_eq!(group.body, format!("sent a message in {expected_group}."));

            assert_eq!(
                group.text_messages_body.as_deref(),
                Some(format!("sent {{count}} messages in {expected_group}.").as_str()),
            );

            assert_eq!(batch.additions[2].sender_name, "Ali");
        }

        Ok(())
    }

    /// The chat hides media waiting for its reupload. Its alert waits with it,
    /// and is shown once the reupload has arrived and downloaded.
    #[tokio::test]

    async fn media_waiting_for_its_reupload_is_announced_only_once_it_arrives() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let db = ctx.app_db.read().await.clone();

        sqlx::raw_sql(
            "INSERT INTO contacts(user_id, username) VALUES (7, 'alice');
             INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('chat', 'Alice', 1);
             INSERT INTO media_files(media_id, type, download_state)
             VALUES ('refused', 'image', 'reuploadRequested'), ('fine', 'image', 'ready');
             INSERT INTO messages(message_id, group_id, sender_id, type, media_id)
             VALUES ('refused', 'chat', 7, 'media', 'refused'),
                    ('fine', 'chat', 7, 'media', 'fine'),
                    ('text', 'chat', 7, 'text', NULL);
             INSERT INTO notification_outbox(event_id, notification_id, conversation_id, \
             sender_id, message_id, kind, created_at)
             VALUES ('refused', 'refused', 'chat', 7, 'refused', 'image', 1),
                    ('fine', 'fine', 'chat', 7, 'fine', 'image', 2),
                    ('text', 'text', 'chat', 7, 'text', 'text', 3);",
        )
        .execute(&db.pool)
        .await?;

        let announced = |batch: &NotificationBatch| {
            batch
                .additions
                .iter()
                .map(|addition| addition.event_id.clone())
                .collect::<Vec<_>>()
        };

        let batch = pending_batch(&ctx, "en").await?;

        assert_eq!(announced(&batch), vec!["fine", "text"]);

        assert_eq!(batch.badge_count, 2);

        assert_eq!(badge_count(&ctx).await?, 2);

        sqlx::query("UPDATE media_files SET download_state = 'ready' WHERE media_id = 'refused'")
            .execute(&db.pool)
            .await?;

        let batch = pending_batch(&ctx, "en").await?;

        assert_eq!(announced(&batch), vec!["refused", "fine", "text"]);

        assert_eq!(badge_count(&ctx).await?, 3);

        Ok(())
    }

    #[tokio::test]

    async fn deleting_messages_clears_badge_and_broadcasts_outbox_changes() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let db = ctx.app_db.read().await.clone();

        sqlx::raw_sql(
            "INSERT INTO contacts(user_id, username) VALUES (7, 'alice');
             INSERT INTO groups(group_id, group_name) VALUES ('chat', 'Alice');
             INSERT INTO messages(message_id, group_id, type)
             VALUES ('image-1', 'chat', 'media'), ('image-2', 'chat', 'media'),
                    ('image-3', 'chat', 'media'), ('image-4', 'chat', 'media'),
                    ('unopened', 'chat', 'media');
             INSERT INTO notification_outbox(event_id, notification_id, conversation_id, \
             sender_id, message_id, kind, created_at, delivered_at)
             SELECT message_id, message_id, group_id, 7, message_id, 'image', 1,
                    CASE WHEN message_id IN ('image-1', 'image-2') THEN 1 END
             FROM messages;
             INSERT INTO notification_outbox(event_id, notification_id, sender_id, kind, \
             created_at)
             VALUES ('request', 'request', 7, 'contact_request', 1);",
        )
        .execute(&db.pool)
        .await?;

        assert_eq!(badge_count(&ctx).await?, 6);

        let mut changes = db.subscribe();

        sqlx::query("DELETE FROM messages WHERE message_id LIKE 'image-%'")
            .execute(&db.pool)
            .await?;

        let changed = tokio::time::timeout(std::time::Duration::from_secs(1), changes.recv())
            .await
            .unwrap()
            .unwrap();

        assert!(changed.tables.contains("notification_outbox"));

        // Assert the trigger worked before badge reconciliation can repair it.
        let cleared: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM notification_outbox WHERE cleared_at IS NOT NULL",
        )
        .fetch_one(&db.pool)
        .await?;

        assert_eq!(cleared, 4);

        assert_eq!(badge_count(&ctx).await?, 2);

        assert!(clear_conversation(&ctx, "chat").await?.is_empty());

        let batch = pending_batch(&ctx, "en").await?;

        assert_eq!(batch.badge_count, 2);

        assert_eq!(batch.additions.len(), 2);

        assert!(batch
            .additions
            .iter()
            .all(|n| n.event_id == "unopened" || n.event_id == "request"));

        Ok(())
    }

    #[tokio::test]

    async fn badge_and_batch_repair_legacy_deleted_message_notifications() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let db = ctx.app_db.read().await.clone();

        sqlx::raw_sql(
            "INSERT INTO contacts(user_id, username) VALUES (7, 'alice');
             INSERT INTO groups(group_id, group_name) VALUES ('chat', 'Alice');
             INSERT INTO messages(message_id, group_id, type, is_deleted_from_sender)
             VALUES ('tombstone', 'chat', 'media', 1), ('unopened', 'chat', 'media', 0);
             INSERT INTO notification_outbox(event_id, notification_id, conversation_id, \
             sender_id, message_id, kind, created_at)
             VALUES ('image', 'image', 'chat', 7, 'missing-image', 'image', 1),
                    ('text', 'text', 'chat', 7, 'missing-text', 'text', 1),
                    ('reaction', 'reaction', 'chat', 7, 'missing-target', 'reaction', 1),
                    ('deleted', 'deleted', 'chat', 7, 'tombstone', 'video', 1),
                    ('unopened', 'unopened', 'chat', 7, 'unopened', 'image', 1),
                    ('request', 'request', NULL, 7, NULL, 'contact_request', 1);",
        )
        .execute(&db.pool)
        .await?;

        // Legacy rows may already have been delivered, or may still be pending.
        for delivered_at in [None, Some(1_i64)] {
            sqlx::query("UPDATE notification_outbox SET cleared_at = NULL, delivered_at = ?")
                .bind(delivered_at)
                .execute(&db.pool)
                .await?;

            assert_eq!(badge_count(&ctx).await?, 2);

            // The extension's batch path must also repair the rows on its own.
            sqlx::query("UPDATE notification_outbox SET cleared_at = NULL")
                .execute(&db.pool)
                .await?;

            let batch = pending_batch(&ctx, "en").await?;

            assert_eq!(batch.badge_count, 2);

            assert_eq!(
                batch.additions.len(),
                if delivered_at.is_some() { 0 } else { 2 }
            );
        }

        Ok(())
    }

    #[tokio::test]

    async fn sender_and_chat_deletion_clear_notifications_transactionally() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let db = ctx.app_db.read().await.clone();

        sqlx::raw_sql(
            "INSERT INTO contacts(user_id, username) VALUES (7, 'alice');
             INSERT INTO groups(group_id, group_name) VALUES ('chat', 'Alice');
             INSERT INTO messages(message_id, group_id, type) VALUES ('image', 'chat', 'media');
             INSERT INTO notification_outbox(event_id, notification_id, conversation_id, \
             sender_id, message_id, kind, created_at)
             VALUES ('image', 'image', 'chat', 7, 'image', 'image', 1),
                    ('reaction', 'reaction', 'chat', 7, 'image', 'reaction', 1);",
        )
        .execute(&db.pool)
        .await?;

        for statement in [
            "UPDATE messages SET is_deleted_from_sender = 1 WHERE message_id = 'image'",
            "DELETE FROM groups WHERE group_id = 'chat'",
        ] {
            let mut tx = db.pool.begin().await?;

            let mut changes = db.subscribe();

            sqlx::query(sqlx::AssertSqlSafe(statement))
                .execute(&mut *tx)
                .await?;

            let remaining: i64 = sqlx::query_scalar(
                "SELECT COUNT(*) FROM notification_outbox WHERE cleared_at IS NULL",
            )
            .fetch_one(&mut *tx)
            .await?;

            assert_eq!(remaining, 0);

            tx.rollback().await?;

            assert_eq!(badge_count(&ctx).await?, 2);

            assert!(matches!(
                changes.try_recv(),
                Err(tokio::sync::broadcast::error::TryRecvError::Empty)
            ));
        }

        sqlx::query("UPDATE messages SET is_deleted_from_sender = 1 WHERE message_id = 'image'")
            .execute(&db.pool)
            .await?;

        assert_eq!(badge_count(&ctx).await?, 0);

        Ok(())
    }

    #[tokio::test]

    async fn location_shares_notify_once_per_chat_and_updates_stay_silent() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        UserConfig::save_json(&ctx, r#"{"userId":42,"username":"me","displayName":"Me"}"#)?;

        let db = ctx.app_db.read().await.clone();

        let mut tx = db.pool.begin().await?;

        sqlx::query(
            "INSERT INTO contacts(user_id, username, display_name, accepted) VALUES (7, 'alice', \
             'Alice', 1)",
        )
        .execute(&mut *tx)
        .await?;

        sqlx::query(
            "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('chat', 'Alice', \
             1), ('group', 'Friends', 0)",
        )
        .execute(&mut *tx)
        .await?;

        sqlx::query(
            "INSERT INTO group_members(group_id, contact_id) VALUES ('chat', 7), ('group', 7)",
        )
        .execute(&mut *tx)
        .await?;

        let mut message_ids = Vec::new();

        for group in ["chat", "group"] {
            let timestamp = current_time().timestamp_millis();

            let mut location = proto::LiveLocationData {
                session_id: uuid::Uuid::new_v4().to_string(),
                message_id: uuid::Uuid::new_v4().to_string(),
                updated_at_ms: timestamp,
                expires_at_ms: timestamp + 600_000,
                ..Default::default()
            };

            let metadata = proto::AdditionalMessageData {
                r#type: proto::additional_message_data::Type::LiveLocation as i32,
                live_location: Some(location.clone()),
                ..Default::default()
            };

            let message = encrypted_content::TextMessage {
                sender_message_id: location.message_id.clone(),
                text: "Live location".into(),
                timestamp,
                additional_message_data: Some(prost::Message::encode_to_vec(&metadata)),
                ..Default::default()
            };

            let content = proto::EncryptedContent {
                group_id: Some(group.into()),
                text_message: Some(message),
                ..Default::default()
            };

            assert!(should_wake_receiver(&mut tx, 42, &content).await?);

            crate::api::messages::incoming::handle_encrypted(
                &ctx,
                &mut tx,
                7,
                group,
                content.clone(),
            )
            .await?;

            // A transport retry does not create another alert.
            crate::api::messages::incoming::handle_encrypted(&ctx, &mut tx, 7, group, content)
                .await?;

            message_ids.push(location.message_id.clone());

            for stopped in [false, true] {
                location.updated_at_ms += 1;

                location.latitude = Some(52.52);

                location.longitude = Some(13.405);

                location.accuracy = Some(8.0);

                location.fix_timestamp_ms = Some(timestamp);

                location.stopped = stopped;

                let metadata = proto::AdditionalMessageData {
                    live_location: Some(location.clone()),
                    ..metadata.clone()
                };

                let update = encrypted_content::AdditionalDataMessage {
                    sender_message_id: uuid::Uuid::new_v4().to_string(),
                    timestamp: location.updated_at_ms,
                    r#type: "liveLocation".into(),
                    hidden: true,
                    additional_message_data: Some(prost::Message::encode_to_vec(&metadata)),
                };

                let content = proto::EncryptedContent {
                    group_id: Some(group.into()),
                    additional_data_message: Some(update),
                    ..Default::default()
                };

                assert!(!should_wake_receiver(&mut tx, 42, &content).await?);

                crate::api::messages::incoming::handle_encrypted(
                    &ctx,
                    &mut tx,
                    7,
                    &location.updated_at_ms.to_string(),
                    content,
                )
                .await?;
            }
        }

        tx.commit().await?;

        for (locale, direct_body, group_body) in [
            (
                "en",
                "shared their live location.",
                "shared their live location in Friends.",
            ),
            (
                "de",
                "hat den Live-Standort geteilt.",
                "hat den Live-Standort in Friends geteilt.",
            ),
            (
                "ar",
                "شارك موقعه المباشر.",
                "شارك موقعه المباشر في Friends.",
            ),
        ] {
            let batch = pending_batch(&ctx, locale).await?;

            assert_eq!(batch.additions.len(), 2);

            assert_eq!(batch.badge_count, 2);

            for addition in batch.additions {
                assert_eq!(addition.title, "Alice");

                assert_eq!(addition.kind, "live_location");

                assert_eq!(addition.text_messages_body, None);

                assert!(message_ids.contains(addition.message_id.as_ref().unwrap()));

                assert_eq!(
                    addition.body,
                    if addition.is_group {
                        group_body
                    } else {
                        direct_body
                    }
                );
            }
        }

        let mut tx = db.pool.begin().await?;

        clear_opened_messages(&mut tx, &message_ids[..1], current_time().timestamp()).await?;

        tx.commit().await?;

        assert_eq!(pending_batch(&ctx, "en").await?.additions.len(), 1);

        // A chat may be opened before its push worker renders the alert.
        sqlx::query("UPDATE messages SET opened_at = ? WHERE message_id = ?")
            .bind(current_time().timestamp())
            .bind(&message_ids[1])
            .execute(&db.pool)
            .await?;

        assert!(pending_batch(&ctx, "en").await?.additions.is_empty());

        assert_eq!(badge_count(&ctx).await?, 0);

        Ok(())
    }

    #[tokio::test]

    async fn opening_chat_preserves_only_unopened_media_notifications() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let database = ctx.app_db.read().await.clone();

        let mut tx = database.pool.begin().await?;

        sqlx::query("INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'alice', 1)")
            .execute(&mut *tx)
            .await?;

        sqlx::query(
            "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('direct', 'Alice', \
             1), ('group', 'Friends', 0)",
        )
        .execute(&mut *tx)
        .await?;

        let media_kinds = ["twonly", "image", "video", "audio", "story"];

        let activity_kinds = [
            "text",
            "response",
            "mention",
            "sticker",
            "live_location",
            "webxdc",
            "story_reply",
            "story_reaction",
            "reaction",
            "stored_media",
            "reopened_media",
            "stored_story",
            "added_to_group",
        ];

        for chat in ["direct", "group"] {
            for kind in media_kinds {
                for opened in [false, true] {
                    for delivered in [false, true] {
                        let id = format!("{chat}-{kind}-{opened}-{delivered}");

                        sqlx::query(
                            "INSERT INTO messages(message_id, group_id, sender_id, type, \
                             opened_at, is_story) VALUES (?, ?, 7, 'media', ?, ?)",
                        )
                        .bind(&id)
                        .bind(chat)
                        .bind(opened.then_some(1_i64))
                        .bind(kind == "story")
                        .execute(&mut *tx)
                        .await?;

                        sqlx::query(
                            "INSERT INTO notification_outbox(event_id, notification_id, \
                             conversation_id, sender_id, message_id, kind, created_at, \
                             delivered_at) VALUES (?, ?, ?, 7, ?, ?, 1, ?)",
                        )
                        .bind(&id)
                        .bind(&id)
                        .bind(chat)
                        .bind(&id)
                        .bind(kind)
                        .bind(delivered.then_some(1_i64))
                        .execute(&mut *tx)
                        .await?;
                    }
                }
            }

            for kind in activity_kinds {
                let id = format!("{chat}-{kind}");

                sqlx::query(
                    "INSERT INTO notification_outbox(event_id, notification_id, conversation_id, \
                     sender_id, message_id, kind, created_at, delivered_at) VALUES (?, ?, ?, 7, \
                     ?, ?, 1, 1)",
                )
                .bind(&id)
                .bind(&id)
                .bind(chat)
                // Activity referring to unopened media must still be cleared.
                .bind(format!("{chat}-image-false-false"))
                .bind(kind)
                .execute(&mut *tx)
                .await?;
            }
        }

        tx.commit().await?;

        for chat in ["direct", "group"] {
            let mut expected = activity_kinds
                .iter()
                .map(|kind| format!("{chat}-{kind}"))
                .collect::<Vec<_>>();

            for kind in media_kinds {
                for delivered in [false, true] {
                    expected.push(format!("{chat}-{kind}-true-{delivered}"));
                }
            }

            expected.sort();

            let mut removed = clear_conversation(&ctx, chat).await?;

            removed.sort();

            assert_eq!(removed, expected);

            assert!(clear_conversation(&ctx, chat).await?.is_empty());

            let remaining: Vec<String> = sqlx::query_scalar(
                "SELECT notification_id FROM notification_outbox WHERE conversation_id = ? AND \
                 cleared_at IS NULL ORDER BY notification_id",
            )
            .bind(chat)
            .fetch_all(&database.pool)
            .await?;

            let mut unopened = media_kinds
                .iter()
                .flat_map(|kind| {
                    [false, true].map(|delivered| format!("{chat}-{kind}-false-{delivered}"))
                })
                .collect::<Vec<_>>();

            unopened.sort();

            assert_eq!(remaining, unopened);

            if chat == "direct" {
                let other_uncleared: i64 = sqlx::query_scalar(
                    "SELECT COUNT(*) FROM notification_outbox WHERE conversation_id = 'group' AND \
                     cleared_at IS NULL",
                )
                .fetch_one(&database.pool)
                .await?;

                assert_eq!(
                    other_uncleared,
                    (media_kinds.len() * 4 + activity_kinds.len()) as i64
                );
            }

            let mut tx = database.pool.begin().await?;

            clear_opened_messages(&mut tx, &unopened, current_time().timestamp()).await?;

            tx.commit().await?;
        }

        assert_eq!(badge_count(&ctx).await?, 0);

        Ok(())
    }

    #[tokio::test]

    async fn opening_chat_clears_reopened_media_with_and_without_a_chat_id() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let database = ctx.app_db.read().await.clone();

        let mut tx = database.pool.begin().await?;

        for statement in [
            "INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'alice', 1)",
            "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('chat', 'Alice', \
             1), ('other-chat', 'Other', 1)",
            "INSERT INTO messages(message_id, group_id, type) VALUES ('image', 'chat', 'media'), \
             ('other-image', 'other-chat', 'media')",
            "INSERT INTO notification_outbox(event_id, notification_id, sender_id, message_id, \
             kind, created_at, delivered_at) VALUES ('legacy', 'legacy-alert', 7, 'image', \
             'reopened_media', 1, 1), ('other', 'other-alert', 7, 'other-image', \
             'reopened_media', 1, 1)",
        ] {
            sqlx::query(sqlx::AssertSqlSafe(statement))
                .execute(&mut *tx)
                .await?;
        }

        let content = proto::EncryptedContent {
            media_update: Some(encrypted_content::MediaUpdate {
                r#type: encrypted_content::media_update::Type::Reopened as i32,
                target_message_id: "image".into(),
            }),
            ..Default::default()
        };

        record_incoming_event(&ctx, &mut tx, 7, "new-alert", &content).await?;

        tx.commit().await?;

        let before = pending_batch(&ctx, "en").await?;

        assert_eq!(before.badge_count, 3);

        assert_eq!(before.additions.len(), 1);

        assert_eq!(before.additions[0].kind, "reopened_media");

        assert_eq!(before.additions[0].conversation_id.as_deref(), Some("chat"));

        let mut removed = clear_conversation(&ctx, "chat").await?;

        removed.sort();

        assert_eq!(removed, vec!["legacy-alert", "new-alert"]);

        let after = pending_batch(&ctx, "en").await?;

        assert!(after.additions.is_empty());

        assert_eq!(after.badge_count, 1);

        assert!(clear_conversation(&ctx, "chat").await?.is_empty());

        assert_eq!(
            clear_conversation(&ctx, "other-chat").await?,
            vec!["other-alert"]
        );

        assert_eq!(badge_count(&ctx).await?, 0);

        Ok(())
    }

    #[tokio::test]

    async fn text_notification_counts_are_localized_without_changing_event_ids() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let database = ctx.app_db.read().await.clone();

        for statement in [
            "INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'alice', 1)",
            "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('g', 'Friends', 0)",
            "INSERT INTO notification_outbox(event_id, notification_id, conversation_id, \
             sender_id, kind, created_at) VALUES ('event', 'message', 'g', 7, 'text', 1)",
        ] {
            sqlx::query(sqlx::AssertSqlSafe(statement))
                .execute(&database.pool)
                .await?;
        }

        for (locale, expected) in [
            ("en", "sent {count} messages in Friends."),
            ("de", "hat {count} Nachrichten in Friends gesendet."),
            ("ar", "{count} رسائل جديدة في Friends."),
        ] {
            let batch = pending_batch(&ctx, locale).await?;

            assert_eq!(batch.additions.len(), 1);

            let addition = &batch.additions[0];

            assert_eq!(addition.text_messages_body.as_deref(), Some(expected));

            assert_eq!(addition.event_id, "event");

            assert_eq!(addition.notification_id, "message");

            assert_eq!(batch.badge_count, 1);
        }

        Ok(())
    }

    #[tokio::test]

    async fn direct_notification_titles_follow_current_contact_names_instead_of_stored_chat_names(
    ) -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let db = ctx.app_db.read().await.clone();

        for statement in [
            "INSERT INTO contacts(user_id, username, display_name, accepted) VALUES (7, 'tobi', \
             'Tobi ✌', 1)",
            "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('direct', 'Tobi ✌', \
             1), ('group', 'Friends', 0)",
            "INSERT INTO notification_outbox(event_id, notification_id, conversation_id, \
             sender_id, kind, created_at) VALUES ('text', 'text', 'direct', 7, 'text', 1), \
             ('image', 'image', 'direct', 7, 'image', 2), ('location', 'location', 'direct', 7, \
             'live_location', 3), ('group', 'group', 'group', 7, 'image', 4)",
        ] {
            sqlx::query(sqlx::AssertSqlSafe(statement))
                .execute(&db.pool)
                .await?;
        }

        for (update, expected) in [
            (
                "UPDATE contacts SET display_name = 'Tobi' WHERE user_id = 7",
                "Tobi",
            ),
            (
                "UPDATE contacts SET nick_name = 'Nickname' WHERE user_id = 7",
                "Nickname",
            ),
        ] {
            sqlx::query(sqlx::AssertSqlSafe(update))
                .execute(&db.pool)
                .await?;

            let batch = pending_batch(&ctx, "de").await?;

            assert_eq!(batch.additions.len(), 4);

            for addition in &batch.additions {
                assert_eq!(addition.sender_name, expected);

                assert_eq!(addition.title, expected);

                assert!(!addition.body.contains(expected));

                assert_eq!(
                    addition.conversation_name.as_deref(),
                    Some(if addition.is_group {
                        "Friends"
                    } else {
                        expected
                    },)
                );
            }
        }

        Ok(())
    }

    #[tokio::test]

    async fn notification_batch_shows_no_avatar_when_none_exists() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        let db = ctx.app_db.read().await.clone();

        for statement in [
            "INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'alice', 1)",
            "INSERT INTO contacts(user_id, username, accepted, avatar_svg_compressed) VALUES \
             (8, 'bob', 1, '<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"10\" \
             height=\"10\"><rect width=\"10\" height=\"10\" fill=\"red\"/></svg>')",
            "INSERT INTO groups(group_id, group_name) VALUES ('g', 'Friends')",
            "INSERT INTO groups(group_id, group_name) VALUES ('h', 'Family')",
            "INSERT INTO group_members(group_id, contact_id) VALUES ('g', 7), ('h', 8)",
            "INSERT INTO notification_outbox(event_id, notification_id, conversation_id, \
             sender_id, kind, created_at) VALUES ('group', 'group', 'g', 7, 'text', 1)",
            "INSERT INTO notification_outbox(event_id, notification_id, sender_id, kind, \
             created_at) VALUES ('direct', 'direct', 7, 'text', 2)",
            "INSERT INTO notification_outbox(event_id, notification_id, conversation_id, \
             sender_id, kind, created_at) VALUES ('avatar', 'avatar', 'h', 8, 'text', 3)",
        ] {
            sqlx::query(sqlx::AssertSqlSafe(statement))
                .execute(&db.pool)
                .await?;
        }

        let batch = pending_batch(&ctx, "en").await?;

        let addition = |event: &str| {
            batch
                .additions
                .iter()
                .find(|addition| addition.event_id == event)
                .unwrap()
        };

        // Alice has no avatar, and neither does the only member of her group.
        let group = addition("group");

        assert!(group.is_group);

        assert_eq!(group.avatar_path, None);

        assert_eq!(group.conversation_avatar_path, None);

        assert_eq!(addition("direct").avatar_path, None);

        let with_avatar = addition("avatar");

        assert!(std::path::Path::new(with_avatar.avatar_path.as_ref().unwrap()).exists());

        let group_avatar = with_avatar.conversation_avatar_path.as_ref().unwrap();

        assert!(std::path::Path::new(group_avatar).exists());

        let json = serde_json::to_value(with_avatar).unwrap();

        assert_eq!(
            json["conversation_avatar_path"].as_str(),
            Some(group_avatar.as_str())
        );

        Ok(())
    }

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
    async fn game_outcomes_use_receiver_localization_catalog_names_and_contact_names() -> Result<()>
    {
        use crate::services::webxdc::WebxdcService;
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        UserConfig::save_json(&ctx, r#"{"userId":42,"username":"me","displayName":"Me"}"#)?;
        let database = ctx.app_db.read().await.clone();
        let mut tx = database.pool.begin().await?;
        for statement in [
            "INSERT INTO contacts(user_id, username, display_name, nick_name) VALUES \
             (7,'ben','Ben','Benny')",
            "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('g','Games',1)",
            "INSERT INTO webxdc_apps(app_id, version, name, name_translations, bundle_sha256, \
             bundle_bytes, cached_at) VALUES \
             ('chess',1,'Chess','{\"en\":\"Chess\",\"de\":\"Schach\",\"ar\":\"الشطرنج\"}','hash',\
             1,0)",
        ] {
            sqlx::query(statement).execute(&mut *tx).await?;
        }
        for outcome in ["turn", "won", "lost"] {
            let instance_id = format!("card-{outcome}");
            sqlx::query(
                "INSERT INTO messages(message_id,group_id,type) VALUES (?,'g','webxdcApp')",
            )
            .bind(&instance_id)
            .execute(&mut *tx)
            .await?;
            sqlx::query(
                "INSERT INTO webxdc_instances(instance_id,group_id,app_id,version,origin_token) \
                 VALUES (?,'g','chess',1,?)",
            )
            .bind(&instance_id)
            .bind(&instance_id)
            .execute(&mut *tx)
            .await?;
            let update = proto::WebxdcUpdate {
                instance_id: instance_id.clone(),
                payload: "{}".into(),
                info: Some("Sender supplied words must not become the push text".into()),
                notify: Some(serde_json::json!({WebxdcService::address_for(&instance_id,42): {"game":outcome}}).to_string()),
                ..Default::default()
            };
            WebxdcService::handle_incoming_update(&mut tx, outcome, "g", 7, &update, 1, 42).await?;
            let card = crate::database::app::messages::queries::get(&mut tx, &instance_id)
                .await?
                .unwrap();
            let origin = <proto::AdditionalMessageData as prost::Message>::decode(
                card.additional_message_data.as_deref().unwrap(),
            )?
            .webxdc_origin
            .unwrap();
            assert_eq!(
                origin.notification_content,
                webxdc_notification_content(&update, 42),
                "the bubble and push must carry the same recipient's outcome"
            );
            assert_eq!(card.content, update.info);
            if outcome == "turn" {
                // Simulate a card written before recipient-specific metadata
                // was saved alongside the shared announcement.
                let mut old = <proto::AdditionalMessageData as prost::Message>::decode(
                    card.additional_message_data.as_deref().unwrap(),
                )?;
                old.webxdc_origin.as_mut().unwrap().notification_content = None;
                sqlx::query("UPDATE messages SET additional_message_data = ? WHERE message_id = 'turn-info'")
                    .bind(prost::Message::encode_to_vec(&old))
                    .execute(&mut *tx)
                    .await?;
            }
            let data = proto::AdditionalMessageData {
                webxdc_update: Some(update),
                ..Default::default()
            };
            let content = proto::EncryptedContent {
                group_id: Some("g".into()),
                additional_data_message: Some(encrypted_content::AdditionalDataMessage {
                    sender_message_id: outcome.into(),
                    hidden: true,
                    additional_message_data: Some(prost::Message::encode_to_vec(&data)),
                    ..Default::default()
                }),
                ..Default::default()
            };
            assert!(should_wake_receiver(&mut tx, 42, &content).await?);
            assert!(!should_wake_receiver(&mut tx, 43, &content).await?);
            record_incoming_event(&ctx, &mut tx, 7, outcome, &content).await?;
        }
        tx.commit().await?;
        sqlx::query("DELETE FROM app_metadata WHERE key = 'webxdc_notification_content_restored'")
            .execute(&database.pool)
            .await?;
        for _ in 0..2 {
            crate::database::app::webxdc::queries::restore_notification_content(&database.pool)
                .await?;
        }
        let restored = crate::database::app::messages::queries::get(
            &mut *database.read_pool.acquire().await?,
            "card-turn",
        )
        .await?
        .unwrap();
        let restored = <proto::AdditionalMessageData as prost::Message>::decode(
            restored.additional_message_data.as_deref().unwrap(),
        )?
        .webxdc_origin
        .unwrap()
        .notification_content
        .unwrap();
        assert_eq!(
            serde_json::from_str::<serde_json::Value>(&restored)?["webxdc_game"],
            "turn"
        );
        for (locale, expected) in [
            (
                "en",
                [
                    "has played Chess. It is your turn.",
                    "has played Chess. You have won.",
                    "has played Chess. You have lost.",
                ],
            ),
            (
                "de-DE",
                [
                    "hat Schach gespielt. Du bist am Zug.",
                    "hat Schach gespielt. Du hast gewonnen.",
                    "hat Schach gespielt. Du hast verloren.",
                ],
            ),
            (
                "ar",
                [
                    "لعب الشطرنج. حان دورك.",
                    "لعب الشطرنج. لقد فزت.",
                    "لعب الشطرنج. لقد خسرت.",
                ],
            ),
        ] {
            let batch = pending_batch(&ctx, locale).await?;
            assert_eq!(batch.additions.len(), 3);
            for (outcome, body) in ["turn", "won", "lost"].into_iter().zip(expected) {
                let alert = batch
                    .additions
                    .iter()
                    .find(|alert| alert.event_id == outcome)
                    .unwrap();
                assert_eq!(alert.title, "Benny");
                assert_eq!(alert.body, body);
            }
        }
        let address = WebxdcService::address_for("instance", 42);
        for malformed in [
            serde_json::json!({"game":"draw"}),
            serde_json::json!({"game":"turn","text":"injected"}),
        ] {
            assert!(announcement_of(&targeted_update(
                &serde_json::json!({&address:malformed}).to_string()
            ))
            .is_none());
        }
        Ok(())
    }

    #[tokio::test]

    async fn visible_game_moves_keep_chat_info_without_alerting_and_other_games_still_alert(
    ) -> Result<()> {
        use crate::services::webxdc::WebxdcService;

        let directory = tempfile::tempdir()?;

        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;

        UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"ben","displayName":"Ben"}"#,
        )?;

        let database = ctx.app_db.read().await.clone();

        let data_dir = std::path::Path::new(&ctx.config.data_dir);

        let mut tx = database.pool.begin().await?;

        for statement in [
            "INSERT INTO contacts(user_id, username) VALUES (7, 'anna')",
            "INSERT INTO groups(group_id, group_name) VALUES ('g', 'Games')",
            "INSERT INTO messages(message_id, group_id, type) VALUES ('connect4', 'g', \
             'webxdcApp'), ('mills', 'g', 'webxdcApp')",
            "INSERT INTO webxdc_instances(instance_id, group_id, app_id, version, origin_token) \
             VALUES ('connect4', 'g', 'connect4', 1, 'connect4-origin'), ('mills', 'g', 'mills', \
             1, 'mills-origin')",
        ] {
            sqlx::query(statement).execute(&mut *tx).await?;
        }

        for (instance_id, message_id, visible) in [
            ("connect4", "visible-move", Some("connect4")),
            ("mills", "other-game-move", Some("connect4")),
            ("connect4", "background-move", None),
        ] {
            ctx.webxdc_visibility.set(data_dir, visible)?;

            let update = proto::WebxdcUpdate {
                instance_id: instance_id.into(),
                payload: "{}".into(),
                info: Some("Anna played a move. Ben is on turn".into()),
                notify: Some(
                    serde_json::json!({WebxdcService::address_for(instance_id, 42): {"game":"turn"}})
                        .to_string(),
                ),
                ..Default::default()
            };

            WebxdcService::handle_incoming_update(&mut tx, message_id, "g", 7, &update, 1, 42)
                .await?;

            let data = proto::AdditionalMessageData {
                r#type: proto::additional_message_data::Type::WebxdcUpdate as i32,
                webxdc_update: Some(update),
                ..Default::default()
            };

            let content = proto::EncryptedContent {
                group_id: Some("g".into()),
                additional_data_message: Some(encrypted_content::AdditionalDataMessage {
                    sender_message_id: message_id.into(),
                    hidden: true,
                    additional_message_data: Some(prost::Message::encode_to_vec(&data)),
                    ..Default::default()
                }),
                ..Default::default()
            };

            assert!(should_wake_receiver(&mut tx, 42, &content).await?);

            assert!(!should_wake_receiver(&mut tx, 43, &content).await?);

            record_incoming_event(&ctx, &mut tx, 7, message_id, &content).await?;

            // Transport redelivery must not duplicate the announcement or alert.
            WebxdcService::handle_incoming_update(
                &mut tx,
                message_id,
                "g",
                7,
                data.webxdc_update.as_ref().unwrap(),
                1,
                42,
            )
            .await?;

            record_incoming_event(&ctx, &mut tx, 7, message_id, &content).await?;
        }

        tx.commit().await?;

        let announcements: Vec<String> =
            sqlx::query_scalar("SELECT content FROM messages WHERE type = 'text'")
                .fetch_all(&database.pool)
                .await?;

        assert_eq!(
            announcements,
            vec!["Anna played a move. Ben is on turn"; 2],
            "only the latest announcement for each game stays in the chat",
        );

        let batch = pending_batch(&ctx, "en").await?;

        assert_eq!(batch.additions.len(), 2);

        assert!(batch.additions.iter().all(|alert| alert.body
            == if alert.event_id == "other-game-move" {
                "has played mills. It is your turn."
            } else {
                "has played connect4. It is your turn."
            }));

        assert!(batch
            .additions
            .iter()
            .all(|alert| alert.event_id != "visible-move"));

        // Opening this game before a worker renders its queued turn clears only
        // that game's alert, including when both games live in the same chat.
        ctx.webxdc_visibility.set(data_dir, Some("connect4"))?;

        let batch = pending_batch(&ctx, "en").await?;

        assert_eq!(batch.additions.len(), 1);

        assert_eq!(batch.additions[0].event_id, "other-game-move");

        assert_eq!(batch.badge_count, 1);

        assert_eq!(badge_count(&ctx).await?, 1);

        Ok(())
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

        sqlx::query(
            "INSERT INTO messages(message_id, group_id, sender_id, type, content) VALUES \
             ('message-info', 'g', 7, 'text', 'Dinner added')",
        )
        .execute(&mut *tx)
        .await?;

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

    fn tells_a_reaction_from_a_reply() {
        for reaction in ["🔥", " ❤️ ", "👍🏽", "👨‍👩‍👧", "1️⃣", "🇩🇪", "😂😂"]
        {
            assert!(is_emoji_only(reaction), "{reaction:?} is a reaction");
        }

        for reply in ["", "nice", "nice 🔥", "12", "#", "🔥 wow"] {
            assert!(!is_emoji_only(reply), "{reply:?} is a reply");
        }
    }

    #[test]

    fn words_what_happened_to_a_story() {
        let mut reaction = pending_row("story_reaction");

        reaction.content = Some("🔥".into());

        assert_eq!(
            localized_body("en", &reaction),
            "has reacted with 🔥 to your story."
        );

        assert_eq!(
            localized_body("de", &reaction),
            "hat mit 🔥 auf deine Story reagiert."
        );

        assert_eq!(
            localized_body("en", &pending_row("story_reply")),
            "has replied to your story."
        );

        assert_eq!(
            localized_body("de", &pending_row("stored_story")),
            "hat deine Story gespeichert."
        );
    }

    #[tokio::test]

    async fn stored_media_only_wakes_and_notifies_its_original_sender() -> Result<()> {
        use crate::api::messages::incoming::messages::queue_encrypted_content;

        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        let database = ctx.app_db.read().await.clone();
        let mut tx = database.pool.begin().await?;

        for statement in [
            "INSERT INTO contacts(user_id, username) VALUES (7, 'saver'), (42, 'author'), (43, \
             'member')",
            "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('direct', 'Direct', \
             1), ('group', 'Group', 0)",
        ] {
            sqlx::query(statement).execute(&mut *tx).await?;
        }

        for chat in ["direct", "group"] {
            for (target, sender, notify) in [
                ("own", None, true),
                ("received", Some(42_i64), false),
                ("unknown", None, false),
            ] {
                let message_id = format!("{chat}-{target}");
                if target != "unknown" {
                    sqlx::query(
                        "INSERT INTO messages(message_id, group_id, sender_id, type) VALUES (?, \
                         ?, ?, 'media')",
                    )
                    .bind(&message_id)
                    .bind(chat)
                    .bind(sender)
                    .execute(&mut *tx)
                    .await?;
                }

                // Legacy updates without a chat ID must obey the same rule.
                for group_id in [Some(chat.to_owned()), None] {
                    let content = proto::EncryptedContent {
                        group_id,
                        media_update: Some(encrypted_content::MediaUpdate {
                            r#type: encrypted_content::media_update::Type::Stored as i32,
                            target_message_id: message_id.clone(),
                        }),
                        ..Default::default()
                    };

                    for recipient in [7, 42, 43] {
                        let receipt_id =
                            queue_encrypted_content(&mut tx, recipient, content.clone(), true)
                                .await?;
                        let wake: bool = sqlx::query_scalar(
                            "SELECT wake_receiver FROM receipts WHERE receipt_id = ?",
                        )
                        .bind(&receipt_id)
                        .fetch_one(&mut *tx)
                        .await?;
                        assert_eq!(wake, sender == Some(recipient), "{message_id}, {recipient}");
                    }

                    let event_id = format!("{message_id}-{}", content.group_id.is_some());
                    record_incoming_event(&ctx, &mut tx, 7, &event_id, &content).await?;
                    let kind: Option<String> = sqlx::query_scalar(
                        "SELECT kind FROM notification_outbox WHERE event_id = ?",
                    )
                    .bind(event_id)
                    .fetch_optional(&mut *tx)
                    .await?;
                    assert_eq!(kind.as_deref(), notify.then_some("stored_media"));
                }
            }
        }

        Ok(())
    }

    #[tokio::test]

    async fn answers_to_the_own_story_are_announced_as_such() -> Result<()> {
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

        for statement in [
            "INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'anna', 1)",
            "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('d', 'Anna', 1)",
            "INSERT INTO messages(message_id, group_id, type, is_story) VALUES ('mine', 'd', \
             'media', 1)",
            "INSERT INTO messages(message_id, group_id, type, content) VALUES ('plain', 'd', \
             'text', 'hi')",
        ] {
            sqlx::query(sqlx::AssertSqlSafe(statement))
                .execute(&mut *tx)
                .await?;
        }

        let text = |id: &str, text: &str, quote: &str| proto::EncryptedContent {
            group_id: Some("d".into()),
            text_message: Some(encrypted_content::TextMessage {
                sender_message_id: id.into(),
                text: text.into(),
                quote_message_id: Some(quote.into()),
                ..Default::default()
            }),
            ..Default::default()
        };

        record_incoming_event(&ctx, &mut tx, 7, "r1", &text("t1", "🔥", "mine")).await?;

        record_incoming_event(&ctx, &mut tx, 7, "r2", &text("t2", "love it", "mine")).await?;

        record_incoming_event(&ctx, &mut tx, 7, "r3", &text("t3", "🔥", "plain")).await?;

        let stored = proto::EncryptedContent {
            media_update: Some(encrypted_content::MediaUpdate {
                r#type: encrypted_content::media_update::Type::Stored as i32,
                target_message_id: "mine".into(),
            }),
            ..Default::default()
        };

        record_incoming_event(&ctx, &mut tx, 7, "r4", &stored).await?;

        let rows: Vec<(String, Option<String>)> =
            sqlx::query_as("SELECT kind, content FROM notification_outbox ORDER BY event_id")
                .fetch_all(&mut *tx)
                .await?;

        assert_eq!(
            rows,
            vec![
                ("story_reaction".into(), Some("🔥".into())),
                ("story_reply".into(), None),
                // An emoji on anything else is an ordinary reply.
                ("response".into(), None),
                ("stored_story".into(), None),
            ]
        );

        Ok(())
    }

    #[test]

    fn announces_a_story_in_every_language() {
        let row = pending_row("story");

        assert_eq!(localized_body("en", &row), "posted a story.");

        assert_eq!(localized_body("de", &row), "hat eine Story gepostet.");

        assert_eq!(localized_body("ar", &row), "قصة جديدة.");
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

        assert_eq!(localized_body("ar", &group), "رسالة جديدة في Friends.");

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
