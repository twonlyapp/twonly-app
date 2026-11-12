/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Progress of adding imported memories to this device.
//!
//! An importer page on a computer can upload thousands of memories. The page
//! uploads them in batches and the server announces new ones at most every 30
//! seconds; each announcement starts a pass that downloads every thumbnail
//! this device lacks, checks and decrypts it, and adds it to the gallery. The
//! app shows this as one bar at the top for the whole import, not one per
//! pass, so the gallery filling up is not a mystery.
//!
//! A pass lists what the server has, then calls [`begin`] with the number of
//! memories this device still lacks and [`advance`] once per memory it
//! handled, added or not. A pass that starts while the bar is shown adds its
//! memories to that bar. When the background task has no pass left, [`finish`]
//! leaves the bar showing what was added, as `waiting`, and hides it unless
//! another pass begins within [`LINGER_LIVE`] after an announcement (the page
//! is likely still uploading) or [`LINGER`] otherwise.

use crate::bridge::memory_importer::MemoryImportProgress;
use crate::error::Result;
use crate::frb_generated::StreamSink;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::{LazyLock, Mutex, PoisonError};
use std::time::{Duration, Instant};
use tokio::sync::watch;

/// Longer than the server's 30 second announcement debounce plus a pass, so
/// a running import keeps one bar between its batches.
const LINGER_LIVE: Duration = Duration::from_secs(45);

/// After a pass nobody announced, such as the daily check.
const LINGER: Duration = Duration::from_secs(4);

/// How long an announcement counts as a live import.
const ANNOUNCEMENT_FRESH: Duration = Duration::from_secs(90);

const IDLE: MemoryImportProgress = MemoryImportProgress {
    active: false,
    total: 0,
    done: 0,
    waiting: false,
};

static PROGRESS: LazyLock<watch::Sender<MemoryImportProgress>> =
    LazyLock::new(|| watch::channel(IDLE).0);

/// Bumped by every [`begin`] that shows memories, so a pending hide from an
/// earlier pass leaves the bar alone.
static GENERATION: AtomicU64 = AtomicU64::new(0);

static LAST_ANNOUNCEMENT: Mutex<Option<Instant>> = Mutex::new(None);

/// Set while [`preview`] owns the bar. Real passes still run meanwhile but
/// leave the bar to it.
static PREVIEW: AtomicBool = AtomicBool::new(false);

fn previewing() -> bool {
    PREVIEW.load(Ordering::Acquire)
}

/// The server announced newly imported memories: an import page is uploading.
pub(crate) fn note_announcement() {
    *LAST_ANNOUNCEMENT
        .lock()
        .unwrap_or_else(PoisonError::into_inner) = Some(Instant::now());
}

/// A pass found `missing` imported memories to add.
pub(crate) fn begin(missing: usize) {
    if !previewing() {
        publish_begin(missing);
    }
}

fn publish_begin(missing: usize) {
    let missing = i64::try_from(missing).unwrap_or(i64::MAX);
    if missing <= 0 {
        return;
    }
    GENERATION.fetch_add(1, Ordering::AcqRel);
    PROGRESS.send_if_modified(|progress| start(progress, missing));
}

/// One memory of the current pass was handled, whether it could be added or
/// not.
pub(crate) fn advance() {
    if !previewing() {
        PROGRESS.send_if_modified(step);
    }
}

/// No pass is left to run: shows what was added, then hides the bar unless
/// another pass begins meanwhile.
pub(crate) fn finish() {
    if previewing() {
        return;
    }
    let live = LAST_ANNOUNCEMENT
        .lock()
        .unwrap_or_else(PoisonError::into_inner)
        .is_some_and(|at| at.elapsed() < ANNOUNCEMENT_FRESH);
    publish_finish(if live { LINGER_LIVE } else { LINGER });
}

fn publish_finish(linger: Duration) {
    if !PROGRESS.send_if_modified(settle) {
        return;
    }
    let generation = GENERATION.load(Ordering::Acquire);
    let hide = move || {
        if GENERATION.load(Ordering::Acquire) == generation {
            PROGRESS.send_if_modified(|progress| {
                let changed = *progress != IDLE;
                *progress = IDLE;
                changed
            });
        }
    };
    match tokio::runtime::Handle::try_current() {
        Ok(handle) => {
            handle.spawn(async move {
                tokio::time::sleep(linger).await;
                hide();
            });
        }
        Err(_) => hide(),
    }
}

/// Plays a made-up import through the real progress channel, so the bar can
/// be checked without an importer page: three batches with a pause between
/// them, like a page that is still uploading. Does nothing while a real bar
/// is shown.
pub(crate) async fn preview() {
    const BATCHES: [usize; 3] = [24, 40, 12];
    const PER_MEMORY: Duration = Duration::from_millis(70);
    const BETWEEN_BATCHES: Duration = Duration::from_secs(4);
    const LINGER_PREVIEW: Duration = Duration::from_secs(5);

    if PROGRESS.borrow().active || PREVIEW.swap(true, Ordering::AcqRel) {
        return;
    }
    for (index, batch) in BATCHES.into_iter().enumerate() {
        if index > 0 {
            PROGRESS.send_if_modified(settle);
            tokio::time::sleep(BETWEEN_BATCHES).await;
        }
        publish_begin(batch);
        for _ in 0..batch {
            tokio::time::sleep(PER_MEMORY).await;
            PROGRESS.send_if_modified(step);
        }
    }
    publish_finish(LINGER_PREVIEW);
    PREVIEW.store(false, Ordering::Release);
}

