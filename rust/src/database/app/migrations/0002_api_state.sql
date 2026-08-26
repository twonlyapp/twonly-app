-- State required by the standalone Rust API and client-to-client processor.
CREATE TABLE api_state (
    key TEXT NOT NULL PRIMARY KEY,
    value BLOB NOT NULL,
    updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);

CREATE TABLE api_outbox (
    sequence_id INTEGER NOT NULL PRIMARY KEY,
    payload BLOB NOT NULL,
    operation_kind TEXT NOT NULL,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    attempt_count INTEGER NOT NULL DEFAULT 0,
    next_attempt_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    expires_at INTEGER
);
CREATE INDEX idx_api_outbox_next_attempt ON api_outbox(next_attempt_at);

CREATE TABLE contact_push_keys (
    contact_id INTEGER NOT NULL REFERENCES contacts(user_id) ON DELETE CASCADE,
    key_id INTEGER NOT NULL,
    key BLOB NOT NULL,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (contact_id, key_id)
);
