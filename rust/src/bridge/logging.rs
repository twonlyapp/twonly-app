/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::error::{Result, TwonlyError};
use flutter_rust_bridge::frb;

#[derive(Clone, Copy, Debug)]
pub enum LogLevel {
    Finest,
    Fine,
    Info,
    Warning,
    Shout,
}

/// Adds a Dart record to the Rust-owned application log.
///
/// This only performs a short, serialized append and is synchronous so Dart
/// records cannot be reordered by a collection of unawaited futures.
#[frb(sync)]
pub fn write_log(
    level: LogLevel,
    source: String,
    message: String,
    in_background: bool,
) -> Result<()> {
    crate::log::write_dart_log(level, &source, &message, in_background)
}

pub async fn load_log_file() -> Result<String> {
    tokio::task::spawn_blocking(crate::log::load_log_file)
        .await
        .map_err(|error| TwonlyError::Generic(error.to_string()))?
}

pub async fn read_last_log_lines(line_count: u32) -> Result<String> {
    tokio::task::spawn_blocking(move || crate::log::read_last_log_lines(line_count as usize))
        .await
        .map_err(|error| TwonlyError::Generic(error.to_string()))?
}

pub async fn clean_log_file() -> Result<()> {
    tokio::task::spawn_blocking(crate::log::clean_log_file)
        .await
        .map_err(|error| TwonlyError::Generic(error.to_string()))?
}

/// Truncates `app.log` through its owner instead of unlinking an open file.
pub async fn clear_log_file() -> Result<bool> {
    tokio::task::spawn_blocking(crate::log::clear_log_file)
        .await
        .map_err(|error| TwonlyError::Generic(error.to_string()))?
}
