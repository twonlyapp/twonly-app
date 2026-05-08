use crate::error::Result;
use chrono::{DateTime, Utc};
use sqlx::{FromRow, SqlitePool};

#[derive(Debug, FromRow)]
pub struct ReceivedMessage {
    pub id: i64,
    pub sender_id: String,
    pub content: Vec<u8>,
    pub timestamp: DateTime<Utc>,
}

impl ReceivedMessage {
    pub async fn insert(pool: &SqlitePool, sender_id: &str, content: &[u8]) -> Result<i64> {
        let result =
            sqlx::query("INSERT INTO received_messages (sender_id, content) VALUES (?, ?)")
                .bind(sender_id)
                .bind(content)
                .execute(pool)
                .await?;

        Ok(result.last_insert_rowid())
    }

    pub async fn get_all(pool: &SqlitePool) -> Result<Vec<Self>> {
        let messages = sqlx::query_as::<_, Self>(
            "SELECT id, sender_id, content, timestamp FROM received_messages ORDER BY timestamp DESC",
        )
        .fetch_all(pool)
        .await?;

        Ok(messages)
    }
}
