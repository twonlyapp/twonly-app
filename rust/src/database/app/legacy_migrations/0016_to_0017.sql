-- Frozen from the historical Drift upgrade; do not edit.

ALTER TABLE "user_discovery_announced_users"
   
    ADD COLUMN "was_asked_friends" INTEGER NOT NULL DEFAULT 0 CHECK (was_asked_friends IN (0, 1));
