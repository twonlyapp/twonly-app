import 'dart:convert';
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:cryptography_flutter_plus/cryptography_flutter_plus.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/model/protobuf/backup/backup.pb.dart';
import 'package:twonly/src/services/api/media_upload.dart';
import 'package:twonly/src/services/twonly_safe/common.twonly_safe.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/settings/backup/backup.view.dart';

Future<void> performTwonlySafeBackup({bool force = false}) async {
  final user = await getUser();

  if (user == null || user.twonlySafeBackup == null || user.isDemoUser) {
    return;
  }

  if (user.twonlySafeBackup!.backupUploadState ==
      LastBackupUploadState.pending) {
    Log.warn('Backup upload is already pending.');
    return;
  }

  final DateTime? lastUpdateTime = user.twonlySafeBackup!.lastBackupDone;
  if (!force && lastUpdateTime != null) {
    if (lastUpdateTime
        .isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
      return;
    }
  }

  Log.info('Starting new twonly Safe-Backup!');

  final baseDir = (await getApplicationSupportDirectory()).path;

  final backupDir = Directory(join(baseDir, 'backup_twonly_safe/'));
  await backupDir.create(recursive: true);

  final backupDatabaseFile =
      File(join(backupDir.path, 'twonly_database.backup.sqlite'));

  final backupDatabaseFileCleaned =
      File(join(backupDir.path, 'twonly_database.backup.cleaned.sqlite'));

  // copy database
  final originalDatabase = File(join(baseDir, 'twonly_database.sqlite'));
  await originalDatabase.copy(backupDatabaseFile.path);

  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final backupDB = TwonlyDatabase(
    driftDatabase(
      name: 'twonly_database.backup',
      native: DriftNativeOptions(
        databaseDirectory: () async {
          return backupDir;
        },
      ),
    ),
  );

  await backupDB.deleteDataForTwonlySafe();

  await backupDB
      .customStatement('VACUUM INTO ?', [backupDatabaseFileCleaned.path]);

  await backupDB.printTableSizes();

  await backupDB.close();

  // ignore: inference_failure_on_collection_literal
  final secureStorageBackup = {};
  const storage = FlutterSecureStorage();
  secureStorageBackup[SecureStorageKeys.signalIdentity] =
      await storage.read(key: SecureStorageKeys.signalIdentity);
  secureStorageBackup[SecureStorageKeys.signalSignedPreKey] =
      await storage.read(key: SecureStorageKeys.signalSignedPreKey);

  final userBackup = await getUser();
  if (userBackup == null) return;
  // FILTER settings which should not be in the backup
  userBackup
    ..twonlySafeBackup = null
    ..lastImageSend = null
    ..todaysImageCounter = null
    ..lastPlanBallance = ''
    ..additionalUserInvites = ''
    ..signalLastSignedPreKeyUpdated = null;

  secureStorageBackup[SecureStorageKeys.userData] = jsonEncode(userBackup);

  // Compress and convert backup data

  final twonlyDatabaseBytes = await backupDatabaseFileCleaned.readAsBytes();
  await backupDatabaseFile.delete();
  await backupDatabaseFileCleaned.delete();

  Log.info('twonlyDatabaseLength = ${twonlyDatabaseBytes.lengthInBytes}');
  Log.info('secureStorageLength = ${jsonEncode(secureStorageBackup).length}');

  final backupProto = TwonlySafeBackupContent(
    secureStorageJson: jsonEncode(secureStorageBackup),
    twonlyDatabase: twonlyDatabaseBytes,
  );

  final backupBytes = gzip.encode(backupProto.writeToBuffer());

  final backupHash = uint8ListToHex((await Sha256().hash(backupBytes)).bytes);

  if (user.twonlySafeBackup!.lastBackupDone == null ||
      user.twonlySafeBackup!.lastBackupDone!
          .isAfter(DateTime.now().subtract(const Duration(days: 90)))) {
    force = true;
  }

  final lastHash =
      await storage.read(key: SecureStorageKeys.twonlySafeLastBackupHash);

  if (lastHash != null && !force) {
    if (backupHash == lastHash) {
      Log.info('Since last backup nothing has changed.');
      return;
    }
  }
  await storage.write(
    key: SecureStorageKeys.twonlySafeLastBackupHash,
    value: backupHash,
  );

  // Encrypt backup data

  final chacha20 = FlutterChacha20.poly1305Aead();
  final nonce = chacha20.newNonce();

  final secretBox = await chacha20.encrypt(
    backupBytes,
    secretKey: SecretKey(user.twonlySafeBackup!.encryptionKey),
    nonce: nonce,
  );

  final encryptedBackupBytes = TwonlySafeBackupEncrypted(
    mac: secretBox.mac.bytes,
    nonce: nonce,
    cipherText: secretBox.cipherText,
  ).writeToBuffer();

  Log.info('Backup files created.');

  final encryptedBackupBytesFile =
      File(join(backupDir.path, 'twonly_safe.backup'));

  await encryptedBackupBytesFile.writeAsBytes(encryptedBackupBytes);

  Log.info(
      'Create twonly Safe backup with a size of ${encryptedBackupBytes.length} bytes.');

  if (user.backupServer != null) {
    if (encryptedBackupBytes.length > user.backupServer!.maxBackupBytes) {
      Log.error('Backup is to big for the alternative backup server.');
      await updateUserdata((user) {
        user.twonlySafeBackup!.backupUploadState = LastBackupUploadState.failed;
        return user;
      });
      return;
    }
  }

  final task = UploadTask.fromFile(
    taskId: 'backup',
    file: encryptedBackupBytesFile,
    httpRequestMethod: 'PUT',
    url: (await getTwonlySafeBackupUrl())!,
    // requiresWiFi: true,
    priority: 5,
    post: 'binary',
    retries: 2,
    headers: {
      'Content-Type': 'application/octet-stream',
    },
  );
  if (await FileDownloader().enqueue(task)) {
    Log.info('Starting upload from twonly Safe backup.');
    await updateUserdata((user) {
      user.twonlySafeBackup!.backupUploadState = LastBackupUploadState.pending;
      user.twonlySafeBackup!.lastBackupDone = DateTime.now();
      user.twonlySafeBackup!.lastBackupSize = encryptedBackupBytes.length;
      return user;
    });
    gUpdateBackupView();
  } else {
    Log.error('Error starting UploadTask for twonly Safe.');
  }
}

Future<void> handleBackupStatusUpdate(TaskStatusUpdate update) async {
  if (update.status == TaskStatus.failed ||
      update.status == TaskStatus.canceled) {
    Log.error(
        'twonly Safe upload failed. ${update.responseStatusCode} ${update.responseBody} ${update.responseHeaders} ${update.exception}');
    await updateUserdata((user) {
      if (user.twonlySafeBackup != null) {
        user.twonlySafeBackup!.backupUploadState = LastBackupUploadState.failed;
      }
      return user;
    });
  } else if (update.status == TaskStatus.complete) {
    Log.error(
        'twonly Safe uploaded with status code ${update.responseStatusCode}');
    await updateUserdata((user) {
      if (user.twonlySafeBackup != null) {
        user.twonlySafeBackup!.backupUploadState =
            LastBackupUploadState.success;
      }
      return user;
    });
  } else {
    Log.info('Backup is in state: ${update.status}');
    return;
  }
  gUpdateBackupView();
}
