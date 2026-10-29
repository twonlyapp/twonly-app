-- Personal verification is the only authority for an inherited attestation.
-- A shared contact is evidence about that contact, not a new trust authority.
DELETE FROM key_verifications
WHERE type NOT IN ('migratedFromOldVersion', 'qrScanned', 'link', 'manual',
                   'secretQrToken', 'contactSharedByVerified')
   OR (type = 'contactSharedByVerified'
       AND (verified_by IS NULL OR verified_by = contact_id))
   OR (type != 'contactSharedByVerified' AND verified_by IS NOT NULL);

DELETE FROM key_verifications
WHERE verification_id NOT IN (
    SELECT MIN(verification_id) FROM key_verifications
    GROUP BY contact_id, type, verified_by
);

CREATE INDEX key_verifications_evidence
ON key_verifications(contact_id, type, verified_by);

CREATE VIEW direct_key_verifications AS
SELECT kv.* FROM key_verifications kv
WHERE kv.type IN ('migratedFromOldVersion', 'qrScanned', 'link', 'manual', 'secretQrToken')
  AND kv.verified_by IS NULL
  AND kv.verification_id = (
      SELECT MIN(other.verification_id) FROM key_verifications other
      WHERE other.contact_id = kv.contact_id AND other.type = kv.type
        AND other.verified_by IS NULL
  );

CREATE VIEW valid_key_verifications AS
SELECT * FROM direct_key_verifications
UNION ALL
SELECT kv.* FROM key_verifications kv
WHERE kv.type = 'contactSharedByVerified'
  AND kv.verified_by != kv.contact_id
  AND EXISTS (
      SELECT 1 FROM direct_key_verifications verifier
      JOIN contacts c ON c.user_id = verifier.contact_id
      WHERE verifier.contact_id = kv.verified_by
        AND c.blocked = 0 AND c.deleted_by_user = 0 AND c.account_deleted = 0
  )
  AND kv.verification_id = (
      SELECT MIN(other.verification_id) FROM key_verifications other
      WHERE other.contact_id = kv.contact_id AND other.type = kv.type
        AND other.verified_by = kv.verified_by
  );

CREATE VIEW valid_discovery_verifications AS
SELECT ur.* FROM user_discovery_user_relations ur
WHERE ur.announced_user_id != ur.from_contact_id
  AND ur.public_key_verified_timestamp IS NOT NULL
  AND EXISTS (
      SELECT 1 FROM direct_key_verifications verifier
      JOIN contacts c ON c.user_id = verifier.contact_id
      WHERE verifier.contact_id = ur.from_contact_id
        AND c.blocked = 0 AND c.deleted_by_user = 0 AND c.account_deleted = 0
  );

-- A displayed token can verify several people, but each person's proof is
-- accepted only once. Replaying it must not undo a deliberate revocation.
-- Retire older tokens whose proofs may already have been accepted.
DELETE FROM verification_tokens;
-- Legacy imports run after SQL migrations. Their tokens must remain retired
-- as well, rather than acquiring an unknown replay history on import.
ALTER TABLE verification_tokens ADD COLUMN proof_version INTEGER NOT NULL DEFAULT 0;

CREATE TABLE verification_token_uses (
    token_id INTEGER NOT NULL REFERENCES verification_tokens(token_id) ON DELETE CASCADE,
    -- Keep consumption history if a contact is removed and then re-added.
    contact_id INTEGER NOT NULL,
    PRIMARY KEY (token_id, contact_id)
);

INSERT INTO app_metadata(key, value) VALUES ('verification_policy_refresh', 'pending');
