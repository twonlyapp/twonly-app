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

/* One deadline and owner across process/render/acknowledge/finalize. Create
   before queueing. Finish also cancels/drains runs that never processed. */
uint64_t twonly_notification_run_create(uint64_t budget_ms);
char *twonly_notification_process_with_id(
    uint64_t run,
    const char *database_dir,
    const char *data_dir,
    const char *locale,
    uint64_t deadline_ms
);
char *twonly_notification_acknowledge_with_id(uint64_t run, const char *event_ids_json);
char *twonly_notification_finalize_with_id(uint64_t run, uint64_t deadline_ms);
void twonly_notification_run_finish(uint64_t run);

void twonly_notification_string_free(char *pointer);

/* Opaque render generation; missing/finished jobs are cancelled. */
bool twonly_video_is_cancelled(const char *job_id);

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

uint64_t twonly_background_run_create(void);
uint64_t twonly_backup_run_create(void);
char *twonly_backup_run_with_id(
    uint64_t run,
    const char *database_dir,
    const char *data_dir
);
void twonly_background_run_dispose(uint64_t run);
char *twonly_background_run_with_id(
    uint64_t run,
    const char *database_dir,
    const char *data_dir,
    const char *media_id
);

/* Requests cancellation; the owned worker acknowledges completion only after
   native SQLite and connection cleanup have finished. Safe from any thread. */
void twonly_database_operation_cancel(uint64_t operation);

/* Nonblocking scene/application state notification; cleanup is owned by Rust. */
void twonly_database_set_foreground(bool active);

/* Wakes foreground reconciliation after a native media request finishes.
   Returns false when no Flutter runtime is available; durable maintenance
   still owns recovery. HTTP success alone never acknowledges the media. */
bool twonly_direct_media_transfer_finished(void);

#ifdef __cplusplus
}
#endif

#endif
