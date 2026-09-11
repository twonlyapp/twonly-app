/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Every boundary between Rust and the platform.
//!
//! Rust owns the decisions; these modules only hand work to the OS APIs that
//! have no Rust equivalent — hardware codecs, container formats without a Rust
//! decoder, durable background transfer, the photo library and notifications.
//! None of them require the Flutter engine to be running.

pub(crate) mod background;
pub(crate) mod gallery;
pub(crate) mod image;
pub(crate) mod location;
pub(crate) mod notifications;
pub(crate) mod prepare;
pub(crate) mod transfer;
pub(crate) mod video;
