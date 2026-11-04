-- Messages parked for a peer without a prekey bundle used to show a spinner
-- forever. They are marked as failed now when parked; mark the ones parked
-- before this change too. Delivering one later removes the mark again.
INSERT INTO message_actions(message_id, contact_id, type)
SELECT r.message_id, r.contact_id, 'sendFailed'
FROM receipts r
JOIN messages m ON m.message_id = r.message_id
WHERE r.deferred_until_session IS NOT NULL
  AND m.sender_id IS NULL
ON CONFLICT(message_id, contact_id, type) DO NOTHING;
