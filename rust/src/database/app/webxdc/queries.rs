use super::table::*;
use crate::error::Result;
use sqlx::SqliteConnection;

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
