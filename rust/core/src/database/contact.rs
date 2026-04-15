// use sqlx::types::chrono::{DateTime, Utc};
use sqlx::FromRow;

use super::Database;
use crate::bridge::error::Result;

#[derive(FromRow, Clone, Debug)]
struct ContactRow {
    pub(crate) user_id: i64,
    pub(crate) username: String,
    // pub(crate) created_at: DateTime<Utc>,
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

#[cfg(test)]
mod tests {
    use crate::bridge::tests::initialize_twonly_for_testing;
    use crate::database::contact::Contact;

    #[tokio::test]
    async fn test_get_all_contacts() {
        let twonly = initialize_twonly_for_testing().await.unwrap();

        let contacts = Contact::get_all_contacts(&twonly.database).await.unwrap();

        let users = vec!["alice", "bob", "charlie", "diana", "eve", "frank", "grace"];

        assert_eq!(contacts.len(), users.len());

        for contact in contacts {
            assert_eq!(users[contact.user_id as usize], &contact.username);
        }
    }
}
