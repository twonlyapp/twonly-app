use crate::error::{Result, TwonlyError};
use sqlx::{Sqlite, Transaction};

pub async fn insert_token(tx: &mut Transaction<'_, Sqlite>, token: &[u8]) -> Result<i64> {
    if token.len() != 16 {
        return Err(TwonlyError::Generic(
            "verification token must contain 16 bytes".into(),
        ));
    }

    Ok(sqlx::query_scalar!(
        r#"
            INSERT INTO verification_tokens(token, proof_version) VALUES (?, 1) RETURNING token_id AS "value!"
        "#,
        token,
    )
    .fetch_one(&mut **tx)
    .await?)
}

pub async fn insert(
    tx: &mut Transaction<'_, Sqlite>, contact: i64, kind: &str, verified_by: Option<i64>,
) -> Result<bool> {
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

    if kind == "contactSharedByVerified" {
        let Some(verifier) = verified_by.filter(|verifier| *verifier != contact) else {
            return Ok(false);
        };

        if !super::queries::can_attest(tx, verifier).await? {
            return Ok(false);
        }
    } else if verified_by.is_some() {
        return Err(TwonlyError::Generic(
            "personal verification cannot have an attester".into(),
        ));
    }

    let inserted = sqlx::query!(
        r#"
            INSERT INTO key_verifications(contact_id, type, verified_by)
            SELECT ?, ?, ?
            WHERE NOT EXISTS (
                SELECT 1 FROM key_verifications
                WHERE contact_id = ? AND type = ? AND verified_by IS ?
            )
        "#,
        contact,
        kind,
        verified_by,
        contact,
        kind,
        verified_by,
    )
    .execute(&mut **tx)
    .await?
    .rows_affected()
        != 0;

    Ok(inserted)
}

pub async fn delete(
    tx: &mut Transaction<'_, Sqlite>, contact: i64, verification: Option<i64>,
) -> Result<bool> {
    if let Some(id) = verification {
        sqlx::query!(
            r#"
                DELETE FROM key_verifications WHERE verification_id IN (
                    SELECT duplicate.verification_id FROM key_verifications duplicate
                    JOIN key_verifications selected
                      ON duplicate.contact_id = selected.contact_id
                     AND duplicate.type = selected.type
                     AND duplicate.verified_by IS selected.verified_by
                    WHERE selected.verification_id = ? AND selected.contact_id = ?
                )
            "#,
            id,
            contact,
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
