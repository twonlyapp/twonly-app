import 'dart:convert' show utf8;
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/core/bridge.dart' as bridge;
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/callbacks/callbacks.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as api_pb;
import 'package:twonly/src/services/api/api.service.dart';
import 'package:twonly/src/services/passwordless_recovery.service.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';

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
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
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

    locator
      ..registerSingleton<TwonlyDB>(
        TwonlyDB(NativeDatabase(dbFile)),
      )
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

    await createIfNotExistsSignalIdentity();
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

  Future<void> setupSignalSession(int contactId) async {
    final identityKeyPair = generateIdentityKeyPair();
    final registrationId = generateRegistrationId(true);
    final signedPreKey = generateSignedPreKey(identityKeyPair, 1);
    final preKey = generatePreKeys(1, 1).first;

    final responseUserData = api_pb.Response_UserData()
      ..userId = Int64(contactId)
      ..username = utf8.encode('user_$contactId')
      ..registrationId = Int64(registrationId)
      ..publicIdentityKey = identityKeyPair.getPublicKey().serialize()
      ..signedPrekey = signedPreKey.getKeyPair().publicKey.serialize()
      ..signedPrekeyId = Int64(signedPreKey.id)
      ..signedPrekeySignature = signedPreKey.signature;

    responseUserData.prekeys.add(
      api_pb.Response_PreKey()
        ..id = Int64(preKey.id)
        ..prekey = preKey.getKeyPair().publicKey.serialize(),
    );

    final success = await processSignalUserData(responseUserData);
    expect(success, isTrue);
  }

  group('PasswordlessRecoveryService - enablePasswordlessRecovery', () {
    test('works with SecondFactorType.none', () async {
      await twonlyDB.contactsDao.insertContact(
        ContactsCompanion.insert(userId: const Value(2), username: 'friend_2'),
      );
      await twonlyDB.contactsDao.insertContact(
        ContactsCompanion.insert(userId: const Value(3), username: 'friend_3'),
      );

      final success =
          await PasswordlessRecoveryService.enablePasswordlessRecovery(
            trustedFriendIds: [2, 3],
            secondFactorType: SecondFactorType.none,
            secondFactorValue: '',
            threshold: 2,
          );

      expect(success, isTrue);

      final c2 = await twonlyDB.contactsDao.getContactById(2);
      final c3 = await twonlyDB.contactsDao.getContactById(3);

      expect(c2?.recoveryIsTrustedFriend, isTrue);
      expect(c3?.recoveryIsTrustedFriend, isTrue);
      expect(c2?.recoverySecretShare, isNotNull);
      expect(c3?.recoverySecretShare, isNotNull);
      expect(c2?.recoveryLastHeartbeat, isNull);
      expect(c3?.recoveryLastHeartbeat, isNull);
    });

    test('works with SecondFactorType.email', () async {
      await twonlyDB.contactsDao.insertContact(
        ContactsCompanion.insert(userId: const Value(2), username: 'friend_2'),
      );

      final success =
          await PasswordlessRecoveryService.enablePasswordlessRecovery(
            trustedFriendIds: [2],
            secondFactorType: SecondFactorType.email,
            secondFactorValue: 'a_very_long_email_addr@gmail.com',
            threshold: 1,
          );

      expect(success, isTrue);

      final c2 = await twonlyDB.contactsDao.getContactById(2);
      expect(c2?.recoveryIsTrustedFriend, isTrue);
      expect(c2?.recoverySecretShare, isNotNull);
    });

    test('works with SecondFactorType.pin', () async {
      await twonlyDB.contactsDao.insertContact(
        ContactsCompanion.insert(userId: const Value(2), username: 'friend_2'),
      );

      final success =
          await PasswordlessRecoveryService.enablePasswordlessRecovery(
            trustedFriendIds: [2],
            secondFactorType: SecondFactorType.pin,
            secondFactorValue: '123456',
            threshold: 1,
          );

      expect(success, isTrue);

      final c2 = await twonlyDB.contactsDao.getContactById(2);
      expect(c2?.recoveryIsTrustedFriend, isTrue);
      expect(c2?.recoverySecretShare, isNotNull);
    });

    test('sends delete messages to old trusted friends', () async {
      await twonlyDB.contactsDao.insertContact(
        ContactsCompanion.insert(
          userId: const Value(2),
          username: 'friend_2',
          recoveryIsTrustedFriend: const Value(true),
        ),
      );
      await twonlyDB.contactsDao.insertContact(
        ContactsCompanion.insert(userId: const Value(3), username: 'friend_3'),
      );

      await setupSignalSession(2);
      await setupSignalSession(3);

      final success =
          await PasswordlessRecoveryService.enablePasswordlessRecovery(
            trustedFriendIds: [3],
            secondFactorType: SecondFactorType.none,
            secondFactorValue: '',
            threshold: 1,
          );

      expect(success, isTrue);

      // Verify old friend got a delete message

      final oldFriend = await twonlyDB.contactsDao.getContactById(2);
      expect(oldFriend?.recoveryIsTrustedFriend, isFalse);
    });
  });
}
