use super::table::*;
use crate::error::Result;
use sqlx::SqliteConnection;

pub async fn list(connection: &mut SqliteConnection) -> Result<Vec<StickerMetadata>> {
    Ok(sqlx::query_as!(
        StickerMetadata,
        r#"
            SELECT content_hash AS "content_hash!",
                width AS "width!",
                height AS "height!",
                usage_count AS "usage_count!",
                created_at AS "created_at!",
                last_used_at AS "last_used_at!"
            FROM stickers
            ORDER BY usage_count DESC,
                last_used_at DESC,
                created_at DESC,
                content_hash ASC
        "#,
    )
    .fetch_all(connection)
    .await?)
}

pub async fn get(connection: &mut SqliteConnection, hash: &str) -> Result<Option<LocalSticker>> {
    let row = sqlx::query!(
        r#"
            SELECT content_hash, width, height, usage_count, created_at, last_used_at, webp FROM stickers
            WHERE content_hash = ?
        "#,
        hash,
    ).fetch_optional(connection).await?;

    Ok(row.map(|row| LocalSticker {
        metadata: StickerMetadata {
            content_hash: row.content_hash,
            width: row.width,
            height: row.height,
            usage_count: row.usage_count,
            created_at: row.created_at,
            last_used_at: row.last_used_at,
        },
        webp: row.webp,
    }))
}

pub async fn assets(
    connection: &mut SqliteConnection, hashes: &[String],
) -> Result<Vec<StickerAsset>> {
    Ok(sqlx::query_as!(
        StickerAsset,
        r#"
            SELECT content_hash, webp FROM stickers WHERE content_hash IN (SELECT value FROM json_each(?))
        "#,
        serde_json::to_string(hashes)?,
    ).fetch_all(connection).await?)
}
