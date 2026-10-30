/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::messages::queue_encrypted_content;
use crate::api::proto::client::{self as proto, encrypted_content};
use crate::context::Context;
use crate::database::app::contacts::table::Contact;
use crate::error::{twonly_error, Result, TwonlyError};
use crate::user_config::UserConfig;
use crate::user_discovery::UserDiscoveryVersion;
use prost::Message;
use sqlx::{Sqlite, Transaction};
use std::sync::Arc;

pub(crate) async fn check_sender_version(
    ctx: &Context, t: &mut Transaction<'_, Sqlite>, from_user_id: i64, version: Vec<u8>,
) -> Result<()> {
    // Asking is what makes them send their updates, which are only taken
    // from contacts we would share ours with.
    if !UserConfig::load_required_from(ctx)?.is_user_discovery_enabled
        || !Contact::is_user_discovery_allowed(ctx, t, from_user_id).await?
    {
        return Ok(());
    }

    if version.len() > 64 {
        return Err(twonly_error!(
            "sender user-discovery version is unexpectedly large"
        ));
    }

    // The inbound message transaction owns the app database's sole connection.
    // Going through `UserDiscovery::should_request_new_messages` here would ask
    // the native store to acquire that same connection and deadlock until the
    // pool's 30-second acquire timeout expires.
    let received_version = UserDiscoveryVersion::decode(version.as_slice())?;

    let stored_version = sqlx::query_scalar!(
        "SELECT user_discovery_version FROM contacts WHERE user_id = ?",
        from_user_id,
    )
    .fetch_optional(&mut **t)
    .await?
    .flatten()
    .map(|version| UserDiscoveryVersion::decode(version.as_slice()))
    .transpose()?
    .unwrap_or_default();

    if received_version.announcement <= stored_version.announcement
        && received_version.promotion <= stored_version.promotion
    {
        return Ok(());
    }

    let current_version = stored_version.encode_to_vec();

    queue_encrypted_content(
        t,
        from_user_id,
        proto::EncryptedContent {
            user_discovery_request: Some(encrypted_content::UserDiscoveryRequest {
                current_version,
            }),
            ..Default::default()
        },
        true,
    )
    .await?;

    Ok(())
}

pub(crate) async fn handle_user_discovery_request(
    ctx: &Arc<Context>, t: &mut Transaction<'_, Sqlite>, from_user_id: i64,
    request: encrypted_content::UserDiscoveryRequest,
) -> Result<()> {
    if !UserConfig::load_required_from(ctx)?.is_user_discovery_enabled
        || !Contact::is_user_discovery_allowed(ctx, t, from_user_id).await?
    {
        return Ok(());
    }

    if request.current_version.len() > 64 {
        return Err(TwonlyError::Generic(
            "user-discovery version is unexpectedly large".into(),
        ));
    }

    let messages = ctx
        .user_discovery
        .get()
        .await
        .get_new_messages(ctx, from_user_id, &request.current_version, t)
        .await?;

    if !messages.is_empty() {
        queue_encrypted_content(
            t,
            from_user_id,
            proto::EncryptedContent {
                user_discovery_update: Some(encrypted_content::UserDiscoveryUpdate { messages }),
                ..Default::default()
            },
            true,
        )
        .await?;
    }

    Ok(())
}

pub(crate) async fn handle_user_discovery_update(
    ctx: &Arc<Context>, t: &mut Transaction<'_, Sqlite>, from_user_id: i64,
    update: encrypted_content::UserDiscoveryUpdate,
) -> Result<()> {
    // Taking someone's announcement means promoting them to our friends, so
    // it takes the same standing as receiving ours. Anything they missed in
    // the meantime they get once they have it: their version keeps arriving
    // with every message, and `check_sender_version` asks for it then.
    if !UserConfig::load_required_from(ctx)?.is_user_discovery_enabled
        || !Contact::is_user_discovery_allowed(ctx, t, from_user_id).await?
    {
        return Ok(());
    }

    if update.messages.iter().any(|message| message.is_empty()) {
        return Err(TwonlyError::Generic(
            "user-discovery update contains an empty message".into(),
        ));
    }

    ctx.user_discovery
        .get()
        .await
        .handle_new_messages(from_user_id, None, update.messages, t)
        .await
}

#[cfg(test)]
mod tests {

    use super::*;
    use crate::user_discovery::user_discovery_message::UserDiscoveryPromotion;
    use crate::user_discovery::UserDiscoveryMessage;

    /// Discovery data is exchanged only with contacts we would share ours
    /// with: anyone else is neither asked for theirs nor listened to.
    #[tokio::test]
    async fn discovery_is_only_exchanged_with_allowed_contacts() -> anyhow::Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        crate::api::ApiRuntime::close(&ctx).await?;
        UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"me","displayName":"Me","isUserDiscoveryEnabled":true}"#,
        )?;
        let database = ctx.app_db.read().await.clone();
        sqlx::query(
            "INSERT INTO contacts(user_id, username, accepted, blocked, media_send_counter) VALUES \
             (7, 'stranger', 0, 0, 0), (8, 'blocked', 1, 1, 4), (9, 'friend', 1, 0, 4)",
        )
        .execute(&database.pool)
        .await?;

        let version = UserDiscoveryVersion {
            announcement: 1,
            promotion: 1,
        };
        let promotion = UserDiscoveryMessage {
            version: Some(version.clone()),
            user_discovery_promotion: Some(UserDiscoveryPromotion {
                public_id: 1234,
                threshold: 3,
                announcement_share: vec![1, 2, 3],
                ..Default::default()
            }),
            ..Default::default()
        };

        for user_id in [7, 8, 9] {
            let mut t = database.pool.begin().await?;
            check_sender_version(&ctx, &mut t, user_id, version.encode_to_vec()).await?;
            handle_user_discovery_update(
                &ctx,
                &mut t,
                user_id,
                encrypted_content::UserDiscoveryUpdate {
                    messages: vec![promotion.encode_to_vec()],
                },
            )
            .await?;
            t.commit().await?;
        }

        let asked: Vec<i64> = sqlx::query_scalar("SELECT contact_id FROM receipts")
            .fetch_all(&database.pool)
            .await?;
        assert_eq!(asked, vec![9]);

        let listened_to: Vec<i64> =
            sqlx::query_scalar("SELECT from_contact_id FROM user_discovery_other_promotions")
                .fetch_all(&database.pool)
                .await?;
        assert_eq!(listened_to, vec![9]);

        let versions: Vec<i64> = sqlx::query_scalar(
            "SELECT user_id FROM contacts WHERE user_discovery_version IS NOT NULL",
        )
        .fetch_all(&database.pool)
        .await?;
        assert_eq!(versions, vec![9]);

        Ok(())
    }
}
