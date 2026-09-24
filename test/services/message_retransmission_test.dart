import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hashlib/random.dart';
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
import 'package:twonly/src/services/api/messages.api.dart';
import 'package:twonly/src/services/api/server_messages.api.dart';
import 'package:twonly/src/services/signal/protocol_state.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:workmanager/workmanager.dart';

import '../mocks/platform_channels.dart';
import '../mocks/test_client.dart';
import '../mocks/workmanager.dart';

/// Runs [action] as [client] and returns what it logged meanwhile.
Future<List<String>> logsOf(
  TestClient client,
  Future<void> Function() action,
) async {
  final lines = <String>[];
  final subscription = Logger.root.onRecord.listen((record) {
    if (record.zone?[#userId] == client.env.userId) lines.add(record.message);
  });
  try {
    await client.run(action);
    return lines;
  } finally {
    await subscription.cancel();
  }
}

/// A text from [sender] to [receiver] as the server would deliver it. It is
/// encrypted, but never sent.
Future<NewMessage> textFrom(
  TestClient sender,
  TestClient receiver,
  String text,
) => sender.run(() async {
  final (body, _) = (await sendCipherText(
    receiver.realUserId,
    pb.EncryptedContent(
      groupId: sender.defaultGroup!.groupId,
      textMessage: pb.EncryptedContent_TextMessage()
        ..senderMessageId = uuid.v4()
        ..text = text,
    ),
    onlyReturnEncryptedData: true,
  ))!;
  return NewMessage(body: body, fromUserId: Int64(sender.realUserId));
});

NewMessage withReceiptId(NewMessage message, String receiptId) => NewMessage(
  body: (pb.Message.fromBuffer(
    message.body,
  )..receiptId = receiptId).writeToBuffer(),
  fromUserId: message.fromUserId,
);

Future<T> later<T>(Duration elapsed, Future<T> Function() action) =>
    withClock(Clock.fixed(DateTime.now().add(elapsed)), action);

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
    tempDir = Directory.systemTemp.createTempSync('twonly_duplicates_test_');
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

  // Alice sends, Bob receives.
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

    bob = TestClient(7003);
    alice = TestClient(8003);
    await bob.init(disablePqc: true);
    await alice.init(disablePqc: true);
    await alice.initContact(bob);
    await bob.initContact(alice);
  });

  tearDown(() async {
    await alice.run(() async => alice.api.close(null));
    await bob.run(() async => bob.api.close(null));
    await alice.env.db.close();
    await bob.env.db.close();
  });

  group('Duplicate messages', () {
    setUp(() async {
      // Acknowledged sessions, so Alice sends plain Whisper messages.
      await alice.sendText(bob, 'hello');
      await bob.expectMessage((m) => m.content == 'hello');
      await bob.sendText(alice, 'hi');
      await alice.expectMessage((m) => m.content == 'hi');
    });

    test('a duplicate is confirmed again once the cooldown ended', () async {
      final message = await textFrom(alice, bob, 'once');
      await bob.run(() => handleClient2ClientMessage(message));
      await bob.expectMessage((m) => m.content == 'once');

      final duringCooldown = await logsOf(
        bob,
        () => handleClient2ClientMessage(message),
      );
      expect(
        duringCooldown,
        contains(contains('Skipping delivery receipt during cooldown')),
      );

      final afterCooldown = await logsOf(
        bob,
        () => later(
          const Duration(hours: 2),
          () => handleClient2ClientMessage(message),
        ),
      );
      expect(
        afterCooldown,
        contains(contains('Sending delivery receipt again')),
      );
    });

    test(
      'a message that could not be decrypted is read when it comes again',
      () async {
        final first = await textFrom(alice, bob, 'first');
        await bob.run(() => handleClient2ClientMessage(first));
        await bob.expectMessage((m) => m.content == 'first');

        // The same ciphertext under a new receipt id cannot be decrypted
        // twice, so Bob answers it with a decryption error.
        final receiptId = uuid.v4();
        final logs = await logsOf(
          bob,
          () => handleClient2ClientMessage(withReceiptId(first, receiptId)),
        );
        expect(logs, contains(contains('Received message with old counter')));
        expect(
          await bob.run(() => twonlyDB.receiptsDao.isDuplicated(receiptId)),
          isFalse,
        );

        // Alice resends it, and this time it can be decrypted.
        final resent = withReceiptId(
          await textFrom(alice, bob, 'resent'),
          receiptId,
        );
        await bob.run(() => handleClient2ClientMessage(resent));
        await bob.expectMessage((m) => m.content == 'resent');
      },
    );

    test('a duplicate reply is never answered', () async {
      final decryptionError = NewMessage(
        body: pb.Message(
          receiptId: uuid.v4(),
          type: pb.Message_Type.PLAINTEXT_CONTENT,
          plaintextContent: pb.PlaintextContent(
            decryptionErrorMessage: pb.PlaintextContent_DecryptionErrorMessage(
              type: pb.PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN,
            ),
          ),
        ).writeToBuffer(),
        fromUserId: Int64(alice.realUserId),
      );
      await bob.run(() => handleClient2ClientMessage(decryptionError));

      final logs = await logsOf(
        bob,
        () => later(
          const Duration(days: 11),
          () => handleClient2ClientMessage(decryptionError),
        ),
      );
      expect(logs, contains(contains('Unencrypted message is a duplicate')));
      expect(logs, isNot(contains(contains('Sending delivery receipt again'))));
    });
  });

  group('Lost sessions', () {
    setUp(
      () => alice.run(() async {
        await (await getSignalStore())!.deleteAllSessions(
          bob.realUserId.toString(),
        );
      }),
    );

    test('a message without a session builds one and arrives', () async {
      await alice.sendText(bob, 'after the session was lost');
      await bob.expectMessage((m) => m.content == 'after the session was lost');
    });

    test('a message that cannot be encrypted waits for a retry', () async {
      // The resync limiter refuses to rebuild the session for now.
      for (var i = 0; i < maxResyncAttempts; i++) {
        recordResyncAttempt(
          bob.realUserId,
          SignalVersion.v1,
          success: false,
        );
      }
      final message = await alice.sendText(bob, 'waiting');
      final receipts = await alice.run(
        () => twonlyDB.receiptsDao.getReceiptsByContactAndMessageId(
          bob.realUserId,
          message.messageId,
        ),
      );
      expect(receipts, hasLength(1));
      expect(receipts.single.ackByServerAt, isNull);

      recordResyncAttempt(bob.realUserId, SignalVersion.v1, success: true);
      await alice.run(retransmitAllMessages);
      await bob.expectMessage((m) => m.content == 'waiting');
    });
  });
}
