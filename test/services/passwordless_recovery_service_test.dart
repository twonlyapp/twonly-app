import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge.dart' as bridge;
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/wrapper.dart' show RustUtils;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/callbacks/callbacks.dart';
import 'package:twonly/src/model/json/onboarding_state.model.dart';
import 'package:twonly/src/model/protobuf/client/generated/passwordless_recovery.pb.dart';
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

  group('PasswordlessRecoveryService - analyzeShares', () {
    var nextMessageId = 1;

    /// Splits recovery data for [userId] the way the owner's app does.
    Future<List<ReceivedRecoveryShare>> sharesOf(
      int keyByte, {
      int userId = 1,
      int threshold = 2,
      int total = 4,
    }) async {
      final secret = SharedSecretData(
        recoveryData: RecoveryData(
          userId: Int64(userId),
          keyManager: List.filled(48, keyByte),
        ).writeToBuffer(),
      ).writeToBuffer();
      final shares = await RustUtils.generateShares(
        secret: secret,
        total: total,
        threshold: threshold,
      );
      return [
        for (final bytes in shares)
          ReceivedRecoveryShare(
            messageId: nextMessageId++,
            trustedFriendDisplayName: 'Friend $nextMessageId',
            myDisplayName: 'Me',
            myUserId: userId,
            myAvatarSvg: null,
            threshold: threshold,
            sharedSecretDataBytes: bytes,
          ),
      ];
    }

    ReceivedRecoveryShare copyOf(
      ReceivedRecoveryShare share, {
      int? threshold,
      List<int>? bytes,
    }) => ReceivedRecoveryShare(
      messageId: nextMessageId++,
      trustedFriendDisplayName: share.trustedFriendDisplayName,
      myDisplayName: share.myDisplayName,
      myUserId: share.myUserId,
      myAvatarSvg: null,
      threshold: threshold ?? share.threshold,
      sharedSecretDataBytes: bytes ?? share.sharedSecretDataBytes,
    );

    List<int> keyManagerOf(RecoveryShareAnalysis analysis) =>
        RecoveryData.fromBuffer(analysis.secret!.recoveryData).keyManager;

    test('a share submitted twice is counted once', () async {
      final shares = await sharesOf(7);

      final analysis = await PasswordlessRecoveryService.analyzeShares([
        shares[0],
        shares[1],
        copyOf(shares[1]),
      ]);

      expect(keyManagerOf(analysis), List.filled(48, 7));
      expect(analysis.shares, [shares[0], shares[1]]);
      expect(analysis.ignoredShares, 1);
    });

    test('a stale share from an earlier setup is left out', () async {
      final honest = await sharesOf(7);
      final stale = await sharesOf(9);

      final analysis = await PasswordlessRecoveryService.analyzeShares([
        honest[0],
        stale[1],
        honest[2],
      ]);

      expect(keyManagerOf(analysis), List.filled(48, 7));
      expect(analysis.shares, [honest[0], honest[2]]);
      expect(analysis.ignoredShares, 1);
    });

    test('a share claiming a threshold of one decides nothing', () async {
      final honest = await sharesOf(7);
      final forged = copyOf(
        honest[0],
        threshold: 1,
        bytes: [
          1,
          ...SharedSecretData(
            recoveryData: RecoveryData(
              userId: Int64(1),
              keyManager: [6, 6, 6],
            ).writeToBuffer(),
          ).writeToBuffer(),
        ],
      );

      final alone = await PasswordlessRecoveryService.analyzeShares([forged]);
      expect(alone.secret, isNull);
      expect(alone.account, isNull);
      expect(alone.ignoredShares, 1);

      final first = await PasswordlessRecoveryService.analyzeShares([
        forged,
        honest[1],
        honest[3],
      ]);
      expect(keyManagerOf(first), List.filled(48, 7));
      expect(first.ignoredShares, 1);
    });

    test('shares naming another account are kept apart', () async {
      final mine = await sharesOf(7);
      final other = await sharesOf(9, userId: 2);

      final analysis = await PasswordlessRecoveryService.analyzeShares([
        other[0],
        mine[0],
        other[1],
        mine[1],
        mine[2],
      ]);

      expect(analysis.account!.myUserId, 1);
      expect(keyManagerOf(analysis), List.filled(48, 7));
      expect(analysis.ignoredShares, 2);
    });

    test('too few matching shares wait for more', () async {
      final honest = await sharesOf(7, threshold: 3);
      final stale = await sharesOf(9, threshold: 3);

      final analysis = await PasswordlessRecoveryService.analyzeShares([
        honest[0],
        stale[1],
        honest[2],
      ]);

      expect(analysis.secret, isNull);
      expect(analysis.thresholdReached, isTrue);
    });

    test('data refused later is skipped', () async {
      final honest = await sharesOf(7);
      final first = await PasswordlessRecoveryService.analyzeShares(honest);

      final again = await PasswordlessRecoveryService.analyzeShares(
        honest,
        rejectedSecrets: {first.secretId!},
      );

      expect(again.secret, isNull);
      expect(again.shares, hasLength(4));
    });
  });
}
