/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::{handle_encrypted, Delivery};
use crate::api::proto::client::{self as proto};
use crate::api::Server;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::database::app::tables::{Contact, MediaFile, NewReceipt, Receipt};
use crate::error::{Result, TwonlyError};
use crate::services::contacts::ContactService;
use crate::utils::new_uuid_v4;
use prost::Message as ProstMessage;
use proto::encrypted_content::error_messages::Type;
use sqlx::{Sqlite, Transaction};
use std::sync::{Arc, Mutex, PoisonError};
use tokio::sync::Notify;

/// Successful sends remain in the outbox until the peer acknowledges them.
/// Keep their cooldown durable and apply it in the queue query, rather than
/// repeatedly selecting them and logging one suppressed attempt per receipt.
const RESEND_SUPPRESSION_SECONDS: i64 = 120;

fn receipt_is_due(acknowledged: Option<i64>, last_retry: Option<i64>, now: i64) -> bool {
    match acknowledged {
        None => true,
        Some(ack) => last_retry.unwrap_or(ack) <= now - RESEND_SUPPRESSION_SECONDS,
    }
}

/// Coalesces overlapping flushes of one account's receipt queue.
///
/// Every committed inbound message asks for a flush, and a flush scans the
/// whole queue, so one mailbox page would otherwise start as many identical
/// scans as it carries messages — all of them competing for the single
/// app-database connection. A request that arrives while a flush runs only
/// marks it dirty, so the running flush queries once more before it returns.
///
/// It lives on the [`Context`] rather than in a static because a flush is
/// bound to the database it scans: a process running two accounts would
/// otherwise let one account's flush turn the other's into a no-op, and the
/// dirty flag would buy the wrong queue a second pass.
#[derive(Default)]
pub(crate) struct FlushClaim {
    state: Mutex<FlushState>,
    finished: Notify,
}

#[derive(Default)]
struct FlushState {
    running: bool,
    dirty: bool,
}

/// Held for as long as a flush owns the claim. Dropping it without releasing
/// it — an error or a panic on the way out — frees the claim for the next
/// caller instead of blocking every later flush.
struct FlushGuard<'a> {
    claim: &'a FlushClaim,
    released: bool,
}

impl<'a> FlushGuard<'a> {
    /// Registers a flush for this caller. Returns `None` when one is already
    /// running, in which case it is marked dirty and will query once more.
    fn claim(state: &'a FlushClaim) -> Option<Self> {
        let mut claim = state.state.lock().unwrap_or_else(PoisonError::into_inner);
        if claim.running {
            claim.dirty = true;
            return None;
        }
        claim.running = true;
        claim.dirty = false;
        drop(claim);
        Some(Self {
            claim: state,
            released: false,
        })
    }

    /// Ends the flush when nothing asked for another one while it ran,
    /// otherwise clears the dirty flag and keeps the claim for one more pass.
    /// Both happen under one lock so a request cannot be dropped between the
    /// last query and the release.
    fn release_or_take_dirty(&mut self) -> bool {
        let mut claim = self
            .claim
            .state
            .lock()
            .unwrap_or_else(PoisonError::into_inner);
        if claim.dirty {
            claim.dirty = false;
            return true;
        }
        claim.running = false;
        self.released = true;
        self.claim.finished.notify_waiters();
        false
    }
}

impl Drop for FlushGuard<'_> {
    fn drop(&mut self) {
        if self.released {
            return;
        }
        self.claim
            .state
            .lock()
            .unwrap_or_else(PoisonError::into_inner)
            .running = false;
        self.claim.finished.notify_waiters();
    }
}

pub(crate) async fn queue_encrypted_content(
    t: &mut Transaction<'_, Sqlite>,
    target_user_id: i64,
    content: proto::EncryptedContent,
    contact_will_send_receipt: bool,
) -> Result<String> {
    Contact::ensure_exists(t, target_user_id).await?;

    let wake_receiver =
        crate::services::notifications::should_wake_receiver(t, target_user_id, &content).await?;

    let webxdc_update = content
        .additional_data_message
        .as_ref()
        .and_then(|message| {
            let data =
                proto::AdditionalMessageData::decode(message.additional_message_data.as_deref()?)
                    .ok()?;
            data.webxdc_update
                .map(|update| (message.sender_message_id.clone(), update.instance_id))
        });

    let message = proto::Message {
        r#type: proto::message::Type::CiphertextV2 as i32,
        receipt_id: String::new(),
        encrypted_content: Some(content.encode_to_vec()),
        plaintext_content: None,
    }
    .encode_to_vec();

    let receipt_id = new_uuid_v4();

    NewReceipt::new(&receipt_id, target_user_id, &message)
        .contact_will_send_receipt(contact_will_send_receipt)
        .wake_receiver(wake_receiver)
        .insert(t)
        .await?;

    if content.group_create.is_some()
        || content.group_join.is_some()
        || content.resend_group_public_key.is_some()
    {
        tracing::info!(
            receipt_id,
            contact_id = target_user_id,
            group_id = content.group_id.as_deref(),
            kind = crate::api::messages::content_type_kind(&content),
            "queued group key control message"
        );
    }

    if let Some((update_message_id, instance_id)) = webxdc_update {
        // Hidden updates have no messages row or delivery indicator of their
        // own. Keep enough context to distinguish a missed turn wake-up from
        // an envelope waiting to be sent, without logging the game payload.
        tracing::info!(
            receipt_id,
            update_message_id,
            instance_id,
            contact_id = target_user_id,
            wake_receiver,
            "queued webxdc update"
        );
    }

    Ok(receipt_id)
}

