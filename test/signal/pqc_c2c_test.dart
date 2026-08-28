// ignore_for_file: avoid_print

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
import 'package:twonly/src/services/api/api.service.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
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
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    WorkmanagerPlatform.instance = MockWorkmanagerPlatform();
    tempDir = Directory.systemTemp.createTempSync('twonly_pqc_c2c_test_');
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

  group('PQC C2C Migration Protocol Tests', () {
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

      clientA = TestClient(3001);
      clientB = TestClient(4002);

      // Initialize BOTH clients with PQC generation disabled.
      await clientA.init(disablePqc: true);
      await clientB.init(disablePqc: true);

      await clientA.initContact(clientB);
      await clientB.initContact(clientA);
    });

    tearDown(() async {
      await clientA.run(() async => clientA.api.close(null));
      await clientB.run(() async => clientB.api.close(null));
      await clientA.env.db.close();
      await clientB.env.db.close();
    });

    test(
      'C2C: V1 to V2 PQC Migration and 100 Messages Exchange',
      () async {
        print('=== Starting V1 Message Exchange ===');

        // Exchange 100 messages in V1
        for (var i = 0; i < 100; i++) {
          final textAtoB = 'Hello Bob V1 - Message $i';
          await clientA.sendText(clientB, textAtoB);
          final receivedByB = await clientB.expectMessage(
            (m) => m.content == textAtoB && m.senderId == clientA.realUserId,
          );
          expect(receivedByB.content, textAtoB);
          expect(receivedByB.type, MessageType.text.name);

          final textBtoA = 'Hello Alice V1 - Reply $i';
          await clientB.sendText(clientA, textBtoA);
          final receivedByA = await clientA.expectMessage(
            (m) => m.content == textBtoA && m.senderId == clientB.realUserId,
          );
          expect(receivedByA.content, textBtoA);
          expect(receivedByA.type, MessageType.text.name);
        }

        print('=== Migrating to V2 PQC ===');

        // Step 2: Migrate to V2
        // For Client A
        await clientA.run(() async {
          await UserService.update((user) {
            user.signalLastPqcPreKeysUploaded = null;
          });
          await createIfNotExistsSignalIdentity(); // This will upload PQC keys
        });

        // For Client B
        await clientB.run(() async {
          await UserService.update((user) {
            user.signalLastPqcPreKeysUploaded = null;
          });
          await createIfNotExistsSignalIdentity(); // This will upload PQC keys
        });

        // Both clients now fetch the updated contacts from the dev server
        // This will invoke processSignalUserData and migrate the signal version to V2
        await clientA.run(() async {
          final userData = await rustApiProtobuf(
            RustApi.getUserById(userId: clientB.realUserId),
            decodeUserData,
          );
          if (userData != null) await processSignalUserData(userData);
        });
        await clientB.run(() async {
          final userData = await rustApiProtobuf(
            RustApi.getUserById(userId: clientA.realUserId),
            decodeUserData,
          );
          if (userData != null) await processSignalUserData(userData);
        });

        print('=== Starting V2 PQC Message Exchange ===');

        // Step 3: Exchange 100 messages in V2
        for (var i = 0; i < 100; i++) {
          final textAtoB = 'Hello Bob V2 PQC - Message $i';
          await clientA.sendText(clientB, textAtoB);
          final receivedByB = await clientB.expectMessage(
            (m) => m.content == textAtoB && m.senderId == clientA.realUserId,
          );
          expect(receivedByB.content, textAtoB);
          expect(receivedByB.type, MessageType.text.name);

          final textBtoA = 'Hello Alice V2 PQC - Reply $i';
          await clientB.sendText(clientA, textBtoA);
          final receivedByA = await clientA.expectMessage(
            (m) => m.content == textBtoA && m.senderId == clientB.realUserId,
          );
          expect(receivedByA.content, textBtoA);
          expect(receivedByA.type, MessageType.text.name);
        }

        print('=== PQC Migration and Exchange Completed Successfully ===');
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}
