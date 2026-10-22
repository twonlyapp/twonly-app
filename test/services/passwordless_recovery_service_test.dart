import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge.dart' as bridge;
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/callbacks/callbacks.dart';
import 'package:twonly/src/services/api/api.service.dart';
import 'package:twonly/src/services/passwordless_recovery.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/log.dart';

import '../helpers/native_database.dart';
import '../mocks/platform_channels.dart';
import '../mocks/user_config.dart';

class MockApiService extends ApiService {}

void main() {
  if (!Platform.isMacOS) {
    return;
  }

  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    Log.init();
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

    tempDir = Directory.systemTemp.createTempSync('twonly_passwordless_test_');
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
    setupPlatformChannelMocks();
    await locator.reset();
    final dbFile = File('${tempDir.path}/twonly.sqlite');
    if (dbFile.existsSync()) {
      dbFile.deleteSync();
    }

    await TestDatabase.create();
    locator
      ..registerSingleton<UserService>(UserService())
      ..registerSingleton<ApiService>(MockApiService());

    userService.currentUser = testUserConfig(
      userId: 1,
      username: 'me',
      displayName: 'Me',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
      appVersion: 100,
    );
    userService.isUserCreated = true;
    await UserService.save(userService.currentUser);
  });

  tearDown(() async {
    try {} catch (_) {}
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('PasswordlessRecoveryService - enablePasswordlessRecovery', () {
    test('works with SecondFactorType.none', () async {
      await rust_contacts.upsertContact(
        patch: const ContactPatch(userId: 2, username: 'friend_2'),
        transaction: currentDatabaseSession(),
      );
      await rust_contacts.upsertContact(
        patch: const ContactPatch(userId: 3, username: 'friend_3'),
        transaction: currentDatabaseSession(),
      );

      final success =
          await PasswordlessRecoveryService.enablePasswordlessRecovery(
            trustedFriendIds: [2, 3],
            secondFactorType: SecondFactorType.none,
            secondFactorValue: '',
            threshold: 2,
          );

      expect(success, isTrue);

      final c2 = await rust_contacts.getContact(
        id: 2,
        transaction: currentDatabaseSession(),
      );
      final c3 = await rust_contacts.getContact(
        id: 3,
        transaction: currentDatabaseSession(),
      );

      expect(c2?.recoveryIsTrustedFriend, isTrue);
      expect(c3?.recoveryIsTrustedFriend, isTrue);
      expect(c2?.recoverySecretShare, isNotNull);
      expect(c3?.recoverySecretShare, isNotNull);
      expect(c2?.recoveryLastHeartbeat, isNull);
      expect(c3?.recoveryLastHeartbeat, isNull);
    });

    test('works with SecondFactorType.email', () async {
      await rust_contacts.upsertContact(
        patch: const ContactPatch(userId: 2, username: 'friend_2'),
        transaction: currentDatabaseSession(),
      );

      final success =
          await PasswordlessRecoveryService.enablePasswordlessRecovery(
            trustedFriendIds: [2],
            secondFactorType: SecondFactorType.email,
            secondFactorValue: 'a_very_long_email_addr@gmail.com',
            threshold: 1,
          );

      expect(success, isTrue);

      final c2 = await rust_contacts.getContact(
        id: 2,
        transaction: currentDatabaseSession(),
      );
      expect(c2?.recoveryIsTrustedFriend, isTrue);
      expect(c2?.recoverySecretShare, isNotNull);
    });

    test('works with SecondFactorType.pin', () async {
      await rust_contacts.upsertContact(
        patch: const ContactPatch(userId: 2, username: 'friend_2'),
        transaction: currentDatabaseSession(),
      );

      final success =
          await PasswordlessRecoveryService.enablePasswordlessRecovery(
            trustedFriendIds: [2],
            secondFactorType: SecondFactorType.pin,
            secondFactorValue: '123456',
            threshold: 1,
          );

      expect(success, isTrue);

      final c2 = await rust_contacts.getContact(
        id: 2,
        transaction: currentDatabaseSession(),
      );
      expect(c2?.recoveryIsTrustedFriend, isTrue);
      expect(c2?.recoverySecretShare, isNotNull);
    });

    test('sends delete messages to old trusted friends', () async {
      await rust_contacts.upsertContact(
        patch: const ContactPatch(
          userId: 2,
          username: 'friend_2',
          recoveryIsTrustedFriend: true,
        ),
        transaction: currentDatabaseSession(),
      );
      await rust_contacts.upsertContact(
        patch: const ContactPatch(userId: 3, username: 'friend_3'),
        transaction: currentDatabaseSession(),
      );

      final success =
          await PasswordlessRecoveryService.enablePasswordlessRecovery(
            trustedFriendIds: [3],
            secondFactorType: SecondFactorType.none,
            secondFactorValue: '',
            threshold: 1,
          );

      expect(success, isTrue);

      // Verify old friend got a delete message

      final oldFriend = await rust_contacts.getContact(
        id: 2,
        transaction: currentDatabaseSession(),
      );
      expect(oldFriend?.recoveryIsTrustedFriend, isFalse);
    });
  });
}
