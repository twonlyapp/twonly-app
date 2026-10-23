-- Native dispatch can deliver a message without recording websocket acceptance.
-- Preserve known acceptance times and repair only outgoing rows with proof of
-- acceptance, delivery or opening already recorded by the recipient status UI.
UPDATE messages
SET ack_by_server = (
    SELECT MIN(action_at)
    FROM message_actions
    WHERE message_actions.message_id = messages.message_id
      AND type IN ('ackByServerAt', 'ackByUserAt', 'openedAt')
)
WHERE sender_id IS NULL
  AND ack_by_server IS NULL
  AND message_id IN (
      SELECT message_id FROM message_actions
      WHERE type IN ('ackByServerAt', 'ackByUserAt', 'openedAt')
  );
