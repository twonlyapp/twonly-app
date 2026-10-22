import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
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
  final appDir = await getApplicationSupportDirectory();
  if (appDir.existsSync()) {
    appDir.deleteSync(recursive: true);
  }
  Log.info('Deleted the local user data.');
  return true;
}
