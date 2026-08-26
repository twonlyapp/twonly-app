/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::database::{app::AppDatabase, signal::Database};
use crate::keys::KeyManager;
use crate::user_discovery::error::{Result, UserDiscoveryError};
use crate::user_discovery::traits::{
    AnnouncedUser, OtherPromotion, UserDiscoveryStore, UserDiscoveryUtils,
};
use crate::user_discovery::UserID;
use libsignal_protocol::{IdentityKey, IdentityKeyPair};
use rand::SeedableRng;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::{Mutex, RwLock};

fn store_error(error: impl std::fmt::Display) -> UserDiscoveryError {
    UserDiscoveryError::Store(error.to_string())
}

#[derive(Clone)]
pub(crate) struct NativeUserDiscoveryStore {
    app_db: Arc<RwLock<Arc<AppDatabase>>>,
    config_path: PathBuf,
}

impl NativeUserDiscoveryStore {
    pub(crate) fn new(app_db: Arc<RwLock<Arc<AppDatabase>>>, data_dir: &str) -> Self {
        Self {
            app_db,
            config_path: PathBuf::from(data_dir).join("user_discovery_config.json"),
        }
    }

    async fn database(&self) -> Arc<AppDatabase> {
        self.app_db.read().await.clone()
    }
}

impl UserDiscoveryStore for NativeUserDiscoveryStore {
    async fn get_config(&self) -> Result<String> {
        if !self.config_path.is_file() {
            return Err(UserDiscoveryError::NotInitialized);
        }
        Ok(std::fs::read_to_string(&self.config_path)?)
    }

    async fn update_config(&self, update: String) -> Result<()> {
        std::fs::write(&self.config_path, update)?;
        Ok(())
    }

