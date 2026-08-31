/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Client side of the Privacy Pass token pool that rate-limits sealed-sender
//! uploads.
//!
//! Tokens are minted over the authenticated WebSocket, where the server counts
//! them against this account's daily quota, and spent later on the anonymous
//! HTTP upload endpoint. Because the issued token is unblinded locally, the
//! server cannot link a redeemed token back to the account it was issued to,
//! which is what lets the upload stay unauthenticated without becoming an open
//! relay.

use crate::api::Server;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::error::{Result, TwonlyError};
use crate::user_config::UserConfig;
use p384::NistP384;
use privacypass::auth::authenticate::TokenChallenge;
use privacypass::common::private::deserialize_public_key;
use privacypass::private_tokens::{TokenRequest, TokenResponse, TokenState};
use privacypass::Serialize as PrivacyPassSerialize;
use std::sync::Arc;
use std::time::{Duration, Instant};

/// Refill once the pool can no longer cover a short burst of messages.
///
/// The issuer only lets a session mint every few seconds, so this has to leave
/// room for a whole cooldown's worth of sends: a threshold that trips only once
/// the pool is nearly empty guarantees a stretch of named messages while the
/// refill waits its turn.
const REFILL_THRESHOLD: i64 = 10;
/// Never ask for more than this, however large the server's batch limit is.
/// Every token in a batch costs a blind and an unblind, both P-384 scalar
/// multiplications, so the batch size is what bounds the CPU spike a refill
/// puts on the device.
const MAX_TOKENS_PER_REFILL: usize = 20;
/// Stop using a token slightly before the server would reject it, so a message
/// in flight around midnight UTC is not refused.
const EXPIRY_SAFETY_MARGIN_SECONDS: i64 = 5 * 60;
/// Back off this long when the issuer refuses for a reason we cannot classify.
const UNKNOWN_REFUSAL_BACKOFF: Duration = Duration::from_secs(15 * 60);
/// Assumed issuance cooldown while the server's own value is unknown, which is
/// the case only when the parameter request itself failed.
const ASSUMED_ISSUANCE_COOLDOWN: Duration = Duration::from_secs(5);
/// A refill waits out a backoff no longer than this and gives up on anything
/// beyond it. The issuance cooldown is seconds long and worth waiting for; an
/// exhausted daily quota lasts until midnight and is not.
const MAX_BACKOFF_WAIT: Duration = Duration::from_secs(30);

pub(crate) struct PrivacyPassTokens;

impl PrivacyPassTokens {
    /// Removes one unexpired token from the local pool.
    ///
    /// A token is spent by handing it to the server, so it is deleted before it
    /// is used: replaying it would be rejected anyway, and keeping it would
    /// stall every later message behind the same dead token.
    ///
    /// Minting never happens here. It needs two server round trips, and putting
    /// those on the send path would delay the very message that emptied the
    /// pool; an empty pool simply means this message goes out named while the
    /// refill runs behind it.
    pub(crate) async fn take(ctx: &Arc<Context>) -> Result<Option<Vec<u8>>> {
        let token = Self::pop(ctx).await?;
        Self::spawn_refill(ctx);
        Ok(token)
    }

    /// Tops the pool up when it is running low. Safe to call on every
    /// connection: it is a no-op while enough tokens are left.
    pub(crate) async fn refill_if_needed(ctx: &Arc<Context>) -> Result<()> {
        // Tokens are only ever spent on sealed-sender uploads. Minting them for
        // an account that has the feature off would burn its daily quota on
        // tokens it can never use.
        if !UserConfig::load_from(ctx)?.is_some_and(|config| config.sealed_sender_enabled) {
            return Ok(());
        }
        if Self::count(ctx).await? >= REFILL_THRESHOLD {
            return Ok(());
        }
        Self::refill(ctx).await
    }

    pub(crate) fn spawn_refill(ctx: &Arc<Context>) {
        let ctx = ctx.clone();
        tokio::spawn(async move {
            if let Err(error) = Self::refill_if_needed(&ctx).await {
                tracing::warn!("Privacy Pass refill failed: {error}");
            }
        });
    }

    async fn count(ctx: &Arc<Context>) -> Result<i64> {
        let database = ctx.app_db.read().await.clone();
        let now = now_seconds();
        Ok(sqlx::query_scalar!(
            "SELECT COUNT(*) FROM privacy_pass_tokens WHERE expires_at > ?",
            now
        )
        .fetch_one(&database.pool)
        .await?)
    }

