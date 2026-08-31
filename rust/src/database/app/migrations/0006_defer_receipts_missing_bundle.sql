-- A queued receipt for a peer with no published prekey bundle and no local
-- session cannot be encrypted at all. Retrying it on every sweep only repeats
-- the same server round-trip, so it is parked here and released again when the
-- peer becomes reachable (a bundle fetch succeeds, or an inbound message from
-- them opens a session).
ALTER TABLE receipts
    ADD COLUMN deferred_until_session INTEGER;
