import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/services/error_reporting.service.dart';
import 'package:twonly/src/utils/log.dart';

/// Deletes local databases and files.
///
/// Set [removeCredentials] only when the current account is intentionally
/// abandoned or its key manager is about to be replaced during recovery.
Future<bool> deleteLocalUserData({bool removeCredentials = false}) async {
  await ErrorReportingService.setEnabled(false);
  if (removeCredentials) {
    await RustKeyManager.removeLocalCredentials();
    Log.info('Removed the local credentials.');
  }
  final privateDir = await getApplicationSupportDirectory();
  // iOS runtime data lives in the App Group. Also clear the old private copy
  // so it cannot bring back an abandoned account during a later migration.
  final directories = {
    privateDir.path,
    AppEnvironment.supportDir,
    AppEnvironment.cacheDir,
  };
  for (final path in directories) {
    _clearDirectory(Directory(path));
  }
  Log.info('Deleted the local user data.');
  return true;
}

void _clearDirectory(Directory directory) {
  if (!directory.existsSync()) return;
  for (final entity in directory.listSync(followLinks: false)) {
    // Keep shared lock inodes and the iOS migration marker. Removing either
    // would let another process bypass admission or re-import old private data.
    if (entity.path.endsWith('.twonly-maintenance.lock') ||
        entity.path == '${directory.path}/.runtime_storage_migrated_v1') {
      continue;
    }
    if (entity is Directory) {
      _clearDirectory(entity);
      if (entity.listSync(followLinks: false).isEmpty) entity.deleteSync();
    } else {
      entity.deleteSync();
    }
  }
}
