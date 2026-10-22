//! Frozen historical upgrades. Current schema changes remain SQLx migrations.
//! Run all pending steps under one exclusive transaction; a failed step leaves
//! both data and user_version unchanged. The legacy connection is closed before
//! import.

use crate::error::{Result, TwonlyError};
use sqlx::sqlite::SqliteConnectOptions;
use sqlx::{Connection, SqliteConnection};
use std::path::Path;
use std::time::Duration;

const STEPS: &[&str] = &[
    include_str!("legacy_migrations/0001_to_0002.sql"),
    include_str!("legacy_migrations/0002_to_0003.sql"),
    include_str!("legacy_migrations/0003_to_0004.sql"),
    include_str!("legacy_migrations/0004_to_0005.sql"),
    include_str!("legacy_migrations/0005_to_0006.sql"),
    include_str!("legacy_migrations/0006_to_0007.sql"),
    include_str!("legacy_migrations/0007_to_0008.sql"),
    include_str!("legacy_migrations/0008_to_0009.sql"),
    include_str!("legacy_migrations/0009_to_0010.sql"),
    include_str!("legacy_migrations/0010_to_0011.sql"),
    include_str!("legacy_migrations/0011_to_0012.sql"),
    include_str!("legacy_migrations/0012_to_0013.sql"),
    include_str!("legacy_migrations/0013_to_0014.sql"),
    include_str!("legacy_migrations/0014_to_0015.sql"),
    include_str!("legacy_migrations/0015_to_0016.sql"),
    include_str!("legacy_migrations/0016_to_0017.sql"),
    include_str!("legacy_migrations/0017_to_0018.sql"),
    include_str!("legacy_migrations/0018_to_0019.sql"),
    include_str!("legacy_migrations/0019_to_0020.sql"),
    include_str!("legacy_migrations/0020_to_0021.sql"),
    include_str!("legacy_migrations/0021_to_0022.sql"),
    include_str!("legacy_migrations/0022_to_0023.sql"),
    include_str!("legacy_migrations/0023_to_0024.sql"),
    include_str!("legacy_migrations/0024_to_0025.sql"),
];

pub async fn upgrade(path: &Path) -> Result<()> {
    crate::database::maintenance::initialize()?;

    let options = SqliteConnectOptions::new()
        .filename(path)
        .create_if_missing(false)
        .foreign_keys(false)
        .busy_timeout(Duration::from_secs(30));

    // Do not change the journal mode of an existing database or copy a live
    // SQLite file: its committed state may still be in a WAL sidecar.
    let mut connection = SqliteConnection::connect_with(&options).await?;

    let result = upgrade_connection(&mut connection).await;

    let closed = connection.close().await;

    result?;

    closed?;

    Ok(())
}

async fn upgrade_connection(connection: &mut SqliteConnection) -> Result<()> {
    let mut tx = connection.begin_with("BEGIN EXCLUSIVE").await?;

    let version: i64 = sqlx::query_scalar("PRAGMA user_version")
        .fetch_one(&mut *tx)
        .await?;

    if !(1..=25).contains(&version) {
        return Err(TwonlyError::Generic(format!(
            "Unsupported legacy schema version {version}"
        )));
    }

    if version == 25 {
        tx.commit().await?;

        return Ok(());
    }

    for step in STEPS.iter().skip((version - 1) as usize) {
        sqlx::raw_sql(*step).execute(&mut *tx).await?;
    }

    sqlx::query("PRAGMA user_version = 25")
        .execute(&mut *tx)
        .await?;

    tx.commit().await?;

    Ok(())
}

#[cfg(test)]

mod tests {

    use super::*;
    use crate::database::app::AppDatabase;
    use serde::Deserialize;
    use sqlx::{AssertSqlSafe, Row};
    use std::collections::BTreeMap;

    #[derive(Deserialize)]

    struct Fixture {
        version: i64,
        schema: Vec<String>,
        seed: Vec<String>,
        expected: BTreeMap<String, Contents>,
    }

    #[derive(Deserialize)]

    struct Contents {
        columns: Vec<String>,
        rows: Vec<Vec<String>>,
    }

    fn fixtures() -> Vec<Fixture> {
        serde_json::from_str(include_str!("../../../tests/fixtures/legacy_upgrades.json")).unwrap()
    }

    async fn seed(path: &Path, fixture: &Fixture) {
        let options = SqliteConnectOptions::new()
            .filename(path)
            .create_if_missing(true)
            .foreign_keys(false);

        let mut connection = SqliteConnection::connect_with(&options).await.unwrap();

        for sql in fixture.schema.iter().chain(&fixture.seed) {
            sqlx::raw_sql(AssertSqlSafe(sql.as_str()))
                .execute(&mut connection)
                .await
                .unwrap();
        }

        sqlx::query(AssertSqlSafe(format!(
            "PRAGMA user_version = {}",
            fixture.version
        )))
        .execute(&mut connection)
        .await
        .unwrap();

        connection.close().await.unwrap();
    }

    #[tokio::test]

