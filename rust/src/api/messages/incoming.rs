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
pub(crate) mod story;
mod text_message;
mod typing_indicator;
mod user_discovery;
mod verification;

use crate::api::messages::incoming::messages::{
    ensure_contact_exists, handle_plaintext_content, handle_sender_delivery_receipt,
    process_encrypted_or_queue_error, queue_decryption_error, queue_sender_delivery_receipt,
    release_deferred_receipts, retransmit_queued_receipts, spawn_receipt_delivery, SessionRepair,
};
use crate::api::messages::{content_type_kind, mailbox_sync};
use crate::api::proto::server_to_client::NewMessage;
use crate::api::proto::{client as proto, client_to_server, server_to_client};
use crate::context::Context;
use crate::database::app::contacts::table::Contact;
use crate::database::app::groups::native::Group;
use crate::database::app::receipts::table::Receipt;
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
    ctx: &Arc<Context>, kind: server_to_client::v0::Kind,
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

            mailbox_sync::finish();

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
    ctx: &Arc<Context>, batch: server_to_client::PendingMessagesV2,
) -> client_to_server::Response {
    let mut delivery_ids = Vec::with_capacity(batch.messages.len());

    let page_size = batch.messages.len();

    let pending_count = batch.pending_count;

    mailbox_sync::record_page(pending_count, 0);

    for (index, message) in batch.messages.into_iter().enumerate() {
        let delivery_id = message.delivery_id;

        let from_user_id = message.from_user_id;

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
                    from_user_id,
                    "dropping an unprocessable mailbox message: {error}"
                );

                delivery_ids.push(delivery_id);
            }
            // Anything else (storage, network, Signal state) may succeed later.
            // Leaving the ID out keeps the row on the server for a retry.
            Err(error) => {
                tracing::warn!(
                    delivery_id,
                    from_user_id,
                    "mailbox message not persisted, will retry: {error}"
                );
            }
        }

        mailbox_sync::record_page(pending_count, index + 1);
    }

    // A page acknowledged only in part ends the server's drain until the next
    // trigger. During a catch-up, ask again straight away rather than wait for
    // the next poll -- but only after a page that moved forward, so rows that
    // keep failing cannot turn this into a loop.
    if mailbox_sync::is_active() && !delivery_ids.is_empty() && delivery_ids.len() < page_size {
        if let Ok(client) = crate::api::ApiRuntime::client(ctx).await {
            client.request_catch_up().await;
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
    ctx: &Arc<Context>, server_message: NewMessage,
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
    ctx: &Arc<Context>, from_user_id: i64, error: &TwonlyError,
) -> DecryptionErrorType {
    if !matches!(
        error,
        TwonlyError::SignalSessionUnusable(_) | TwonlyError::SignalPreKeyUnavailable(_)
    ) {
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
/// protocol, so what we send them next already goes out as v2. The decryption
/// error answering their legacy message is plaintext and does not use it; see
/// [`claim_legacy_upgrade_request`] for how the peer itself is moved to v2.
///
/// Runs before the inbound transaction opens: it awaits a server round-trip and
/// `establish_signal_session` writes through the pool, and the app database
/// allows a single connection, so doing this under an open transaction would
/// deadlock until the acquire timeout.
async fn upgrade_legacy_session_to_v2(
    ctx: &Arc<Context>, database: &Arc<crate::database::app::AppDatabase>, from_user_id: i64,
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

/// How long a legacy peer is given to move to v2 before it is asked again.
const LEGACY_UPGRADE_REQUEST_INTERVAL_SECS: i64 = 60 * 60;

/// Claims the right to ask a legacy peer to move to v2, at most once per
/// [`LEGACY_UPGRADE_REQUEST_INTERVAL_SECS`].
///
/// Clients before 0.6.0 fetch a fresh prekey bundle only for a
/// `PREKEY_UNKNOWN` decryption error, and that bundle is what switches the
/// contact to v2 on their side. They answer every decryption error by resending
/// the same queued message, still encrypted as v1, so answering each of those
/// resends would never end and would spend one of our one-time prekeys per
/// round. Leaving the resends unanswered stops the loop: without a reply the
/// old client does not send the message again.
async fn claim_legacy_upgrade_request(
    t: &mut Transaction<'_, Sqlite>, contact_id: i64,
) -> Result<bool> {
    let now = crate::utils::current_time().timestamp();

    let asked_before = now - LEGACY_UPGRADE_REQUEST_INTERVAL_SECS;

    let claimed = sqlx::query!(
        r#"
        INSERT INTO legacy_upgrade_requests(contact_id, requested_at)
        VALUES (?, ?)
        ON CONFLICT(contact_id) DO UPDATE SET requested_at = excluded.requested_at
        WHERE legacy_upgrade_requests.requested_at <= ?
        "#,
        contact_id,
        now,
        asked_before,
    )
    .execute(&mut **t)
    .await?
    .rows_affected()
        > 0;

    Ok(claimed)
}

#[tracing::instrument(
    skip_all,
    fields(
        receipt_id = tracing::field::Empty,
        user = tracing::field::Empty,
        kind = tracing::field::Empty,
        group_id = tracing::field::Empty
    )
)]
/// Entry point for one inbound server message, whichever transport carried it.
/// Public so tests can deliver the same message twice and prove a redelivery is
/// handled rather than dropped.
pub async fn handle_decoded_server_message(
    ctx: &Arc<Context>, from_user_id: i64, message: proto::Message,
) -> Result<()> {
    crate::performance::measure("message.receive", "message.process", async {
        tracing::Span::current().record("receipt_id", &message.receipt_id);

        tracing::Span::current().record("user", from_user_id);

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

        // The outcome of decrypting again stops telling the two apart once the
        // peer opens a new session: it re-encrypts its queue under the same receipt
        // IDs, and every copy opens. Only the mark says a copy was handled, and
        // handling it again repeats everything it did -- a reupload request answered
        // with another full reupload.
        let already_handled =
            retry_decryption && Receipt::was_handled(&mut t, &message.receipt_id).await?;

        if already_handled {
            tracing::info!("Decrypting a redelivered message that was already handled");
        } else if retry_decryption {
            tracing::info!("Decrypting a redelivered message that was claimed but not handled");
        }

        if !claimed && resumed_plaintext.is_none() && !retry_decryption {
            // Delivery receipts are terminal messages and must never themselves be
            // acknowledged. For regular messages Dart retries the delivery receipt
            // after ten days, atomically claiming the retry by moving created_at.
            let should_resend = message_type != Type::SenderDeliveryReceipt
                && Receipt::claim_received_retry(&mut t, &message.receipt_id).await?;

            // A claim does not prove the receipt this one acknowledges is gone.
            // Our own receipt IDs share the claim table: a peer's decryption
            // error arrives under the ID of the receipt it failed on. Once such
            // an ID is claimed, every later acknowledgement of that receipt
            // lands here, and skipping it kept the receipt in the queue, resent
            // on each message from the peer and acknowledged again each time.
            // Clearing it is idempotent; a receipt already gone matches nothing.
            if message_type == Type::SenderDeliveryReceipt {
                handle_sender_delivery_receipt(&mut t, from_user_id, &message.receipt_id).await?;
            }

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

        let mut withhold_delivery_receipt = false;
        let mut defer_until_accepted = false;
        let mut handled = false;

        let mut session_repair = SessionRepair::None;

        match message_type {
            Type::SenderDeliveryReceipt => {
                tracing::info!("Received sender delivery receipt");

                handle_sender_delivery_receipt(&mut t, from_user_id, &message.receipt_id).await?;
            }
            Type::Ciphertext | Type::PrekeyBundle => {
                if claim_legacy_upgrade_request(&mut t, from_user_id).await? {
                    tracing::info!("Asking the legacy peer to fetch our v2 prekey bundle");

                    queue_decryption_error(
                        &mut t,
                        from_user_id,
                        &message.receipt_id,
                        DecryptionErrorType::PrekeyUnknown as i32,
                    )
                    .await?;
                } else {
                    tracing::info!(
                    "Leaving a legacy message unanswered; the peer was already asked to upgrade"
                );
                }

                // Never acknowledged: the message was not read, so the sender must
                // not be told it was delivered.
                withhold_delivery_receipt = true;
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
                    // Decrypting kept the session in step; the content itself was
                    // handled the first time. Falling through queues the sender
                    // delivery receipt the peer keeps resending for.
                    Ok(_) if already_handled => {
                        tracing::info!(
                            receipt_id = message.receipt_id,
                            "acknowledging a redelivered message without handling it again"
                        );
                    }
                    Ok(plaintext) => {
                        // Decryption consumed a ratchet step in the signal database,
                        // which this transaction cannot roll back. Commit the
                        // plaintext with the claim first, so a rollback further down
                        // leaves a redelivery something to resume from instead of a
                        // session that can no longer decrypt the message.
                        Receipt::store_pending_plaintext(&mut t, &message.receipt_id, &plaintext)
                            .await?;

                        t.commit().await?;

                        let content = proto::EncryptedContent::decode(plaintext.as_slice())
                            .map_err(|error| {
                                TwonlyError::UnprocessableContent(format!(
                                    "invalid decrypted client content: {error}"
                                ))
                            })?;

                        contact::prepare_contact_request(ctx, from_user_id, &content).await?;

                        t = database.pool.begin().await?;

                        // Decrypting proves the peer speaks v2, so drop any 'v1'
                        // marking left by a contact lookup that ran before the peer
                        // published a prekey bundle. Otherwise every receipt back to
                        // them would keep fetching a bundle the server does not have.
                        sqlx::query!(
                            "UPDATE contacts SET signal_version = 'v2' WHERE user_id = ? AND \
                         signal_version != 'v2'",
                            from_user_id,
                        )
                        .execute(&mut *t)
                        .await?;

                        // The account just wrote to us, so it exists after all: a
                        // deleted mark on it was wrong, and would keep every reply
                        // from being queued.
                        sqlx::query!(
                            "UPDATE contacts SET account_deleted = 0 WHERE user_id = ? AND \
                         account_deleted = 1",
                            from_user_id,
                        )
                        .execute(&mut *t)
                        .await?;

                        sqlx::query!(
                            "UPDATE user_discovery_announced_users SET account_deleted = 0 WHERE \
                         announced_user_id = ? AND account_deleted = 1",
                            from_user_id,
                        )
                        .execute(&mut *t)
                        .await?;

                        // Decrypting means a session now exists, so anything parked
                        // for want of one can go out again.
                        sqlx::query!(
                        "UPDATE receipts SET deferred_until_session = NULL WHERE contact_id = ? \
                         AND deferred_until_session IS NOT NULL",
                        from_user_id,
                    )
                        .execute(&mut *t)
                        .await?;

                        let delivery = process_encrypted_or_queue_error(
                            ctx,
                            &mut t,
                            from_user_id,
                            &message.receipt_id,
                            content,
                        )
                        .await?;
                        withhold_delivery_receipt = delivery != Delivery::Ack;
                        defer_until_accepted = delivery == Delivery::Deferred;
                        handled = delivery == Delivery::Ack;
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
                    Err(error @ TwonlyError::SignalStorage(_)) => return Err(error),
                    Err(error) => {
                        tracing::warn!(
                            receipt_id = message.receipt_id,
                            "V2 decryption failed: {error}"
                        );

                        if matches!(error, TwonlyError::SignalPreKeyUnavailable(_)) {
                            // Do not pin the app writer while checking/publishing
                            // keys over the network. The per-receipt lock still
                            // excludes another handler for this same envelope.
                            t.rollback().await?;
                            crate::api::Server::repair_pqc_bundle(ctx).await?;
                            t = database.pool.begin().await?;
                            Receipt::claim_received(&mut t, &message.receipt_id).await?;
                        }

                        let error_type = reset_unusable_session(ctx, from_user_id, &error).await;

                        queue_decryption_error(
                            &mut t,
                            from_user_id,
                            &message.receipt_id,
                            error_type as i32,
                        )
                        .await?;

                        withhold_delivery_receipt = true;
                    }
                }
            }
            Type::PlaintextContent => {
                tracing::info!("Handling plaintext content");

                let plaintext = message.plaintext_content.ok_or_else(|| {
                    TwonlyError::Generic("plaintext client message has no content".into())
                })?;

                session_repair = handle_plaintext_content(
                    ctx,
                    &mut t,
                    from_user_id,
                    &message.receipt_id,
                    plaintext,
                )
                .await?;
            }
            Type::TestNotification => {}
        }

        if is_encrypted_message & !withhold_delivery_receipt {
            queue_sender_delivery_receipt(&mut t, from_user_id, &message.receipt_id).await?;
        }

        // The message is about to become durable, so the plaintext parked for a
        // retry that is no longer needed can go.
        if !defer_until_accepted {
            Receipt::clear_pending_plaintext(&mut t, &message.receipt_id).await?;
        }

        if handled {
            Receipt::mark_handled(&mut t, &message.receipt_id).await?;
        }

        t.commit().await?;

        if let Err(error) = crate::user_config::UserConfig::update(ctx, |user| {
            user.last_server_message_at = Some(crate::utils::current_time().timestamp());
        }) {
            tracing::warn!(%error, "could not record the last server-message timestamp");
        }

        let ctx = ctx.clone();

        crate::database::lifecycle::spawn(async move {
            // The peer reset their session, or keeps failing to open ours, so the
            // parked receipt has to wait for a session built from a fresh prekey
            // bundle. `establish_signal_session` releases it, and the flush below
            // then sends it as a prekey message the peer can open without any
            // prior state.
            if session_repair != SessionRepair::None {
                if let Err(error) =
                    rebuild_session_and_release(&ctx, from_user_id, session_repair).await
                {
                    tracing::warn!(
                        from_user_id,
                        ?session_repair,
                        "could not rebuild the signal session: {error}"
                    );
                }
            }

            if let Err(error) = retransmit_queued_receipts(&ctx).await {
                tracing::warn!("failed to flush messages queued during inbound handling: {error}");
            }
        });

        if defer_until_accepted {
            // Keep the reliable-mailbox envelope on the server too. A redelivery
            // resumes the plaintext; it must never reach the duplicate/ACK path.
            Err(TwonlyError::ContactAcceptancePending)
        } else {
            Ok(())
        }
    })
    .await
}

/// Opens a new session with a peer that reset theirs or cannot open ours.
///
/// Our own record is retired first: keeping it as the current state would
/// only encrypt more messages the peer cannot read. `establish_signal_session`
/// then installs a session built from their current prekey bundle and
/// releases everything parked for it.
async fn rebuild_session_and_release(
    ctx: &Arc<Context>, from_user_id: i64, repair: SessionRepair,
) -> Result<()> {
    let outcome = rebuild_session(ctx, from_user_id, repair).await;

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

async fn rebuild_session(
    ctx: &Arc<Context>, from_user_id: i64, repair: SessionRepair,
) -> Result<()> {
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

    // The peer asked for exactly this, so the repair worked and the next
    // unrelated failure starts from a full budget rather than what this one
    // spent. A rebuild we started ourselves is only proven once the peer reads
    // it; clearing here would let every further failure spend another of the
    // peer's one-time prekeys.
    if repair == SessionRepair::PeerReset {
        SessionResetLimiter::clear(&rust_database.pool, &name, 1).await?;
    }

    tracing::info!(from_user_id, ?repair, "rebuilt the signal session");

    Ok(())
}

/// Whether the sender learns that a handled message arrived.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]

pub(crate) enum Delivery {
    /// Queue the sender delivery receipt, which ends the sender's retries.
    Ack,
    /// Tell the sender nothing, either because an error response goes back
    /// instead or because the content is ignored outright.
    Withhold,
    /// Keep decrypted content and retry it after the friendship is accepted.
    Deferred,
}

/// Dispatches already-decrypted client-to-client content to its concrete
/// feature module. Transport decoding and Signal decryption do not belong in
/// this dispatcher.
pub(crate) async fn handle_encrypted(
    ctx: &Arc<Context>, t: &mut Transaction<'_, Sqlite>, from_user_id: i64, receipt_id: &str,
    content: proto::EncryptedContent,
) -> Result<Delivery> {
    // A story that arrives after its 24 hours is ignored whole: no row, no
    // notification and no receipt. The sender drops its receipt when the story
    // expires there, which is what ends its retransmissions.
    if content.story.as_ref().is_some_and(story::is_expired) {
        tracing::info!("Ignoring a story that arrived after it expired");

        return Ok(Delivery::Withhold);
    }

    let notification_content = content.clone();

    // A peer that sends a message again -- after a session reset it resends
    // its queue under new receipt IDs -- finds the chat row already there, and
    // the chat shows nothing new. Alerting for it would announce a message the
    // user cannot find.
    let already_held = already_held(t, from_user_id, &content).await?;

    match handle_encrypted_inner(ctx, t, from_user_id, receipt_id, content).await {
        Err(TwonlyError::ContactAcceptancePending) => return Ok(Delivery::Deferred),
        result => result?,
    }

    if already_held {
        tracing::info!("Not alerting for a message this device already holds");
    } else {
        crate::services::notifications::record_incoming_event(
            ctx,
            t,
            from_user_id,
            receipt_id,
            &notification_content,
        )
        .await?;
    }

    Ok(Delivery::Ack)
}

/// Whether the text, media or reaction in `content` is already stored here,
/// so handling it again shows the user nothing new.
async fn already_held(
    t: &mut Transaction<'_, Sqlite>, from_user_id: i64, content: &proto::EncryptedContent,
) -> Result<bool> {
    if let Some(reaction) = content.reaction.as_ref().filter(|value| !value.remove) {
        return Ok(sqlx::query_scalar!(
            r#"SELECT EXISTS(
                SELECT 1 FROM reactions WHERE message_id = ? AND sender_id = ? AND emoji = ?
            ) AS "held!: bool""#,
            reaction.target_message_id,
            from_user_id,
            reaction.emoji,
        )
        .fetch_one(&mut **t)
        .await?);
    }

    let message_id = if let Some(message) = content.text_message.as_ref() {
        &message.sender_message_id
    } else if let Some(media) = content
        .media
        .as_ref()
        .filter(|media| media.r#type != proto::encrypted_content::media::Type::Reupload as i32)
    {
        &media.sender_message_id
    } else {
        return Ok(false);
    };

    Ok(sqlx::query_scalar!(
        r#"SELECT EXISTS(SELECT 1 FROM messages WHERE message_id = ?) AS "held!: bool""#,
        message_id,
    )
    .fetch_one(&mut **t)
    .await?)
}

async fn handle_encrypted_inner(
    ctx: &Arc<Context>, t: &mut Transaction<'_, Sqlite>, from_user_id: i64, receipt_id: &str,
    content: proto::EncryptedContent,
) -> Result<()> {
    Receipt::mark_all_for_retry(t, from_user_id).await?;

    if let Some(version) = content.sender_user_discovery_version.clone() {
        user_discovery::check_sender_version(ctx, t, from_user_id, version).await?;
    }

    contact::check_for_profile_update(t, from_user_id, &content).await?;

    contact::check_for_custom_avatar_update(t, from_user_id, &content).await?;

    if content.ask_for_friend_promotions == Some(true) {
        Contact::update_ask_for_friend_promotions(t, from_user_id).await?;
    }

    if let Some(allowed) = content.widget_sharing_allowed {
        Contact::update_widget_sharing_allowed(t, from_user_id, allowed).await?;
    }

    let type_kind = content_type_kind(&content);

    tracing::Span::current().record("kind", type_kind);

    if let Some(group_id) = content.group_id.as_deref() {
        tracing::Span::current().record("group_id", group_id);
    }

    tracing::info!("Handling incoming message: {type_kind}");

    if let Some(request) = content.contact_request {
        return contact::handle_contact_request(ctx, t, from_user_id, request).await;
    }

    // A sender that stopped sharing sends zero. A missing score says nothing:
    // protocol replies queued straight from a handler are not decorated.
    if let Some(score) = content.sender_twonly_score {
        Contact::update_twonly_score(t, from_user_id, Some(score)).await?;
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

    if let Some(item) = content.story {
        return story::handle_story(ctx, t, from_user_id, item).await;
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

            // A deliberate block is terminal, rather than a friendship waiting
            // for acceptance. Do not create a request or retain its mailbox row.
            if contact.as_ref().is_some_and(|value| value.blocked != 0) {
                return Ok(());
            }

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

                return Err(TwonlyError::ContactAcceptancePending);
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
        return media::handle_media(ctx, t, from_user_id, &group_id, media, false).await;
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

    #[tokio::test]
    async fn blocked_media_does_not_create_a_request_or_wait_for_acceptance() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        ctx.key_manager.lock().await.user_id = Some(42);
        let database = ctx.app_db.read().await.clone();
        sqlx::query(
            "INSERT INTO contacts(user_id, username, blocked, deleted_by_user) VALUES (7, \
             'blocked', 1, 1)",
        )
        .execute(&database.pool)
        .await?;
        let mut t = database.pool.begin().await?;
        let delivery = handle_encrypted(
            &ctx,
            &mut t,
            7,
            "blocked-image",
            proto::EncryptedContent {
                group_id: Some(Group::direct_chat_id(42, 7)),
                media: Some(proto::encrypted_content::Media {
                    r#type: proto::encrypted_content::media::Type::Image as i32,
                    sender_message_id: "blocked-image".into(),
                    ..Default::default()
                }),
                ..Default::default()
            },
        )
        .await?;
        assert_eq!(delivery, Delivery::Ack);
        let contact = Contact::get_contact_by_id(&mut t, 7).await?.unwrap();
        assert_eq!(
            (
                contact.accepted,
                contact.requested,
                contact.blocked,
                contact.deleted_by_user
            ),
            (0, 0, 1, 1)
        );
        let pending: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM receipts")
            .fetch_one(&mut *t)
            .await?;
        assert_eq!(pending, 0);
        Ok(())
    }

    #[tokio::test]
    async fn media_waiting_for_acceptance_is_not_acked_and_survives_redelivery() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;
        ctx.key_manager.lock().await.user_id = Some(42);
        crate::user_config::UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"me","displayName":"Me"}"#,
        )?;
        let database = ctx.app_db.read().await.clone();
        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'friend')")
            .execute(&database.pool)
            .await?;
        let group_id = Group::direct_chat_id(42, 7);
        let content = proto::EncryptedContent {
            group_id: Some(group_id.clone()),
            media: Some(proto::encrypted_content::Media {
                r#type: proto::encrypted_content::media::Type::Image as i32,
                sender_message_id: "new-image".into(),
                timestamp: chrono::Utc::now().timestamp_millis(),
                ..Default::default()
            }),
            ..Default::default()
        };
        let mut t = database.pool.begin().await?;
        Receipt::claim_received(&mut t, "image-receipt").await?;
        Receipt::store_pending_plaintext(&mut t, "image-receipt", &content.encode_to_vec()).await?;
        t.commit().await?;
        // Keep background delivery offline while exercising the real inbound path.
        let client = crate::api::ApiRuntime::client(&ctx).await?;
        let _transport = client.ws_client.lock().await;
        let message = server_to_client::PendingMessageV2 {
            delivery_id: 1,
            from_user_id: 7,
            body: proto::Message {
                receipt_id: "image-receipt".into(),
                r#type: Type::CiphertextV2 as i32,
                ..Default::default()
            }
            .encode_to_vec(),
        };
        for _ in 0..2 {
            let response = acknowledge_pending_messages(
                &ctx,
                server_to_client::PendingMessagesV2 {
                    messages: vec![message.clone()],
                    pending_count: None,
                },
            )
            .await;
            let Some(Response::Ok(response)) = response.response else {
                panic!("expected mailbox response")
            };
            let Some(ok::Ok::AcknowledgedPendingMessages(ack)) = response.ok else {
                panic!("expected delivery IDs")
            };
            assert!(
                ack.delivery_ids.is_empty(),
                "the server must retain the undelivered image"
            );
            let mut t = database.pool.begin().await?;
            assert_eq!(
                Receipt::pending_plaintext(&mut t, "image-receipt").await?,
                Some(content.encode_to_vec())
            );
            let acked: bool = sqlx::query_scalar(
                "SELECT EXISTS(SELECT 1 FROM receipts WHERE receipt_id = 'image-receipt')",
            )
            .fetch_one(&mut *t)
            .await?;
            assert!(!acked, "no success receipt before the image is stored");
            let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM messages")
                .fetch_one(&mut *t)
                .await?;
            assert_eq!(count, 0);
            t.rollback().await?;
        }
        let mut t = database.pool.begin().await?;
        sqlx::query("UPDATE contacts SET accepted = 1, requested = 0 WHERE user_id = 7")
            .execute(&mut *t)
            .await?;
        let contact = Contact::get_contact_by_id(&mut t, 7).await?.unwrap();
        Group::create_direct_chat(&ctx, &mut t, contact).await?;
        t.commit().await?;
        {
            let response = acknowledge_pending_messages(
                &ctx,
                server_to_client::PendingMessagesV2 {
                    messages: vec![message.clone()],
                    pending_count: None,
                },
            )
            .await;
            let Some(Response::Ok(response)) = response.response else {
                panic!("expected mailbox response")
            };
            let Some(ok::Ok::AcknowledgedPendingMessages(ack)) = response.ok else {
                panic!("expected delivery IDs")
            };
            assert_eq!(ack.delivery_ids, vec![1]);
        }
        let mut t = database.pool.begin().await?;
        assert!(Receipt::pending_plaintext(&mut t, "image-receipt")
            .await?
            .is_none());
        let copies: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM messages WHERE message_id = 'new-image' AND media_id IS NOT NULL",
        )
        .fetch_one(&mut *t)
        .await?;
        assert_eq!(copies, 1);
        let acked: bool = sqlx::query_scalar(
            "SELECT EXISTS(SELECT 1 FROM receipts WHERE receipt_id = 'image-receipt')",
        )
        .fetch_one(&mut *t)
        .await?;
        assert!(acked);
        Ok(())
    }

    async fn signal_engine(
        pool: sqlx::SqlitePool, name: &str,
    ) -> Result<crate::signal::engine::RustSignalEngine> {
        use rand::SeedableRng as _;

        let identity =
            libsignal_protocol::IdentityKeyPair::generate(&mut rand::rngs::StdRng::from_os_rng());

        crate::signal::engine::RustSignalEngine::new_with_pool(
            pool,
            identity.serialize().to_vec(),
            rand::random::<u32>() & 0x3fff,
            name.into(),
        )
    }

    /// The peer from the log: on every wake-up it opens a new session and
    /// resends its queue under the same receipt IDs. Each copy decrypts, so
    /// only the handled mark keeps it from being handled once per resend.
    #[tokio::test]

    async fn a_handled_message_resent_under_a_new_session_is_acknowledged_not_handled_again(
    ) -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;

        ctx.key_manager.lock().await.user_id = Some(42);

        crate::user_config::UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"me","displayName":"Me"}"#,
        )?;

        let rust_database = ctx.rust_db.read().await.clone();

        *ctx.signal_engine.lock().await =
            Some(signal_engine(rust_database.pool.clone(), "42").await?);

        let peer_path = directory.path().join("peer.db");

        std::fs::File::create(&peer_path)?;

        let peer_database =
            crate::database::signal::Database::new(&peer_path.display().to_string(), None, false)
                .await?;

        peer_database.run_migrations().await?;

        let peer = signal_engine(peer_database.pool.clone(), "7").await?;

        let database = ctx.app_db.read().await.clone();

        sqlx::query("INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'friend', 1)")
            .execute(&database.pool)
            .await?;

        let mut t = database.pool.begin().await?;

        let contact = Contact::get_contact_by_id(&mut t, 7).await?.unwrap();

        Group::create_direct_chat(&ctx, &mut t, contact).await?;

        t.commit().await?;

        // Keep receipt delivery offline while exercising the real inbound path.
        let client = crate::api::ApiRuntime::client(&ctx).await?;

        let _transport = client.ws_client.lock().await;

        let content = proto::EncryptedContent {
            group_id: Some(Group::direct_chat_id(42, 7)),
            text_message: Some(proto::encrypted_content::TextMessage {
                sender_message_id: "resent-text".into(),
                text: "hello".into(),
                timestamp: chrono::Utc::now().timestamp_millis(),
                ..Default::default()
            }),
            ..Default::default()
        };

        // Opens a session from a fresh bundle, the way the peer does after a
        // reset, and encrypts the same content under the same receipt ID.
        let deliver = || async {
            let bundle = ctx
                .signal_engine
                .lock()
                .await
                .as_ref()
                .unwrap()
                .generate_bundle()
                .await?;

            peer.reset_session("42", 1, false).await?;

            peer.process_prekey_bundle("42".into(), 1, bundle).await?;

            let ciphertext = peer
                .encrypt_message("42".into(), 1, content.encode_to_vec())
                .await?;

            handle_decoded_server_message(
                &ctx,
                7,
                proto::Message {
                    receipt_id: "resent-receipt".into(),
                    r#type: Type::CiphertextV2 as i32,
                    encrypted_content: Some(ciphertext),
                    plaintext_content: None,
                },
            )
            .await
        };

        let stored = || async {
            sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM messages WHERE message_id = 'resent-text'",
            )
            .fetch_one(&database.pool)
            .await
        };

        deliver().await?;

        assert_eq!(stored().await?, 1);

        // The chat row is gone, as it is once its timer runs out. A copy that
        // was handled again would put it back.
        sqlx::query("DELETE FROM messages WHERE message_id = 'resent-text'")
            .execute(&database.pool)
            .await?;

        deliver().await?;

        assert_eq!(
            stored().await?,
            0,
            "a handled message must not be handled again"
        );

        let acknowledged: bool = sqlx::query_scalar(
            "SELECT EXISTS(SELECT 1 FROM receipts WHERE receipt_id = 'resent-receipt')",
        )
        .fetch_one(&database.pool)
        .await?;

        assert!(acknowledged, "the resend is answered so the peer can stop");

        // A claim without the mark -- left by a failed decryption, or older
        // than the mark -- is still decrypted and handled.
        sqlx::query("UPDATE received_receipts SET handled_at = NULL")
            .execute(&database.pool)
            .await?;

        deliver().await?;

        assert_eq!(stored().await?, 1);

        Ok(())
    }

    #[tokio::test]

    async fn an_acknowledgement_under_a_claimed_id_still_clears_its_receipt() -> anyhow::Result<()>
    {
        let directory = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;

        crate::api::ApiRuntime::close(&ctx).await?;

        let database = ctx.app_db.read().await.clone();

        sqlx::raw_sql(
            "INSERT INTO contacts(user_id, username) VALUES (7, 'alice'), (8, 'bob');
             INSERT INTO receipts(receipt_id, contact_id, message, ack_by_server_at)
             VALUES ('stuck', 7, x'00', 1);",
        )
        .execute(&database.pool)
        .await?;

        // The peer's decryption error for this receipt claimed its ID.
        let mut t = database.pool.begin().await?;

        Receipt::claim_received(&mut t, "stuck").await?;

        t.commit().await?;

        let acknowledgement = proto::Message {
            receipt_id: "stuck".into(),
            r#type: Type::SenderDeliveryReceipt as i32,
            ..Default::default()
        };

        let pending = || async {
            sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM receipts WHERE receipt_id = 'stuck'")
                .fetch_one(&database.pool)
                .await
        };

        // Someone else's acknowledgement cannot clear it.
        handle_decoded_server_message(&ctx, 8, acknowledgement.clone()).await?;

        assert_eq!(pending().await?, 1);

        handle_decoded_server_message(&ctx, 7, acknowledgement.clone()).await?;

        assert_eq!(pending().await?, 0);

        // A further copy finds nothing left to clear.
        handle_decoded_server_message(&ctx, 7, acknowledgement).await?;

        assert_eq!(pending().await?, 0);

        Ok(())
    }

    #[tokio::test]

    async fn contact_request_lookup_does_not_hold_the_app_connection() -> anyhow::Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;

        crate::api::ApiRuntime::close(&ctx).await?;

        let database = ctx.app_db.read().await.clone();

        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'alice')")
            .execute(&database.pool)
            .await?;

        let content = proto::EncryptedContent {
            contact_request: Some(proto::encrypted_content::ContactRequest {
                r#type: proto::encrypted_content::contact_request::Type::Request as i32,
            }),
            ..Default::default()
        };

        // Resume after decryption, without needing a Signal session or server.
        let mut t = database.pool.begin().await?;

        Receipt::claim_received(&mut t, "contact-request").await?;

        Receipt::store_pending_plaintext(&mut t, "contact-request", &content.encode_to_vec())
            .await?;

        t.commit().await?;

        let client = crate::api::ApiRuntime::client(&ctx).await?;

        let _transport = client.ws_client.lock().await;

        let message = proto::Message {
            receipt_id: "contact-request".into(),
            r#type: Type::CiphertextV2 as i32,
            ..Default::default()
        };

        {
            let handling = handle_decoded_server_message(&ctx, 7, message);

            tokio::pin!(handling);

            // Drive handling until it waits for the deliberately stalled lookup.
            assert!(
                tokio::time::timeout(std::time::Duration::from_millis(100), &mut handling,)
                    .await
                    .is_err()
            );

            let rows = tokio::time::timeout(
                std::time::Duration::from_secs(1),
                database.raw_select(
                    "SELECT username FROM contacts WHERE user_id = 7".into(),
                    vec![],
                ),
            )
            .await??;

            assert_eq!(rows.rows[0].values[0].text_value.as_deref(), Some("alice"));
        }

        // Cancelling the lookup leaves the plaintext durable for redelivery.
        let mut t = database.pool.begin().await?;

        assert_eq!(
            Receipt::pending_plaintext(&mut t, "contact-request").await?,
            Some(content.encode_to_vec())
        );

        t.rollback().await?;

        Ok(())
    }

    #[tokio::test]

    async fn reactions_to_expired_messages_are_acknowledged_without_blocking_valid_reactions(
    ) -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;

        crate::user_config::UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"me","displayName":"Me"}"#,
        )?;

        let database = ctx.app_db.read().await.clone();

        for statement in [
            "INSERT INTO contacts(user_id, username) VALUES (7, 'alice')",
            "INSERT INTO groups(group_id, group_name) VALUES ('chat', 'Chat')",
            "INSERT INTO group_members(group_id, contact_id) VALUES ('chat', 7)",
            "INSERT INTO messages(message_id, group_id, type) VALUES ('expired', 'chat', 'text'), \
             ('present', 'chat', 'text')",
            "DELETE FROM messages WHERE message_id = 'expired'",
        ] {
            sqlx::query(statement).execute(&database.pool).await?;
        }

        let mut messages = Vec::new();

        for (delivery_id, message_id) in [(1, "expired"), (2, "present")] {
            let receipt_id = format!("reaction-{message_id}");

            let content = proto::EncryptedContent {
                group_id: Some("chat".into()),
                reaction: Some(proto::encrypted_content::Reaction {
                    target_message_id: message_id.into(),
                    emoji: "👍".into(),
                    remove: false,
                }),
                ..Default::default()
            };

            // Resume plaintext left by an earlier attempt, as happens when a
            // database error rolls back handling after decryption committed.
            let mut t = database.pool.begin().await?;

            Receipt::claim_received(&mut t, &receipt_id).await?;

            Receipt::store_pending_plaintext(&mut t, &receipt_id, &content.encode_to_vec()).await?;

            t.commit().await?;

            messages.push(server_to_client::PendingMessageV2 {
                delivery_id,
                from_user_id: 7,
                body: proto::Message {
                    receipt_id,
                    r#type: Type::CiphertextV2 as i32,
                    ..Default::default()
                }
                .encode_to_vec(),
            });
        }

        let response = acknowledge_pending_messages(
            &ctx,
            server_to_client::PendingMessagesV2 {
                messages,
                pending_count: None,
            },
        )
        .await;

        let Some(Response::Ok(response)) = response.response else {
            panic!("expected a mailbox acknowledgement");
        };

        let Some(ok::Ok::AcknowledgedPendingMessages(ack)) = response.ok else {
            panic!("expected acknowledged delivery IDs");
        };

        assert_eq!(ack.delivery_ids, vec![1, 2]);

        let reactions: Vec<String> = sqlx::query_scalar("SELECT message_id FROM reactions")
            .fetch_all(&database.pool)
            .await?;

        assert_eq!(reactions, vec!["present"]);

        let pending: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM received_receipts WHERE pending_plaintext IS NOT NULL",
        )
        .fetch_one(&database.pool)
        .await?;

        assert_eq!(pending, 0);

        Ok(())
    }

    #[tokio::test]

    async fn incoming_twonly_score_is_stored_and_a_missing_one_keeps_it() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;

        let database = ctx.app_db.read().await.clone();

        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'alice')")
            .execute(&database.pool)
            .await?;

        let mut transaction = database.pool.begin().await?;

        handle_encrypted_inner(
            &ctx,
            &mut transaction,
            7,
            "score-present",
            proto::EncryptedContent {
                sender_twonly_score: Some(23),
                ..Default::default()
            },
        )
        .await?;

        transaction.commit().await?;

        let score: Option<i64> =
            sqlx::query_scalar("SELECT twonly_score FROM contacts WHERE user_id = 7")
                .fetch_one(&database.pool)
                .await?;

        assert_eq!(score, Some(23));

        // A protocol reply queued straight from a handler is not decorated.
        let mut transaction = database.pool.begin().await?;

        handle_encrypted_inner(
            &ctx,
            &mut transaction,
            7,
            "undecorated-reply",
            proto::EncryptedContent {
                message_update: Some(proto::encrypted_content::MessageUpdate {
                    r#type: proto::encrypted_content::message_update::Type::Opened as i32,
                    multiple_target_message_ids: vec!["widget-image".into()],
                    ..Default::default()
                }),
                ..Default::default()
            },
        )
        .await?;

        transaction.commit().await?;

        let score: Option<i64> =
            sqlx::query_scalar("SELECT twonly_score FROM contacts WHERE user_id = 7")
                .fetch_one(&database.pool)
                .await?;

        assert_eq!(score, Some(23), "an undecorated reply keeps the score");

        let mut transaction = database.pool.begin().await?;

        handle_encrypted_inner(
            &ctx,
            &mut transaction,
            7,
            "score-hidden",
            proto::EncryptedContent {
                sender_twonly_score: Some(0),
                ..Default::default()
            },
        )
        .await?;

        transaction.commit().await?;

        let score: Option<i64> =
            sqlx::query_scalar("SELECT twonly_score FROM contacts WHERE user_id = 7")
                .fetch_one(&database.pool)
                .await?;

        assert_eq!(score, Some(0), "a sender that stopped sharing sends zero");

        Ok(())
    }

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

    /// An old client resends the same v1 message for every decryption error,
    /// so only the first one in an interval may be answered.
    #[tokio::test]

    async fn a_legacy_peer_is_asked_to_upgrade_once_per_interval() {
        let directory = tempfile::tempdir().unwrap();

        let path = directory.path().join("app.sqlite");

        let database = crate::database::app::AppDatabase::new(path.to_str().unwrap(), None, false)
            .await
            .unwrap();

        database.run_migrations().await.unwrap();

        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'alice')")
            .execute(&database.pool)
            .await
            .unwrap();

        let mut t = database.pool.begin().await.unwrap();

        assert!(claim_legacy_upgrade_request(&mut t, 7).await.unwrap());

        assert!(!claim_legacy_upgrade_request(&mut t, 7).await.unwrap());

        t.commit().await.unwrap();

        // Once the interval has passed without the peer upgrading, it is asked
        // again, for example because its bundle fetch failed.
        sqlx::query("UPDATE legacy_upgrade_requests SET requested_at = requested_at - ?")
            .bind(LEGACY_UPGRADE_REQUEST_INTERVAL_SECS)
            .execute(&database.pool)
            .await
            .unwrap();

        let mut t = database.pool.begin().await.unwrap();

        assert!(claim_legacy_upgrade_request(&mut t, 7).await.unwrap());

        assert!(!claim_legacy_upgrade_request(&mut t, 7).await.unwrap());

        t.commit().await.unwrap();
    }
}
