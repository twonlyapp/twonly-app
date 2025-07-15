import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:hashlib/hashlib.dart';
import 'package:http/http.dart' as http;
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/services/api/media_upload.dart';
import 'package:twonly/src/services/twonly_safe/create_backup.twonly_safe.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';

Future<void> enableTwonlySafe(String password) async {
  final user = await getUser();
  if (user == null) return;

  final (backupId, encryptionKey) = await getMasterKey(password, user.username);

  await updateUserdata((user) {
    user.twonlySafeBackup = TwonlySafeBackup(
      encryptionKey: encryptionKey,
      backupId: backupId,
    );
    return user;
  });
  unawaited(performTwonlySafeBackup(force: true));
}

Future<void> disableTwonlySafe() async {
  final serverUrl = await getTwonlySafeBackupUrl();
  if (serverUrl != null) {
    try {
      final response = await http.delete(
        Uri.parse(serverUrl),
        headers: {
          'Content-Type': 'application/json', // Set the content type if needed
          // Add any other headers if required
        },
      );
      Log.info('Download deleted with: ${response.statusCode}');
    } catch (e) {
      Log.error('Could not connect to the server.');
    }
  }
  await updateUserdata((user) {
    user.twonlySafeBackup = null;
    return user;
  });
}

Future<(Uint8List, Uint8List)> getMasterKey(
  String password,
  String username,
) async {
  final List<int> passwordBytes = utf8.encode(password);
  final List<int> saltBytes = utf8.encode(username);

  // Values are derived from the Threema Whitepaper
  // https://threema.com/assets/documents/cryptography_whitepaper.pdf

  final scrypt = Scrypt(
    cost: 65536,
    salt: saltBytes,
  );

  final key = scrypt.convert(passwordBytes).bytes;
  return (key.sublist(0, 32), key.sublist(32, 64));
}

Future<String?> getTwonlySafeBackupUrl() async {
  final user = await getUser();
  if (user == null || user.twonlySafeBackup == null) return null;
  return getTwonlySafeBackupUrlFromServer(
    user.twonlySafeBackup!.backupId,
    user.backupServer,
  );
}

Future<String?> getTwonlySafeBackupUrlFromServer(
  List<int> backupId,
  BackupServer? backupServer,
) async {
  var backupServerUrl = 'https://safe.twonly.eu/';

  if (backupServer != null) {
    backupServerUrl = backupServer.serverUrl;
  }

  final backupIdHex = uint8ListToHex(backupId).toLowerCase();

  return '${backupServerUrl}backups/$backupIdHex';
}
