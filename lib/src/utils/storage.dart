import 'dart:async';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';

/// Deletes local databases and files.
///
/// Set [removeCredentials] only when the current account is intentionally
/// abandoned or its key manager is about to be replaced during recovery.
Future<bool> deleteLocalUserData({bool removeCredentials = false}) async {
  if (removeCredentials) {
    await RustKeyManager.removeLocalCredentials();
    Log.info('Removed the local credentials.');
  }
  // The database files are deleted a few lines down either way, so a drift
  // isolate that no longer answers must not block the whole recovery.
  try {
    await twonlyDB.close().timeout(const Duration(seconds: 5));
    Log.info('Closed the app database.');
  } catch (e) {
    Log.warn('Could not close the app database, deleting it anyway', e);
  }
  // Wait for the background drift isolate to potentially shut down
  await Future.delayed(const Duration(milliseconds: 200));

  // Remove port mappings to prevent connecting to an old, detached isolate that holds a deleted DB file.
  IsolateNameServer.removePortNameMapping('drift-db/twonly');
  IsolateNameServer.removePortNameMapping('drift-db/twonly/control');

  final appDir = await getApplicationSupportDirectory();
  if (appDir.existsSync()) {
    appDir.deleteSync(recursive: true);
  }
  locator
    ..unregister<TwonlyDB>()
    ..registerLazySingleton<TwonlyDB>(TwonlyDB.new);
  Log.info('Deleted the local user data.');
  return true;
}
