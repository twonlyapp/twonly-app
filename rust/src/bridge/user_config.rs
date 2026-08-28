use crate::context::Context;
use crate::error::Result;
use crate::user_config::UserConfig;

pub struct UserConfigApi {}

impl UserConfigApi {
    pub async fn load() -> Result<Option<UserConfig>> {
        let ctx = Context::get_static()?;
        UserConfig::load_from(ctx)
    }

    pub async fn create(
        user_id: i64,
        username: String,
        display_name: String,
        current_setup_page: Option<String>,
        app_version: i64,
    ) -> Result<UserConfig> {
        serde_json::from_value(serde_json::json!({
            "userId": user_id,
            "username": username,
            "displayName": display_name,
            "subscriptionPlan": "Free",
            "currentSetupPage": current_setup_page,
            "appVersion": app_version,
        }))
        .map_err(Into::into)
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn clone(config: UserConfig) -> UserConfig {
        config
    }

    pub async fn save(config: UserConfig) -> Result<UserConfig> {
        let ctx = Context::get_static()?;
        let normalized = UserConfig::save_json(ctx, &serde_json::to_string(&config)?)?;
        let config: UserConfig = serde_json::from_str(&normalized)?;
        let mut key_manager = ctx.get_key_manager().await?;
        if key_manager.user_id != Some(config.user_id) {
            key_manager.user_id = Some(config.user_id);
            key_manager.store_to_keychain(ctx.get_secure_storage())?;
        }
        drop(key_manager);
        if let Ok(callbacks) = crate::bridge::callbacks::get_callbacks() {
            (callbacks.api.user_config_changed)(config.clone()).await;
        }
        Ok(config)
    }

    pub async fn update(base: UserConfig, config: UserConfig) -> Result<UserConfig> {
        let ctx = Context::get_static()?;
        let normalized = UserConfig::update_json(
            ctx,
            &serde_json::to_string(&base)?,
            &serde_json::to_string(&config)?,
        )?;
        let config: UserConfig = serde_json::from_str(&normalized)?;
        if let Ok(callbacks) = crate::bridge::callbacks::get_callbacks() {
            (callbacks.api.user_config_changed)(config.clone()).await;
        }
        Ok(config)
    }

    pub async fn import_json(json: String) -> Result<UserConfig> {
        let config: UserConfig = serde_json::from_str(&json)?;
        Self::save(config).await
    }
}
