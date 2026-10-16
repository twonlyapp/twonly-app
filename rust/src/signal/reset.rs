/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Rate limiting for Signal session resets.
//!
//! Resetting a session is a repair both sides have to agree on: we retire our
//! record and ask the peer to open a new one. When the peer cannot honour that
//! -- their identity key no longer matches the one we trust, or their own
//! record is equally broken -- every message would trigger another reset
//! request in each direction. The counters here bound that loop: a peer gets at
//! most one reset per [`RESET_COOLDOWN`], and at most [`MAX_RESETS_PER_WINDOW`]
//! within [`RESET_WINDOW`], after which the message is dropped and the failure
//! is left to the user-visible retry path.

use crate::error::Result;
use sqlx::SqlitePool;

/// Shortest gap between two resets of the same session. A reset needs a server
/// round-trip and a message each way, so anything faster only stacks duplicate
/// repairs for a repair already in flight.
const RESET_COOLDOWN: i64 = 60;

/// Window the reset budget is counted over.
const RESET_WINDOW: i64 = 60 * 60;

/// Resets allowed per peer per [`RESET_WINDOW`]. A repair that works needs one;
/// a handful covers messages that crossed it in flight. Beyond that the session
/// is not the problem and resetting again will not make it one.
const MAX_RESETS_PER_WINDOW: i64 = 5;

pub(crate) struct SessionResetLimiter;

impl SessionResetLimiter {
    /// Claims permission to reset the session with `name`/`device_id`.
    ///
    /// Returns `false` when the peer is inside the cooldown or has spent its
    /// budget for the window, in which case the caller must leave the session
    /// alone and let the message fail.
    pub(crate) async fn claim(pool: &SqlitePool, name: &str, device_id: u32) -> Result<bool> {
        let now = crate::utils::current_time().timestamp();
        let window_start = now - RESET_WINDOW;

        // One statement so two inbound messages racing on the same peer cannot
        // both read a stale count and each claim the last slot.
        let claimed = sqlx::query!(
            r#"
            INSERT INTO signal_session_resets(
                name, device_id, last_reset_at, window_started_at, resets_in_window
            )
            VALUES (?, ?, ?, ?, 1)
            ON CONFLICT(name, device_id) DO UPDATE SET
                last_reset_at = excluded.last_reset_at,
                -- A window that has run out starts over with this reset as its
                -- first, so a peer that broke months ago is not still blocked.
                window_started_at = CASE
                    WHEN signal_session_resets.window_started_at <= ?
                    THEN excluded.last_reset_at
                    ELSE signal_session_resets.window_started_at
                END,
                resets_in_window = CASE
                    WHEN signal_session_resets.window_started_at <= ? THEN 1
                    ELSE signal_session_resets.resets_in_window + 1
                END
            -- Every SET expression above reads the row as it was before the
            -- update, and this predicate decides whether the update happens at
            -- all: zero affected rows means the claim was refused. A first
            -- reset for a peer takes the INSERT path and is always allowed.
            WHERE signal_session_resets.last_reset_at <= ?
              AND (signal_session_resets.window_started_at <= ?
                   OR signal_session_resets.resets_in_window < ?)
            "#,
            name,
            device_id,
            now,
            now,
            window_start,
            window_start,
            // Cooldown: the update only lands once the previous reset is old
            // enough for a repair to have had a chance to complete.
            now - RESET_COOLDOWN,
            window_start,
            MAX_RESETS_PER_WINDOW,
        )
        .execute(pool)
        .await?
        .rows_affected()
            != 0;

        if !claimed {
            tracing::warn!(
                name,
                device_id,
                "signal session reset suppressed: the peer is inside the cooldown or over budget"
            );
        }

        Ok(claimed)
    }

    /// Forgets the reset history for a peer, so a session that works again
    /// starts from a full budget.
    pub(crate) async fn clear(pool: &SqlitePool, name: &str, device_id: u32) -> Result<()> {
        sqlx::query!(
            r#"DELETE FROM signal_session_resets WHERE name = ? AND device_id = ?"#,
            name,
            device_id,
        )
        .execute(pool)
        .await?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::database::signal::Database;

    async fn test_pool() -> SqlitePool {
        let database = Database::new(&"sqlite::memory:".to_string(), None, false)
            .await
            .unwrap();
        database.run_migrations().await.unwrap();
        database.pool.clone()
    }

    /// Moves a peer's bookkeeping back in time, standing in for a cooldown or a
    /// window that has since elapsed.
    async fn age_by(pool: &SqlitePool, name: &str, seconds: i64) {
        sqlx::query!(
            r#"
            UPDATE signal_session_resets
            SET last_reset_at = last_reset_at - ?, window_started_at = window_started_at - ?
            WHERE name = ?
            "#,
            seconds,
            seconds,
            name,
        )
        .execute(pool)
        .await
        .unwrap();
    }

    #[tokio::test]
    async fn the_cooldown_holds_off_a_second_reset_for_the_same_peer() {
        let pool = test_pool().await;

        assert!(SessionResetLimiter::claim(&pool, "1", 1).await.unwrap());
        // The repair from the first claim is still in flight.
        assert!(!SessionResetLimiter::claim(&pool, "1", 1).await.unwrap());
        // A different peer has its own budget.
        assert!(SessionResetLimiter::claim(&pool, "2", 1).await.unwrap());

        age_by(&pool, "1", RESET_COOLDOWN).await;
        assert!(SessionResetLimiter::claim(&pool, "1", 1).await.unwrap());
    }

    #[tokio::test]
    async fn a_peer_that_cannot_be_repaired_runs_out_of_budget() {
        let pool = test_pool().await;

        for reset in 0..MAX_RESETS_PER_WINDOW {
            assert!(
                SessionResetLimiter::claim(&pool, "1", 1).await.unwrap(),
                "reset {reset} is within the budget"
            );
            age_by(&pool, "1", RESET_COOLDOWN).await;
        }

        // Out of budget: the cooldown has passed, but the window has not.
        assert!(!SessionResetLimiter::claim(&pool, "1", 1).await.unwrap());

        // Ageing past the window starts the budget over, so a peer that broke
        // long ago is not blocked forever.
        age_by(&pool, "1", RESET_WINDOW).await;
        assert!(SessionResetLimiter::claim(&pool, "1", 1).await.unwrap());
    }

    #[tokio::test]
    async fn a_repaired_session_starts_from_a_full_budget() {
        let pool = test_pool().await;

        assert!(SessionResetLimiter::claim(&pool, "1", 1).await.unwrap());
        SessionResetLimiter::clear(&pool, "1", 1).await.unwrap();

        // Neither the cooldown nor the spent budget survives the clear.
        assert!(SessionResetLimiter::claim(&pool, "1", 1).await.unwrap());
    }
}
