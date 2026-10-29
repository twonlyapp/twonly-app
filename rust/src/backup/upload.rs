//! Backup policy and uploads shared by the settings action and OS schedulers.

use super::backup_archive::BackupArchive;
use super::backup_identity::BackupIdentity;
use crate::bridge::api::RustApi;
use crate::context::Context;
use crate::database::lifecycle::Operation;
use crate::error::{Result, TwonlyError};
use crate::user_config::UserConfig;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::path::Path;
use std::sync::Arc;
use std::time::Duration;

static UPLOADS: tokio::sync::Mutex<()> = tokio::sync::Mutex::const_new(());

#[derive(Clone, Copy, Default, PartialEq, Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
enum UploadState {
    #[default]
    None,
    Pending,
    Failed,
    Success,
}

/// Keep the historical Dart JSON format so existing backups/settings migrate
/// without resetting their last successful upload timestamps.
#[derive(Default, Debug, Serialize, Deserialize)]
#[serde(default, rename_all = "camelCase")]
struct Status {
    identity_state: UploadState,
    #[serde(deserialize_with = "read_timestamp")]
    identity_last_success_full: Option<DateTime<Utc>>,
    identity_size: Option<u64>,
    archive_state: UploadState,
    #[serde(deserialize_with = "read_timestamp")]
    archive_last_success_full: Option<DateTime<Utc>>,
    archive_size: Option<u64>,
}

fn read_timestamp<'de, D: serde::Deserializer<'de>>(
    deserializer: D,
) -> std::result::Result<Option<DateTime<Utc>>, D::Error> {
    use chrono::TimeZone;
    let value = Option::<String>::deserialize(deserializer)?;
    value
        .map(|value| {
            DateTime::parse_from_rfc3339(&value)
                .map(|date| date.with_timezone(&Utc))
                .or_else(|_| {
                    chrono::NaiveDateTime::parse_from_str(&value, "%Y-%m-%dT%H:%M:%S%.f").map(
                        |date| {
                            chrono::Local
                                .from_local_datetime(&date)
                                .earliest()
                                .map(|date| date.with_timezone(&Utc))
                                .unwrap_or_else(|| date.and_utc())
                        },
                    )
                })
                .map_err(serde::de::Error::custom)
        })
        .transpose()
}

fn due(state: UploadState, last: Option<DateTime<Utc>>, days: i64, now: DateTime<Utc>) -> bool {
    state != UploadState::Success
        || last.is_none_or(|last| last < now - chrono::Duration::days(days))
}

fn status_path(ctx: &Context) -> std::path::PathBuf {
    Path::new(&ctx.config.data_dir).join("keyvalue/current_backup_state.json")
}

fn load_status(ctx: &Context) -> Result<Status> {
    match std::fs::read(status_path(ctx)) {
        Ok(bytes) => match serde_json::from_slice(&bytes) {
            Ok(status) => Ok(status),
            Err(error) => {
                tracing::warn!(%error, "invalid backup status; retrying both uploads");
                Ok(Status::default())
            }
        },
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(Status::default()),
        Err(error) => Err(error.into()),
    }
}

fn save_status(ctx: &Context, status: &Status) -> Result<()> {
    let path = status_path(ctx);
    std::fs::create_dir_all(path.parent().unwrap())?;
    let pending = path.with_extension("json.pending");
    let mut file = std::fs::File::create(&pending)?;
    serde_json::to_writer(&mut file, status)?;
    file.sync_all()?;
    std::fs::rename(pending, path)?;
    Ok(())
}

pub(crate) async fn run(ctx: &Arc<Context>, force: bool, operation: &Operation) -> Result<bool> {
    let client = crate::api::http::client_builder()
        .timeout(Duration::from_secs(10 * 60))
        .build()
        .map_err(|error| TwonlyError::Generic(error.to_string()))?;
    run_with_client(
        ctx,
        force,
        operation,
        &client,
        &RustApi::api_base_url("https".into()),
    )
    .await
}

