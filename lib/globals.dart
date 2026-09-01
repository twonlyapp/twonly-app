import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/utils/log.dart';

final int isolateCallbackId = Random().nextInt(0x7FFFFFFF);

class AppEnvironment {
  static const _runtimeChannel = MethodChannel('eu.twonly/runtime_storage');
  static late String cacheDir;
  static late String supportDir;

  static bool _isInitialized = false;

  // will be loaded in the main_camera_controller.dart
  static List<CameraDescription> cameras = [];

  static Future<void> init() async {
    if (_isInitialized) return;
    cacheDir = (await getApplicationCacheDirectory()).path;
    final privateSupportDir = (await getApplicationSupportDirectory()).path;
    if (Platform.isIOS) {
      final sharedSupportDir = await _runtimeChannel.invokeMethod<String>(
        'runtimeSupportDirectory',
      );
      if (sharedSupportDir == null || sharedSupportDir.isEmpty) {
        throw StateError('The iOS runtime App Group is unavailable.');
      }
      await _migrateToSharedSupportDirectory(
        Directory(privateSupportDir),
        Directory(sharedSupportDir),
      );
      supportDir = sharedSupportDir;
    } else {
      supportDir = privateSupportDir;
    }
    Log.init();
    _isInitialized = true;
  }

  static Future<void> _migrateToSharedSupportDirectory(
    Directory source,
    Directory destination,
  ) async {
    await destination.create(recursive: true);
    final marker = File('${destination.path}/.runtime_storage_migrated_v1');
    if (marker.existsSync() || !source.existsSync()) return;

    await for (final entity in source.list(followLinks: false)) {
      await _copyEntity(entity, destination.path);
    }
    await marker.writeAsString(
      DateTime.now().toUtc().toIso8601String(),
      flush: true,
    );
  }

  static Future<void> _copyEntity(
    FileSystemEntity entity,
    String destinationDirectory,
  ) async {
    final name = entity.uri.pathSegments
        .where((value) => value.isNotEmpty)
        .last;
    final destinationPath = '$destinationDirectory/$name';
    if (entity is Directory) {
      final destination = Directory(destinationPath);
      await destination.create(recursive: true);
      await for (final child in entity.list(followLinks: false)) {
        await _copyEntity(child, destination.path);
      }
      return;
    }
    if (entity is! File) return;

    final destination = File(destinationPath);
    if (destination.existsSync()) return;
    final temporary = File('$destinationPath.migrating');
    await entity.copy(temporary.path);
    await temporary.rename(destination.path);
  }

  static void initTesting({String? customCacheDir, String? customSupportDir}) {
    cacheDir = customCacheDir ?? '/tmp/twonly_cache';
    supportDir = customSupportDir ?? '/tmp/twonly_support';
    _isInitialized = true;
  }
}

class AppState {
  static bool isAppInBackground = true;
  static bool allowErrorTrackingViaSentry = false;
  static bool gotMessageFromServer = false;
  static int latestAppVersionId = 119;
  static bool hasCameraPermissions = false;
}
