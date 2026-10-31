-- Restore accepted contacts for existing direct chats after migration.
-- Preserve explicit blocks, removals, and deleted accounts.
UPDATE contacts
SET accepted = 1, requested = 0, requested_by_user = 0
WHERE blocked = 0 AND deleted_by_user = 0 AND account_deleted = 0
  AND (accepted = 0 OR requested != 0 OR requested_by_user != 0)
  AND EXISTS (
      SELECT 1 FROM group_members m
      JOIN groups g ON g.group_id = m.group_id
      WHERE m.contact_id = contacts.user_id AND g.is_direct_chat = 1
  );
