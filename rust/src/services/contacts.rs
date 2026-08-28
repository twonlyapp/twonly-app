/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::messages::outgoing::send_c2c_message_to_contact;
use crate::api::proto::client::{self as proto, encrypted_content};
use crate::api::proto::server_to_client;
use crate::api::Server;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::database::app::tables::{Contact, Group, UpdateContact};
use crate::error::{Result, TwonlyError};
use crate::signal::engine::FrbPreKeyBundle;
use crate::user_config::UserConfig;
use prost::Message as _;
use std::io::Write as _;
use std::sync::Arc;

pub struct ContactService {
    ctx: Arc<Context>,
}

impl ContactService {
    pub fn new(ctx: &Arc<Context>) -> Self {
        Self { ctx: ctx.clone() }
    }

    pub async fn request_by_username(&self, username: String, blocking: bool) -> Result<()> {
        let user = match Server::get_user_by_username(&self.ctx, username.clone()).await? {
            ServerResult::Ok(user) => user,
            ServerResult::ErrorCode(code) => {
                return Err(TwonlyError::Generic(format!(
                    "User not found or server error: {code}"
                )));
            }
        };

        self.process_user_prekey_bundle(&user).await?;

        let database = self.ctx.app_db.read().await.clone();
        let mut transaction = database.pool.begin().await?;
        UpdateContact::builder()
            .user_id(user.user_id)
            .username(username)
            .signal_version("v2".to_owned())
            .requested(false)
            .blocked(false)
            .deleted_by_user(false)
            .build()
            .insert_on_conflict_update(&mut transaction)
            .await?;
        transaction.commit().await?;
        database.notify_committed(["contacts"]);

        self.send_contact_request(
            user.user_id,
            encrypted_content::contact_request::Type::Request,
            blocking,
        )
        .await
    }

    pub(crate) async fn establish_signal_session(&self, user_id: i64) -> Result<()> {
        let user = match Server::get_user_by_id(&self.ctx, user_id).await? {
            ServerResult::Ok(user) => user,
            ServerResult::ErrorCode(code) => {
                return Err(TwonlyError::Generic(format!(
                    "Could not load prekey bundle for user {user_id}: server error {code}"
                )));
            }
        };
        self.process_user_prekey_bundle(&user).await
    }

    async fn process_user_prekey_bundle(
        &self,
        user: &server_to_client::response::UserData,
    ) -> Result<()> {
        let missing = TwonlyError::ApiResponseMissingField;
        let pqc_bundle = user.pqc_bundle.as_ref().ok_or(missing("pqc_bundle"))?;
        let identity_key = user
            .public_identity_key
            .clone()
            .ok_or(missing("public_identity_key"))?;

        let registration_id = user.registration_id.ok_or(missing("registration_id"))?;

        let (pre_key_id, pre_key_public, kyber_pre_key_id, kyber_pre_key_public, kyber_signature) =
            if let Some(prekey) = &pqc_bundle.prekey {
                (
                    Some(prekey.ecc_pre_key_id as u32),
                    Some(prekey.ecc_pre_key.clone()),
                    prekey.kyber_pre_key_id as u32,
                    prekey.kyber_pre_key.clone(),
                    prekey.kyber_pre_key_signature.clone(),
                )
            } else {
                let prekey = user.prekeys.first();
                (
                    prekey.map(|value| value.id as u32),
                    prekey.map(|value| value.prekey.clone()),
                    pqc_bundle.kyber_signed_prekey_id as u32,
                    pqc_bundle.kyber_signed_prekey.clone(),
                    pqc_bundle.kyber_signed_prekey_signature.clone(),
                )
            };

        self.ctx
            .signal_engine
            .lock()
            .await
            .as_ref()
            .ok_or(TwonlyError::SignalIdentityNotFound)?
            .process_prekey_bundle(
                user.user_id.to_string(),
                1,
                FrbPreKeyBundle {
                    registration_id: registration_id as u32,
                    device_id: 1,
                    pre_key_id,
                    pre_key_public,
                    signed_pre_key_id: pqc_bundle.ecc_signed_prekey_id as u32,
                    signed_pre_key_public: pqc_bundle.ecc_signed_prekey.clone(),
                    signed_pre_key_signature: pqc_bundle.ecc_signed_prekey_signature.clone(),
                    kyber_pre_key_id,
                    kyber_pre_key_public,
                    kyber_pre_key_signature: kyber_signature,
                    identity_key,
                },
            )
            .await?;
        Ok(())
    }

