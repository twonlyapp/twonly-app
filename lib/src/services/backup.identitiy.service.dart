import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hashlib/hashlib.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';

Future performTwonlySafeBackup() async {
  Log.info("Starting new backup creation.");
  final baseDir = (await getApplicationSupportDirectory()).path;

  var originalDatabase = File(join(baseDir, "twonly_database.sqlite"));
  var backupDir = Directory(join(baseDir, "backup_twonly_safe/"));
  if (backupDir.existsSync()) {
    await backupDir.delete(recursive: true);
  }
  await backupDir.create(recursive: true);

  var backupDatabaseFile =
      File(join(backupDir.path, "twonly_database.backup.sqlite"));

  // copy database
  await originalDatabase.copy(backupDatabaseFile.path);

  final backupDB = TwonlyDatabase(
    driftDatabase(
      name: "twonly_database.backup",
      native: DriftNativeOptions(
        databaseDirectory: () async {
          return backupDir;
        },
      ),
    ),
  );

  await backupDB.deleteDataForTwonlySafe();

  var secureStorageBackup = {};
  final storage = FlutterSecureStorage();
  secureStorageBackup[SecureStorageKeys.signalIdentity] =
      await storage.read(key: SecureStorageKeys.signalIdentity);
  secureStorageBackup[SecureStorageKeys.signalSignedPreKey] =
      await storage.read(key: SecureStorageKeys.signalSignedPreKey);
  secureStorageBackup[SecureStorageKeys.userData] =
      await storage.read(key: SecureStorageKeys.userData);

  var backupSecureStorage = File(join(backupDir.path, "secure_storage.json"));

  await backupSecureStorage.writeAsString(jsonEncode(secureStorageBackup));

  Log.info("Backup files created.");

  var twonlySafeBackupZip = File(join(backupDir.path, "twonly_safe.zip"));

  await createZipArchive(
      twonlySafeBackupZip.path, [backupSecureStorage, backupDatabaseFile]);

  // await backupDir.delete(recursive: true);
}

Future<void> createZipArchive(String zipFilePath, List<File> filesToZip) async {
  final encoder = ZipFileEncoder();
  encoder.create(zipFilePath);
  for (var file in filesToZip) {
    await encoder.addFile(file);
  }
  await encoder.close();
}

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
  performTwonlySafeBackup();
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
