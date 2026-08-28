/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

pub(crate) mod client2client;

use crate::api::messages::incoming::client2client::messages::{
    decrypt_legacy_signal_with_error, ensure_contact_exists, handle_plaintext_content,
    handle_sender_delivery_receipt, process_encrypted_or_queue_error, queue_decryption_error,
    queue_sender_delivery_receipt, retransmit_queued_receipts, spawn_receipt_delivery,
};
use crate::api::proto::client as proto;
use crate::api::proto::server_to_client::NewMessage;
use crate::api::proto::{client_to_server, server_to_client};
use crate::bridge::callbacks::get_callbacks;
use crate::context::Context;
use crate::database::app::tables::Receipt;
use crate::error::{Result, TwonlyError};
use crate::sealed_sender::SealedSender;
use client_to_server::response::{ok, Response};
use prost::Message as _;
use proto::message::Type;
use server_to_client::v0::Kind;
use std::sync::Arc;

pub(crate) async fn handle_server_message(
    ctx: &Arc<Context>,
    kind: server_to_client::v0::Kind,
) -> Result<client_to_server::Response> {
    let ok = match kind {
        // These booleans are presence-only request markers. Their value is not part of
        // the protocol; the Dart client likewise checks hasRequestNewPreKeys() only.
        Kind::RequestNewPreKeys(_) => match handle_request_new_prekeys(ctx).await {
            Ok(response) => response,
            Err(error) => {
                tracing::error!("failed to generate requested prekeys: {error}");
                ok::Ok::None(true)
            }
        },
        Kind::RequestNewPqcPreKeys(_) => match handle_request_new_pqc_prekeys(ctx).await {
            Ok(response) => response,
            Err(error) => {
                tracing::error!("failed to generate requested PQC prekeys: {error}");
                ok::Ok::None(true)
            }
        },
        Kind::NewMessage(message) => {
            if let Err(error) = handle_new_server_message(ctx, message).await {
                tracing::error!("failed to process client message: {error}");
            }
            ok::Ok::None(true)
        }
        Kind::NewMessages(messages) => {
            for message in messages.new_messages {
                if let Err(error) = handle_new_server_message(ctx, message).await {
                    // One bad item must not block the rest of a server batch.
                    tracing::error!("failed to process client message in batch: {error}");
                }
            }
            ok::Ok::None(true)
        }
        Kind::SealedSenderMessage(message) => {
            if let Err(error) = handle_sealed_message(ctx, message.body).await {
                tracing::error!("failed to process sealed-sender message: {error}");
            }
            ok::Ok::None(true)
        }
        Kind::SealedSenderMessages(messages) => {
            for message in messages.messages {
                if let Err(error) = handle_sealed_message(ctx, message.body).await {
                    tracing::error!("failed to process sealed-sender message in batch: {error}");
                }
            }
            ok::Ok::None(true)
        }
        other => {
            // Dart logged unknown unsolicited messages but still acknowledged
            // their envelope, preventing an infinite server redelivery loop.
            tracing::error!("unsupported unsolicited server message: {other:?}");
            ok::Ok::None(true)
        }
    };

    Ok(client_to_server::Response {
        response: Some(Response::Ok(client_to_server::response::Ok {
            ok: Some(ok),
        })),
    })
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

pub(crate) async fn handle_request_new_prekeys(
    ctx: &Arc<Context>,
) -> Result<client_to_server::response::ok::Ok> {
    let prekeys = match get_callbacks() {
        Ok(callbacks) => (callbacks.legacy_signal.generate_prekeys)()
            .await
            .into_iter()
            .map(|key| client_to_server::response::PreKey {
                id: key.id,
                prekey: key.public_key,
            })
            .collect(),
        Err(TwonlyError::MissingCallbackInitialization) => {
            let engine = ctx.get_signal_engine().lock().await;
            engine
                .as_ref()
                .ok_or(TwonlyError::SignalIdentityNotFound)?
                .generate_prekeys(200)
                .await?
                .into_iter()
                .map(|(id, public_key)| client_to_server::response::PreKey {
                    id: i64::from(id),
                    prekey: public_key,
                })
                .collect()
        }
        Err(error) => return Err(error),
    };

    Ok(client_to_server::response::ok::Ok::Prekeys(
        client_to_server::response::Prekeys { prekeys },
    ))
}

pub(crate) async fn handle_request_new_pqc_prekeys(
    ctx: &Arc<Context>,
) -> Result<client_to_server::response::ok::Ok> {
    let engine = ctx.get_signal_engine().lock().await;

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

    let database = ctx.get_app_database().await;

    let mut tr = database.pool.begin().await?;

    let claimed = Receipt::claim_received(&mut tr, &message.receipt_id).await?;

    if !claimed {
        // Delivery receipts are terminal messages and must never themselves be
        // acknowledged. For regular messages Dart retries the delivery receipt
        // after ten days, atomically claiming the retry by moving created_at.
        let should_resend = message_type != Type::SenderDeliveryReceipt
            && Receipt::claim_received_retry(&mut tr, &message.receipt_id).await?;
        if should_resend {
            tracing::info!("Queueing sender delivery receipt for retry");
            queue_sender_delivery_receipt(&mut tr, from_user_id, &message.receipt_id).await?;
        }
        tr.commit().await?;
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
            handle_sender_delivery_receipt(&mut tr, from_user_id, &message.receipt_id).await?;
        }
        Type::Ciphertext | Type::PrekeyBundle => {
            let ciphertext = message.encrypted_content.ok_or_else(|| {
                TwonlyError::Generic("legacy encrypted client message has no ciphertext".into())
            })?;
            tracing::info!("Decrypting legacy signal message...");
            match decrypt_legacy_signal_with_error(from_user_id, ciphertext, message.r#type).await?
            {
                Ok(content) => {
                    tracing::info!("Decrypted successfully, processing...");
                    sends_error_response = process_encrypted_or_queue_error(
                        ctx,
                        &mut tr,
                        from_user_id,
                        &message.receipt_id,
                        content,
                    )
                    .await?
                    .is_some();
                }
                Err(error_type) => {
                    tracing::info!(error_type, "Decryption error");
                    if error_type
                        == proto::plaintext_content::decryption_error_message::Type::PrekeyUnknown
                            as i32
                    {
                        if let Ok(callbacks) = get_callbacks() {
                            (callbacks.api.resync_signal_session)(from_user_id).await;
                        }
                    }
                    queue_decryption_error(&mut tr, from_user_id, &message.receipt_id, error_type)
                        .await?;
                    sends_error_response = true;
                }
            }
        }
        Type::CiphertextV2 => {
            let ciphertext = message.encrypted_content.ok_or_else(|| {
                TwonlyError::Generic("V2 encrypted client message has no ciphertext".into())
            })?;
            let decrypted = {
                let engine = ctx.get_signal_engine().lock().await;
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
                        &mut tr,
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
                    queue_decryption_error(&mut tr, from_user_id, &message.receipt_id, 0).await?;
                    sends_error_response = true;
                }
            }
        }
        Type::PlaintextContent => {
            tracing::info!("Handling plaintext content");
            let plaintext = message.plaintext_content.ok_or_else(|| {
                TwonlyError::Generic("plaintext client message has no content".into())
            })?;
            handle_plaintext_content(ctx, &mut tr, from_user_id, &message.receipt_id, plaintext)
                .await?;
        }
        Type::TestNotification => {}
    }

    if is_encrypted_message && !sends_error_response {
        queue_sender_delivery_receipt(&mut tr, from_user_id, &message.receipt_id).await?;
    }

    tr.commit().await?;

    database.notify_committed([
        "received_receipts",
        "receipts",
        "messages",
        "groups",
        "contacts",
        "key_verifications",
        "user_discovery_own_promotions",
    ]);

    let ctx = ctx.clone();
    tokio::spawn(async move {
        if let Err(error) = retransmit_queued_receipts(&ctx).await {
            tracing::warn!("failed to flush messages queued during inbound handling: {error}");
        }
    });

    Ok(())
}
