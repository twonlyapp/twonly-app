-- A decryption error proves the peer received the uploaded attachment's
-- envelope. Retry its retained plaintext without requiring the source file
-- again. Keep session deferral and resend cooldowns until repair completes.
UPDATE receipts
SET will_be_retried_by_media_upload = 0
WHERE will_be_retried_by_media_upload = 1
  AND decryption_failures > 0;
