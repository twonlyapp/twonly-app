/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::Server;
use crate::api::proto::client_to_server;
use crate::api::proto::server_to_client::response::ok::Ok as ResponseOk;
use crate::api::proto::server_to_client::response::PrivacyPassParameters;
use crate::api::runtime::helpers::decode_ok_value;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::error::Result;
use std::sync::Arc;

impl Server {
    /// Loads the current issuance parameters: the daily token challenge, the
    /// issuer public key and the limits the client has to stay inside.
    pub(crate) async fn get_privacy_pass_parameters(
        ctx: &Arc<Context>,
    ) -> Result<ServerResult<PrivacyPassParameters>> {
        let bytes = Self::application(
            ctx,
            client_to_server::application_data::ApplicationData::GetPrivacyPassParameters(
                client_to_server::application_data::GetPrivacyPassParameters {},
            ),
        )
        .await?;
        decode_ok_value(bytes, |value| match value {
            ResponseOk::PrivacyPassParameters(parameters) => Some(parameters),
            _ => None,
        })
    }

    /// Exchanges blinded token requests for the server's blinded evaluations.
    ///
    /// This runs over the authenticated socket, so the server counts the tokens
    /// against this account's daily quota. The tokens themselves are unlinkable
    /// to it once they are finalized.
    pub(crate) async fn issue_privacy_pass_tokens(
        ctx: &Arc<Context>,
        token_requests: Vec<Vec<u8>>,
    ) -> Result<ServerResult<Vec<Vec<u8>>>> {
        let bytes = Self::application(
            ctx,
            client_to_server::application_data::ApplicationData::IssuePrivacyPassTokens(
                client_to_server::application_data::IssuePrivacyPassTokens { token_requests },
            ),
        )
        .await?;
        decode_ok_value(bytes, |value| match value {
            ResponseOk::PrivacyPassTokenResponses(responses) => Some(responses.token_responses),
            _ => None,
        })
    }
}
