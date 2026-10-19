#ifndef TWONLY_NOTIFICATIONS_H
#define TWONLY_NOTIFICATIONS_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Log arrival before scheduling the drain. Pass only the transport identifier;
   sent_at_ms is zero when the transport does not supply a send timestamp. */
void twonly_notification_received(
    const char *data_dir,
    const char *message_id,
    int64_t sent_at_ms
);

char *twonly_notification_process(
    const char *database_dir,
    const char *data_dir,
    const char *locale,
    uint64_t deadline_ms
);

char *twonly_notification_acknowledge(const char *event_ids_json);

/* Settles the work deferred behind the alert — media downloads, widget upkeep,
   and closing the background socket. Call it only after the batch from
   `twonly_notification_process` has been rendered; skipping it is safe. */
char *twonly_notification_finalize(uint64_t deadline_ms);

void twonly_notification_string_free(char *pointer);

/* Runs a native live-location state/update/stop operation. Release the JSON
   response with twonly_notification_string_free. No Flutter engine is needed. */
char *twonly_live_location_run(const char *directory, const char *request);

/* Runs one maintenance job: preparing a single media file when `media_id` is
   given, or resuming everything left in flight when it is NULL. Returns a JSON
   `{"ok":bool,"error":string?}` that must be released with
   `twonly_background_string_free`. */
char *twonly_background_run(
    const char *database_dir,
    const char *data_dir,
    const char *media_id
);

void twonly_background_string_free(char *pointer);

/* Wakes foreground reconciliation after a native media request finishes.
   Returns false when no Flutter runtime is available; durable maintenance
   still owns recovery. HTTP success alone never acknowledges the media. */
bool twonly_direct_media_transfer_finished(void);

#ifdef __cplusplus
}
#endif

#endif
