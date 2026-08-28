/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::context::Context;
use crate::error::{twonly_error, Result, TwonlyError};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs::File;
use std::io::Write;
use std::path::PathBuf;
use std::sync::{OnceLock, RwLock};

mod defaults {
    pub fn true_value() -> bool {
        true
    }

    pub fn subscription_plan() -> String {
        "Free".into()
    }

    pub fn pre_key_index() -> i64 {
        100_000
    }

    pub fn required_send_images() -> i64 {
        4
    }

    pub fn user_discovery_threshold() -> u8 {
        3
    }

    pub fn passwordless_threshold() -> i64 {
        2
    }
}

mod optional_datetime {
    use chrono::{DateTime, NaiveDateTime, Utc};
    use serde::{Deserialize, Deserializer, Serializer};

    pub fn serialize<S>(value: &Option<DateTime<Utc>>, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        match value {
            Some(date) => serializer.serialize_some(&date.to_rfc3339()),
            None => serializer.serialize_none(),
        }
    }

    pub fn deserialize<'de, D>(deserializer: D) -> Result<Option<DateTime<Utc>>, D::Error>
    where
        D: Deserializer<'de>,
    {
        let Some(value) = Option::<String>::deserialize(deserializer)? else {
            return Ok(None);
        };
        if let Ok(date) = DateTime::parse_from_rfc3339(&value) {
            return Ok(Some(date.with_timezone(&Utc)));
        }
        NaiveDateTime::parse_from_str(&value, "%Y-%m-%dT%H:%M:%S%.f")
            .map(|date| Some(date.and_utc()))
            .map_err(serde::de::Error::custom)
    }
}

fn config_lock() -> &'static RwLock<()> {
    static LOCK: OnceLock<RwLock<()>> = OnceLock::new();
    LOCK.get_or_init(|| RwLock::new(()))
}

