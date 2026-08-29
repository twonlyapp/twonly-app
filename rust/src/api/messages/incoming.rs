/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

mod additional_data;
pub(crate) mod contact;
mod errors;
mod groups;
mod media;
pub mod messages;
mod reaction;
pub mod recovery;
mod text_message;
mod typing_indicator;
mod user_discovery;
mod verification;

use crate::api::messages::content_type_kind;
use crate::api::messages::incoming::messages::{
    ensure_contact_exists, handle_plaintext_content, handle_sender_delivery_receipt,
    process_encrypted_or_queue_error, queue_decryption_error, queue_sender_delivery_receipt,
    retransmit_queued_receipts, spawn_receipt_delivery,
};
use crate::api::proto::client as proto;
use crate::api::proto::server_to_client::NewMessage;
use crate::api::proto::{client_to_server, server_to_client};
use crate::context::Context;
use crate::database::app::tables::{Contact, Group, Receipt};
use crate::error::{Result, TwonlyError};
use crate::sealed_sender::SealedSender;
use crate::services::contacts::ContactService;
use client_to_server::response::{ok, Response};
use prost::Message as _;
use proto::message::Type;
use server_to_client::v0::Kind;
use sqlx::{Sqlite, Transaction};
use std::sync::Arc;

pub(crate) async fn handle_server_message(
    ctx: &Arc<Context>,
    kind: server_to_client::v0::Kind,
) -> Result<client_to_server::Response> {
    let ok = match kind {
        Kind::RequestNewPqcPreKeys(_) => match handle_request_new_pqc_prekeys(ctx).await {
            Ok(response) => response,
            Err(error) => {
                tracing::warn!("failed to generate requested PQC prekeys: {error}");
                ok::Ok::None(true)
            }
        },
        Kind::NewMessage(message) => {
            if let Err(error) = handle_new_server_message(ctx, message).await {
                tracing::warn!("failed to process client message: {error}");
            }
            ok::Ok::None(true)
        }
        Kind::NewMessages(messages) => {
            for message in messages.new_messages {
                if let Err(error) = handle_new_server_message(ctx, message).await {
                    // One bad item must not block the rest of a server batch.
                    tracing::warn!("failed to process client message in batch: {error}");
                }
            }
            ok::Ok::None(true)
        }
        Kind::PendingMessagesV2(batch) => {
            return Ok(acknowledge_pending_messages(ctx, batch).await);
        }
        Kind::SealedSenderMessage(message) => {
            if let Err(error) = handle_sealed_message(ctx, message.body).await {
                tracing::warn!("failed to process sealed-sender message: {error}");
            }
            ok::Ok::None(true)
        }
        Kind::SealedSenderMessages(messages) => {
            for message in messages.messages {
                if let Err(error) = handle_sealed_message(ctx, message.body).await {
                    tracing::warn!("failed to process sealed-sender message in batch: {error}");
                }
            }
            ok::Ok::None(true)
        }
        Kind::MailboxDrained(_) => {
            ctx.mark_mailbox_drained();
            ok::Ok::None(true)
        }
        other => {
            // Dart logged unknown unsolicited messages but still acknowledged
            // their envelope, preventing an infinite server redelivery loop.
            tracing::warn!("unsupported unsolicited server message: {other:?}");
            ok::Ok::None(true)
        }
    };

    Ok(client_to_server::Response {
        response: Some(Response::Ok(client_to_server::response::Ok {
            ok: Some(ok),
        })),
    })
}

/// Processes a reliable-mailbox batch and reports back exactly which delivery
/// IDs are now durable locally. The server deletes only those rows, so anything
/// left out is redelivered on the next drain.
///
/// Deduplication is the `received_receipts` claim inside
/// [`handle_decoded_server_message`]: it is committed in the same transaction
/// that persists the message, is keyed on the end-to-end receipt ID, and is
/// never purged. A redelivered envelope is therefore recognised before it is
/// decrypted, whichever transport carried it.
async fn acknowledge_pending_messages(
    ctx: &Arc<Context>,
    batch: server_to_client::PendingMessagesV2,
) -> client_to_server::Response {
    let mut delivery_ids = Vec::with_capacity(batch.messages.len());

    for message in batch.messages {
        let delivery_id = message.delivery_id;
        let result = handle_new_server_message(
            ctx,
            NewMessage {
                from_user_id: message.from_user_id,
                body: message.body,
            },
        )
        .await;

        match result {
            // Committed, or recognised as a duplicate. Either way it is durable.
            Ok(()) => delivery_ids.push(delivery_id),
            // An envelope that cannot be decoded will never decode. Acknowledge
            // it so one poisoned row cannot be redelivered forever.
            Err(
                error @ (TwonlyError::ProtobufDecode(_) | TwonlyError::UnknownProtobufEnumValue(_)),
            ) => {
                tracing::warn!(
                    delivery_id,
                    "dropping an undecodable mailbox message: {error}"
                );
                delivery_ids.push(delivery_id);
            }
            // Anything else (storage, network, Signal state) may succeed later.
            // Leaving the ID out keeps the row on the server for a retry.
            Err(error) => {
                tracing::warn!(
                    delivery_id,
                    "mailbox message not persisted, will retry: {error}"
                );
            }
        }
    }

    client_to_server::Response {
        response: Some(Response::Ok(client_to_server::response::Ok {
            ok: Some(ok::Ok::AcknowledgedPendingMessages(
                client_to_server::response::AcknowledgedPendingMessages { delivery_ids },
            )),
        })),
    }
}