    async fn pop(ctx: &Arc<Context>) -> Result<Option<Vec<u8>>> {
        let database = ctx.app_db.read().await.clone();
        let now = now_seconds();
        let mut transaction = database.pool.begin().await?;
        sqlx::query!("DELETE FROM privacy_pass_tokens WHERE expires_at <= ?", now)
            .execute(&mut *transaction)
            .await?;
        let token = sqlx::query_scalar!(
            r#"DELETE FROM privacy_pass_tokens
               WHERE token = (
                   SELECT token FROM privacy_pass_tokens
                   WHERE expires_at > ?
                   ORDER BY expires_at ASC
                   LIMIT 1
               )
               RETURNING token"#,
            now
        )
        .fetch_optional(&mut *transaction)
        .await?;
        transaction.commit().await?;
        Ok(token)
    }

    async fn refill(ctx: &Arc<Context>) -> Result<()> {
        // A refill already in flight will fill the pool for everyone waiting on
        // it, so a second one would only spend quota twice.
        let Ok(mut issuance) = ctx.privacy_pass_issuance.try_lock() else {
            return Ok(());
        };
        // A backoff short enough to be the issuer's cooldown is waited out
        // rather than skipped: returning here would leave the pool empty with
        // nothing scheduled to fill it, so every message until the next send
        // would go named. Longer backoffs are not worth holding a task for.
        if let Some(next) = *issuance {
            let wait = next.saturating_duration_since(Instant::now());
            if wait > MAX_BACKOFF_WAIT {
                return Ok(());
            }
            if !wait.is_zero() {
                tokio::time::sleep(wait).await;
            }
        }
        // Another caller may have filled the pool while this one waited.
        if Self::count(ctx).await? >= REFILL_THRESHOLD {
            return Ok(());
        }

        let parameters = match Server::get_privacy_pass_parameters(ctx).await? {
            ServerResult::Ok(parameters) => parameters,
            ServerResult::ErrorCode(code) => {
                *issuance = Some(Instant::now() + backoff_for(code, ASSUMED_ISSUANCE_COOLDOWN));
                return Err(TwonlyError::Generic(format!(
                    "server rejected the Privacy Pass parameter request with code {code}"
                )));
            }
        };

        let challenge = TokenChallenge::deserialize(parameters.token_challenge.as_slice())
            .map_err(|error| {
                TwonlyError::Generic(format!("invalid Privacy Pass challenge: {error}"))
            })?;
        let public_key =
            deserialize_public_key::<NistP384>(&parameters.public_key).map_err(|error| {
                TwonlyError::Generic(format!("invalid Privacy Pass public key: {error}"))
            })?;

        let batch_size = (parameters.max_batch_size as usize).min(MAX_TOKENS_PER_REFILL);
        if batch_size == 0 {
            return Err(TwonlyError::Generic(
                "server does not issue any Privacy Pass tokens".into(),
            ));
        }

        // Blinding a batch is a run of P-384 scalar multiplications. On the
        // async runtime it would stall the socket tasks sharing those threads,
        // which is felt as dropped connections rather than as slow minting.
        let (requests, states) = tokio::task::spawn_blocking(move || {
            let mut requests = Vec::with_capacity(batch_size);
            let mut states: Vec<TokenState<NistP384>> = Vec::with_capacity(batch_size);
            for _ in 0..batch_size {
                let (request, state) = TokenRequest::<NistP384>::new(public_key, &challenge)
                    .map_err(|error| {
                        TwonlyError::Generic(format!(
                            "could not blind a Privacy Pass token: {error}"
                        ))
                    })?;
                requests.push(request.tls_serialize_detached().map_err(|error| {
                    TwonlyError::Generic(format!("could not serialize a token request: {error}"))
                })?);
                states.push(state);
            }
            Ok::<_, TwonlyError>((requests, states))
        })
        .await
        .map_err(|error| TwonlyError::Generic(format!("token blinding panicked: {error}")))??;

        let cooldown = Duration::from_secs(u64::from(parameters.issuance_cooldown_seconds));
        let responses = match Server::issue_privacy_pass_tokens(ctx, requests).await? {
            ServerResult::Ok(responses) => {
                // The issuer refuses a session that mints again inside its
                // cooldown, and that refusal is indistinguishable from real
                // trouble. Pacing the next refill here keeps the client from
                // provoking one.
                *issuance = Some(Instant::now() + cooldown);
                responses
            }
            ServerResult::ErrorCode(code) => {
                *issuance = Some(Instant::now() + backoff_for(code, cooldown));
                return Err(TwonlyError::Generic(format!(
                    "server rejected the Privacy Pass issuance with code {code}"
                )));
            }
        };
        if responses.len() != states.len() {
            return Err(TwonlyError::Generic(
                "server returned the wrong number of Privacy Pass responses".into(),
            ));
        }

        // Unblinding is the same kind of curve work, so it is offloaded too.
        let tokens = tokio::task::spawn_blocking(move || {
            responses
                .into_iter()
                .zip(states.iter())
                .map(|(serialized, state)| {
                    let response = TokenResponse::<NistP384>::try_from_bytes(&serialized).map_err(
                        |error| {
                            TwonlyError::Generic(format!("invalid Privacy Pass response: {error}"))
                        },
                    )?;
                    response
                        .issue_token(state)
                        .map_err(|error| {
                            TwonlyError::Generic(format!(
                                "could not finalize a Privacy Pass token: {error}"
                            ))
                        })?
                        .tls_serialize_detached()
                        .map_err(|error| {
                            TwonlyError::Generic(format!(
                                "could not serialize a Privacy Pass token: {error}"
                            ))
                        })
                })
                .collect::<Result<Vec<Vec<u8>>>>()
        })
        .await
        .map_err(|error| TwonlyError::Generic(format!("token finalization panicked: {error}")))??;

        let expires_at = expiry_for_todays_challenge(i64::from(parameters.max_age_seconds));
        let database = ctx.app_db.read().await.clone();
        let mut transaction = database.pool.begin().await?;
        for token in tokens {
            sqlx::query!(
                r#"INSERT INTO privacy_pass_tokens(token, expires_at) VALUES (?, ?)
                   ON CONFLICT(token) DO NOTHING"#,
                token,
                expires_at,
            )
            .execute(&mut *transaction)
            .await?;
        }
        transaction.commit().await?;

        Ok(())
    }
}

