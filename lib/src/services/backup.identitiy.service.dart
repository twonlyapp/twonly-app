import 'dart:convert';
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hashlib/hashlib.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/model/protobuf/backup/backup.pb.dart';
import 'package:twonly/src/services/api/media_send.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/settings/backup/backup.view.dart';

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

Future performTwonlySafeBackup({bool force = false}) async {
  final user = await getUser();

  if (user == null || user.twonlySafeBackup == null) {
    Log.warn("perform twonly safe backup was called while it is disabled");
    return;
  }

  if (user.twonlySafeBackup!.backupUploadState ==
      LastBackupUploadState.pending) {
    Log.warn("Backup upload is already pending.");
    return;
  }

  DateTime? lastUpdateTime = user.twonlySafeBackup!.lastBackupDone;
  if (!force && lastUpdateTime != null) {
    if (lastUpdateTime.isAfter(DateTime.now().subtract(Duration(days: 1)))) {
      return;
    }
  }

  Log.info("Starting new twonly Safe-Backup.");

  final baseDir = (await getApplicationSupportDirectory()).path;

  final backupDir = Directory(join(baseDir, "backup_twonly_safe/"));
  await backupDir.create(recursive: true);

  final backupDatabaseFile =
      File(join(backupDir.path, "twonly_database.backup.sqlite"));

  // copy database
  final originalDatabase = File(join(baseDir, "twonly_database.sqlite"));
  await originalDatabase.copy(backupDatabaseFile.path);

  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
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

  var userBackup = await getUser();
  if (userBackup == null) return;
  // FILTER settings which should not be in the backup
  userBackup.twonlySafeBackup = null;
  userBackup.lastImageSend = null;
  userBackup.todaysImageCounter = null;
  userBackup.lastPlanBallance = "";
  userBackup.additionalUserInvites = "";
  userBackup.signalLastSignedPreKeyUpdated = null;

  secureStorageBackup[SecureStorageKeys.userData] = jsonEncode(userBackup);

  // Compress and convert backup data

  final twonlyDatabaseBytes = await backupDatabaseFile.readAsBytes();
  await backupDatabaseFile.delete();

  final backupProto = TwonlySafeBackupContent(
    secureStorageJson: jsonEncode(secureStorageBackup),
    twonlyDatabase: twonlyDatabaseBytes,
  );

  final backupBytes = gzip.encode(backupProto.writeToBuffer());

  final backupHash = uint8ListToHex((await Sha256().hash(backupBytes)).bytes);

  if (user.twonlySafeBackup!.lastBackupDone == null ||
      user.twonlySafeBackup!.lastBackupDone!
          .isAfter(DateTime.now().subtract(Duration(days: 90)))) {
    force = true;
  }

  final lastHash =
      await storage.read(key: SecureStorageKeys.twonlySafeLastBackupHash);

  if (lastHash != null && !force) {
    if (backupHash == lastHash) {
      Log.info("Since last backup nothing has changed.");
      return;
    }
  }
  await storage.write(
    key: SecureStorageKeys.twonlySafeLastBackupHash,
    value: backupHash,
  );

  // Encrypt backup data

  final xchacha20 = Xchacha20.poly1305Aead();
  final nonce = xchacha20.newNonce();

  final secretBox = await xchacha20.encrypt(
    backupBytes,
    secretKey: SecretKey(user.twonlySafeBackup!.encryptionKey),
    nonce: nonce,
  );

  final encryptedBackupBytes = (TwonlySafeBackupEncrypted(
    mac: secretBox.mac.bytes,
    nonce: nonce,
    cipherText: secretBox.cipherText,
  )).writeToBuffer();

  Log.info("Backup files created.");

  var encryptedBackupBytesFile =
      File(join(backupDir.path, "twonly_safe.backup"));

  await encryptedBackupBytesFile.writeAsBytes(encryptedBackupBytes);

  Log.info(
      "Create twonly Safe backup with a size of ${encryptedBackupBytes.length} bytes.");

  if (user.backupServer != null) {
    if (encryptedBackupBytes.length > user.backupServer!.maxBackupBytes) {
      Log.error("Backup is to big for the alternative backup server.");
      await updateUserdata((user) {
        user.twonlySafeBackup!.backupUploadState = LastBackupUploadState.failed;
        return user;
      });
      return;
    }
  }

  final task = UploadTask.fromFile(
    taskId: "backup",
    file: encryptedBackupBytesFile,
    httpRequestMethod: "PUT",
    url: (await getTwonlySafeBackupUrl())!,
    requiresWiFi: true,
    priority: 5,
    retries: 2,
    headers: {
      "Content-Type": "application/octet-stream",
    },
  );
  if (await FileDownloader().enqueue(task)) {
    Log.info("Starting upload from twonly Safe backup.");
    await updateUserdata((user) {
      user.twonlySafeBackup!.backupUploadState = LastBackupUploadState.pending;
      user.twonlySafeBackup!.lastBackupDone = DateTime.now();
      user.twonlySafeBackup!.lastBackupSize = encryptedBackupBytes.length;
      return user;
    });
    gUpdateBackupView();
  } else {
    Log.error("Error starting UploadTask for twonly Safe.");
  }
}

Future handleBackupStatusUpdate(TaskStatusUpdate update) async {
  if (update.status == TaskStatus.failed ||
      update.status == TaskStatus.canceled) {
    Log.error(
        "twonly Safe upload failed. ${update.responseStatusCode} ${update.responseBody} ${update.responseHeaders} ${update.exception}");
    await updateUserdata((user) {
      if (user.twonlySafeBackup != null) {
        user.twonlySafeBackup!.backupUploadState = LastBackupUploadState.failed;
      }
      return user;
    });
  } else if (update.status == TaskStatus.complete) {
    Log.error(
        "twonly Safe uploaded with status code ${update.responseStatusCode}");
    await updateUserdata((user) {
      if (user.twonlySafeBackup != null) {
        user.twonlySafeBackup!.backupUploadState =
            LastBackupUploadState.success;
      }
      return user;
    });
  } else {
    Log.info("Backup is in state: ${update.status}");
    return;
  }
  gUpdateBackupView();
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
