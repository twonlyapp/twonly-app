/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::encrypted_content;
use crate::bridge::callbacks::get_callbacks;
use crate::context::Context;
use crate::database::app::tables::{KeyVerificationType, NewKeyVerification};
use crate::error::Result;
use crate::user_config::UserConfig;
use hmac::{Hmac, Mac};
use sha2::Sha256;
use sqlx::{Sqlite, Transaction};
use std::sync::Arc;

pub(crate) async fn handle_key_verification_proof(
    ctx: &Arc<Context>,
    transaction: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    proof: encrypted_content::KeyVerificationProof,
) -> Result<()> {
    let signal_engine = ctx.signal_engine.lock().await;
    let Some(engine) = signal_engine.as_ref() else {
        tracing::warn!(
            from_user_id,
            "verification proof arrived before Signal initialized"
        );
        return Ok(());
    };
    let Some(contact_public_key) = engine
        .get_contact_identity_key(&from_user_id.to_string())
        .await?
    else {
        tracing::warn!(
            from_user_id,
            "verification proof has no stored contact identity"
        );
        return Ok(());
    };
    let own_public_key = engine.get_identity_key().await?;
    drop(signal_engine);

    let own_user_id = ctx.user_id().await?;
    let mut signed_data = Vec::with_capacity(16 + own_public_key.len() + contact_public_key.len());
    signed_data.extend_from_slice(&own_user_id.to_le_bytes());
    signed_data.extend_from_slice(&own_public_key);
    signed_data.extend_from_slice(&from_user_id.to_le_bytes());
    signed_data.extend_from_slice(&contact_public_key);

    let cutoff = chrono::Utc::now().timestamp() - 60 * 60;
    let tokens = sqlx::query_scalar!(
        "SELECT token FROM verification_tokens WHERE created_at >= ?",
        cutoff,
    )
    .fetch_all(&mut **transaction)
    .await?;

    let verified = tokens.into_iter().any(|token| {
        Hmac::<Sha256>::new_from_slice(&token).is_ok_and(|mut mac| {
            mac.update(&signed_data);
            mac.verify_slice(&proof.calculated_mac).is_ok()
        })
    });
    if !verified {
        tracing::warn!(
            from_user_id,
            "verification proof did not match a recent token"
        );
        return Ok(());
    }

    NewKeyVerification::new(from_user_id, KeyVerificationType::SecretQrToken)
        .insert(transaction)
        .await?;

    if UserConfig::load_required_from(ctx)?.is_user_discovery_enabled {
        ctx.user_discovery
            .get()
            .await
            .update_verification_state_for_user(
                from_user_id,
                Some(chrono::Utc::now().timestamp_millis()),
                transaction,
            )
            .await?;
    }

    tracing::info!(from_user_id, "contact verified via secret QR token");
    if let Ok(callbacks) = get_callbacks() {
        tokio::spawn(async move {
            (callbacks.api.verification_succeeded)(from_user_id).await;
        });
    }
    Ok(())
}