fn now_seconds() -> i64 {
    chrono::Utc::now().timestamp()
}

/// How long to leave the issuer alone after it refused to mint.
///
/// The two refusals the server sends routinely are minutes apart in cost, and
/// treating them alike is what took sealed sender down for a quarter of an hour
/// over a burst the client only had to pace.
fn backoff_for(code: i32, cooldown: Duration) -> Duration {
    use crate::api::proto::error::ErrorCode;

    if code == ErrorCode::TooManyRequests as i32 {
        // The per-session issuance cooldown. It clears in seconds.
        cooldown
    } else if code == ErrorCode::PrivacyPassQuotaExhausted as i32 {
        // The daily counter is keyed on the server's calendar date, so nothing
        // this account does before midnight earns another token.
        duration_until_next_utc_day()
    } else {
        UNKNOWN_REFUSAL_BACKOFF
    }
}

/// Time left in the current UTC day, which is when the issuer's daily counter
/// rolls over. Never zero, so a refusal always costs at least one wait.
fn duration_until_next_utc_day() -> Duration {
    const SECONDS_PER_DAY: i64 = 24 * 60 * 60;
    let now = now_seconds();
    let remaining = SECONDS_PER_DAY - now.rem_euclid(SECONDS_PER_DAY);
    Duration::from_secs(remaining.max(1) as u64)
}

/// The server derives its challenge from the current UTC day and accepts a
/// token for `max_age_seconds` counted from the start of that day, not from the
/// moment it was issued.
fn expiry_for_todays_challenge(max_age_seconds: i64) -> i64 {
    const SECONDS_PER_DAY: i64 = 24 * 60 * 60;
    let start_of_day = now_seconds().div_euclid(SECONDS_PER_DAY) * SECONDS_PER_DAY;
    start_of_day + max_age_seconds - EXPIRY_SAFETY_MARGIN_SECONDS
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tokens_expire_with_the_day_they_were_issued_for() {
        const SECONDS_PER_DAY: i64 = 24 * 60 * 60;
        let expiry = expiry_for_todays_challenge(7 * SECONDS_PER_DAY);
        let start_of_day = now_seconds().div_euclid(SECONDS_PER_DAY) * SECONDS_PER_DAY;

        assert_eq!(
            expiry,
            start_of_day + 7 * SECONDS_PER_DAY - EXPIRY_SAFETY_MARGIN_SECONDS
        );
        assert!(expiry > now_seconds());
    }

    #[test]
    fn the_issuance_cooldown_does_not_cost_a_quarter_of_an_hour() {
        use crate::api::proto::error::ErrorCode;

        let cooldown = Duration::from_secs(5);
        assert_eq!(
            backoff_for(ErrorCode::TooManyRequests as i32, cooldown),
            cooldown
        );
        assert_eq!(
            backoff_for(ErrorCode::InternalError as i32, cooldown),
            UNKNOWN_REFUSAL_BACKOFF
        );
        // Nothing earns a token before the daily counter rolls over, so this
        // one must not come back after a mere cooldown.
        assert!(
            backoff_for(ErrorCode::PrivacyPassQuotaExhausted as i32, cooldown)
                == duration_until_next_utc_day()
        );
    }

    #[test]
    fn the_daily_quota_backoff_ends_within_the_day() {
        const SECONDS_PER_DAY: u64 = 24 * 60 * 60;
        let remaining = duration_until_next_utc_day();
        assert!(!remaining.is_zero());
        assert!(remaining <= Duration::from_secs(SECONDS_PER_DAY));
    }
}
