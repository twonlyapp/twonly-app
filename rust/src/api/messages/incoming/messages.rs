/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::handle_encrypted;
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
use std::sync::Arc;

#[cfg(not(debug_assertions))]
use std::{collections::HashMap, sync::LazyLock};

#[cfg(not(debug_assertions))]
static ALREADY_QUEUED_RECEIPTS: LazyLock<std::sync::Mutex<HashMap<String, std::time::Instant>>> =
    LazyLock::new(|| std::sync::Mutex::new(HashMap::new()));

pub(crate) async fn queue_encrypted_content(
    t: &mut Transaction<'_, Sqlite>,
    target_user_id: i64,
    content: proto::EncryptedContent,
    contact_will_send_receipt: bool,
) -> Result<String> {
    Contact::ensure_exists(t, target_user_id).await?;

    let wake_receiver = crate::services::notifications::should_wake_receiver(&content);

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

    Ok(receipt_id)
}

pub(crate) async fn process_encrypted_or_queue_error(
    ctx: &Arc<Context>,
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    receipt_id: &str,
    content: proto::EncryptedContent,
) -> Result<Option<String>> {
    let group_id = content.group_id.clone();

    match handle_encrypted(ctx, t, from_user_id, receipt_id, content).await {
        Ok(()) => Ok(None),
        Err(error) => {
            let description = error.to_string();
            if description.contains("group join arrived before") {
                queue_retry_control(t, from_user_id, receipt_id).await?;
                return Ok(Some(receipt_id.to_owned()));
            }

            let error_type = if description.contains("not a member") {
                Some(Type::GroupNotFoundOrNotAMember)
            } else if description.contains("not implemented in Rust") {
                Some(Type::UnknownMessageType)
            } else {
                None
            };

            let Some(error_type) = error_type else {
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

            Ok(Some(outgoing_receipt_id))
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
}

async fn load_queued_receipt_row(
    pool: &sqlx::SqlitePool,
    receipt_id: &str,
) -> Result<Option<PreparedQueuedReceiptRow>> {
    Ok(sqlx::query_as!(
        PreparedQueuedReceiptRow,
        r#"
        SELECT r.contact_id, r.message, r.message_id, r.contact_will_sends_receipt,
               r.wake_receiver, c.account_deleted, c.signal_version
        FROM receipts r
        JOIN contacts c ON c.user_id = r.contact_id
        WHERE r.receipt_id = ?
        "#,
        receipt_id,
    )
    .fetch_optional(pool)
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
    #[cfg(not(debug_assertions))]
    {
        let mut locks = ALREADY_QUEUED_RECEIPTS.lock().unwrap();
        if let Some(time) = locks.get(receipt_id) {
            if time.elapsed() < std::time::Duration::from_secs(120) {
                tracing::info!(
                    "Blocking queued receipt, as it was already sent within the last 120 seconds"
                );
                return Ok(());
            }
        }
        locks.insert(receipt_id.to_owned(), std::time::Instant::now());
        locks.retain(|_, time| time.elapsed() < std::time::Duration::from_secs(120));
    }

    let app_db = ctx.app_db.read().await.clone();
    let Some(row) = load_queued_receipt_row(&app_db.pool, receipt_id).await? else {
        return Ok(());
    };

    // The server has no account for this contact any more, so preparing the
    // payload would only fetch a prekey bundle that answers `UserIdNotFound`
    // on every retry. Drop the receipt instead of queueing it forever.
    if row.account_deleted != 0 {
        Receipt::delete(&app_db.pool, receipt_id).await?;
        return Ok(());
    }

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

    let mut t = app_db.pool.begin().await?;
    if let Some(message_id) = receipt.message_id {
        sqlx::query!(
            r#"
            INSERT INTO message_actions(message_id, contact_id, type)
            VALUES (?, ?, 'ackByServerAt')
            ON CONFLICT(message_id, contact_id, type)
            DO UPDATE SET action_at = CAST(strftime('%s', 'now') AS INTEGER)
            "#,
            message_id,
            receipt.contact_id,
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
        Receipt::delete(&mut *t, receipt_id).await?;
    } else {
        sqlx::query!(
            r#"
            UPDATE receipts SET
                ack_by_server_at = CAST(strftime('%s', 'now') AS INTEGER),
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
    let database = ctx.app_db.read().await.clone();
    let receipt_ids = sqlx::query_scalar!(
        r#"
        SELECT receipt_id FROM receipts
        WHERE will_be_retried_by_media_upload = 0
          AND deferred_until_session IS NULL
          AND (ack_by_server_at IS NULL OR mark_for_retry IS NOT NULL)
          AND (mark_for_retry_after_accepted IS NULL OR EXISTS(
              SELECT 1 FROM contacts
              WHERE contacts.user_id = receipts.contact_id AND contacts.accepted = 1
          ))
        ORDER BY created_at
        "#
    )
    .fetch_all(&database.pool)
    .await?;
    for receipt_id in receipt_ids {
        if let Err(error) = send_queued_receipt(ctx, &receipt_id).await {
            tracing::warn!(receipt_id, "queued delivery receipt retry failed: {error}");
        }
    }
    Ok(())
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
        .insert_or_replace(tr)
        .await?;
    Ok(())
}

pub(crate) async fn handle_sender_delivery_receipt(
    transaction: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    receipt_id: &str,
) -> Result<()> {
    let message_id = sqlx::query_scalar!(
        r#"
        SELECT message_id
        FROM receipts
        WHERE receipt_id = ? AND contact_id = ?
        "#,
        receipt_id,
        from_user_id,
    )
    .fetch_optional(&mut **transaction)
    .await?
    .flatten();

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

pub async fn handle_plaintext_content(
    _ctx: &Context,
    transaction: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    receipt_id: &str,
    plaintext: proto::PlaintextContent,
) -> Result<Option<String>> {
    if plaintext.decryption_error_message.is_some() || plaintext.retry_control_error.is_some() {
        let new_receipt_id = uuid::Uuid::new_v4().to_string();
        sqlx::query!(
            r#"
            UPDATE receipts
            SET receipt_id = ?,
                mark_for_retry = CAST(strftime('%s', 'now') AS INTEGER),
                retry_count = retry_count + 1,
                ack_by_server_at = NULL
            WHERE receipt_id = ? AND contact_id = ?
            "#,
            new_receipt_id,
            receipt_id,
            from_user_id,
        )
        .execute(&mut **transaction)
        .await?;
        return Ok(Some(new_receipt_id));
    }
    Ok(None)
}
