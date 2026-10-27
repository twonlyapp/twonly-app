import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/model/json/backup.model.dart';
import 'package:twonly/src/services/backup/backup_fallback_policy.dart';
import 'package:twonly/src/services/backup/native_backup_schedule.dart';

void main() {
  final now = DateTime.utc(2030, 10, 23, 12);
  const scheduled = NativeBackupSchedule(
    state: NativeBackupScheduleState.scheduled,
  );

  CurrentBackupStatus status({int archiveHours = 1, int identityDays = 1}) =>
      CurrentBackupStatus()
        ..archiveState = LastBackupUploadState.success
        ..archiveLastSuccessFull = now.subtract(Duration(hours: archiveHours))
        ..identityState = LastBackupUploadState.success
        ..identityLastSuccessFull = now.subtract(Duration(days: identityDays));

  bool fallback(
    CurrentBackupStatus backup, {
    NativeBackupSchedule schedule = scheduled,
    DateTime? since,
  }) => BackupFallbackPolicy.shouldRun(
    backup: backup,
    schedule: schedule,
    now: now,
    monitoringSince: since ?? now,
  );

  test(
    'healthy schedules retain ordinary due backups during the grace period',
    () {
      expect(fallback(status(archiveHours: 25, identityDays: 7)), isFalse);
      expect(fallback(status(archiveHours: 47)), isFalse);
    },
  );

  test(
    'overdue backups trigger a fallback even if a pending job still exists',
    () {
      expect(fallback(status(archiveHours: 48)), isTrue);
      expect(fallback(status(identityDays: 8)), isTrue);
    },
  );

  for (final state in [
    NativeBackupScheduleState.notScheduled,
    NativeBackupScheduleState.unavailable,
  ]) {
    test('$state triggers only due uploads', () {
      final schedule = NativeBackupSchedule(state: state);
      expect(fallback(status(), schedule: schedule), isFalse);
      expect(fallback(status(archiveHours: 25), schedule: schedule), isTrue);
    });
  }

  test(
    'system restrictions trigger a due backup without waiting for staleness',
    () {
      const restricted = NativeBackupSchedule(
        state: NativeBackupScheduleState.scheduled,
        executionAllowed: false,
      );
      expect(fallback(status(), schedule: restricted), isFalse);
      expect(fallback(status(archiveHours: 25), schedule: restricted), isTrue);
    },
  );

  test('failed uploads retry but a recently interrupted upload can wait', () {
    for (final identity in [false, true]) {
      final backup = status();
      if (identity) {
        backup.identityState = LastBackupUploadState.failed;
      } else {
        backup.archiveState = LastBackupUploadState.failed;
      }
      expect(fallback(backup), isTrue);
    }
    expect(
      fallback(status()..archiveState = LastBackupUploadState.pending),
      isFalse,
    );
  });

  test('running native work is never duplicated, even when overdue', () {
    expect(
      fallback(
        status(archiveHours: 100),
        schedule: const NativeBackupSchedule(
          state: NativeBackupScheduleState.running,
        ),
      ),
      isFalse,
    );
  });

  test('never-completed backups receive a durable initial grace period', () {
    final backup = CurrentBackupStatus();
    expect(fallback(backup), isFalse);
    expect(
      fallback(backup, since: now.subtract(const Duration(hours: 47))),
      isFalse,
    );
    expect(
      fallback(backup, since: now.subtract(const Duration(hours: 48))),
      isTrue,
    );
  });
}
