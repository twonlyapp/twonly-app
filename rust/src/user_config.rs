/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use serde::{Deserialize, Serialize};
use std::{fs::File, path::PathBuf};

use crate::{
    context::Context,
    error::{twonly_error, Result, TwonlyError},
};

fn default_required_send_images() -> i64 {
    4
}

fn default_can_use_login_token_for_auth() -> bool {
    true
}

/// Read-only Rust view of the persisted `user.json` file.
///
/// This deliberately contains only fields consumed by Rust. Unknown Dart
/// fields are ignored by Serde. Loading uses `File::open`, so this module can
/// never create, truncate, or modify the configuration file.
#[derive(Clone, Debug, Deserialize, Serialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct UserConfig {
    pub user_id: Option<i64>,
    #[serde(default)]
    pub device_id: i64,
    #[serde(default)]
    pub app_version: i64,

    #[serde(default = "default_can_use_login_token_for_auth")]
    pub can_use_login_token_for_auth: bool,
    #[serde(default)]
    pub is_user_discovery_enabled: bool,
    #[serde(default = "default_required_send_images")]
    pub required_send_images: i64,
    #[serde(default)]
    pub user_discovery_requires_manual_approval: bool,
    pub username: Option<String>,
    pub display_name: Option<String>,
    pub avatar_svg: Option<String>,
    #[serde(default)]
    pub avatar_counter: i64,
    #[serde(default = "default_true")]
    pub ask_for_friend_promotions: bool,
    #[serde(default = "default_true")]
    pub typing_indicators: bool,
}

fn default_true() -> bool {
    true
}

impl UserConfig {
    pub(crate) fn load_required_from(context: &Context) -> Result<Self> {
        Self::load_from(context)?.ok_or_else(|| twonly_error!("user configuration is unavailable"))
    }

    pub(crate) fn load_from(context: &Context) -> Result<Option<Self>> {
        let path = PathBuf::from(context.data_dir())
            .join("keyvalue")
            .join("user.json");
        if !path.exists() {
            return Ok(None);
        }
        let file = File::open(&path)?;
        serde_json::from_reader(file).map(Some).map_err(|error| {
            TwonlyError::Generic(format!(
                "invalid user configuration {}: {error}",
                path.display()
            ))
        })
    }
}

#[cfg(test)]
mod tests {
    use super::UserConfig;

    #[test]
    fn parses_only_rust_fields_and_applies_defaults() {
        let config: UserConfig = serde_json::from_str(
            r#"{
                "userId": 42,
                "username": "alice",
                "displayName": "Alice",
                "unrelatedFlutterSetting": {"ignored": true}
            }"#,
        )
        .unwrap();

        assert_eq!(config.user_id, Some(42));
        assert_eq!(config.username.as_deref(), Some("alice"));
        assert_eq!(config.required_send_images, 4);

        assert!(config.can_use_login_token_for_auth);
        assert!(!config.is_user_discovery_enabled);
    }
}
