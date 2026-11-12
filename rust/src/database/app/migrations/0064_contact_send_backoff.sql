-- The server refused envelopes for a contact because a sending limit was
-- reached: their mailbox holds too many of our undelivered messages, or too
-- many other mailboxes do. Nothing is sent to them before `retry_at`, and every
-- further refusal makes the wait longer. A message from them makes the retry
-- due at once; a delivery that goes through removes the row.
CREATE TABLE contact_send_backoff (
    contact_id INTEGER PRIMARY KEY REFERENCES contacts(user_id) ON DELETE CASCADE,
    attempts INTEGER NOT NULL,
    retry_at INTEGER NOT NULL
);
