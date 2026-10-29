-- Error envelopes have their own receipt IDs. Deduplicating those IDs cannot
-- bound the contact requests they create, especially after a request is ACKed.
-- Limit acceptance notices separately: redelivering a retained message must
-- not mint a new error envelope on each mailbox drain either.
CREATE TABLE contact_handshake_repairs (
    contact_id INTEGER NOT NULL PRIMARY KEY REFERENCES contacts(user_id) ON DELETE CASCADE,
    requested_at INTEGER,
    notified_at INTEGER,
    awaiting_acceptance_since INTEGER
);

INSERT INTO contact_handshake_repairs(contact_id, awaiting_acceptance_since)
SELECT contact_id, MIN(mark_for_retry_after_accepted)
FROM receipts WHERE mark_for_retry_after_accepted IS NOT NULL
GROUP BY contact_id;
