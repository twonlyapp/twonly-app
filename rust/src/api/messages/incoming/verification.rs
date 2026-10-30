/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::messages::queue_encrypted_content;
use crate::api::proto::client::{encrypted_content, EncryptedContent};
use crate::bridge::callbacks::get_callbacks;
use crate::context::Context;
use crate::database::app::contacts::table::{Contact, UpdateContact};
use crate::database::app::groups::native::Group;
use crate::database::app::key_verifications::table::{KeyVerificationType, NewKeyVerification};
use crate::error::Result;
use crate::user_config::UserConfig;
use hmac::{Hmac, KeyInit, Mac};
use sha2::Sha256;
use sqlx::{Sqlite, Transaction};
use std::sync::Arc;

pub(crate) async fn handle_key_verification_proof(
    ctx: &Arc<Context>, transaction: &mut Transaction<'_, Sqlite>, from_user_id: i64,
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

    if from_user_id == own_user_id {
        return Ok(());
    }

    let mut signed_data = Vec::with_capacity(16 + own_public_key.len() + contact_public_key.len());

    signed_data.extend_from_slice(&own_user_id.to_le_bytes());

    signed_data.extend_from_slice(&own_public_key);

    signed_data.extend_from_slice(&from_user_id.to_le_bytes());

    signed_data.extend_from_slice(&contact_public_key);

    let now = chrono::Utc::now().timestamp();

    let tokens = sqlx::query!(
        "SELECT token_id, token, created_at FROM verification_tokens WHERE created_at >= ? AND created_at \
         <= ? AND length(token) = 16 AND proof_version = 1",
        now - 60 * 60,
        now
    )
    .map(|row| (row.token_id, row.token, row.created_at))
    .fetch_all(&mut **transaction)
    .await?;

    let verified_at = tokens
        .into_iter()
        .filter(|(_, token, _)| {
            Hmac::<Sha256>::new_from_slice(token).is_ok_and(|mut mac| {
                mac.update(&signed_data);
                mac.verify_slice(&proof.calculated_mac).is_ok()
            })
        })
        .map(|(token_id, _, created_at)| (created_at, token_id))
        .max();

    let Some((token_created_at, token_id)) = verified_at else {
        tracing::warn!(
            from_user_id,
            "verification proof did not match a recent token"
        );

        return Ok(());
    };

    let consumed = sqlx::query!(
        r#"INSERT INTO verification_token_uses(token_id, contact_id) VALUES (?, ?)
           ON CONFLICT DO NOTHING"#,
        token_id,
        from_user_id,
    )
    .execute(&mut **transaction)
    .await?
    .rows_affected();

    if consumed == 0 {
        return Ok(());
    }

    accept_recent_qr_contact(ctx, transaction, from_user_id, token_created_at, now).await?;

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
        crate::database::lifecycle::spawn(async move {
            (callbacks.api.verification_succeeded)(from_user_id).await;
        });
    }

    Ok(())
}

