-- Retry responses requeue an envelope under a fresh receipt ID. Keep the
-- live-location link attached so retries work and newer points can still
-- replace that queued update.
CREATE TABLE live_location_outbox_updated (
    receipt_id TEXT PRIMARY KEY NOT NULL REFERENCES receipts(receipt_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    message_id TEXT NOT NULL REFERENCES messages(message_id) ON DELETE CASCADE
);

INSERT INTO live_location_outbox_updated(receipt_id, message_id)
SELECT receipt_id, message_id FROM live_location_outbox;

DROP TABLE live_location_outbox;
ALTER TABLE live_location_outbox_updated RENAME TO live_location_outbox;
