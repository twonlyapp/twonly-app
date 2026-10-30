//! Tests for the production v3 writer. The existing v1/v2 regression tests
//! remain unchanged and continue exercising their historical archive format.

use super::*;
use sqlx::Executor;

async fn context() -> (tempfile::TempDir, Arc<Context>) {
    let directory = tempfile::tempdir().unwrap();
    let ctx = Context::init_for_testing(
        directory.path().join("database"),
        directory.path().join("data"),
    )
    .await
    .unwrap();
    (directory, ctx)
}

async fn close(ctx: &Arc<Context>) {
    crate::api::runtime::ApiRuntime::close(ctx).await.unwrap();
    ctx.app_db.read().await.close().await;
    ctx.rust_db.read().await.pool.close().await;
}

async fn decrypt(ctx: &Context, path: &Path) -> Vec<u8> {
    ctx.key_manager
        .lock()
        .await
        .main_key
        .decrypt_backup(&std::fs::read(path).unwrap())
        .unwrap()
}

#[tokio::test]
async fn production_backup_compresses_rows_rebuilds_indexes_and_preserves_database_semantics() {
    let (directory, ctx) = context().await;
    let app = ctx.app_db.read().await.clone();
    app.pool.execute(
        "CREATE TABLE backup_types (id INTEGER PRIMARY KEY AUTOINCREMENT, rowid TEXT, payload TEXT NOT NULL, binary BLOB, number REAL, optional TEXT, computed INTEGER GENERATED ALWAYS AS (length(payload)) STORED);
         CREATE INDEX backup_large_index ON backup_types(payload);
         CREATE UNIQUE INDEX backup_partial_index ON backup_types(rowid) WHERE optional IS NOT NULL;
         CREATE TABLE backup_audit (message TEXT);
         CREATE TRIGGER backup_insert AFTER INSERT ON backup_types BEGIN INSERT INTO backup_audit VALUES ('inserted'); END;
         CREATE VIEW backup_view AS SELECT id, computed FROM backup_types;
         INSERT INTO backup_types(id, rowid, payload, binary, number) VALUES (1, 'first', 'hello', x'0001ff', 1.25), (4, 'fourth', 'world', x'', NULL), (900, 'deleted', 'gone', NULL, NULL);
         DELETE FROM backup_types WHERE id = 900;
         CREATE TABLE backup_without_rowid (a TEXT, b INTEGER, payload BLOB, PRIMARY KEY(a,b)) WITHOUT ROWID;
         INSERT INTO backup_without_rowid VALUES ('key', 9223372036854775807, x'00ff');"
    ).await.unwrap();
    // Embedded NUL and non-ASCII text must survive; SQL quote()/text dumps
    // would truncate the NUL-containing value.
    sqlx::query("UPDATE backup_types SET optional = ? WHERE id = 1")
        .bind("before\0after 😀")
        .execute(&app.pool)
        .await
        .unwrap();
    let payload = "repeated backup content ".repeat(200);
    for id in 1000..1200 {
        sqlx::query("INSERT INTO backup_types(id, payload) VALUES (?, ?)")
            .bind(id)
            .bind(&payload)
            .execute(&app.pool)
            .await
            .unwrap();
    }
    // Preserve the high-water mark even though its last row was deleted.
    app.pool.execute("INSERT INTO backup_types(id, payload) VALUES (9000, 'deleted'); DELETE FROM backup_types WHERE id = 9000;").await.unwrap();
    let schema_before: Vec<(String, String, Option<String>)> =
        sqlx::query_as("SELECT type, name, sql FROM sqlite_schema ORDER BY type, name")
            .fetch_all(&app.pool)
            .await
            .unwrap();
    let audit_before: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM backup_audit")
        .fetch_one(&app.pool)
        .await
        .unwrap();
    let live = ctx.rust_db.read().await.clone();
    live.pool.execute("INSERT INTO signal_sessions VALUES ('peer', 1, zeroblob(262144)); INSERT INTO signal_pre_keys VALUES (1, x'010203'); INSERT INTO signal_identities VALUES ('peer', x'040506', 1);").await.unwrap();

    let legacy_path = BackupArchive::create_backup(&ctx).await.unwrap();
    let legacy_size = legacy_path.metadata().unwrap().len();
    let (_, path) = BackupArchive::create_backup_with_token(&ctx).await.unwrap();
    let encrypted = std::fs::read(&path).unwrap();
    assert!(!encrypted.starts_with(b"PK"));
    eprintln!(
        "Indexed fixture backup: {legacy_size} bytes (v2) -> {} bytes (v3)",
        encrypted.len()
    );
    assert!((encrypted.len() as u64) < legacy_size / 5);
    let source_size = directory
        .path()
        .join("database/app_db.sqlite")
        .metadata()
        .unwrap()
        .len();
    assert!(
        (encrypted.len() as u64) < source_size / 5,
        "compressible indexed source: {source_size}, encrypted archive: {}",
        encrypted.len()
    );
    let decrypted = decrypt(&ctx, &path).await;
    let mut archive = ZipArchive::new(Cursor::new(decrypted)).unwrap();
    assert!(archive.by_name("app_db.sqlite").is_err());
    assert!(archive.by_name("rust_db.sqlite").is_err());
    assert!(archive.by_name("app_db.dump").unwrap().size() > 0);
    assert!(archive.by_name("rust_db.dump").unwrap().size() > 0);
    let manifest: BackupManifest =
        serde_json::from_reader(archive.by_name(BACKUP_MANIFEST_FILE).unwrap()).unwrap();
    assert_eq!(manifest.format_version, 3);
    assert_eq!(
        sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM signal_sessions")
            .fetch_one(&live.pool)
            .await
            .unwrap(),
        1
    );

    app.pool
        .execute("DELETE FROM backup_types; DELETE FROM backup_without_rowid;")
        .await
        .unwrap();
    BackupArchive::restore_from_backup(&ctx, &path)
        .await
        .unwrap();
    let restored = ctx.app_db.read().await.clone();
    let row = sqlx::query("SELECT id, rowid, payload, binary, number, optional, computed FROM backup_types WHERE id = 1").fetch_one(&restored.pool).await.unwrap();
    assert_eq!(row.get::<i64, _>("id"), 1);
    assert_eq!(row.get::<String, _>("rowid"), "first");
    assert_eq!(row.get::<Vec<u8>, _>("binary"), vec![0, 1, 255]);
    assert_eq!(row.get::<f64, _>("number"), 1.25);
    assert_eq!(row.get::<String, _>("optional"), "before\0after 😀");
    assert_eq!(row.get::<i64, _>("computed"), 5);
    assert_eq!(
        sqlx::query_scalar::<_, Vec<u8>>("SELECT binary FROM backup_types WHERE id = 4")
            .fetch_one(&restored.pool)
            .await
            .unwrap(),
        Vec::<u8>::new()
    );
    assert_eq!(
        sqlx::query_scalar::<_, i64>("SELECT b FROM backup_without_rowid")
            .fetch_one(&restored.pool)
            .await
            .unwrap(),
        i64::MAX
    );
    let schema_after: Vec<(String, String, Option<String>)> =
        sqlx::query_as("SELECT type, name, sql FROM sqlite_schema ORDER BY type, name")
            .fetch_all(&restored.pool)
            .await
            .unwrap();
    assert_eq!(schema_after, schema_before);
    assert_eq!(
        sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM backup_audit")
            .fetch_one(&restored.pool)
            .await
            .unwrap(),
        audit_before,
        "triggers must not fire while replaying rows"
    );
    assert!(sqlx::query("INSERT INTO backup_types(rowid,payload,optional) VALUES ('first','duplicate','present')").execute(&restored.pool).await.is_err(), "partial unique index must be rebuilt");
    let id: i64 =
        sqlx::query_scalar("INSERT INTO backup_types(payload) VALUES ('next') RETURNING id")
            .fetch_one(&restored.pool)
            .await
            .unwrap();
    assert_eq!(id, 9001);
    assert_eq!(
        sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM backup_audit")
            .fetch_one(&restored.pool)
            .await
            .unwrap(),
        audit_before + 1
    );
    let signal = ctx.rust_db.read().await.clone();
    assert_eq!(
        sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM signal_sessions")
            .fetch_one(&signal.pool)
            .await
            .unwrap(),
        0
    );
    assert_eq!(
        sqlx::query_scalar::<_, Vec<u8>>(
            "SELECT record_bytes FROM signal_pre_keys WHERE pre_key_id = 1"
        )
        .fetch_one(&signal.pool)
        .await
        .unwrap(),
        vec![1, 2, 3]
    );
    for file in ["app_db.sqlite", "rust_db.sqlite"] {
        assert!(!std::fs::read(directory.path().join("database").join(file))
            .unwrap()
            .starts_with(b"SQLite format 3\0"));
    }
    assert!(!std::fs::read_dir(directory.path().join("data"))
        .unwrap()
        .any(|entry| entry
            .unwrap()
            .file_name()
            .to_string_lossy()
            .starts_with(".backup-")));
    close(&ctx).await;
}

