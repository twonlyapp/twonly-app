use crate::error::{Result, TwonlyError};
use sqlx::{Sqlite, Transaction};

pub async fn insert_token(tx: &mut Transaction<'_, Sqlite>, token: &[u8]) -> Result<i64> {
    Ok(sqlx::query_scalar!(
        r#"
            INSERT INTO verification_tokens(token) VALUES (?) RETURNING token_id AS "value!"
        "#,
        token,
    )
    .fetch_one(&mut **tx)
    .await?)
}

pub async fn insert(
    tx: &mut Transaction<'_, Sqlite>, contact: i64, kind: &str, verified_by: Option<i64>,
) -> Result<()> {
    if ![
        "migratedFromOldVersion",
        "qrScanned",
        "link",
        "manual",
        "secretQrToken",
        "contactSharedByVerified",
    ]
    .contains(&kind)
    {
        return Err(TwonlyError::Generic("unknown verification type".into()));
    }

    sqlx::query!(
        r#"
            INSERT INTO key_verifications(contact_id, type, verified_by) VALUES (?, ?, ?)
        "#,
        contact,
        kind,
        verified_by,
    )
    .execute(&mut **tx)
    .await?;

    Ok(())
}

pub async fn delete(
    tx: &mut Transaction<'_, Sqlite>, contact: i64, verification: Option<i64>,
) -> Result<bool> {
    if let Some(id) = verification {
        sqlx::query!(
            r#"
                DELETE FROM key_verifications WHERE verification_id = ?
            "#,
            id,
        )
        .execute(&mut **tx)
        .await?;
    } else {
        sqlx::query!(
            r#"
                DELETE FROM key_verifications WHERE contact_id = ?
            "#,
            contact,
        )
        .execute(&mut **tx)
        .await?;
    }

    Ok(sqlx::query_scalar!(
        r#"
            SELECT NOT EXISTS(SELECT 1 FROM key_verifications WHERE contact_id = ?) AS "value!: bool"
        "#,
        contact,
    )
    .fetch_one(&mut **tx)
    .await?)
}
