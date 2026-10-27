-- Records that a claimed message was handled and its handling committed.
--
-- A redelivered encrypted message is decrypted again, on the assumption that
-- the outcome tells a handled message from one that never opened: the ratchet
-- reports a duplicate for the former. That holds only while the peer resends
-- the same ciphertext. A peer that opened a new session re-encrypts its whole
-- queue under the same receipt IDs, every copy opens again, and every one was
-- handled a second time -- a reupload request answered with a full reupload
-- on each of the peer's wake-ups.
--
-- The mark is written in the commit that handles the message, so it is only
-- ever set when that is known. Claims from before this column, and claims left
-- by a failed decryption, stay NULL and keep being decrypted and handled.
ALTER TABLE received_receipts
    ADD COLUMN handled_at INTEGER;
