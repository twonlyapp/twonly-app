-- Apps such as a shared expense ledger have one instance per chat.
ALTER TABLE webxdc_apps ADD COLUMN one_time BOOLEAN NOT NULL DEFAULT FALSE;
