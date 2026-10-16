/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

#![allow(clippy::derive_partial_eq_without_eq)]

include!(concat!(env!("OUT_DIR"), "/websocket_protocol.rs"));

pub mod client {
    include!(concat!(env!("OUT_DIR"), "/client_messages.rs"));
}

pub mod http_requests {
    include!(concat!(env!("OUT_DIR"), "/http_requests.rs"));
}
