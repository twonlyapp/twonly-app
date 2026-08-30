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
const REFILL_THRESHOLD: i64 = 5;
/// Never ask for more than this, however large the server's batch limit is.
/// Every token in a batch costs a blind and an unblind, both P-384 scalar
/// multiplications, so the batch size is what bounds the CPU spike a refill
/// puts on the device.
const MAX_TOKENS_PER_REFILL: usize = 10;
/// Stop using a token slightly before the server would reject it, so a message
/// in flight around midnight UTC is not refused.
const EXPIRY_SAFETY_MARGIN_SECONDS: i64 = 5 * 60;
/// Back off this long after the server refused to issue tokens.
const REFUSED_ISSUANCE_BACKOFF: Duration = Duration::from_secs(15 * 60);

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
        if issuance.is_some_and(|next| Instant::now() < next) {
            return Ok(());
        }
        // Another caller may have filled the pool while this one waited.
        if Self::count(ctx).await? >= REFILL_THRESHOLD {
            return Ok(());
        }

        let parameters = match Server::get_privacy_pass_parameters(ctx).await? {
            ServerResult::Ok(parameters) => parameters,
            ServerResult::ErrorCode(code) => {
                *issuance = Some(Instant::now() + REFUSED_ISSUANCE_BACKOFF);
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

        let responses = match Server::issue_privacy_pass_tokens(ctx, requests).await? {
            ServerResult::Ok(responses) => responses,
            ServerResult::ErrorCode(code) => {
                *issuance = Some(Instant::now() + REFUSED_ISSUANCE_BACKOFF);
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
}
