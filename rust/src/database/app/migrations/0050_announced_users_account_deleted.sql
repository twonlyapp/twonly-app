-- Records that the server denied an announced user exists.
--
-- Every authenticated connection refreshes the announced users it has no
-- username for. A deleted account never gets one, so without this mark it is
-- asked about again on every connection, forever. Contacts keep the same fact
-- in `contacts.account_deleted`.
ALTER TABLE user_discovery_announced_users
    ADD COLUMN account_deleted INTEGER NOT NULL DEFAULT 0 CHECK (account_deleted IN (0, 1));
