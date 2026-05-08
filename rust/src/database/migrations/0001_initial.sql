-- Initial migration: Create received_messages and sending_messages tables

CREATE TABLE IF NOT EXISTS received_messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sender_id TEXT NOT NULL,
    content BLOB NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
);

CREATE TABLE IF NOT EXISTS sending_messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipient_id TEXT NOT NULL,
    content BLOB NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'pending'
);
