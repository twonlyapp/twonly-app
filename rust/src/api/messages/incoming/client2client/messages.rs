/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::handle_encrypted;
use crate::api::proto::client::{self as proto, encrypted_content};

use crate::api::Server;
use crate::bridge::api::ServerResult;
use crate::bridge::callbacks::get_callbacks;
use crate::context::Context;
use crate::database::app::tables::{Contact, NewReceipt, Receipt};
use crate::error::{twonly_error, Result, TwonlyError};
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

async fn native_push_data(
    _ctx: &Context,
    contact_id: i64,
    message_id: Option<String>,
    plaintext: &[u8],
    message_type: i32,
) -> Result<Option<Vec<u8>>> {
    let callbacks = match get_callbacks() {
        Ok(callbacks) => callbacks,
        Err(TwonlyError::MissingCallbackInitialization) => {
            return Ok(None);
        }
        Err(error) => return Err(error),
    };
    Ok(
        (callbacks.api.create_push_data)(contact_id, message_id, plaintext.to_vec(), message_type)
            .await,
    )
}

pub(crate) async fn queue_encrypted_content(
    transaction: &mut Transaction<'_, Sqlite>,
    target_user_id: i64,
    content: proto::EncryptedContent,
    contact_will_send_receipt: bool,
) -> Result<String> {
    let Ok(Some(contact)) = Contact::get_contact_by_id(transaction, target_user_id).await else {
        return Err(twonly_error!("missing contact"));
    };

    let message = proto::Message {
        r#type: if contact.signal_version == "v2" {
            proto::message::Type::CiphertextV2 as i32
        } else {
            proto::message::Type::Ciphertext as i32
        },
        receipt_id: String::new(),
        encrypted_content: Some(content.encode_to_vec()),
        plaintext_content: None,
    }
    .encode_to_vec();

    let receipt_id = new_uuid_v4();
    NewReceipt::new(&receipt_id, target_user_id, &message)
        .contact_will_send_receipt(contact_will_send_receipt)
        .insert(transaction)
        .await?;

    Ok(receipt_id)
}

