-- Keep discovery claims, but only apply them to the identity used for messaging.
-- Rust refreshes this local snapshot from the Signal store when a session is
-- established, an announcement arrives, and the application initializes.
ALTER TABLE user_discovery_announced_users ADD COLUMN session_identity_key BLOB;

DROP VIEW valid_discovery_verifications;
CREATE VIEW valid_discovery_verifications AS
SELECT ur.* FROM user_discovery_user_relations ur
JOIN user_discovery_announced_users announced
  ON announced.announced_user_id = ur.announced_user_id
WHERE ur.announced_user_id != ur.from_contact_id
  AND ur.public_key_verified_timestamp IS NOT NULL
  AND length(announced.announced_public_key) > 0
  AND announced.session_identity_key = announced.announced_public_key
  AND EXISTS (
      SELECT 1 FROM direct_key_verifications verifier
      JOIN contacts c ON c.user_id = verifier.contact_id
      WHERE verifier.contact_id = ur.from_contact_id
        AND c.blocked = 0 AND c.deleted_by_user = 0 AND c.account_deleted = 0
  );
