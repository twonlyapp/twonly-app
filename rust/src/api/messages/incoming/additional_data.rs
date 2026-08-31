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
use crate::utils::milliseconds_to_seconds;
use prost::Message as ProstMessage;
use sqlx::{Sqlite, Transaction};

pub(crate) async fn handle_additional_data_message(
    ctx: &Context,
    tr: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    group_id: &str,
    message: encrypted_content::AdditionalDataMessage,
) -> Result<()> {
    Message::check_message_owner(tr, &message.sender_message_id, from_user_id).await?;
    let timestamp = milliseconds_to_seconds(message.timestamp);

    if let Some(data) = message.additional_message_data.as_deref() {
        // Additional metadata is optional. Keep accepting the containing
        // message if it is malformed or contact verification cannot complete.
        if let Err(error) = verify_shared_contacts(ctx, tr, from_user_id, data).await {
            tracing::warn!("failed to handle additional message data: {error}");
        }
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

    Group::increase_last_message_exchange(tr, group_id, timestamp).await?;

    Ok(())
}

async fn verify_shared_contacts(
    ctx: &Context,
    tr: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    bytes: &[u8],
) -> Result<()> {
    let data = proto::AdditionalMessageData::decode(bytes)?;

    if data.r#type != proto::additional_message_data::Type::Contacts as i32 {
        return Ok(());
    }

    let signal_database = ctx.rust_db.read().await.clone();

    for contact in data.contacts {
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
