-- Peers announce sealed-sender support in every encrypted content they send.
-- Until a contact has announced it, messages keep using the named transport.
ALTER TABLE contacts
    ADD COLUMN sealed_sender_enabled INTEGER NOT NULL DEFAULT 0
        CHECK (sealed_sender_enabled IN (0, 1));

-- Anonymous rate-limiting tokens for the sealed-sender upload endpoint. They
-- are issued over the authenticated WebSocket and spent unauthenticated over
-- HTTP, so a token must never be linkable back to its issuance.
CREATE TABLE privacy_pass_tokens (
    token BLOB NOT NULL PRIMARY KEY,
    expires_at INTEGER NOT NULL,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);

CREATE INDEX idx_privacy_pass_tokens_expires_at ON privacy_pass_tokens(expires_at);