fn merge_changed_fields(
    current: &mut serde_json::Map<String, serde_json::Value>,
    base: &serde_json::Map<String, serde_json::Value>,
    updated: &serde_json::Map<String, serde_json::Value>,
) {
    for key in base.keys().chain(updated.keys()) {
        if base.get(key) == updated.get(key) {
            continue;
        }
        match updated.get(key) {
            Some(value) => {
                current.insert(key.clone(), value.clone());
            }
            None => {
                current.remove(key);
            }
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize, Default, PartialEq)]
#[serde(rename_all = "camelCase")]
#[flutter_rust_bridge::frb(non_final)]
pub struct TwonlySafeBackup {
    #[serde(default)]
    #[frb(non_final)]
    pub last_backup_size: i64,
    #[serde(default)]
    #[frb(non_final)]
    pub backup_upload_state: LastBackupUploadState,
    #[serde(default, with = "optional_datetime")]
    #[frb(non_final)]
    pub last_backup_done: Option<chrono::DateTime<chrono::Utc>>,
    #[serde(default)]
    #[frb(non_final)]
    pub backup_id: Vec<u8>,
    #[serde(default)]
    #[frb(non_final)]
    pub encryption_key: Vec<u8>,
}

#[derive(Clone, Copy, Debug, Default, Deserialize, Serialize, PartialEq)]
#[serde(rename_all = "camelCase")]
pub enum LastBackupUploadState {
    #[default]
    None,
    Pending,
    Failed,
    Success,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
#[serde(rename_all = "camelCase")]
#[flutter_rust_bridge::frb(non_final)]
pub struct PasswordlessRecoveryConfig {
    #[frb(non_final)]
    pub email: Option<String>,
    #[serde(default = "defaults::passwordless_threshold")]
    #[frb(non_final)]
    pub threshold: i64,
    #[frb(non_final)]
    pub server_key_protection: Option<Vec<u8>>,
    #[frb(non_final)]
    pub pin_unlock_token: Option<Vec<u8>>,
    #[serde(default, with = "optional_datetime")]
    #[frb(non_final)]
    pub last_server_heartbeat: Option<chrono::DateTime<chrono::Utc>>,
    #[serde(default, with = "optional_datetime")]
    #[frb(non_final)]
    pub last_contact_heartbeat: Option<chrono::DateTime<chrono::Utc>>,
    #[frb(non_final)]
    pub encrypted_server_key: Option<Vec<u8>>,
}

#[derive(Clone, Copy, Debug, Default, Deserialize, Serialize, PartialEq)]
#[serde(rename_all = "camelCase")]
pub enum SetupProfile {
    #[default]
    Standard,
    Customized,
}

#[derive(Clone, Copy, Debug, Default, Deserialize, Serialize, PartialEq)]
#[serde(rename_all = "camelCase")]
pub enum ThemeMode {
    #[default]
    System,
    Light,
    Dark,
}

#[derive(Clone, Debug, Deserialize, Serialize, Default, PartialEq)]
#[serde(rename_all = "camelCase")]
#[flutter_rust_bridge::frb(non_final)]
pub struct UserConfig {
    #[frb(non_final)]
    pub user_id: i64,
    #[frb(non_final)]
    pub username: String,
    #[frb(non_final)]
    pub display_name: String,
    #[frb(non_final)]
    pub avatar_svg: Option<String>,
    #[serde(default)]
    #[frb(non_final)]
    pub app_version: i64,
    #[serde(default)]
    #[frb(non_final)]
    pub avatar_counter: i64,
    #[serde(default = "defaults::true_value")]
    #[frb(non_final)]
    pub video_stabilization_enabled: bool,
    #[serde(default)]
    #[frb(non_final)]
    pub is_developer: bool,
    #[serde(default)]
    #[frb(non_final)]
    pub device_id: i64,
    #[serde(default)]
    #[frb(non_final)]
    pub setup_profile: SetupProfile,

    #[serde(default = "defaults::subscription_plan")]
    #[frb(non_final)]
    pub subscription_plan: String,
    #[frb(non_final)]
    pub subscription_plan_id_store: Option<String>,
    #[serde(default, with = "optional_datetime")]
    #[frb(non_final)]
    pub last_image_send: Option<chrono::DateTime<chrono::Utc>>,
    #[frb(non_final)]
    pub todays_image_counter: Option<i64>,
    #[frb(non_final)]
    pub last_plan_ballance: Option<String>,
    #[frb(non_final)]
    pub additional_user_invites: Option<String>,

    #[serde(default)]
    #[frb(non_final)]
    pub theme_mode: ThemeMode,
    #[frb(non_final)]
    pub primary_color_value: Option<i64>,
    #[frb(non_final)]
    pub default_show_time: Option<i64>,
    #[serde(default)]
    #[frb(non_final)]
    pub requested_audio_permission: bool,
    #[serde(default)]
    #[frb(non_final)]
    pub enable_database_logging: bool,
    #[serde(default)]
    #[frb(non_final)]
    pub automatically_mark_equal_media_files_as_opened: bool,
    #[serde(default = "defaults::true_value")]
    #[frb(non_final)]
    pub show_news_shortcut: bool,
    #[serde(default)]
    #[frb(non_final)]
    pub show_show_image_preview_when_sending: bool,
    #[serde(default = "defaults::true_value")]
    #[frb(non_final)]
    pub start_with_camera_open: bool,
    #[frb(non_final)]
    pub pre_selected_emojies: Option<Vec<String>>,
    #[frb(non_final)]
    pub auto_download_options: Option<HashMap<String, Vec<String>>>,
    #[serde(default = "defaults::true_value")]
    #[frb(non_final)]
    pub store_media_files_in_gallery: bool,
    #[serde(default)]
    #[frb(non_final)]
    pub auto_store_all_send_unlimited_media_files: bool,
    #[serde(default = "defaults::true_value")]
    #[frb(non_final)]
    pub typing_indicators: bool,
    #[serde(default = "defaults::true_value")]
    #[frb(non_final)]
    pub show_restore_flame: bool,
    #[frb(non_final)]
    pub my_best_friend_group_id: Option<String>,
    #[serde(default, with = "optional_datetime")]
    #[frb(non_final)]
    pub signal_last_signed_pre_key_updated: Option<chrono::DateTime<chrono::Utc>>,
    #[serde(default, with = "optional_datetime")]
    #[frb(non_final)]
    pub signal_last_pqc_pre_keys_uploaded: Option<chrono::DateTime<chrono::Utc>>,
    #[serde(default)]
    #[frb(non_final)]
    pub allow_error_tracking_via_sentry: bool,
    #[serde(default)]
    #[frb(non_final)]
    pub screen_lock_enabled: bool,
    #[serde(default)]
    #[frb(non_final)]
    pub is_cloud_backup_enabled: bool,

    #[serde(default)]
    #[frb(non_final)]
    pub is_user_discovery_enabled: bool,
    #[serde(default = "defaults::required_send_images")]
    #[frb(non_final)]
    pub required_send_images: i64,
    #[serde(default = "defaults::user_discovery_threshold")]
    #[frb(non_final)]
    pub user_discovery_threshold: u8,
    #[serde(default)]
    #[frb(non_final)]
    pub user_discovery_requires_manual_approval: bool,
    #[serde(default = "defaults::true_value")]
    #[frb(non_final)]
    pub user_discovery_share_promotion: bool,
    #[serde(default)]
    #[frb(non_final)]
    pub user_discovery_initialization_error: bool,

    #[serde(default = "defaults::true_value")]
    #[frb(non_final)]
    pub ask_for_friend_promotions: bool,
    #[serde(default = "defaults::pre_key_index")]
    #[frb(non_final)]
    pub current_pre_key_index_start: i64,
    #[serde(default = "defaults::pre_key_index")]
    #[frb(non_final)]
    pub current_signed_pre_key_index_start: i64,
    #[frb(non_final)]
    pub last_change_log_hash: Option<Vec<u8>>,
    #[serde(default = "defaults::true_value")]
    #[frb(non_final)]
    pub hide_change_log: bool,
    #[serde(default)]
    #[frb(non_final)]
    pub hide_memories_backup_promo: bool,
    #[serde(default = "defaults::true_value")]
    #[frb(non_final)]
    pub update_fcm_token: bool,
    #[serde(default = "defaults::true_value")]
    #[frb(non_final)]
    pub can_use_login_token_for_auth: bool,

    #[frb(non_final)]
    pub twonly_safe_backup: Option<TwonlySafeBackup>,
    #[serde(default)]
    #[frb(non_final)]
    pub is_backup_enabled: bool,
    #[frb(non_final)]
    pub password_less_recovery: Option<PasswordlessRecoveryConfig>,
    #[frb(non_final)]
    pub fcm_token: Option<String>,
    #[frb(non_final)]
    pub current_setup_page: Option<String>,
    #[serde(default)]
    #[frb(non_final)]
    pub skip_setup_pages: bool,
    #[serde(default)]
    #[frb(non_final)]
    pub has_zoomed: bool,
}

impl UserConfig {
    fn path(context: &Context) -> PathBuf {
        PathBuf::from(&context.config.data_dir)
            .join("keyvalue")
            .join("user.json")
    }

    pub(crate) fn load_required_from(context: &Context) -> Result<Self> {
        Self::load_from(context)?.ok_or_else(|| twonly_error!("user configuration is unavailable"))
    }

    pub(crate) fn load_from(context: &Context) -> Result<Option<Self>> {
        let _guard = config_lock()
            .read()
            .map_err(|_| twonly_error!("user configuration lock was poisoned"))?;
        Self::load_from_unlocked(context)
    }

    fn load_from_unlocked(context: &Context) -> Result<Option<Self>> {
        let path = Self::path(context);
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

    /// Validates and atomically persists the complete user configuration.
    /// Rust is the only writer of `user.json`.
    pub(crate) fn save_json(context: &Context, json: &str) -> Result<String> {
        let _guard = config_lock()
            .write()
            .map_err(|_| twonly_error!("user configuration lock was poisoned"))?;
        Self::save_json_unlocked(context, json)
    }

    /// Atomically updates the latest persisted configuration with a typed Rust
    /// mutation. Unlike `update_json`, this does not need a caller snapshot:
    /// loading, mutation, and saving all happen while holding the write lock.
    pub(crate) fn update(context: &Context, mutate: impl FnOnce(&mut Self)) -> Result<Self> {
        let _guard = config_lock()
            .write()
            .map_err(|_| twonly_error!("user configuration lock was poisoned"))?;
        let mut config = Self::load_from_unlocked(context)?
            .ok_or_else(|| twonly_error!("user configuration is unavailable"))?;
        mutate(&mut config);
        Self::save_unlocked(context, &config)?;
        Ok(config)
    }

    /// Applies only fields changed relative to the caller's original snapshot.
    /// Concurrent updates from Flutter isolates or Rust therefore do not
    /// overwrite unrelated fields with stale values.
    pub(crate) fn update_json(
        context: &Context,
        base_json: &str,
        updated_json: &str,
    ) -> Result<String> {
        let base: serde_json::Map<String, serde_json::Value> = serde_json::from_str(base_json)?;
        let updated: serde_json::Map<String, serde_json::Value> =
            serde_json::from_str(updated_json)?;
        let _guard = config_lock()
            .write()
            .map_err(|_| twonly_error!("user configuration lock was poisoned"))?;
        let current = Self::load_from_unlocked(context)?
            .ok_or_else(|| twonly_error!("user configuration is unavailable"))?;
        let mut current: serde_json::Map<String, serde_json::Value> =
            serde_json::from_value(serde_json::to_value(current)?)?;

        merge_changed_fields(&mut current, &base, &updated);
        Self::save_json_unlocked(context, &serde_json::to_string(&current)?)
    }

    fn save_json_unlocked(context: &Context, json: &str) -> Result<String> {
        let config: Self = serde_json::from_str(json).map_err(|error| {
            TwonlyError::Generic(format!("invalid user configuration update: {error}"))
        })?;
        Self::save_unlocked(context, &config)
    }

    fn save_unlocked(context: &Context, config: &Self) -> Result<String> {
        let normalized = serde_json::to_string(&config)?;
        let path = Self::path(context);
        let parent = path
            .parent()
            .ok_or_else(|| twonly_error!("user configuration path has no parent"))?;
        std::fs::create_dir_all(parent)?;
        let temporary = parent.join("user.json.tmp");
        let mut file = File::create(&temporary)?;
        file.write_all(normalized.as_bytes())?;
        file.sync_all()?;
        std::fs::rename(&temporary, &path)?;
        Ok(normalized)
    }
}

#[cfg(test)]
mod tests {
    use super::{merge_changed_fields, UserConfig};

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

        assert_eq!(config.user_id, 42);
        assert_eq!(config.username, "alice");
        assert_eq!(config.required_send_images, 4);

        assert!(config.can_use_login_token_for_auth);
        assert!(!config.is_user_discovery_enabled);
    }

    #[test]
    fn merges_only_fields_changed_by_a_stale_snapshot() {
        let mut current = serde_json::from_str(r#"{"theme":"dark","counter":2}"#).unwrap();
        let base = serde_json::from_str(r#"{"theme":"light","counter":1}"#).unwrap();
        let updated = serde_json::from_str(r#"{"theme":"system","counter":1}"#).unwrap();

        merge_changed_fields(&mut current, &base, &updated);

        assert_eq!(current["theme"], "system");
        assert_eq!(current["counter"], 2);
    }
}
