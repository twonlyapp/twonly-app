/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Handing queued envelopes to an OS-owned transfer.
//!
//! A message only reaches the server over the websocket, which exists only
//! while the app is running. A message composed offline therefore waits for the
//! next app launch rather than the next network — the opposite of what a
//! messenger promises. Media already avoids this: its envelopes ride inside the
//! attachment manifest, which `WorkManager` and a background `URLSession` both
//! deliver on their own once connectivity returns.
//!
//! This gives plain messages the same route. The envelope is encrypted here,
//! written to a request file, and POSTed to `v2/messages/dispatch` by the same
//! native transfer that carries media.
//!
//! It is an accelerator, not a replacement. The receipt stays in the outbox and
//! is still retransmitted over the socket, because the outcome of an OS
//! transfer can be lost before it reaches this process - iOS does not relaunch
//! after a force quit, and `WorkManager` records its `Result` nowhere durable.
//! A recipient that receives both copies discards the second by receipt id,
//! exactly as it already does for a socket retransmission.

use crate::api::messages::incoming::messages;
use crate::api::proto::http_requests::{OutboxDispatch, OutboxDispatchBatch};
use crate::bridge::api::RustApi;
use crate::context::Context;
use crate::error::Result;
use crate::native::transfer;
use crate::utils::new_uuid_v7;
use prost::Message as _;
use serde::Serialize;
use sqlx::FromRow;
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;

/// How long the native transfer keeps retrying an envelope. Past this the
/// recipient's session has usually moved on far enough that the socket
/// retransmission — which re-encrypts — is the better copy anyway.
const DISPATCH_VALIDITY_SECONDS: i64 = 24 * 60 * 60;
/// Handing over a very large backlog at once would write one request file per
/// receipt; beyond this the socket is the more sensible route.
const MAXIMUM_HANDOVERS: usize = 20;

#[derive(FromRow)]
struct ExpiredJob {
    body_path: String,
}

/// Mirrors the single-request form of the descriptor the native uploaders read.
#[derive(Serialize)]
struct NativeRequest {
    role: String,
    url: String,
    method: String,
    headers: HashMap<String, String>,
    body_path: String,
}

#[derive(Serialize)]
struct NativeDescriptor {
    attachment_id: String,
    expires_at: i64,
    media: NativeRequest,
}

pub struct OutboxDispatchService {
    ctx: Arc<Context>,
}

impl OutboxDispatchService {
    pub fn new(ctx: &Arc<Context>) -> Self {
        Self { ctx: ctx.clone() }
    }

    fn job_dir(&self) -> PathBuf {
        PathBuf::from(&self.ctx.config.data_dir).join("outbox-dispatch")
    }

    /// Hands every receipt that has not reached the server to the OS.
    ///
    /// Called when the app is going away — backgrounded, or shutting down —
    /// which is exactly when the socket is about to stop being an option.
    pub async fn hand_pending_to_os(&self) -> Result<usize> {
        self.purge_expired().await?;

        let database = self.ctx.app_db.read().await.clone();
        let receipt_ids = sqlx::query_scalar::<_, String>(
            r#"SELECT receipt_id FROM receipts
               WHERE will_be_retried_by_media_upload = 0
                 AND deferred_until_session IS NULL
                 AND ack_by_server_at IS NULL
                 AND receipt_id NOT IN (SELECT receipt_id FROM outbox_dispatch_jobs)
                 AND (mark_for_retry_after_accepted IS NULL OR EXISTS(
                     SELECT 1 FROM contacts
                     WHERE contacts.user_id = receipts.contact_id AND contacts.accepted = 1
                 ))
               ORDER BY created_at
               LIMIT ?"#,
        )
        .bind(MAXIMUM_HANDOVERS as i64)
        .fetch_all(&database.pool)
        .await?;
        drop(database);

        let mut handed = 0;
        for receipt_id in receipt_ids {
            match self.hand_to_os(&receipt_id).await {
                Ok(true) => handed += 1,
                Ok(false) => {}
                // A peer with no session yet needs a prekey bundle from the
                // server, which is the one thing this path cannot do offline.
                Err(error) => {
                    tracing::info!(receipt_id, %error, "could not hand the envelope to the OS");
                }
            }
        }
        if handed > 0 {
            tracing::info!(handed, "handed queued envelopes to the OS transfer");
        }
        Ok(handed)
    }

