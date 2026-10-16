-- Chunks survive process restarts and out-of-order delivery. They are removed
-- as soon as a complete, verified state transfer has been installed.
CREATE TABLE webxdc_sync_chunks (
    transfer_id TEXT NOT NULL,
    group_id TEXT NOT NULL REFERENCES groups(group_id) ON DELETE CASCADE,
    sender_id INTEGER NOT NULL REFERENCES contacts(user_id) ON DELETE CASCADE,
    chunk_index INTEGER NOT NULL,
    chunk_count INTEGER NOT NULL,
    payload_sha256 BLOB NOT NULL,
    payload BLOB NOT NULL,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    PRIMARY KEY (transfer_id, sender_id, chunk_index)
);

CREATE INDEX idx_webxdc_sync_chunks_created_at
    ON webxdc_sync_chunks(created_at);

-- A newly joined member can receive a live update before the instance snapshot.
-- Keep it until the app card arrives instead of dropping shared state.
CREATE TABLE webxdc_pending_updates (
    message_id TEXT NOT NULL PRIMARY KEY,
    instance_id TEXT NOT NULL,
    group_id TEXT NOT NULL REFERENCES groups(group_id) ON DELETE CASCADE,
    sender_id INTEGER NOT NULL REFERENCES contacts(user_id) ON DELETE CASCADE,
    payload TEXT NOT NULL,
    info TEXT,
    href TEXT,
    summary TEXT,
    document TEXT,
    received_at INTEGER NOT NULL
);

CREATE INDEX idx_webxdc_pending_updates_instance
    ON webxdc_pending_updates(instance_id, received_at);
