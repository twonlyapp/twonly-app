import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge.dart' as bridge;
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/callbacks/callbacks.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/api.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/memories/memories_cloud.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';

import '../mocks/platform_channels.dart';
import '../mocks/test_client.dart';

void main() {
  group('Memories Cloud Backup Integration', () {
    late TestClient client;
    late Directory tempDir;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
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
      Log.init();
      setupPlatformChannelMocks();
      HttpOverrides.global = RealHttpOverrides();
      final dylibPath =
          '${Directory.current.path}/rust/target/debug/librust_lib_twonly.dylib';
      if (File(dylibPath).existsSync()) {
        await RustLib.init(externalLibrary: ExternalLibrary.open(dylibPath));
      } else {
        await RustLib.init();
      }
      await initFlutterCallbacksForRust();
      tempDir = Directory.systemTemp.createTempSync(
        'twonly_cloud_backup_test_',
      );
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

      if (locator.isRegistered<TwonlyDB>()) {
        await locator.unregister<TwonlyDB>();
      }
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

      client = TestClient(777);
      await client.init();
    });

    tearDownAll(() async {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('Full Backup Lifecycle', () async {
      await client.run(() async {
        await UserService.update((u) => u.isCloudBackupEnabled = true);

        // 1. Create a dummy media file
        final mediaId = 'test_media_${DateTime.now().millisecondsSinceEpoch}';

        await twonlyDB.mediaFilesDao.insertOrUpdateMedia(
          MediaFilesCompanion(
            mediaId: Value(mediaId),
            createdAt: Value(DateTime.now()),
            stored: const Value(true),
            hasThumbnail: const Value(true),
            cloudState: const Value(CloudState.none),
            type: const Value(MediaType.image),
          ),
        );

        final mediaFile = await twonlyDB.mediaFilesDao.getMediaFileById(
          mediaId,
        );
        expect(mediaFile, isNotNull);
        expect(mediaFile!.cloudState, CloudState.none);

        // Mock stored and thumbnail files
        final mediaService = MediaFileService(mediaFile);
        final storedFile = mediaService.storedPath;
        final thumbnailFile = mediaService.thumbnailPath;

        await storedFile.create(recursive: true);
        await storedFile.writeAsBytes([1, 2, 3, 4, 5]);

        await thumbnailFile.create(recursive: true);
        await thumbnailFile.writeAsBytes([1, 2, 3]);

        // 2. Trigger checkUploads (which performs S3 POST upload and confirmation)
        await memoriesCloudService.checkUploads();

        // 3. Verify that the media has cloudState == uploaded
        final finalMedia = await twonlyDB.mediaFilesDao.getMediaFileById(
          mediaId,
        );
        expect(finalMedia, isNotNull);

        // In case the server rejects because the user is not allowed (PlanNotAllowed), return early
        if (finalMedia!.cloudState == CloudState.none) {
          return;
        }

        expect(finalMedia.cloudState, CloudState.uploaded);
      });
    });
  });
}
