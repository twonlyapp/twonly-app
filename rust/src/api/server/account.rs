/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::{server_ok, Server};
use crate::api::proto::client_to_server;
use crate::api::proto::server_to_client::response::{ok::Ok as ResponseOk, ProofOfWork};
use crate::api::runtime::helpers::decode_ok_value;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::error::{Result, TwonlyError};
use std::sync::Arc;

impl Server {
    pub async fn register(
        ctx: &Arc<Context>,
        username: String,
        proof_of_work: i64,
        lang_code: String,
        is_ios: bool,
    ) -> Result<ServerResult<i64>> {
        let mut key_manager = ctx.key_manager.lock().await;
        if key_manager.signal_identity.is_none() {
            let identity = crate::keys::SignalIdentityKey::generate()?;
            key_manager.signal_identity = Some(identity);
            key_manager.store_to_keychain(&ctx.secure_storage)?;
        }
        let identity = key_manager
            .signal_identity
            .as_ref()
            .ok_or(TwonlyError::SignalIdentityNotFound)?;

        let identity_key_pair_structure = identity.identity_key_pair_structure.clone();
        let registration_id = identity.registration_id;
        let login_token = key_manager.main_key.get_login_token().to_vec();
        drop(key_manager);

        let database = ctx.rust_db.read().await.clone();
        let registration_engine = crate::signal::engine::RustSignalEngine::new_with_pool(
            database.pool.clone(),
            identity_key_pair_structure.clone(),
            registration_id as u32,
            "pending-registration".to_string(),
        )?;
        let bundle = registration_engine.generate_bundle().await?;
        let prekeys = registration_engine
            .generate_pqc_prekeys()
            .await?
            .into_iter()
            .map(
                |key| client_to_server::handshake::initial_pqc_keys::PqcPreKey {
                    ecc_pre_key_id: i64::from(key.ecc_pre_key_id),
                    ecc_pre_key: key.ecc_pre_key,
                    kyber_pre_key_id: i64::from(key.kyber_pre_key_id),
                    kyber_pre_key: key.kyber_pre_key,
                    kyber_pre_key_signature: key.kyber_pre_key_signature,
                },
            )
            .collect();
        let initial_pqc_keys = client_to_server::handshake::InitialPqcKeys {
            public_identity_key: bundle.identity_key,
            registration_id: i64::from(bundle.registration_id),
            ecc_signed_prekey_id: i64::from(bundle.signed_pre_key_id),
            ecc_signed_prekey: bundle.signed_pre_key_public,
            ecc_signed_prekey_signature: bundle.signed_pre_key_signature,
            kyber_signed_prekey_id: i64::from(bundle.kyber_pre_key_id),
            kyber_signed_prekey: bundle.kyber_pre_key_public,
            kyber_signed_prekey_signature: bundle.kyber_pre_key_signature,
            prekeys,
        };
        let register = client_to_server::handshake::Register {
            username,
            invite_code: None,
            public_identity_key: None,
            signed_prekey: None,
            signed_prekey_signature: None,
            signed_prekey_id: None,
            registration_id: None,
            is_ios,
            lang_code,
            proof_of_work,
            login_token: Some(login_token),
            initial_pqc_keys: Some(initial_pqc_keys),
        };

        let bytes = Self::handshake(
            ctx,
            client_to_server::handshake::Handshake::Register(register),
        )
        .await?;

        let res = decode_ok_value(bytes, |value| match value {
            ResponseOk::Userid(id) => Some(id),
            _ => None,
        })?;

        if let ServerResult::Ok(user_id) = res {
            let mut key_manager = ctx.key_manager.lock().await;
            key_manager.user_id = Some(user_id);
            key_manager.store_to_keychain(&ctx.secure_storage)?;
            let signal_identity = key_manager.signal_identity.as_ref().map(|identity| {
                (
                    identity.identity_key_pair_structure.clone(),
                    identity.registration_id,
                )
            });
            drop(key_manager);

            if let Some((identity_key_pair_structure, registration_id)) = signal_identity {
                let database = ctx.rust_db.read().await.clone();
                *ctx.signal_engine.lock().await =
                    Some(crate::signal::engine::RustSignalEngine::new_with_pool(
                        database.pool.clone(),
                        identity_key_pair_structure,
                        registration_id as u32,
                        user_id.to_string(),
                    )?);
            }

            let now = crate::utils::current_time().with_timezone(&chrono::Utc);
            let _ = crate::user_config::UserConfig::update(ctx, |config| {
                config.signal_last_signed_pre_key_updated = Some(now);
                config.signal_last_pqc_pre_keys_uploaded = Some(now);
            });
            let _ = crate::api::ApiRuntime::reload_configuration(ctx).await;
        }

        Ok(res)
    }

    pub async fn get_proof_of_work(ctx: &Arc<Context>) -> Result<ServerResult<ProofOfWork>> {
        let bytes = Self::handshake(
            ctx,
            client_to_server::handshake::Handshake::RequestPow(
                client_to_server::handshake::RequestPow {},
            ),
        )
        .await?;

        decode_ok_value(bytes, |value| match value {
            ResponseOk::ProofOfWork(p) => Some(p),
            _ => None,
        })
    }

    pub async fn download_done(
        ctx: &Arc<Context>,
        download_token: Vec<u8>,
    ) -> Result<ServerResult<()>> {
        server_ok!(
            Self::durable_application(
                ctx,
                client_to_server::application_data::ApplicationData::DownloadDone(
                    client_to_server::application_data::DownloadDone { download_token },
                ),
                "download_done",
            )
            .await?
        )
    }

    pub async fn set_login_token(
        ctx: &Arc<Context>,
        login_token: Vec<u8>,
    ) -> Result<ServerResult<()>> {
        server_ok!(
            Self::application(
                ctx,
                client_to_server::application_data::ApplicationData::SetLoginToken(
                    client_to_server::application_data::SetLoginToken { login_token },
                ),
            )
            .await?
        )
    }

    pub async fn delete_account(ctx: &Arc<Context>) -> Result<ServerResult<()>> {
        server_ok!(
            Self::application(
                ctx,
                client_to_server::application_data::ApplicationData::DeleteAccount(
                    client_to_server::application_data::DeleteAccount {},
                ),
            )
            .await?
        )
    }

    pub async fn update_fcm_token(
        ctx: &Arc<Context>,
        google_fcm: String,
    ) -> Result<ServerResult<()>> {
        server_ok!(
            Self::application(
                ctx,
                client_to_server::application_data::ApplicationData::UpdateGoogleFcmToken(
                    client_to_server::application_data::UpdateGoogleFcmToken { google_fcm },
                ),
            )
            .await?
        )
    }

    pub async fn change_username(ctx: &Arc<Context>, username: String) -> Result<ServerResult<()>> {
        server_ok!(
            Self::application(
                ctx,
                client_to_server::application_data::ApplicationData::ChangeUsername(
                    client_to_server::application_data::ChangeUsername { username },
                ),
            )
            .await?
        )
    }
}
