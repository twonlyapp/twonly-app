CREATE TABLE notification_outbox (
    event_id TEXT NOT NULL PRIMARY KEY,
    notification_id TEXT NOT NULL,
    conversation_id TEXT,
    sender_id INTEGER NOT NULL REFERENCES contacts(user_id) ON DELETE CASCADE,
    message_id TEXT,
    kind TEXT NOT NULL,
    content TEXT,
    created_at INTEGER NOT NULL,
    delivered_at INTEGER,
    cleared_at INTEGER
);

CREATE INDEX idx_notification_outbox_pending
    ON notification_outbox(delivered_at, created_at);

CREATE INDEX idx_notification_outbox_conversation
    ON notification_outbox(conversation_id, cleared_at);

ALTER TABLE receipts
    ADD COLUMN wake_receiver INTEGER NOT NULL DEFAULT 0 CHECK (wake_receiver IN (0, 1));
