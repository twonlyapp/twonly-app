-- Envelopes handed to an OS-owned transfer instead of the websocket.
--
-- The socket only exists while the app runs, so a message queued while offline
-- waits for the next app launch rather than the next network. An envelope
-- prepared here is POSTed by WorkManager or a background URLSession, which both
-- wait for connectivity themselves and survive the app being closed.
--
-- The receipt itself stays in `receipts` and keeps being retried over the
-- socket: this is an accelerator, not a replacement. A recipient that receives
-- both copies deduplicates them by receipt id, exactly as it already does for a
-- socket retransmission.
CREATE TABLE outbox_dispatch_jobs (
    receipt_id TEXT PRIMARY KEY,
    dispatch_id TEXT NOT NULL UNIQUE,
    contact_id INTEGER NOT NULL,
    body_path TEXT NOT NULL,
    expires_at INTEGER NOT NULL,
    created_at INTEGER NOT NULL
);

CREATE INDEX outbox_dispatch_jobs_expiry_idx ON outbox_dispatch_jobs(expires_at);
