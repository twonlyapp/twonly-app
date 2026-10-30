use flutter_rust_bridge::frb;

/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::error::Result;
use sqlx::{Sqlite, Transaction};

#[derive(sqlx::FromRow, Debug, Clone, PartialEq, Eq)]
#[frb]

pub struct Receipt {
    pub receipt_id: String,
    pub contact_id: i64,
    pub message_id: Option<String>,
    pub message: Vec<u8>,
    #[frb(name = "contactWillSendsReceiptFlag")]
    pub contact_will_sends_receipt: i64,
    #[frb(name = "willBeRetriedByMediaUploadFlag")]
    pub will_be_retried_by_media_upload: i64,
    #[frb(name = "markForRetrySeconds")]
    pub mark_for_retry: Option<i64>,
    #[frb(name = "markForRetryAfterAcceptedSeconds")]
    pub mark_for_retry_after_accepted: Option<i64>,
    #[frb(name = "ackByServerAtSeconds")]
    pub ack_by_server_at: Option<i64>,
    pub retry_count: i64,
    #[frb(name = "lastRetrySeconds")]
    pub last_retry: Option<i64>,
    #[frb(name = "createdAtSeconds")]
    pub created_at: i64,
    pub wake_receiver: i64,
}

/// The decrypted content of a message, parked on its receipt claim until its
/// handling commits.
#[derive(Debug, PartialEq, Eq)]
pub struct ParkedPlaintext {
    /// Who sent it. Claims parked before the sender was recorded have none.
    pub from_user_id: Option<i64>,
    pub plaintext: Vec<u8>,
}

/// A parked message whose next attempt is due.
pub struct DueParkedMessage {
    pub receipt_id: String,
    pub from_user_id: i64,
}

pub struct NewReceipt<'a> {
    receipt_id: &'a str,
    contact_id: i64,
    message: &'a [u8],
    contact_will_send_receipt: bool,
    wake_receiver: bool,
}

