/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Chooses between the sealed and the named transport for an outgoing message.
//!
//! A sealed envelope is uploaded anonymously, so the server never learns who
//! sent it. That only works when both sides agree: the recipient has to
//! understand the envelope, and this account has to have the feature enabled.
//! Everything else — an unknown identity key, an empty token pool, a failing
//! upload — falls back to the named transport rather than dropping the message.

use crate::api::messages::incoming::messages::PreparedQueuedReceipt;
use crate::api::sealed_sender::SealedSenderApi;
use crate::context::Context;
use crate::error::{Result, TwonlyError};
use crate::sealed_sender::SealedSender;
use crate::services::privacy_pass::PrivacyPassTokens;
use crate::user_config::UserConfig;
use libsignal_protocol::IdentityKeyPair;
use rand::SeedableRng;
use std::sync::Arc;

pub(crate) struct SealedSenderService;

impl SealedSenderService {
    /// Whether messages to this contact are allowed to travel sealed.
    ///
    /// The contact's flag is only set once they have announced support in an
    /// encrypted content of their own, so a peer that does not understand the
    /// envelope never receives one.
    pub(crate) async fn is_enabled_for(ctx: &Arc<Context>, contact_id: i64) -> Result<bool> {
        // The contact's flag is checked first on purpose. This runs for every
        // queued receipt, and reading the user configuration means a file read
        // and a JSON parse under a process-wide lock, which is far more
        // expensive than an indexed lookup on the primary key.
        let database = ctx.app_db.read().await.clone();
        let contact_accepts = sqlx::query_scalar!(
            "SELECT EXISTS(SELECT 1 FROM contacts WHERE user_id = ? AND sealed_sender_enabled = 1)",
            contact_id,
        )
        .fetch_one(&database.pool)
        .await?
            != 0;
        if !contact_accepts {
            return Ok(false);
        }
        Ok(UserConfig::load_from(ctx)?.is_some_and(|config| config.sealed_sender_enabled))
    }

    /// Tries to deliver a prepared receipt as a sealed envelope.
    ///
    /// Returns `false` when the message has to go out over the named transport
    /// instead. The caller may then send it normally: a receiver that ends up
    /// seeing both copies discards the second one by receipt ID.
    pub(crate) async fn try_send(
        ctx: &Arc<Context>,
        receipt: &PreparedQueuedReceipt,
    ) -> Result<bool> {
        if !Self::is_enabled_for(ctx, receipt.contact_id).await? {
            return Ok(false);
        }

        let Some(recipient_identity) = ctx.get_identity(receipt.contact_id).await? else {
            tracing::info!(
                contact_id = receipt.contact_id,
                "no pinned identity key yet; sending this message named"
            );
            return Ok(false);
        };

        let (from_user_id, sender_identity) = {
            let key_manager = ctx.key_manager.lock().await;
            let Some(from_user_id) = key_manager.user_id else {
                return Ok(false);
            };
            let Some(identity) = key_manager.signal_identity.as_ref() else {
                return Ok(false);
            };
            let identity =
                IdentityKeyPair::try_from(identity.identity_key_pair_structure.as_slice())
                    .map_err(|error| TwonlyError::Signal(error.to_string()))?;
            (from_user_id, identity)
        };

        // An empty pool, or an issuer that refuses to mint, must never hold a
        // message back: it just goes out named instead.
        let token = match PrivacyPassTokens::take(ctx).await {
            Ok(Some(token)) => token,
            Ok(None) => {
                tracing::info!("no Privacy Pass token available; sending this message named");
                return Ok(false);
            }
            Err(error) => {
                tracing::warn!("could not obtain a Privacy Pass token: {error}");
                return Ok(false);
            }
        };

        let envelope = {
            let mut rng = rand::rngs::StdRng::from_os_rng();
            SealedSender::encrypt(
                from_user_id,
                receipt.contact_id,
                receipt.message.clone(),
                &sender_identity,
                recipient_identity.public_key(),
                &mut rng,
            )?
        };

        match SealedSenderApi::upload(receipt.contact_id, envelope, token, receipt.wake_receiver)
            .await
        {
            Ok(message_id) => {
                tracing::info!(
                    receipt_id = receipt.receipt_id,
                    message_id,
                    "sent message via sealed sender"
                );
                Ok(true)
            }
            Err(error) => {
                tracing::warn!("sealed-sender upload failed, falling back to named send: {error}");
                Ok(false)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::database::app::tables::Contact;

    async fn context(
        sealed_sender_enabled: bool,
    ) -> anyhow::Result<(tempfile::TempDir, Arc<Context>)> {
        let temp = tempfile::tempdir()?;
        let data_dir = temp.path().join("data");
        std::fs::create_dir_all(data_dir.join("keyvalue"))?;
        let config = UserConfig {
            sealed_sender_enabled,
            ..Default::default()
        };
        std::fs::write(
            data_dir.join("keyvalue/user.json"),
            serde_json::to_vec(&config)?,
        )?;
        let context = Context::init_for_testing(temp.path().join("database"), data_dir).await?;
        Ok((temp, context))
    }

    async fn insert_contact(ctx: &Arc<Context>, user_id: i64) -> anyhow::Result<()> {
        let database = ctx.app_db.read().await.clone();
        sqlx::query!(
            "INSERT INTO contacts(user_id, username, accepted) VALUES (?, ?, 1)",
            user_id,
            "peer",
        )
        .execute(&database.pool)
        .await?;
        Ok(())
    }

    async fn announce(ctx: &Arc<Context>, user_id: i64, enabled: bool) -> anyhow::Result<()> {
        let database = ctx.app_db.read().await.clone();
        let mut transaction = database.pool.begin().await?;
        Contact::set_sealed_sender_enabled(&mut transaction, user_id, enabled).await?;
        transaction.commit().await?;
        Ok(())
    }

    #[tokio::test]
    async fn a_contact_that_never_announced_support_keeps_the_named_transport() -> anyhow::Result<()>
    {
        let (_temp, ctx) = context(true).await?;
        insert_contact(&ctx, 21).await?;

        assert!(!SealedSenderService::is_enabled_for(&ctx, 21).await?);
        Ok(())
    }

    #[tokio::test]
    async fn both_sides_have_to_enable_the_feature() -> anyhow::Result<()> {
        let (_temp, ctx) = context(true).await?;
        insert_contact(&ctx, 21).await?;
        announce(&ctx, 21, true).await?;

        assert!(SealedSenderService::is_enabled_for(&ctx, 21).await?);

        // The contact withdrawing its announcement is enough to stop sealing.
        announce(&ctx, 21, false).await?;
        assert!(!SealedSenderService::is_enabled_for(&ctx, 21).await?);
        Ok(())
    }

    #[tokio::test]
    async fn the_local_setting_disables_sealing_for_every_contact() -> anyhow::Result<()> {
        let (_temp, ctx) = context(false).await?;
        insert_contact(&ctx, 21).await?;
        announce(&ctx, 21, true).await?;

        assert!(!SealedSenderService::is_enabled_for(&ctx, 21).await?);
        Ok(())
    }

    #[tokio::test]
    async fn an_unknown_contact_is_never_sealed() -> anyhow::Result<()> {
        let (_temp, ctx) = context(true).await?;

        assert!(!SealedSenderService::is_enabled_for(&ctx, 404).await?);
        Ok(())
    }
}
