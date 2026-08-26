/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::encrypted_content;
use crate::bridge::callbacks::get_callbacks;
use crate::error::Result;
use sqlx::{Sqlite, Transaction};

pub(crate) async fn handle_key_verification_proof(
    _transaction: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    proof: encrypted_content::KeyVerificationProof,
) -> Result<()> {
    if let Ok(callbacks) = get_callbacks() {
        tokio::spawn(async move {
            (callbacks.api.verification_proof)(from_user_id, proof.calculated_mac).await;
        });
    }
    Ok(())
}
