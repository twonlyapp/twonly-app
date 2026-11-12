/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Backing off from a contact after the server refused an envelope for them.
//!
//! The server refuses new envelopes when the contact's mailbox already holds
//! too many of ours (`MailboxFull`) or when too many different mailboxes hold
//! undelivered messages from us (`RecipientLimitReached`). Neither clears within seconds, so retrying
//! on every flush would only repeat the same refusal. Instead every queued
//! envelope for that contact waits for `retry_at`, and each further refusal
//! roughly doubles the wait, up to [`MAX_DELAY_SECONDS`].
//!
//! The receipts themselves stay queued untouched; the messages they carry are
//! marked `sendDeferred` so the chat can say they will be retried later. A
//! delivery that goes through removes the backoff and the mark, and a message
//! from the contact makes the next retry due at once, because it shows they
//! are back and about to fetch their mailbox.

use crate::api::proto::error::ErrorCode;
use crate::error::Result;
use sqlx::SqliteConnection;

/// The wait after the first refusal.
pub(crate) const BASE_DELAY_SECONDS: i64 = 5 * 60;

/// The longest wait. A recipient can stay away for weeks, so the retries
/// never stop; this only bounds how late the first one after their return is.
pub(crate) const MAX_DELAY_SECONDS: i64 = 6 * 60 * 60;

/// How far a delay may stray from its nominal value, in both directions.
/// Spreads the retries of many senders blocked by the same limit.
const JITTER: f64 = 0.2;

/// Whether the server refused an envelope because of a sending limit, which
/// asks for a later retry rather than reporting a failure.
pub(crate) fn is_limit_error(code: i32) -> bool {
    code == ErrorCode::MailboxFull as i32 || code == ErrorCode::RecipientLimitReached as i32
}

/// Wait before the next retry after `refusals` consecutive refusals.
///
/// `jitter` is a factor in `[1 - JITTER, 1 + JITTER]`; the result never
/// exceeds [`MAX_DELAY_SECONDS`].
pub(crate) fn delay_seconds(refusals: i64, jitter: f64) -> i64 {
    let doublings = (refusals - 1).clamp(0, 20) as u32;
    let nominal = BASE_DELAY_SECONDS
        .saturating_mul(1_i64 << doublings)
        .min(MAX_DELAY_SECONDS);
    let jitter = jitter.clamp(1.0 - JITTER, 1.0 + JITTER);
    ((nominal as f64 * jitter).round() as i64).clamp(1, MAX_DELAY_SECONDS)
}

/// When the contact's backoff ends, if it has not ended by `now`.
pub(crate) async fn active_until(
    connection: &mut SqliteConnection, contact_id: i64, now: i64,
) -> Result<Option<i64>> {
    Ok(sqlx::query_scalar!(
        "SELECT retry_at FROM contact_send_backoff WHERE contact_id = ? AND retry_at > ?",
        contact_id,
        now,
    )
    .fetch_optional(connection)
    .await?)
}

/// Records one more refusal for the contact and returns when to retry.
///
/// Every message still waiting for the server to take it is marked as
/// deferred, not just the one refused: they all wait for the same retry.
pub(crate) async fn record_refusal(
    connection: &mut SqliteConnection, contact_id: i64, now: i64,
) -> Result<i64> {
    let refusals = sqlx::query_scalar!(
        "SELECT attempts FROM contact_send_backoff WHERE contact_id = ?",
        contact_id,
    )
    .fetch_optional(&mut *connection)
    .await?
    .unwrap_or(0)
        + 1;

    let jitter = 1.0 + JITTER * (2.0 * rand::random::<f64>() - 1.0);

    let retry_at = now + delay_seconds(refusals, jitter);

    sqlx::query!(
        r#"INSERT INTO contact_send_backoff(contact_id, attempts, retry_at) VALUES (?, ?, ?)
           ON CONFLICT(contact_id) DO UPDATE SET
               attempts = excluded.attempts,
               retry_at = excluded.retry_at"#,
        contact_id,
        refusals,
        retry_at,
    )
    .execute(&mut *connection)
    .await?;

    mark_waiting_messages(connection, Some(contact_id), now).await?;

    Ok(retry_at)
}

/// Marks the messages queued for contacts whose backoff has not ended by
/// `now` as deferred, limited to `contact_id` when given.
///
/// Only messages we wrote and the server has not taken yet qualify: a resend
/// of a delivered message is not shown as waiting again. Media and messages
/// parked for a missing session have their own state and are left alone.
pub(crate) async fn mark_waiting_messages(
    connection: &mut SqliteConnection, contact_id: Option<i64>, now: i64,
) -> Result<()> {
    sqlx::query!(
        r#"INSERT INTO message_actions(message_id, contact_id, type)
           SELECT r.message_id, r.contact_id, 'sendDeferred'
           FROM receipts r
           JOIN contact_send_backoff b ON b.contact_id = r.contact_id AND b.retry_at > ?
           JOIN messages m ON m.message_id = r.message_id
           WHERE (? IS NULL OR r.contact_id = ?)
             AND r.ack_by_server_at IS NULL
             AND r.will_be_retried_by_media_upload = 0
             AND r.deferred_until_session IS NULL
             AND m.sender_id IS NULL
           ON CONFLICT(message_id, contact_id, type) DO NOTHING"#,
        now,
        contact_id,
        contact_id,
    )
    .execute(connection)
    .await?;

    Ok(())
}

