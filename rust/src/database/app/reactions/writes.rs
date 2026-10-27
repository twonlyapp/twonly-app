use crate::error::Result;
use sqlx::{Sqlite, Transaction};

pub async fn update_own(
    tx: &mut Transaction<'_, Sqlite>, message: &str, emoji: &str, remove: bool,
) -> Result<()> {
    sqlx::query!(
        r#"
            DELETE FROM reactions WHERE message_id = ? AND sender_id IS NULL AND emoji = ?
        "#,
        message,
        emoji,
    )
    .execute(&mut **tx)
    .await?;

    if !remove {
        sqlx::query!(
            r#"
                INSERT INTO reactions(message_id, emoji, sender_id)
                SELECT ?,
                    ?,
                    NULL
                WHERE EXISTS(
                    SELECT 1
                    FROM messages
                    WHERE message_id = ?
                )
            "#,
            message,
            emoji,
            message,
        )
        .execute(&mut **tx)
        .await?;
    }

    Ok(())
}
