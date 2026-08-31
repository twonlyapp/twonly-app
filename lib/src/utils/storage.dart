import 'dart:async';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';

/// Deletes local databases and files.
///
/// Set [removeCredentials] only when the current account is intentionally
/// abandoned or its key manager is about to be replaced during recovery.
Future<bool> deleteLocalUserData({bool removeCredentials = false}) async {
  if (removeCredentials) {
    await RustKeyManager.removeLocalCredentials();
  }
  await twonlyDB.close();
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
  return true;
}
