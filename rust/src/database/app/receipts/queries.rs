use super::table::Receipt;
use crate::error::Result;
use sqlx::SqliteConnection;

// Retain one canonical native model, including Rust-only delivery state.

pub async fn get(connection: &mut SqliteConnection, id: &str) -> Result<Option<Receipt>> {
    Ok(sqlx::query_as!(
        Receipt,
        r#"
            SELECT
            receipt_id AS "receipt_id!",
                contact_id AS "contact_id!",
                message_id AS "message_id?",
                message AS "message!",
                contact_will_sends_receipt AS "contact_will_sends_receipt!",
                will_be_retried_by_media_upload AS "will_be_retried_by_media_upload!",
                mark_for_retry AS "mark_for_retry?",
                mark_for_retry_after_accepted AS "mark_for_retry_after_accepted?",
                ack_by_server_at AS "ack_by_server_at?",
                retry_count AS "retry_count!",
                last_retry AS "last_retry?",
                created_at AS "created_at!",
                wake_receiver AS "wake_receiver!"
            FROM receipts WHERE receipt_id = ?
        "#,
        id,
    )
    .fetch_optional(connection)
    .await?)
}

pub async fn list(connection: &mut SqliteConnection) -> Result<Vec<Receipt>> {
    Ok(sqlx::query_as!(
        Receipt,
        r#"
            SELECT
            receipt_id AS "receipt_id!",
                contact_id AS "contact_id!",
                message_id AS "message_id?",
                message AS "message!",
                contact_will_sends_receipt AS "contact_will_sends_receipt!",
                will_be_retried_by_media_upload AS "will_be_retried_by_media_upload!",
                mark_for_retry AS "mark_for_retry?",
                mark_for_retry_after_accepted AS "mark_for_retry_after_accepted?",
                ack_by_server_at AS "ack_by_server_at?",
                retry_count AS "retry_count!",
                last_retry AS "last_retry?",
                created_at AS "created_at!",
                wake_receiver AS "wake_receiver!"
            FROM receipts ORDER BY rowid
        "#,
    )
    .fetch_all(connection)
    .await?)
}

pub async fn media_retransmissions(
    connection: &mut SqliteConnection, cutoff: i64,
) -> Result<Vec<Receipt>> {
    Ok(sqlx::query_as!(
        Receipt,
        r#"
            SELECT
            receipt_id AS "receipt_id!",
                contact_id AS "contact_id!",
                message_id AS "message_id?",
                message AS "message!",
                contact_will_sends_receipt AS "contact_will_sends_receipt!",
                will_be_retried_by_media_upload AS "will_be_retried_by_media_upload!",
                mark_for_retry AS "mark_for_retry?",
                mark_for_retry_after_accepted AS "mark_for_retry_after_accepted?",
                ack_by_server_at AS "ack_by_server_at?",
                retry_count AS "retry_count!",
                last_retry AS "last_retry?",
                created_at AS "created_at!",
                wake_receiver AS "wake_receiver!"
            FROM receipts
            WHERE mark_for_retry < ?
                AND mark_for_retry_after_accepted IS NULL
                AND will_be_retried_by_media_upload = 1
            ORDER BY rowid
        "#,
        cutoff,
    )
    .fetch_all(connection)
    .await?)
}
