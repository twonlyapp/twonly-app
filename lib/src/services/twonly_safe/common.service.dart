import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:hashlib/hashlib.dart';
import 'package:http/http.dart' as http;
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/services/api/media_upload.dart';
import 'package:twonly/src/services/twonly_safe/create_backup.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';

Future<String?> getTwonlySafeBackupUrl() async {
  final user = await getUser();
  if (user == null || user.twonlySafeBackup == null) return null;

  String backupServerUrl = "https://safe.twonly.eu/";

  if (user.backupServer != null) {
    backupServerUrl = user.backupServer!.serverUrl;
  }

  String backupId =
      uint8ListToHex(user.twonlySafeBackup!.backupId).toLowerCase();

  return "${backupServerUrl}backups/$backupId";
}

Future enableTwonlySafe(String password) async {
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
  performTwonlySafeBackup(force: true);
}

Future disableTwonlySafe() async {
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
      Log.info("Download deleted with: ${response.statusCode}");
    } catch (e) {
      Log.error("Could not connect to the server.");
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
  List<int> passwordBytes = utf8.encode(password);
  List<int> saltBytes = utf8.encode(username);

  // Parameters for scrypt

  // Create an instance of Scrypt
  final scrypt = Scrypt(
    cost: 65536,
    blockSize: 8,
    parallelism: 1,
    derivedKeyLength: 64,
    salt: saltBytes,
  );

  // Derive the key
  // final key = (await compute(scrypt.convert, passwordBytes)).bytes;
  final key = (scrypt.convert(passwordBytes)).bytes;
  return (key.sublist(0, 32), key.sublist(32, 64));
}
