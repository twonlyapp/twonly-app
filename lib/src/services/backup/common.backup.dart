import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:hashlib/hashlib.dart';
import 'package:http/http.dart' as http;
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/services/backup/create.backup.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

Future<void> enableTwonlySafe(String password) async {
  final (backupId, encryptionKey) = await getMasterKey(
    password,
    AppSession.currentUser.username,
  );

  await updateUser((user) {
    user.twonlySafeBackup = TwonlySafeBackup(
      encryptionKey: encryptionKey,
      backupId: backupId,
    );
  });
  unawaited(performTwonlySafeBackup(force: true));
}

Future<void> removeTwonlySafeFromServer() async {
  final serverUrl = getTwonlySafeBackupUrl();
  if (serverUrl == null) {
    Log.error('Could not remove twonly safe as serverUrl is null');
    return;
  }
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
    Log.error('Could not connect upload the backup.');
  }
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

String? getTwonlySafeBackupUrl() {
  if (AppSession.currentUser.twonlySafeBackup == null) return null;
  return getTwonlySafeBackupUrlFromServer(
    AppSession.currentUser.twonlySafeBackup!.backupId,
    AppSession.currentUser.backupServer,
  );
}

String? getTwonlySafeBackupUrlFromServer(
  List<int> backupId,
  BackupServer? backupServer,
) {
  var backupServerUrl = 'https://safe.twonly.eu/';

  if (backupServer != null) {
    backupServerUrl = backupServer.serverUrl;
  }

  final backupIdHex = uint8ListToHex(backupId).toLowerCase();

  return '${backupServerUrl}backups/$backupIdHex';
}
