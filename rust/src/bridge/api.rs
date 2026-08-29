/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::messages::incoming::messages;
use crate::api::ApiRuntime;
pub use crate::api::PqcPreKeyInput;
use crate::api::Server;
use crate::context::Context;
use crate::context::RuntimeMode;
use crate::error::{Result, TwonlyError};
use crate::frb_generated::StreamSink;
use crate::services::contacts::ContactService;
use crate::services::messages::MessageService;
use crate::user_config::UserConfig;
use flutter_rust_bridge::frb;

#[frb(ignore)]
pub enum ServerResult<T> {
    Ok(T),
    ErrorCode(i32),
}

fn api_result<T>(result: ServerResult<T>) -> Result<T> {
    match result {
        ServerResult::Ok(value) => Ok(value),
        ServerResult::ErrorCode(code) => Err(TwonlyError::Api(code)),
    }
}

fn empty_api_response(bytes: Vec<u8>) -> Result<()> {
    crate::api::runtime::helpers::decode_empty_ok(bytes).and_then(api_result)
}

#[derive(Clone, Debug)]
pub struct ApiConfig {
    /// Full WebSocket URL, for example `wss://api.twonly.eu/api/client`.
    pub websocket_url: String,
    /// Authentication identity. `None` keeps the transport usable for
    /// unauthenticated registration/recovery requests.
    /// The persisted integer schema/app version used by the legacy-token
    /// migration guard in the Dart implementation.
    pub legacy_user_app_version: i64,
    pub in_background: bool,
    pub can_use_login_token_for_auth: bool,
}

