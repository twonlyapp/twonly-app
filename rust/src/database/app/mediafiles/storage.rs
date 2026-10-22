//! File checks stay next to native queries so complete media records do not
//! cross the bridge just to return a count or a byte total.

use super::table::MediaStorageStat;
use crate::error::{Result, TwonlyError};
use sqlx::SqliteConnection;
use std::collections::{BTreeMap, HashSet};
use std::path::PathBuf;

fn filename(id: &str, kind: &str) -> String {
    let extension = match kind {
        "image" => "webp",
        "video" => "mp4",
        "gif" => "gif",
        "audio" => "m4a",
        _ => "",
    };

    format!("{id}.{extension}")
}

pub async fn stats(
    connection: &mut SqliteConnection, directory: PathBuf,
) -> Result<Vec<MediaStorageStat>> {
    let rows = sqlx::query!("SELECT media_id, type, size_in_bytes FROM media_files")
        .fetch_all(connection)
        .await?;

    crate::database::lifecycle::spawn_blocking(move || {
        let existing: HashSet<_> = match std::fs::read_dir(&directory) {
            Ok(entries) => entries
                .filter_map(|entry| entry.ok())
                .filter(|entry| entry.path().is_file())
                .map(|entry| entry.file_name().to_string_lossy().into_owned())
                .collect(),
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => HashSet::new(),
            Err(error) => return Err(error.into()),
        };

        let mut totals = BTreeMap::new();

        for row in rows {
            let (id, kind, bytes) = (row.media_id, row.r#type, row.size_in_bytes);

            if existing.contains(&filename(&id, &kind)) {
                *totals.entry(kind).or_insert(0) += bytes.unwrap_or(0);
            }
        }

        Ok(totals
            .into_iter()
            .map(|(media_type, bytes)| MediaStorageStat { media_type, bytes })
            .collect())
    })
    .await
    .map_err(|error| TwonlyError::Generic(error.to_string()))?
}

pub async fn cloud_only_count(
    connection: &mut SqliteConnection, directory: PathBuf,
) -> Result<i64> {
    let rows = sqlx::query!(
        "SELECT media_id, type FROM media_files WHERE stored = 1 AND cloud_state = 'uploaded'",
    )
    .fetch_all(connection)
    .await?;

    crate::database::lifecycle::spawn_blocking(move || {
        rows.into_iter()
            .filter(|row| {
                std::fs::metadata(directory.join(filename(&row.media_id, &row.r#type)))
                    .map(|metadata| metadata.len() == 0)
                    .unwrap_or(true)
            })
            .count() as i64
    })
    .await
    .map_err(|error| TwonlyError::Generic(error.to_string()))
}

/// Called after the server disables cloud storage. A missing local original
/// removes its row, while file cleanup is queued in the same transaction.

pub async fn finish_backup_disable(
    tx: &mut sqlx::Transaction<'_, sqlx::Sqlite>, directory: PathBuf,
) -> Result<i64> {
    let rows = sqlx::query!("SELECT media_id, type FROM media_files WHERE stored = 1")
        .fetch_all(&mut **tx)
        .await?;

    let missing =
        crate::database::lifecycle::spawn_blocking(move || -> Result<Vec<(String, String)>> {
            let mut missing = Vec::new();

            for row in rows {
                let (id, kind) = (row.media_id, row.r#type);

                // Permission/storage failures are errors, never evidence of deletion.
                if !directory.join(filename(&id, &kind)).try_exists()? {
                    missing.push((id, kind));
                }
            }

            Ok(missing)
        })
        .await
        .map_err(|error| TwonlyError::Generic(error.to_string()))??;

    let count = missing.len() as i64;

    for (id, kind) in missing {
        sqlx::query!(
            r#"
                INSERT INTO pending_media_file_removals(media_id, media_type)
                VALUES (?, ?)
                ON CONFLICT(media_id) DO UPDATE SET media_type = excluded.media_type
            "#,
            &id,
            kind,
        )
        .execute(&mut **tx)
        .await?;

        sqlx::query!(
            r#"
                DELETE FROM media_files WHERE media_id = ?
            "#,
            id,
        )
        .execute(&mut **tx)
        .await?;
    }

    sqlx::query!(
        r#"
            UPDATE media_files SET cloud_state = 'none'
        "#,
    )
    .execute(&mut **tx)
    .await?;

    Ok(count)
}
