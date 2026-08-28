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
use libsignal_protocol::{GenericSignedPreKey, IdentityKeyPair, SignedPreKeyRecord};
use std::sync::Arc;

impl Server {
    pub async fn register(
        ctx: &Arc<Context>,
        username: String,
        proof_of_work: i64,
        lang_code: String,
        is_ios: bool,
    ) -> Result<ServerResult<i64>> {
        let key_manager = ctx.key_manager.lock().await;
        let identity = key_manager
            .signal_identity
            .as_ref()
            .ok_or(TwonlyError::SignalIdentityNotFound)?;
        let identity_pair =
            IdentityKeyPair::try_from(identity.identity_key_pair_structure.as_slice())
                .map_err(|error| TwonlyError::Signal(error.to_string()))?;
        let (&signed_prekey_id, record) = identity
            .pre_key_store
            .iter()
            .min_by_key(|(id, _)| *id)
            .ok_or_else(|| {
            TwonlyError::Generic("Signal signed-prekey store is empty".into())
        })?;
        let signed_prekey = SignedPreKeyRecord::deserialize(record)
            .map_err(|error| TwonlyError::Signal(error.to_string()))?;
        let login_token = key_manager.main_key.get_login_token().to_vec();
        let register = client_to_server::handshake::Register {
            username,
            invite_code: None,
            public_identity_key: identity_pair.identity_key().serialize().to_vec(),
            signed_prekey: signed_prekey
                .public_key()
                .map_err(|error| TwonlyError::Signal(error.to_string()))?
                .serialize()
                .to_vec(),
            signed_prekey_signature: signed_prekey
                .signature()
                .map_err(|error| TwonlyError::Signal(error.to_string()))?,
            signed_prekey_id,
            registration_id: identity.registration_id,
            is_ios,
            lang_code,
            proof_of_work,
            login_token: Some(login_token),
        };
        drop(key_manager);

        let bytes = Self::handshake(
            ctx,
            client_to_server::handshake::Handshake::Register(register),
        )
        .await?;

        decode_ok_value(bytes, |value| match value {
            ResponseOk::Userid(id) => Some(id),
            _ => None,
        })
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