pub(crate) async fn process_encrypted_or_queue_error(
    ctx: &Arc<Context>,
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    receipt_id: &str,
    content: proto::EncryptedContent,
) -> Result<Delivery> {
    let group_id = content.group_id.clone();
    let kind = crate::api::messages::content_type_kind(&content);

    match handle_encrypted(ctx, t, from_user_id, receipt_id, content).await {
        Ok(delivery) => Ok(delivery),
        Err(error) => {
            let description = error.to_string();
            if description.contains("group join arrived before") {
                queue_retry_control(t, from_user_id, receipt_id).await?;
                return Ok(Delivery::Withhold);
            }

            let error_type = if description.contains("not a member") {
                Some(Type::GroupNotFoundOrNotAMember)
            } else if description.contains("not implemented in Rust") {
                Some(Type::UnknownMessageType)
            } else {
                None
            };

            let Some(error_type) = error_type else {
                tracing::warn!(
                    from_user_id,
                    receipt_id,
                    group_id,
                    kind,
                    %error,
                    "failed to handle decrypted message"
                );
                return Err(error);
            };

            let outgoing_receipt_id = new_uuid_v4();
            let response_content = proto::EncryptedContent {
                group_id,
                error_messages: Some(proto::encrypted_content::ErrorMessages {
                    r#type: error_type as i32,
                    related_receipt_id: receipt_id.to_owned(),
                }),
                ..Default::default()
            };

            let response = proto::Message {
                r#type: proto::message::Type::CiphertextV2 as i32,
                receipt_id: String::new(),
                encrypted_content: Some(response_content.encode_to_vec()),
                plaintext_content: None,
            }
            .encode_to_vec();

            sqlx::query!(
                r#"
                INSERT INTO receipts(receipt_id, contact_id, message, contact_will_sends_receipt)
                VALUES (?, ?, ?, 0)
                "#,
                outgoing_receipt_id,
                from_user_id,
                response,
            )
            .execute(&mut **t)
            .await?;

            Ok(Delivery::Withhold)
        }
    }
}

async fn queue_retry_control(
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    receipt_id: &str,
) -> Result<()> {
    let response = proto::Message {
        r#type: proto::message::Type::PlaintextContent as i32,
        receipt_id: String::new(),
        encrypted_content: None,
        plaintext_content: Some(proto::PlaintextContent {
            decryption_error_message: None,
            retry_control_error: Some(proto::plaintext_content::RetryErrorMessage {}),
        }),
    }
    .encode_to_vec();

    sqlx::query!(
        r#"
        INSERT OR REPLACE INTO receipts(receipt_id, contact_id, message, contact_will_sends_receipt)
        VALUES (?, ?, ?, 0)
        "#,
        receipt_id,
        from_user_id,
        response,
    )
    .execute(&mut **t)
    .await?;

    Ok(())
}

pub(crate) async fn ensure_contact_exists(ctx: &Arc<Context>, from_user_id: i64) -> Result<()> {
    let db_app = ctx.app_db.read().await.clone();

    let exists = sqlx::query_scalar!(
        "SELECT EXISTS(SELECT 1 FROM contacts WHERE user_id = ?)",
        from_user_id,
    )
    .fetch_one(&db_app.pool)
    .await?;

    if exists != 0 {
        return Ok(());
    }

    tracing::info!("Contact not found locally. Requesting user from the server.");

    let user = match Server::get_user_by_id(ctx, from_user_id).await? {
        ServerResult::Ok(u) => u,
        ServerResult::ErrorCode(code) => {
            return Err(TwonlyError::Generic(format!(
                "Failed to get user by id: {}",
                code
            )));
        }
    };

    let username = user
        .username
        .map(String::from_utf8)
        .transpose()?
        .unwrap_or_else(|| "[Unknown]".into());

    let signal_version = if user.pqc_bundle.is_some() {
        "v2"
    } else {
        "v1"
    };

    tracing::info!("Loaded username: {username}");

    // Hidden, not requested: a first message from a stranger is not itself a
    // contact request, and `requested = 1` here turned "added me to a group"
    // into a phantom one. The direct-chat branch in `incoming.rs` and
    // `handle_contact_request` set `requested` when it is really meant.
    sqlx::query!(
        r#"
        INSERT OR IGNORE INTO contacts(user_id, username, signal_version, accepted, requested, deleted_by_user)
        VALUES (?, ?, ?, 0, 0, 1)
        "#,
        from_user_id,
        username,
        signal_version,
    )
    .execute(&db_app.pool)
    .await?;

    if let Some(identity_key) = user.public_identity_key {
        let rust_database = ctx.rust_db.read().await.clone();
        sqlx::query!(
            r#"
            INSERT INTO signal_identities(name, identity_key, timestamp)
            VALUES (?, ?, CAST(strftime('%s', 'now') AS INTEGER))
            ON CONFLICT(name) DO NOTHING
            "#,
            from_user_id.to_string(),
            identity_key,
        )
        .execute(&rust_database.pool)
        .await?;
    }

    Ok(())
}

pub(crate) async fn queue_sender_delivery_receipt(
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    receipt_id: &str,
) -> Result<()> {
    let response = proto::Message {
        r#type: proto::message::Type::SenderDeliveryReceipt as i32,
        receipt_id: String::new(),
        encrypted_content: None,
        plaintext_content: None,
    }
    .encode_to_vec();

    sqlx::query!(
        r#"
        INSERT OR IGNORE INTO receipts(
            receipt_id, contact_id, message, contact_will_sends_receipt
        ) VALUES (?, ?, ?, 0)
        "#,
        receipt_id,
        from_user_id,
        response,
    )
    .execute(&mut **t)
    .await?;

    Ok(())
}

pub(crate) fn spawn_receipt_delivery(ctx: &Arc<Context>, receipt_id: String) {
    // The unsolicited-message handler runs on the socket reader task. Waiting
    // for a request response there would deadlock that reader, so delivery is
    // started only after the transaction commits and the handler can return.
    let ctx = ctx.clone();
    tokio::spawn(async move {
        if let Err(error) = send_queued_receipt(&ctx, &receipt_id).await {
            tracing::warn!(receipt_id, "failed to send delivery receipt: {error}");
        }
    });
}

