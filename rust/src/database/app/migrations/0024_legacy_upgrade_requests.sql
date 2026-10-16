-- When a peer still sending legacy (v1) Signal messages was last asked to move
-- to v2. Older clients retry every decryption error with the same v1
-- ciphertext, so the request is answered once per interval and the retries in
-- between are left unanswered, which is what ends that loop.
CREATE TABLE legacy_upgrade_requests (
    contact_id INTEGER PRIMARY KEY REFERENCES contacts(user_id) ON DELETE CASCADE,
    requested_at INTEGER NOT NULL
);