async fn run_with_client(
    ctx: &Arc<Context>, force: bool, operation: &Operation, client: &reqwest::Client,
    base_url: &str,
) -> Result<bool> {
    tokio::select! {
        biased;
        _ = operation.until_cancelled() => operation.check().map(|_| false),
        result = upload(ctx, force, operation, client, base_url) => result,
    }
}

async fn upload(
    ctx: &Arc<Context>, force: bool, operation: &Operation, client: &reqwest::Client,
    base_url: &str,
) -> Result<bool> {
    let _uploads = UPLOADS.lock().await;
    operation.check()?;
    let Some(user) = UserConfig::load_from(ctx)? else {
        return Ok(true);
    };
    if !user.is_backup_enabled {
        return Ok(true);
    }
    if Path::new(&ctx.config.data_dir)
        .join("keyvalue/backup_recovery_state.json")
        .try_exists()?
    {
        return Ok(false);
    }
    let mut status = load_status(ctx)?;
    let now = Utc::now();
    let mut successful = true;

    let identity_due = force
        || due(
            status.identity_state,
            status.identity_last_success_full,
            7,
            now,
        );

    let archive_due = force
        || due(
            status.archive_state,
            status.archive_last_success_full,
            1,
            now,
        );

    if identity_due {
        let identity = {
            let keys = ctx.key_manager.lock().await;
            keys.backup_password
                .as_ref()
                .map(|password| {
                    Ok::<_, TwonlyError>((
                        hex::encode(password.backup_id),
                        BackupIdentity::encrypt_key_manager(&keys)?,
                    ))
                })
                .transpose()
        };
        match identity {
            Ok(Some((id, bytes))) => {
                status.identity_state = UploadState::Pending;
                status.identity_size = Some(bytes.len() as u64);
                save_status(ctx, &status)?;
                let started = std::time::Instant::now();
                let result = client
                    .put(format!("{base_url}backup/identity/{id}"))
                    .header("Content-Type", "application/octet-stream")
                    .body(bytes)
                    .send()
                    .await;
                if accepted(result, "identity") {
                    tracing::info!(
                        bytes = status.identity_size,
                        upload_ms = started.elapsed().as_millis() as u64,
                        "identity backup uploaded"
                    );
                    status.identity_state = UploadState::Success;
                    status.identity_last_success_full = Some(Utc::now());
                } else {
                    status.identity_state = UploadState::Failed;
                    successful = false;
                }
            }
            Ok(None) => {
                tracing::warn!("backup password is unavailable; retaining backup for retry");
                status.identity_state = UploadState::Failed;
                successful = false;
            }
            Err(error) => {
                tracing::warn!(%error, "could not encrypt identity backup");
                status.identity_state = UploadState::Failed;
                successful = false;
            }
        }
        save_status(ctx, &status)?;
    }

    if archive_due {
        operation.check()?;
        let started = std::time::Instant::now();
        let mut create_ms = 0_u64;
        let result = async {
            let headers = crate::api::http::authentication_headers(ctx).await?;
            let (token, archive) =
                BackupArchive::create_backup_with_operation(ctx, operation.clone()).await?;
            create_ms = started.elapsed().as_millis() as u64;
            let bytes = std::fs::read(archive)?;
            status.archive_state = UploadState::Pending;
            status.archive_size = Some(bytes.len() as u64);
            save_status(ctx, &status)?;
            // Preserve the server's multipart `file` contract without adding a
            // second HTTP stack or requiring a Flutter engine for the upload.
            let boundary = format!("twonly-{}", uuid::Uuid::new_v4());
            let mut body = format!(
                "--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; \
                 filename=\"archive.bin\"\r\nContent-Type: application/octet-stream\r\n\r\n"
            )
            .into_bytes();
            body.extend_from_slice(&bytes);
            body.extend_from_slice(format!("\r\n--{boundary}--\r\n").as_bytes());
            let mut request = client
                .post(format!("{base_url}backup/archive/{token}"))
                .header(
                    "Content-Type",
                    format!("multipart/form-data; boundary={boundary}"),
                );
            for (name, value) in headers {
                request = request.header(name, value);
            }
            Ok::<_, TwonlyError>(accepted(request.body(body).send().await, "archive"))
        }
        .await;
        match result {
            Ok(true) => {
                tracing::info!(
                    bytes = status.archive_size,
                    create_ms,
                    upload_ms = (started.elapsed().as_millis() as u64).saturating_sub(create_ms),
                    "archive backup uploaded"
                );
                status.archive_state = UploadState::Success;
                status.archive_last_success_full = Some(Utc::now());
            }
            Ok(false) => {
                status.archive_state = UploadState::Failed;
                successful = false;
            }
            Err(error) => {
                tracing::warn!(%error, "could not create/upload archive backup");
                status.archive_state = UploadState::Failed;
                successful = false;
            }
        }
        save_status(ctx, &status)?;
    }
    // One line per run, so a log shows that a backup ran even when nothing was
    // due, which a log of failures alone cannot tell apart from no run at all.
    tracing::info!(identity_due, archive_due, successful, "backup run finished");
    Ok(successful)
}

