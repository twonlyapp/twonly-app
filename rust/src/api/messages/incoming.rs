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
    release_deferred_receipts, retransmit_queued_receipts, spawn_receipt_delivery,
};
use crate::api::proto::client as proto;
use crate::api::proto::server_to_client::NewMessage;
use crate::api::proto::{client_to_server, server_to_client};
use crate::context::Context;
use crate::database::app::tables::{Contact, Group, Receipt};
use crate::error::{Result, TwonlyError};
use crate::services::contacts::ContactService;
use crate::services::groups::GroupService;
use crate::signal::reset::SessionResetLimiter;
use client_to_server::response::{ok, Response};
use prost::Message as _;
use proto::message::Type;
use proto::plaintext_content::decryption_error_message::Type as DecryptionErrorType;
use server_to_client::v0::Kind;
use sqlx::{Sqlite, Transaction};
use std::collections::HashMap;
use std::sync::{Arc, LazyLock, Mutex, PoisonError, Weak};

/// Serialises the handling of one receipt ID against itself.
///
/// The server resends a mailbox page whose acknowledgement timed out, so a
/// message can arrive again while the first copy is still being handled. Both
/// copies would open their own transaction on the single app-database
/// connection, and the second could only ever find the claim the first is
/// about to write. Waiting here keeps the duplicate off that connection until
/// the first copy has committed, after which it takes the ordinary
/// already-claimed path.
static IN_FLIGHT_RECEIPTS: LazyLock<Mutex<HashMap<String, Weak<tokio::sync::Mutex<()>>>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

/// The registry entry for one in-flight receipt. It keeps the only strong
/// reference held by a handler that is not waiting, so dropping it once no
/// other copy is queued takes the entry out of the registry again.
struct InFlightReceipt {
    receipt_id: String,
    lock: Arc<tokio::sync::Mutex<()>>,
}

impl InFlightReceipt {
    fn claim(receipt_id: &str) -> Self {
        let mut in_flight = IN_FLIGHT_RECEIPTS
            .lock()
            .unwrap_or_else(PoisonError::into_inner);
        let lock = in_flight
            .get(receipt_id)
            .and_then(Weak::upgrade)
            .unwrap_or_else(|| {
                let lock = Arc::new(tokio::sync::Mutex::new(()));
                in_flight.insert(receipt_id.to_owned(), Arc::downgrade(&lock));
                lock
            });
        Self {
            receipt_id: receipt_id.to_owned(),
            lock,
        }
    }
}

