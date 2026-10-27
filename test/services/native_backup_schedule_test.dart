import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/services/backup/native_backup_schedule.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('eu.twonly/backup_schedule');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'reads the native reservation and converts its timestamp to local time',
    () async {
      final earliest = DateTime.utc(2030, 10, 23, 18, 30);
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'getSchedule');
        return {
          'state': 'scheduled',
          'earliestStartMillis': earliest.millisecondsSinceEpoch,
        };
      });

      final schedule = await NativeBackupScheduler.getSchedule();
      expect(schedule.state, NativeBackupScheduleState.scheduled);
      expect(schedule.earliestStart, earliest.toLocal());
      expect(schedule.earliestStart!.isUtc, isFalse);
    },
  );

  test(
    'retains system restrictions even when a job is still scheduled',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {
          'state': 'scheduled',
          'executionAllowed': false,
        },
      );
      final schedule = await NativeBackupScheduler.getSchedule();
      expect(schedule.state, NativeBackupScheduleState.scheduled);
      expect(schedule.executionAllowed, isFalse);
    },
  );

  test('queries again so retry backoff changes are reflected', () async {
    var millis = DateTime.utc(2030).millisecondsSinceEpoch;
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {
        'state': 'scheduled',
        'earliestStartMillis': millis,
      },
    );
    final first = await NativeBackupScheduler.getSchedule();
    millis += const Duration(minutes: 15).inMilliseconds;
    final retry = await NativeBackupScheduler.getSchedule();
    expect(
      retry.earliestStart!.difference(first.earliestStart!),
      const Duration(minutes: 15),
    );
  });

  test(
    'distinguishes pending without a date, running, and unscheduled work',
    () async {
      for (final entry in {
        'scheduled': NativeBackupScheduleState.scheduled,
        'running': NativeBackupScheduleState.running,
        'notScheduled': NativeBackupScheduleState.notScheduled,
      }.entries) {
        messenger.setMockMethodCallHandler(
          channel,
          (_) async => {
            'state': entry.key,
            'earliestStartMillis': null,
          },
        );
        final schedule = await NativeBackupScheduler.getSchedule();
        expect(schedule.state, entry.value);
        expect(schedule.earliestStart, isNull);
      }
    },
  );

  test(
    'query failures are unavailable, rather than reporting no pending job',
    () async {
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(code: 'schedule_unavailable');
      });
      expect(
        (await NativeBackupScheduler.getSchedule()).state,
        NativeBackupScheduleState.unavailable,
      );
      messenger.setMockMethodCallHandler(channel, null);
      expect(
        (await NativeBackupScheduler.getSchedule()).state,
        NativeBackupScheduleState.unavailable,
      );
    },
  );
}
