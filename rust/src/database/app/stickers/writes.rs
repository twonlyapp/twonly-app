use super::queries;
use super::table::LocalSticker;
use crate::error::{Result, TwonlyError};
use sha2::{Digest, Sha256};
use sqlx::{Sqlite, Transaction};

fn validate(webp: &[u8], width: i64, height: i64, expected: Option<&str>) -> Result<String> {
    if webp.is_empty()
        || webp.len() > 128 * 1024
        || !(1..=300).contains(&width)
        || !(1..=300).contains(&height)
    {
        return Err(TwonlyError::Generic(
            "invalid sticker size or dimensions".into(),
        ));
    }

    let hash = hex::encode(Sha256::digest(webp));

    if expected.is_some_and(|expected| expected != hash) {
        return Err(TwonlyError::Generic(
            "sticker digest does not match its bytes".into(),
        ));
    }

    Ok(hash)
}

pub async fn save(
    tx: &mut Transaction<'_, Sqlite>, webp: &[u8], width: i64, height: i64, expected: Option<&str>,
) -> Result<bool> {
    let hash = validate(webp, width, height, expected)?;

    Ok(sqlx::query!(
        r#"
            INSERT INTO stickers(content_hash, webp, width, height)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(content_hash) DO NOTHING
        "#,
        hash,
        webp,
        width,
        height,
    )
    .execute(&mut **tx)
    .await?
    .rows_affected()
        != 0)
}

pub async fn replace(
    tx: &mut Transaction<'_, Sqlite>, original_hash: &str, webp: &[u8], width: i64, height: i64,
    expected: &str,
) -> Result<LocalSticker> {
    let hash = validate(webp, width, height, Some(expected))?;

    // Metadata only: editing must not fetch the old image just to copy counters.
    let original = sqlx::query!(
        r#"
            SELECT usage_count, created_at, last_used_at
            FROM stickers
            WHERE content_hash = ?
        "#,
        original_hash,
    )
    .fetch_optional(&mut **tx)
    .await?;

    let original =
        original.ok_or_else(|| TwonlyError::Generic("sticker is no longer stored".into()))?;

    let (usage, created, used) = (
        original.usage_count,
        original.created_at,
        original.last_used_at,
    );

    if hash != original_hash {
        sqlx::query!(
            r#"
                INSERT INTO stickers (
                    content_hash, webp, width, height,
                    usage_count, created_at, last_used_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(content_hash) DO UPDATE
                SET usage_count = stickers.usage_count + excluded.usage_count,
                    last_used_at = MAX(stickers.last_used_at, excluded.last_used_at)
            "#,
            &hash,
            webp,
            width,
            height,
            usage,
            created,
            used,
        )
        .execute(&mut **tx)
        .await?;

        remove(tx, original_hash).await?;
    }

    Ok(queries::get(tx, &hash)
        .await?
        .expect("sticker exists within transaction"))
}

pub async fn record_use(tx: &mut Transaction<'_, Sqlite>, hash: &str) -> Result<()> {
    sqlx::query!(
        r#"
            UPDATE stickers
            SET usage_count = usage_count + 1,
                last_used_at = CAST(strftime('%s', 'now') AS INTEGER)
            WHERE content_hash = ?
        "#,
        hash,
    )
    .execute(&mut **tx)
    .await?;

    Ok(())
}

pub async fn remove(tx: &mut Transaction<'_, Sqlite>, hash: &str) -> Result<()> {
    sqlx::query!(
        r#"
            DELETE FROM stickers WHERE content_hash = ?
        "#,
        hash,
    )
    .execute(&mut **tx)
    .await?;

    Ok(())
}