fn start(progress: &mut MemoryImportProgress, missing: i64) -> bool {
    if missing <= 0 {
        return false;
    }
    if progress.active {
        // A pass that stopped early leaves its rest to this one, which lists
        // them again, so only what is done carries over.
        progress.total = progress.done.saturating_add(missing);
        progress.waiting = false;
    } else {
        *progress = MemoryImportProgress {
            active: true,
            total: missing,
            done: 0,
            waiting: false,
        };
    }
    true
}

fn step(progress: &mut MemoryImportProgress) -> bool {
    if !progress.active || progress.waiting || progress.done >= progress.total {
        return false;
    }
    progress.done += 1;
    true
}

fn settle(progress: &mut MemoryImportProgress) -> bool {
    if !progress.active || progress.waiting {
        return false;
    }
    progress.total = progress.done;
    progress.waiting = true;
    true
}

/// Forwards the progress to Flutter, starting with the current state so a
/// bar mounted halfway through shows it straight away.
pub(crate) async fn stream(sink: StreamSink<MemoryImportProgress>) -> Result<()> {
    let mut receiver = PROGRESS.subscribe();
    let current = *receiver.borrow_and_update();
    if sink.add(current).is_err() {
        return Ok(());
    }

    // This observes process-wide progress and owns no database resources, so
    // it outlives foreground database sessions like the mailbox catch-up.
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

/// Calls [`finish`] when dropped, so a pass that fails or panics never leaves
/// the bar counting.
pub(crate) struct FinishOnDrop;

impl Drop for FinishOnDrop {
    fn drop(&mut self) {
        finish();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test(start_paused = true)]
    async fn the_preview_plays_batches_and_keeps_real_passes_out() {
        let mut receiver = PROGRESS.subscribe();
        let preview = tokio::spawn(preview());

        receiver.changed().await.unwrap();
        assert_eq!(
            *receiver.borrow_and_update(),
            MemoryImportProgress {
                active: true,
                total: 24,
                done: 0,
                waiting: false,
            }
        );

        // A real pass during the preview leaves the bar alone.
        begin(500);
        advance();
        finish();
        assert_eq!(receiver.borrow().total, 24);

        preview.await.unwrap();
        assert_eq!(
            *receiver.borrow(),
            MemoryImportProgress {
                active: true,
                total: 76,
                done: 76,
                waiting: true,
            }
        );
        assert!(!previewing());

        tokio::time::sleep(Duration::from_secs(6)).await;
        assert_eq!(*receiver.borrow(), IDLE);
    }

    #[test]
    fn nothing_missing_shows_nothing() {
        let mut progress = IDLE;
        assert!(!start(&mut progress, 0));
        assert_eq!(progress, IDLE);
    }

    #[test]
    fn a_pass_counts_up_to_its_total() {
        let mut progress = IDLE;
        assert!(start(&mut progress, 3));
        assert!(step(&mut progress));
        assert!(step(&mut progress));
        assert!(step(&mut progress));
        assert_eq!(
            progress,
            MemoryImportProgress {
                active: true,
                total: 3,
                done: 3,
                waiting: false,
            }
        );
        // Never past the total.
        assert!(!step(&mut progress));
        assert_eq!(progress.done, 3);
    }

    #[test]
    fn a_following_pass_extends_the_shown_bar() {
        let mut progress = IDLE;
        start(&mut progress, 10);
        for _ in 0..4 {
            step(&mut progress);
        }
        // The first pass stopped after four; the next one finds the six left
        // and two that arrived meanwhile.
        start(&mut progress, 8);
        assert_eq!((progress.total, progress.done), (12, 4));
    }

    #[test]
    fn the_next_batch_continues_a_waiting_bar() {
        let mut progress = IDLE;
        start(&mut progress, 5);
        for _ in 0..5 {
            step(&mut progress);
        }
        assert!(settle(&mut progress));
        assert!(progress.waiting);
        // Waiting adds nothing.
        assert!(!step(&mut progress));

        start(&mut progress, 7);
        assert_eq!(
            progress,
            MemoryImportProgress {
                active: true,
                total: 12,
                done: 5,
                waiting: false,
            }
        );
    }

    #[test]
    fn a_pass_that_stopped_early_settles_on_what_it_did() {
        let mut progress = IDLE;
        start(&mut progress, 10);
        step(&mut progress);
        settle(&mut progress);
        assert_eq!((progress.total, progress.done), (1, 1));
    }

    #[test]
    fn nothing_settles_without_a_bar() {
        let mut progress = IDLE;
        assert!(!settle(&mut progress));
        assert!(!step(&mut progress));
        assert_eq!(progress, IDLE);
    }
}
