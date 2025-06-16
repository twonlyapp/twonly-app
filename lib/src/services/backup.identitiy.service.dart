import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hashlib/hashlib.dart';
import 'package:twonly/src/utils/storage.dart';

Future enableTwonlySafe(String password) async {
  final user = await getUser();
  if (user == null) return;

  final (backupId, encryptionKey) = await getMasterKey(password, user.username);

  await updateUserdata((user) {
    user.identityBackupEnabled = true;
    user.twonlySafeBackupId = backupId.toList();
    user.twonlySafeEncryptionKey = encryptionKey.toList();
    return user;
  });
  startTwonlySafeBackup();
}

Future disableTwonlySafe() async {
  await updateUserdata((user) {
    user.identityBackupEnabled = false;
    user.twonlySafeBackupId = null;
    user.twonlySafeEncryptionKey = null;
    user.identityBackupLastBackupTime = null;
    user.identityBackupLastBackupSize = 0;
    return user;
  });
}

Future startTwonlySafeBackup() async {
  print("startTwonlySafeBackup");
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