    async fn set_shares(&self, shares: Vec<Vec<u8>>) -> Result<()> {
        let db = self.database().await;
        let mut tx = db.pool.begin().await.map_err(store_error)?;
        sqlx::query!(r#"DELETE FROM user_discovery_shares"#)
            .execute(&mut *tx)
            .await
            .map_err(store_error)?;
        for share in shares {
            sqlx::query!(
                r#"INSERT INTO user_discovery_shares (share) VALUES (?)"#,
                share
            )
            .execute(&mut *tx)
            .await
            .map_err(store_error)?;
        }
        tx.commit().await.map_err(store_error)?;
        db.notify_committed(["user_discovery_shares"]);
        Ok(())
    }

    async fn get_share_for_contact(&self, contact_id: UserID) -> Result<Vec<u8>> {
        let db = self.database().await;
        let mut tx = db.pool.begin().await.map_err(store_error)?;
        if let Some(share) = sqlx::query_scalar!(
            r#"
            SELECT share
            FROM user_discovery_shares
            WHERE contact_id = ?
            LIMIT 1
            "#,
            contact_id,
        )
        .fetch_optional(&mut *tx)
        .await
        .map_err(store_error)?
        {
            tx.commit().await.map_err(store_error)?;
            return Ok(share);
        }
        let available = sqlx::query!(
            r#"
            SELECT share_id, share
            FROM user_discovery_shares
            WHERE contact_id IS NULL
            LIMIT 1
            "#,
        )
        .fetch_optional(&mut *tx)
        .await
        .map_err(store_error)?;
        let Some(row) = available else {
            tx.rollback().await.map_err(store_error)?;
            return Err(UserDiscoveryError::NoSharesLeft);
        };
        let share_id = row.share_id;
        let share = row.share;
        sqlx::query!(
            r#"
            UPDATE user_discovery_shares
            SET contact_id = ?
            WHERE share_id = ?
            "#,
            contact_id,
            share_id,
        )
        .execute(&mut *tx)
        .await
        .map_err(store_error)?;
        tx.commit().await.map_err(store_error)?;
        db.notify_committed(["user_discovery_shares"]);
        Ok(share)
    }

    async fn push_own_promotion_and_clear_old_version(
        &self,
        contact_id: UserID,
        _version: u32,
        promotion: Vec<u8>,
    ) -> Result<()> {
        let db = self.database().await;
        let mut tx = db.pool.begin().await.map_err(store_error)?;
        sqlx::query!(
            r#"
            UPDATE user_discovery_own_promotions
            SET promotion = X''
            WHERE contact_id = ?
            "#,
            contact_id,
        )
        .execute(&mut *tx)
        .await
        .map_err(store_error)?;
        sqlx::query!(
            r#"
            INSERT INTO user_discovery_own_promotions (
                contact_id,
                promotion
            ) VALUES (?, ?)
            "#,
            contact_id,
            promotion,
        )
        .execute(&mut *tx)
        .await
        .map_err(store_error)?;
        tx.commit().await.map_err(store_error)?;
        db.notify_committed(["user_discovery_own_promotions"]);
        Ok(())
    }

    async fn get_own_promotions_after_version(&self, version: u32) -> Result<Vec<Vec<u8>>> {
        let db = self.database().await;
        sqlx::query_scalar!(
            r#"
            SELECT promotion
            FROM user_discovery_own_promotions
            WHERE version_id > ?
            "#,
            version,
        )
        .fetch_all(&db.pool)
        .await
        .map_err(store_error)
    }

    async fn store_other_promotion(&self, promotion: OtherPromotion) -> Result<()> {
        let db = self.database().await;
        sqlx::query!(
            r#"
            INSERT INTO user_discovery_other_promotions (
                from_contact_id,
                promotion_id,
                public_id,
                threshold,
                announcement_share,
                public_key_verified_timestamp
            ) VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(from_contact_id, public_id) DO UPDATE SET
                promotion_id = excluded.promotion_id,
                threshold = excluded.threshold,
                announcement_share = excluded.announcement_share,
                public_key_verified_timestamp = excluded.public_key_verified_timestamp
            "#,
            promotion.from_contact_id,
            promotion.promotion_id,
            promotion.public_id,
            promotion.threshold,
            promotion.announcement_share,
            promotion.public_key_verified_timestamp,
        )
        .execute(&db.pool)
        .await
        .map_err(store_error)?;
        db.notify_committed(["user_discovery_other_promotions"]);
        Ok(())
    }

    async fn get_other_promotions_by_public_id(
        &self,
        public_id: i64,
    ) -> Result<Vec<OtherPromotion>> {
        let db = self.database().await;
        let rows = sqlx::query!(
            r#"
            SELECT
                promotion_id,
                public_id,
                from_contact_id,
                threshold,
                announcement_share,
                public_key_verified_timestamp
            FROM user_discovery_other_promotions
            WHERE public_id = ?
            "#,
            public_id,
        )
        .fetch_all(&db.pool)
        .await
        .map_err(store_error)?;
        rows.into_iter()
            .map(|row| {
                Ok(OtherPromotion {
                    promotion_id: u32::try_from(row.promotion_id).map_err(store_error)?,
                    public_id: row.public_id,
                    from_contact_id: row.from_contact_id,
                    threshold: u8::try_from(row.threshold).map_err(store_error)?,
                    announcement_share: row.announcement_share,
                    public_key_verified_timestamp: row.public_key_verified_timestamp,
                })
            })
            .collect()
    }

    async fn get_announced_user_by_public_id(
        &self,
        public_id: i64,
    ) -> Result<Option<AnnouncedUser>> {
        let db = self.database().await;
        let row = sqlx::query!(
            r#"
            SELECT
                announced_user_id,
                announced_public_key,
                public_id
            FROM user_discovery_announced_users
            WHERE public_id = ?
            "#,
            public_id,
        )
        .fetch_optional(&db.pool)
        .await
        .map_err(store_error)?;
        row.map(|row| {
            Ok(AnnouncedUser {
                user_id: row.announced_user_id,
                public_key: row.announced_public_key,
                public_id: row.public_id,
            })
        })
        .transpose()
    }

    async fn push_new_user_relation(
        &self,
        from_contact_id: UserID,
        announced_user: AnnouncedUser,
        public_key_verified_timestamp: Option<i64>,
    ) -> Result<()> {
        let db = self.database().await;
        let mut tx = db.pool.begin().await.map_err(store_error)?;
        sqlx::query!(
            r#"
            INSERT INTO user_discovery_announced_users (
                announced_user_id,
                announced_public_key,
                public_id
            ) VALUES (?, ?, ?)
            ON CONFLICT DO UPDATE SET
                announced_user_id = excluded.announced_user_id,
                announced_public_key = excluded.announced_public_key,
                public_id = excluded.public_id
            "#,
            announced_user.user_id,
            announced_user.public_key,
            announced_user.public_id,
        )
        .execute(&mut *tx)
        .await
        .map_err(store_error)?;
        sqlx::query!(
            r#"
            INSERT INTO user_discovery_user_relations (
                announced_user_id,
                from_contact_id,
                public_key_verified_timestamp
            ) VALUES (?, ?, ?)
            ON CONFLICT(announced_user_id, from_contact_id) DO UPDATE SET
                public_key_verified_timestamp = excluded.public_key_verified_timestamp
            "#,
            announced_user.user_id,
            from_contact_id,
            public_key_verified_timestamp,
        )
        .execute(&mut *tx)
        .await
        .map_err(store_error)?;
        tx.commit().await.map_err(store_error)?;
        db.notify_committed([
            "user_discovery_announced_users",
            "user_discovery_user_relations",
        ]);
        Ok(())
    }

    #[cfg(test)]
    async fn get_all_announced_users(
        &self,
    ) -> Result<std::collections::HashMap<AnnouncedUser, Vec<(UserID, Option<i64>)>>> {
        Err(UserDiscoveryError::Store("not used by native store".into()))
    }

    async fn get_contact_promotion(&self, contact_id: UserID) -> Result<Option<Vec<u8>>> {
        let db = self.database().await;
        sqlx::query_scalar!(
            r#"
            SELECT promotion
            FROM user_discovery_own_promotions
            WHERE contact_id = ?
            ORDER BY version_id DESC
            LIMIT 1
            "#,
            contact_id,
        )
        .fetch_optional(&db.pool)
        .await
        .map_err(store_error)
    }

    async fn get_contact_version(&self, contact_id: UserID) -> Result<Option<Vec<u8>>> {
        let db = self.database().await;
        sqlx::query_scalar!(
            r#"
            SELECT user_discovery_version
            FROM contacts
            WHERE user_id = ?
            "#,
            contact_id,
        )
        .fetch_optional(&db.pool)
        .await
        .map_err(store_error)
        .map(Option::flatten)
    }

    async fn set_contact_version(&self, contact_id: UserID, update: Vec<u8>) -> Result<()> {
        let db = self.database().await;
        sqlx::query!(
            r#"
            UPDATE contacts
            SET user_discovery_version = ?
            WHERE user_id = ?
            "#,
            update,
            contact_id,
        )
        .execute(&db.pool)
        .await
        .map_err(store_error)?;
        db.notify_committed(["contacts"]);
        Ok(())
    }
}

pub(crate) struct NativeUserDiscoveryUtils {
    key_manager: Arc<Mutex<KeyManager>>,
    rust_db: Arc<RwLock<Arc<Database>>>,
}

impl NativeUserDiscoveryUtils {
    pub(crate) fn new(
        key_manager: Arc<Mutex<KeyManager>>,
        rust_db: Arc<RwLock<Arc<Database>>>,
    ) -> Self {
        Self {
            key_manager,
            rust_db,
        }
    }
}

impl UserDiscoveryUtils for NativeUserDiscoveryUtils {
    async fn sign_data(&self, input_data: &[u8]) -> Result<Vec<u8>> {
        let key_manager = self.key_manager.lock().await;
        let identity = key_manager
            .signal_identity
            .as_ref()
            .ok_or_else(|| UserDiscoveryError::Store("no Signal identity found".into()))?;
        let key_pair = IdentityKeyPair::try_from(identity.identity_key_pair_structure.as_slice())
            .map_err(store_error)?;
        let mut csprng = rand::rngs::StdRng::from_os_rng();
        key_pair
            .private_key()
            .calculate_signature_for_multipart_message(&[input_data], &mut csprng)
            .map(|signature| signature.to_vec())
            .map_err(store_error)
    }

