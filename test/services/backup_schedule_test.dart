import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/services/backup/backup_schedule.dart';

void main() {
  test('forced intent survives a scheduler restart until completion', () async {
    var persisted = false;
    var visible = false;
    final calls = <bool>[];
    BackupSchedule create() => BackupSchedule(
      isVisible: () => visible,
      loadForced: () async => persisted,
      saveForced: (force) async => persisted = force,
      perform: (force) async {
        calls.add(force);
        return true;
      },
    );
    await create().request(force: true);
    expect(persisted, isTrue);
    visible = true;
    await create().resume();
    expect(calls, [true]);
    expect(persisted, isFalse);
    await create().resume();
    expect(calls, [true]);
  });

  test(
    'a new forced request is retained while an older run finishes',
    () async {
      var persisted = false;
      var visible = true;
      final started = Completer<void>();
      final finish = Completer<void>();
      final schedule = BackupSchedule(
        isVisible: () => visible,
        loadForced: () async => persisted,
        saveForced: (force) async => persisted = force,
        perform: (force) async {
          started.complete();
          await finish.future;
          return true;
        },
      );
      final run = schedule.request(force: true);
      await started.future;
      visible = false;
      await schedule.request(force: true);
      finish.complete();
      await run;
      expect(persisted, isTrue);
    },
  );

  test('storage failures prevent work and remain retryable', () async {
    var fail = true;
    var calls = 0;
    final schedule = BackupSchedule(
      isVisible: () => true,
      saveForced: (_) async {
        if (fail) throw StateError('storage unavailable');
      },
      perform: (_) async {
        calls++;
        return true;
      },
    );
    await expectLater(schedule.request(force: true), throwsStateError);
    expect(calls, 0);
    fail = false;
    await schedule.request(force: true);
    expect(calls, 1);
  });

  test(
    'background requests coalesce and preserve force until resume',
    () async {
      var visible = false;
      final calls = <bool>[];
      final schedule = BackupSchedule(
        isVisible: () => visible,
        perform: (force) async {
          calls.add(force);
          return true;
        },
      );
      await schedule.request();
      await schedule.request(force: true);
      await schedule.request();
      expect(calls, isEmpty);
      visible = true;
      await schedule.resume();
      await schedule.resume();
      expect(calls, [true]);
    },
  );

  test(
    'requests arriving during a run wait for the next visible session',
    () async {
      var visible = true;
      final started = Completer<void>();
      final finish = Completer<void>();
      final calls = <bool>[];
      final schedule = BackupSchedule(
        isVisible: () => visible,
        perform: (force) async {
          calls.add(force);
          if (calls.length == 1) {
            started.complete();
            await finish.future;
          }
          return true;
        },
      );
      final first = schedule.request();
      await started.future;
      visible = false;
      await schedule.request(force: true);
      finish.complete();
      await first;
      expect(calls, [false]);
      visible = true;
      await schedule.resume();
      expect(calls, [false, true]);
    },
  );

  test('failed admission retains the forced request for resume', () async {
    var fail = true;
    final calls = <bool>[];
    final schedule = BackupSchedule(
      isVisible: () => true,
      perform: (force) async {
        if (fail) throw StateError('native admission was denied');
        calls.add(force);
        return true;
      },
    );
    await expectLater(schedule.request(force: true), throwsStateError);
    fail = false;
    await schedule.resume();
    expect(calls, [true]);
  });

  test(
    'native deferral preserves force without an immediate retry loop',
    () async {
      var allowed = false;
      final calls = <bool>[];
      final schedule = BackupSchedule(
        isVisible: () => true,
        perform: (force) async {
          calls.add(force);
          return allowed;
        },
      );
      await schedule.request(force: true);
      expect(calls, [true]);
      allowed = true;
      await schedule.resume();
      expect(calls, [true, true]);
    },
  );
}
