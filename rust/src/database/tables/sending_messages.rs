use crate::error::Result;
use chrono::{DateTime, Utc};
use sqlx::{FromRow, SqlitePool};

#[derive(Debug, FromRow)]
pub struct SendingMessage {
    pub id: i64,
    pub recipient_id: String,
    pub content: Vec<u8>,
    pub timestamp: DateTime<Utc>,
    pub status: String,
}

impl SendingMessage {
    pub async fn insert(pool: &SqlitePool, recipient_id: &str, content: &[u8]) -> Result<i64> {
        let result =
            sqlx::query("INSERT INTO sending_messages (recipient_id, content) VALUES (?, ?)")
                .bind(recipient_id)
                .bind(content)
                .execute(pool)
                .await?;

        Ok(result.last_insert_rowid())
    }

    pub async fn get_all(pool: &SqlitePool) -> Result<Vec<Self>> {
        let messages = sqlx::query_as::<_, Self>(
            "SELECT id, recipient_id, content, timestamp, status FROM sending_messages ORDER BY timestamp DESC",
        )
        .fetch_all(pool)
        .await?;

        Ok(messages)
    }
}
