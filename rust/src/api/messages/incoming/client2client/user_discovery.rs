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
use sqlx::{Sqlite, Transaction};
use std::collections::HashSet;
use std::sync::LazyLock;
use tokio::sync::Mutex;

static REQUESTED_UPDATES: LazyLock<Mutex<HashSet<i64>>> =
    LazyLock::new(|| Mutex::new(HashSet::new()));

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

    let Some(current_version) = ctx
        .get_user_discovery()
        .get()
        .await
        .should_request_new_messages(from_user_id, &version)
        .await?
    else {
        return Ok(());
    };

    if !REQUESTED_UPDATES.lock().await.insert(from_user_id) {
        return Ok(());
    }

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
    ctx: &Context,
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
        .get_user_discovery()
        .get()
        .await
        .get_new_messages(from_user_id, &request.current_version)
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
    ctx: &Context,
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
        .get_user_discovery()
        .get()
        .await
        .handle_new_messages(from_user_id, None, update.messages)
        .await?)
}
