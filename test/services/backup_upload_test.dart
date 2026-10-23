import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/model/json/backup.model.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';

import '../mocks/user_config.dart';

class _BackupApi implements RustLibApi {
  final calls = <bool>[];
  Future<bool> Function(bool)? upload;

  @override
  Future<bool> crateBridgeWrapperBackupRustBackupArchiveUploadBackup({
    required bool force,
  }) async {
    calls.add(force);
    return upload?.call(force) ?? true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('eu.twonly/backup_schedule');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final api = _BackupApi();
  late Directory directory;
  final retryTimers = <Timer>[];

  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() async {
    AppState.isAppInBackground = false;
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {'state': 'scheduled'},
    );
    await locator.reset();
    locator.registerSingleton<UserService>(
      UserService()
        ..isUserCreated = true
        ..currentUser = (testUserConfig(
          userId: 1,
          username: 'backup',
          displayName: 'Backup',
          subscriptionPlan: 'Free',
          currentSetupPage: null,
          appVersion: 1,
        )..isBackupEnabled = true),
    );
    api.calls.clear();
    api.upload = null;
    directory = Directory.systemTemp.createTempSync('twonly-backup-upload-');
    AppEnvironment.initTesting(
      customCacheDir: directory.path,
      customSupportDir: directory.path,
    );
  });

  tearDown(() async {
    AppState.isAppInBackground = true;
    messenger.setMockMethodCallHandler(channel, null);
    for (final timer in retryTimers) {
      timer.cancel();
    }
    retryTimers.clear();
    await directory.delete(recursive: true);
  });

  Future<void> request({bool force = false}) => runZoned(
    () => BackupService.makeBackup(force: force),
    zoneSpecification: ZoneSpecification(
      createTimer: (self, parent, zone, duration, callback) {
        final timer = parent.createTimer(zone, duration, callback);
        if (duration == const Duration(minutes: 15)) retryTimers.add(timer);
        return timer;
      },
    ),
  );

  test('explicit requests wait for resume and preserve force', () async {
    AppState.isAppInBackground = true;
    await request(force: true);
    expect(api.calls, isEmpty);
    AppState.isAppInBackground = false;
    await BackupService.resumePendingBackup();
    expect(api.calls, [true]);
  });

  test('manual backups delegate to the shared native uploader', () async {
    await request(force: true);
    expect(api.calls, [true]);
    expect(
      (await KeyValueStore.get(KeyValueKeys.forcedBackupPending))?['pending'],
      isFalse,
    );
  });

  test(
    'native failures retain forced intent and schedule another attempt',
    () async {
      api.upload = (_) async => false;
      await request(force: true);
      expect(retryTimers, hasLength(1));
      expect(
        (await KeyValueStore.get(KeyValueKeys.forcedBackupPending))?['pending'],
        isTrue,
      );
      api.upload = (_) async => true;
      await BackupService.resumePendingBackup();
      expect(api.calls, [true, true]);
      expect(
        (await KeyValueStore.get(KeyValueKeys.forcedBackupPending))?['pending'],
        isFalse,
      );
    },
  );

  test('native cancellation leaves the request retryable', () async {
    api.upload = (_) async => throw StateError('cancelled');
    await request(force: true);
    expect(retryTimers, hasLength(1));
    api.upload = (_) async => true;
    await BackupService.resumePendingBackup();
    expect(api.calls, [true, true]);
  });

  test('backups stay disabled while recovery is pending', () async {
    await KeyValueStore.put(KeyValueKeys.backupRecoveryState, {
      'username': 'backup',
      'password': 'password',
      'userId': 1,
      'state': 'identityBackupStarted',
    });
    await request();
    expect(api.calls, isEmpty);
    await KeyValueStore.delete(KeyValueKeys.backupRecoveryState);
    await BackupService.resumePendingBackup();
    expect(api.calls, [false]);
  });

  test('disabled backups do not call native uploads', () async {
    userService.currentUser.isBackupEnabled = false;
    await request(force: true);
    expect(api.calls, isEmpty);
  });
  Future<void> saveStatus(DateTime now, {int archiveHours = 1}) =>
      KeyValueStore.put(
        KeyValueKeys.currentBackupState,
        (CurrentBackupStatus()
              ..identityState = LastBackupUploadState.success
              ..identityLastSuccessFull = now.subtract(const Duration(days: 1))
              ..archiveState = LastBackupUploadState.success
              ..archiveLastSuccessFull = now.subtract(
                Duration(hours: archiveHours),
              ))
            .toJson(),
      );

  test(
    'startup leaves routine due uploads to a healthy background job',
    () async {
      final now = DateTime.utc(2030, 10, 23);
      await saveStatus(now, archiveHours: 25);
      await withClock(
        Clock.fixed(now),
        BackupService.checkStartupBackupFallback,
      );
      expect(api.calls, isEmpty);
    },
  );

  test(
    'startup runs an overdue backup in the foreground without forcing fresh uploads',
    () async {
      final now = DateTime.utc(2030, 10, 23);
      await saveStatus(now, archiveHours: 48);
      await withClock(
        Clock.fixed(now),
        BackupService.checkStartupBackupFallback,
      );
      expect(api.calls, [false]);
    },
  );

  test('a due backup falls back if the native scheduler is missing', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {'state': 'notScheduled'},
    );
    final now = DateTime.utc(2030, 10, 23);
    await saveStatus(now, archiveHours: 25);
    await withClock(Clock.fixed(now), BackupService.checkStartupBackupFallback);
    expect(api.calls, [false]);
  });

  test('backgrounded startup defers its fallback check until resume', () async {
    final now = DateTime.utc(2030, 10, 23);
    await saveStatus(now, archiveHours: 48);
    AppState.isAppInBackground = true;
    await withClock(Clock.fixed(now), BackupService.checkStartupBackupFallback);
    expect(api.calls, isEmpty);
    AppState.isAppInBackground = false;
    await withClock(Clock.fixed(now), BackupService.resumePendingBackup);
    expect(api.calls, [false]);
    await withClock(Clock.fixed(now), BackupService.resumePendingBackup);
    expect(api.calls, [false]);
  });

  test(
    'a pause during the OS query rechecks current backup status on resume',
    () async {
      final now = DateTime.utc(2030, 10, 23);
      await saveStatus(now, archiveHours: 48);
      messenger.setMockMethodCallHandler(channel, (_) async {
        AppState.isAppInBackground = true;
        return {'state': 'scheduled'};
      });
      await withClock(
        Clock.fixed(now),
        BackupService.checkStartupBackupFallback,
      );
      expect(api.calls, isEmpty);
      // The native worker succeeds before the next foreground session.
      await saveStatus(now);
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {'state': 'scheduled'},
      );
      AppState.isAppInBackground = false;
      await withClock(Clock.fixed(now), BackupService.resumePendingBackup);
      expect(api.calls, isEmpty);
    },
  );

  test(
    'startup preserves the initial grace period across repeated launches',
    () async {
      final now = DateTime.utc(2030, 10, 23);
      await withClock(
        Clock.fixed(now),
        BackupService.checkStartupBackupFallback,
      );
      expect(api.calls, isEmpty);
      await withClock(
        Clock.fixed(now.add(const Duration(hours: 47))),
        BackupService.checkStartupBackupFallback,
      );
      expect(api.calls, isEmpty);
      final stored = await KeyValueStore.get(
        KeyValueKeys.backupFallbackMonitoring,
      );
      expect(stored?['since'], now.toIso8601String());
      await withClock(
        Clock.fixed(now.add(const Duration(hours: 48))),
        BackupService.checkStartupBackupFallback,
      );
      expect(api.calls, [false]);
    },
  );

  test(
    'startup never backs up disabled accounts or an active recovery',
    () async {
      userService.currentUser.isBackupEnabled = false;
      await BackupService.checkStartupBackupFallback();
      expect(api.calls, isEmpty);
      userService.currentUser.isBackupEnabled = true;
      await KeyValueStore.put(KeyValueKeys.backupRecoveryState, {
        'username': 'backup',
        'password': 'password',
        'userId': 1,
        'state': 'identityBackupStarted',
      });
      await BackupService.checkStartupBackupFallback();
      expect(api.calls, isEmpty);
    },
  );
  test(
    'a foreground request started during the startup check prevents another backup',
    () async {
      final now = DateTime.utc(2030, 10, 23);
      await saveStatus(now, archiveHours: 48);
      final queried = Completer<void>();
      final finishQuery = Completer<void>();
      messenger.setMockMethodCallHandler(channel, (_) async {
        queried.complete();
        await finishQuery.future;
        return {'state': 'scheduled'};
      });
      final fallback = withClock(
        Clock.fixed(now),
        BackupService.checkStartupBackupFallback,
      );
      await queried.future;
      await BackupService.makeBackup();
      finishQuery.complete();
      await fallback;
      expect(api.calls, [false]);
    },
  );
  test(
    'startup does not queue another upload behind a running foreground backup',
    () async {
      final now = DateTime.utc(2030, 10, 23);
      await saveStatus(now, archiveHours: 48);
      final started = Completer<void>();
      final finish = Completer<bool>();
      api.upload = (_) {
        started.complete();
        return finish.future;
      };
      final manual = BackupService.makeBackup();
      await started.future;
      await withClock(
        Clock.fixed(now),
        BackupService.checkStartupBackupFallback,
      );
      finish.complete(true);
      await manual;
      expect(api.calls, [false]);
    },
  );
}
