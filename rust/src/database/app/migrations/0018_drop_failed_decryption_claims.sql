-- Drops the column added by 0017.
--
-- It marked claims left behind by a failed decryption so their redelivery
-- would decrypt again. That distinction turned out to be both unknowable and
-- unnecessary: a claim carrying no parked plaintext says nothing about whether
-- its message was handled, and claims written before the column existed could
-- never be marked at all. Every redelivered encrypted message is decrypted
-- again instead, and the outcome answers the question -- it opens, or it comes
-- back as a duplicate the ratchet already consumed.
ALTER TABLE received_receipts
    DROP COLUMN decryption_failed;
