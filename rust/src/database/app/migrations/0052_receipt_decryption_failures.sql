-- Counts how often the peer reported that it could not decrypt this message.
--
-- A decryption error requeues the receipt under a new ID and sends it again at
-- once. When it is our session the peer cannot open, every resend fails the
-- same way, and the two devices trade errors and resends as fast as the
-- network carries them. The count lets a repeated failure back off, rebuild 
-- the session, and finally wait for a session instead of failing again.
ALTER TABLE receipts
ADD COLUMN decryption_failures INTEGER NOT NULL DEFAULT 0;