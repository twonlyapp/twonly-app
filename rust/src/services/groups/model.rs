/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use sqlx::{Sqlite, SqlitePool, Transaction};

use crate::error::{Result, TwonlyError};

#[derive(sqlx::FromRow, Clone)]
pub(crate) struct GroupRecord {
    pub group_id: String,
    pub group_name: String,
    pub state_version_id: i64,
    pub state_encryption_key: Option<Vec<u8>>,
    pub my_group_private_key: Option<Vec<u8>>,
}

impl GroupRecord {
    pub async fn load(pool: &SqlitePool, group_id: &str) -> Result<Self> {
        sqlx::query_as!(
            Self,
            r#"SELECT group_id, group_name, state_version_id,
                      state_encryption_key, my_group_private_key
               FROM groups WHERE group_id = ?"#,
            group_id,
        )
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| TwonlyError::Generic(format!("group {group_id} does not exist")))
    }

    pub async fn load_in_transaction(
        transaction: &mut Transaction<'_, Sqlite>,
        group_id: &str,
    ) -> Result<Self> {
        sqlx::query_as!(
            Self,
            r#"SELECT group_id, group_name, state_version_id,
                      state_encryption_key, my_group_private_key
               FROM groups WHERE group_id = ?"#,
            group_id,
        )
        .fetch_optional(&mut **transaction)
        .await?
        .ok_or_else(|| TwonlyError::Generic(format!("group {group_id} does not exist")))
    }

    pub fn state_key(&self) -> Result<&[u8]> {
        self.state_encryption_key
            .as_deref()
            .ok_or_else(|| TwonlyError::Generic("group state key is unavailable".into()))
    }

    pub fn identity(&self) -> Result<libsignal_protocol::IdentityKeyPair> {
        libsignal_protocol::IdentityKeyPair::try_from(
            self.my_group_private_key
                .as_deref()
                .ok_or_else(|| TwonlyError::Generic("group private key is unavailable".into()))?,
        )
        .map_err(|error| TwonlyError::Signal(error.to_string()))
    }
}