pub(crate) async fn process_encrypted_or_queue_error(
    ctx: &Arc<Context>,
    tr: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    receipt_id: &str,
    content: proto::EncryptedContent,
) -> Result<Option<String>> {
    let group_id = content.group_id.clone();

    match handle_encrypted(ctx, tr, from_user_id, receipt_id, content).await {
        Ok(()) => Ok(None),
        Err(error) => {
            let description = error.to_string();
            if description.contains("group join arrived before") {
                queue_retry_control(tr, from_user_id, receipt_id).await?;
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
            let outgoing_receipt_id = uuid::Uuid::new_v4().to_string();
            let response_content = proto::EncryptedContent {
                group_id,
                error_messages: Some(proto::encrypted_content::ErrorMessages {
                    r#type: error_type as i32,
                    related_receipt_id: receipt_id.to_owned(),
                }),
                ..Default::default()
            };
            let response = proto::Message {
                r#type: proto::message::Type::Ciphertext as i32,
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
            .execute(&mut **tr)
            .await?;
            Ok(Some(outgoing_receipt_id))
        }
    }
}

async fn queue_retry_control(
    transaction: &mut Transaction<'_, Sqlite>,
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
    .execute(&mut **transaction)
    .await?;
    Ok(())
}

pub(crate) async fn ensure_contact_exists(ctx: &Arc<Context>, from_user_id: i64) -> Result<()> {
    let db_app = ctx.get_app_database().await;

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

    sqlx::query!(
        r#"
        INSERT OR IGNORE INTO contacts(user_id, username, signal_version, accepted, requested)
        VALUES (?, ?, ?, 0, 1)
        "#,
        from_user_id,
        username,
        signal_version,
    )
    .execute(&db_app.pool)
    .await?;

    if let Some(identity_key) = user.public_identity_key {
        let rust_database = ctx.get_rust_db().await;
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

    db_app.notify_committed(["contacts"]);
    Ok(())
}

pub(crate) async fn queue_sender_delivery_receipt(
    transaction: &mut Transaction<'_, Sqlite>,
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
    .execute(&mut **transaction)
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

    let app_db = ctx.get_app_database().await;
    let row = sqlx::query!(
        r#"
        SELECT r.contact_id, r.message, r.message_id, r.contact_will_sends_receipt,
               r.retry_count, c.account_deleted
        FROM receipts r
        JOIN contacts c ON c.user_id = r.contact_id
        WHERE r.receipt_id = ?
        "#,
        receipt_id,
    )
    .fetch_optional(&app_db.pool)
    .await?;

    let Some(row) = row else {
        return Ok(());
    };

    if row.account_deleted != 0 {
        Receipt::delete(&app_db.pool, receipt_id).await?;
        app_db.notify_committed(["receipts"]);
        return Ok(());
    }

    let mut message = proto::Message::decode(row.message.as_slice())?;
    message.receipt_id = receipt_id.to_owned();

    let message_type = proto::message::Type::try_from(message.r#type)?;

    let push_data = if row.retry_count == 0 {
        native_push_data(
            ctx,
            row.contact_id,
            row.message_id.clone(),
            &message.encrypted_content.clone().unwrap_or_default(),
            message.r#type,
        )
        .await?
    } else {
        None
    };

    match message_type {
        proto::message::Type::Ciphertext | proto::message::Type::PrekeyBundle => {
            let plaintext = message.encrypted_content.take().ok_or_else(|| {
                TwonlyError::Generic("queued legacy message has no plaintext".into())
            })?;
            let (ciphertext, encrypted_type) =
                encrypt_legacy_signal(row.contact_id, plaintext).await?;
            message.encrypted_content = Some(ciphertext);
            message.r#type = encrypted_type;
        }
        proto::message::Type::CiphertextV2 => {
            let plaintext = message
                .encrypted_content
                .take()
                .ok_or_else(|| TwonlyError::Generic("queued V2 message has no plaintext".into()))?;
            let engine = ctx.get_signal_engine().lock().await;
            message.encrypted_content = Some(
                engine
                    .as_ref()
                    .ok_or(TwonlyError::SignalIdentityNotFound)?
                    .encrypt_message(row.contact_id.to_string(), 1, plaintext)
                    .await?,
            );
        }
        _ => {}
    }

    match Server::send_text_message(ctx, row.contact_id, message.encode_to_vec(), push_data).await?
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
    if let Some(message_id) = row.message_id {
        sqlx::query!(
            r#"
            INSERT INTO message_actions(message_id, contact_id, type)
            VALUES (?, ?, 'ackByServerAt')
            ON CONFLICT(message_id, contact_id, type)
            DO UPDATE SET action_at = CAST(strftime('%s', 'now') AS INTEGER)
            "#,
            message_id,
            row.contact_id,
        )
        .execute(&mut *t)
        .await?;
    }
    if row.contact_will_sends_receipt == 0 {
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
    app_db.notify_committed(["receipts", "message_actions"]);
    Ok(())
}

pub(crate) async fn prepare_queued_receipt(
    ctx: &Context,
    receipt_id: &str,
) -> Result<Option<(Vec<u8>, Option<Vec<u8>>)>> {
    let database = ctx.get_app_database().await;
    let row = sqlx::query!(
        r#"SELECT contact_id, message, message_id, retry_count
           FROM receipts WHERE receipt_id = ?"#,
        receipt_id,
    )
    .fetch_optional(&database.pool)
    .await?;
    let Some(row) = row else { return Ok(None) };
    let mut message = proto::Message::decode(row.message.as_slice())
        .map_err(|error| TwonlyError::Generic(format!("invalid queued message: {error}")))?;
    message.receipt_id = receipt_id.to_owned();
    let push_data = if row.retry_count == 0 {
        native_push_data(
            ctx,
            row.contact_id,
            row.message_id,
            &message.encrypted_content.clone().unwrap_or_default(),
            message.r#type,
        )
        .await?
    } else {
        None
    };

    match proto::message::Type::try_from(message.r#type)
        .map_err(|_| TwonlyError::Generic("queued message has invalid type".into()))?
    {
        proto::message::Type::Ciphertext => {
            let plaintext = message
                .encrypted_content
                .take()
                .ok_or_else(|| TwonlyError::Generic("queued message has no content".into()))?;

            let (ciphertext, message_type) =
                encrypt_legacy_signal(row.contact_id, plaintext).await?;

            message.encrypted_content = Some(ciphertext);
            message.r#type = message_type;
        }
        proto::message::Type::CiphertextV2 => {
            let plaintext = message
                .encrypted_content
                .take()
                .ok_or_else(|| TwonlyError::Generic("queued message has no content".into()))?;

            let engine = ctx.get_signal_engine().lock().await;

            message.encrypted_content = Some(
                engine
                    .as_ref()
                    .ok_or(TwonlyError::SignalIdentityNotFound)?
                    .encrypt_message(row.contact_id.to_string(), 1, plaintext)
                    .await?,
            );
        }
        _ => {}
    }
    Ok(Some((message.encode_to_vec(), push_data)))
}

pub(crate) async fn retransmit_queued_receipts(ctx: &Arc<Context>) -> Result<()> {
    let database = ctx.get_app_database().await;
    let receipt_ids = sqlx::query_scalar!(
        r#"
        SELECT receipt_id FROM receipts
        WHERE will_be_retried_by_media_upload = 0
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

pub(crate) async fn decrypt_legacy_signal_with_error(
    from_user_id: i64,
    ciphertext: Vec<u8>,
    message_type: i32,
) -> Result<core::result::Result<proto::EncryptedContent, i32>> {
    let callbacks = get_callbacks()?;
    let decrypted = (callbacks.legacy_signal.decrypt)(from_user_id, ciphertext, message_type).await;

    let Some(plaintext) = decrypted.plaintext else {
        return Ok(Err(decrypted.decryption_error_type.unwrap_or(0)));
    };

    proto::EncryptedContent::decode(plaintext.as_slice())
        .map(Ok)
        .map_err(|error| {
            TwonlyError::Generic(format!(
                "Flutter returned invalid legacy Signal plaintext: {error}"
            ))
        })
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

pub(crate) async fn encrypt_legacy_signal(
    target_user_id: i64,
    plaintext: Vec<u8>,
) -> Result<(Vec<u8>, i32)> {
    let callbacks = get_callbacks()?;
    let encrypted = (callbacks.legacy_signal.encrypt)(target_user_id, plaintext)
        .await
        .ok_or_else(|| TwonlyError::Generic("Flutter legacy Signal encryption failed".into()))?;
    if !is_legacy_signal_type(encrypted.message_type) {
        return Err(TwonlyError::Generic(format!(
            "Flutter returned non-legacy Signal message type {}",
            encrypted.message_type
        )));
    }
    Ok((encrypted.ciphertext, encrypted.message_type))
}

fn is_legacy_signal_type(message_type: i32) -> bool {
    use proto::message::Type;
    message_type == Type::Ciphertext as i32 || message_type == Type::PrekeyBundle as i32
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

pub(crate) async fn handle_message_update(
    transaction: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    update: encrypted_content::MessageUpdate,
) -> Result<()> {
    use encrypted_content::message_update::Type;
    let timestamp = crate::utils::milliseconds_to_seconds(update.timestamp);

    match Type::try_from(update.r#type)
        .map_err(|_| TwonlyError::Generic("invalid message update".into()))?
    {
        Type::Opened => {
            for message_id in update.multiple_target_message_ids {
                let action_at = sqlx::query_scalar::<_, i64>(
                    "SELECT MAX(created_at, ?) FROM messages WHERE message_id = ?",
                )
                .bind(timestamp)
                .bind(&message_id)
                .fetch_optional(&mut **transaction)
                .await?;
                let Some(action_at) = action_at else { continue };
                sqlx::query!(
                    r#"
                    INSERT INTO message_actions(message_id, contact_id, type, action_at)
                    VALUES (?, ?, 'openedAt', ?)
                    ON CONFLICT(message_id, contact_id, type)
                    DO UPDATE SET action_at = excluded.action_at
                    "#,
                    message_id,
                    from_user_id,
                    action_at,
                )
                .execute(&mut **transaction)
                .await?;
                sqlx::query!(
                    r#"UPDATE messages SET opened_at = ?, opened_by_all = CASE WHEN NOT EXISTS(
                           SELECT 1 FROM group_members gm
                           WHERE gm.group_id = messages.group_id AND NOT EXISTS(
                               SELECT 1 FROM message_actions ma
                               WHERE ma.message_id = messages.message_id
                                 AND ma.contact_id = gm.contact_id AND ma.type = 'openedAt'
                           )
                       ) THEN ? ELSE NULL END
                       WHERE message_id = ?"#,
                    action_at,
                    action_at,
                    message_id,
                )
                .execute(&mut **transaction)
                .await?;
            }
        }
        Type::Delete => {
            let media_id = sqlx::query_scalar!(
                "SELECT media_id FROM messages WHERE message_id = ? AND sender_id = ?",
                update.sender_message_id,
                from_user_id,
            )
            .fetch_optional(&mut **transaction)
            .await?
            .flatten();
            sqlx::query!(
                "DELETE FROM message_histories WHERE message_id = ?",
                update.sender_message_id
            )
            .execute(&mut **transaction)
            .await?;
            sqlx::query!(
                "DELETE FROM receipts WHERE message_id = ?",
                update.sender_message_id
            )
            .execute(&mut **transaction)
            .await?;
            sqlx::query!(
                r#"
                UPDATE messages
                SET is_deleted_from_sender = 1, content = NULL, media_id = NULL, modified_at = ?
                WHERE message_id = ? AND sender_id = ?
                "#,
                timestamp,
                update.sender_message_id,
                from_user_id,
            )
            .execute(&mut **transaction)
            .await?;
            if let Some(media_id) = media_id {
                let references = sqlx::query_scalar!(
                    "SELECT COUNT(*) FROM messages WHERE media_id = ?",
                    media_id,
                )
                .fetch_one(&mut **transaction)
                .await?;
                if references == 0 {
                    sqlx::query!("DELETE FROM media_files WHERE media_id = ?", media_id)
                        .execute(&mut **transaction)
                        .await?;
                    if let Ok(callbacks) = get_callbacks() {
                        if let Some(message_id) = update.sender_message_id.clone() {
                            tokio::spawn(async move {
                                (callbacks.api.media_action)(
                                    "delete".into(),
                                    media_id,
                                    from_user_id,
                                    message_id,
                                )
                                .await;
                            });
                        }
                    }
                }
            }
        }
        Type::EditText => {
            sqlx::query!(
                r#"INSERT INTO message_histories(message_id, content, created_at)
                   SELECT message_id, content, ? FROM messages
                   WHERE message_id = ? AND sender_id = ? AND content IS NOT NULL"#,
                timestamp,
                update.sender_message_id,
                from_user_id,
            )
            .execute(&mut **transaction)
            .await?;
            sqlx::query!(
                r#"
                UPDATE messages
                SET content = ?, modified_at = ?
                WHERE message_id = ? AND sender_id = ? AND content IS NOT NULL
                "#,
                update.text,
                timestamp,
                update.sender_message_id,
                from_user_id,
            )
            .execute(&mut **transaction)
            .await?;
        }
    }
    Ok(())
}
