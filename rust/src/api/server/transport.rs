/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::Server;
use crate::api::{proto::client_to_server, ApiRuntime};
use crate::context::Context;
use crate::error::Result;
use prost::Message as _;
use std::sync::Arc;

impl Server {
    fn application_request(
        application: client_to_server::application_data::ApplicationData,
    ) -> Vec<u8> {
        client_to_server::ClientToServer {
            v: Some(client_to_server::client_to_server::V::V0(
                client_to_server::V0 {
                    seq: 0,
                    kind: Some(client_to_server::v0::Kind::Applicationdata(
                        client_to_server::ApplicationData {
                            application_data: Some(application),
                        },
                    )),
                },
            )),
        }
        .encode_to_vec()
    }

    fn handshake_request(handshake: client_to_server::handshake::Handshake) -> Vec<u8> {
        client_to_server::ClientToServer {
            v: Some(client_to_server::client_to_server::V::V0(
                client_to_server::V0 {
                    seq: 0,
                    kind: Some(client_to_server::v0::Kind::Handshake(
                        client_to_server::Handshake {
                            handshake: Some(handshake),
                        },
                    )),
                },
            )),
        }
        .encode_to_vec()
    }

    pub(super) async fn application(
        ctx: &Arc<Context>,
        value: client_to_server::application_data::ApplicationData,
    ) -> Result<Vec<u8>> {
        ApiRuntime::request_authenticated(ctx, Self::application_request(value), None).await
    }

    pub(super) async fn application_for_contact(
        ctx: &Arc<Context>,
        value: client_to_server::application_data::ApplicationData,
        contact_id: i64,
    ) -> Result<Vec<u8>> {
        ApiRuntime::request_authenticated(ctx, Self::application_request(value), Some(contact_id))
            .await
    }

    pub(super) async fn durable_application(
        ctx: &Arc<Context>,
        value: client_to_server::application_data::ApplicationData,
        kind: &'static str,
    ) -> Result<Vec<u8>> {
        ApiRuntime::request_durable_authenticated(ctx, Self::application_request(value), kind).await
    }

    pub(super) async fn handshake(
        ctx: &Arc<Context>,
        value: client_to_server::handshake::Handshake,
    ) -> Result<Vec<u8>> {
        ApiRuntime::request_binary(ctx, Self::handshake_request(value)).await
    }
}
