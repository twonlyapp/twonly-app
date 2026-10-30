//! Version 3 backups contain schema and typed rows, never encrypted SQLite
//! pages or index contents. Plaintext stays in memory; restore writes directly
//! into a new SQLCipher database before the normal installation checks run.

use crate::database::lifecycle::Operation;
use crate::error::{Result, TwonlyError};
use futures_util::TryStreamExt;
use serde::{Deserialize, Serialize};
use sqlx::{AssertSqlSafe, Connection, Row, SqlitePool, TypeInfo, ValueRef};
use zeroize::{Zeroize, ZeroizeOnDrop, Zeroizing};

pub(crate) const DATABASES: [(&str, &str); 2] = [
    ("app_db.sqlite", "app_db.dump"),
    ("rust_db.sqlite", "rust_db.dump"),
];

#[derive(Serialize, Deserialize, Zeroize, ZeroizeOnDrop)]
struct Dump {
    user_version: i64,
    application_id: i64,
    schema: Vec<Schema>,
    tables: Vec<Table>,
}

#[derive(Serialize, Deserialize, Zeroize, ZeroizeOnDrop)]
struct Schema {
    kind: String,
    sql: String,
}

#[derive(Serialize, Deserialize, Zeroize, ZeroizeOnDrop)]
struct Table {
    name: String,
    columns: Vec<String>,
    rows: Vec<Vec<Value>>,
}

#[derive(Serialize, Deserialize, Zeroize, ZeroizeOnDrop)]
enum Value {
    Null,
    Integer(i64),
    Real(f64),
    Text(String),
    Blob(Vec<u8>),
}

fn failure(error: impl std::fmt::Display) -> TwonlyError {
    TwonlyError::Generic(format!("Logical backup: {error}"))
}

fn quote(name: &str) -> String {
    format!("\"{}\"", name.replace('"', "\"\""))
}

pub(crate) async fn export(pool: &SqlitePool, operation: &Operation) -> Result<Zeroizing<Vec<u8>>> {
    let mut connection = pool.acquire().await?;
    crate::database::snapshot::watch(&mut connection, operation).await?;

    let mut dump = Dump {
        user_version: sqlx::query_scalar("PRAGMA user_version")
            .fetch_one(&mut *connection)
            .await?,
        application_id: sqlx::query_scalar("PRAGMA application_id")
            .fetch_one(&mut *connection)
            .await?,
        schema: Vec::new(),
        tables: Vec::new(),
    };
    for row in sqlx::query("SELECT type, sql FROM sqlite_schema WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%' ORDER BY rowid")
        .fetch_all(&mut *connection).await? {
        dump.schema.push(Schema { kind: row.try_get("type")?, sql: row.try_get("sql")? });
    }

    let tables: Vec<String> = sqlx::query_scalar("SELECT name FROM sqlite_schema WHERE type = 'table' AND (name NOT LIKE 'sqlite_%' OR name = 'sqlite_sequence') ORDER BY name")
        .fetch_all(&mut *connection).await?;
    for name in tables {
        operation.check()?;
        let columns = sqlx::query("SELECT name, hidden FROM pragma_table_xinfo(?) ORDER BY cid")
            .bind(&name)
            .fetch_all(&mut *connection)
            .await?;
        let all_names: Vec<String> = columns.iter().map(|row| row.get("name")).collect();
        let mut columns: Vec<String> = columns
            .iter()
            .filter(|row| row.get::<i64, _>("hidden") == 0)
            .map(|row| row.get("name"))
            .collect();
        let without_rowid: i64 = sqlx::query_scalar(
            "SELECT wr FROM pragma_table_list WHERE schema = 'main' AND name = ?",
        )
        .bind(&name)
        .fetch_one(&mut *connection)
        .await?;
        if without_rowid == 0 {
            // Preserve rowids used by chat views, even after deletions left gaps.
            let alias = ["rowid", "_rowid_", "oid"]
                .into_iter()
                .find(|alias| {
                    !all_names
                        .iter()
                        .any(|name| name.eq_ignore_ascii_case(alias))
                })
                .ok_or_else(|| failure("all rowid aliases are shadowed"))?;
            columns.insert(0, alias.to_owned());
        }
        let select = format!(
            "SELECT {} FROM {}",
            columns
                .iter()
                .map(|name| quote(name))
                .collect::<Vec<_>>()
                .join(","),
            quote(&name)
        );
        let mut table = Table {
            name,
            columns,
            rows: Vec::new(),
        };
        let mut rows = sqlx::query(AssertSqlSafe(select)).fetch(&mut *connection);
        while let Some(row) = rows.try_next().await? {
            operation.check()?;
            let mut values = Vec::with_capacity(table.columns.len());
            for index in 0..table.columns.len() {
                let raw = row.try_get_raw(index)?;
                values.push(if raw.is_null() {
                    Value::Null
                } else {
                    match raw.type_info().name() {
                        "INTEGER" => Value::Integer(row.try_get_unchecked(index)?),
                        "REAL" => Value::Real(row.try_get_unchecked(index)?),
                        "TEXT" => Value::Text(row.try_get_unchecked(index)?),
                        "BLOB" => Value::Blob(row.try_get_unchecked(index)?),
                        kind => return Err(failure(format!("unsupported value type {kind}"))),
                    }
                });
            }
            table.rows.push(values);
        }
        dump.tables.push(table);
    }
    operation.check()?;
    Ok(Zeroizing::new(
        postcard::to_allocvec(&dump).map_err(failure)?,
    ))
}

