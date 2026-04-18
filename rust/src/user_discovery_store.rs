#[allow(async_fn_in_trait)]
use protocols::user_discovery::error::{Result, UserDiscoveryError};
use protocols::user_discovery::traits::{AnnouncedUser, OtherPromotion, UserDiscoveryStore};
use protocols::user_discovery::UserID;
use sqlx::{QueryBuilder, Row, Sqlite, Transaction};
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;

use crate::bridge::error::TwonlyError;
use crate::bridge::{get_workspace, Twonly};

#[derive(Clone)]
pub(crate) struct UserDiscoveryDatabaseStore {
    ws: Arc<&'static Twonly>,
}

impl UserDiscoveryStore for UserDiscoveryDatabaseStore {
    async fn new() -> Self {
        #[cfg(test)]
        return Self {
            ws: Arc::new(
                crate::bridge::tests::initialize_twonly_for_testing(false)
                    .await
                    .unwrap(),
            ),
        };
        #[allow(unreachable_code)]
        Self {
            ws: Arc::new(get_workspace().unwrap()),
        }
    }
    async fn get_config(&self) -> Result<String> {
        let config_path =
            PathBuf::from(&self.ws.config.data_directory).join("user_discovery_config.json");

        if !config_path.is_file() {
            return Err(UserDiscoveryError::NotInitialized);
        }

        tracing::debug!("Loading Config from {}", config_path.display());
        Ok(std::fs::read_to_string(&config_path)?)
    }

    async fn update_config(&self, update: String) -> Result<()> {
        tracing::debug!("Updating configuration file.");
        let config_path =
            PathBuf::from(&self.ws.config.data_directory).join("user_discovery_config.json");
        std::fs::write(config_path, &update)?;
        Ok(())
    }

    async fn set_shares(&self, shares: Vec<Vec<u8>>) -> Result<()> {
        let mut query_builder: QueryBuilder<Sqlite> =
            QueryBuilder::new("INSERT INTO user_discovery_shares (share) ");

        query_builder.push_values(shares, |mut b, share| {
            b.push_bind(share);
        });

        query_builder
            .build()
            .execute(&self.ws.database.pool)
            .await
            .map_err(TwonlyError::from)?;

        Ok(())
    }

    async fn get_share_for_contact(&self, contact_id: UserID) -> Result<Vec<u8>> {
        let mut tx: Transaction<'_, Sqlite> = self
            .ws
            .database
            .pool
            .begin()
            .await
            .map_err(TwonlyError::from)?;

        // 1. Check if the user already has a share assigned
        let existing: Option<Vec<u8>> =
            sqlx::query_scalar("SELECT share FROM user_discovery_shares WHERE contact_id = ?")
                .bind(contact_id)
                .fetch_optional(&mut *tx)
                .await
                .map_err(TwonlyError::from)?;

        if let Some(share) = existing {
            tx.commit().await.map_err(TwonlyError::from)?;
            return Ok(share);
        }

        // 2. No share found. Try to assign an available one (where contact_id is NULL)
        let rows_affected = sqlx::query(
            "UPDATE user_discovery_shares 
         SET contact_id = ? 
         WHERE share_id = (
             SELECT share_id FROM user_discovery_shares 
             WHERE contact_id IS NULL 
             LIMIT 1
         )",
        )
        .bind(contact_id)
        .execute(&mut *tx)
        .await
        .map_err(TwonlyError::from)?
        .rows_affected();

        if rows_affected == 0 {
            return Err(UserDiscoveryError::NoSharesLeft);
        }

        // 3. Retrieve the newly assigned share
        let assigned_share: Vec<u8> =
            sqlx::query_scalar("SELECT share FROM user_discovery_shares WHERE contact_id = ?")
                .bind(contact_id)
                .fetch_one(&mut *tx)
                .await
                .map_err(TwonlyError::from)?;

        tx.commit().await.map_err(TwonlyError::from)?;
        Ok(assigned_share)
    }

    async fn push_own_promotion(
        &self,
        contact_id: UserID,
        version: u32,
        promotion: Vec<u8>,
    ) -> Result<()> {
        sqlx::query(
            r#"
        INSERT INTO user_discovery_own_promotions (contact_id, promotion, version_id)
        VALUES (?1, ?2, ?3)
        "#,
        )
        .bind(contact_id)
        .bind(promotion)
        .bind(version as i64) // SQLite integers are usually i32/i64
        .execute(&self.ws.database.pool)
        .await
        .map_err(TwonlyError::from)?;
        Ok(())
    }

    async fn get_own_promotions_after_version(&self, version: u32) -> Result<Vec<Vec<u8>>> {
        let promotions: Vec<Vec<u8>> = sqlx::query_scalar(
            "SELECT promotion FROM user_discovery_own_promotions 
         WHERE version_id > ? 
         ORDER BY version_id ASC",
        )
        .bind(version as i64)
        .fetch_all(&self.ws.database.pool)
        .await
        .map_err(TwonlyError::from)?;
        Ok(promotions)
    }

    async fn store_other_promotion(&self, promotion: OtherPromotion) -> Result<()> {
        sqlx::query(
            r"
        INSERT INTO user_discovery_other_promotions (
            from_contact_id, 
            promotion_id, 
            public_id, 
            threshold, 
            announcement_share, 
            public_key_verified_timestamp
        )
        VALUES (?1, ?2, ?3, ?4, ?5, ?6)
        ",
        )
        .bind(promotion.from_contact_id)
        .bind(promotion.promotion_id as i64)
        .bind(promotion.public_id)
        .bind(promotion.threshold as i64)
        .bind(promotion.announcement_share)
        .bind(promotion.public_key_verified_timestamp) // Option<i64> maps to NULLable
        .execute(&self.ws.database.pool)
        .await
        .map_err(TwonlyError::from)?;

        Ok(())
    }