fn accepted(result: std::result::Result<reqwest::Response, reqwest::Error>, kind: &str) -> bool {
    match result {
        Ok(response) if response.status().is_success() => true,
        Ok(response) => {
            tracing::warn!(%kind, status = %response.status(), "backup upload rejected");
            false
        }
        Err(error) => {
            tracing::warn!(%kind, %error, "backup upload failed; will retry");
            false
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::{BufRead, BufReader, Read, Write};

    async fn context() -> (tempfile::TempDir, Arc<Context>) {
        let directory = tempfile::tempdir().unwrap();
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await
                .unwrap();
        std::fs::create_dir_all(Path::new(&ctx.config.data_dir).join("keyvalue")).unwrap();
        UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"backup","displayName":"Backup","isBackupEnabled":true}"#,
        )
        .unwrap();
        ctx.key_manager.lock().await.backup_password =
            Some(crate::keys::BackupPasswordKeys::new([1; 32], [2; 32]));
        (directory, ctx)
    }

    fn successful() -> Status {
        Status {
            identity_state: UploadState::Success,
            identity_last_success_full: Some(Utc::now()),
            archive_state: UploadState::Success,
            archive_last_success_full: Some(Utc::now()),
            ..Status::default()
        }
    }

    async fn attempt(ctx: &Arc<Context>, force: bool, url: &str) -> Result<bool> {
        let operation = Operation::new(Duration::from_secs(10));
        let client = crate::api::http::client_builder().build().unwrap();
        let result = operation
            .scope(run_with_client(ctx, force, &operation, &client, url))
            .await;
        operation.cancel();
        operation.drain().await;
        result
    }

    fn server(status: u16) -> (String, std::thread::JoinHandle<(String, Vec<u8>)>) {
        let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
        let url = format!("http://{}/", listener.local_addr().unwrap());
        let worker = std::thread::spawn(move || {
            let (socket, _) = listener.accept().unwrap();
            socket
                .set_read_timeout(Some(Duration::from_secs(10)))
                .unwrap();
            let mut stream = BufReader::new(socket);
            let mut headers = String::new();
            let mut length = 0;
            loop {
                let mut line = String::new();
                assert_ne!(stream.read_line(&mut line).unwrap(), 0);
                if line == "\r\n" {
                    break;
                }
                if let Some(value) = line.to_ascii_lowercase().strip_prefix("content-length: ") {
                    length = value.trim().parse().unwrap();
                }
                headers.push_str(&line);
            }
            let mut body = vec![0; length];
            stream.read_exact(&mut body).unwrap();
            write!(
                stream.get_mut(),
                "HTTP/1.1 {status} Result\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
            )
            .unwrap();
            (headers, body)
        });
        (url, worker)
    }

    #[test]
    fn due_dates_and_legacy_dart_timestamps_are_preserved() {
        let now = Utc::now();
        assert!(!due(
            UploadState::Success,
            Some(now - chrono::Duration::hours(23)),
            1,
            now
        ));
        assert!(due(
            UploadState::Success,
            Some(now - chrono::Duration::days(2)),
            1,
            now
        ));
        assert!(!due(
            UploadState::Success,
            Some(now - chrono::Duration::days(6)),
            7,
            now
        ));
        assert!(due(UploadState::Failed, Some(now), 7, now));
        assert!(due(UploadState::Pending, Some(now), 1, now));
        let status: Status = serde_json::from_str(r#"{"identityState":"success","identityLastSuccessFull":"2026-10-20T12:00:00.123456","archiveLastSuccessFull":"2026-10-20T12:00:00.000Z"}"#).unwrap();
        assert!(status.identity_last_success_full.is_some());
        assert!(status.archive_last_success_full.is_some());
        let json = serde_json::to_value(status).unwrap();
        assert_eq!(json["identityState"], "success");
        assert!(json["identityLastSuccessFull"]
            .as_str()
            .unwrap()
            .ends_with('Z'));
    }

    #[tokio::test]
    async fn disabled_recovering_and_current_backups_do_not_upload() {
        let (_directory, ctx) = context().await;
        save_status(&ctx, &successful()).unwrap();
        assert!(attempt(&ctx, false, "http://127.0.0.1:1/").await.unwrap());
        let recovery = Path::new(&ctx.config.data_dir).join("keyvalue/backup_recovery_state.json");
        std::fs::write(&recovery, "{}").unwrap();
        assert!(!attempt(&ctx, true, "http://127.0.0.1:1/").await.unwrap());
        std::fs::remove_file(recovery).unwrap();
        UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"backup","displayName":"Backup","isBackupEnabled":false}"#,
        )
        .unwrap();
        assert!(attempt(&ctx, true, "http://127.0.0.1:1/").await.unwrap());
    }

    #[tokio::test]
    async fn identity_upload_is_encrypted_and_keeps_the_archive_timestamp() {
        let (_directory, ctx) = context().await;
        let mut status = successful();
        status.identity_last_success_full = Some(Utc::now() - chrono::Duration::days(8));
        let archive_date = status.archive_last_success_full;
        save_status(&ctx, &status).unwrap();
        let (url, worker) = server(200);
        assert!(attempt(&ctx, false, &url).await.unwrap());
        let (headers, body) = worker.join().unwrap();
        assert!(headers.starts_with(&format!(
            "PUT /backup/identity/{} HTTP/1.1",
            hex::encode([1; 32])
        )));
        let keys = ctx.key_manager.lock().await;
        BackupIdentity::decrypt_key_manager(keys.backup_password.as_ref().unwrap(), &body).unwrap();
        let status = load_status(&ctx).unwrap();
        assert_eq!(status.identity_state, UploadState::Success);
        assert_eq!(status.archive_last_success_full, archive_date);
    }

    #[tokio::test]
    async fn rejected_and_offline_uploads_retain_success_dates_and_retry() {
        let (_directory, ctx) = context().await;
        let mut status = successful();
        status.identity_state = UploadState::Failed;
        let last_success = status.identity_last_success_full;
        save_status(&ctx, &status).unwrap();
        assert!(!attempt(&ctx, false, "http://127.0.0.1:1/").await.unwrap());
        let (url, worker) = server(503);
        assert!(!attempt(&ctx, false, &url).await.unwrap());
        worker.join().unwrap();
        let status = load_status(&ctx).unwrap();
        assert_eq!(status.identity_state, UploadState::Failed);
        assert_eq!(status.identity_last_success_full, last_success);
        let (url, worker) = server(200);
        assert!(attempt(&ctx, false, &url).await.unwrap());
        worker.join().unwrap();
        assert_eq!(
            load_status(&ctx).unwrap().identity_state,
            UploadState::Success
        );
    }

    #[tokio::test]
    async fn archive_upload_uses_multipart_and_account_authentication() {
        let (_directory, ctx) = context().await;
        let mut status = successful();
        status.archive_state = UploadState::Failed;
        let identity_date = status.identity_last_success_full;
        save_status(&ctx, &status).unwrap();
        let (url, worker) = server(200);
        assert!(attempt(&ctx, false, &url).await.unwrap());
        let (headers, body) = worker.join().unwrap();
        assert!(headers.starts_with("POST /backup/archive/"));
        assert!(headers.contains("x-twonly-user-id: 000000000000002A"));
        assert!(headers.contains("x-twonly-login-token: "));
        assert!(headers.contains("multipart/form-data; boundary="));
        let prefix = body
            .windows(4)
            .position(|part| part == b"\r\n\r\n")
            .unwrap()
            + 4;
        let suffix = body.windows(4).rposition(|part| part == b"\r\n--").unwrap();
        let keys = ctx.key_manager.lock().await;
        let decrypted = keys.main_key.decrypt_backup(&body[prefix..suffix]).unwrap();
        let archive = zip::ZipArchive::new(std::io::Cursor::new(decrypted)).unwrap();
        assert!(archive
            .file_names()
            .any(|name| name.is_ok_and(|name| name == "backup-manifest.json")));
        let status = load_status(&ctx).unwrap();
        assert_eq!(status.archive_state, UploadState::Success);
        assert_eq!(status.identity_last_success_full, identity_date);
    }

    #[tokio::test]
    async fn simultaneous_scheduled_requests_upload_only_once() {
        let (_directory, ctx) = context().await;
        let mut status = successful();
        status.identity_state = UploadState::Failed;
        save_status(&ctx, &status).unwrap();
        let (url, worker) = server(200);
        let (first, second) = tokio::join!(attempt(&ctx, false, &url), attempt(&ctx, false, &url));
        assert!(first.unwrap());
        assert!(second.unwrap());
        worker.join().unwrap();
    }

    #[tokio::test]
    async fn cancellation_during_upload_retains_pending_status_for_retry() {
        let (_directory, ctx) = context().await;
        let mut status = successful();
        status.identity_state = UploadState::Failed;
        let last_success = status.identity_last_success_full;
        save_status(&ctx, &status).unwrap();
        let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
        let url = format!("http://{}/", listener.local_addr().unwrap());
        let operation = Operation::new(Duration::from_secs(10));
        let cancelled = operation.clone();
        let worker = std::thread::spawn(move || {
            let (mut socket, _) = listener.accept().unwrap();
            socket
                .set_read_timeout(Some(Duration::from_secs(5)))
                .unwrap();
            let mut buffer = [0; 4096];
            assert!(socket.read(&mut buffer).unwrap() > 0);
            cancelled.cancel();
            std::thread::sleep(Duration::from_millis(100));
            let _ = socket.write_all(b"HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n");
        });
        let client = crate::api::http::client_builder().build().unwrap();
        assert!(operation
            .scope(run_with_client(&ctx, false, &operation, &client, &url))
            .await
            .is_err());
        operation.drain().await;
        worker.join().unwrap();
        let status = load_status(&ctx).unwrap();
        assert_eq!(status.identity_state, UploadState::Pending);
        assert_eq!(status.identity_last_success_full, last_success);
    }

    #[tokio::test]
    async fn cancelled_operation_never_starts_an_upload() {
        let (_directory, ctx) = context().await;
        let operation = Operation::new(Duration::from_secs(1));
        operation.cancel();
        assert!(operation.scope(run(&ctx, true, &operation)).await.is_err());
        assert!(!status_path(&ctx).exists());
    }
}
