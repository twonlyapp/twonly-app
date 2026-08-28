/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::error::Result;
use sqlx::{Sqlite, Transaction};

#[derive(sqlx::FromRow, Debug, Clone)]
pub struct Receipt {
    pub receipt_id: String,
    pub contact_id: i64,
    pub message_id: Option<String>,
    pub message: Vec<u8>,
    pub contact_will_sends_receipt: i64,
    pub will_be_retried_by_media_upload: i64,
    pub mark_for_retry: Option<i64>,
    pub mark_for_retry_after_accepted: Option<i64>,
    pub ack_by_server_at: Option<i64>,
    pub retry_count: i64,
    pub last_retry: Option<i64>,
    pub created_at: i64,
}
pub struct NewReceipt<'a> {
    receipt_id: &'a str,
    contact_id: i64,
    message: &'a [u8],
    contact_will_send_receipt: bool,
}

impl Receipt {
    pub async fn insert_reaction(
        transaction: &mut Transaction<'_, Sqlite>,
        message_id: &str,
        sender_id: i64,
        emoji: &str,
    ) -> Result<()> {
        sqlx::query!(
            r#"
            INSERT INTO reactions(message_id, emoji, sender_id)
            VALUES (?, ?, ?)
            ON CONFLICT(message_id, sender_id, emoji) DO NOTHING
            "#,
            message_id,
            emoji,
            sender_id,
        )
        .execute(&mut **transaction)
        .await?;

        Ok(())
    }

    pub async fn delete_reaction(
        transaction: &mut Transaction<'_, Sqlite>,
        message_id: &str,
        sender_id: i64,
        emoji: &str,
    ) -> Result<()> {
        sqlx::query!(
            r#"
            DELETE FROM reactions
            WHERE message_id = ? AND sender_id = ? AND emoji = ?
            "#,
            message_id,
            sender_id,
            emoji,
        )
        .execute(&mut **transaction)
        .await?;

        Ok(())
    }

    pub async fn claim_received(
        transaction: &mut Transaction<'_, Sqlite>,
        receipt_id: &str,
    ) -> Result<bool> {
        let claimed = sqlx::query!(
            r#"
            INSERT INTO received_receipts(receipt_id)
            VALUES (?)
            ON CONFLICT(receipt_id) DO NOTHING
            "#,
            receipt_id,
        )
        .execute(&mut **transaction)
        .await?
        .rows_affected()
            != 0;

        Ok(claimed)
    }

    pub async fn claim_received_retry(
        transaction: &mut Transaction<'_, Sqlite>,
        receipt_id: &str,
    ) -> Result<bool> {
        let claimed = sqlx::query!(
            r#"
            UPDATE received_receipts
            SET created_at = CAST(strftime('%s', 'now') AS INTEGER)
            WHERE receipt_id = ?
              AND created_at <= CAST(strftime('%s', 'now') AS INTEGER) - 864000
            "#,
            receipt_id,
        )
        .execute(&mut **transaction)
        .await?
        .rows_affected()
            != 0;

        Ok(claimed)
    }

    pub async fn mark_all_for_retry(
        transaction: &mut Transaction<'_, Sqlite>,
        contact_id: i64,
    ) -> Result<()> {
        sqlx::query!(
            r#"
            UPDATE receipts
            SET mark_for_retry = CAST(strftime('%s', 'now') AS INTEGER)
            WHERE contact_id = ? AND mark_for_retry IS NULL
            "#,
            contact_id,
        )
        .execute(&mut **transaction)
        .await?;

        Ok(())
    }

    pub async fn delete<'c, E>(executor: E, receipt_id: &str) -> Result<()>
    where
        E: sqlx::Executor<'c, Database = Sqlite>,
    {
        sqlx::query!("DELETE FROM receipts WHERE receipt_id = ?", receipt_id)
            .execute(executor)
            .await?;
        Ok(())
    }
}

impl<'a> NewReceipt<'a> {
    pub fn new(receipt_id: &'a str, contact_id: i64, message: &'a [u8]) -> Self {
        Self {
            receipt_id,
            contact_id,
            message,
            contact_will_send_receipt: true,
        }
    }

    pub fn contact_will_send_receipt(mut self, val: bool) -> Self {
        self.contact_will_send_receipt = val;
        self
    }

    pub async fn insert(&self, transaction: &mut Transaction<'_, Sqlite>) -> Result<()> {
        sqlx::query!(
            r#"
            INSERT INTO receipts(receipt_id, contact_id, message, contact_will_sends_receipt)
            VALUES (?, ?, ?, ?)
            "#,
            self.receipt_id,
            self.contact_id,
            self.message,
            self.contact_will_send_receipt,
        )
        .execute(&mut **transaction)
        .await?;

        Ok(())
    }

    pub async fn insert_or_replace(&self, transaction: &mut Transaction<'_, Sqlite>) -> Result<()> {
        sqlx::query!(
            r#"
            INSERT OR REPLACE INTO receipts(receipt_id, contact_id, message, contact_will_sends_receipt)
            VALUES (?, ?, ?, ?)
            "#,
            self.receipt_id,
            self.contact_id,
            self.message,
            self.contact_will_send_receipt,
        )
        .execute(&mut **transaction)
        .await?;

        Ok(())
    }
}
