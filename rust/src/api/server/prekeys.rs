/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::Server;
use crate::api::proto::client_to_server;
use crate::context::Context;
use crate::error::Result;
use std::sync::Arc;

pub struct PqcPreKeyInput {
    pub ecc_pre_key_id: i64,
    pub ecc_pre_key: Vec<u8>,
    pub kyber_pre_key_id: i64,
    pub kyber_pre_key: Vec<u8>,
    pub kyber_pre_key_signature: Vec<u8>,
}

impl Server {
    #[doc(hidden)]
    pub async fn generate_and_upload_pqc_pre_keys(ctx: &Arc<Context>) -> Result<Vec<u8>> {
        let engine = ctx.signal_engine.lock().await;
        let bundle = engine
            .as_ref()
            .ok_or(crate::error::TwonlyError::SignalIdentityNotFound)?
            .generate_bundle()
            .await?;
        drop(engine);

        Self::upload_pqc_pre_keys(
            ctx,
            i64::from(bundle.signed_pre_key_id),
            bundle.signed_pre_key_public,
            bundle.signed_pre_key_signature,
            i64::from(bundle.kyber_pre_key_id),
            bundle.kyber_pre_key_public,
            bundle.kyber_pre_key_signature,
            Vec::new(),
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
                },
            ),
        )
        .await
    }
}