    async fn verify_signature(
        &self,
        input_data: &[u8],
        pubkey: &[u8],
        signature: &[u8],
    ) -> Result<bool> {
        let identity = match IdentityKey::decode(pubkey) {
            Ok(identity) => identity,
            Err(_) => return Ok(false),
        };
        Ok(identity
            .public_key()
            .verify_signature(input_data, signature))
    }

    async fn verify_stored_pubkey(&self, from_contact_id: UserID, pubkey: &[u8]) -> Result<bool> {
        let db = self.rust_db.read().await.clone();
        let stored = sqlx::query_scalar!(
            r#"
            SELECT identity_key
            FROM signal_identities
            WHERE name = ?
            "#,
            from_contact_id.to_string(),
        )
        .fetch_optional(&db.pool)
        .await
        .map_err(store_error)?;
        Ok(stored.as_deref() == Some(pubkey))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::keys::SignalIdentityKey;
    use std::collections::HashMap;

    #[tokio::test]
    async fn native_store_and_signal_utils_use_rust_owned_state() {
        let temp = tempfile::tempdir().unwrap();
        let app_path = temp.path().join("app.sqlite");
        let app_db = AppDatabase::new(app_path.to_str().unwrap(), None, false)
            .await
            .unwrap();
        app_db.run_migrations().await.unwrap();
        sqlx::query!(
            r#"
            INSERT INTO contacts (user_id, username)
            VALUES (1, 'one'), (2, 'two')
            "#
        )
        .execute(&app_db.pool)
        .await
        .unwrap();
        let app_handle = Arc::new(RwLock::new(Arc::new(app_db)));
        let store = NativeUserDiscoveryStore::new(app_handle, temp.path().to_str().unwrap());

        store.update_config("config".into()).await.unwrap();
        assert_eq!(store.get_config().await.unwrap(), "config");
        store.set_shares(vec![vec![1], vec![2]]).await.unwrap();
        let assigned = store.get_share_for_contact(1).await.unwrap();
        assert_eq!(store.get_share_for_contact(1).await.unwrap(), assigned);
        store.set_contact_version(1, vec![7]).await.unwrap();
        assert_eq!(store.get_contact_version(1).await.unwrap(), Some(vec![7]));
        store
            .push_own_promotion_and_clear_old_version(1, 1, vec![8])
            .await
            .unwrap();
        assert_eq!(store.get_contact_promotion(1).await.unwrap(), Some(vec![8]));

        let promotion = OtherPromotion {
            promotion_id: 3,
            public_id: 4,
            from_contact_id: 1,
            threshold: 2,
            announcement_share: vec![5],
            public_key_verified_timestamp: Some(6),
        };
        store.store_other_promotion(promotion).await.unwrap();
        assert_eq!(
            store
                .get_other_promotions_by_public_id(4)
                .await
                .unwrap()
                .len(),
            1
        );
        let announced = AnnouncedUser {
            user_id: 2,
            public_key: vec![9],
            public_id: 10,
        };
        store
            .push_new_user_relation(1, announced, Some(11))
            .await
            .unwrap();
        assert_eq!(
            store
                .get_announced_user_by_public_id(10)
                .await
                .unwrap()
                .unwrap()
                .user_id,
            2
        );

        let rust_path = temp.path().join("rust.sqlite");
        let rust_path_string = rust_path.display().to_string();
        let rust_db = Database::new(&rust_path_string, None, false).await.unwrap();
        rust_db.run_migrations().await.unwrap();
        let rust_handle = Arc::new(RwLock::new(Arc::new(rust_db)));

        let mut rng = rand::rng();
        let identity = IdentityKeyPair::generate(&mut rng);
        let public_key = identity.identity_key().serialize().to_vec();
        sqlx::query!(
            r#"
            INSERT INTO signal_identities (name, identity_key, timestamp)
            VALUES ('1', ?, 0)
            "#,
            &public_key,
        )
        .execute(&rust_handle.read().await.pool)
        .await
        .unwrap();
        let mut key_manager = KeyManager::generate().unwrap();
        key_manager.signal_identity = Some(SignalIdentityKey {
            identity_key_pair_structure: identity.serialize().to_vec(),
            registration_id: 1,
            pre_key_store: HashMap::new(),
        });
        let utils = NativeUserDiscoveryUtils::new(Arc::new(Mutex::new(key_manager)), rust_handle);
        let message = b"native discovery";
        let signature = utils.sign_data(message).await.unwrap();
        assert!(utils
            .verify_signature(message, &public_key, &signature)
            .await
            .unwrap());
        assert!(utils.verify_stored_pubkey(1, &public_key).await.unwrap());
        assert!(!utils.verify_stored_pubkey(2, &public_key).await.unwrap());
    }
}