    async fn all_25_historical_versions_match_drift_with_data_and_import_successfully() {
        for fixture in fixtures() {
            let directory = tempfile::tempdir().unwrap();

            let path = directory.path().join("twonly.sqlite");

            seed(&path, &fixture).await;

            upgrade(&path)
                .await
                .unwrap_or_else(|error| panic!("v{}: {error}", fixture.version));

            upgrade(&path).await.unwrap(); // A restarted startup is idempotent.
            let options = SqliteConnectOptions::new().filename(&path).read_only(true);

            let mut connection = SqliteConnection::connect_with(&options).await.unwrap();

            for (table, expected) in &fixture.expected {
                let columns = expected
                    .columns
                    .iter()
                    .map(|name| format!("quote(\"{name}\")"))
                    .collect::<Vec<_>>()
                    .join(", ");

                let rows = sqlx::query(AssertSqlSafe(format!(
                    "SELECT {columns} FROM \"{table}\" ORDER BY rowid"
                )))
                .fetch_all(&mut connection)
                .await
                .unwrap();

                let actual: Vec<Vec<String>> = rows
                    .iter()
                    .map(|row| {
                        (0..expected.columns.len())
                            .map(|index| row.get(index))
                            .collect()
                    })
                    .collect();

                assert_eq!(actual, expected.rows, "v{} table {table}", fixture.version);
            }

            connection.close().await.unwrap();

            let target = AppDatabase::new(
                directory.path().join("app.sqlite").to_str().unwrap(),
                None,
                false,
            )
            .await
            .unwrap();

            target.run_migrations().await.unwrap();

            let direct_path = directory.path().join("direct-import.sqlite");

            seed(&direct_path, &fixture).await;

            target
                .import_legacy(&direct_path)
                .await
                .unwrap_or_else(|error| panic!("import v{}: {error}", fixture.version));

            assert!(target.is_legacy_import_complete().await.unwrap());

            let (name, avatar, signal): (String, Vec<u8>, String) = sqlx::query_as(
                "SELECT display_name, avatar_svg_compressed, signal_version FROM contacts WHERE \
                 user_id = 7",
            )
            .fetch_one(&target.pool)
            .await
            .unwrap();

            assert_eq!(name, "Ålice");

            assert_eq!(avatar, vec![0, 255, 1]);

            assert_eq!(signal, "v1");

            let flags: (i64, i64) =
                sqlx::query_as("SELECT archived, deleted_content FROM groups WHERE group_id = 'g'")
                    .fetch_one(&target.pool)
                    .await
                    .unwrap();

            assert_eq!(flags, (1, 1));

            target.pool.close().await;
        }
    }

    #[tokio::test]

    async fn failure_rolls_back_prior_steps_and_unsupported_versions_are_untouched() {
        let directory = tempfile::tempdir().unwrap();

        let path = directory.path().join("twonly.sqlite");

        seed(&path, &fixtures().remove(0)).await;

        let mut connection = SqliteConnection::connect_with(
            &SqliteConnectOptions::new()
                .filename(&path)
                .foreign_keys(false),
        )
        .await
        .unwrap();

        sqlx::query("DROP TABLE media_files")
            .execute(&mut connection)
            .await
            .unwrap();

        connection.close().await.unwrap();

        assert!(upgrade(&path).await.is_err());

        let mut connection =
            SqliteConnection::connect_with(&SqliteConnectOptions::new().filename(&path))
                .await
                .unwrap();

        let version: i64 = sqlx::query_scalar("PRAGMA user_version")
            .fetch_one(&mut connection)
            .await
            .unwrap();

        assert_eq!(version, 1);

        let columns: Vec<String> =
            sqlx::query_scalar("SELECT name FROM pragma_table_info('messages')")
                .fetch_all(&mut connection)
                .await
                .unwrap();

        assert!(!columns.contains(&"media_reopened".into()));

        sqlx::query("PRAGMA user_version = 26")
            .execute(&mut connection)
            .await
            .unwrap();

        connection.close().await.unwrap();

        assert!(upgrade(&path).await.is_err());

        let mut connection =
            SqliteConnection::connect_with(&SqliteConnectOptions::new().filename(&path))
                .await
                .unwrap();

        let version: i64 = sqlx::query_scalar("PRAGMA user_version")
            .fetch_one(&mut connection)
            .await
            .unwrap();

        assert_eq!(version, 26);

        let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM contacts WHERE user_id = 7")
            .fetch_one(&mut connection)
            .await
            .unwrap();

        assert_eq!(count, 1);

        connection.close().await.unwrap();

        let absent = directory.path().join("new.sqlite");

        assert!(upgrade(&absent).await.is_err());

        assert!(!absent.exists());
    }

    #[tokio::test]

    async fn legacy_upgrade_and_import_read_committed_wal_without_switching_modes() {
        let directory = tempfile::tempdir().unwrap();

        let path = directory.path().join("twonly.sqlite");

        seed(&path, &fixtures().remove(0)).await;

        let options = SqliteConnectOptions::new()
            .filename(&path)
            .journal_mode(sqlx::sqlite::SqliteJournalMode::Wal);

        let mut legacy = SqliteConnection::connect_with(&options).await.unwrap();

        sqlx::query("UPDATE contacts SET username = 'committed-in-wal' WHERE user_id = 7")
            .execute(&mut legacy)
            .await
            .unwrap();

        let wal = std::path::PathBuf::from(format!("{}-wal", path.display()));

        assert!(std::fs::metadata(wal).unwrap().len() > 0);

        upgrade(&path).await.unwrap();

        let mode: String = sqlx::query_scalar("PRAGMA journal_mode")
            .fetch_one(&mut legacy)
            .await
            .unwrap();

        assert_eq!(mode, "wal");

        let target = AppDatabase::new(
            directory.path().join("app.sqlite").to_str().unwrap(),
            None,
            false,
        )
        .await
        .unwrap();

        target.run_migrations().await.unwrap();

        target.import_legacy(&path).await.unwrap();

        let username: String =
            sqlx::query_scalar("SELECT username FROM contacts WHERE user_id = 7")
                .fetch_one(&target.pool)
                .await
                .unwrap();

        assert_eq!(username, "committed-in-wal");

        legacy.close().await.unwrap();

        target.pool.close().await;
    }
}