    async fn get_other_promotions_by_public_id(
        &self,
        public_id: i64,
    ) -> Result<Vec<OtherPromotion>> {
        let promotions = sqlx::query_as::<_, OtherPromotion>(
            "SELECT * FROM user_discovery_other_promotions WHERE public_id = ?",
        )
        .bind(public_id)
        .fetch_all(&self.ws.database.pool)
        .await
        .map_err(TwonlyError::from)?;
        Ok(promotions)
    }

    async fn get_announced_user_by_public_id(
        &self,
        public_id: i64,
    ) -> Result<Option<AnnouncedUser>> {
        let row = sqlx::query("SELECT * FROM user_discovery_announced_users WHERE public_id = ?")
            .bind(public_id)
            .fetch_optional(&self.ws.database.pool)
            .await
            .map_err(TwonlyError::from)?;
        match row {
            Some(r) => Ok(Some(AnnouncedUser {
                user_id: r.get::<i64, _>("announced_user_id"),
                public_key: r.get::<Vec<u8>, _>("announced_public_key"),
                public_id: r.get::<i64, _>("public_id"),
            })),
            None => Ok(None),
        }
    }

    async fn push_new_user_relation(
        &self,
        from_contact_id: UserID,
        announced_user: AnnouncedUser,
        public_key_verified_timestamp: Option<i64>,
    ) -> Result<()> {
        let mut tx = self
            .ws
            .database
            .pool
            .begin()
            .await
            .map_err(TwonlyError::from)?;

        sqlx::query(
        r"
            INSERT INTO user_discovery_announced_users (announced_user_id, announced_public_key, public_id)
            VALUES (?1, ?2, ?3)
            ON CONFLICT(announced_user_id) DO NOTHING
        ")
            .bind(announced_user.user_id)
            .bind(announced_user.public_key)
            .bind(announced_user.public_id)
            .execute(&mut *tx)
            .await.map_err(TwonlyError::from)?;

        if from_contact_id != announced_user.user_id {
            tracing::debug!(
                "INSERTING THAT {} KNOWS {}",
                from_contact_id,
                announced_user.user_id
            );
            sqlx::query(
                r"INSERT INTO user_discovery_user_relations (
            announced_user_id, 
            from_contact_id, 
            public_key_verified_timestamp
        )
        VALUES (?1, ?2, ?3)
        ON CONFLICT(announced_user_id, from_contact_id) DO UPDATE SET
            public_key_verified_timestamp = excluded.public_key_verified_timestamp
        ",
            )
            .bind(announced_user.user_id)
            .bind(from_contact_id)
            .bind(public_key_verified_timestamp)
            .execute(&mut *tx)
            .await
            .map_err(TwonlyError::from)?;
        }

        tx.commit().await.map_err(TwonlyError::from)?;

        Ok(())
    }

    async fn get_all_announced_users(
        &self,
    ) -> Result<HashMap<AnnouncedUser, Vec<(UserID, Option<i64>)>>> {
        let rows = sqlx::query(
            r#"
    SELECT 
        u.announced_user_id, 
        u.announced_public_key, 
        u.public_id,
        r.from_contact_id, 
        r.public_key_verified_timestamp
    FROM user_discovery_announced_users u
    LEFT JOIN user_discovery_user_relations r 
        ON u.announced_user_id = r.announced_user_id
    ORDER BY u.announced_user_id
    "#,
        )
        .fetch_all(&self.ws.database.pool)
        .await
        .map_err(TwonlyError::from)?;

        let mut map: HashMap<AnnouncedUser, Vec<(UserID, Option<i64>)>> = HashMap::new();

        for row in rows {
            let announced_user = AnnouncedUser {
                user_id: row.get::<i64, _>("announced_user_id"),
                public_key: row.get::<Vec<u8>, _>("announced_public_key"),
                public_id: row.get::<i64, _>("public_id"),
            };

            let relations_list = map.entry(announced_user).or_insert_with(Vec::new);

            // SQLX returns NULL for columns in a LEFT JOIN where no match is found.
            if let Ok(Some(contact_id)) = row.try_get::<Option<i64>, _>("from_contact_id") {
                let timestamp = row.get::<Option<i64>, _>("public_key_verified_timestamp");
                relations_list.push((contact_id, timestamp));
            }
        }

        Ok(map)
    }

    async fn get_contact_version(&self, contact_id: UserID) -> Result<Option<Vec<u8>>> {
        let version: Option<Vec<u8>> =
            sqlx::query_scalar("SELECT user_discovery_version FROM contacts WHERE user_id = ?")
                .bind(contact_id)
                .fetch_optional(&self.ws.database.pool)
                .await
                .map_err(TwonlyError::from)?;

        Ok(version)
    }

    async fn set_contact_version(&self, contact_id: UserID, update: Vec<u8>) -> Result<()> {
        sqlx::query("UPDATE contacts SET user_discovery_version = ? WHERE user_id = ?")
            .bind(update)
            .bind(contact_id)
            .execute(&self.ws.database.pool)
            .await
            .map_err(TwonlyError::from)?;

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use crate::user_discovery_store::UserDiscoveryDatabaseStore;
    use protocols::user_discovery::tests::test_initialize_user_discovery;

    #[tokio::test]
    async fn test_initialize_user_discovery_database_store() {
        let _ = pretty_env_logger::try_init();
        test_initialize_user_discovery::<UserDiscoveryDatabaseStore>().await;
    }
}