pub(crate) async fn import(pool: &SqlitePool, bytes: &[u8], operation: &Operation) -> Result<()> {
    operation.check()?;
    let dump: Dump = postcard::from_bytes(bytes).map_err(failure)?;
    let mut connection = pool.acquire().await?;
    crate::database::snapshot::watch(&mut connection, operation).await?;
    // Data comes before triggers and explicit indexes. Foreign keys can point
    // forward to another table; validate the complete graph before committing.
    sqlx::query("PRAGMA foreign_keys = OFF")
        .execute(&mut *connection)
        .await?;
    let result = async {
        let mut transaction = connection.begin().await?;
        for schema in dump.schema.iter().filter(|schema| schema.kind == "table") {
            operation.check()?;
            sqlx::raw_sql(AssertSqlSafe(schema.sql.as_str()))
                .execute(&mut *transaction)
                .await?;
        }
        for table in &dump.tables {
            operation.check()?;
            if table.name == "sqlite_sequence" {
                sqlx::query("DELETE FROM sqlite_sequence")
                    .execute(&mut *transaction)
                    .await?;
            }
            let insert = format!(
                "INSERT INTO {} ({}) VALUES ({})",
                quote(&table.name),
                table
                    .columns
                    .iter()
                    .map(|name| quote(name))
                    .collect::<Vec<_>>()
                    .join(","),
                vec!["?"; table.columns.len()].join(",")
            );
            for row in &table.rows {
                operation.check()?;
                if row.len() != table.columns.len() {
                    return Err(failure("row width does not match schema"));
                }
                let mut query = sqlx::query(AssertSqlSafe(insert.as_str()));
                for value in row {
                    query = match value {
                        Value::Null => query.bind(Option::<i64>::None),
                        Value::Integer(value) => query.bind(*value),
                        Value::Real(value) => query.bind(*value),
                        Value::Text(value) => query.bind(value),
                        Value::Blob(value) => query.bind(value),
                    };
                }
                query.execute(&mut *transaction).await?;
            }
        }
        for kind in ["index", "view", "trigger"] {
            for schema in dump.schema.iter().filter(|schema| schema.kind == kind) {
                operation.check()?;
                sqlx::raw_sql(AssertSqlSafe(schema.sql.as_str()))
                    .execute(&mut *transaction)
                    .await?;
            }
        }
        for (pragma, value) in [
            ("user_version", dump.user_version),
            ("application_id", dump.application_id),
        ] {
            sqlx::query(AssertSqlSafe(format!("PRAGMA {pragma} = {value}")))
                .execute(&mut *transaction)
                .await?;
        }
        if !sqlx::query("PRAGMA foreign_key_check")
            .fetch_all(&mut *transaction)
            .await?
            .is_empty()
        {
            return Err(failure("foreign key validation failed"));
        }
        transaction.commit().await?;
        Ok(())
    }
    .await;
    // Close rather than return a connection with foreign_keys disabled.
    let closed = connection.close().await;
    result?;
    closed?;
    Ok(())
}