impl ApiConfig {
    pub(crate) async fn from_rust_state(context: &Context) -> Result<Self> {
        let user = UserConfig::load_from(context)?;
        Ok(Self {
            websocket_url: format!("{}client", RustApi::api_base_url("wss".to_owned())),
            legacy_user_app_version: user.as_ref().map_or(0, |value| value.app_version),
            in_background: context.runtime_mode == RuntimeMode::Notification,
            can_use_login_token_for_auth: user
                .as_ref()
                .is_some_and(|value| value.can_use_login_token_for_auth),
        })
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ApiConnectionState {
    Stopped,
    Connecting,
    Connected,
    Authenticating,
    Authenticated,
    Reconnecting,
    Suspended,
    PermanentlyRejected,
}

#[derive(Clone, Debug)]
pub struct ApiEvent {
    pub kind: ApiEventKind,
    pub state: Option<ApiConnectionState>,
    pub message: Option<String>,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ApiEventKind {
    ConnectionStateChanged,
    TransportError,
    Authenticated,
    PlanUpdated,
    AppOutdated,
    NewDeviceRegistered,
    LoginTokenMigrated,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct FrbPasswordlessNotificationMessage {
    pub id: i64,
    pub encrypted_message: Vec<u8>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct FrbUserData {
    pub user_id: i64,
    pub username: Vec<u8>,
    pub public_identity_key: Vec<u8>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct FrbProofOfWork {
    pub prefix: String,
    pub difficulty: i64,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct FrbMemoriesUsage {
    pub current_bytes: i64,
    pub count: i64,
    pub max_bytes: i64,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct FrbAdditionalAccount {
    pub user_id: i64,
    pub plan_id: String,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct FrbPlanBalance {
    pub used_daily_media_upload_limit: i64,
    pub used_upload_media_size_limit: i64,
    pub payment_period_days: Option<i64>,
    pub last_payment_done_unix_timestamp: Option<i64>,
    pub additional_accounts: Vec<FrbAdditionalAccount>,
    pub auto_renewal: Option<bool>,
    pub additional_account_owner_id: Option<i64>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct FrbPresignedPost {
    pub url: String,
    pub fields: Vec<(String, String)>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct FrbMemoriesUploadUrls {
    pub media_id: String,
    pub thumbnail_upload: Option<FrbPresignedPost>,
    pub full_upload: Option<FrbPresignedPost>,
}

/// Flutter-facing facade for the Rust-owned API runtime.
pub struct RustApi {}

impl RustApi {
    pub async fn request_contact_by_username(username: String) -> Result<()> {
        let ctx = Context::get_static()?;
        ContactService::new(ctx)
            .request_by_username(username, false)
            .await
    }

    #[frb(sync)]
    pub fn api_base_url(protocol: String) -> String {
        if cfg!(debug_assertions) {
            format!("{}://dev-api.twonly.eu/api/", protocol)
        } else {
            format!("{}://api.twonly.eu/api/", protocol)
        }
    }

    pub async fn connect() -> Result<()> {
        let ctx = Context::get_static()?;
        ApiRuntime::connect(ctx).await
    }

    /// Reloads identity and authentication settings from Rust-owned storage.
    /// No configuration values are accepted from the caller.
    pub async fn reload_configuration() -> Result<()> {
        let ctx = Context::get_static()?;
        ApiRuntime::reload_configuration(ctx).await
    }

    pub async fn close() -> Result<()> {
        let ctx = Context::get_static()?;
        ApiRuntime::close(ctx).await
    }

    pub async fn connection_state() -> Result<ApiConnectionState> {
        let ctx = Context::get_static()?;
        ApiRuntime::connection_state(ctx).await
    }

    pub async fn set_background(in_background: bool) -> Result<()> {
        let ctx = Context::get_static()?;
        ApiRuntime::set_background(ctx, in_background).await
    }

    pub async fn set_network_available(available: bool) -> Result<()> {
        let ctx = Context::get_static()?;
        ApiRuntime::set_network_available(ctx, available).await
    }

    pub async fn send_binary(bytes: Vec<u8>) -> Result<()> {
        let ctx = Context::get_static()?;
        ApiRuntime::send_binary(ctx, bytes).await
    }

    /// Sends a protobuf ClientToServer envelope. Rust assigns the sequence ID
    /// and resolves this future with the matching ServerToClient response.
    pub async fn request_binary(bytes: Vec<u8>) -> Result<Vec<u8>> {
        let ctx = Context::get_static()?;
        ApiRuntime::request_binary(ctx, bytes).await
    }

    pub async fn allocate_sequence() -> Result<u64> {
        let ctx = Context::get_static()?;
        ApiRuntime::allocate_sequence(ctx).await
    }

    pub async fn events(sink: StreamSink<ApiEvent>) -> Result<()> {
        let ctx = Context::get_static()?;
        ApiRuntime::events(ctx, sink).await
    }

    pub async fn register(
        username: String,
        proof_of_work: i64,
        lang_code: String,
        is_ios: bool,
    ) -> Result<i64> {
        let ctx = Context::get_static()?;
        Server::register(ctx, username, proof_of_work, lang_code, is_ios)
            .await
            .and_then(api_result)
    }

    pub async fn get_user_by_id(user_id: i64) -> Result<FrbUserData> {
        let ctx = Context::get_static()?;
        let res = Server::get_user_by_id(ctx, user_id)
            .await
            .and_then(api_result)?;
        Ok(FrbUserData {
            user_id: res.user_id,
            username: res.username.unwrap_or_default(),
            public_identity_key: res.public_identity_key.unwrap_or_default(),
        })
    }
    pub async fn check_for_deleted_usernames() -> Result<()> {
        let ctx = Context::get_static()?;
        Server::check_for_deleted_usernames(ctx).await
    }
    pub async fn get_user_id_from_username(username: String) -> Result<i64> {
        let ctx = Context::get_static()?;
        Server::get_user_id_from_username(ctx, username)
            .await
            .and_then(api_result)
    }
    pub async fn get_user_data(username: String) -> Result<FrbUserData> {
        let ctx = Context::get_static()?;
        let res = Server::get_user_by_username(ctx, username)
            .await
            .and_then(api_result)?;
        Ok(FrbUserData {
            user_id: res.user_id,
            username: res.username.unwrap_or_default(),
            public_identity_key: res.public_identity_key.unwrap_or_default(),
        })
    }
    pub async fn get_proof_of_work() -> Result<FrbProofOfWork> {
        let ctx = Context::get_static()?;
        let res = Server::get_proof_of_work(ctx).await.and_then(api_result)?;
        Ok(FrbProofOfWork {
            prefix: res.prefix,
            difficulty: res.difficulty,
        })
    }
    pub async fn download_done(token: Vec<u8>) -> Result<()> {
        let ctx = Context::get_static()?;
        Server::download_done(ctx, token).await.and_then(api_result)
    }

    pub async fn download_media(media_id: String) -> Result<()> {
        let ctx = Context::get_static()?;
        crate::services::mediafiles::MediaFileService::new(ctx)
            .download_when_available(&media_id)
            .await
    }

    pub async fn download_pending_media() -> Result<()> {
        let ctx = Context::get_static()?;
        crate::services::mediafiles::MediaFileService::new(ctx)
            .download_pending()
            .await
    }

    pub async fn request_media_reupload(media_id: String) -> Result<()> {
        let ctx = Context::get_static()?;
        crate::services::mediafiles::MediaFileService::new(ctx)
            .request_reupload(&media_id)
            .await
    }
    pub async fn set_login_token(token: Vec<u8>) -> Result<()> {
        let ctx = Context::get_static()?;
        Server::set_login_token(ctx, token)
            .await
            .and_then(api_result)
    }

    pub async fn request_memories_upload(
        size: i64,
        original_date: i64,
        media_id: String,
    ) -> Result<FrbMemoriesUploadUrls> {
        let ctx = Context::get_static()?;
        let res = Server::request_memories_upload(ctx, size, original_date, media_id)
            .await
            .and_then(api_result)?;
        Ok(FrbMemoriesUploadUrls {
            media_id: res.media_id,
            thumbnail_upload: res.thumbnail_upload.map(|p| FrbPresignedPost {
                url: p.url,
                fields: p.fields.into_iter().collect(),
            }),
            full_upload: res.full_upload.map(|p| FrbPresignedPost {
                url: p.url,
                fields: p.fields.into_iter().collect(),
            }),
        })
    }
    pub async fn get_memories_usage() -> Result<FrbMemoriesUsage> {
        let ctx = Context::get_static()?;
        let res = Server::get_memories_usage(ctx).await.and_then(api_result)?;
        Ok(FrbMemoriesUsage {
            current_bytes: res.current_bytes,
            count: res.count,
            max_bytes: res.max_bytes,
        })
    }
    pub async fn get_memories_url(media_id: String, thumbnail: bool) -> Result<String> {
        let ctx = Context::get_static()?;
        let res = Server::get_memories_url(ctx, media_id, thumbnail)
            .await
            .and_then(api_result)?;
        Ok(res.full_download_url)
    }
    pub async fn confirm_memories_upload(media_id: String) -> Result<()> {
        let ctx = Context::get_static()?;
        Server::confirm_memories_upload(ctx, media_id)
            .await
            .and_then(api_result)
    }
    pub async fn delete_memory(media_id: String) -> Result<()> {
        let ctx = Context::get_static()?;
        Server::delete_memory(ctx, media_id)
            .await
            .and_then(api_result)
    }
    pub async fn disable_memories_backup() -> Result<()> {
        let ctx = Context::get_static()?;
        Server::disable_memories_backup(ctx)
            .await
            .and_then(api_result)
    }
    pub async fn get_plan_balance() -> Result<FrbPlanBalance> {
        let ctx = Context::get_static()?;
        let res = Server::get_plan_balance_model(ctx)
            .await
            .and_then(api_result)?;
        Ok(FrbPlanBalance {
            used_daily_media_upload_limit: res.used_daily_media_upload_limit,
            used_upload_media_size_limit: res.used_upload_media_size_limit,
            payment_period_days: res.payment_period_days,
            last_payment_done_unix_timestamp: res.last_payment_done_unix_timestamp,
            additional_accounts: res
                .additional_accounts
                .into_iter()
                .map(|a| FrbAdditionalAccount {
                    user_id: a.user_id,
                    plan_id: a.plan_id,
                })
                .collect(),
            auto_renewal: res.auto_renewal,
            additional_account_owner_id: res.additional_account_owner_id,
        })
    }
    pub async fn load_plan_balance() -> Result<FrbPlanBalance> {
        Self::get_plan_balance().await
    }
    pub async fn remove_additional_user(user_id: i64) -> Result<()> {
        let ctx = Context::get_static()?;
        Server::remove_additional_user(ctx, user_id)
            .await
            .and_then(api_result)
    }
    pub async fn add_additional_user(user_id: i64) -> Result<()> {
        let ctx = Context::get_static()?;
        Server::add_additional_user(ctx, user_id)
            .await
            .and_then(api_result)
    }
    pub async fn register_passwordless_recovery(
        encrypted_server_key: Vec<u8>,
        pin_unlock_token: Option<Vec<u8>>,
    ) -> Result<()> {
        let ctx = Context::get_static()?;
        Server::register_passwordless_recovery(ctx, encrypted_server_key, pin_unlock_token)
            .await
            .and_then(api_result)
    }
    pub async fn perform_passwordless_recovery_heartbeat() -> Result<()> {
        let ctx = Context::get_static()?;
        crate::api::messages::incoming::recovery::perform_heartbeat(ctx).await
    }
    pub async fn get_server_key_for_passwordless_recovery(
        user_id: i64,
        server_key_protection: Vec<u8>,
        pin_unlock_token: Option<Vec<u8>>,
        pin_protection_key: Option<Vec<u8>>,
        email: Option<String>,
    ) -> Result<Vec<u8>> {
        let ctx = Context::get_static()?;
        Server::get_server_key_for_passwordless_recovery(
            ctx,
            user_id,
            server_key_protection,
            pin_unlock_token,
            pin_protection_key,
            email,
        )
        .await
        .and_then(api_result)
    }
    pub async fn submit_recovery_share(
        notification_id: String,
        encrypted_message: Vec<u8>,
    ) -> Result<()> {
        let ctx = Context::get_static()?;
        Server::submit_recovery_share(ctx, notification_id, encrypted_message)
            .await
            .and_then(api_result)
    }
    pub async fn register_passwordless_notification(
        notification_id: String,
        download_auth_token: Vec<u8>,
        lang_code: String,
        google_fcm: Option<String>,
    ) -> Result<()> {
        let ctx = Context::get_static()?;
        Server::register_passwordless_notification(
            ctx,
            notification_id,
            download_auth_token,
            lang_code,
            google_fcm,
        )
        .await
        .and_then(api_result)
    }

    pub async fn check_for_passwordless_notification(
        notification_id: String,
        download_auth_token: Vec<u8>,
        already_received_message_ids: Vec<i64>,
    ) -> Result<Vec<FrbPasswordlessNotificationMessage>> {
        let ctx = Context::get_static()?;
        let res = Server::check_for_passwordless_notification(
            ctx,
            notification_id,
            download_auth_token,
            already_received_message_ids,
        )
        .await
        .and_then(api_result)?;
        Ok(res
            .messages
            .into_iter()
            .map(|msg| FrbPasswordlessNotificationMessage {
                id: msg.id,
                encrypted_message: msg.encrypted_message,
            })
            .collect())
    }

    pub async fn report_user(user_id: i64, reason: String) -> Result<()> {
        let ctx = Context::get_static()?;
        Server::report_user(ctx, user_id, reason)
            .await
            .and_then(api_result)
    }
    pub async fn delete_account() -> Result<()> {
        let ctx = Context::get_static()?;
        Server::delete_account(ctx).await.and_then(api_result)
    }
    pub async fn update_fcm_token(token: String) -> Result<()> {
        let ctx = Context::get_static()?;
        Server::update_fcm_token(ctx, token)
            .await
            .and_then(api_result)
    }
    pub async fn ipa_purchase(
        product_id: String,
        source: String,
        verification_data: String,
    ) -> Result<()> {
        let ctx = Context::get_static()?;
        empty_api_response(Server::ipa_purchase(ctx, product_id, source, verification_data).await?)
    }
    pub async fn change_username(username: String) -> Result<()> {
        let ctx = Context::get_static()?;
        Server::change_username(ctx, username)
            .await
            .and_then(api_result)
    }
    pub async fn force_ipa_check() -> Result<()> {
        let ctx = Context::get_static()?;
        Server::force_ipa_check(ctx).await.and_then(api_result)
    }
    pub async fn update_signed_pre_key(id: i64, key: Vec<u8>, signature: Vec<u8>) -> Result<()> {
        let ctx = Context::get_static()?;
        empty_api_response(Server::update_signed_pre_key(ctx, id, key, signature).await?)
    }
    #[allow(clippy::too_many_arguments)]
    pub async fn upload_pqc_pre_keys(
        public_identity_key: Vec<u8>,
        registration_id: i64,
        ecc_signed_prekey_id: i64,
        ecc_signed_prekey: Vec<u8>,
        ecc_signed_prekey_signature: Vec<u8>,
        kyber_signed_prekey_id: i64,
        kyber_signed_prekey: Vec<u8>,
        kyber_signed_prekey_signature: Vec<u8>,
        prekeys: Vec<PqcPreKeyInput>,
    ) -> Result<()> {
        let ctx = Context::get_static()?;
        Server::upload_pqc_pre_keys(
            ctx,
            public_identity_key,
            registration_id,
            ecc_signed_prekey_id,
            ecc_signed_prekey,
            ecc_signed_prekey_signature,
            kyber_signed_prekey_id,
            kyber_signed_prekey,
            kyber_signed_prekey_signature,
            prekeys,
        )
        .await
        .and_then(empty_api_response)
    }
    pub async fn send_text_message(user_id: i64, body: Vec<u8>) -> Result<()> {
        let ctx = Context::get_static()?;
        Server::send_text_message(ctx, user_id, body, false)
            .await
            .and_then(api_result)
    }

    pub async fn send_encrypted_content(
        contact_id: i64,
        content: Vec<u8>,
        message_id: Option<String>,
        only_send_if_no_receipts_are_open: Option<bool>,
        only_return_encrypted_data: Option<bool>,
        blocking: Option<bool>,
    ) -> Result<Option<Vec<u8>>> {
        let ctx = Context::get_static()?;
        crate::api::messages::outgoing::send_c2c_message_to_contact()
            .ctx(ctx)
            .contact_id(contact_id)
            .encrypted_content(content)
            .maybe_message_id(message_id)
            .only_send_if_no_receipts_are_open(only_send_if_no_receipts_are_open.unwrap_or(false))
            .only_return_encrypted_data(only_return_encrypted_data.unwrap_or(false))
            .blocking(blocking.unwrap_or(false))
            .call()
            .await
            .map_err(Into::into)
    }

    pub async fn send_encrypted_content_to_group(
        group_id: String,
        content: Vec<u8>,
        message_id: Option<String>,
        only_send_if_no_receipts_are_open: Option<bool>,
    ) -> Result<()> {
        let ctx = Context::get_static()?;
        crate::services::messages::MessageService::new(ctx)
            .send_to_group(
                group_id,
                content,
                message_id,
                only_send_if_no_receipts_are_open.unwrap_or(false),
            )
            .await
    }

    pub async fn insert_and_send_text(
        group_id: String,
        text: String,
        quote_message_id: Option<String>,
    ) -> Result<String> {
        let ctx = Context::get_static()?;
        crate::services::messages::MessageService::new(ctx)
            .insert_and_send_text(group_id, text, quote_message_id)
            .await
    }

    pub async fn insert_and_send_additional_data(
        group_id: String,
        message_type: String,
        additional_data: Vec<u8>,
    ) -> Result<String> {
        let ctx = Context::get_static()?;
        crate::services::messages::MessageService::new(ctx)
            .insert_and_send_additional_data(group_id, message_type, additional_data)
            .await
    }

    pub async fn insert_and_send_contact_share(
        group_id: String,
        contact_ids: Vec<i64>,
    ) -> Result<String> {
        let ctx = Context::get_static()?;
        crate::services::messages::MessageService::new(ctx)
            .insert_and_send_contact_share(group_id, contact_ids)
            .await
    }

    pub async fn insert_and_send_ask_about_user(
        contact_id: i64,
        ask_about_user_id: i64,
    ) -> Result<String> {
        let ctx = Context::get_static()?;
        crate::services::messages::MessageService::new(ctx)
            .insert_and_send_ask_about_user(contact_id, ask_about_user_id)
            .await
    }

    pub async fn send_typing(group_id: String, is_typing: bool) -> Result<()> {
        let ctx = Context::get_static()?;
        crate::services::messages::MessageService::new(ctx)
            .send_typing(group_id, is_typing)
            .await
    }

    pub async fn retransmit_all_messages() -> Result<()> {
        let ctx = Context::get_static()?;
        crate::services::messages::MessageService::new(ctx)
            .retransmit_all()
            .await
    }

    pub async fn send_queued_message(receipt_id: String) -> Result<()> {
        let ctx = Context::get_static()?;
        crate::services::messages::MessageService::new(ctx)
            .send_receipt(receipt_id)
            .await
    }

    pub async fn prepare_queued_message(receipt_id: String) -> Result<Option<Vec<u8>>> {
        messages::prepare_queued_receipt(Context::get_static()?, &receipt_id)
            .await
            .map_err(Into::into)
    }

    pub async fn notify_messages_opened(contact_id: i64, message_ids: Vec<String>) -> Result<()> {
        let ctx = Context::get_static()?;
        MessageService::new(ctx)
            .notify_opened(contact_id, message_ids)
            .await
    }

    pub async fn send_contact_profile(contact_id: i64) -> Result<()> {
        let ctx = Context::get_static()?;
        ContactService::new(ctx).send_profile(contact_id).await
    }

    pub async fn establish_signal_session(
        contact_id: i64,
        expected_public_key: Option<Vec<u8>>,
    ) -> Result<()> {
        let ctx = Context::get_static()?;
        ContactService::new(ctx)
            .establish_signal_session(contact_id, expected_public_key)
            .await
    }
}
