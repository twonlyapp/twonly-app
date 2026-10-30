use super::table::*;
use crate::error::Result;
use sqlx::SqliteConnection;

/// Game cards move to their latest announced activity's timestamp, so this
/// includes a recent move in a game that was originally added earlier.
pub async fn has_recent_messages(connection: &mut SqliteConnection, since: i64) -> Result<bool> {
    Ok(sqlx::query_scalar!(
        r#"SELECT EXISTS (
            SELECT 1 FROM webxdc_instances i
            JOIN messages m ON m.message_id = i.instance_id
            WHERE m.type = 'webxdcApp' AND m.is_deleted_from_sender = 0
                AND m.created_at >= ?
        ) AS "value!: bool""#,
        since,
    )
    .fetch_one(connection)
    .await?)
}

/// Upgrade existing cards using the notification payload already on this
/// device. New activities persist it with their origin, independently of push
/// delivery or whether the game is open.
pub(crate) async fn restore_notification_content(pool: &sqlx::SqlitePool) -> Result<()> {
    use crate::api::proto::client::AdditionalMessageData;
    use prost::Message;

    let mut transaction = pool.begin().await?;
    let claimed = sqlx::query!(
        "INSERT INTO app_metadata(key, value) VALUES ('webxdc_notification_content_restored', '1')
         ON CONFLICT(key) DO NOTHING"
    )
    .execute(&mut *transaction)
    .await?
    .rows_affected();
    if claimed == 0 {
        return Ok(());
    }
    let rows = sqlx::query!(
        r#"SELECT m.message_id, m.additional_message_data, n.content AS "content!: String"
           FROM messages m JOIN chat_messages c ON c.activity_message_id = m.message_id
           JOIN notification_outbox n ON n.message_id = m.message_id
           WHERE m.type = 'text' AND n.kind = 'webxdc' AND n.content IS NOT NULL
           ORDER BY n.created_at"#
    )
    .fetch_all(&mut *transaction)
    .await?;
    for row in rows {
        let Some(bytes) = row.additional_message_data else {
            continue;
        };
        let Ok(mut data) = AdditionalMessageData::decode(bytes.as_slice()) else {
            continue;
        };
        let Some(origin) = data.webxdc_origin.as_mut() else {
            continue;
        };
        if origin.notification_content.is_some() || !row.message_id.ends_with("-info") {
            continue;
        }
        origin.notification_content = Some(row.content);
        let bytes = data.encode_to_vec();
        sqlx::query!(
            "UPDATE messages SET additional_message_data = ? WHERE message_id = ?",
            bytes,
            row.message_id
        )
        .execute(&mut *transaction)
        .await?;
    }
    transaction.commit().await?;
    Ok(())
}

pub async fn app(
    connection: &mut SqliteConnection, id: &str, version: i64,
) -> Result<Option<WebxdcCardApp>> {
    Ok(sqlx::query_as!(
        WebxdcCardApp,
        r#"
            SELECT app_id AS "app_id!",
                version AS "version!",
                name AS "name!",
                name_translations AS "name_translations!",
                icon AS "icon?"
            FROM webxdc_apps
            WHERE app_id = ? AND version = ?
        "#,
        id,
        version,
    )
    .fetch_optional(connection)
    .await?)
}

pub async fn instance(
    connection: &mut SqliteConnection, id: &str,
) -> Result<Option<WebxdcCardInstance>> {
    Ok(sqlx::query_as!(
        WebxdcCardInstance,
        r#"
            SELECT instance_id AS "instance_id!",
                group_id AS "group_id!",
                app_id AS "app_id!",
                version AS "version!",
                bundle_sha256 AS "bundle_sha256?",
                origin_token AS "origin_token!",
                summary AS "summary?",
                document AS "document?"
            FROM webxdc_instances
            WHERE instance_id = ?
        "#,
        id,
    )
    .fetch_optional(connection)
    .await?)
}

pub async fn serial(connection: &mut SqliteConnection, id: &str) -> Result<i64> {
    Ok(sqlx::query_scalar!(
        r#"
            SELECT COALESCE(MAX(serial), 0) AS "value!"
            FROM webxdc_updates
            WHERE instance_id = ?
        "#,
        id,
    )
    .fetch_one(connection)
    .await?)
}
