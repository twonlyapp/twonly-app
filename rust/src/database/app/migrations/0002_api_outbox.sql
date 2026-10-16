CREATE TABLE
    api_outbox (
        sequence_id INTEGER NOT NULL PRIMARY KEY,
        payload BLOB NOT NULL,
        operation_kind TEXT NOT NULL,
        created_at INTEGER NOT NULL DEFAULT (
            CAST(strftime ('%s', CURRENT_TIMESTAMP) AS INTEGER)
        ),
        attempt_count INTEGER NOT NULL DEFAULT 0,
        next_attempt_at INTEGER NOT NULL DEFAULT (
            CAST(strftime ('%s', CURRENT_TIMESTAMP) AS INTEGER)
        ),
        expires_at INTEGER
    );

CREATE INDEX idx_api_outbox_next_attempt ON api_outbox (next_attempt_at);
