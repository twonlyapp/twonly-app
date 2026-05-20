import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge.dart' as bridge;
import 'package:twonly/core/bridge/wrapper/backup.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/callbacks/callbacks.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/backup.model.dart';
import 'package:twonly/src/model/json/userdata.model.dart'
    hide LastBackupUploadState;
import 'package:twonly/src/services/api.service.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';

void main() {
  if (!Platform.isMacOS) {
    return;
  }

  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Map<String, dynamic> initialUserData;

  setUpAll(() async {
    const channel = MethodChannel('com.bbflight.background_downloader');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          if (methodCall.method == 'enqueue') {
            return true;
          }
          return null;
        });

    final dylibPath =
        '${Directory.current.path}/rust/target/debug/librust_lib_twonly.dylib';
    if (File(dylibPath).existsSync()) {
      await RustLib.init(
        externalLibrary: ExternalLibrary.open(dylibPath),
      );
    } else {
      await RustLib.init();
    }
    await initFlutterCallbacksForRust();

    tempDir = Directory.systemTemp.createTempSync('twonly_backup_test_');
    AppEnvironment.initTesting(
      customCacheDir: tempDir.path,
      customSupportDir: tempDir.path,
    );

    await bridge.initializeTwonlyFlutter(
      config: bridge.InitConfig(
        databaseDir: tempDir.path,
        dataDir: tempDir.path,
      ),
    );
  });

  setUp(() async {
    await locator.reset();
    final dbFile = File('${tempDir.path}/twonly.sqlite');
    locator
      ..registerSingleton<TwonlyDB>(
        TwonlyDB(NativeDatabase(dbFile)),
      )
      ..registerSingleton<UserService>(UserService())
      ..registerSingleton<ApiService>(ApiService());

    userService.currentUser = UserData(
      userId: 1,
      username: 'test_user',
      displayName: 'Test User',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
      appVersion: 100,
    );
    userService.isUserCreated = true;
    await UserService.save(userService.currentUser);
    initialUserData = (await KeyValueStore.get('user'))!;

    await RustBackupIdentity.setBackupPasswordKeys(
      password: 'strong_password',
      userId: 1,
    );
  });

  tearDown(() async {
    try {
      await twonlyDB.close();
    } catch (_) {}
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('BackupService Tests', () {
    test('getData returns default backup status initially', () async {
      final data = await BackupService.getData();
      expect(data.identityState, LastBackupUploadState.none);
      expect(data.archiveState, LastBackupUploadState.none);
      expect(data.identityLastSuccessFull, isNull);
      expect(data.archiveLastSuccessFull, isNull);
    });

    test(
      'onBackupUpdated stream emits events when backup status changes',
      () async {
        var eventEmitted = false;
        final subscription = BackupService.onBackupUpdated.listen((_) {
          eventEmitted = true;
        });

        final dummyTask = UploadTask(url: 'http://localhost', filename: 'test');
        await BackupService.handleBackupStatusUpdate(
          'backup_identity',
          TaskStatusUpdate(dummyTask, TaskStatus.complete),
        );

        await Future.delayed(Duration.zero);
        expect(eventEmitted, isTrue);
        await subscription.cancel();
      },
    );

    test(
      'handleBackupStatusUpdate updates identity and archive status correctly',
      () async {
        // Test success update for identity status
        final dummyTask1 = UploadTask(
          url: 'http://localhost',
          filename: 'test',
        );
        await BackupService.handleBackupStatusUpdate(
          'backup_identity',
          TaskStatusUpdate(dummyTask1, TaskStatus.complete),
        );

        var data = await BackupService.getData();
        expect(data.identityState, LastBackupUploadState.success);
        expect(data.identityLastSuccessFull, isNotNull);

        // Test failure update for archive status
        final dummyTask2 = UploadTask(
          url: 'http://localhost',
          filename: 'test',
        );
        await BackupService.handleBackupStatusUpdate(
          'backup_archive',
          TaskStatusUpdate(dummyTask2, TaskStatus.failed),
        );

        data = await BackupService.getData();
        expect(data.archiveState, LastBackupUploadState.failed);
        expect(data.archiveLastSuccessFull, isNotNull);
      },
    );

    test(
      'startFullBackupRecovery returns usernameNotValid for offline/unknown user',
      () async {
        final error = await BackupService.startFullBackupRecovery(
          'unknown_user',
          'password',
        );
        expect(error, RecoveryError.usernameNotValid);
      },
    );

    test(
      'Full backup recovery flow restores identity and user.json archive successfully',
      () async {
        final initialBackupIdStr = await RustBackupIdentity.getBackupId();

        // 1. Create backups of baseline state purely natively to avoid background backup races
        final identityBytes = await RustBackupIdentity.getIdentityBackupBytes();
        final (_, archivePath) = await RustBackupArchive.createBackupArchive();

        // 2. Tamper with user.json data and verify alteration
        await KeyValueStore.put(
          'user',
          {'changed': true, 'username': 'tampered'},
        );

        final changedUserData = await KeyValueStore.get('user');
        expect(changedUserData?['changed'], isTrue);

        // 3. Trigger a change of the key_manager before restoring
        await RustBackupIdentity.importBackupPasswordKeys(
          backupId: List.filled(32, 1),
          encryptionKey: List.filled(32, 1),
        );

        final changedBackupIdStr = await RustBackupIdentity.getBackupId();
        expect(changedBackupIdStr, isNot(equals(initialBackupIdStr)));

        // 4. Restore identity and archive
        final backupKeys = await RustBackupIdentity.getBackupPasswordKeys(
          userId: 1,
          password: 'strong_password',
        );
        await RustBackupIdentity.restoreIdentityBackup(
          keys: backupKeys,
          encryptedBytes: identityBytes,
        );

        await RustBackupArchive.restoreBackupArchive(filePath: archivePath);

        final restoredBackupIdStr = await RustBackupIdentity.getBackupId();
        expect(restoredBackupIdStr, equals(initialBackupIdStr));

        // 5. Verify user.json data is fully restored
        final restoredUserData = await KeyValueStore.get('user');
        expect(
          restoredUserData?['username'],
          equals(initialUserData['username']),
        );
      },
    );
  });
}
