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
      await migrateToSharedSupportDirectory(
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

  /// Bootstraps the shared store before Rust opens either database. Native
  /// workers wait for the completion marker, including after an interruption.
  static Future<void> migrateToSharedSupportDirectory(
    Directory source,
    Directory destination,
  ) async {
    await destination.create(recursive: true);
    final marker = File('${destination.path}/.runtime_storage_migrated_v1');
    if (marker.existsSync()) return;

    final pending = File('${destination.path}/.runtime_storage_migrating_v1');
    final pendingTemporary = File('${pending.path}.tmp');
    final sourcePath = source.absolute.path;
    if (pending.existsSync()) {
      if (await pending.readAsString() != sourcePath) {
        throw StateError(
          'The shared runtime migration belongs to another source.',
        );
      }
    } else {
      final entries = await destination.list(followLinks: false).toList();
      // WidgetKit may record placements before the first app launch. It does
      // not open SQLite, and its independent configuration must be preserved.
      if (entries.any(
        (entry) =>
            entry.path != pendingTemporary.path &&
            entry.path != '${destination.path}/widget',
      )) {
        throw StateError(
          'The shared runtime contains data without a migration marker. '
          'Both stores have been preserved.',
        );
      }
      await pendingTemporary.writeAsString(sourcePath, flush: true);
      await pendingTemporary.rename(pending.path);
    }

    if (source.existsSync()) {
      await for (final entity in source.list(followLinks: false)) {
        await _copyEntity(entity, destination.path);
      }
    }
    final completed = File('${marker.path}.tmp');
    await completed.writeAsString(
      DateTime.now().toUtc().toIso8601String(),
      flush: true,
    );
    await completed.rename(marker.path);
    await pending.delete();
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