impl Drop for InFlightReceipt {
    fn drop(&mut self) {
        let mut in_flight = IN_FLIGHT_RECEIPTS
            .lock()
            .unwrap_or_else(PoisonError::into_inner);
        // Every other copy of this receipt holds a strong reference of its
        // own, and both taking one and removing the entry happen under this
        // lock, so being the last holder means nothing is queued behind us.
        if Arc::strong_count(&self.lock) == 1 {
            in_flight.remove(&self.receipt_id);
        }
    }
}

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
/// [`handle_decoded_server_message`]: it is keyed on the end-to-end receipt ID
/// and is never purged, so a redelivered envelope is recognised before it is
/// decrypted, whichever transport carried it. An encrypted message commits its
/// claim together with its plaintext one step ahead of the message itself,
/// because the ratchet step decryption spends cannot be rolled back; a retry
/// that finds that plaintext resumes from it instead of decrypting again.
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
            // An envelope that cannot be decoded, or content this client will
            // never be able to act on, stays broken however often it is
            // redelivered. Acknowledge it so one poisoned row cannot be
            // redelivered forever.
            Err(
                error @ (TwonlyError::ProtobufDecode(_)
                | TwonlyError::UnknownProtobufEnumValue(_)
                | TwonlyError::UnprocessableContent(_)),
            ) => {
                tracing::warn!(
                    delivery_id,
                    "dropping an unprocessable mailbox message: {error}"
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

/// Retires our session with a peer when it can no longer open what they send,
/// and picks the error type the peer is answered with.
///
/// A session whose ratchet has diverged -- the usual cause is one side
/// restoring a backup, which rewinds its record behind the peer's -- never
/// recovers by decrypting the same ciphertext again. Retiring it locally is
/// only half the repair: the peer holds the matching half and has to open a
/// new session, which `SESSION_RESET_REQUIRED` asks them to do. Anything else
/// (a duplicate, an identity change, a storage failure) keeps the plain
/// `UNKNOWN` error, whose retry the peer already knows how to handle.
///
/// A refused rate-limit claim also falls back to `UNKNOWN`: the session stays
/// as it is and the message fails, rather than two clients trading resets.
async fn reset_unusable_session(
    ctx: &Arc<Context>,
    from_user_id: i64,
    error: &TwonlyError,
) -> DecryptionErrorType {
    if !matches!(error, TwonlyError::SignalSessionUnusable(_)) {
        return DecryptionErrorType::Unknown;
    }

    let name = from_user_id.to_string();
    let rust_database = ctx.rust_db.read().await.clone();

    match SessionResetLimiter::claim(&rust_database.pool, &name, 1).await {
        Ok(false) => return DecryptionErrorType::Unknown,
        Ok(true) => {}
        Err(error) => {
            tracing::warn!(from_user_id, "could not claim a session reset: {error}");
            return DecryptionErrorType::Unknown;
        }
    }

    let engine = ctx.signal_engine.lock().await;
    let Some(engine) = engine.as_ref() else {
        return DecryptionErrorType::Unknown;
    };

    match engine.reset_session(&name, 1, false).await {
        Ok(_) => {
            tracing::warn!(
                from_user_id,
                "signal session could not decrypt and was reset; asking the peer for a new one"
            );
            DecryptionErrorType::SessionResetRequired
        }
        Err(error) => {
            tracing::warn!(from_user_id, "could not reset the signal session: {error}");
            DecryptionErrorType::Unknown
        }
    }
}

/// Rebuilds a v2 Signal session for a peer that still speaks the legacy
/// protocol, so the decryption error queued for the message can be answered
/// with a session the peer can upgrade to.
///
/// Runs before the inbound transaction opens: it awaits a server round-trip and
/// `establish_signal_session` writes through the pool, and the app database
/// allows a single connection, so doing this under an open transaction would
/// deadlock until the acquire timeout.
async fn upgrade_legacy_session_to_v2(
    ctx: &Arc<Context>,
    database: &Arc<crate::database::app::AppDatabase>,
    from_user_id: i64,
) -> Result<()> {
    tracing::info!("Received legacy signal message; rejecting and upgrading session to v2");

    let has_v2_session = ContactService::new(ctx)
        .has_v2_session(from_user_id)
        .await?;

    let is_v2_contact = sqlx::query_scalar!(
        "SELECT signal_version FROM contacts WHERE user_id = ?",
        from_user_id,
    )
    .fetch_optional(&database.pool)
    .await?
    .is_some_and(|version| version == "v2");

    if has_v2_session && is_v2_contact {
        return Ok(());
    }

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
    .execute(&database.pool)
    .await?;

    Ok(())
}

#[tracing::instrument(
    skip_all,
    fields(
        receipt_id = tracing::field::Empty,
        user = tracing::field::Empty,
        kind = tracing::field::Empty
    )
)]
/// Entry point for one inbound server message, whichever transport carried it.
/// Public so tests can deliver the same message twice and prove a redelivery is
/// handled rather than dropped.
pub async fn handle_decoded_server_message(
    ctx: &Arc<Context>,
    from_user_id: i64,
    message: proto::Message,
) -> Result<()> {
    tracing::Span::current().record("receipt_id", &message.receipt_id);

    if message.receipt_id.is_empty() {
        return Err(TwonlyError::Generic(
            "client message has no receipt ID".into(),
        ));
    }

    // A redelivery of a message still being handled waits here instead of
    // racing the copy in flight for the single app-database connection. The
    // registry entry outlives the lock guard, so the receipt stays registered
    // for as long as anything is queued on it.
    let in_flight = InFlightReceipt::claim(&message.receipt_id);
    let _in_flight = in_flight.lock.lock().await;

    let message_type = Type::try_from(message.r#type)?;
    let is_encrypted_message = matches!(
        message_type,
        Type::Ciphertext | Type::PrekeyBundle | Type::CiphertextV2
    );

    tracing::info!(
        is_encrypted_message,
        ?message_type,
        "Parsed incoming message type"
    );

    if is_encrypted_message {
        ensure_contact_exists(ctx, from_user_id).await?;
    }

    let database = ctx.app_db.read().await.clone();

    // Upgrading a legacy peer to a v2 session needs a server round-trip and
    // writes through the pool itself, so it has to finish before the
    // transaction below claims the single app-database connection.
    if matches!(message_type, Type::Ciphertext | Type::PrekeyBundle) {
        upgrade_legacy_session_to_v2(ctx, &database, from_user_id).await?;
    }

    let mut t = database.pool.begin().await?;

    let claimed = Receipt::claim_received(&mut t, &message.receipt_id).await?;

    // A claim that was committed with a plaintext still parked on it belongs to
    // a message whose handling did not commit. Its ratchet step is spent, so the
    // redelivery has to resume from that plaintext instead of decrypting again.
    let resumed_plaintext = if claimed || message_type != Type::CiphertextV2 {
        None
    } else {
        Receipt::pending_plaintext(&mut t, &message.receipt_id).await?
    };

    if resumed_plaintext.is_some() {
        tracing::info!("Resuming a redelivered message from its parked plaintext");
    }

    // A claim with no plaintext parked on it says nothing about whether the
    // message was handled: a decryption that failed leaves exactly the same
    // trace as one that succeeded and committed. Dropping the redelivery on
    // that ambiguity is what left a peer whose session had broken with no way
    // back to the decrypt path -- and no answer at all, so they resent the same
    // receipt forever. Decrypt again and let the outcome say which it was: a
    // message that opens was never handled, and one the ratchet has already
    // consumed comes back as a duplicate and is acknowledged below.
    let retry_decryption = !claimed && resumed_plaintext.is_none() && is_encrypted_message;

    if retry_decryption {
        tracing::info!("Decrypting a redelivered message that was claimed but not handled");
    }

    if !claimed && resumed_plaintext.is_none() && !retry_decryption {
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
    let mut rebuild_session = false;

    match message_type {
        Type::SenderDeliveryReceipt => {
            tracing::info!("Received sender delivery receipt");
            handle_sender_delivery_receipt(&mut t, from_user_id, &message.receipt_id).await?;
        }
        Type::Ciphertext | Type::PrekeyBundle => {
            queue_decryption_error(&mut t, from_user_id, &message.receipt_id, 0).await?;
            sends_error_response = true;
        }
        Type::CiphertextV2 => {
            let decrypted = match resumed_plaintext {
                Some(plaintext) => Ok(plaintext),
                None => {
                    let ciphertext = message.encrypted_content.ok_or_else(|| {
                        TwonlyError::UnprocessableContent(
                            "V2 encrypted client message has no ciphertext".into(),
                        )
                    })?;
                    let engine = ctx.signal_engine.lock().await;
                    engine
                        .as_ref()
                        .ok_or(TwonlyError::SignalIdentityNotFound)?
                        .decrypt_message(from_user_id.to_string(), 1, ciphertext)
                        .await
                }
            };
            match decrypted {
                Ok(plaintext) => {
                    // Decryption consumed a ratchet step in the signal database,
                    // which this transaction cannot roll back. Commit the
                    // plaintext with the claim first, so a rollback further down
                    // leaves a redelivery something to resume from instead of a
                    // session that can no longer decrypt the message.
                    Receipt::store_pending_plaintext(&mut t, &message.receipt_id, &plaintext)
                        .await?;
                    t.commit().await?;
                    t = database.pool.begin().await?;

                    // Decrypting proves the peer speaks v2, so drop any 'v1'
                    // marking left by a contact lookup that ran before the peer
                    // published a prekey bundle. Otherwise every receipt back to
                    // them would keep fetching a bundle the server does not have.
                    sqlx::query!(
                        "UPDATE contacts SET signal_version = 'v2' WHERE user_id = ? AND signal_version != 'v2'",
                        from_user_id,
                    )
                    .execute(&mut *t)
                    .await?;

                    // Decrypting means a session now exists, so anything parked
                    // for want of one can go out again.
                    sqlx::query!(
                        "UPDATE receipts SET deferred_until_session = NULL WHERE contact_id = ? AND deferred_until_session IS NOT NULL",
                        from_user_id,
                    )
                    .execute(&mut *t)
                    .await?;

                    let content =
                        proto::EncryptedContent::decode(plaintext.as_slice()).map_err(|error| {
                            TwonlyError::UnprocessableContent(format!(
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
                // The ratchet has already consumed this message, so it was
                // handled and the peer is only missing the answer. Falling
                // through without an error response queues the sender delivery
                // receipt below, which is the terminal message that stops them
                // resending it.
                Err(TwonlyError::SignalDuplicateMessage(reason)) => {
                    tracing::info!(
                        receipt_id = message.receipt_id,
                        "acknowledging a message this session already handled: {reason}"
                    );
                }
                Err(error) => {
                    tracing::warn!(
                        receipt_id = message.receipt_id,
                        "V2 decryption failed: {error}"
                    );
                    let error_type = reset_unusable_session(ctx, from_user_id, &error).await;
                    queue_decryption_error(
                        &mut t,
                        from_user_id,
                        &message.receipt_id,
                        error_type as i32,
                    )
                    .await?;
                    sends_error_response = true;
                }
            }
        }
        Type::PlaintextContent => {
            tracing::info!("Handling plaintext content");
            let plaintext = message.plaintext_content.ok_or_else(|| {
                TwonlyError::Generic("plaintext client message has no content".into())
            })?;
            rebuild_session =
                handle_plaintext_content(ctx, &mut t, from_user_id, &message.receipt_id, plaintext)
                    .await?;
        }
        Type::TestNotification => {}
    }

    if is_encrypted_message & !sends_error_response {
        queue_sender_delivery_receipt(&mut t, from_user_id, &message.receipt_id).await?;
    }

    // The message is about to become durable, so the plaintext parked for a
    // retry that is no longer needed can go.
    Receipt::clear_pending_plaintext(&mut t, &message.receipt_id).await?;

    t.commit().await?;

    if let Err(error) = crate::user_config::UserConfig::update(ctx, |user| {
        user.last_server_message_at = Some(crate::utils::current_time().timestamp());
    }) {
        tracing::warn!(%error, "could not record the last server-message timestamp");
    }

    ctx.mark_incoming_committed();

    let ctx = ctx.clone();
    tokio::spawn(async move {
        // The peer reset their session, so the parked receipt has to wait for a
        // session built from a fresh prekey bundle. `establish_signal_session`
        // releases it, and the flush below then sends it as a prekey message
        // the peer can open without any prior state.
        if rebuild_session {
            if let Err(error) = rebuild_session_after_peer_reset(&ctx, from_user_id).await {
                tracing::warn!(
                    from_user_id,
                    "could not rebuild the signal session the peer reset: {error}"
                );
            }
        }

        if let Err(error) = retransmit_queued_receipts(&ctx).await {
            tracing::warn!("failed to flush messages queued during inbound handling: {error}");
        }
    });

    Ok(())
}

/// Answers a peer's session reset by opening a new session with them.
///
/// Our own record is retired first: the peer discarded the half that matches
/// it, so keeping it as the current state would only encrypt more messages
/// they cannot read. `establish_signal_session` then installs a session built
/// from their current prekey bundle and releases everything parked for it.
async fn rebuild_session_after_peer_reset(ctx: &Arc<Context>, from_user_id: i64) -> Result<()> {
    let outcome = rebuild_session(ctx, from_user_id).await;

    // `handle_plaintext_content` parked the receipt for this rebuild, and
    // nothing else is coming to free it. A refused claim means a rebuild is
    // already in flight or just finished, and a failed one leaves the send path
    // to park the receipt again for the reason it actually failed on -- both
    // are better than a receipt that waits for a peer who may never write
    // again.
    let database = ctx.app_db.read().await.clone();
    release_deferred_receipts(&database, from_user_id).await?;

    outcome
}

async fn rebuild_session(ctx: &Arc<Context>, from_user_id: i64) -> Result<()> {
    let name = from_user_id.to_string();
    let rust_database = ctx.rust_db.read().await.clone();

    // The same budget the receiving side spends, so a pair of clients that
    // cannot agree on a session stops trading rebuilds instead of looping.
    if !SessionResetLimiter::claim(&rust_database.pool, &name, 1).await? {
        return Ok(());
    }

    {
        let engine = ctx.signal_engine.lock().await;
        let engine = engine.as_ref().ok_or(TwonlyError::SignalIdentityNotFound)?;
        engine.reset_session(&name, 1, false).await?;
    }

    ContactService::new(ctx)
        .establish_signal_session(from_user_id, None)
        .await?;

    // The repair worked, so the next unrelated failure starts from a full
    // budget rather than what this one spent.
    SessionResetLimiter::clear(&rust_database.pool, &name, 1).await?;

    tracing::info!(
        from_user_id,
        "rebuilt the signal session after a peer reset"
    );
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
        ctx,
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

    if let Some(allowed) = content.widget_sharing_allowed {
        Contact::update_widget_sharing_allowed(t, from_user_id, allowed).await?;
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
        return media::handle_media_update(ctx, t, from_user_id, update).await;
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
        return verification::handle_key_verification_proof(ctx, t, from_user_id, proof).await;
    }

    if let Some(recovery) = content.passwordless_recovery {
        return recovery::handle_passwordless_recovery(t, from_user_id, recovery).await;
    }

    if let Some(heartbeat) = content.passwordless_recovery_heartbeat {
        return recovery::handle_passwordless_recovery_heartbeat(t, from_user_id, heartbeat).await;
    }

    let Some(group_id) = content.group_id else {
        // Everything below is group-scoped. Reaching here without a group ID is
        // normal for a content that only carries sender metadata (a profile
        // counter, a user-discovery version, a friend-promotion request), all of
        // which has already been applied above. Failing it would only make the
        // server redeliver a message there is nothing left to do with.
        tracing::info!("Incoming message carried sender metadata only");
        return Ok(());
    };

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

    // `ensure_group_member` accepts a member the outgoing fan-out excludes, so
    // a stale `leftGroup` row makes the group one-way without a word at either
    // end. Their message says the row is wrong; the group server settles it.
    // Scheduled, not awaited: it is a network round trip and this transaction
    // holds the app database's one connection.
    if Group::has_member_left(t, &group_id, from_user_id).await? {
        GroupService::spawn_stale_membership_refresh(ctx, group_id.clone(), from_user_id);
    }

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
        return media::handle_media(ctx, t, from_user_id, &group_id, media).await;
    }

    if let Some(reaction) = content.reaction {
        return reaction::handle_reaction(t, from_user_id, &group_id, reaction).await;
    }

    if let Some(indicator) = content.typing_indicator {
        return typing_indicator::handle_typing_indicator(t, from_user_id, &group_id, indicator)
            .await;
    }

    Err(TwonlyError::UnprocessableContent(format!(
        "client2client content in receipt {receipt_id} is not implemented in Rust"
    )))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn copies_of_one_receipt_share_a_lock_until_the_last_one_goes() {
        let receipt_id = "in-flight-registry-test";

        let first = InFlightReceipt::claim(receipt_id);
        let second = InFlightReceipt::claim(receipt_id);
        assert!(Arc::ptr_eq(&first.lock, &second.lock));

        // One copy leaving must not unregister a receipt another still holds.
        drop(second);
        let third = InFlightReceipt::claim(receipt_id);
        assert!(Arc::ptr_eq(&third.lock, &first.lock));

        drop(third);
        drop(first);
        assert!(!IN_FLIGHT_RECEIPTS
            .lock()
            .unwrap_or_else(PoisonError::into_inner)
            .contains_key(receipt_id));
    }
}
