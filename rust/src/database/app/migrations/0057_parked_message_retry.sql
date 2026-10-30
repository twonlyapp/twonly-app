-- A message whose plaintext is parked here is retried from this device.
--
-- The server serves a mailbox oldest first, a page at a time, and keeps every
-- row the client leaves out of its acknowledgement. Leaving out a message that
-- failed after decryption kept it at the front of the mailbox for as long as
-- it failed: a hundred such messages, which anyone can send, and nothing behind
-- them was delivered again. Its plaintext is parked here already, so the
-- server's copy only repeats it. The client now acknowledges it and retries
-- from the parked plaintext, which needs to know who sent it, when to try
-- again, and whether it waits for the sender to be accepted.
--
-- The sender also binds the parked plaintext to the account that sent it. A
-- redelivery naming anyone else is not resumed from it.
ALTER TABLE received_receipts
ADD COLUMN pending_from_user_id INTEGER;

ALTER TABLE received_receipts
ADD COLUMN pending_since INTEGER;

ALTER TABLE received_receipts
ADD COLUMN pending_attempts INTEGER NOT NULL DEFAULT 0;

ALTER TABLE received_receipts
ADD COLUMN pending_retry_at INTEGER;

ALTER TABLE received_receipts
ADD COLUMN pending_waits_for_acceptance INTEGER NOT NULL DEFAULT 0
    CHECK (pending_waits_for_acceptance IN (0, 1));

CREATE INDEX idx_received_receipts_parked
    ON received_receipts(pending_from_user_id)
    WHERE pending_plaintext IS NOT NULL;