/// The token owner's stored creation time authorizes acceptance. The timestamp
/// embedded in a scanned link is only used by the scanner to choose its UI.
async fn accept_recent_qr_contact(
    ctx: &Arc<Context>, transaction: &mut Transaction<'_, Sqlite>, from_user_id: i64,
    token_created_at: i64, now: i64,
) -> Result<()> {
    if !(0..=5 * 60).contains(&(now - token_created_at)) {
        return Ok(());
    }

    let Some(contact) = Contact::get_contact_by_id(transaction, from_user_id)
        .await?
        .filter(|contact| contact.blocked == 0 && contact.accepted == 0)
    else {
        return Ok(());
    };

    UpdateContact::builder()
        .user_id(from_user_id)
        .requested(false)
        .requested_by_user(false)
        .accepted(true)
        .deleted_by_user(false)
        .build()
        .update(transaction)
        .await?;

    Group::create_direct_chat(ctx, transaction, contact).await?;

    super::errors::release_after_contact_acceptance(transaction, from_user_id).await?;

    queue_encrypted_content(
        transaction,
        from_user_id,
        EncryptedContent {
            contact_request: Some(encrypted_content::ContactRequest {
                r#type: encrypted_content::contact_request::Type::Accept as i32,
            }),
            ..Default::default()
        },
        true,
    )
    .await?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::proto::client as proto;
    use libsignal_protocol::IdentityKeyPair;
    use prost::Message as _;
    use rand::SeedableRng as _;

    #[tokio::test]
    async fn only_a_valid_fresh_qr_proof_accepts_the_contact() -> anyhow::Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        crate::api::ApiRuntime::close(&ctx).await?;
        UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"owner","displayName":"Owner","isUserDiscoveryEnabled":false}"#,
        )?;

        let mut rng = rand::rngs::StdRng::from_os_rng();
        let identity = IdentityKeyPair::generate(&mut rng);
        ctx.inject_test_signal_identity(identity.serialize().to_vec(), 1)
            .await?;
        ctx.inject_test_user_id(42).await?;
        let contact_key = IdentityKeyPair::generate(&mut rng)
            .identity_key()
            .serialize();
        let rust_db = ctx.rust_db.read().await.clone();
        sqlx::query(
            "INSERT INTO signal_identities(name, identity_key, timestamp) VALUES ('7', ?, 0)",
        )
        .bind(contact_key.as_ref())
        .execute(&rust_db.pool)
        .await?;

        let token = vec![17; 16];
        let mut mac = Hmac::<Sha256>::new_from_slice(&token)?;
        mac.update(&42_i64.to_le_bytes());
        mac.update(&identity.identity_key().serialize());
        mac.update(&7_i64.to_le_bytes());
        mac.update(&contact_key);
        let proof = mac.finalize().into_bytes().to_vec();

        let db = ctx.app_db.read().await.clone();
        // A valid older proof still verifies identity, but cannot accept a request.
        for (age, blocked, valid, proof_version, accepts, verifies) in [
            (0, false, true, 1, true, true),
            (299, false, true, 1, true, true),
            (301, false, true, 1, false, true),
            (3601, false, true, 1, false, false),
            (-60, false, true, 1, false, false),
            (0, true, true, 1, false, true),
            (0, false, false, 1, false, false),
            (0, false, true, 0, false, false),
        ] {
            let mut t = db.pool.begin().await?;
            sqlx::query(
                "INSERT INTO contacts(user_id, username, requested, blocked) VALUES (7, \
                 'scanner', 1, ?)",
            )
            .bind(blocked)
            .execute(&mut *t)
            .await?;
            sqlx::query("INSERT INTO verification_tokens(token, created_at, proof_version) VALUES (?, ?, ?)")
                .bind(&token)
                .bind(chrono::Utc::now().timestamp() - age)
                .bind(proof_version)
                .execute(&mut *t)
                .await?;

            let incoming_proof = encrypted_content::KeyVerificationProof {
                calculated_mac: if valid { proof.clone() } else { vec![0; 32] },
            };
            handle_key_verification_proof(&ctx, &mut t, 7, incoming_proof.clone()).await?;

            let contact = Contact::get_contact_by_id(&mut t, 7).await?.unwrap();
            assert_eq!(
                contact.accepted != 0,
                accepts,
                "token age {age}, blocked {blocked}, valid {valid}"
            );
            assert_eq!(contact.requested != 0, !accepts);
            assert_eq!(contact.blocked != 0, blocked);
            let chats: i64 =
                sqlx::query_scalar("SELECT COUNT(*) FROM groups WHERE is_direct_chat = 1")
                    .fetch_one(&mut *t)
                    .await?;
            assert_eq!(chats, i64::from(accepts));
            let verified: i64 = sqlx::query_scalar(
                "SELECT COUNT(*) FROM key_verifications WHERE type = 'secretQrToken'",
            )
            .fetch_one(&mut *t)
            .await?;
            assert_eq!(verified, i64::from(verifies));

            if accepts {
                // Replaying the proof must not queue another acceptance.
                handle_key_verification_proof(&ctx, &mut t, 7, incoming_proof.clone()).await?;
                let count: i64 = sqlx::query_scalar(
                    "SELECT COUNT(*) FROM key_verifications WHERE contact_id = 7",
                )
                .fetch_one(&mut *t)
                .await?;
                assert_eq!(count, 1, "replaying must not duplicate evidence");

                crate::database::app::key_verifications::writes::delete(&mut t, 7, None).await?;
                handle_key_verification_proof(&ctx, &mut t, 7, incoming_proof).await?;
                assert!(
                    !crate::database::app::key_verifications::queries::is_verified(&mut t, 7)
                        .await?,
                    "replaying must not undo revocation"
                );
            }
            let receipts: Vec<Vec<u8>> =
                sqlx::query_scalar("SELECT message FROM receipts WHERE contact_id = 7")
                    .fetch_all(&mut *t)
                    .await?;
            assert_eq!(receipts.len(), usize::from(accepts));
            if accepts {
                let message = proto::Message::decode(receipts[0].as_slice())?;
                let content =
                    EncryptedContent::decode(message.encrypted_content.unwrap().as_slice())?;
                assert_eq!(
                    content.contact_request.unwrap().r#type,
                    encrypted_content::contact_request::Type::Accept as i32
                );
            }
            t.rollback().await?;
        }
        Ok(())
    }
}