pub(crate) async fn handle_new_server_message(
    ctx: &Arc<Context>,
    server_message: NewMessage,
) -> Result<()> {
    let message = proto::Message::decode(server_message.body.as_slice())?;
    handle_decoded_server_message(ctx, server_message.from_user_id, message).await
}

pub(crate) async fn handle_sealed_message(ctx: &Arc<Context>, bytes: Vec<u8>) -> Result<()> {
    let payload = SealedSender::decrypt(&bytes, ctx.as_ref()).await?;

    let message = payload
        .message
        .ok_or_else(|| TwonlyError::Generic("sealed message contains no client message".into()))?;

    handle_decoded_server_message(ctx, payload.from_user_id, message).await
}

pub(crate) async fn handle_request_new_pqc_prekeys(
    ctx: &Arc<Context>,
) -> Result<client_to_server::response::ok::Ok> {
    let engine = ctx.signal_engine.lock().await;

    let prekeys = engine
        .as_ref()
        .ok_or(TwonlyError::SignalIdentityNotFound)?
        .generate_pqc_prekeys()
        .await?
        .into_iter()
        .map(|key| client_to_server::application_data::PqcPreKey {
            ecc_pre_key_id: i64::from(key.ecc_pre_key_id),
            ecc_pre_key: key.ecc_pre_key,
            kyber_pre_key_id: i64::from(key.kyber_pre_key_id),
            kyber_pre_key: key.kyber_pre_key,
            kyber_pre_key_signature: key.kyber_pre_key_signature,
        })
        .collect();

    Ok(client_to_server::response::ok::Ok::PrekeysPqc(
        client_to_server::response::PqcPrekeys { prekeys },
    ))
}

