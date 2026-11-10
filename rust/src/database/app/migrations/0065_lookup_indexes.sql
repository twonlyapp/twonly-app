-- Media lookups and the media_files foreign key (ON DELETE SET NULL) filter on
-- messages.media_id alone. idx_messages_chat_media leads with group_id, so it
-- cannot serve them and each lookup or media delete scanned every message.
-- SQLite infers `media_id IS NOT NULL` from `media_id = ?` and `media_id IN`,
-- so the partial index serves those queries and the foreign-key check.
CREATE INDEX idx_messages_media_id
ON messages(media_id)
WHERE media_id IS NOT NULL;

-- Foreign keys are enforced, so every message delete looks up the rows that
-- reference it. Without these indexes each delete scanned all of these tables.
CREATE INDEX idx_message_histories_message_id
ON message_histories(message_id);

CREATE INDEX idx_live_location_targets_message_id
ON live_location_targets(message_id);

CREATE INDEX idx_live_location_outbox_message_id
ON live_location_outbox(message_id);

-- Pending receipts are retried, updated and deleted by contact.
CREATE INDEX idx_receipts_contact_id
ON receipts(contact_id);

-- The group history query filters by group and orders by action_at, rowid;
-- the index returns rows in that order without a separate sort.
CREATE INDEX idx_group_histories_group_action
ON group_histories(group_id, action_at);
