/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use sqlx::{Sqlite, Transaction};

use crate::{error::Result, utils::new_uuid_v4};

#[derive(Clone, Copy)]
pub enum GroupHistoryType {
    UpdatedContactUsername,
    UpdatedContactDisplayName,
}

impl GroupHistoryType {
    fn as_str(self) -> &'static str {
        match self {
            Self::UpdatedContactUsername => "updatedContactUsername",
            Self::UpdatedContactDisplayName => "updatedContactDisplayName",
        }
    }
}

pub struct InsertGroupHistories<'a> {
    contact_id: i64,
    old_group_name: &'a str,
    new_group_name: &'a str,
    history_type: GroupHistoryType,
}

impl<'a> InsertGroupHistories<'a> {
    pub fn new(
        contact_id: i64,
        old_group_name: &'a str,
        new_group_name: &'a str,
        history_type: GroupHistoryType,
    ) -> Self {
        Self {
            contact_id,
            old_group_name,
            new_group_name,
            history_type,
        }
    }

    pub async fn insert(self, tr: &mut Transaction<'_, Sqlite>) -> Result<()> {
        let group_ids = sqlx::query_scalar!(
            "SELECT group_id FROM group_members WHERE contact_id = ?",
            self.contact_id,
        )
        .fetch_all(&mut **tr)
        .await?;
        let history_type = self.history_type.as_str();

        for group_id in group_ids {
            let group_history_id = new_uuid_v4();
            sqlx::query!(
                r#"
                INSERT INTO group_histories(
                    group_history_id,
                    group_id,
                    contact_id,
                    old_group_name,
                    new_group_name,
                    type
                ) VALUES (?, ?, ?, ?, ?, ?)
                "#,
                group_history_id,
                group_id,
                self.contact_id,
                self.old_group_name,
                self.new_group_name,
                history_type,
            )
            .execute(&mut **tr)
            .await?;
        }

        Ok(())
    }
}
