/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::Server;
use crate::api::proto::{client_to_server, server_to_client};
use crate::api::runtime::helpers::decode_ok_value;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::error::{Result, TwonlyError};
use std::sync::atomic::Ordering;
use std::sync::Arc;

pub struct PqcPreKeyInput {
    pub ecc_pre_key_id: i64,
    pub ecc_pre_key: Vec<u8>,
    pub kyber_pre_key_id: i64,
    pub kyber_pre_key: Vec<u8>,
    pub kyber_pre_key_signature: Vec<u8>,
}

impl Server {
    /// Publishes a signed PQC prekey when the server holds none for this
    /// account.
    ///
    /// The bundle is otherwise only published by the registration handshake, so
    /// an account created before that existed keeps no `pqc_bundle` and no code
    /// path ever creates one. Peers then cannot open a session with it at all,
    /// and every message they queue for us fails forever. Checking once per
    /// connection lets such an account heal itself.
    pub async fn ensure_pqc_bundle_published(ctx: &Arc<Context>) -> Result<()> {
        if ctx.pqc_bundle_verified.load(Ordering::Acquire) {
            return Ok(());
        }

        let user_id = ctx.user_id().await?;
        let bytes = Self::application(
            ctx,
            client_to_server::application_data::ApplicationData::GetUserById(
                client_to_server::application_data::GetUserById { user_id },
            ),
        )
        .await?;
        let user = match decode_ok_value(bytes, |value| match value {
            server_to_client::response::ok::Ok::Userdata(user) => Some(user),
            _ => None,
        })? {
            ServerResult::Ok(user) => user,
            ServerResult::ErrorCode(code) => {
                return Err(TwonlyError::Generic(format!(
                    "could not read back this account to check its prekey bundle: server error {code}"
                )));
            }
        };

        if user.pqc_bundle.is_none() {
            tracing::info!("server holds no PQC prekey bundle for this account; publishing one");
            Self::generate_and_upload_pqc_pre_keys(ctx).await?;
        }

        ctx.pqc_bundle_verified.store(true, Ordering::Release);
        Ok(())
    }

    #[doc(hidden)]
    pub async fn generate_and_upload_pqc_pre_keys(ctx: &Arc<Context>) -> Result<Vec<u8>> {
        let engine = ctx.signal_engine.lock().await;
        let bundle = engine
            .as_ref()
            .ok_or(crate::error::TwonlyError::SignalIdentityNotFound)?
            .generate_bundle()
            .await?;
        let prekeys = engine
            .as_ref()
            .ok_or(crate::error::TwonlyError::SignalIdentityNotFound)?
            .generate_pqc_prekeys()
            .await?
            .into_iter()
            .map(|key| PqcPreKeyInput {
                ecc_pre_key_id: i64::from(key.ecc_pre_key_id),
                ecc_pre_key: key.ecc_pre_key,
                kyber_pre_key_id: i64::from(key.kyber_pre_key_id),
                kyber_pre_key: key.kyber_pre_key,
                kyber_pre_key_signature: key.kyber_pre_key_signature,
            })
            .collect();
        drop(engine);

        Self::upload_pqc_pre_keys(
            ctx,
            bundle.identity_key,
            i64::from(bundle.registration_id),
            i64::from(bundle.signed_pre_key_id),
            bundle.signed_pre_key_public,
            bundle.signed_pre_key_signature,
            i64::from(bundle.kyber_pre_key_id),
            bundle.kyber_pre_key_public,
            bundle.kyber_pre_key_signature,
            prekeys,
        )
        .await
    }

    pub async fn update_signed_pre_key(
        ctx: &Arc<Context>,
        id: i64,
        key: Vec<u8>,
        signature: Vec<u8>,
    ) -> Result<Vec<u8>> {
        Self::application(
            ctx,
            client_to_server::application_data::ApplicationData::UpdateSignedPrekey(
                client_to_server::application_data::UpdateSignedPreKey {
                    signed_prekey_id: id,
                    signed_prekey: key,
                    signed_prekey_signature: signature,
                },
            ),
        )
        .await
    }

    #[allow(clippy::too_many_arguments)]
    pub async fn upload_pqc_pre_keys(
        ctx: &Arc<Context>,
        public_identity_key: Vec<u8>,
        registration_id: i64,
        ecc_signed_prekey_id: i64,
        ecc_signed_prekey: Vec<u8>,
        ecc_signed_prekey_signature: Vec<u8>,
        kyber_signed_prekey_id: i64,
        kyber_signed_prekey: Vec<u8>,
        kyber_signed_prekey_signature: Vec<u8>,
        prekeys: Vec<PqcPreKeyInput>,
    ) -> Result<Vec<u8>> {
        let prekeys = prekeys
            .into_iter()
            .map(|key| client_to_server::application_data::PqcPreKey {
                ecc_pre_key_id: key.ecc_pre_key_id,
                ecc_pre_key: key.ecc_pre_key,
                kyber_pre_key_id: key.kyber_pre_key_id,
                kyber_pre_key: key.kyber_pre_key,
                kyber_pre_key_signature: key.kyber_pre_key_signature,
            })
            .collect();
        Self::application(
            ctx,
            client_to_server::application_data::ApplicationData::UploadPqcPrekeys(
                client_to_server::application_data::UploadPqcPreKeys {
                    ecc_signed_prekey_id,
                    ecc_signed_prekey,
                    ecc_signed_prekey_signature,
                    kyber_signed_prekey_id,
                    kyber_signed_prekey,
                    kyber_signed_prekey_signature,
                    prekeys,
                    public_identity_key: Some(public_identity_key),
                    registration_id: Some(registration_id),
                },
            ),
        )
        .await
    }
}
