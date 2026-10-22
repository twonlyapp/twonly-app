use super::table::ReceiptPatch;
use crate::error::Result;
use sqlx::{Sqlite, Transaction};

#[derive(Clone, Copy)]

pub enum ReceiptTarget<'a> {
    Id(&'a str),
    Message(&'a str),
    Contact(i64),
    ContactMessage(i64, &'a str),
}

pub async fn delete(tx: &mut Transaction<'_, Sqlite>, selection: ReceiptTarget<'_>) -> Result<()> {
    macro_rules! delete {
        ($predicate:literal $(, $arg:expr)* $(,)?) => {
            sqlx::query!("DELETE FROM receipts " + $predicate, $($arg),*).execute(&mut **tx).await?
        };
    }

    match selection {
        ReceiptTarget::Id(id) => {
            delete!("WHERE receipt_id = ?", id);
        }
        ReceiptTarget::Message(id) => {
            delete!("WHERE message_id = ?", id);
        }
        ReceiptTarget::Contact(id) => {
            delete!("WHERE contact_id = ?", id);
        }
        ReceiptTarget::ContactMessage(contact, message) => {
            delete!("WHERE contact_id = ? AND message_id = ?", contact, message);
        }
    }

    Ok(())
}

pub async fn purge(tx: &mut Transaction<'_, Sqlite>, cutoff: i64) -> Result<()> {
    sqlx::query!(
        r#"
            DELETE FROM received_receipts WHERE created_at < ?
        "#,
        cutoff,
    )
    .execute(&mut **tx)
    .await?;

    sqlx::query!(
        r#"
            DELETE
            FROM receipts
            WHERE EXISTS (
                SELECT 1
                FROM contacts
                WHERE contacts.user_id = receipts.contact_id
                    AND contacts.account_deleted = 1
            )
        "#,
    )
    .execute(&mut **tx)
    .await?;

    Ok(())
}

pub async fn update(
    tx: &mut Transaction<'_, Sqlite>, selection: ReceiptTarget<'_>, patch: ReceiptPatch,
) -> Result<()> {
    if !(patch.receipt_id.is_some()
        || patch.contact_id.is_some()
        || patch.message_id.is_some()
        || patch.message.is_some()
        || patch.contact_will_sends_receipt.is_some()
        || patch.will_be_retried_by_media_upload.is_some()
        || patch.mark_for_retry.is_some()
        || patch.mark_for_retry_after_accepted.is_some()
        || patch.ack_by_server_at.is_some()
        || patch.retry_count.is_some()
        || patch.last_retry.is_some()
        || patch.created_at.is_some())
    {
        return Ok(());
    }

    macro_rules! update {
        ($predicate:literal $(, $arg:expr)* $(,)?) => {
            sqlx::query!(
                r#"
                    UPDATE receipts SET receipt_id = CASE WHEN ? THEN ? ELSE receipt_id END,
                    contact_id = CASE WHEN ? THEN ? ELSE contact_id END,
                    message_id = CASE WHEN ? THEN ? ELSE message_id END,
                    message = CASE WHEN ? THEN ? ELSE message END,
                    contact_will_sends_receipt = CASE WHEN ? THEN ? ELSE contact_will_sends_receipt END,
                    will_be_retried_by_media_upload = CASE WHEN ? THEN ? ELSE will_be_retried_by_media_upload END,
                    mark_for_retry = CASE WHEN ? THEN ? ELSE mark_for_retry END,
                    mark_for_retry_after_accepted = CASE WHEN ? THEN ? ELSE mark_for_retry_after_accepted END,
                    ack_by_server_at = CASE WHEN ? THEN ? ELSE ack_by_server_at END,
                    retry_count = CASE WHEN ? THEN ? ELSE retry_count END,
                    last_retry = CASE WHEN ? THEN ? ELSE last_retry END,
                    created_at = CASE WHEN ? THEN ? ELSE created_at END
                "# + $predicate,
                patch.receipt_id.is_some(),
                patch.receipt_id.as_deref(),
                patch.contact_id.is_some(),
                patch.contact_id,
                patch.message_id.is_some(),
                patch.message_id.as_ref().and_then(|value| value.value.as_deref()),
                patch.message.is_some(),
                patch.message.as_deref(),
                patch.contact_will_sends_receipt.is_some(),
                patch.contact_will_sends_receipt,
                patch.will_be_retried_by_media_upload.is_some(),
                patch.will_be_retried_by_media_upload,
                patch.mark_for_retry.is_some(),
                patch.mark_for_retry.as_ref().and_then(|value| value.value),
                patch.mark_for_retry_after_accepted.is_some(),
                patch.mark_for_retry_after_accepted.as_ref().and_then(|value| value.value),
                patch.ack_by_server_at.is_some(),
                patch.ack_by_server_at.as_ref().and_then(|value| value.value),
                patch.retry_count.is_some(),
                patch.retry_count,
                patch.last_retry.is_some(),
                patch.last_retry.as_ref().and_then(|value| value.value),
                patch.created_at.is_some(),
                patch.created_at,
                $($arg),*
            ).execute(&mut **tx).await?
        };
    }

    match selection {
        ReceiptTarget::Id(id) => {
            update!("WHERE receipt_id = ?", id);
        }
        ReceiptTarget::Message(id) => {
            update!("WHERE message_id = ?", id);
        }
        ReceiptTarget::Contact(id) => {
            update!("WHERE contact_id = ?", id);
        }
        ReceiptTarget::ContactMessage(contact, message) => {
            update!("WHERE contact_id = ? AND message_id = ?", contact, message);
        }
    }

    Ok(())
}
