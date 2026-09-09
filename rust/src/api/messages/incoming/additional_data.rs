/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::{self as proto, encrypted_content};
use crate::context::Context;
use crate::database::app::tables::Group;
use crate::database::app::tables::KeyVerificationType;
use crate::database::app::tables::Message;
use crate::database::app::tables::NewKeyVerification;
use crate::database::app::tables::{MessageType, NewMessage};
use crate::error::Result;
use crate::services::webxdc::WebxdcService;
use crate::utils::milliseconds_to_seconds;
use prost::Message as ProstMessage;
use sqlx::{Sqlite, Transaction};

pub(crate) async fn handle_additional_data_message(
    ctx: &std::sync::Arc<Context>,
    tr: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    group_id: &str,
    message: encrypted_content::AdditionalDataMessage,
) -> Result<()> {
    Message::check_message_owner(tr, &message.sender_message_id, from_user_id).await?;
    let timestamp = milliseconds_to_seconds(message.timestamp);

    // Additional metadata is optional. Keep accepting the containing message if
    // it is malformed or a handler cannot complete.
    let data = match message.additional_message_data.as_deref() {
        Some(bytes) => match proto::AdditionalMessageData::decode(bytes) {
            Ok(data) => Some(data),
            Err(error) => {
                tracing::warn!("failed to decode additional message data: {error}");
                None
            }
        },
        None => None,
    };

    if let Some(data) = data.as_ref() {
        if data.webxdc_sync_request.is_some() {
            let ctx = ctx.clone();
            let group_id = group_id.to_owned();
            tokio::spawn(async move {
                if let Err(error) = WebxdcService::new(&ctx)
                    .send_one_time_apps_to_contact(&group_id, from_user_id)
                    .await
                {
                    tracing::warn!(%error, "could not answer one-time app sync request");
                }
            });
        } else if let Some(sync) = data.webxdc_sync.as_ref() {
            WebxdcService::handle_sync_chunk(tr, group_id, from_user_id, sync).await?;
        } else if let Some(update) = data.webxdc_update.as_ref() {
            // App state belongs in the instance's own log, which is ordered,
            // gap free, and outside the reach of the chat's deletion timer.
            WebxdcService::handle_incoming_update(
                tr,
                &message.sender_message_id,
                group_id,
                from_user_id,
                update,
                timestamp,
            )
            .await?;
        } else if let Err(error) = verify_shared_contacts(ctx, tr, from_user_id, data).await {
            tracing::warn!("failed to handle additional message data: {error}");
        }
    }

    // A hidden message carries state a feature exchanges rather than something
    // a person sent, so it leaves no trace in the chat: no row means it cannot
    // be rendered, quoted, deleted, or swept up by the deletion timer, and the
    // chat's last exchange is left alone so a running app cannot keep a streak
    // alive on its own.
    if message.hidden {
        return Ok(());
    }

    NewMessage::builder()
        .group_id(group_id)
        .message_id(&message.sender_message_id)
        .message_type(MessageType::Other(&message.r#type))
        .created_at(timestamp)
        .sender_id(from_user_id)
        .maybe_additional_message_data(message.additional_message_data.as_deref())
        .ack_by_server(chrono::Utc::now().timestamp())
        .build()
        .insert(tr)
        .await?;

    if let Some(app) = data.as_ref().and_then(|data| data.webxdc_app.as_ref()) {
        // Recorded only once the card exists: the instance is keyed by that
        // message and cascades from it.
        WebxdcService::handle_incoming_app(tr, &message.sender_message_id, group_id, app).await?;
    }

    Group::increase_last_message_exchange(tr, group_id, timestamp).await?;

    Ok(())
}

async fn verify_shared_contacts(
    ctx: &Context,
    tr: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    data: &proto::AdditionalMessageData,
) -> Result<()> {
    if data.r#type != proto::additional_message_data::Type::Contacts as i32 {
        return Ok(());
    }

    let signal_database = ctx.rust_db.read().await.clone();

    for contact in &data.contacts {
        if contact.public_identity_key.is_empty() {
            tracing::info!("shared contact carries no public key, skipping verification");
            continue;
        }

        let stored_identity = sqlx::query_scalar!(
            "SELECT identity_key FROM signal_identities WHERE name = ?",
            contact.user_id.to_string(),
        )
        .fetch_optional(&signal_database.pool)
        .await?;

        let Some(stored_identity) = stored_identity else {
            tracing::info!("no public key stored for contact");
            continue;
        };

        if stored_identity != contact.public_identity_key {
            tracing::warn!("shared contact public identity key does not match");
            continue;
        }

        NewKeyVerification::new(
            contact.user_id,
            KeyVerificationType::ContactSharedByVerified,
        )
        .verified_by(from_user_id)
        .insert(tr)
        .await?;

        let verified_at = chrono::Utc::now().timestamp_millis();
        ctx.user_discovery
            .get()
            .await
            .update_verification_state_for_user(contact.user_id, Some(verified_at), tr)
            .await?;

        tracing::info!("verified a contact from shared additional data");
    }
    Ok(())
}
