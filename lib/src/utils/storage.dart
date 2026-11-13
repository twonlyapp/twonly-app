import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/model/json/onboarding_state.model.dart';
import 'package:twonly/src/services/error_reporting.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';
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
  if (removeCredentials && (Platform.isIOS || Platform.isAndroid)) {
    await const MethodChannel(
      'eu.twonly/account_reset',
    ).invokeMethod<void>('clearPlatformData');
  }
  final privateDir = await getApplicationSupportDirectory();
  final documentsDir = await getApplicationDocumentsDirectory();
  final temporaryDir = await getTemporaryDirectory();
  // iOS runtime data lives in the App Group. Also clear the old private copy
  // so it cannot bring back an abandoned account during a later migration.
  final directories = {
    privateDir.path,
    AppEnvironment.supportDir,
    AppEnvironment.cacheDir,
    documentsDir.path,
    temporaryDir.path,
  };
  final preferences = await SharedPreferences.getInstance();
  if (!await preferences.clear()) {
    throw StateError('Could not clear local preferences');
  }
  for (final path in directories) {
    _clearDirectory(Directory(path));
  }
  Log.info('Deleted the local user data.');
  return true;
}

/// Registration must never replace the account ID over an existing database.
/// Close native owners, erase the account, then let a new process initialize
/// empty databases and a new main key before showing the registration form.
Future<void> prepareNewAccountRegistration({
  required String notificationTitle,
  required String notificationBody,
}) async {
  await deleteLocalUserData(removeCredentials: true);
  await KeyValueStore.putAtomically(
    KeyValueKeys.onboardingState,
    OnboardingState(openRegistration: true).toJson(),
  );
  final restarted = await Restart.restartApp(
    notificationTitle: notificationTitle,
    notificationBody: notificationBody,
    forceKill: true,
  );
  if (!restarted) throw StateError('Could not restart twonly');
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
