import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:background_downloader/background_downloader.dart';
import 'package:clock/clock.dart' as clock;
import 'package:http/http.dart' as http;
import 'package:mutex/mutex.dart';
import 'package:twonly/core/bridge.dart' as bridge;
import 'package:twonly/core/bridge/wrapper/backup.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/model/json/backup.model.dart';
import 'package:twonly/src/services/api/utils.api.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

class BackupService {
  static final Mutex _protected = Mutex();

  static String _getIdentityBackupUrl(String backupId) =>
      '${apiService.apiEndpoint}/backup/identity/$backupId';

  static String _getArchiveBackupUrl(String backupDownloadToken, int? userId) =>
      '${apiService.apiEndpoint}/backup/archive/${userId == null ? '' : '${userId.toRadixString(16).padLeft(16, '0').toUpperCase()}/'}$backupDownloadToken';

  static final _backupUpdateController = StreamController<void>.broadcast();
  static Stream<void> get onBackupUpdated => _backupUpdateController.stream;

  static Future<CurrentBackupStatus> getData() async {
    return CurrentBackupStatus.fromJson(
      (await KeyValueStore.get(KeyValueKeys.currentBackupState)) ??
          CurrentBackupStatus().toJson(),
    );
  }

  static Future<void> updateBackupPassword(String password) async {
    // Set or reset the backup data...
    await KeyValueStore.put(
      KeyValueKeys.currentBackupState,
      CurrentBackupStatus().toJson(),
    );
    _backupUpdateController.add(null);

    await RustBackupIdentity.setBackupPasswordKeys(
      password: password,
      // Using the userId is this will never change in a users lifecycle
      userId: userService.currentUser.userId,
    );

    await UserService.update((u) => u.isBackupEnabled = true);

    unawaited(makeBackup(force: true));
  }

  static Future<void> handleBackupStatusUpdate(
    String taskId,
    TaskStatusUpdate update,
  ) async {
    var status = LastBackupUploadState.success;

    if (update.status == TaskStatus.failed ||
        update.status == TaskStatus.canceled) {
      status = LastBackupUploadState.failed;
    } else if (update.status != TaskStatus.complete) {
      Log.info('Backup is in state: ${update.status}');
      return;
    }
    await _protected.protect(() async {
      final backup = await getData();
      if (taskId == 'backup_identity') {
        backup
          ..identityLastSuccessFull = clock.clock.now()
          ..identityState = status;
      } else {
        backup
          ..archiveLastSuccessFull = clock.clock.now()
          ..archiveState = status;
      }
      await KeyValueStore.put(
        KeyValueKeys.currentBackupState,
        backup.toJson(),
      );
      _backupUpdateController.add(null);
    });
  }

  static Future<void> makeBackup({bool force = false}) async {
    await _protected.protect(() async {
      final backup = await getData();

      final lastDay = clock.clock.now().subtract(const Duration(days: 1));
      final lastWeek = clock.clock.now().subtract(const Duration(days: 7));

      if (force ||
          backup.identityLastSuccessFull == null ||
          (backup.identityState != LastBackupUploadState.pending &&
                  backup.identityLastSuccessFull!.isBefore(lastWeek) ||
              backup.identityLastSuccessFull!.isBefore(
                lastWeek.subtract(const Duration(days: 1)),
              ))) {
        Log.info('Performing a identity backup.');
        final encryptedBackup =
            await RustBackupIdentity.getIdentityBackupBytes();

        final backupTempFile = File(
          '${AppEnvironment.cacheDir}/identity_backup.bin',
        )..writeAsBytesSync(encryptedBackup);

        Log.info(
          'Identity backup has a size of ${backupTempFile.statSync().size}.',
        );

        final backupId = await RustBackupIdentity.getBackupId();
        if (backupId == null) {
          Log.error('Got empty backup id.');
          backup.identityState = LastBackupUploadState.failed;
        } else {
          final task = UploadTask.fromFile(
            taskId: 'backup_identity',
            httpRequestMethod: 'PUT',
            file: backupTempFile,
            url: _getIdentityBackupUrl(backupId),
            post: 'binary',
            retries: 2,
            headers: {
              'Content-Type': 'application/octet-stream',
            },
          );
          if (await FileDownloader().enqueue(task)) {
            Log.info('Starting upload from backup identity.');
            backup
              ..identityState = LastBackupUploadState.pending
              ..identityLastSuccessFull = clock.clock.now()
              ..identitySize = encryptedBackup.length;
            await KeyValueStore.put(
              KeyValueKeys.currentBackupState,
              backup.toJson(),
            );
            _backupUpdateController.add(null);
          } else {
            Log.error('Error starting upload task for backup identity.');
          }
        }
      }

      if (force ||
          backup.archiveLastSuccessFull == null ||
          (backup.archiveState != LastBackupUploadState.pending &&
                  backup.archiveLastSuccessFull!.isBefore(lastDay) ||
              backup.archiveLastSuccessFull!.isBefore(
                lastDay.subtract(const Duration(days: 1)),
              ))) {
        Log.info('Creating a archive backup.');
        late final String backupArchive;
        late final String backupDownloadToken;
        try {
          (backupDownloadToken, backupArchive) =
              await RustBackupArchive.createBackupArchive();
        } catch (e) {
          Log.error(e);
          return;
        }
        Log.info(
          'Archive backup has a size of ${File(backupArchive).statSync().size}.',
        );

        final headers = await getAuthenticationHeader();
        if (headers == null) {
          Log.error('Auth headers are empty. Returning');
          return;
        }

        final task = UploadTask.fromFile(
          taskId: 'backup_archive',
          file: File(backupArchive),
          url: _getArchiveBackupUrl(backupDownloadToken, null),
          priority: 0,
          retries: 10,
          headers: headers,
        );
        if (await FileDownloader().enqueue(task)) {
          Log.info('Uploading backup archive.');
          backup
            ..archiveState = LastBackupUploadState.pending
            ..archiveLastSuccessFull = clock.clock.now()
            ..archiveSize = File(backupArchive).statSync().size;
          await KeyValueStore.put(
            KeyValueKeys.currentBackupState,
            backup.toJson(),
          );
          _backupUpdateController.add(null);
        } else {
          Log.error('Error starting upload task for backup archive.');
        }
      }
    });
  }

