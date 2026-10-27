-- Frozen from the historical Drift upgrade; do not edit.

ALTER TABLE "contacts"
   
    ADD COLUMN "ask_for_friend_promotions" INTEGER NULL CHECK (ask_for_friend_promotions IN (0, 1));
