/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::messages::queue_encrypted_content;
use crate::api::proto::client::{self as proto, encrypted_content};
use crate::context::Context;
use crate::database::app::tables::Contact;
use crate::error::{twonly_error, Result, TwonlyError};
use crate::user_config::UserConfig;
use crate::user_discovery::UserDiscoveryVersion;
use prost::Message;
use sqlx::{Sqlite, Transaction};
use std::sync::Arc;

pub(crate) async fn check_sender_version(
    ctx: &Context,
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    version: Vec<u8>,
) -> Result<()> {
    if !UserConfig::load_required_from(ctx)?.is_user_discovery_enabled {
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
    ctx: &Arc<Context>,
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
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
        .get_new_messages(from_user_id, &request.current_version, t)
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
    ctx: &Arc<Context>,
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    update: encrypted_content::UserDiscoveryUpdate,
) -> Result<()> {
    if !UserConfig::load_required_from(ctx)?.is_user_discovery_enabled {
        return Ok(());
    }

    if update.messages.iter().any(|message| message.is_empty()) {
        return Err(TwonlyError::Generic(
            "user-discovery update contains an empty message".into(),
        ));
    }

    Ok(ctx
        .user_discovery
        .get()
        .await
        .handle_new_messages(from_user_id, None, update.messages, t)
        .await?)
}
