-- A contact's latest publicly shared twonly Score. NULL means that the
-- contact does not currently share it.
ALTER TABLE contacts ADD COLUMN twonly_score INTEGER;
