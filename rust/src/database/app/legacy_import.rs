/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::{
    AppDatabase, MigrationReport, TableMigrationCount, APPLICATION_TABLES, LEGACY_COPY_TABLES,
};
use crate::error::{Result, TwonlyError};
use sqlx::{Acquire, AssertSqlSafe, Row};
use std::collections::BTreeSet;
use std::path::Path;

impl AppDatabase {
    pub async fn is_legacy_import_complete(&self) -> Result<bool> {
        let value = sqlx::query_scalar!(
            r#"
            SELECT value
            FROM app_metadata
            WHERE key = 'legacy_import_complete'
            "#
        )
        .fetch_optional(&self.pool)
        .await?;
        Ok(value.as_deref() == Some("1"))
    }

    pub async fn complete_empty_legacy_import(&self) -> Result<MigrationReport> {
        let mut transaction = self.pool.begin().await?;
        sqlx::query!(
            r#"
            INSERT INTO app_metadata(key, value)
            VALUES('legacy_schema_version', '25')
            ON CONFLICT(key) DO UPDATE SET value = excluded.value
            "#
        )
        .execute(&mut *transaction)
        .await?;
        sqlx::query!(
            r#"
            INSERT INTO app_metadata(key, value)
            VALUES('legacy_import_complete', '1')
            ON CONFLICT(key) DO UPDATE SET value = excluded.value
            "#
        )
        .execute(&mut *transaction)
        .await?;
        transaction.commit().await?;
        self.migration_report().await
    }

