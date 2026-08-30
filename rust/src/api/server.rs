/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

mod account;
mod contacts;
mod memories;
mod passwordless;
pub mod prekeys;
mod privacy_pass;
mod purchases;
mod transport;

pub struct Server;

macro_rules! server_ok {
    ($body:expr) => {
        decode_ok_value($body, |value| match value {
            ResponseOk::None(_) => Some(()),
            _ => None,
        })
    };
}

pub(crate) use server_ok;
