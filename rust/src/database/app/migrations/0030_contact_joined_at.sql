-- UTC Unix timestamp at which the contact registered with twonly. NULL until
-- it has been loaded from a server that supports this profile field.
ALTER TABLE contacts ADD COLUMN joined_at INTEGER;