#[tokio::test]
async fn corrupt_logical_payload_is_rejected_before_touching_live_databases() {
    let (_directory, ctx) = context().await;
    let (_, path) = BackupArchive::create_backup_with_token(&ctx).await.unwrap();
    let mut archive = ZipArchive::new(Cursor::new(decrypt(&ctx, &path).await)).unwrap();
    let mut rebuilt = Vec::new();
    {
        let mut writer = ZipWriter::new(Cursor::new(&mut rebuilt));
        for index in 0..archive.len() {
            let mut file = archive.by_index(index).unwrap();
            let name = file.name().unwrap().into_owned();
            writer
                .start_file(
                    &name,
                    SimpleFileOptions::default().compression_method(CompressionMethod::Deflated),
                )
                .unwrap();
            if name == "app_db.dump" {
                std::io::Write::write_all(&mut writer, b"corrupt payload").unwrap();
            } else {
                copy(&mut file, &mut writer).unwrap();
            }
        }
        writer.finish().unwrap();
    }
    let bytes = ctx
        .key_manager
        .lock()
        .await
        .main_key
        .encrypt_backup(&rebuilt);
    std::fs::write(&path, bytes).unwrap();
    let app = ctx.app_db.read().await.clone();
    app.pool
        .execute("INSERT INTO app_metadata(key,value) VALUES ('preserved','yes')")
        .await
        .unwrap();
    let error = BackupArchive::restore_from_backup(&ctx, &path)
        .await
        .unwrap_err();
    assert!(error.to_string().contains("checksum"), "{error}");
    assert_eq!(
        sqlx::query_scalar::<_, String>("SELECT value FROM app_metadata WHERE key = 'preserved'")
            .fetch_one(&app.pool)
            .await
            .unwrap(),
        "yes"
    );
    close(&ctx).await;
}

#[tokio::test]
async fn failed_production_backup_preserves_previous_archive_and_removes_staging() {
    let (directory, ctx) = context().await;
    let (_, path) = BackupArchive::create_backup_with_token(&ctx).await.unwrap();
    let previous = std::fs::read(&path).unwrap();
    ctx.rust_db.read().await.pool.close().await;
    std::fs::remove_file(directory.path().join("database/rust_db.sqlite")).unwrap();
    assert!(BackupArchive::create_backup_with_token(&ctx).await.is_err());
    assert_eq!(std::fs::read(&path).unwrap(), previous);
    assert!(!std::fs::read_dir(directory.path().join("data"))
        .unwrap()
        .any(|entry| entry
            .unwrap()
            .file_name()
            .to_string_lossy()
            .starts_with(".backup-")));
    close(&ctx).await;
}
