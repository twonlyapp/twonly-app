pub mod received_messages;

#[macro_export]
macro_rules! generate_insert {
    ($table:literal, $fn_name:ident, $($field:ident : $ty:ty),+) => {
        pub async fn $fn_name(
            pool: &sqlx::SqlitePool,
            $($field: $ty),+
        ) -> crate::error::Result<i64> {
            let sql = format!(
                "INSERT INTO {} ({}) VALUES ({}) RETURNING id",
                $table,
                vec![$(stringify!($field)),+].join(", "),
                vec!["?"; [$({stringify!($field); 1}),+].len()].join(", ")
            );

            let row: (i64,) = sqlx::query_as(sqlx::AssertSqlSafe(sql))
                $(.bind($field))+
                .fetch_one(pool)
                .await?;

            Ok(row.0)
        }
    };
}

#[macro_export]
macro_rules! generate_select {
    ($table:literal, $fn_name:ident) => {
        pub async fn $fn_name(pool: &sqlx::SqlitePool) -> crate::error::Result<Vec<Self>> {
            let sql = format!("SELECT * FROM {}", $table);
            let results = sqlx::query_as::<_, Self>(sqlx::AssertSqlSafe(sql))
                .fetch_all(pool)
                .await?;
            Ok(results)
        }
    };
    ($table:literal, $fn_name:ident, $($field:ident : $ty:ty),+) => {
        pub async fn $fn_name(pool: &sqlx::SqlitePool, $($field: $ty),+) -> crate::error::Result<Vec<Self>> {
            let mut sql = format!("SELECT * FROM {} WHERE ", $table);
            let mut filters = Vec::new();
            $(
                filters.push(format!("{} = ?", stringify!($field)));
            )+
            sql.push_str(&filters.join(" AND "));

            let results = sqlx::query_as::<_, Self>(sqlx::AssertSqlSafe(sql))
                $(.bind($field))+
                .fetch_all(pool)
                .await?;
            Ok(results)
        }
    };
}

#[macro_export]
macro_rules! generate_table_tests {
    (
        $struct:ident,
        $insert_fn:ident ($($arg:expr),+),
        $select_all_fn:ident
    ) => {
        #[cfg(test)]
        mod tests {
            use super::*;
            use crate::database::Database;
            use tempfile::tempdir;

            #[tokio::test]
            async fn test_generated_basic() {
                let dir = tempdir().unwrap();
                let db_path = dir.path().join("test.sqlite").display().to_string();
                let db = Database::new(&db_path, None, false).await.unwrap();
                db.run_migrations().await.unwrap();

                let _id = $struct::$insert_fn(&db.pool, $($arg),+).await.unwrap();
                let all = $struct::$select_all_fn(&db.pool).await.unwrap();
                assert_eq!(all.len(), 1);
            }
        }
    };
}

#[macro_export]
macro_rules! generate_test_select {
    ($struct:ident, $insert_fn:ident ($($arg:expr),+), $select_fn:ident ($($sel_arg:expr),+)) => {
        paste::paste! {
            #[cfg(test)]
            #[tokio::test]
            async fn [<test_ $select_fn>]() {
                use tempfile::tempdir;
                let dir = tempdir().unwrap();
                let db_path = dir.path().join("test.sqlite").display().to_string();
                let db = crate::database::Database::new(&db_path, None, false).await.unwrap();
                db.run_migrations().await.unwrap();

                $struct::$insert_fn(&db.pool, $($arg),+).await.unwrap();
                let results = $struct::$select_fn(&db.pool, $($sel_arg),+).await.unwrap();
                assert_eq!(results.len(), 1);
            }
        }
    };
}
