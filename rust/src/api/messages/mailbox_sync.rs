/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Progress of a large mailbox catch-up.
//!
//! A device that was offline for long, or whose contacts kept resending, can
//! find thousands of messages waiting. Working through them takes minutes, and
//! until it is done new messages queue behind the old ones. The app shows this
//! as a progress screen instead of looking as if nothing arrives.
//!
//! Every mailbox page carries the server's count of waiting rows, so the first
//! page above [`SYNC_THRESHOLD`] fixes the total and each handled message moves
//! `remaining` down. The catch-up ends when the server reports the mailbox
//! drained, when the count reaches zero, or after [`STALL_TIMEOUT`] without
//! progress, so a device that went offline is never locked behind the screen.

use crate::bridge::api::MailboxSyncProgress;
use crate::error::Result;
use crate::frb_generated::StreamSink;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{LazyLock, Mutex, PoisonError};
use std::time::{Duration, Instant};
use tokio::sync::watch;

/// A mailbox holding more messages than this is caught up behind the progress
/// screen.

pub(crate) const SYNC_THRESHOLD: i64 = 2000;

/// How long a catch-up may go without handling a single message before it is
/// given up. Pages keep coming while the connection holds, so this only ends a
/// catch-up whose connection is gone.

const STALL_TIMEOUT: Duration = Duration::from_secs(120);

const STALL_CHECK_INTERVAL: Duration = Duration::from_secs(15);

const IDLE: MailboxSyncProgress = MailboxSyncProgress {
    active: false,
    total: 0,
    remaining: 0,
};

static MAILBOX_SYNC: LazyLock<watch::Sender<MailboxSyncProgress>> =
    LazyLock::new(|| watch::channel(IDLE).0);

static LAST_PROGRESS: Mutex<Option<Instant>> = Mutex::new(None);

/// Set while [`preview`] owns the channel. Real pages and drains are kept out
/// of it meanwhile, and the catch-up cadence ignores the made-up progress.

static PREVIEW: AtomicBool = AtomicBool::new(false);

fn mark_progress() {
    *LAST_PROGRESS.lock().unwrap_or_else(PoisonError::into_inner) = Some(Instant::now());
}

pub(crate) fn is_active() -> bool {
    !PREVIEW.load(Ordering::Acquire) && MAILBOX_SYNC.borrow().active
}

/// Records how far the current mailbox page has got. `pending` is the server's
/// count of waiting rows when it sent the page, the page included, and
/// `handled` how many of the page's messages are done.

pub(crate) fn record_page(pending: Option<u64>, handled: usize) {
    if PREVIEW.load(Ordering::Acquire) {
        return;
    }

    publish_page(pending, handled);
}

fn publish_page(pending: Option<u64>, handled: usize) {
    // A server that does not count leaves the page without progress.
    let Some(pending) = pending else {
        return;
    };

    let pending = i64::try_from(pending).unwrap_or(i64::MAX);

    let handled = i64::try_from(handled).unwrap_or(i64::MAX);

    MAILBOX_SYNC.send_if_modified(|sync| {
        let before = *sync;

        if advance(sync, pending, handled) {
            mark_progress();
        }

        if before.active != sync.active {
            if sync.active {
                tracing::info!(pending, "a large mailbox is waiting; showing the catch-up");
            } else {
                tracing::info!(total = before.total, "caught up with the mailbox");
            }
        }

        *sync != before
    });
}

/// Moves `sync` to the state a page reports, and returns whether that counts
/// as progress -- a catch-up starting, or a message less to go.

fn advance(sync: &mut MailboxSyncProgress, pending: i64, handled: i64) -> bool {
    let remaining = pending.saturating_sub(handled).max(0);

    let mut progressed = false;

    if !sync.active {
        if pending <= SYNC_THRESHOLD {
            return false;
        }

        *sync = MailboxSyncProgress {
            active: true,
            total: pending,
            remaining: pending,
        };

        progressed = true;
    }

    if remaining == 0 {
        *sync = IDLE;

        return true;
    }

    // Messages arriving while the catch-up runs raise the total, so the bar
    // never runs backwards past its start.
    sync.total = sync.total.max(pending);

    progressed |= remaining < sync.remaining;

    sync.remaining = remaining;

    progressed
}

/// Ends the catch-up once the server has nothing left to send.

pub(crate) fn finish() {
    if PREVIEW.load(Ordering::Acquire) {
        return;
    }

    publish_finish();
}

