import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge.dart' as bridge;
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/callbacks/callbacks.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/services/api.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:workmanager/workmanager.dart';

import '../mocks/platform_channels.dart';
import '../mocks/test_client.dart';
import '../mocks/workmanager.dart';

void main() {
  if (!Platform.isMacOS) {
    return;
  }

  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    // Log.init();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    WorkmanagerPlatform.instance = MockWorkmanagerPlatform();
    tempDir = Directory.systemTemp.createTempSync('twonly_messaging_test_');
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

  group('C2C Messaging Protocol - Real API Stress Tests', () {
    late TestClient clientA;
    late TestClient clientB;

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

      clientA = TestClient(1001);
      clientB = TestClient(2002);

      await clientA.init();
      await clientB.init();

      await clientA.initContact(clientB);
      await clientB.initContact(clientA);
    });

    tearDown(() async {
      await clientA.run(() async => clientA.api.close(null));
      await clientB.run(() async => clientB.api.close(null));
      await clientA.env.db.close();
      await clientB.env.db.close();
    });

    test('C2C: Text Message Send & Receive', () async {
      const text = 'Hello User B!';
      await clientA.sendText(clientB, text);

      final receivedMsg = await clientB.expectMessage(
        (m) => m.content == text && m.senderId == clientA.realUserId,
      );

      expect(receivedMsg.content, text);
      expect(receivedMsg.senderId, clientA.realUserId);
      expect(receivedMsg.type, MessageType.text.name);
    });

    test('C2C: GroupJoin & ResendGroupPublicKey', () async {
      // clientA creates a fake group ID
      const groupId = 'test-group-id';

      // clientA asks clientB for public key
      await clientA.sendResendGroupPublicKey(clientB, groupId);

      // We expect clientB to process it without crashing.
      // Wait for it to settle by sending a text message and awaiting it.
      await clientA.sendText(clientB, 'sync1');
      await clientB.expectMessage((m) => m.content == 'sync1');

      // clientA sends GroupJoin
      await clientA.sendGroupJoin(clientB, groupId, [1, 2, 3]);

      await clientA.sendText(clientB, 'sync2');
      await clientB.expectMessage((m) => m.content == 'sync2');
    });

    test('C2C: ErrorMessages', () async {
      await clientA.sendErrorMessages(
        clientB,
        pb.EncryptedContent_ErrorMessages_Type.SESSION_OUT_OF_SYNC,
        'fake-receipt',
      );
      await clientA.sendText(clientB, 'sync3');
      await clientB.expectMessage((m) => m.content == 'sync3');
    });

    test('C2C: UserDiscoveryRequest & Update', () async {
      await clientA.sendUserDiscoveryRequest(clientB, [1]);
      await clientA.sendUserDiscoveryUpdate(clientB, [
        [1, 2],
      ]);
      await clientA.sendText(clientB, 'sync4');
      await clientB.expectMessage((m) => m.content == 'sync4');
    });

    test('C2C: KeyVerificationProof', () async {
      await clientA.sendKeyVerificationProof(clientB, [0, 0, 0]);
      await clientA.sendText(clientB, 'sync5');
      await clientB.expectMessage((m) => m.content == 'sync5');
    });

    test('C2C: SENDER_DELIVERY_RECEIPT', () async {
      await clientA.sendDeliveryReceipt(clientB, 'fake-receipt-999');
      await clientA.sendText(clientB, 'sync6');
      await clientB.expectMessage((m) => m.content == 'sync6');
    });

    test('C2C: Reaction Send & Receive', () async {
      final msgA = await clientA.sendText(clientB, 'Message to react to');
      await clientB.expectMessage((m) => m.content == 'Message to react to');

      await clientB.sendReaction(clientA, msgA.messageId, '👍');
      final receivedReaction = await clientA.expectReaction(
        msgA.messageId,
        '👍',
      );
      expect(receivedReaction.emoji, '👍');
    });

    test('C2C: MessageUpdate (Edit & Delete)', () async {
      final msgA = await clientA.sendText(clientB, 'Message to edit');
      await clientB.expectMessage((m) => m.content == 'Message to edit');

      await clientA.sendMessageUpdate(
        clientB,
        msgA.messageId,
        pb.EncryptedContent_MessageUpdate_Type.EDIT_TEXT,
        text: 'Edited text',
      );

      final editedMsg = await clientB.expectMessage(
        (m) => m.content == 'Edited text' && m.messageId == msgA.messageId,
      );
      expect(editedMsg.content, 'Edited text');

      await clientA.sendMessageUpdate(
        clientB,
        msgA.messageId,
        pb.EncryptedContent_MessageUpdate_Type.DELETE,
      );
      await clientA.sendText(clientB, 'sync7');
      await clientB.expectMessage((m) => m.content == 'sync7');
    });

    test('C2C: Media Message', () async {
      await clientA.sendMedia(
        clientB,
        'media-msg-id',
        pb.EncryptedContent_Media_Type.IMAGE,
      );
      await clientA.sendText(clientB, 'sync8');
      await clientB.expectMessage((m) => m.content == 'sync8');
    });
  });
}
