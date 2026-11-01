-- Inbound profile claims only schedule work. Keep the cooldown even after a
-- successful refresh, and keep pending work across cancellation or restart.
CREATE TABLE contact_metadata_refreshes (
    contact_id INTEGER PRIMARY KEY REFERENCES contacts(user_id) ON DELETE CASCADE,
    pending INTEGER NOT NULL DEFAULT 1 CHECK (pending IN (0, 1)),
    generation INTEGER NOT NULL DEFAULT 1,
    next_attempt_at INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE contact_metadata_refresh_budget (
    singleton INTEGER PRIMARY KEY CHECK (singleton = 1),
    next_attempt_at INTEGER NOT NULL DEFAULT 0
);

INSERT INTO contact_metadata_refresh_budget(singleton) VALUES (1);
