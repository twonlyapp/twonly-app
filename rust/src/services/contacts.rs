/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::messages::incoming::messages::release_deferred_receipts;
use crate::api::messages::outgoing::send_c2c_message_to_contact;
use crate::api::proto::client::{self as proto, encrypted_content};
use crate::api::proto::server_to_client;
use crate::api::Server;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::database::app::contacts::table::{Contact, UpdateContact};
use crate::database::app::groups::native::Group;
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

        if let Some(joined_at) = user.joined_at {
            sqlx::query!(
                "UPDATE contacts SET joined_at = ? WHERE user_id = ?",
                joined_at,
                user.user_id
            )
            .execute(&mut *transaction)
            .await?;
        }

        transaction.commit().await?;

        self.send_contact_request(
            user.user_id,
            encrypted_content::contact_request::Type::Request,
            blocking,
        )
        .await
    }

    /// Whether a v2 Signal session for this peer already exists locally.
    ///
    /// A session built from an inbound prekey message is enough to encrypt for
    /// the peer, even when the server holds no prekey bundle for them.
    pub(crate) async fn has_v2_session(&self, user_id: i64) -> Result<bool> {
        let rust_database = self.ctx.rust_db.read().await.clone();

        Ok(sqlx::query_scalar!(
            "SELECT EXISTS(SELECT 1 FROM signal_sessions WHERE name = ? AND device_id = 1)",
            user_id.to_string(),
        )
        .fetch_one(&rust_database.pool)
        .await?
            != 0)
    }

    pub(crate) async fn establish_signal_session(
        &self, user_id: i64, expected_public_key: Option<Vec<u8>>,
    ) -> Result<()> {
        let user = match Server::get_user_by_id(&self.ctx, user_id).await? {
            ServerResult::Ok(user) => user,
            ServerResult::ErrorCode(code) => {
                // Typed, because the send path drops a message only for an
                // account the server positively denies. Anything else is a
                // reason to try again later.
                if code == crate::api::proto::error::ErrorCode::UserIdNotFound as i32 {
                    return Err(TwonlyError::PeerAccountDeleted(user_id));
                }

                return Err(TwonlyError::Generic(format!(
                    "Could not load prekey bundle for user {user_id}: server error {code}"
                )));
            }
        };

        if let Some(expected_key) = expected_public_key {
            let server_key = user
                .public_identity_key
                .as_ref()
                .ok_or(TwonlyError::ApiResponseMissingField("public_identity_key"))?;

            if server_key != &expected_key {
                return Err(TwonlyError::Generic(format!(
                    "Public identity key mismatch for user {user_id}"
                )));
            }
        }

        self.process_user_prekey_bundle(&user).await?;

        let database = self.ctx.app_db.read().await.clone();

        // The server answered with a bundle, so a previous `UserIdNotFound`
        // (or a manual mark) must not keep the contact blocked.
        sqlx::query!(
            "UPDATE contacts SET signal_version = 'v2', account_deleted = 0, joined_at = \
             COALESCE(?, joined_at) WHERE user_id = ?",
            user.joined_at,
            user_id
        )
        .execute(&database.pool)
        .await?;

        release_deferred_receipts(&database, user_id).await?;

        Ok(())
    }

    pub(crate) async fn request_by_id(
        &self, user_id: i64, expected_public_key: Vec<u8>, blocking: bool,
    ) -> Result<()> {
        self.establish_signal_session(user_id, Some(expected_public_key))
            .await?;

        self.send_contact_request(
            user_id,
            encrypted_content::contact_request::Type::Request,
            blocking,
        )
        .await
    }

    async fn process_user_prekey_bundle(
        &self, user: &server_to_client::response::UserData,
    ) -> Result<()> {
        let missing = TwonlyError::ApiResponseMissingField;

        let pqc_bundle = user
            .pqc_bundle
            .as_ref()
            .ok_or(TwonlyError::PeerHasNoPrekeyBundle(user.user_id))?;

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

        let database = self.ctx.app_db.read().await.clone();
        let mut transaction = database.pool.begin().await?;
        self.ctx
            .user_discovery
            .get()
            .await
            .refresh_session_identity(user.user_id, &mut transaction)
            .await?;
        transaction.commit().await?;

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
            .requested_by_user(false)
            .accepted(true)
            .deleted_by_user(false)
            .build()
            .update(&mut transaction)
            .await?;

        Group::create_direct_chat(&self.ctx, &mut transaction, contact).await?;

        crate::api::messages::incoming::errors::release_after_contact_acceptance(
            &mut transaction,
            contact_id,
        )
        .await?;

        transaction.commit().await?;

        // What they sent while waiting for this is parked on this device.
        crate::api::messages::incoming::spawn_parked_message_retry(&self.ctx);

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
            .requested_by_user(false)
            .accepted(false)
            .deleted_by_user(true)
            .build()
            .update(&mut t)
            .await?;

        t.commit().await?;

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
                        custom_avatar_requested: None,
                        custom_avatar: None,
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
        &self, contact_id: i64, request_type: encrypted_content::contact_request::Type,
        blocking: bool,
    ) -> Result<()> {
        // Recorded here rather than at the call sites so no path can send a
        // request without it: it is what later tells an incoming accept apart
        // from an unsolicited one.
        if request_type == encrypted_content::contact_request::Type::Request {
            let database = self.ctx.app_db.read().await.clone();

            let mut transaction = database.pool.begin().await?;

            UpdateContact::builder()
                .user_id(contact_id)
                .requested_by_user(true)
                .build()
                .update(&mut transaction)
                .await?;

            transaction.commit().await?;
        }

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

/// Records that the server denied this account exists, and lets go of
/// everything still queued for it.
///
/// Only a `UserIdNotFound` answer about this very user may lead here. User IDs
/// are random and a deleted account is never brought back, so the denial is
/// final: nothing queued for the account can be delivered, and asking about it
/// again costs a round trip on every connection. A message the account sends
/// after all clears the mark again, see `handle_decoded_server_message`.
pub(crate) async fn mark_account_deleted(
    database: &crate::database::app::AppDatabase, user_id: i64,
) -> Result<()> {
    let mut transaction = database.pool.begin().await?;

    let contact = sqlx::query!(
        "UPDATE contacts SET account_deleted = 1 WHERE user_id = ? AND account_deleted = 0",
        user_id
    )
    .execute(&mut *transaction)
    .await?
    .rows_affected();

    let announced = sqlx::query!(
        "UPDATE user_discovery_announced_users SET account_deleted = 1 WHERE announced_user_id = \
         ? AND account_deleted = 0",
        user_id
    )
    .execute(&mut *transaction)
    .await?
    .rows_affected();

    let receipts = sqlx::query!("DELETE FROM receipts WHERE contact_id = ?", user_id)
        .execute(&mut *transaction)
        .await?
        .rows_affected();

    transaction.commit().await?;

    if contact + announced + receipts > 0 {
        tracing::info!(
            user_id,
            dropped_receipts = receipts,
            "account no longer exists; dropped everything queued for it"
        );
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::messages::incoming::messages::{queue_encrypted_content, send_queued_receipt};

    #[tokio::test]

    async fn a_deleted_account_is_marked_once_and_nothing_is_queued_or_sent_for_it() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;

        let database = ctx.app_db.read().await.clone();

        sqlx::raw_sql(
            "INSERT INTO contacts(user_id, username) VALUES (7, 'gone'), (8, 'still-here');
             INSERT INTO user_discovery_announced_users(announced_user_id, announced_public_key, \
             public_id) VALUES (7, x'01', 70), (9, x'02', 90);
             INSERT INTO receipts(receipt_id, contact_id, message)
             VALUES ('to-gone-1', 7, x'00'), ('to-gone-2', 7, x'00'), ('to-friend', 8, x'00');",
        )
        .execute(&database.pool)
        .await?;

        mark_account_deleted(&database, 7).await?;

        let flags: (i64, i64, i64) = sqlx::query_as(
            "SELECT (SELECT account_deleted FROM contacts WHERE user_id = 7),
                    (SELECT account_deleted FROM user_discovery_announced_users \
             WHERE announced_user_id = 7),
                    (SELECT account_deleted FROM user_discovery_announced_users \
             WHERE announced_user_id = 9)",
        )
        .fetch_one(&database.pool)
        .await?;

        assert_eq!(flags, (1, 1, 0));

        let receipts: Vec<String> =
            sqlx::query_scalar("SELECT receipt_id FROM receipts ORDER BY receipt_id")
                .fetch_all(&database.pool)
                .await?;

        assert_eq!(receipts, vec!["to-friend"]);

        let mut transaction = database.pool.begin().await?;

        queue_encrypted_content(
            &mut transaction,
            7,
            proto::EncryptedContent {
                text_message: Some(encrypted_content::TextMessage {
                    sender_message_id: "late".into(),
                    text: "hello?".into(),
                    ..Default::default()
                }),
                ..Default::default()
            },
            true,
        )
        .await?;

        transaction.commit().await?;

        let queued: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM receipts WHERE contact_id = 7")
            .fetch_one(&database.pool)
            .await?;

        assert_eq!(queued, 0, "nothing is queued for a deleted account");

        // A receipt that got in before the mark is dropped by the send path
        // itself, without asking the server about the account again.
        sqlx::query(
            "INSERT INTO receipts(receipt_id, contact_id, message) VALUES ('raced', 7, x'00')",
        )
        .execute(&database.pool)
        .await?;

        crate::api::ApiRuntime::close(&ctx).await?;

        send_queued_receipt(&ctx, "raced").await?;

        let left: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM receipts WHERE contact_id = 7")
            .fetch_one(&database.pool)
            .await?;

        assert_eq!(left, 0);

        Ok(())
    }
}