    pub async fn accept_request(&self, contact_id: i64, blocking: bool) -> Result<()> {
        let database = self.ctx.app_db.read().await.clone();
        let mut transaction = database.pool.begin().await?;
        let contact = Contact::get_contact_by_id(&mut transaction, contact_id)
            .await?
            .ok_or_else(|| TwonlyError::Generic("contact request does not exist".into()))?;

        if contact.requested == 0 {
            return Err(TwonlyError::Generic(
                "contact has no pending request".into(),
            ));
        }

        UpdateContact::builder()
            .user_id(contact_id)
            .requested(false)
            .accepted(true)
            .deleted_by_user(false)
            .build()
            .update(&mut transaction)
            .await?;

        Group::create_direct_chat(&self.ctx, &mut transaction, contact).await?;
        transaction.commit().await?;
        database.notify_committed(["contacts", "groups"]);

        self.send_contact_request(
            contact_id,
            encrypted_content::contact_request::Type::Accept,
            blocking,
        )
        .await
    }

    pub async fn reject_request(&self, contact_id: i64, blocking: bool) -> Result<()> {
        let db_app = self.ctx.app_db.read().await.clone();

        let mut t = db_app.pool.begin().await?;

        let contact = Contact::get_contact_by_id(&mut t, contact_id)
            .await?
            .ok_or_else(|| TwonlyError::Generic("contact request does not exist".into()))?;

        if contact.requested == 0 {
            return Err(TwonlyError::Generic(
                "contact has no pending request".into(),
            ));
        }

        UpdateContact::builder()
            .user_id(contact_id)
            .requested(false)
            .accepted(false)
            .deleted_by_user(true)
            .build()
            .update(&mut t)
            .await?;

        t.commit().await?;
        db_app.notify_committed(["contacts"]);

        self.send_contact_request(
            contact_id,
            encrypted_content::contact_request::Type::Reject,
            blocking,
        )
        .await
    }

    pub async fn send_profile(&self, contact_id: i64) -> Result<()> {
        let config = UserConfig::load_required_from(&self.ctx)?;

        let avatar_svg_compressed = config
            .avatar_svg
            .as_deref()
            .map(|avatar| {
                let mut encoder =
                    flate2::write::GzEncoder::new(Vec::new(), flate2::Compression::default());
                encoder.write_all(avatar.as_bytes())?;
                encoder.finish()
            })
            .transpose()?;

        send_c2c_message_to_contact()
            .ctx(&self.ctx)
            .contact_id(contact_id)
            .encrypted_content(
                proto::EncryptedContent {
                    contact_update: Some(encrypted_content::ContactUpdate {
                        r#type: encrypted_content::contact_update::Type::Update as i32,
                        username: Some(config.username),
                        display_name: Some(config.display_name),
                        avatar_svg_compressed,
                    }),
                    ..Default::default()
                }
                .encode_to_vec(),
            )
            .call()
            .await?;

        Ok(())
    }

    async fn send_contact_request(
        &self,
        contact_id: i64,
        request_type: encrypted_content::contact_request::Type,
        blocking: bool,
    ) -> Result<()> {
        send_c2c_message_to_contact()
            .ctx(&self.ctx)
            .contact_id(contact_id)
            .encrypted_content(
                proto::EncryptedContent {
                    contact_request: Some(encrypted_content::ContactRequest {
                        r#type: request_type as i32,
                    }),
                    ..Default::default()
                }
                .encode_to_vec(),
            )
            .blocking(blocking)
            .call()
            .await?;
        Ok(())
    }
}