    /// Encrypts one queued receipt and schedules its delivery with the OS.
    ///
    /// Returns whether anything was scheduled: a receipt that has meanwhile
    /// been sent, or one whose contact deleted their account, is not an error.
    pub async fn hand_to_os(&self, receipt_id: &str) -> Result<bool> {
        let Some(prepared) =
            messages::prepare_queued_receipt_details(&self.ctx, receipt_id).await?
        else {
            return Ok(false);
        };

        let dispatch_id = new_uuid_v7();
        let batch = OutboxDispatchBatch {
            dispatches: vec![OutboxDispatch {
                dispatch_id: dispatch_id.clone(),
                recipient_user_id: prepared.contact_id,
                encrypted_body: prepared.message.encode_to_vec(),
                wake_receiver: prepared.wake_receiver,
            }],
        };

        let directory = self.job_dir().join(&dispatch_id);
        std::fs::create_dir_all(&directory)?;
        let body_path = directory.join("dispatch.pb");
        std::fs::write(&body_path, batch.encode_to_vec())?;

        let expires_at = chrono::Utc::now().timestamp() + DISPATCH_VALIDITY_SECONDS;
        let user_id = self.ctx.user_id().await?;
        let login_token = self.ctx.key_manager.lock().await.main_key.get_login_token();
        let descriptor = NativeDescriptor {
            attachment_id: format!("outbox-{dispatch_id}"),
            expires_at,
            media: NativeRequest {
                role: "media".into(),
                url: format!(
                    "{}v2/messages/dispatch",
                    RustApi::api_base_url("https".into())
                ),
                method: "POST".into(),
                headers: HashMap::from([
                    ("content-type".into(), "application/x-protobuf".into()),
                    (
                        "x-twonly-user-id".into(),
                        hex::encode(user_id.to_be_bytes()),
                    ),
                    ("x-twonly-login-token".into(), hex::encode(login_token)),
                ]),
                body_path: body_path.to_string_lossy().into_owned(),
            },
        };

        let database = self.ctx.app_db.read().await.clone();
        // The row is written before the hand-off so a process death between the
        // two leaves a job the expiry sweep can clean up, rather than a file
        // nothing knows about.
        sqlx::query(
            r#"INSERT INTO outbox_dispatch_jobs
               (receipt_id, dispatch_id, contact_id, body_path, expires_at, created_at)
               VALUES (?, ?, ?, ?, ?, ?)"#,
        )
        .bind(receipt_id)
        .bind(&dispatch_id)
        .bind(prepared.contact_id)
        .bind(body_path.to_string_lossy().as_ref())
        .bind(expires_at)
        .bind(chrono::Utc::now().timestamp())
        .execute(&database.pool)
        .await?;
        drop(database);

        let descriptor_json = serde_json::to_string(&descriptor)?;
        if let Err(error) = transfer::schedule(&descriptor_json) {
            self.forget(receipt_id).await;
            return Err(error);
        }
        Ok(true)
    }

    /// Drops a job and its request file. The receipt is untouched: the socket
    /// path remains responsible for it either way.
    async fn forget(&self, receipt_id: &str) {
        let database = self.ctx.app_db.read().await.clone();
        let removed = sqlx::query_as::<_, ExpiredJob>(
            "DELETE FROM outbox_dispatch_jobs WHERE receipt_id = ? RETURNING body_path",
        )
        .bind(receipt_id)
        .fetch_optional(&database.pool)
        .await;
        if let Ok(Some(job)) = removed {
            Self::remove_job_files(&job.body_path);
        }
    }

    /// Clears out jobs the native transfer has given up on. Nothing reports a
    /// finished transfer back, so age is the only signal there is.
    pub async fn purge_expired(&self) -> Result<()> {
        let database = self.ctx.app_db.read().await.clone();
        let expired = sqlx::query_as::<_, ExpiredJob>(
            r#"DELETE FROM outbox_dispatch_jobs
               WHERE expires_at <= CAST(strftime('%s','now') AS INTEGER)
                  OR receipt_id NOT IN (SELECT receipt_id FROM receipts)
               RETURNING body_path"#,
        )
        .fetch_all(&database.pool)
        .await?;
        for job in expired {
            Self::remove_job_files(&job.body_path);
        }
        Ok(())
    }

    fn remove_job_files(body_path: &str) {
        let path = PathBuf::from(body_path);
        match std::fs::remove_file(&path) {
            Ok(()) => {}
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
            Err(error) => {
                tracing::warn!(path = %path.display(), %error, "could not remove a dispatch body");
            }
        }
        if let Some(parent) = path.parent() {
            let _ = std::fs::remove_dir(parent);
        }
    }
}