async fn encrypt_v2_with_session_recovery(
    ctx: &Arc<Context>,
    contact_id: i64,
    plaintext: Vec<u8>,
) -> Result<Vec<u8>> {
    let encrypt = |plaintext| async move {
        let engine = ctx.signal_engine.lock().await;
        engine
            .as_ref()
            .ok_or(TwonlyError::SignalIdentityNotFound)?
            .encrypt_message(contact_id.to_string(), 1, plaintext)
            .await
    };

    match encrypt(plaintext.clone()).await {
        Err(TwonlyError::Signal(message))
            if message.contains("session with") & message.contains("not found") =>
        {
            tracing::warn!(
                contact_id,
                "Signal session missing; rebuilding it from the server prekey bundle"
            );

            ContactService::new(ctx)
                .establish_signal_session(contact_id, None)
                .await?;

            encrypt(plaintext).await
        }
        result => result,
    }
}

pub(crate) struct PreparedQueuedReceipt {
    pub contact_id: i64,
    pub message_id: Option<String>,
    pub contact_will_sends_receipt: i64,
    pub message: proto::Message,
    pub wake_receiver: bool,
}

struct PreparedQueuedReceiptRow {
    contact_id: i64,
    message: Vec<u8>,
    message_id: Option<String>,
    contact_will_sends_receipt: i64,
    wake_receiver: i64,
    account_deleted: i64,
    signal_version: String,
    ack_by_server_at: Option<i64>,
    last_retry: Option<i64>,
}

async fn load_queued_receipt_row(
    pool: &sqlx::SqlitePool,
    receipt_id: &str,
) -> Result<Option<PreparedQueuedReceiptRow>> {
    let row = sqlx::query_as!(
        PreparedQueuedReceiptRow,
        r#"
        SELECT r.contact_id, r.message, r.message_id, r.contact_will_sends_receipt,
               r.wake_receiver, c.account_deleted, c.signal_version,
               r.ack_by_server_at, r.last_retry
        FROM receipts r
        JOIN contacts c ON c.user_id = r.contact_id
        WHERE r.receipt_id = ?
        "#,
        receipt_id,
    )
    .fetch_optional(pool)
    .await?;
    let Some(mut row) = row else {
        return Ok(None);
    };
    row.message_id = tracked_message_id(pool, row.message_id, &row.message).await?;
    Ok(Some(row))
}

/// Hidden game updates stay independent of purgeable chat rows in the outbox,
/// but their acknowledgements belong to the announcement derived from them.
async fn tracked_message_id<'e>(
    executor: impl sqlx::Executor<'e, Database = Sqlite>,
    message_id: Option<String>,
    queued_message: &[u8],
) -> Result<Option<String>> {
    if message_id.is_some() {
        return Ok(message_id);
    }
    let announcement_id = (|| {
        let envelope = proto::Message::decode(queued_message).ok()?;
        let content =
            proto::EncryptedContent::decode(envelope.encrypted_content?.as_slice()).ok()?;
        let message = content.additional_data_message?;
        let data =
            proto::AdditionalMessageData::decode(message.additional_message_data?.as_slice())
                .ok()?;
        (message.hidden && data.webxdc_update.is_some()).then(|| {
            crate::services::webxdc::WebxdcService::info_message_id(&message.sender_message_id)
        })
    })();
    let Some(announcement_id) = announcement_id else {
        return Ok(None);
    };
    // The announcement can be absent (a silent update or an expired chat row).
    // Only track rows that still exist, and never recreate purged announcements.
    Ok(sqlx::query_scalar::<_, String>(
        "SELECT message_id FROM messages WHERE message_id = ? AND sender_id IS NULL",
    )
    .bind(announcement_id)
    .fetch_optional(executor)
    .await?)
}

pub(crate) async fn prepare_queued_receipt_details(
    ctx: &Arc<Context>,
    receipt_id: &str,
) -> Result<Option<PreparedQueuedReceipt>> {
    let app_db = ctx.app_db.read().await.clone();
    let Some(row) = load_queued_receipt_row(&app_db.pool, receipt_id).await? else {
        return Ok(None);
    };

    if row.account_deleted != 0 {
        return Err(TwonlyError::Generic(format!(
            "contact {} deleted their account",
            row.contact_id
        )));
    }

    prepare_queued_receipt_from_row(ctx, receipt_id, row)
        .await
        .map(Some)
}