    pub async fn import_legacy(&self, legacy_path: &Path) -> Result<MigrationReport> {
        if self.is_legacy_import_complete().await? {
            return self.migration_report().await;
        }
        if !legacy_path.exists() {
            return Err(TwonlyError::DatabaseNotFound);
        }
        let mut connection = self.pool.acquire().await?;
        // SQLCipher's KEY clause and the attached schema are not available to
        // SQLx's compile-time SQLite connection.
        sqlx::query(r#"ATTACH DATABASE ? AS legacy KEY ''"#)
            .bind(legacy_path.to_string_lossy().as_ref())
            .execute(&mut *connection)
            .await?;
        let import_result = import(&mut connection).await;
        let _ = sqlx::query(r#"DETACH DATABASE legacy"#)
            .execute(&mut *connection)
            .await;
        let report = import_result?;
        Ok(report)
    }

    async fn migration_report(&self) -> Result<MigrationReport> {
        let legacy_version = sqlx::query_scalar!(
            r#"
            SELECT value
            FROM app_metadata
            WHERE key = 'legacy_schema_version'
            "#
        )
        .fetch_optional(&self.pool)
        .await?
        .and_then(|value| value.parse().ok())
        .unwrap_or(25);
        let mut tables = Vec::with_capacity(APPLICATION_TABLES.len());
        for table in APPLICATION_TABLES {
            let rows = sqlx::query_scalar::<_, i64>(AssertSqlSafe(format!(
                r#"SELECT COUNT(*) FROM "{table}""#
            )))
            .fetch_one(&self.pool)
            .await?;
            tables.push(TableMigrationCount {
                table: (*table).to_owned(),
                rows,
            });
        }
        Ok(MigrationReport {
            legacy_version,
            tables,
        })
    }
}

async fn import(
    connection: &mut sqlx::pool::PoolConnection<sqlx::Sqlite>,
) -> Result<MigrationReport> {
    let legacy_version: i64 = sqlx::query_scalar(r#"PRAGMA legacy.user_version"#)
        .fetch_one(&mut **connection)
        .await?;
    if legacy_version != 25 {
        return Err(TwonlyError::Generic(format!("Legacy database must be upgraded to Drift schema 25 before import; found {legacy_version}")));
    }
    let mut tx = connection.begin().await?;
    sqlx::query!(r#"PRAGMA defer_foreign_keys = ON"#)
        .execute(&mut *tx)
        .await?;
    let mut counts = Vec::with_capacity(APPLICATION_TABLES.len());
    for table in LEGACY_COPY_TABLES {
        let columns = common_columns(&mut tx, table).await?;
        if columns.is_empty() {
            return Err(TwonlyError::Generic(format!(
                "No importable columns found for {table}"
            )));
        }
        let quoted = columns
            .iter()
            .map(|column| format!("\"{}\"", column.replace('"', "\"\"")))
            .collect::<Vec<_>>()
            .join(", ");
        sqlx::query(AssertSqlSafe(format!(
            r#"INSERT OR REPLACE INTO main."{table}" ({quoted}) SELECT {quoted} FROM legacy."{table}""#
        )))
        .execute(&mut *tx)
        .await?;
        let source_count: i64 = sqlx::query_scalar(AssertSqlSafe(format!(
            r#"SELECT COUNT(*) FROM legacy."{table}""#
        )))
        .fetch_one(&mut *tx)
        .await?;
        let target_count: i64 = sqlx::query_scalar(AssertSqlSafe(format!(
            r#"SELECT COUNT(*) FROM main."{table}""#
        )))
        .fetch_one(&mut *tx)
        .await?;
        if source_count != target_count {
            return Err(TwonlyError::Generic(format!(
                "Row count mismatch for {table}: source={source_count}, target={target_count}"
            )));
        }
        let mismatch: Option<i64> = sqlx::query_scalar(AssertSqlSafe(format!(
            r#"SELECT 1 FROM (SELECT {quoted} FROM main."{table}" EXCEPT SELECT {quoted} FROM legacy."{table}") LIMIT 1"#
        )))
        .fetch_optional(&mut *tx)
        .await?;
        let reverse_mismatch: Option<i64> = sqlx::query_scalar(AssertSqlSafe(format!(
            r#"SELECT 1 FROM (SELECT {quoted} FROM legacy."{table}" EXCEPT SELECT {quoted} FROM main."{table}") LIMIT 1"#
        )))
        .fetch_optional(&mut *tx)
        .await?;
        if mismatch.is_some() || reverse_mismatch.is_some() {
            return Err(TwonlyError::Generic(format!(
                "Data mismatch while importing {table}"
            )));
        }
        counts.push(TableMigrationCount {
            table: (*table).to_owned(),
            rows: source_count,
        });
    }
    migrate_legacy_contact_groups(&mut tx, &mut counts).await?;
    copy_sequences(&mut tx).await?;
    let foreign_key_errors =
        sqlx::query_scalar!(r#"SELECT COUNT(*) FROM pragma_foreign_key_check"#)
            .fetch_one(&mut *tx)
            .await?;
    if foreign_key_errors != 0 {
        return Err(TwonlyError::Generic(format!(
            "Imported database has {foreign_key_errors} foreign-key violations"
        )));
    }
    sqlx::query!(
        r#"
        INSERT INTO app_metadata(key, value)
        VALUES('legacy_schema_version', ?)
        ON CONFLICT(key) DO UPDATE SET value = excluded.value
        "#,
        legacy_version.to_string(),
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query!(
        r#"
        INSERT INTO app_metadata(key, value)
        VALUES('legacy_import_complete', '1')
        ON CONFLICT(key) DO UPDATE SET value = '1'
        "#
    )
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(MigrationReport {
        legacy_version,
        tables: counts,
    })
}

async fn migrate_legacy_contact_groups(
    connection: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    counts: &mut Vec<TableMigrationCount>,
) -> Result<()> {
    sqlx::query(
        r#"INSERT INTO main.contact_groups (
               id, name, emoji, text_color, background_color,
               show_as_shortcut, show_as_label, usage_counter, created_at
           )
           SELECT id, name, NULL, text_color, background_color,
                  0, 1, 0, created_at
           FROM legacy.labels"#,
    )
    .execute(&mut **connection)
    .await?;
    sqlx::query(
        r#"INSERT OR IGNORE INTO main.contact_group_members
               (contact_group_id, user_id, group_id)
           SELECT label_id, contact_id, NULL
           FROM legacy.contact_labels"#,
    )
    .execute(&mut **connection)
    .await?;
    sqlx::query(
        r#"INSERT INTO main.contact_groups (
               id, name, emoji, text_color, background_color,
               show_as_shortcut, show_as_label, usage_counter, created_at
           )
           SELECT COALESCE((SELECT MAX(id) FROM legacy.labels), 0) + id,
                  emoji, emoji, 4278190080, 0,
                  1, 0, usage_counter,
                  CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)
           FROM legacy.shortcuts"#,
    )
    .execute(&mut **connection)
    .await?;
    sqlx::query(
        r#"INSERT OR IGNORE INTO main.contact_group_members
               (contact_group_id, user_id, group_id)
           SELECT COALESCE((SELECT MAX(id) FROM legacy.labels), 0) + sm.shortcut_id,
                  gm.contact_id, NULL
           FROM legacy.shortcut_members sm
           INNER JOIN legacy.groups g ON g.group_id = sm.group_id
           INNER JOIN legacy.group_members gm ON gm.group_id = g.group_id
           WHERE g.is_direct_chat = 1"#,
    )
    .execute(&mut **connection)
    .await?;
    sqlx::query(
        r#"INSERT OR IGNORE INTO main.contact_group_members
               (contact_group_id, user_id, group_id)
           SELECT COALESCE((SELECT MAX(id) FROM legacy.labels), 0) + sm.shortcut_id,
                  NULL, sm.group_id
           FROM legacy.shortcut_members sm
           INNER JOIN legacy.groups g ON g.group_id = sm.group_id
           WHERE g.is_direct_chat = 0"#,
    )
    .execute(&mut **connection)
    .await?;

    for table in ["contact_groups", "contact_group_members"] {
        let rows = sqlx::query_scalar::<_, i64>(AssertSqlSafe(format!(
            r#"SELECT COUNT(*) FROM main."{table}""#
        )))
        .fetch_one(&mut **connection)
        .await?;
        counts.push(TableMigrationCount {
            table: table.to_owned(),
            rows,
        });
    }
    Ok(())
}

async fn common_columns(
    connection: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    table: &str,
) -> Result<Vec<String>> {
    let source_rows = sqlx::query(AssertSqlSafe(format!(
        r#"PRAGMA legacy.table_info("{table}")"#
    )))
    .fetch_all(&mut **connection)
    .await?;
    if source_rows.is_empty() {
        return Err(TwonlyError::Generic(format!(
            "Legacy database is missing table {table}"
        )));
    }
    let source: BTreeSet<String> = source_rows
        .iter()
        .map(|row| row.get::<String, _>("name"))
        .collect();
    let target_rows = sqlx::query(AssertSqlSafe(format!(
        r#"PRAGMA main.table_info("{table}")"#
    )))
    .fetch_all(&mut **connection)
    .await?;
    Ok(target_rows
        .iter()
        .map(|row| row.get::<String, _>("name"))
        .filter(|column| source.contains(column))
        .collect())
}

async fn copy_sequences(connection: &mut sqlx::Transaction<'_, sqlx::Sqlite>) -> Result<()> {
    for table in [
        "message_histories",
        "key_verifications",
        "verification_tokens",
        "user_discovery_own_promotions",
        "user_discovery_shares",
        "contact_groups",
    ] {
        let source_sequence: Option<i64> =
            sqlx::query_scalar(r#"SELECT seq FROM legacy.sqlite_sequence WHERE name = ?"#)
                .bind(table)
                .fetch_optional(&mut **connection)
                .await?;
        if let Some(sequence) = source_sequence {
            sqlx::query!(r#"DELETE FROM main.sqlite_sequence WHERE name = ?"#, table)
                .execute(&mut **connection)
                .await?;
            sqlx::query!(
                r#"INSERT INTO main.sqlite_sequence(name, seq) VALUES(?, ?)"#,
                table,
                sequence,
            )
            .execute(&mut **connection)
            .await?;
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::database::app::{SqlValue, APPLICATION_TABLES};
    use sqlx::{AssertSqlSafe, SqlitePool};
    use tempfile::tempdir;

    #[tokio::test]
    async fn imports_all_application_tables_and_is_idempotent() {
        let directory = tempdir().unwrap();
        let legacy_path = directory.path().join("twonly.sqlite");
        let target_path = directory.path().join("app_db.sqlite");

        let legacy = AppDatabase::new(legacy_path.to_str().unwrap(), None, false)
            .await
            .unwrap();
        create_legacy_schema(&legacy.pool).await;
        sqlx::query!(r#"PRAGMA user_version = 25"#)
            .execute(&legacy.pool)
            .await
            .unwrap();
        populate_every_table(&legacy.pool).await;
        create_and_populate_drift_signal_tables(&legacy.pool).await;
        legacy.pool.close().await;

        let target = AppDatabase::new(target_path.to_str().unwrap(), Some("test-key"), false)
            .await
            .unwrap();
        target.run_migrations().await.unwrap();
        let first = target.import_legacy(&legacy_path).await.unwrap();
        assert_eq!(first.tables.len(), APPLICATION_TABLES.len());
        assert!(first
            .tables
            .iter()
            .filter(|entry| !entry.table.starts_with("contact_group"))
            .all(|entry| entry.rows == 1));
        assert_eq!(
            first
                .tables
                .iter()
                .find(|entry| entry.table == "contact_groups")
                .unwrap()
                .rows,
            2
        );
        assert_eq!(
            first
                .tables
                .iter()
                .find(|entry| entry.table == "contact_group_members")
                .unwrap()
                .rows,
            2
        );
        let second = target.import_legacy(&legacy_path).await.unwrap();
        assert_eq!(first, second);
        assert!(target.is_legacy_import_complete().await.unwrap());

        let migrated_shortcut = sqlx::query_as::<_, (String, String, i64, i64)>(
            r#"SELECT name, emoji, background_color, show_as_shortcut
               FROM contact_groups WHERE emoji = '🔥'"#,
        )
        .fetch_one(&target.pool)
        .await
        .unwrap();
        assert_eq!(migrated_shortcut, ("🔥".into(), "🔥".into(), 0, 1));
        let migrated_group_target: String = sqlx::query_scalar(
            r#"SELECT group_id
               FROM contact_group_members
               WHERE group_id IS NOT NULL"#,
        )
        .fetch_one(&target.pool)
        .await
        .unwrap();
        assert_eq!(migrated_group_target, "group-1");

        let selected = target
            .raw_select(
                "SELECT username, avatar_svg_compressed FROM contacts WHERE user_id = ?".to_owned(),
                vec![SqlValue::integer(7)],
            )
            .await
            .unwrap();
        assert_eq!(selected.columns, vec!["username", "avatar_svg_compressed"]);
        assert_eq!(
            selected.rows[0].values[0],
            SqlValue::text("alice".to_owned())
        );
        assert_eq!(selected.rows[0].values[1], SqlValue::blob(vec![0, 1, 255]));

        target
            .raw_execute("BEGIN TRANSACTION".to_owned(), vec![])
            .await
            .unwrap();
        target
            .raw_execute(
                "UPDATE contacts SET username = ? WHERE user_id = ?".to_owned(),
                vec![SqlValue::text("changed".to_owned()), SqlValue::integer(7)],
            )
            .await
            .unwrap();
        target
            .raw_execute("ROLLBACK".to_owned(), vec![])
            .await
            .unwrap();
        let username = sqlx::query_scalar!(
            r#"
            SELECT username
            FROM contacts
            WHERE user_id = 7
            "#
        )
        .fetch_one(&target.pool)
        .await
        .unwrap();
        assert_eq!(username, "alice");

        let legacy_check = AppDatabase::new(legacy_path.to_str().unwrap(), None, true)
            .await
            .unwrap();
        let signal_checks = [
            (
                "signal_identity_key_stores",
                "identity_key",
                vec![0, 1, 2, 255],
            ),
            ("signal_pre_key_stores", "pre_key", vec![3, 4, 5]),
            ("signal_sender_key_stores", "sender_key", vec![6, 7, 8]),
            ("signal_session_stores", "session_record", vec![9, 10, 11]),
            (
                "signal_signed_pre_key_stores",
                "signed_pre_key",
                vec![12, 13, 14],
            ),
        ];
        for (table, column, expected) in signal_checks {
            let actual: Vec<u8> = sqlx::query_scalar(AssertSqlSafe(format!(
                r#"SELECT {column} FROM {table} LIMIT 1"#
            )))
            .fetch_one(&legacy_check.pool)
            .await
            .unwrap();
            assert_eq!(actual, expected, "Signal data changed in {table}");
        }
    }

    async fn create_legacy_schema(pool: &SqlitePool) {
        for migration in [
            include_str!("migrations/0001_initial.sql"),
            include_str!("migrations/0002_api_outbox.sql"),
            include_str!("migrations/0003_notification_outbox.sql"),
            include_str!("migrations/0004_sealed_sender.sql"),
            include_str!("migrations/0005_direct_media_upload.sql"),
            include_str!("migrations/0006_defer_receipts_missing_bundle.sql"),
            include_str!("migrations/0007_remove_experimental_transport.sql"),
            include_str!("migrations/0008_pending_plaintext.sql"),
            include_str!("migrations/0009_outbox_dispatch.sql"),
            include_str!("migrations/0010_media_trim.sql"),
            include_str!("migrations/0011_outgoing_contact_request.sql"),
        ] {
            sqlx::raw_sql(migration).execute(pool).await.unwrap();
        }
    }

    #[tokio::test]
    async fn rust_migration_converts_direct_users_and_actual_groups() {
        let directory = tempdir().unwrap();
        let path = directory.path().join("pre-contact-groups.sqlite");
        let database = AppDatabase::new(path.to_str().unwrap(), None, false)
            .await
            .unwrap();
        create_legacy_schema(&database.pool).await;
        for statement in [
            "INSERT INTO contacts(user_id, username) VALUES(7, 'alice')",
            "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES('direct-1', 'Alice', 1)",
            "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES('group-1', 'Friends', 0)",
            "INSERT INTO group_members(group_id, contact_id) VALUES('direct-1', 7)",
            "INSERT INTO shortcuts(id, emoji, usage_counter) VALUES(3, '🔥', 5)",
            "INSERT INTO shortcut_members(shortcut_id, group_id) VALUES(3, 'direct-1')",
            "INSERT INTO shortcut_members(shortcut_id, group_id) VALUES(3, 'group-1')",
            "INSERT INTO labels(id, name, text_color, background_color) VALUES(5, 'Family', 1, 2)",
            "INSERT INTO contact_labels(contact_id, label_id) VALUES(7, 5)",
        ] {
            sqlx::query(statement)
                .execute(&database.pool)
                .await
                .unwrap();
        }

        sqlx::raw_sql(include_str!("migrations/0012_contact_groups.sql"))
            .execute(&database.pool)
            .await
            .unwrap();

        let shortcut = sqlx::query_as::<_, (i64, String, String, i64, i64, i64)>(
            r#"SELECT id, name, emoji, background_color, show_as_shortcut, usage_counter
               FROM contact_groups WHERE emoji = '🔥'"#,
        )
        .fetch_one(&database.pool)
        .await
        .unwrap();
        assert_eq!(shortcut, (8, "🔥".into(), "🔥".into(), 0, 1, 5));

        let members = sqlx::query_as::<_, (Option<i64>, Option<String>)>(
            r#"SELECT user_id, group_id
               FROM contact_group_members
               WHERE contact_group_id = 8
               ORDER BY group_id"#,
        )
        .fetch_all(&database.pool)
        .await
        .unwrap();
        assert_eq!(
            members,
            vec![(Some(7), None), (None, Some("group-1".into()))]
        );
        let old_table_count: i64 = sqlx::query_scalar(
            r#"SELECT COUNT(*) FROM sqlite_master
               WHERE type = 'table'
                 AND name IN ('shortcuts', 'shortcut_members', 'labels', 'contact_labels')"#,
        )
        .fetch_one(&database.pool)
        .await
        .unwrap();
        assert_eq!(old_table_count, 0);
    }

    async fn populate_every_table(pool: &SqlitePool) {
        let statements = [
            "INSERT INTO contacts(user_id, username, avatar_svg_compressed, signal_version) VALUES(7, 'alice', x'0001FF', 'v2')",
            "INSERT INTO groups(group_id, group_name) VALUES('group-1', 'Friends')",
            "INSERT INTO media_files(media_id, type, encryption_key) VALUES('media-1', 'image', x'1020')",
            "INSERT INTO messages(group_id, message_id, sender_id, type, content, media_id) VALUES('group-1', 'message-1', 7, 'media', '', 'media-1')",
            "INSERT INTO message_histories(id, message_id, contact_id, content) VALUES(11, 'message-1', 7, NULL)",
            "INSERT INTO reactions(message_id, emoji, sender_id) VALUES('message-1', '👍', 7)",
            "INSERT INTO group_members(group_id, contact_id, member_state) VALUES('group-1', 7, 'admin')",
            "INSERT INTO receipts(receipt_id, contact_id, message_id, message) VALUES('receipt-1', 7, 'message-1', x'00FF')",
            "INSERT INTO received_receipts(receipt_id) VALUES('received-1')",
            "INSERT INTO message_actions(message_id, contact_id, type) VALUES('message-1', 7, 'openedAt')",
            "INSERT INTO group_histories(group_history_id, group_id, contact_id, type) VALUES('history-1', 'group-1', 7, 'createdGroup')",
            "INSERT INTO key_verifications(verification_id, contact_id, type, verified_by) VALUES(13, 7, 'qrScanned', NULL)",
            "INSERT INTO verification_tokens(token_id, token) VALUES(17, x'ABCDEF')",
            "INSERT INTO user_discovery_announced_users(announced_user_id, announced_public_key, public_id, username) VALUES(19, x'01', 23, 'bob')",
            "INSERT INTO user_discovery_user_relations(announced_user_id, from_contact_id) VALUES(19, 7)",
            "INSERT INTO user_discovery_other_promotions(from_contact_id, promotion_id, public_id, threshold, announcement_share) VALUES(7, 29, 31, 3, x'02')",
            "INSERT INTO user_discovery_own_promotions(version_id, contact_id, promotion) VALUES(37, 7, x'03')",
            "INSERT INTO user_discovery_shares(share_id, share, contact_id) VALUES(41, x'04', 7)",
            "INSERT INTO shortcuts(id, emoji, usage_counter) VALUES(43, '🔥', 5)",
            "INSERT INTO shortcut_members(shortcut_id, group_id) VALUES(43, 'group-1')",
            "INSERT INTO labels(id, name, text_color, background_color) VALUES(47, 'Family', 1, 2)",
            "INSERT INTO contact_labels(contact_id, label_id) VALUES(7, 47)",
        ];
        for statement in statements {
            sqlx::query(statement).execute(pool).await.unwrap();
        }
    }

    async fn create_and_populate_drift_signal_tables(pool: &SqlitePool) {
        let statements = [
            "CREATE TABLE signal_identity_key_stores(device_id INTEGER NOT NULL, name TEXT NOT NULL, identity_key BLOB NOT NULL, created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)), PRIMARY KEY(device_id, name))",
            "CREATE TABLE signal_pre_key_stores(pre_key_id INTEGER NOT NULL PRIMARY KEY, pre_key BLOB NOT NULL, created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))",
            "CREATE TABLE signal_sender_key_stores(sender_key_name TEXT NOT NULL PRIMARY KEY, sender_key BLOB NOT NULL)",
            "CREATE TABLE signal_session_stores(device_id INTEGER NOT NULL, name TEXT NOT NULL, session_record BLOB NOT NULL, created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)), PRIMARY KEY(device_id, name))",
            "CREATE TABLE signal_signed_pre_key_stores(signed_pre_key_id INTEGER NOT NULL PRIMARY KEY, signed_pre_key BLOB NOT NULL, created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))",
            "INSERT INTO signal_identity_key_stores(device_id, name, identity_key) VALUES(1, 'alice', x'000102FF')",
            "INSERT INTO signal_pre_key_stores(pre_key_id, pre_key) VALUES(2, x'030405')",
            "INSERT INTO signal_sender_key_stores(sender_key_name, sender_key) VALUES('group', x'060708')",
            "INSERT INTO signal_session_stores(device_id, name, session_record) VALUES(3, 'bob', x'090A0B')",
            "INSERT INTO signal_signed_pre_key_stores(signed_pre_key_id, signed_pre_key) VALUES(4, x'0C0D0E')",
        ];
        for statement in statements {
            sqlx::query(statement).execute(pool).await.unwrap();
        }
    }
}
