-- A direct chat is created when a friendship is accepted. A peer's temporary
-- loss of its contact state must not turn that friendship into a new request.
-- Preserve explicit blocks, removals, and deleted accounts.
UPDATE contacts
SET accepted = 1, requested = 0, requested_by_user = 0
WHERE accepted = 0 AND blocked = 0 AND deleted_by_user = 0 AND account_deleted = 0
  AND EXISTS (
      SELECT 1 FROM group_members m
      JOIN groups g ON g.group_id = m.group_id
      WHERE m.contact_id = contacts.user_id AND g.is_direct_chat = 1
  );

UPDATE receipts
SET mark_for_retry_after_accepted = NULL
WHERE mark_for_retry_after_accepted IS NOT NULL
  AND EXISTS (
      SELECT 1 FROM contacts c
      JOIN group_members m ON m.contact_id = c.user_id
      JOIN groups g ON g.group_id = m.group_id
      WHERE c.user_id = receipts.contact_id AND c.accepted = 1
        AND c.blocked = 0 AND c.deleted_by_user = 0 AND c.account_deleted = 0
        AND g.is_direct_chat = 1
  );
