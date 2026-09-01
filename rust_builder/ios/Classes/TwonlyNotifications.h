#ifndef TWONLY_NOTIFICATIONS_H
#define TWONLY_NOTIFICATIONS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

char *twonly_notification_process(
    const char *database_dir,
    const char *data_dir,
    const char *locale,
    uint64_t deadline_ms
);

char *twonly_notification_acknowledge(const char *event_ids_json);

void twonly_notification_string_free(char *pointer);

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

#ifdef __cplusplus
}
#endif

#endif