  static Future<BackupRecovery?> getBackupRecoveryData() async {
    final stateJson = await KeyValueStore.get(KeyValueKeys.backupRecoveryState);
    if (stateJson == null) return null;
    return BackupRecovery.fromJson(stateJson);
  }

  static Future<RecoveryError?> _nextBackupStage() async {
    return _protected.protect(() async {
      final recoveryData = await getBackupRecoveryData();
      if (recoveryData == null) return null;

      if (recoveryData.state == BackupRecoveryState.identityBackupStarted) {
        // First start to download the identity to restore the KeyManager
        final backupKeys = await RustBackupIdentity.getBackupPasswordKeys(
          userId: recoveryData.userId,
          password: recoveryData.password,
        );
        final backupId = uint8ListToHex(backupKeys.backupId);
        final backupServerUrl = _getIdentityBackupUrl(backupId);
        final (encryptedBytes, error) = await _downloadBackup(backupServerUrl);
        if (error != null || encryptedBytes == null) {
          Log.error(error);
          return error;
        }

        Log.info('Restored identity.');

        try {
          await RustBackupIdentity.restoreIdentityBackup(
            keys: backupKeys,
            encryptedBytes: encryptedBytes,
          );
          recoveryData.state = BackupRecoveryState.archiveBackupStarted;
          await KeyValueStore.put(
            KeyValueKeys.backupRecoveryState,
            recoveryData.toJson(),
          );
          _backupUpdateController.add(null);
        } catch (e) {
          Log.error(e);
          return RecoveryError.unkownError;
        }
      }

      if (recoveryData.state == BackupRecoveryState.archiveBackupStarted) {
        // The KeyManager was restored sucessfully, restore the archive now.
        try {
          final downloadToken =
              await RustBackupArchive.getBackupDownloadToken();
          if (downloadToken == null) {
            // identity was not restored correctly try this again.
            recoveryData.state = BackupRecoveryState.identityBackupStarted;
            await KeyValueStore.put(
              KeyValueKeys.backupRecoveryState,
              recoveryData.toJson(),
            );
            return RecoveryError.tryAgainLater;
          }

          final backupServerUrl = _getArchiveBackupUrl(
            downloadToken,
            recoveryData.userId,
          );
          final backupArchive = await _downloadBackup(backupServerUrl);
          if (backupArchive.$2 != null || backupArchive.$1 == null) {
            return backupArchive.$2;
          }

          final archiveFile = File('${AppEnvironment.cacheDir}/archive.bin')
            ..writeAsBytesSync(backupArchive.$1!);

          await RustBackupArchive.restoreBackupArchive(
            filePath: archiveFile.path,
          );
          await UserService.update((u) {
            u.deviceId += 1;
          });
          await KeyValueStore.delete(
            KeyValueKeys.backupRecoveryState,
          );
        } catch (e) {
          Log.error(e);
          return RecoveryError.unkownError;
        }
      }

      return null;
    });
  }

  static Future<RecoveryError?> startFullBackupRecovery(
    String username,
    String password,
  ) async {
    final userId = await apiService.getUserIdFromUsername(username);
    if (userId == null) {
      return RecoveryError.usernameNotValid;
    }

    final state = BackupRecovery(
      username: username,
      userId: userId,
      password: password,
    );

    await deleteLocalUserData();
    try {
      await bridge.initializeTwonlyFlutter(
        config: bridge.InitConfig(
          databaseDir: AppEnvironment.supportDir,
          dataDir: AppEnvironment.supportDir,
        ),
      );
    } catch (e) {
      Log.error(e);
      return RecoveryError.unkownError;
    }
    await KeyValueStore.put(KeyValueKeys.backupRecoveryState, state.toJson());
    return _nextBackupStage();
  }

  static Future<(Uint8List?, RecoveryError?)> _downloadBackup(
    String backupServerUrl,
  ) async {
    late http.Response response;

    try {
      response = await http.get(
        Uri.parse(backupServerUrl),
        headers: {
          HttpHeaders.acceptHeader: 'application/octet-stream',
        },
      );
    } catch (e) {
      Log.error('Error fetching backup: $e');
      return (null, RecoveryError.noInternet);
    }

    Log.warn('Backup downlaod status: ${response.statusCode}');

    switch (response.statusCode) {
      case 200:
        return (response.bodyBytes, null);
      case 404:
        return (null, RecoveryError.passwordInvalid);
      default:
        return (null, RecoveryError.tryAgainLater);
    }
  }
}

enum RecoveryError {
  usernameNotValid,
  passwordInvalid,
  tryAgainLater,
  noInternet,
  unkownError,
}
