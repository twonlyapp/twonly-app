/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::{bridge::callbacks::CURRENT_CALLBACK_ID, bridge::get_twonly_flutter, error::Result};

pub struct FlutterUserDiscovery {}

impl FlutterUserDiscovery {
    /// UI-facing read used to display the current discovery version.
    pub async fn get_current_version(callback_id: u32) -> Result<Vec<u8>> {
        CURRENT_CALLBACK_ID
            .scope(callback_id, async move {
                Ok(get_twonly_flutter()?
                    .user_discovery
                    .get()
                    .await
                    .get_current_version()
                    .await?)
            })
            .await
    }

    /// UI-facing hook used when a user manually changes contact verification.
    pub async fn update_verification_state_for_user(
        callback_id: u32,
        contact_id: i64,
        public_key_verified_timestamp: Option<i64>,
    ) -> Result<()> {
        CURRENT_CALLBACK_ID
            .scope(callback_id, async move {
                let ctx = get_twonly_flutter()?;
                let database = ctx.app_db.read().await.clone();
                let mut transaction = database.pool.begin().await?;
                ctx.user_discovery
                    .get()
                    .await
                    .update_verification_state_for_user(
                        contact_id,
                        public_key_verified_timestamp,
                        &mut transaction,
                    )
                    .await?;
                transaction.commit().await?;
                Ok(())
            })
            .await
    }

    pub async fn change_exclusion_for_contact(
        callback_id: u32,
        contact_id: i64,
        exclude: bool,
    ) -> Result<()> {
        CURRENT_CALLBACK_ID
            .scope(callback_id, async move {
                let ctx = get_twonly_flutter()?;
                let database = ctx.app_db.read().await.clone();
                let mut transaction = database.pool.begin().await?;
                sqlx::query!(
                    "UPDATE user_discovery_own_promotions SET promotion = X'' WHERE contact_id = ?",
                    contact_id,
                )
                .execute(&mut *transaction)
                .await?;
                sqlx::query!(
                    r#"
                    UPDATE contacts
                    SET user_discovery_excluded = ?, user_discovery_version = NULL
                    WHERE user_id = ?
                    "#,
                    exclude,
                    contact_id,
                )
                .execute(&mut *transaction)
                .await?;
                transaction.commit().await?;
                Ok(())
            })
            .await
    }
}
