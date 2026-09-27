/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::media;
use crate::api::proto::client::encrypted_content;
use crate::context::Context;
use crate::database::app::tables::{Contact, Group};
use crate::error::{Result, TwonlyError};
use crate::services::stories::STORY_LIFETIME_SECONDS;
use crate::utils::milliseconds_to_seconds;
use encrypted_content::media::Type as MediaType;
use sqlx::{Sqlite, Transaction};
use std::sync::Arc;

/// When the story was posted, capped at `now`: a timestamp from the future
/// would otherwise keep the story around for longer than its 24 hours.
pub(crate) fn posted_at(story: &encrypted_content::Story, now: i64) -> i64 {
    story
        .media
        .as_ref()
        .map_or(0, |media| milliseconds_to_seconds(media.timestamp))
        .min(now)
}

pub(crate) fn is_expired(story: &encrypted_content::Story) -> bool {
    let now = chrono::Utc::now().timestamp();
    posted_at(story, now) + STORY_LIFETIME_SECONDS <= now
}

/// Files a story item under the 1:1 chat with its sender, where it stays
/// hidden until it is saved. Expired items never get here; see
/// `handle_encrypted`.
pub(crate) async fn handle_story(
    ctx: &Arc<Context>,
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    story: encrypted_content::Story,
) -> Result<()> {
    let posted_at = posted_at(&story, chrono::Utc::now().timestamp());
    let Some(mut media) = story.media else {
        return Err(TwonlyError::UnprocessableContent(
            "story carries no media".into(),
        ));
    };
    if !matches!(
        MediaType::try_from(media.r#type)?,
        MediaType::Image | MediaType::Video
    ) {
        tracing::warn!(
            from_user_id,
            "dropping a story that is not an image or video"
        );
        return Ok(());
    }

    let Some(contact) = Contact::get_contact_by_id(t, from_user_id)
        .await?
        .filter(|contact| {
            contact.accepted != 0 && contact.blocked == 0 && contact.deleted_by_user == 0
        })
    else {
        tracing::info!(
            from_user_id,
            "dropping a story from someone who is not a contact"
        );
        return Ok(());
    };

    let group_id = Group::direct_chat_id(ctx.user_id().await?, from_user_id);
    let has_chat = sqlx::query_scalar!(
        r#"SELECT EXISTS(SELECT 1 FROM groups WHERE group_id = ?) AS "exists!: bool""#,
        group_id,
    )
    .fetch_one(&mut **t)
    .await?;
    if !has_chat {
        Group::create_direct_chat(ctx, t, contact).await?;
    }

    // A story replays until it expires, for everybody it was sent to, so
    // whatever limits the sender's editor attached do not apply to it.
    media.display_limit_in_milliseconds = None;
    media.requires_authentication = false;
    media.widget_only = None;
    media.quote_message_id = None;
    media.timestamp = posted_at.saturating_mul(1_000);

    media::handle_media(ctx, t, from_user_id, &group_id, media, true).await
}

#[cfg(test)]
mod tests {
    use crate::api::messages::incoming::{handle_encrypted, Delivery};
    use crate::api::proto::client::{encrypted_content, EncryptedContent};
    use crate::context::Context;
    use crate::database::app::tables::Group;
    use crate::error::Result;
    use crate::services::stories::{
        STORY_ANNOUNCE_RECENT_EXCHANGE_SECONDS, STORY_LIFETIME_SECONDS,
    };
    use crate::user_config::UserConfig;
    use std::sync::Arc;

    async fn context(story_notifications: bool) -> Result<(tempfile::TempDir, Arc<Context>)> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        UserConfig::save_json(
            &ctx,
            &format!(
                r#"{{"userId":42,"username":"ben","displayName":"Ben","storyNotifications":{story_notifications}}}"#
            ),
        )?;
        ctx.inject_test_user_id(42).await?;
        let database = ctx.app_db.read().await.clone();
        sqlx::query("INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'anna', 1)")
            .execute(&database.pool)
            .await?;
        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (8, 'stranger')")
            .execute(&database.pool)
            .await?;
        Ok((directory, ctx))
    }

    /// The 1:1 chat with contact 7, last used for a text or media message at
    /// `last_text_or_media_at`.
    async fn chat_with_anna(ctx: &Context, last_text_or_media_at: Option<i64>) -> Result<String> {
        let chat = Group::direct_chat_id(42, 7);
        let database = ctx.app_db.read().await.clone();
        sqlx::query(
            "INSERT INTO groups(group_id, group_name, is_direct_chat, joined_group, last_text_or_media_at) VALUES (?, 'Anna', 1, 1, ?)",
        )
        .bind(&chat)
        .bind(last_text_or_media_at)
        .execute(&database.pool)
        .await?;
        sqlx::query("INSERT INTO group_members(group_id, contact_id) VALUES (?, 7)")
            .bind(&chat)
            .execute(&database.pool)
            .await?;
        Ok(chat)
    }

    fn story(message_id: &str, posted_at: i64, notify: bool) -> EncryptedContent {
        EncryptedContent {
            story: Some(encrypted_content::Story {
                media: Some(encrypted_content::Media {
                    sender_message_id: message_id.into(),
                    r#type: encrypted_content::media::Type::Image as i32,
                    // Whatever the editor had set, a story replays.
                    display_limit_in_milliseconds: Some(5_000),
                    timestamp: posted_at * 1_000,
                    download_token: Some(vec![1; 32]),
                    encryption_key: Some(vec![2; 32]),
                    encryption_mac: Some(vec![3; 16]),
                    encryption_nonce: Some(vec![4; 12]),
                    ..Default::default()
                }),
                notify,
            }),
            ..Default::default()
        }
    }

    async fn receive(
        ctx: &Arc<Context>,
        from: i64,
        receipt_id: &str,
        content: EncryptedContent,
    ) -> Result<Delivery> {
        let database = ctx.app_db.read().await.clone();
        let mut t = database.pool.begin().await?;
        let delivery = handle_encrypted(ctx, &mut t, from, receipt_id, content).await?;
        t.commit().await?;
        Ok(delivery)
    }

    async fn outbox_kinds(ctx: &Context) -> Result<Vec<String>> {
        let database = ctx.app_db.read().await.clone();
        Ok(
            sqlx::query_scalar("SELECT kind FROM notification_outbox ORDER BY event_id")
                .fetch_all(&database.pool)
                .await?,
        )
    }

    #[tokio::test]
    async fn a_story_is_filed_hidden_in_the_direct_chat_and_announced_once() -> Result<()> {
        let (_directory, ctx) = context(true).await?;
        let now = chrono::Utc::now().timestamp();
        chat_with_anna(&ctx, Some(now - 3600)).await?;

        assert_eq!(
            receive(&ctx, 7, "r1", story("s1", now, true)).await?,
            Delivery::Ack
        );
        assert_eq!(
            receive(&ctx, 7, "r2", story("s2", now, false)).await?,
            Delivery::Ack
        );

        let database = ctx.app_db.read().await.clone();
        let rows: Vec<(String, String, i64)> = sqlx::query_as(
            "SELECT message_id, group_id, is_story FROM messages ORDER BY message_id",
        )
        .fetch_all(&database.pool)
        .await?;
        let chat = Group::direct_chat_id(42, 7);
        assert_eq!(
            rows,
            vec![
                ("s1".into(), chat.clone(), 1),
                ("s2".into(), chat.clone(), 1)
            ]
        );
        let limits: Vec<Option<i64>> =
            sqlx::query_scalar("SELECT display_limit_in_milliseconds FROM media_files")
                .fetch_all(&database.pool)
                .await?;
        assert_eq!(limits, vec![None, None]);
        // Not an exchange in the chat: no flames, no media counted.
        let counter: i64 =
            sqlx::query_scalar("SELECT total_media_counter FROM groups WHERE group_id = ?")
                .bind(&chat)
                .fetch_one(&database.pool)
                .await?;
        assert_eq!(counter, 0);
        // Only the item the sender woke this device for is announced.
        assert_eq!(outbox_kinds(&ctx).await?, vec!["story".to_owned()]);
        Ok(())
    }

    #[tokio::test]
    async fn a_muted_receiver_files_the_story_without_announcing_it() -> Result<()> {
        let (_directory, ctx) = context(false).await?;
        let now = chrono::Utc::now().timestamp();
        chat_with_anna(&ctx, Some(now - 3600)).await?;
        assert_eq!(
            receive(&ctx, 7, "r1", story("s1", now, true)).await?,
            Delivery::Ack
        );
        let database = ctx.app_db.read().await.clone();
        let stories: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM messages WHERE is_story = 1")
            .fetch_one(&database.pool)
            .await?;
        assert_eq!(stories, 1);
        assert!(outbox_kinds(&ctx).await?.is_empty());
        Ok(())
    }

    #[tokio::test]
    async fn an_expired_story_is_ignored_without_a_receipt() -> Result<()> {
        let (_directory, ctx) = context(true).await?;
        let late = chrono::Utc::now().timestamp() - STORY_LIFETIME_SECONDS - 60;
        assert_eq!(
            receive(&ctx, 7, "r1", story("s1", late, true)).await?,
            Delivery::Withhold
        );
        let database = ctx.app_db.read().await.clone();
        let messages: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM messages")
            .fetch_one(&database.pool)
            .await?;
        assert_eq!(messages, 0);
        assert!(outbox_kinds(&ctx).await?.is_empty());
        Ok(())
    }

    #[tokio::test]
    async fn a_story_from_someone_not_accepted_is_dropped() -> Result<()> {
        let (_directory, ctx) = context(true).await?;
        let now = chrono::Utc::now().timestamp();
        assert_eq!(
            receive(&ctx, 8, "r1", story("s1", now, true)).await?,
            Delivery::Ack
        );
        let database = ctx.app_db.read().await.clone();
        let messages: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM messages")
            .fetch_one(&database.pool)
            .await?;
        assert_eq!(messages, 0);
        assert!(outbox_kinds(&ctx).await?.is_empty());
        Ok(())
    }

    #[tokio::test]
    async fn a_story_between_people_who_stopped_writing_is_not_announced() -> Result<()> {
        let (_directory, ctx) = context(true).await?;
        let now = chrono::Utc::now().timestamp();
        // They last wrote to each other just over two weeks ago.
        chat_with_anna(
            &ctx,
            Some(now - STORY_ANNOUNCE_RECENT_EXCHANGE_SECONDS - 60),
        )
        .await?;
        assert_eq!(
            receive(&ctx, 7, "r1", story("s1", now, true)).await?,
            Delivery::Ack
        );
        assert!(outbox_kinds(&ctx).await?.is_empty());

        // A text from them counts as writing again, and the next story is
        // announced.
        let text = EncryptedContent {
            group_id: Some(Group::direct_chat_id(42, 7)),
            text_message: Some(encrypted_content::TextMessage {
                sender_message_id: "t1".into(),
                text: "hi".into(),
                timestamp: now * 1_000,
                ..Default::default()
            }),
            ..Default::default()
        };
        receive(&ctx, 7, "r2", text).await?;
        assert_eq!(
            receive(&ctx, 7, "r3", story("s2", now, true)).await?,
            Delivery::Ack
        );
        // Ordered by receipt: the text (r2) came before the story (r3).
        assert_eq!(
            outbox_kinds(&ctx).await?,
            vec!["text".to_owned(), "story".to_owned()]
        );
        Ok(())
    }

    #[tokio::test]
    async fn a_story_does_not_count_as_writing() -> Result<()> {
        let (_directory, ctx) = context(true).await?;
        let now = chrono::Utc::now().timestamp();
        let chat = chat_with_anna(&ctx, None).await?;
        receive(&ctx, 7, "r1", story("s1", now, true)).await?;
        let database = ctx.app_db.read().await.clone();
        let last: Option<i64> =
            sqlx::query_scalar("SELECT last_text_or_media_at FROM groups WHERE group_id = ?")
                .bind(&chat)
                .fetch_one(&database.pool)
                .await?;
        assert_eq!(last, None);
        assert!(outbox_kinds(&ctx).await?.is_empty());
        Ok(())
    }

    #[test]
    fn a_future_timestamp_is_capped_at_arrival() {
        let content = story("s1", 2_000, true);
        assert_eq!(
            super::posted_at(content.story.as_ref().unwrap(), 1_000),
            1_000
        );
    }
}