/// Encrypts the queued payload. Fetches a prekey bundle from the server when
/// the contact has no v2 session yet, so the caller must have ruled out a
/// deleted account first.
async fn prepare_queued_receipt_from_row(
    ctx: &Arc<Context>,
    receipt_id: &str,
    row: PreparedQueuedReceiptRow,
) -> Result<PreparedQueuedReceipt> {
    let mut message = proto::Message::decode(row.message.as_slice())
        .map_err(|error| TwonlyError::Generic(format!("invalid queued message: {error}")))?;
    message.receipt_id = receipt_id.to_owned();

    let message_type = proto::message::Type::try_from(message.r#type)
        .map_err(|_| TwonlyError::Generic("queued message has invalid type".into()))?;

    let is_encrypted = matches!(
        message_type,
        proto::message::Type::Ciphertext
            | proto::message::Type::PrekeyBundle
            | proto::message::Type::CiphertextV2
    );

    if is_encrypted {
        if row.signal_version != "v2" {
            let contacts = ContactService::new(ctx);
            if let Err(error) = contacts
                .establish_signal_session(row.contact_id, None)
                .await
            {
                // The peer may have published no prekey bundle yet, for example
                // when their account predates the PQC keys. An existing session
                // still encrypts for them, so only a peer we cannot talk to at
                // all keeps the payload queued.
                if !contacts.has_v2_session(row.contact_id).await? {
                    return Err(error);
                }
                tracing::warn!(
                    contact_id = row.contact_id,
                    "prekey bundle unavailable; encrypting with the existing v2 session: {error}"
                );
            }
        }

        let plaintext = message.encrypted_content.take().ok_or_else(|| {
            TwonlyError::Generic("queued encrypted message has no content".into())
        })?;
        let plaintext =
            crate::services::avatars::refresh_queued_response(ctx, row.contact_id, plaintext)
                .await?;

        message.encrypted_content =
            Some(encrypt_v2_with_session_recovery(ctx, row.contact_id, plaintext).await?);
        message.r#type = proto::message::Type::CiphertextV2 as i32;
    }

    Ok(PreparedQueuedReceipt {
        contact_id: row.contact_id,
        message_id: row.message_id,
        contact_will_sends_receipt: row.contact_will_sends_receipt,
        message,
        wake_receiver: row.wake_receiver != 0,
    })
}

pub(crate) async fn prepare_queued_receipt(
    ctx: &Arc<Context>,
    receipt_id: &str,
) -> Result<Option<Vec<u8>>> {
    Ok(prepare_queued_receipt_details(ctx, receipt_id)
        .await?
        .map(|receipt| receipt.message.encode_to_vec()))
}

pub(crate) async fn send_queued_receipt(ctx: &Arc<Context>, receipt_id: &str) -> Result<()> {
    let started = std::time::Instant::now();
    let app_db = ctx.app_db.read().await.clone();
    let Some(row) = load_queued_receipt_row(&app_db.pool, receipt_id).await? else {
        return Ok(());
    };
    // Direct sends share the same rule as a sweep. An explicit recovery clears
    // ack_by_server_at, so failed sends and session-reset retries bypass it.
    if !receipt_is_due(
        row.ack_by_server_at,
        row.last_retry,
        chrono::Utc::now().timestamp(),
    ) {
        return Ok(());
    }

    // `account_deleted` is a latch: one `UserIdNotFound` on any contact-scoped
    // request sets it, and this check runs before anything that could clear it,
    // so a peer who has since re-registered would stay unreachable forever --
    // every message dropped here, unsent, unacknowledged and unlogged. Ask the
    // server once more before believing it, and drop only what the server
    // positively denies.
    let row = if row.account_deleted != 0 {
        match ContactService::new(ctx)
            .establish_signal_session(row.contact_id, None)
            .await
        {
            Err(TwonlyError::PeerAccountDeleted(contact_id)) => {
                tracing::warn!(
                    receipt_id,
                    contact_id,
                    "dropping a message for an account the server does not know"
                );
                Receipt::delete(&app_db.pool, receipt_id).await?;
                return Ok(());
            }
            // The account exists; it has just published no bundle. An existing
            // session may still encrypt for it, and if not, preparing the
            // payload parks the receipt for the right reason.
            Ok(()) | Err(TwonlyError::PeerHasNoPrekeyBundle(_)) => {
                tracing::info!(
                    contact_id = row.contact_id,
                    "contact is registered after all; clearing the deleted-account mark"
                );
            }
            // Anything else -- a network failure above all -- must not be read
            // as a deleted account. Leave the receipt queued for a later sweep.
            Err(error) => return Err(error),
        }

        // `establish_signal_session` cleared the mark and may have changed
        // `signal_version`, so the payload is prepared from the current row.
        match load_queued_receipt_row(&app_db.pool, receipt_id).await? {
            Some(row) => row,
            None => return Ok(()),
        }
    } else {
        row
    };

    let receipt = match prepare_queued_receipt_from_row(ctx, receipt_id, row).await {
        Ok(receipt) => receipt,
        // `prepare_queued_receipt_from_row` only lets this through when there
        // is no usable session either, so there is nothing to retry against
        // until the peer reappears.
        Err(TwonlyError::PeerHasNoPrekeyBundle(contact_id)) => {
            tracing::info!(
                receipt_id,
                contact_id,
                "peer has no prekey bundle and no session; deferring the receipt until one exists"
            );
            defer_receipt_until_session(&app_db, receipt_id).await?;
            return Ok(());
        }
        Err(error) => return Err(error),
    };

    match Server::send_text_message(
        ctx,
        receipt.contact_id,
        receipt.message.encode_to_vec(),
        receipt.wake_receiver,
    )
    .await?
    {
        ServerResult::Ok(()) => {}
        ServerResult::ErrorCode(code) => {
            return Err(TwonlyError::Generic(format!(
                "server rejected sender delivery receipt with code: {}",
                code
            )));
        }
    }

    // A peer's delivery receipt may arrive much later. Log server acceptance
    // separately so delayed receiver wake-ups do not look like delayed sends.
    tracing::info!(
        receipt_id,
        contact_id = receipt.contact_id,
        wake_receiver = receipt.wake_receiver,
        elapsed_ms = started.elapsed().as_millis() as u64,
        "server accepted queued receipt"
    );

    let mut t = app_db.pool.begin().await?;
    if let Some(message_id) = receipt.message_id {
        sqlx::query!(
            r#"
            INSERT INTO message_actions(message_id, contact_id, type)
            SELECT ?, ?, 'ackByServerAt'
            WHERE EXISTS (SELECT 1 FROM messages WHERE message_id = ?)
            ON CONFLICT(message_id, contact_id, type)
            DO UPDATE SET action_at = CAST(strftime('%s', 'now') AS INTEGER)
            "#,
            message_id,
            receipt.contact_id,
            message_id,
        )
        .execute(&mut *t)
        .await?;

        // `message_actions` keeps the per-recipient acknowledgement used by
        // group chats. The message row also carries the aggregate value used
        // by message bubbles and chat previews to leave the "sending" state.
        sqlx::query("UPDATE messages SET ack_by_server = ? WHERE message_id = ?")
            .bind(chrono::Utc::now().timestamp())
            .bind(&message_id)
            .execute(&mut *t)
            .await?;
    }
    if receipt.contact_will_sends_receipt == 0 {
        // Terminal replies are deleted on success. A redelivered message may
        // queue its acknowledgement again; allow that reply immediately so a
        // lost acknowledgement never keeps the peer's outbox alive.
        Receipt::delete(&mut *t, receipt_id).await?;
    } else {
        // The wake is spent the moment the server accepts the envelope, so it
        // is cleared here alongside the acknowledgement that records it.
        //
        // This receipt outlives its delivery -- it is kept until the peer's own
        // receipt comes back -- and every inbound message from that peer marks
        // it for retry again. Without this, one message would push the peer
        // once per retransmission: a chat busy enough to keep retrying, a game
        // exchanging updates for instance, would alert them over and over for a
        // message they were told about the first time and already have.
        sqlx::query!(
            r#"
            UPDATE receipts SET
                ack_by_server_at = CAST(strftime('%s', 'now') AS INTEGER),
                wake_receiver = 0,
                retry_count = retry_count + 1,
                last_retry = CAST(strftime('%s', 'now') AS INTEGER),
                mark_for_retry = NULL
            WHERE receipt_id = ?
            "#,
            receipt_id,
        )
        .execute(&mut *t)
        .await?;
    }
    t.commit().await?;
    Ok(())
}

/// Parks a receipt that cannot be encrypted until the peer becomes reachable.
///
/// The peer has published no prekey bundle and we hold no session with them, so
/// every sweep would repeat the same failing server round-trip. The receipt is
/// kept, not dropped: `release_deferred_receipts` puts it back in the queue as
/// soon as a session exists.
async fn defer_receipt_until_session(
    database: &Arc<crate::database::app::AppDatabase>,
    receipt_id: &str,
) -> Result<()> {
    sqlx::query!(
        r#"
        UPDATE receipts
        SET deferred_until_session = CAST(strftime('%s', 'now') AS INTEGER)
        WHERE receipt_id = ?
        "#,
        receipt_id,
    )
    .execute(&database.pool)
    .await?;
    Ok(())
}

/// Requeues everything parked for a peer we can now encrypt for.
///
/// Called wherever a v2 session appears: a prekey bundle fetch that succeeded,
/// or an inbound message from the peer that opened a session on our side.
pub(crate) async fn release_deferred_receipts(
    database: &Arc<crate::database::app::AppDatabase>,
    contact_id: i64,
) -> Result<()> {
    sqlx::query!(
        "UPDATE receipts SET deferred_until_session = NULL WHERE contact_id = ? AND deferred_until_session IS NOT NULL",
        contact_id,
    )
    .execute(&database.pool)
    .await?;
    Ok(())
}

pub async fn retransmit_queued_receipts(ctx: &Arc<Context>) -> Result<()> {
    let Some(mut guard) = FlushGuard::claim(&ctx.queued_receipt_flush) else {
        return Ok(());
    };

    flush_claimed_receipts(ctx, &mut guard).await
}

/// Unlike event-triggered flushes, a worker about to close its socket must wait
/// for an existing flush. Register before claiming so completion or cancellation
/// between the claim check and the await cannot lose the wake-up.
pub(crate) async fn retransmit_queued_receipts_and_wait(ctx: &Arc<Context>) -> Result<()> {
    loop {
        let notified = ctx.queued_receipt_flush.finished.notified();
        tokio::pin!(notified);
        notified.as_mut().enable();
        if let Some(mut guard) = FlushGuard::claim(&ctx.queued_receipt_flush) {
            return flush_claimed_receipts(ctx, &mut guard).await;
        }
        notified.await;
    }
}

async fn flush_claimed_receipts(ctx: &Arc<Context>, guard: &mut FlushGuard<'_>) -> Result<()> {
    loop {
        flush_queued_receipts(ctx).await?;

        if !guard.release_or_take_dirty() {
            return Ok(());
        }
    }
}

async fn flush_queued_receipts(ctx: &Arc<Context>) -> Result<()> {
    let database = ctx.app_db.read().await.clone();
    let receipt_ids = due_receipt_ids(&database.pool, chrono::Utc::now().timestamp()).await?;
    for receipt_id in receipt_ids {
        if let Err(error) = send_queued_receipt(ctx, &receipt_id).await {
            tracing::warn!(receipt_id, "queued delivery receipt retry failed: {error}");
        }
    }
    Ok(())
}

async fn due_receipt_ids(pool: &sqlx::SqlitePool, now: i64) -> Result<Vec<String>> {
    let retry_before = now - RESEND_SUPPRESSION_SECONDS;
    let receipt_ids = sqlx::query_scalar!(
        r#"
        SELECT receipt_id FROM receipts
        WHERE will_be_retried_by_media_upload = 0
          AND deferred_until_session IS NULL
          AND (ack_by_server_at IS NULL OR mark_for_retry IS NOT NULL)
          AND (ack_by_server_at IS NULL OR COALESCE(last_retry, ack_by_server_at) <= ?)
          AND (mark_for_retry_after_accepted IS NULL OR EXISTS(
              SELECT 1 FROM contacts
              WHERE contacts.user_id = receipts.contact_id AND contacts.accepted = 1
          ))
        ORDER BY created_at
        "#,
        retry_before,
    )
    .fetch_all(pool)
    .await?;
    Ok(receipt_ids)
}

/// Includes cooldown entries: the scheduler must retain the next chance to
/// retry them, while contacts without a session or acceptance stay parked.
pub(crate) async fn has_pending_receipts(ctx: &Arc<Context>) -> Result<bool> {
    let database = ctx.app_db.read().await.clone();
    Ok(sqlx::query_scalar::<_, i64>(
        r#"SELECT EXISTS(SELECT 1 FROM receipts
           WHERE will_be_retried_by_media_upload = 0
             AND deferred_until_session IS NULL
             AND (ack_by_server_at IS NULL OR mark_for_retry IS NOT NULL)
             AND (mark_for_retry_after_accepted IS NULL OR EXISTS(
                 SELECT 1 FROM contacts WHERE contacts.user_id = receipts.contact_id
                   AND contacts.accepted = 1
             )))"#,
    )
    .fetch_one(&database.pool)
    .await?
        != 0)
}

