import 'package:twonly/src/model/json/backup.model.dart';
import 'package:twonly/src/services/backup/native_backup_schedule.dart';

/// Give the OS one extra day beyond the usual daily/weekly upload cadence.
/// A pending job by itself does not prove that background execution works.
class BackupFallbackPolicy {
  static const archiveInterval = Duration(days: 1);
  static const identityInterval = Duration(days: 7);
  static const backgroundGrace = Duration(days: 1);

  static bool shouldRun({
    required CurrentBackupStatus backup,
    required NativeBackupSchedule schedule,
    required DateTime now,
    required DateTime monitoringSince,
  }) {
    if (schedule.state == NativeBackupScheduleState.running) return false;

    bool due(LastBackupUploadState state, DateTime? last, Duration interval) =>
        state != LastBackupUploadState.success ||
        last == null ||
        now.difference(last) > interval;

    final archiveDue = due(
      backup.archiveState,
      backup.archiveLastSuccessFull,
      archiveInterval,
    );
    final identityDue = due(
      backup.identityState,
      backup.identityLastSuccessFull,
      identityInterval,
    );
    if (!archiveDue && !identityDue) return false;

    if (!schedule.executionAllowed ||
        schedule.state == NativeBackupScheduleState.notScheduled ||
        schedule.state == NativeBackupScheduleState.unavailable ||
        backup.archiveState == LastBackupUploadState.failed ||
        backup.identityState == LastBackupUploadState.failed) {
      return true;
    }

    bool overdue(DateTime? last, Duration interval) =>
        now.difference(last ?? monitoringSince) >= interval + backgroundGrace;

    return (archiveDue &&
            overdue(backup.archiveLastSuccessFull, archiveInterval)) ||
        (identityDue &&
            overdue(backup.identityLastSuccessFull, identityInterval));
  }
}
