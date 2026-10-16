-- Whether *we* sent this contact a request that is still outstanding.
--
-- Until now that was only implied, by a row sitting at
-- `accepted = requested = deleted_by_user = blocked = 0`. Every other way a
-- row reaches that shape -- a peer met in a shared group, a backup restore,
-- an avatar lookup -- was therefore indistinguishable from "we asked them",
-- so an unsolicited `Accept` could make its sender an accepted contact and an
-- unsolicited `Request` was auto-accepted. Recording the send makes both
-- checks answer the question they actually mean to ask.
ALTER TABLE contacts ADD COLUMN requested_by_user INTEGER NOT NULL DEFAULT 0
    CHECK (requested_by_user IN (0, 1));

-- Carry in-flight handshakes over the upgrade. This is exactly the shape the
-- old accept path honoured, so it grants nothing that was not already
-- reachable before.
UPDATE contacts SET requested_by_user = 1
WHERE accepted = 0 AND requested = 0 AND deleted_by_user = 0 AND blocked = 0;