pub(crate) async fn queue_decryption_error(
    tr: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    receipt_id: &str,
    error_type: i32,
) -> Result<()> {
    let response = proto::Message {
        r#type: proto::message::Type::PlaintextContent as i32,
        receipt_id: String::new(),
        encrypted_content: None,
        plaintext_content: Some(proto::PlaintextContent {
            decryption_error_message: Some(proto::plaintext_content::DecryptionErrorMessage {
                r#type: error_type,
            }),
            retry_control_error: None,
        }),
    }
    .encode_to_vec();
    NewReceipt::new(receipt_id, from_user_id, &response)
        .contact_will_send_receipt(false)
        .insert_if_absent(tr)
        .await?;
    Ok(())
}

pub(crate) async fn handle_sender_delivery_receipt(
    transaction: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    receipt_id: &str,
) -> Result<()> {
    let receipt = sqlx::query!(
        r#"
        SELECT message_id, message
        FROM receipts
        WHERE receipt_id = ? AND contact_id = ?
        "#,
        receipt_id,
        from_user_id,
    )
    .fetch_optional(&mut **transaction)
    .await?;

    let message_id = match receipt {
        Some(receipt) => {
            tracked_message_id(&mut **transaction, receipt.message_id, &receipt.message).await?
        }
        None => None,
    };

    if let Some(message_id) = message_id {
        sqlx::query!(
            r#"
            INSERT INTO message_actions(message_id, contact_id, type)
            VALUES (?, ?, 'ackByUserAt')
            ON CONFLICT(message_id, contact_id, type)
            DO UPDATE SET action_at = CAST(strftime('%s', 'now') AS INTEGER)
            "#,
            message_id,
            from_user_id,
        )
        .execute(&mut **transaction)
        .await?;

        MediaFile::handle_response_from_receiver(transaction, &message_id).await?;
    }
    sqlx::query!(
        r#"
        DELETE FROM receipts
        WHERE receipt_id = ? AND contact_id = ?
        "#,
        receipt_id,
        from_user_id,
    )
    .execute(&mut **transaction)
    .await?;

    Ok(())
}

