use super::table::*;
use crate::database::app::contacts;
use crate::error::Result;
use sqlx::SqliteConnection;

pub async fn first_types(connection: &mut SqliteConnection) -> Result<Vec<FirstVerificationType>> {
    Ok(sqlx::query_as!(
        FirstVerificationType,
        r#"
            SELECT contact_id AS "contact_id!",
                type AS "type!"
            FROM (
                SELECT contact_id, type, ROW_NUMBER() OVER (
                    PARTITION BY contact_id
                    ORDER BY created_at, verification_id
                ) AS rank
                FROM valid_key_verifications
            )
            WHERE rank = 1
            ORDER BY contact_id
        "#,
    )
    .fetch_all(connection)
    .await?)
}

pub async fn is_verified(connection: &mut SqliteConnection, id: i64) -> Result<bool> {
    Ok(sqlx::query_scalar!(
        r#"
            SELECT EXISTS(
                SELECT 1
                FROM valid_key_verifications kv
                WHERE kv.contact_id = ?
            ) AS "value!: bool"
        "#,
        id,
    )
    .fetch_one(connection)
    .await?)
}

/// Only personal evidence authorizes an attestation. Inherited evidence must
/// never bootstrap another authority, including through a cycle.
pub async fn can_attest(connection: &mut SqliteConnection, id: i64) -> Result<bool> {
    Ok(sqlx::query_scalar!(
        r#"
            SELECT EXISTS(
                SELECT 1 FROM direct_key_verifications kv
                JOIN contacts c ON c.user_id = kv.contact_id
                WHERE kv.contact_id = ? AND c.blocked = 0
                    AND c.deleted_by_user = 0 AND c.account_deleted = 0
            ) AS "value!: bool"
        "#,
        id,
    )
    .fetch_one(connection)
    .await?)
}

pub async fn direct_verified_at(connection: &mut SqliteConnection, id: i64) -> Result<Option<i64>> {
    Ok(sqlx::query_scalar!(
        r#"SELECT MAX(created_at) * 1000 AS "value?: i64"
           FROM direct_key_verifications WHERE contact_id = ?"#,
        id,
    )
    .fetch_one(connection)
    .await?)
}

pub async fn list(connection: &mut SqliteConnection, id: i64) -> Result<Vec<KeyVerification>> {
    Ok(sqlx::query_as!(
        KeyVerification,
        r#"
            SELECT verification_id AS "verification_id!",
                contact_id AS "contact_id!",
                type AS "type!",
                verified_by AS "verified_by?",
                created_at AS "created_at!"
            FROM valid_key_verifications
            WHERE contact_id = ?
            ORDER BY verification_id
        "#,
        id,
    )
    .fetch_all(connection)
    .await?)
}

pub async fn contact(connection: &mut SqliteConnection, id: i64) -> Result<ContactVerifications> {
    let verifications: Vec<KeyVerification> = sqlx::query_as!(
        KeyVerification,
        r#"
            SELECT verification_id AS "verification_id!",
                contact_id AS "contact_id!",
                type AS "type!",
                verified_by AS "verified_by?",
                created_at AS "created_at!"
            FROM valid_key_verifications kv
            WHERE contact_id = ?
            ORDER BY verification_id
        "#,
        id,
    )
    .fetch_all(&mut *connection)
    .await?;

    let ids: Vec<_> = verifications
        .iter()
        .filter_map(|row| row.verified_by)
        .collect();

    let contacts = contacts::queries::list(
        connection,
        &contacts::table::ContactQuery {
            filter: contacts::table::ContactFilter::Ids,
            ids,
            username: None,
            username2: None,
            required_send_images: 0,
            manual_approval: false,
        },
    )
    .await?;

    Ok(ContactVerifications {
        verifications,
        contacts,
    })
}

pub async fn transferred(
    connection: &mut SqliteConnection, id: i64,
) -> Result<TransferredVerifications> {
    let relations: Vec<TransferredVerification> = sqlx::query_as!(
        TransferredVerification,
        r#"
            SELECT ur.from_contact_id AS "contact_id!",
                ur.public_key_verified_timestamp AS "verified_at!"
            FROM valid_discovery_verifications ur
            WHERE ur.announced_user_id = ?
            ORDER BY ur.from_contact_id
        "#,
        id,
    )
    .fetch_all(&mut *connection)
    .await?;

    let ids = relations.iter().map(|row| row.contact_id).collect();

    let contacts = contacts::queries::list(
        connection,
        &contacts::table::ContactQuery {
            filter: contacts::table::ContactFilter::Ids,
            ids,
            username: None,
            username2: None,
            required_send_images: 0,
            manual_approval: false,
        },
    )
    .await?;

    Ok(TransferredVerifications {
        relations,
        contacts,
    })
}

pub async fn groups(
    connection: &mut SqliteConnection, group: Option<&str>,
) -> Result<Vec<GroupVerification>> {
    // EXISTS avoids multiplying one member by all of their verifications and
    // announcement relations. Only one summary per group crosses the bridge.
    let rows = sqlx::query!(
        r#"
            SELECT group_id AS "group_id!",
                MIN(trust) AS "status!: i64",
                SUM(CASE
                WHEN trust = 0 THEN 1
                ELSE 0
                END
            ) AS "unverified_count!: i64"
            FROM (
                SELECT gm.group_id, CASE
                WHEN EXISTS(
                    SELECT 1
                    FROM direct_key_verifications kv
                    WHERE kv.contact_id = gm.contact_id
                ) THEN 2
                WHEN EXISTS(
                    SELECT 1 FROM valid_key_verifications kv
                    WHERE kv.contact_id = gm.contact_id
                ) THEN 1
                WHEN EXISTS(
                    SELECT 1
                    FROM valid_discovery_verifications ur
                    WHERE ur.announced_user_id = gm.contact_id
                ) THEN 1
                ELSE 0
                END AS trust
                FROM group_members gm
                WHERE ? IS NULL
                    OR gm.group_id = ?
            )
            GROUP BY group_id
            ORDER BY group_id
        "#,
        group,
        group,
    )
    .fetch_all(connection)
    .await?;

    Ok(rows
        .into_iter()
        .map(|row| GroupVerification {
            group_id: row.group_id,
            status: match row.status {
                2 => VerificationStatus::Trusted,
                1 => VerificationStatus::PartialTrusted,
                _ => VerificationStatus::NotTrusted,
            },
            unverified_count: row.unverified_count,
        })
        .collect())
}
