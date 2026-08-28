/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

#![allow(unexpected_cfgs)]
pub mod api;
pub mod callbacks;
pub mod groups;
pub mod user_config;
pub mod wrapper;


use crate::context::Context;
use crate::error::Result;
use flutter_rust_bridge::frb;

pub use crate::user_discovery::AnnouncedUser;
pub use crate::user_discovery::OtherPromotion;

pub struct InitConfig {
    pub database_dir: String,
    pub data_dir: String,
}

#[frb(mirror(OtherPromotion))]
pub struct _OtherPromotion {
    pub promotion_id: u32,
    pub public_id: i64,
    pub from_contact_id: i64,
    pub threshold: u8,
    pub announcement_share: Vec<u8>,
    pub public_key_verified_timestamp: Option<i64>,
}

#[frb(mirror(AnnouncedUser))]
pub struct _AnnouncedUser {
    pub user_id: i64,
    pub public_key: Vec<u8>,
    pub public_id: i64,
}

pub(super) fn get_twonly_flutter() -> Result<&'static Context> {
    let ctx = Context::get_static()?;
    Ok(&**ctx)
}

pub async fn initialize_twonly_flutter(config: InitConfig) -> Result<()> {
    Context::init_flutter(config).await?;
    Ok(())
}

/// Initializes the complete Rust runtime without Flutter or callback setup.
/// Background executables should call this before using `RustApi`.
pub async fn initialize_twonly_standalone(config: InitConfig) -> Result<()> {
    Context::init_standalone(config).await
}