/// Requeues the receipt a peer could not process, under a new ID.
///
/// Returns whether the peer also retired their Signal session, in which case
/// the caller has to rebuild one before the requeued receipt can go out. The
/// receipt is parked here so the flush that follows the caller's commit cannot
/// send it through the session the peer just threw away.
pub async fn handle_plaintext_content(
    _ctx: &Context,
    transaction: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    receipt_id: &str,
    plaintext: proto::PlaintextContent,
) -> Result<bool> {
    if plaintext.decryption_error_message.is_none() && plaintext.retry_control_error.is_none() {
        return Ok(false);
    }

    // An unknown type comes from a client newer than this one. Treating it as
    // a plain retry request is what every release before session resets did,
    // so it stays the fallback rather than an error.
    let rebuild_session = plaintext.decryption_error_message.is_some_and(|error| {
        proto::plaintext_content::decryption_error_message::Type::try_from(error.r#type)
            == Ok(proto::plaintext_content::decryption_error_message::Type::SessionResetRequired)
    });

    let new_receipt_id = uuid::Uuid::new_v4().to_string();
    sqlx::query!(
        r#"
        UPDATE receipts
        SET receipt_id = ?,
            mark_for_retry = CAST(strftime('%s', 'now') AS INTEGER),
            retry_count = retry_count + 1,
            ack_by_server_at = NULL,
            -- A rebuild needs a server round-trip, so it cannot run inside this
            -- transaction. `release_deferred_receipts` frees the receipt once
            -- the new session stands.
            deferred_until_session = CASE
                WHEN ? THEN CAST(strftime('%s', 'now') AS INTEGER)
                ELSE deferred_until_session
            END
        WHERE receipt_id = ? AND contact_id = ?
        "#,
        new_receipt_id,
        rebuild_session,
        receipt_id,
        from_user_id,
    )
    .execute(&mut **transaction)
    .await?;

    Ok(rebuild_session)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn receipt_sweeps_skip_cooldowns_but_preserve_retries() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;
        let database = ctx.app_db.read().await.clone();
        sqlx::query("INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'accepted', 1), (8, 'unaccepted', 0)")
            .execute(&database.pool).await?;
        let now = chrono::Utc::now().timestamp();
        // A busy mailbox marks all 200 recently accepted messages again. None
        // should reach the send loop, even across many consecutive sweeps.
        for index in 0..200 {
            sqlx::query("INSERT INTO receipts(receipt_id, contact_id, message, ack_by_server_at, last_retry, mark_for_retry) VALUES (?, 7, x'00', ?, ?, ?)")
                .bind(format!("recent-{index}")).bind(now - 1).bind(now - 1).bind(now)
                .execute(&database.pool).await?;
        }
        for (id, ack, last_retry) in [
            ("unsent", None, None),
            ("failed-attempt", None, Some(now)),
            ("explicit-reset", None, Some(now - 1)),
            ("old", Some(now - 121), Some(now - 120)),
            ("legacy-no-last-retry", Some(now - 120), None),
        ] {
            sqlx::query("INSERT INTO receipts(receipt_id, contact_id, message, ack_by_server_at, last_retry, mark_for_retry) VALUES (?, 7, x'00', ?, ?, ?)")
                .bind(id).bind(ack).bind(last_retry).bind(now)
                .execute(&database.pool).await?;
        }
        for statement in [
            "INSERT INTO receipts(receipt_id, contact_id, message, deferred_until_session) VALUES ('deferred', 7, x'00', 1)",
            "INSERT INTO receipts(receipt_id, contact_id, message, will_be_retried_by_media_upload) VALUES ('media', 7, x'00', 1)",
            "INSERT INTO receipts(receipt_id, contact_id, message, mark_for_retry_after_accepted) VALUES ('unaccepted', 8, x'00', 1)",
            "INSERT INTO receipts(receipt_id, contact_id, message, ack_by_server_at) VALUES ('not-marked', 7, x'00', 1)",
        ] {
            sqlx::query(statement).execute(&database.pool).await?;
        }
        for _ in 0..10 {
            let mut due = due_receipt_ids(&database.pool, now).await?;
            due.sort();
            assert_eq!(
                due,
                [
                    "explicit-reset",
                    "failed-attempt",
                    "legacy-no-last-retry",
                    "old",
                    "unsent"
                ]
            );
        }
        assert_eq!(due_receipt_ids(&database.pool, now + 119).await?.len(), 205);
        assert!(has_pending_receipts(&ctx).await?);

        // Direct calls use persisted timestamps too, before decoding or
        // networking. x'00' would fail to decode if this cooldown were missed.
        send_queued_receipt(&ctx, "recent-0").await?;
        assert!(!receipt_is_due(Some(now - 1), Some(now - 1), now));
        assert!(receipt_is_due(None, Some(now - 1), now));
        assert!(receipt_is_due(Some(now - 120), None, now));
        Ok(())
    }

    #[tokio::test]
    async fn duplicate_delivery_acknowledgements_are_immediately_due() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;
        let database = ctx.app_db.read().await.clone();
        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'peer')")
            .execute(&database.pool)
            .await?;
        for _ in 0..2 {
            let mut t = database.pool.begin().await?;
            queue_sender_delivery_receipt(&mut t, 7, "duplicate").await?;
            t.commit().await?;
            assert_eq!(
                due_receipt_ids(&database.pool, chrono::Utc::now().timestamp()).await?,
                ["duplicate"]
            );
            // Terminal replies are removed once the server accepts them. A
            // subsequent genuine duplicate can queue the same ACK immediately.
            Receipt::delete(&database.pool, "duplicate").await?;
        }
        assert!(!has_pending_receipts(&ctx).await?);
        Ok(())
    }

    #[tokio::test]
    async fn shutdown_flush_waits_for_the_active_flush() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;
        let mut guard = FlushGuard::claim(&ctx.queued_receipt_flush).unwrap();
        let waiting = {
            let ctx = ctx.clone();
            tokio::spawn(async move { retransmit_queued_receipts_and_wait(&ctx).await })
        };
        tokio::task::yield_now().await;
        assert!(!waiting.is_finished());
        assert!(
            guard.release_or_take_dirty(),
            "the waiter requested a final pass"
        );
        assert!(!waiting.is_finished());
        assert!(!guard.release_or_take_dirty());
        tokio::time::timeout(std::time::Duration::from_secs(1), waiting)
            .await
            .unwrap()
            .unwrap()?;
        Ok(())
    }

    #[tokio::test]
    async fn cancelling_an_active_flush_wakes_every_shutdown_waiter() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;
        let (started, ready) = tokio::sync::oneshot::channel();
        let active = {
            let ctx = ctx.clone();
            tokio::spawn(async move {
                let guard = FlushGuard::claim(&ctx.queued_receipt_flush).unwrap();
                started.send(()).unwrap();
                std::future::pending::<()>().await;
                drop(guard);
            })
        };
        ready.await.unwrap();
        let mut waiters = Vec::new();
        for _ in 0..3 {
            let ctx = ctx.clone();
            waiters.push(tokio::spawn(async move {
                retransmit_queued_receipts_and_wait(&ctx).await
            }));
        }
        tokio::task::yield_now().await;
        assert!(waiters.iter().all(|waiter| !waiter.is_finished()));
        active.abort();
        for waiter in waiters {
            tokio::time::timeout(std::time::Duration::from_secs(1), waiter)
                .await
                .unwrap()
                .unwrap()?;
        }
        assert!(FlushGuard::claim(&ctx.queued_receipt_flush).is_some());
        Ok(())
    }

    #[tokio::test]
    async fn server_acknowledgements_resolve_the_game_announcement_without_a_cascading_link(
    ) -> Result<()> {
        let directory = tempfile::tempdir()?;
        let path = directory.path().join("app.sqlite");
        let database =
            crate::database::app::AppDatabase::new(path.to_str().unwrap(), None, false).await?;
        database.run_migrations().await?;
        let mut tx = database.pool.begin().await?;
        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'ben')")
            .execute(&mut *tx)
            .await?;
        sqlx::query("INSERT INTO groups(group_id, group_name) VALUES ('g', 'Games')")
            .execute(&mut *tx)
            .await?;
        sqlx::query("INSERT INTO messages(message_id, group_id, type, content) VALUES ('update-info', 'g', 'text', 'Your turn')").execute(&mut *tx).await?;
        let data = proto::AdditionalMessageData {
            webxdc_update: Some(proto::WebxdcUpdate {
                instance_id: "card".into(),
                payload: "{}".into(),
                info: Some("Your turn".into()),
                ..Default::default()
            }),
            ..Default::default()
        };
        let receipt_id = queue_encrypted_content(
            &mut tx,
            7,
            proto::EncryptedContent {
                group_id: Some("g".into()),
                additional_data_message: Some(proto::encrypted_content::AdditionalDataMessage {
                    sender_message_id: "update".into(),
                    hidden: true,
                    additional_message_data: Some(data.encode_to_vec()),
                    ..Default::default()
                }),
                ..Default::default()
            },
            true,
        )
        .await?;
        tx.commit().await?;
        let row = load_queued_receipt_row(&database.pool, &receipt_id)
            .await?
            .unwrap();
        assert_eq!(row.message_id.as_deref(), Some("update-info"));
        // The actual outbox stays independent of the chat deletion timer.
        sqlx::query("DELETE FROM messages WHERE message_id = 'update-info'")
            .execute(&database.pool)
            .await?;
        let row = load_queued_receipt_row(&database.pool, &receipt_id)
            .await?
            .unwrap();
        assert_eq!(row.message_id, None);
        Ok(())
    }

    #[tokio::test]
    async fn live_location_receipts_can_be_requeued_without_losing_their_outbox_link() -> Result<()>
    {
        let directory = tempfile::tempdir()?;
        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;
        let database = ctx.app_db.read().await.clone();
        for statement in [
            "INSERT INTO contacts(user_id, username) VALUES (7, 'alice')",
            "INSERT INTO groups(group_id, group_name) VALUES ('chat', 'Chat')",
            "INSERT INTO messages(message_id, group_id, type) VALUES ('location', 'chat', 'text')",
        ] {
            sqlx::query(statement).execute(&database.pool).await?;
        }
        for reset in [false, true] {
            let mut t = database.pool.begin().await?;
            NewReceipt::new("old-receipt", 7, b"queued update")
                .insert(&mut t)
                .await?;
            sqlx::query("INSERT INTO live_location_outbox(receipt_id, message_id) VALUES ('old-receipt', 'location')")
                .execute(&mut *t).await?;
            let rebuild = handle_plaintext_content(
                &ctx,
                &mut t,
                7,
                "old-receipt",
                proto::PlaintextContent {
                    decryption_error_message: reset.then_some(
                        proto::plaintext_content::DecryptionErrorMessage {
                            r#type: proto::plaintext_content::decryption_error_message::Type::SessionResetRequired as i32,
                        },
                    ),
                    retry_control_error: (!reset).then_some(proto::plaintext_content::RetryErrorMessage {}),
                },
            )
            .await?;
            assert_eq!(rebuild, reset);
            t.commit().await?;

            let (receipt_id, message_id, retry_count, deferred): (String, String, i64, Option<i64>) = sqlx::query_as(
                "SELECT r.receipt_id, l.message_id, r.retry_count, r.deferred_until_session FROM receipts r JOIN live_location_outbox l ON l.receipt_id = r.receipt_id",
            )
            .fetch_one(&database.pool)
            .await?;
            assert_ne!(receipt_id, "old-receipt");
            assert_eq!(message_id, "location");
            assert_eq!(retry_count, 1);
            assert_eq!(deferred.is_some(), reset);
            sqlx::query("DELETE FROM receipts WHERE receipt_id = ?")
                .bind(receipt_id)
                .execute(&database.pool)
                .await?;
            let remaining: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM live_location_outbox")
                .fetch_one(&database.pool)
                .await?;
            assert_eq!(remaining, 0);
        }
        Ok(())
    }

    #[test]
    fn a_second_flush_request_marks_the_running_one_dirty() {
        let state = FlushClaim::default();
        let mut guard = FlushGuard::claim(&state).expect("nothing else holds the claim");
        assert!(FlushGuard::claim(&state).is_none());

        // The running flush sees the dirty flag and keeps its claim.
        assert!(guard.release_or_take_dirty());
        // Nothing arrived during the second pass, so the claim is released.
        assert!(!guard.release_or_take_dirty());

        // Dropping a guard that never released frees the claim too, so an
        // error on the way out cannot block every later flush.
        let guard = FlushGuard::claim(&state).expect("the claim was released");
        drop(guard);
        assert!(FlushGuard::claim(&state).is_some());
    }

    /// Two accounts in one process each flush their own queue. A claim held
    /// for one must not turn the other's flush into a no-op.
    #[test]
    fn each_account_holds_its_own_flush_claim() {
        let first = FlushClaim::default();
        let second = FlushClaim::default();

        let _held = FlushGuard::claim(&first).expect("nothing else holds the claim");
        assert!(FlushGuard::claim(&second).is_some());
    }

    #[tokio::test]
    async fn a_duplicate_decryption_failure_cannot_downgrade_a_queued_session_reset() {
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

        let mut transaction = database.pool.begin().await.unwrap();
        queue_decryption_error(
            &mut transaction,
            7,
            "failed-receipt",
            proto::plaintext_content::decryption_error_message::Type::SessionResetRequired as i32,
        )
        .await
        .unwrap();
        // A redelivery reaches the reset limiter while the first response is
        // still queued and falls back to Unknown. It must leave the stronger
        // response untouched.
        queue_decryption_error(
            &mut transaction,
            7,
            "failed-receipt",
            proto::plaintext_content::decryption_error_message::Type::Unknown as i32,
        )
        .await
        .unwrap();
        transaction.commit().await.unwrap();

        let bytes = sqlx::query_scalar::<_, Vec<u8>>(
            "SELECT message FROM receipts WHERE receipt_id = 'failed-receipt'",
        )
        .fetch_one(&database.pool)
        .await
        .unwrap();
        let message = proto::Message::decode(bytes.as_slice()).unwrap();
        let error = message
            .plaintext_content
            .and_then(|content| content.decryption_error_message)
            .expect("the queued response is a decryption error");
        assert_eq!(
            error.r#type,
            proto::plaintext_content::decryption_error_message::Type::SessionResetRequired as i32
        );
    }
}
