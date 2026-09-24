import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hashlib/random.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart'
    show CiphertextMessage;
import 'package:logging/logging.dart';
import 'package:twonly/core/bridge.dart' as bridge;
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/callbacks/callbacks.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    show NewMessage;
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/services/api/api.service.dart';
import 'package:twonly/src/services/api/server_messages.api.dart';
import 'package:twonly/src/services/signal/encryption.signal.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:workmanager/workmanager.dart';

import '../mocks/platform_channels.dart';
import '../mocks/test_client.dart';
import '../mocks/workmanager.dart';

// Every client in this process shares one Rust Signal engine, whose identity
// is the one imported last. A contact can therefore only move from V1 to V2
// by processing the bundle of the client that was initialized last.

Future<void> uploadPqcKeys(TestClient client) => client.run(() async {
  await UserService.update((user) {
    user.signalLastPqcPreKeysUploaded = null;
  });
  await SignalIdentityService.onAuthenticated();
});

Future<SignalVersion?> versionOf(TestClient client, TestClient contact) =>
    client.run(
      () async => (await client.env.db.contactsDao.getContactById(
        contact.realUserId,
      ))?.signalVersion,
    );

/// Runs [action] as [client] and returns what it logged meanwhile.
Future<(T, List<String>)> logsOf<T>(
  TestClient client,
  Future<T> Function() action,
) async {
  final lines = <String>[];
  final subscription = Logger.root.onRecord.listen((record) {
    if (record.zone?[#userId] == client.env.userId) lines.add(record.message);
  });
  try {
    return (await client.run(action), lines);
  } finally {
    await subscription.cancel();
  }
}

Uint8List textContent(String text) => pb.EncryptedContent(
  textMessage: pb.EncryptedContent_TextMessage()..text = text,
).writeToBuffer();

/// [sender] encrypts messages over V1 that never reach [receiver], until its
/// sending chain is further ahead than [receiver] can follow.
Future<void> breakV1Chain(TestClient sender, TestClient receiver) =>
    sender.run(() async {
      for (var i = 0; i < 2002; i++) {
        await signalEncryptMessage(receiver.realUserId, textContent('lost $i'));
      }
    });

void main() {
  if (!Platform.isMacOS) {
    return;
  }

  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    Logger.root.level = Level.ALL;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    WorkmanagerPlatform.instance = MockWorkmanagerPlatform();
    tempDir = Directory.systemTemp.createTempSync('twonly_recovery_test_');
    AppEnvironment.initTesting(
      customCacheDir: tempDir.path,
      customSupportDir: tempDir.path,
    );

    final dylibPath =
        '${Directory.current.path}/rust/target/debug/librust_lib_twonly.dylib';
    if (File(dylibPath).existsSync()) {
      await RustLib.init(externalLibrary: ExternalLibrary.open(dylibPath));
    } else {
      await RustLib.init();
    }
    await initFlutterCallbacksForRust();

    await bridge.initializeTwonlyFlutter(
      config: bridge.InitConfig(
        databaseDir: tempDir.path,
        dataDir: tempDir.path,
      ),
    );

    if (locator.isRegistered<TwonlyDB>()) await locator.unregister<TwonlyDB>();
    if (locator.isRegistered<UserService>()) {
      await locator.unregister<UserService>();
    }
    if (locator.isRegistered<ApiService>()) {
      await locator.unregister<ApiService>();
    }

    locator
      ..registerFactory<TwonlyDB>(() {
        final db = Zone.current[#twonlyDB] as TwonlyDB?;
        if (db != null) return db;
        throw StateError('No TwonlyDB in active Zone.');
      })
      ..registerFactory<UserService>(() {
        final us = Zone.current[#userService] as UserService?;
        if (us != null) return us;
        throw StateError('No UserService in active Zone.');
      })
      ..registerFactory<ApiService>(() {
        final api = Zone.current[#apiService] as ApiService?;
        if (api != null) return api;
        throw StateError('No ApiService in active Zone.');
      });
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('Signal session recovery', () {
    // Alice sends, Bob receives. Bob is always initialized first, so the
    // shared Rust identity is Alice's.
    late TestClient alice;
    late TestClient bob;

    setUp(() async {
      setupPlatformChannelMocks();
      HttpOverrides.global = RealHttpOverrides();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/package_info'),
            (call) async {
              return {
                'appName': 'twonly',
                'packageName': 'eu.twonly.app',
                'version': '1.0.0',
                'buildNumber': '100',
              };
            },
          );
      await Workmanager().initialize(() {});

      bob = TestClient(7002);
      alice = TestClient(8001);
      await bob.init(disablePqc: true);
      await alice.init(disablePqc: true);
    });

    tearDown(() async {
      await alice.run(() async => alice.api.close(null));
      await bob.run(() async => bob.api.close(null));
      await alice.env.db.close();
      await bob.env.db.close();
    });

    /// Both sides talk V1 and Alice's session is acknowledged, so she sends
    /// plain Whisper messages. Alice then publishes a V2 bundle.
    Future<void> talkOverV1ThenPublishV2({bool letBobSettle = false}) async {
      await alice.initContact(bob);
      await bob.initContact(alice);
      await alice.sendText(bob, 'hello over V1');
      await bob.expectMessage((m) => m.content == 'hello over V1');
      await bob.sendText(alice, 'reply over V1');
      await alice.expectMessage((m) => m.content == 'reply over V1');
      if (letBobSettle) {
        // Bob upgrades V1 contacts on his own shortly after messages arrive.
        // Let that happen while Alice has no V2 bundle to upgrade to.
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      await uploadPqcKeys(alice);
    }

    test('a replayed V2 message leaves the session alone', () async {
      await uploadPqcKeys(alice);
      await uploadPqcKeys(bob);
      await alice.initContact(bob);
      await bob.initContact(alice);
      expect(await versionOf(bob, alice), SignalVersion.v2);

      final ciphertext = (await alice.run(
        () => signalEncryptMessageV2(bob.realUserId, textContent('once')),
      ))!.ciphertext;
      final (first, _) = await bob.run(
        () => signalDecryptMessageV2(alice.realUserId, ciphertext),
      );
      expect(first!.textMessage.text, 'once');

      final ((replayed, errorType), logs) = await logsOf(
        bob,
        () => signalDecryptMessageV2(alice.realUserId, ciphertext),
      );

      expect(replayed, isNull);
      expect(
        errorType,
        pb.PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN,
      );
      expect(logs, isNot(contains(contains('re-sync the session'))));
      expect(logs, isNot(contains(contains('Could not decrypt message'))));
    });

    test('a V2 message moves a V1 contact to V2', () async {
      await uploadPqcKeys(bob);
      await alice.initContact(bob);
      await bob.initContact(alice);
      expect(await versionOf(alice, bob), SignalVersion.v2);
      expect(await versionOf(bob, alice), SignalVersion.v1);

      final ciphertext = (await alice.run(
        () => signalEncryptMessageV2(bob.realUserId, textContent('over V2')),
      ))!.ciphertext;
      final (content, _) = await bob.run(
        () => signalDecryptMessageV2(alice.realUserId, ciphertext),
      );

      expect(content!.textMessage.text, 'over V2');
      expect(await versionOf(bob, alice), SignalVersion.v2);
    });

    test(
      'a dead V1 chain asks the sender to rebuild, not us to reset V2',
      () async {
        await talkOverV1ThenPublishV2();
        await bob.run(() async {
          final userData = await bob.api.getUserById(alice.realUserId);
          expect(await processSignalUserData(userData!), isTrue);
        });
        expect(await versionOf(bob, alice), SignalVersion.v2);

        await breakV1Chain(alice, bob);
        final encrypted = (await alice.run(
          () => signalEncryptMessage(bob.realUserId, textContent('stuck')),
        ))!;
        expect(encrypted.type, pb.Message_Type.CIPHERTEXT);

        final ((content, errorType), logs) = await logsOf(
          bob,
          () => signalDecryptMessageV1(
            alice.realUserId,
            encrypted.ciphertext,
            CiphertextMessage.whisperType,
          ),
        );

        expect(content, isNull);
        expect(
          errorType,
          pb.PlaintextContent_DecryptionErrorMessage_Type.PREKEY_UNKNOWN,
        );
        expect(logs, contains(contains('beyond the receiving window')));
        expect(logs, isNot(contains(contains('re-sync the session'))));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'a V1 resync that moves us to V2 asks the sender to rebuild as well',
      () async {
        await talkOverV1ThenPublishV2(letBobSettle: true);
        expect(await versionOf(bob, alice), SignalVersion.v1);

        await breakV1Chain(alice, bob);
        final encrypted = (await alice.run(
          () => signalEncryptMessage(bob.realUserId, textContent('stuck')),
        ))!;

        final ((content, errorType), logs) = await logsOf(
          bob,
          () => signalDecryptMessageV1(
            alice.realUserId,
            encrypted.ciphertext,
            CiphertextMessage.whisperType,
          ),
        );

        expect(content, isNull);
        expect(
          errorType,
          pb.PlaintextContent_DecryptionErrorMessage_Type.PREKEY_UNKNOWN,
        );
        expect(logs, contains(contains('re-sync the session')));
        expect(await versionOf(bob, alice), SignalVersion.v2);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'a broken V1 session does not hold back V2 messages of the same batch',
      () async {
        await talkOverV1ThenPublishV2();
        await bob.run(() async {
          final userData = await bob.api.getUserById(alice.realUserId);
          expect(await processSignalUserData(userData!), isTrue);
        });
        // Bob's first V2 message gives Alice a V2 session to answer with.
        await bob.sendText(alice, 'hello over V2');
        await alice.expectMessage((m) => m.content == 'hello over V2');
        await breakV1Chain(alice, bob);

        Future<NewMessage> fromAlice(SignalEncryptResult encrypted) async =>
            NewMessage(
              body: pb.Message(
                receiptId: uuid.v4(),
                type: encrypted.type,
                encryptedContent: encrypted.ciphertext,
              ).writeToBuffer(),
              fromUserId: Int64(alice.realUserId),
            );
        Uint8List text(String text) => pb.EncryptedContent(
          groupId: alice.defaultGroup!.groupId,
          textMessage: pb.EncryptedContent_TextMessage()
            ..senderMessageId = uuid.v4()
            ..text = text,
        ).writeToBuffer();

        final overDeadV1Chain = await alice.run(
          () async => fromAlice(
            (await signalEncryptMessage(
              bob.realUserId,
              text('over the dead V1 chain'),
            ))!,
          ),
        );
        final overV2 = await alice.run(
          () async => fromAlice(
            (await signalEncryptMessageV2(
              bob.realUserId,
              text('over V2 in the same batch'),
            ))!,
          ),
        );

        final brokenSessions = <(int, SignalVersion)>{};
        await bob.run(() async {
          for (final message in [overDeadV1Chain, overV2]) {
            await handleClient2ClientMessage(
              message,
              brokenSessionsInCurrentBatch: brokenSessions,
            );
          }
        });

        expect(brokenSessions, {(alice.realUserId, SignalVersion.v1)});
        await bob.expectMessage(
          (m) => m.content == 'over V2 in the same batch',
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'a message sent over a dead V1 chain still arrives',
      () async {
        await talkOverV1ThenPublishV2();
        await bob.run(() async {
          final userData = await bob.api.getUserById(alice.realUserId);
          expect(await processSignalUserData(userData!), isTrue);
        });
        await breakV1Chain(alice, bob);

        await alice.sendText(bob, 'sent over the dead chain');

        final received = await bob.expectMessage(
          (m) => m.content == 'sent over the dead chain',
        );
        expect(received.senderId, alice.realUserId);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
