/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::messages::content_type_kind;
use crate::api::proto::client as proto;
use crate::context::Context;
use crate::database::app::tables::{Contact, Group, Receipt};
use crate::error::{Result, TwonlyError};
use sqlx::{Sqlite, Transaction};
use std::sync::Arc;
use typing_indicator::handle_typing_indicator;

mod additional_data;
pub(crate) mod contact;
mod errors;
mod groups;
mod media;
pub mod messages;
mod reaction;
pub(crate) mod recovery;
mod text_message;
mod typing_indicator;
mod user_discovery;
mod verification;

/// Dispatches already-decrypted client-to-client content to its concrete
/// feature module. Transport decoding and Signal decryption do not belong in
/// this dispatcher.
pub(crate) async fn handle_encrypted(
    ctx: &Arc<Context>,
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    receipt_id: &str,
    content: proto::EncryptedContent,
) -> Result<()> {
    Receipt::mark_all_for_retry(t, from_user_id).await?;

    if let Some(version) = content.sender_user_discovery_version.clone() {
        user_discovery::check_sender_version(ctx, t, from_user_id, version).await?;
    }

    contact::check_for_profile_update(t, from_user_id, &content).await?;

    if content.ask_for_friend_promotions == Some(true) {
        Contact::update_ask_for_friend_promotions(t, from_user_id).await?;
    }

    let type_kind = content_type_kind(&content);

    tracing::Span::current().record("kind", type_kind);
    tracing::info!("Handling incoming message: {type_kind}");

    if let Some(request) = content.contact_request {
        return contact::handle_contact_request(ctx, t, from_user_id, request).await;
    }

    if let Some(update) = content.contact_update {
        return contact::handle_contact_update(
            ctx,
            t,
            from_user_id,
            content.sender_profile_counter,
            update,
        )
        .await;
    }

    if let Some(update) = content.message_update {
        return text_message::handle_message_update(ctx, t, from_user_id, update).await;
    }

    if let Some(update) = content.media_update {
        return media::handle_media_update(t, from_user_id, update).await;
    }

    if let Some(error) = content.error_messages {
        return errors::handle_error_message(
            ctx,
            t,
            from_user_id,
            content.group_id.as_deref(),
            error,
        )
        .await;
    }

    if let Some(update) = content.user_discovery_update {
        return user_discovery::handle_user_discovery_update(ctx, t, from_user_id, update).await;
    }

    if let Some(request) = content.user_discovery_request {
        return user_discovery::handle_user_discovery_request(ctx, t, from_user_id, request).await;
    }

    if let Some(proof) = content.key_verification_proof {
        return verification::handle_key_verification_proof(t, from_user_id, proof).await;
    }

    if let Some(recovery) = content.passwordless_recovery {
        return recovery::handle_passwordless_recovery(t, from_user_id, recovery).await;
    }

    if let Some(heartbeat) = content.passwordless_recovery_heartbeat {
        return recovery::handle_passwordless_recovery_heartbeat(t, from_user_id, heartbeat).await;
    }

    let group_id = content
        .group_id
        .ok_or_else(|| TwonlyError::Generic("group-scoped message has no group ID".into()))?;

    if let Some(create) = content.group_create {
        return groups::handle_group_create(ctx, t, from_user_id, &group_id, create).await;
    }

    if let Some(join) = content.group_join {
        return groups::handle_group_join(t, from_user_id, &group_id, join).await;
    }

    let is_member = sqlx::query_scalar!(
        "SELECT EXISTS(SELECT 1 FROM group_members WHERE group_id = ? AND contact_id = ?)",
        group_id,
        from_user_id,
    )
    .fetch_one(&mut **t)
    .await?
        != 0;

    if !is_member {
        let local_user_id = ctx.user_id().await?;

        if Group::direct_chat_id(local_user_id, from_user_id) == group_id {
            let contact = Contact::get_contact_by_id(t, from_user_id).await?;

            if let Some(contact) =
                contact.filter(|value| value.accepted != 0 && value.deleted_by_user == 0)
            {
                Group::create_direct_chat(ctx, t, contact).await?;
            } else {
                sqlx::query!(
                    "UPDATE contacts SET requested = 1, deleted_by_user = 0 WHERE user_id = ?",
                    from_user_id,
                )
                .execute(&mut **t)
                .await?;
                messages::queue_encrypted_content(
                    t,
                    from_user_id,
                    proto::EncryptedContent {
                        error_messages: Some(proto::encrypted_content::ErrorMessages {
                            r#type: proto::encrypted_content::error_messages::Type::ErrorProcessingMessageCreatedAccountRequestInstead as i32,
                            related_receipt_id: receipt_id.to_owned(),
                        }),
                        ..Default::default()
                    },
                    false,
                )
                .await?;
                return Ok(());
            }
        }
    }

    groups::ensure_group_member(t, from_user_id, &group_id).await?;

    if content.resend_group_public_key.is_some() {
        return groups::handle_resend_group_public_key(t, from_user_id, &group_id).await;
    }

    if let Some(update) = content.group_update {
        return groups::handle_group_update(ctx, t, from_user_id, &group_id, update).await;
    }

    if let Some(flame) = content.flame_sync {
        return groups::handle_flame_sync(t, &group_id, flame).await;
    }

    if let Some(message) = content.text_message {
        return text_message::handle_text_message(t, from_user_id, &group_id, message).await;
    }

    if let Some(message) = content.additional_data_message {
        return additional_data::handle_additional_data_message(
            ctx,
            t,
            from_user_id,
            &group_id,
            message,
        )
        .await;
    }

    if let Some(media) = content.media {
        return media::handle_media(t, from_user_id, &group_id, media).await;
    }

    if let Some(reaction) = content.reaction {
        return reaction::handle_reaction(t, from_user_id, &group_id, reaction).await;
    }

    if let Some(indicator) = content.typing_indicator {
        return handle_typing_indicator(t, from_user_id, &group_id, indicator).await;
    }

    Err(TwonlyError::Generic(format!(
        "client2client content in receipt {receipt_id} is not implemented in Rust"
    )))
}