impl Receipt {
    /// Returns whether the reaction is new; a resent one is already stored.
    pub async fn insert_reaction(
        transaction: &mut Transaction<'_, Sqlite>, message_id: &str, sender_id: i64, emoji: &str,
    ) -> Result<bool> {
        let inserted = sqlx::query!(
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
        .await?
        .rows_affected();

        Ok(inserted > 0)
    }

    pub async fn delete_reaction(
        transaction: &mut Transaction<'_, Sqlite>, message_id: &str, sender_id: i64, emoji: &str,
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
        transaction: &mut Transaction<'_, Sqlite>, receipt_id: &str,
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
        transaction: &mut Transaction<'_, Sqlite>, receipt_id: &str, from_user_id: i64,
        plaintext: &[u8],
    ) -> Result<()> {
        sqlx::query!(
            r#"
            UPDATE received_receipts
            SET pending_plaintext = ?,
                pending_from_user_id = ?,
                pending_since = COALESCE(
                    pending_since, CAST(strftime('%s', 'now') AS INTEGER)
                )
            WHERE receipt_id = ?
            "#,
            plaintext,
            from_user_id,
            receipt_id,
        )
        .execute(&mut **transaction)
        .await?;

        Ok(())
    }

    /// Returns the parked plaintext of a receipt whose handling did not commit.
    pub async fn pending_plaintext(
        transaction: &mut Transaction<'_, Sqlite>, receipt_id: &str,
    ) -> Result<Option<ParkedPlaintext>> {
        let parked = sqlx::query!(
            r#"
            SELECT pending_from_user_id, pending_plaintext AS "plaintext!"
            FROM received_receipts
            WHERE receipt_id = ? AND pending_plaintext IS NOT NULL
            "#,
            receipt_id,
        )
        .fetch_optional(&mut **transaction)
        .await?;

        Ok(parked.map(|row| ParkedPlaintext {
            from_user_id: row.pending_from_user_id,
            plaintext: row.plaintext,
        }))
    }

    /// Drops a parked plaintext once its message no longer needs it.
    pub async fn clear_pending_plaintext(
        transaction: &mut Transaction<'_, Sqlite>, receipt_id: &str,
    ) -> Result<()> {
        sqlx::query!(
            r#"
            UPDATE received_receipts
            SET pending_plaintext = NULL,
                pending_since = NULL,
                pending_attempts = 0,
                pending_retry_at = NULL,
                pending_waits_for_acceptance = 0
            WHERE receipt_id = ? AND pending_plaintext IS NOT NULL
            "#,
            receipt_id,
        )
        .execute(&mut **transaction)
        .await?;

        Ok(())
    }

    /// Keeps a parked message until its sender is accepted. It is retried
    /// once they are, or dropped once they are blocked.
    pub async fn park_until_accepted(
        transaction: &mut Transaction<'_, Sqlite>, receipt_id: &str, from_user_id: i64,
    ) -> Result<()> {
        sqlx::query!(
            r#"
            UPDATE received_receipts
            SET pending_waits_for_acceptance = 1,
                pending_from_user_id = COALESCE(pending_from_user_id, ?),
                pending_since = COALESCE(
                    pending_since, CAST(strftime('%s', 'now') AS INTEGER)
                )
            WHERE receipt_id = ? AND pending_plaintext IS NOT NULL
            "#,
            from_user_id,
            receipt_id,
        )
        .execute(&mut **transaction)
        .await?;

        Ok(())
    }

    /// Counts a failed attempt at a parked message and schedules the next one,
    /// doubling the wait from `first_backoff` up to `max_backoff` seconds.
    /// Returns the attempts made so far, or `None` when nothing is parked.
    pub async fn record_parked_failure(
        transaction: &mut Transaction<'_, Sqlite>, receipt_id: &str, from_user_id: i64, now: i64,
        first_backoff: i64, max_backoff: i64,
    ) -> Result<Option<i64>> {
        // Every SET expression reads the row as it was before the update, so
        // the backoff doubles with the attempts made before this one.
        let attempts = sqlx::query_scalar!(
            r#"
            UPDATE received_receipts
            SET pending_attempts = pending_attempts + 1,
                pending_retry_at = ? + MIN(? << MIN(pending_attempts, 30), ?),
                pending_waits_for_acceptance = 0,
                pending_from_user_id = COALESCE(pending_from_user_id, ?),
                pending_since = COALESCE(pending_since, ?)
            WHERE receipt_id = ? AND pending_plaintext IS NOT NULL
            RETURNING pending_attempts
            "#,
            now,
            first_backoff,
            max_backoff,
            from_user_id,
            now,
            receipt_id,
        )
        .fetch_optional(&mut **transaction)
        .await?;

        Ok(attempts)
    }

    /// The parked messages whose next attempt is due: failed ones once their
    /// backoff has passed, and those that waited for a sender who has since
    /// been accepted, or blocked, which drops them. Oldest first, so a chat
    /// replays in the order it was sent.
    pub async fn due_parked(pool: &sqlx::SqlitePool, now: i64) -> Result<Vec<DueParkedMessage>> {
        Ok(sqlx::query_as!(
            DueParkedMessage,
            r#"
            SELECT r.receipt_id, r.pending_from_user_id AS "from_user_id!: i64"
            FROM received_receipts r
            JOIN contacts c ON c.user_id = r.pending_from_user_id
            WHERE r.pending_plaintext IS NOT NULL
              AND CASE WHEN r.pending_waits_for_acceptance != 0
                  THEN c.blocked != 0 OR (c.accepted != 0 AND c.deleted_by_user = 0)
                  ELSE COALESCE(r.pending_retry_at, 0) <= ?
              END
            ORDER BY COALESCE(r.pending_since, r.created_at), r.receipt_id
            "#,
            now,
        )
        .fetch_all(pool)
        .await?)
    }

    /// Drops every message parked since before `parked_before`, whatever it
    /// waits for, and returns how many there were.
    pub async fn drop_expired_parked(pool: &sqlx::SqlitePool, parked_before: i64) -> Result<u64> {
        Ok(sqlx::query!(
            r#"
            UPDATE received_receipts
            SET pending_plaintext = NULL,
                pending_since = NULL,
                pending_attempts = 0,
                pending_retry_at = NULL,
                pending_waits_for_acceptance = 0
            WHERE pending_plaintext IS NOT NULL
              AND COALESCE(pending_since, created_at) < ?
            "#,
            parked_before,
        )
        .execute(pool)
        .await?
        .rows_affected())
    }

    /// Records, in the commit that handles it, that a claimed message was
    /// handled. Only a mark written here is proof: an unmarked claim may be one
    /// whose decryption failed, or one older than the mark.
    pub async fn mark_handled(
        transaction: &mut Transaction<'_, Sqlite>, receipt_id: &str,
    ) -> Result<()> {
        sqlx::query!(
            r#"
            UPDATE received_receipts
            SET handled_at = CAST(strftime('%s', 'now') AS INTEGER)
            WHERE receipt_id = ? AND handled_at IS NULL
            "#,
            receipt_id,
        )
        .execute(&mut **transaction)
        .await?;

        Ok(())
    }

    pub async fn was_handled(
        transaction: &mut Transaction<'_, Sqlite>, receipt_id: &str,
    ) -> Result<bool> {
        let handled = sqlx::query_scalar!(
            r#"
            SELECT handled_at IS NOT NULL AS "handled!: bool"
            FROM received_receipts
            WHERE receipt_id = ?
            "#,
            receipt_id,
        )
        .fetch_optional(&mut **transaction)
        .await?
        .unwrap_or(false);

        Ok(handled)
    }

    pub async fn claim_received_retry(
        transaction: &mut Transaction<'_, Sqlite>, receipt_id: &str,
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
        transaction: &mut Transaction<'_, Sqlite>, contact_id: i64,
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

        Receipt::store_pending_plaintext(&mut t, "receipt", 7, b"decrypted")
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
            Some(ParkedPlaintext {
                from_user_id: Some(7),
                plaintext: b"decrypted".to_vec(),
            })
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

use crate::database::app::patch::{NullableInt, NullableText};

#[derive(Debug, Clone, Default)]

pub struct ReceiptPatch {
    pub receipt_id: Option<String>,
    pub contact_id: Option<i64>,
    pub message_id: Option<NullableText>,
    pub message: Option<Vec<u8>>,
    pub contact_will_sends_receipt: Option<bool>,
    pub will_be_retried_by_media_upload: Option<bool>,
    pub mark_for_retry: Option<NullableInt>,
    pub mark_for_retry_after_accepted: Option<NullableInt>,
    pub ack_by_server_at: Option<NullableInt>,
    pub retry_count: Option<i64>,
    pub last_retry: Option<NullableInt>,
    pub created_at: Option<i64>,
}
