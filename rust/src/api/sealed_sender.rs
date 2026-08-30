/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Anonymous upload endpoint for sealed-sender envelopes.
//!
//! Unlike every other API call this one carries no session and no
//! authentication header: the whole point is that the server must not learn who
//! sent the envelope. The Privacy Pass token in the request is what keeps the
//! endpoint from becoming an open relay.

use crate::api::proto::http_requests::{SealedSenderMessageRequest, SealedSenderMessageResponse};
use crate::bridge::api::RustApi;
use crate::error::{Result, TwonlyError};
use prost::Message as _;
use std::sync::LazyLock;

/// One shared client, so a sealed upload reuses a pooled connection instead of
/// paying for a TLS handshake per message.
static CLIENT: LazyLock<reqwest::Client> = LazyLock::new(|| {
    reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()
        .expect("the sealed-sender HTTP client must be constructible")
});

pub(crate) struct SealedSenderApi;

impl SealedSenderApi {
    pub(crate) async fn upload(
        recipient_user_id: i64,
        sealed_sender_message: Vec<u8>,
        privacy_pass_token: Vec<u8>,
        wake_receiver: bool,
    ) -> Result<String> {
        let request = SealedSenderMessageRequest {
            recipient_user_id,
            sealed_sender_message,
            privacy_pass_token,
            wake_receiver,
        };

        let response = CLIENT
            .post(format!(
                "{}sealed-sender/messages",
                RustApi::api_base_url("https".into())
            ))
            .header("Content-Type", "application/x-protobuf")
            .body(request.encode_to_vec())
            .send()
            .await
            .map_err(|error| TwonlyError::Generic(error.to_string()))?;

        let status = response.status();
        if !status.is_success() {
            return Err(TwonlyError::Generic(format!(
                "sealed-sender upload returned {status}"
            )));
        }

        let body = response
            .bytes()
            .await
            .map_err(|error| TwonlyError::Generic(error.to_string()))?;
        Ok(SealedSenderMessageResponse::decode(body)
            .map_err(|error| TwonlyError::Generic(error.to_string()))?
            .message_id)
    }
}
