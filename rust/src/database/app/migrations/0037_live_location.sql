-- Runtime sessions are device-local and never restored from a chat backup.
CREATE TABLE live_location_sessions (
    session_id TEXT PRIMARY KEY NOT NULL,
    expires_at_ms INTEGER NOT NULL
);
CREATE TABLE live_location_targets (
    session_id TEXT NOT NULL REFERENCES live_location_sessions(session_id) ON DELETE CASCADE,
    group_id TEXT NOT NULL REFERENCES groups(group_id) ON DELETE CASCADE,
    message_id TEXT NOT NULL REFERENCES messages(message_id) ON DELETE CASCADE,
    recipient_ids TEXT NOT NULL,
    PRIMARY KEY(session_id, group_id)
);
-- At most the latest unsent point per card/recipient, never a movement log.
CREATE TABLE live_location_outbox (
    receipt_id TEXT PRIMARY KEY NOT NULL REFERENCES receipts(receipt_id) ON DELETE CASCADE,
    message_id TEXT NOT NULL REFERENCES messages(message_id) ON DELETE CASCADE
);
-- Mailbox delivery can put an update before its text-message card.
CREATE TABLE live_location_pending (
    message_id TEXT PRIMARY KEY NOT NULL,
    group_id TEXT NOT NULL,
    sender_id INTEGER NOT NULL,
    updated_at_ms INTEGER NOT NULL,
    expires_at_ms INTEGER NOT NULL,
    data BLOB NOT NULL
);
