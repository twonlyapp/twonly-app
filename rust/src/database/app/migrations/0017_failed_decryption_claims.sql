-- Records that a claimed message never decrypted.
--
-- The claim is committed before the message is handled, so a redelivery is not
-- processed twice. Without this column a claim left behind by a failed
-- decryption looks exactly like one left by a message that was handled, and the
-- redelivery is dropped -- which is how a peer whose session broke could never
-- reach the decrypt path again, and so never trigger the session reset that
-- would have repaired it.
ALTER TABLE received_receipts
    ADD COLUMN decryption_failed INTEGER NOT NULL DEFAULT 0;
