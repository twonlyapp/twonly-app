import 'dart:async';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/secure_storage.dart';

Future<bool> deleteLocalUserData() async {
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
  await SecureStorage.instance.deleteAll();
  locator
    ..unregister<TwonlyDB>()
    ..registerLazySingleton<TwonlyDB>(TwonlyDB.new);
  return true;
}