/// Whether any contact is in a backoff that has not ended by `now`.
pub(crate) async fn any_active(connection: &mut SqliteConnection, now: i64) -> Result<bool> {
    Ok(sqlx::query_scalar!(
        r#"SELECT EXISTS(SELECT 1 FROM contact_send_backoff WHERE retry_at > ?) AS "active!: bool""#,
        now,
    )
    .fetch_one(connection)
    .await?)
}

/// Ends the contact's backoff after a delivery the server accepted.
pub(crate) async fn clear(connection: &mut SqliteConnection, contact_id: i64) -> Result<()> {
    sqlx::query!(
        "DELETE FROM contact_send_backoff WHERE contact_id = ?",
        contact_id
    )
    .execute(connection)
    .await?;

    Ok(())
}

/// Makes the next retry for the contact due at once, keeping the count of
/// refusals: if the server still refuses, the wait after that grows as before
/// instead of starting over with every message they send.
pub(crate) async fn retry_now(connection: &mut SqliteConnection, contact_id: i64) -> Result<()> {
    sqlx::query!(
        "UPDATE contact_send_backoff SET retry_at = 0 WHERE contact_id = ? AND retry_at > 0",
        contact_id
    )
    .execute(connection)
    .await?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::context::Context;

    #[test]
    fn delay_doubles_from_five_minutes_up_to_six_hours() {
        let delays: Vec<i64> = (1..=9)
            .map(|refusals| delay_seconds(refusals, 1.0))
            .collect();
        assert_eq!(
            delays,
            vec![300, 600, 1200, 2400, 4800, 9600, 19200, 21600, 21600]
        );
        assert_eq!(delay_seconds(0, 1.0), 300);
        assert_eq!(delay_seconds(i64::MAX, 1.0), MAX_DELAY_SECONDS);
    }

    #[test]
    fn jitter_is_bounded_and_never_exceeds_the_maximum() {
        assert_eq!(delay_seconds(1, 0.8), 240);
        assert_eq!(delay_seconds(1, 1.2), 360);
        assert_eq!(delay_seconds(1, 5.0), 360);
        assert_eq!(delay_seconds(20, 1.2), MAX_DELAY_SECONDS);
    }

    #[test]
    fn only_limit_codes_ask_for_a_later_retry() {
        assert!(is_limit_error(ErrorCode::MailboxFull as i32));
        assert!(is_limit_error(ErrorCode::RecipientLimitReached as i32));
        assert!(!is_limit_error(ErrorCode::InternalError as i32));
        assert!(!is_limit_error(ErrorCode::UserIdNotFound as i32));
    }

    #[tokio::test]
    async fn refusals_grow_the_wait_and_mark_only_waiting_messages() -> anyhow::Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;
        let database = ctx.app_db.read().await.clone();
        sqlx::raw_sql(
            "INSERT INTO contacts(user_id, username) VALUES (7, 'anna'), (8, 'ben');
             INSERT INTO groups(group_id, group_name) VALUES ('g', 'G');
             INSERT INTO messages(message_id, group_id, type) VALUES
                 ('waiting', 'g', 'text'), ('delivered', 'g', 'text'), ('other', 'g', 'text');
             INSERT INTO receipts(receipt_id, contact_id, message_id, message, ack_by_server_at)
             VALUES ('r1', 7, 'waiting', x'00', NULL), ('r2', 7, 'delivered', x'00', 100),
                    ('r3', 8, 'other', x'00', NULL);",
        )
        .execute(&database.pool)
        .await?;

        let mut connection = database.pool.acquire().await?;
        let first = record_refusal(&mut connection, 7, 1_000).await?;
        assert!((1_000 + 240..=1_000 + 360).contains(&first));
        let second = record_refusal(&mut connection, 7, 1_000).await?;
        assert!((1_000 + 480..=1_000 + 720).contains(&second));

        let marked: Vec<String> = sqlx::query_scalar(
            "SELECT message_id FROM message_actions WHERE type = 'sendDeferred' ORDER BY 1",
        )
        .fetch_all(&mut *connection)
        .await?;
        assert_eq!(marked, vec!["waiting".to_owned()]);

        assert_eq!(active_until(&mut connection, 7, 1_000).await?, Some(second));
        assert_eq!(active_until(&mut connection, 8, 1_000).await?, None);
        assert!(any_active(&mut connection, 1_000).await?);

        // A message from them makes the retry due but keeps the count.
        retry_now(&mut connection, 7).await?;
        assert_eq!(active_until(&mut connection, 7, 1_000).await?, None);

        // While the retry is due, a newly queued message is not deferred.
        sqlx::raw_sql(
            "INSERT INTO messages(message_id, group_id, type) VALUES ('later', 'g', 'text');
             INSERT INTO receipts(receipt_id, contact_id, message_id, message)
             VALUES ('r4', 7, 'later', x'00');",
        )
        .execute(&mut *connection)
        .await?;
        mark_waiting_messages(&mut connection, None, 1_000).await?;
        let later_marked: i64 =
            sqlx::query_scalar("SELECT COUNT(*) FROM message_actions WHERE message_id = 'later'")
                .fetch_one(&mut *connection)
                .await?;
        assert_eq!(later_marked, 0);

        let third = record_refusal(&mut connection, 7, 1_000).await?;
        assert!((1_000 + 960..=1_000 + 1_440).contains(&third));
        let later_marked: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM message_actions WHERE message_id = 'later' AND type = \
             'sendDeferred'",
        )
        .fetch_one(&mut *connection)
        .await?;
        assert_eq!(later_marked, 1);

        clear(&mut connection, 7).await?;
        assert!(!any_active(&mut connection, 1_000).await?);
        Ok(())
    }
}
