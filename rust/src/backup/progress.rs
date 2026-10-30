//! Process-wide progress shared by manual and native scheduled uploads.

use crate::error::Result;
use crate::frb_generated::StreamSink;
use std::sync::LazyLock;
use tokio::sync::watch;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum BackupStage {
    Idle,
    Preparing,
    Snapshotting,
    Exporting,
    Compressing,
    Encrypting,
    UploadingIdentity,
    UploadingArchive,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct BackupProgress {
    pub stage: BackupStage,
    pub completed_bytes: i64,
    pub total_bytes: i64,
}

static PROGRESS: LazyLock<watch::Sender<BackupProgress>> = LazyLock::new(|| {
    watch::channel(BackupProgress {
        stage: BackupStage::Idle,
        completed_bytes: 0,
        total_bytes: 0,
    })
    .0
});

pub(crate) fn stage(stage: BackupStage) {
    bytes(stage, 0, 0);
}

pub(crate) fn bytes(stage: BackupStage, completed_bytes: u64, total_bytes: u64) {
    PROGRESS.send_replace(BackupProgress {
        stage,
        completed_bytes: i64::try_from(completed_bytes).unwrap_or(i64::MAX),
        total_bytes: i64::try_from(total_bytes).unwrap_or(i64::MAX),
    });
}

/// Drop also covers cancellation while a request is waiting for the server.
pub(crate) struct UploadGuard;

impl UploadGuard {
    pub(crate) fn new() -> Self {
        stage(BackupStage::Preparing);
        Self
    }
}

impl Drop for UploadGuard {
    fn drop(&mut self) {
        stage(BackupStage::Idle);
    }
}

pub(crate) async fn stream(sink: StreamSink<BackupProgress>) -> Result<()> {
    let mut receiver = PROGRESS.subscribe();
    let current = *receiver.borrow_and_update();
    if sink.add(current).is_err() {
        return Ok(());
    }
    tokio::spawn(async move {
        while receiver.changed().await.is_ok() {
            let progress = *receiver.borrow_and_update();
            if sink.add(progress).is_err() {
                break;
            }
        }
    });
    Ok(())
}
