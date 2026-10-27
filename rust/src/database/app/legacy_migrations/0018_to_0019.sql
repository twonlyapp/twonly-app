-- Frozen from the historical Drift upgrade; do not edit.

ALTER TABLE "key_verifications"
   
    ADD COLUMN "verified_by" INTEGER NULL REFERENCES contacts(user_id)ON DELETE CASCADE;
