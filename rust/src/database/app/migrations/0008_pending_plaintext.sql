-- Signal decryption advances the double ratchet in the *signal* database, which
-- has nothing to do with the app-database transaction that guards the receipt
-- claim. Rolling that transaction back after a successful decryption therefore
-- un-claims the receipt without rewinding the ratchet: the server redelivers
-- the envelope and the retry dies with "message with old counter", losing the
-- message for good.
--
-- The plaintext is parked here in the same commit that claims the receipt, so a
-- retry resumes from it instead of decrypting a second time. It is cleared as
-- soon as the message has been handled.
ALTER TABLE received_receipts
    ADD COLUMN pending_plaintext BLOB;
