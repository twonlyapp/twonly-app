// ignore_for_file: strict_raw_type

import 'dart:convert' show utf8;
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:crypto/crypto.dart';
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
import 'package:twonly/src/model/json/userdata.model.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as api_pb;
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/services/api.service.dart';
import 'package:twonly/src/services/api/utils.api.dart';
import 'package:twonly/src/services/passwordless_recovery.service.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';

import '../mocks/platform_channels.dart';

class MockApiService extends ApiService {
  final List<(List<int>, List<int>?)> registeredPasswordLessRecoveries = [];
  final List<(int, Uint8List, List<int>?)> sentTextMessages = [];

  @override
  Future<Result> registerPasswordLessRecovery(
    List<int> encryptedServerKey,
    List<int>? pinUnlockToken,
  ) async {
    registeredPasswordLessRecoveries.add((encryptedServerKey, pinUnlockToken));
    return Result.success(api_pb.Response_Ok());
  }

  @override
  Future<Result> sendTextMessage(
    int target,
    Uint8List msg,
    List<int>? pushData,
  ) async {
    sentTextMessages.add((target, msg, pushData));
    return Result.success(api_pb.Response_Ok());
  }

  @override
  Future<Result> updateSignedPreKey(
    int id,
    List<int> key,
    List<int> signature,
  ) async {
    return Result.success(api_pb.Response_Ok());
  }
}

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

    userService.currentUser = UserData(
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

      final mockApi = apiService as MockApiService;
      mockApi.sentTextMessages.clear();

      final success =
          await PasswordlessRecoveryService.enablePasswordlessRecovery(
            trustedFriendIds: [3],
            secondFactorType: SecondFactorType.none,
            secondFactorValue: '',
            threshold: 1,
          );

      expect(success, isTrue);

      // Verify old friend got a delete message
      expect(mockApi.sentTextMessages.isNotEmpty, isTrue);
      final deleteMsg = mockApi.sentTextMessages.firstWhere((t) => t.$1 == 2);
      expect(deleteMsg, isNotNull);

      final oldFriend = await twonlyDB.contactsDao.getContactById(2);
      expect(oldFriend?.recoveryIsTrustedFriend, isFalse);
    });
  });

  group('PasswordlessRecoveryService - performHeartbeat', () {
    test(
      'triggers server registration based on lastServerHeartbeat time',
      () async {
        final config = PasswordLessRecovery(3)
          ..encryptedServerKey = Uint8List.fromList([1, 2, 3])
          ..pinUnlockToken = Uint8List.fromList([4, 5, 6]);

        await UserService.update((u) => u.passwordLessRecovery = config);

        final mockApi = apiService as MockApiService;
        mockApi.registeredPasswordLessRecoveries.clear();

        // Case 1: lastServerHeartbeat is null -> should trigger registration
        await PasswordlessRecoveryService.performHeartbeat();
        expect(mockApi.registeredPasswordLessRecoveries.length, 1);
        expect(
          userService.currentUser.passwordLessRecovery?.lastServerHeartbeat,
          isNotNull,
        );

        // Case 2: lastServerHeartbeat is < 30 days old -> should not trigger
        mockApi.registeredPasswordLessRecoveries.clear();
        final now = clock.now();
        await UserService.update(
          (u) => u.passwordLessRecovery?.lastServerHeartbeat = now.subtract(
            const Duration(days: 15),
          ),
        );
        await PasswordlessRecoveryService.performHeartbeat();
        expect(mockApi.registeredPasswordLessRecoveries.length, 0);

        // Case 3: lastServerHeartbeat is > 30 days old -> should trigger
        await withClock(Clock.fixed(now), () async {
          await UserService.update(
            (u) => u.passwordLessRecovery?.lastServerHeartbeat = now.subtract(
              const Duration(days: 31),
            ),
          );
          await PasswordlessRecoveryService.performHeartbeat();
          expect(mockApi.registeredPasswordLessRecoveries.length, 1);
          expect(
            userService.currentUser.passwordLessRecovery?.lastServerHeartbeat,
            now,
          );
        });
      },
    );

    test(
      'sends secret shares to trusted friends with null recoveryLastHeartbeat',
      () async {
        final config = PasswordLessRecovery(3)
          ..encryptedServerKey = Uint8List.fromList([1, 2, 3])
          ..pinUnlockToken = Uint8List.fromList([4, 5, 6]);
        await UserService.update((u) => u.passwordLessRecovery = config);

        await twonlyDB.contactsDao.insertContact(
          ContactsCompanion.insert(
            userId: const Value(2),
            username: 'friend_2',
            recoveryIsTrustedFriend: const Value(true),
            recoverySecretShare: Value(Uint8List.fromList([1, 2, 3])),
            recoveryLastHeartbeat: const Value(null),
          ),
        );

        await setupSignalSession(2);

        final mockApi = apiService as MockApiService;
        mockApi.sentTextMessages.clear();

        final baseTime = DateTime(2026, 6, 20, 12);

        await withClock(Clock.fixed(baseTime), () async {
          await PasswordlessRecoveryService.performHeartbeat();
        });

        // Verify message sent
        expect(mockApi.sentTextMessages.length, 1);
        expect(mockApi.sentTextMessages.first.$1, 2);

        // Verify db update
        final c2 = await twonlyDB.contactsDao.getContactById(2);
        expect(c2?.recoveryLastHeartbeat, isNull);

        // Verify calling again does not resend
        mockApi.sentTextMessages.clear();
        await withClock(Clock.fixed(baseTime), () async {
          await PasswordlessRecoveryService.performHeartbeat();
        });
        expect(mockApi.sentTextMessages.length, 0);
      },
    );

    test(
      'sends heartbeat to friends who chose us as a trusted friend based on time',
      () async {
        final config = PasswordLessRecovery(3)
          ..encryptedServerKey = Uint8List.fromList([1, 2, 3])
          ..pinUnlockToken = Uint8List.fromList([4, 5, 6]);
        await UserService.update((u) => u.passwordLessRecovery = config);

        final shareBytes = Uint8List.fromList([10, 20, 30]);
        await twonlyDB.contactsDao.insertContact(
          ContactsCompanion.insert(
            userId: const Value(3),
            username: 'friend_3',
            recoveryContactsSecretShare: Value(shareBytes),
            recoveryContactsLastHeartbeat: const Value(null),
          ),
        );

        await setupSignalSession(3);

        final mockApi = apiService as MockApiService;
        mockApi.sentTextMessages.clear();

        final baseTime = DateTime(2026, 6, 20, 12);

        // Case 1: recoveryContactsLastHeartbeat is null -> should send
        await withClock(Clock.fixed(baseTime), () async {
          await PasswordlessRecoveryService.performHeartbeat();
        });
        expect(mockApi.sentTextMessages.length, 1);
        expect(mockApi.sentTextMessages.first.$1, 3);

        final c3 = await twonlyDB.contactsDao.getContactById(3);
        expect(c3?.recoveryContactsLastHeartbeat, baseTime);

        // Case 2: last heartbeat is < 7 days -> should not send
        mockApi.sentTextMessages.clear();
        await withClock(
          Clock.fixed(baseTime.add(const Duration(days: 5))),
          () async {
            await PasswordlessRecoveryService.performHeartbeat();
          },
        );
        expect(mockApi.sentTextMessages.length, 0);

        // Case 3: last heartbeat is > 7 days -> should send
        mockApi.sentTextMessages.clear();
        final targetTime = baseTime.add(const Duration(days: 8));
        await withClock(Clock.fixed(targetTime), () async {
          await PasswordlessRecoveryService.performHeartbeat();
        });
        expect(mockApi.sentTextMessages.length, 1);

        final c3Updated = await twonlyDB.contactsDao.getContactById(3);
        expect(c3Updated?.recoveryContactsLastHeartbeat, targetTime);
      },
    );

    test(
      'sends heartbeat to friends who chose us as a trusted friend even if our config is null',
      () async {
        await UserService.update((u) => u.passwordLessRecovery = null);

        final shareBytes = Uint8List.fromList([10, 20, 30]);
        await twonlyDB.contactsDao.insertContact(
          ContactsCompanion.insert(
            userId: const Value(4),
            username: 'friend_4',
            recoveryContactsSecretShare: Value(shareBytes),
            recoveryContactsLastHeartbeat: const Value(null),
          ),
        );

        await setupSignalSession(4);

        final mockApi = apiService as MockApiService;
        mockApi.sentTextMessages.clear();

        final baseTime = DateTime(2026, 6, 20, 12);

        await withClock(Clock.fixed(baseTime), () async {
          await PasswordlessRecoveryService.performHeartbeat();
        });

        expect(mockApi.sentTextMessages.length, 1);
        expect(mockApi.sentTextMessages.first.$1, 4);
      },
    );
  });

  group('PasswordlessRecoveryService - handlePasswordlessRecovery', () {
    test(
      'handlePasswordlessRecovery deletes share when delete is true',
      () async {
        await twonlyDB.contactsDao.insertContact(
          ContactsCompanion.insert(
            userId: const Value(4),
            username: 'friend_4',
            recoveryContactsSecretShare: Value(Uint8List.fromList([7, 8, 9])),
            recoveryContactsLastHeartbeat: Value(DateTime.now()),
          ),
        );

        final msg = pb.EncryptedContent_PasswordLessRecovery()..delete = true;

        await PasswordlessRecoveryService.handlePasswordlessRecovery(
          4,
          msg,
          'receipt_id_1',
        );

        final c4 = await twonlyDB.contactsDao.getContactById(4);
        expect(c4?.recoveryContactsSecretShare, isNull);
        expect(c4?.recoveryContactsLastHeartbeat, isNull);
      },
    );

    test(
      'handlePasswordlessRecovery saves share when delete is false',
      () async {
        await twonlyDB.contactsDao.insertContact(
          ContactsCompanion.insert(
            userId: const Value(4),
            username: 'friend_4',
          ),
        );

        final msg = pb.EncryptedContent_PasswordLessRecovery()
          ..delete = false
          ..recoverySecretShare = [11, 22, 33];

        await PasswordlessRecoveryService.handlePasswordlessRecovery(
          4,
          msg,
          'receipt_id_2',
        );

        final c4 = await twonlyDB.contactsDao.getContactById(4);
        expect(
          c4?.recoveryContactsSecretShare,
          Uint8List.fromList([11, 22, 33]),
        );
        expect(c4?.recoveryContactsLastHeartbeat, isNull);
      },
    );
  });

  group('PasswordlessRecoveryService - handlePasswordlessRecoveryHeartbeat', () {
    test('sends delete message back if stored share is null', () async {
      await twonlyDB.contactsDao.insertContact(
        ContactsCompanion.insert(userId: const Value(5), username: 'friend_5'),
      );

      await setupSignalSession(5);

      final mockApi = apiService as MockApiService;
      mockApi.sentTextMessages.clear();

      final msg = pb.EncryptedContent_PasswordLessRecoveryHeartbeat()
        ..hash = [1, 2, 3];

      await PasswordlessRecoveryService.handlePasswordlessRecoveryHeartbeat(
        5,
        msg,
        'receipt_id_3',
      );

      // Await unawaited sendCipherText call
      await Future.delayed(const Duration(milliseconds: 100));

      // We expect a delete message sent back
      expect(mockApi.sentTextMessages.isNotEmpty, isTrue);
      expect(mockApi.sentTextMessages.first.$1, 5);
    });

    test(
      'updates recoveryLastHeartbeat to clock.now() when hash matches',
      () async {
        final shareBytes = Uint8List.fromList([1, 2, 3]);
        final hashBytes = sha256.convert(shareBytes).bytes;

        await twonlyDB.contactsDao.insertContact(
          ContactsCompanion.insert(
            userId: const Value(5),
            username: 'friend_5',
            recoverySecretShare: Value(shareBytes),
          ),
        );

        final msg = pb.EncryptedContent_PasswordLessRecoveryHeartbeat()
          ..hash = hashBytes;

        final now = DateTime(2026, 6, 20, 12);

        await withClock(Clock.fixed(now), () async {
          await PasswordlessRecoveryService.handlePasswordlessRecoveryHeartbeat(
            5,
            msg,
            'receipt_id_4',
          );
        });

        final c5 = await twonlyDB.contactsDao.getContactById(5);
        expect(c5?.recoveryLastHeartbeat, now);
      },
    );

    test(
      'sets recoveryLastHeartbeat to null when hash does not match',
      () async {
        final shareBytes = Uint8List.fromList([1, 2, 3]);
        final wrongHashBytes = sha256.convert([4, 5, 6]).bytes;

        await twonlyDB.contactsDao.insertContact(
          ContactsCompanion.insert(
            userId: const Value(5),
            username: 'friend_5',
            recoverySecretShare: Value(shareBytes),
            recoveryLastHeartbeat: Value(DateTime.now()),
          ),
        );

        final msg = pb.EncryptedContent_PasswordLessRecoveryHeartbeat()
          ..hash = wrongHashBytes;

        await PasswordlessRecoveryService.handlePasswordlessRecoveryHeartbeat(
          5,
          msg,
          'receipt_id_5',
        );

        final c5 = await twonlyDB.contactsDao.getContactById(5);
        expect(c5?.recoveryLastHeartbeat, isNull);
      },
    );
  });
}