fn publish_finish() {
    MAILBOX_SYNC.send_if_modified(|sync| {
        if !sync.active {
            return false;
        }

        tracing::info!(total = sync.total, "mailbox drained; catch-up finished");

        *sync = IDLE;

        true
    });
}

fn expire_if_stalled() {
    let stalled = LAST_PROGRESS
        .lock()
        .unwrap_or_else(PoisonError::into_inner)
        .is_some_and(|last| last.elapsed() >= STALL_TIMEOUT);

    if !stalled {
        return;
    }

    MAILBOX_SYNC.send_if_modified(|sync| {
        if !sync.active {
            return false;
        }

        tracing::warn!(
            total = sync.total,
            remaining = sync.remaining,
            "mailbox catch-up made no progress; hiding it until pages arrive again"
        );

        *sync = IDLE;

        true
    });
}

/// Plays a made-up catch-up of 3000 messages through the real progress
/// channel, so the screen can be checked without a mailbox that full. Does
/// nothing while a real catch-up runs.

pub(crate) async fn preview() {
    const TOTAL: u64 = 3000;
    const PAGE: u64 = 100;
    const STEP: u64 = 10;

    if MAILBOX_SYNC.borrow().active || PREVIEW.swap(true, Ordering::AcqRel) {
        return;
    }

    let mut pending = TOTAL;

    while pending > 0 {
        let page = PAGE.min(pending);

        for handled in (0..=page).step_by(STEP as usize) {
            publish_page(Some(pending), handled as usize);

            tokio::time::sleep(Duration::from_millis(50)).await;
        }

        pending -= page;
    }

    publish_finish();

    PREVIEW.store(false, Ordering::Release);
}

/// Forwards the catch-up progress to Flutter, starting with the current state
/// so a screen mounted halfway through shows it straight away. The stall check
/// rides on this loop: only a device with a screen to unblock needs it.

pub(crate) async fn stream(sink: StreamSink<MailboxSyncProgress>) -> Result<()> {
    let mut receiver = MAILBOX_SYNC.subscribe();

    expire_if_stalled();

    let current = *receiver.borrow_and_update();

    if sink.add(current).is_err() {
        return Ok(());
    }

    crate::database::lifecycle::spawn(async move {
        loop {
            tokio::select! {
                changed = receiver.changed() => {
                    if changed.is_err() {
                        break;
                    }
                }
                () = tokio::time::sleep(STALL_CHECK_INTERVAL) => {
                    // An expiry publishes through the channel, so the next
                    // turn of the loop forwards it.
                    expire_if_stalled();

                    continue;
                }
            }

            let progress = *receiver.borrow_and_update();

            if sink.add(progress).is_err() {
                break;
            }
        }
    });

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn idle() -> MailboxSyncProgress {
        IDLE
    }

    #[test]
    fn a_small_mailbox_never_starts_a_catch_up() {
        let mut sync = idle();

        assert!(!advance(&mut sync, SYNC_THRESHOLD, 0));

        assert_eq!(sync, idle());
    }

    #[test]
    fn the_first_large_page_fixes_the_total_and_messages_count_down() {
        let mut sync = idle();

        assert!(advance(&mut sync, 6000, 0));

        assert_eq!(
            sync,
            MailboxSyncProgress {
                active: true,
                total: 6000,
                remaining: 6000
            }
        );

        assert!(advance(&mut sync, 6000, 40));

        assert_eq!(sync.remaining, 5960);

        // The next page reports what is left; the total stays.
        advance(&mut sync, 5900, 0);

        assert_eq!((sync.total, sync.remaining), (6000, 5900));
    }

    #[test]
    fn the_catch_up_continues_below_the_threshold_until_it_is_done() {
        let mut sync = idle();

        advance(&mut sync, 2500, 0);

        advance(&mut sync, 100, 0);

        assert!(sync.active);

        assert!(advance(&mut sync, 100, 100));

        assert_eq!(sync, idle());
    }

    #[test]
    fn new_messages_raise_the_total_instead_of_overflowing_it() {
        let mut sync = idle();

        advance(&mut sync, 3000, 0);

        assert!(!advance(&mut sync, 3200, 0));

        assert_eq!((sync.total, sync.remaining), (3200, 3200));
    }

    #[test]
    fn a_redelivered_page_is_not_progress() {
        let mut sync = idle();

        advance(&mut sync, 3000, 0);

        advance(&mut sync, 3000, 100);

        // The same page again after a lost acknowledgement.
        assert!(!advance(&mut sync, 3000, 0));

        assert_eq!(sync.remaining, 3000);
    }
}
