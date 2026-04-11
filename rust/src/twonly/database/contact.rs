// Table is defined in contacts.table.dart

use sqlx::{
    types::chrono::{DateTime, Utc},
    FromRow,
};

use crate::twonly::{database::Database, error::Result};

#[derive(FromRow, Clone, Debug)]
struct ContactRow {
    pub(crate) user_id: i64,
    pub(crate) username: String,
    pub(crate) created_at: DateTime<Utc>,
}

pub struct Contact {
    pub user_id: i64,
    pub username: String,
    // pub created_at: DateTime<Utc>,
}

impl From<ContactRow> for Contact {
    fn from(row: ContactRow) -> Self {
        Self {
            user_id: row.user_id,
            username: row.username,
            // created_at: row.created_at,
        }
    }
}

impl Contact {
    pub(crate) async fn get_all_contacts(db: &Database) -> Result<Vec<Contact>> {
        let rows = sqlx::query_as::<_, ContactRow>("SELECT * FROM contacts")
            .fetch_all(&db.pool)
            .await?;
        Ok(rows.into_iter().map(Into::into).collect())
    }
}
