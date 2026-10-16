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
    pub wake_receiver: i64,
}
pub struct NewReceipt<'a> {
    receipt_id: &'a str,
    contact_id: i64,
    message: &'a [u8],
    contact_will_send_receipt: bool,
    wake_receiver: bool,
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

    /// Parks the plaintext of an already-decrypted message on its receipt
    /// claim. Signal decryption is a one-shot operation — it advances the
    /// double ratchet in the signal database, outside this transaction — so the
    /// plaintext has to be committed together with the claim. A redelivery that
    /// finds it here resumes handling instead of decrypting again, which would
    /// fail with an old-counter error.
    pub async fn store_pending_plaintext(
        transaction: &mut Transaction<'_, Sqlite>,
        receipt_id: &str,
        plaintext: &[u8],
    ) -> Result<()> {
        sqlx::query!(
            r#"
            UPDATE received_receipts
            SET pending_plaintext = ?
            WHERE receipt_id = ?
            "#,
            plaintext,
            receipt_id,
        )
        .execute(&mut **transaction)
        .await?;

        Ok(())
    }

    /// Returns the parked plaintext of a receipt whose handling did not commit.
    pub async fn pending_plaintext(
        transaction: &mut Transaction<'_, Sqlite>,
        receipt_id: &str,
    ) -> Result<Option<Vec<u8>>> {
        let plaintext = sqlx::query_scalar!(
            r#"
            SELECT pending_plaintext
            FROM received_receipts
            WHERE receipt_id = ?
            "#,
            receipt_id,
        )
        .fetch_optional(&mut **transaction)
        .await?
        .flatten();

        Ok(plaintext)
    }

    /// Drops a parked plaintext once its message no longer needs it.
    pub async fn clear_pending_plaintext(
        transaction: &mut Transaction<'_, Sqlite>,
        receipt_id: &str,
    ) -> Result<()> {
        sqlx::query!(
            r#"
            UPDATE received_receipts
            SET pending_plaintext = NULL
            WHERE receipt_id = ? AND pending_plaintext IS NOT NULL
            "#,
            receipt_id,
        )
        .execute(&mut **transaction)
        .await?;

        Ok(())
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
            wake_receiver: false,
        }
    }

    pub fn contact_will_send_receipt(mut self, val: bool) -> Self {
        self.contact_will_send_receipt = val;
        self
    }

    pub fn wake_receiver(mut self, val: bool) -> Self {
        self.wake_receiver = val;
        self
    }

    pub async fn insert(&self, transaction: &mut Transaction<'_, Sqlite>) -> Result<()> {
        sqlx::query!(
            r#"
            INSERT INTO receipts(receipt_id, contact_id, message, contact_will_sends_receipt, wake_receiver)
            VALUES (?, ?, ?, ?, ?)
            "#,
            self.receipt_id,
            self.contact_id,
            self.message,
            self.contact_will_send_receipt,
            self.wake_receiver,
        )
        .execute(&mut **transaction)
        .await?;

        Ok(())
    }

    /// Queues a response only while no response for this inbound receipt is in
    /// flight. A redelivery can race the sender task, but it must not replace
    /// the response that task is about to send.
    pub async fn insert_if_absent(&self, transaction: &mut Transaction<'_, Sqlite>) -> Result<()> {
        sqlx::query!(
            r#"
            INSERT INTO receipts(receipt_id, contact_id, message, contact_will_sends_receipt, wake_receiver)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(receipt_id) DO NOTHING
            "#,
            self.receipt_id,
            self.contact_id,
            self.message,
            self.contact_will_send_receipt,
            self.wake_receiver,
        )
        .execute(&mut **transaction)
        .await?;

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::database::app::AppDatabase;

    #[tokio::test]
    async fn a_parked_plaintext_survives_a_rolled_back_handling() {
        let directory = tempfile::tempdir().unwrap();
        let path = directory.path().join("app.sqlite");
        let database = AppDatabase::new(path.to_str().unwrap(), None, false)
            .await
            .unwrap();
        database.run_migrations().await.unwrap();

        // Phase one: the claim and the plaintext of a message whose ratchet step
        // is already spent are committed together.
        let mut t = database.pool.begin().await.unwrap();
        assert!(Receipt::claim_received(&mut t, "receipt").await.unwrap());
        Receipt::store_pending_plaintext(&mut t, "receipt", b"decrypted")
            .await
            .unwrap();
        t.commit().await.unwrap();

        // Phase two fails, so nothing it wrote survives.
        let mut t = database.pool.begin().await.unwrap();
        Receipt::clear_pending_plaintext(&mut t, "receipt")
            .await
            .unwrap();
        t.rollback().await.unwrap();

        // The redelivery is not a fresh claim, but it can resume without
        // decrypting the message a second time.
        let mut t = database.pool.begin().await.unwrap();
        assert!(!Receipt::claim_received(&mut t, "receipt").await.unwrap());
        assert_eq!(
            Receipt::pending_plaintext(&mut t, "receipt").await.unwrap(),
            Some(b"decrypted".to_vec())
        );

        // Once handling commits, the plaintext is gone and a later redelivery is
        // recognised as the plain duplicate it is.
        Receipt::clear_pending_plaintext(&mut t, "receipt")
            .await
            .unwrap();
        t.commit().await.unwrap();

        let mut t = database.pool.begin().await.unwrap();
        assert!(!Receipt::claim_received(&mut t, "receipt").await.unwrap());
        assert_eq!(
            Receipt::pending_plaintext(&mut t, "receipt").await.unwrap(),
            None
        );
    }
}
