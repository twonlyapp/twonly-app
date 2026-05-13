-- Initial migration: Create received_messages and sending_messages tables

CREATE TABLE IF NOT EXISTS received_messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sender_id BIGINT NOT NULL,
    content BLOB NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