#[tracing::instrument(
    skip_all,
    fields(
        receipt_id = tracing::field::Empty,
        user = tracing::field::Empty,
        kind = tracing::field::Empty
    )
)]
pub(crate) async fn handle_decoded_server_message(
    ctx: &Arc<Context>,
    from_user_id: i64,
    message: proto::Message,
) -> Result<()> {
    tracing::Span::current().record("receipt_id", &message.receipt_id);
    if let Ok(user) = ctx.user_id().await {
        tracing::Span::current().record("user", user);
    }
    tracing::info!("Started processing incoming message");

    if message.receipt_id.is_empty() {
        return Err(TwonlyError::Generic(
            "client message has no receipt ID".into(),
        ));
    }

    let message_type = Type::try_from(message.r#type)?;
    let is_encrypted_message = matches!(
        message_type,
        Type::Ciphertext | Type::PrekeyBundle | Type::CiphertextV2
    );
    tracing::info!(is_encrypted_message, ?message_type, "Parsed message type");

    if is_encrypted_message {
        tracing::info!("Ensuring contact exists...");
        ensure_contact_exists(ctx, from_user_id).await?;
    }

    let database = ctx.app_db.read().await.clone();

    let mut t = database.pool.begin().await?;

    let claimed = Receipt::claim_received(&mut t, &message.receipt_id).await?;

    if !claimed {
        // Delivery receipts are terminal messages and must never themselves be
        // acknowledged. For regular messages Dart retries the delivery receipt
        // after ten days, atomically claiming the retry by moving created_at.
        let should_resend = message_type != Type::SenderDeliveryReceipt
            && Receipt::claim_received_retry(&mut t, &message.receipt_id).await?;

        if should_resend {
            tracing::info!("Queueing sender delivery receipt for retry");
            queue_sender_delivery_receipt(&mut t, from_user_id, &message.receipt_id).await?;
        }

        t.commit().await?;

        if should_resend {
            tracing::info!("Spawning receipt delivery for retry");
            spawn_receipt_delivery(ctx, message.receipt_id);
        }

        tracing::info!("Returning early because receipt was already claimed");
        return Ok(());
    }

    let mut sends_error_response = false;

    match message_type {
        Type::SenderDeliveryReceipt => {
            tracing::info!("Received sender delivery receipt");
            handle_sender_delivery_receipt(&mut t, from_user_id, &message.receipt_id).await?;
        }
        Type::Ciphertext | Type::PrekeyBundle => {
            tracing::info!("Received legacy signal message; rejecting and upgrading session to v2");

            let has_v2_session = {
                let rust_database = ctx.rust_db.read().await.clone();
                sqlx::query_scalar!(
                    "SELECT EXISTS(SELECT 1 FROM signal_sessions WHERE name = ? AND device_id = 1)",
                    from_user_id.to_string(),
                )
                .fetch_one(&rust_database.pool)
                .await?
                    != 0
            };

            let is_v2_contact = {
                let contact = Contact::get_contact_by_id(&mut t, from_user_id).await?;
                contact.as_ref().is_some_and(|c| c.signal_version == "v2")
            };

            if !has_v2_session || !is_v2_contact {
                if let Err(error) = ContactService::new(ctx)
                    .establish_signal_session(from_user_id, None)
                    .await
                {
                    tracing::warn!(
                        from_user_id,
                        "failed to establish v2 signal session from server: {error}"
                    );
                }
                sqlx::query!(
                    "UPDATE contacts SET signal_version = 'v2' WHERE user_id = ?",
                    from_user_id,
                )
                .execute(&mut *t)
                .await?;
            }

            queue_decryption_error(&mut t, from_user_id, &message.receipt_id, 0).await?;
            sends_error_response = true;
        }
        Type::CiphertextV2 => {
            let ciphertext = message.encrypted_content.ok_or_else(|| {
                TwonlyError::Generic("V2 encrypted client message has no ciphertext".into())
            })?;
            let decrypted = {
                let engine = ctx.signal_engine.lock().await;
                engine
                    .as_ref()
                    .ok_or(TwonlyError::SignalIdentityNotFound)?
                    .decrypt_message(from_user_id.to_string(), 1, ciphertext)
                    .await
            };
            match decrypted {
                Ok(plaintext) => {
                    let content =
                        proto::EncryptedContent::decode(plaintext.as_slice()).map_err(|error| {
                            TwonlyError::Generic(format!(
                                "invalid decrypted client content: {error}"
                            ))
                        })?;
                    sends_error_response = process_encrypted_or_queue_error(
                        ctx,
                        &mut t,
                        from_user_id,
                        &message.receipt_id,
                        content,
                    )
                    .await?
                    .is_some();
                }
                Err(error) => {
                    tracing::warn!(
                        receipt_id = message.receipt_id,
                        "V2 decryption failed: {error}"
                    );
                    queue_decryption_error(&mut t, from_user_id, &message.receipt_id, 0).await?;
                    sends_error_response = true;
                }
            }
        }
        Type::PlaintextContent => {
            tracing::info!("Handling plaintext content");
            let plaintext = message.plaintext_content.ok_or_else(|| {
                TwonlyError::Generic("plaintext client message has no content".into())
            })?;
            handle_plaintext_content(ctx, &mut t, from_user_id, &message.receipt_id, plaintext)
                .await?;
        }
        Type::TestNotification => {}
    }

    if is_encrypted_message & !sends_error_response {
        queue_sender_delivery_receipt(&mut t, from_user_id, &message.receipt_id).await?;
    }

    t.commit().await?;
    ctx.mark_incoming_committed();

    database.notify_committed([
        "received_receipts",
        "receipts",
        "messages",
        "groups",
        "contacts",
        "key_verifications",
        "user_discovery_own_promotions",
        "notification_outbox",
    ]);

    let ctx = ctx.clone();
    tokio::spawn(async move {
        if let Err(error) = retransmit_queued_receipts(&ctx).await {
            tracing::warn!("failed to flush messages queued during inbound handling: {error}");
        }
    });

    Ok(())
}

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
    let notification_content = content.clone();
    handle_encrypted_inner(ctx, t, from_user_id, receipt_id, content).await?;
    crate::services::notifications::record_incoming_event(
        t,
        from_user_id,
        receipt_id,
        &notification_content,
    )
    .await
}

async fn handle_encrypted_inner(
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
        return typing_indicator::handle_typing_indicator(t, from_user_id, &group_id, indicator)
            .await;
    }

    Err(TwonlyError::Generic(format!(
        "client2client content in receipt {receipt_id} is not implemented in Rust"
    )))
}
