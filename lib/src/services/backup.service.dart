import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:clock/clock.dart' as clock;
import 'package:http/http.dart' as http;
import 'package:mutex/mutex.dart';
import 'package:twonly/core/bridge/wrapper/backup.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/model/json/backup.model.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

class BackupService {
  static final Mutex _protected = Mutex();
  static const _retryDelay = Duration(minutes: 15);
  static const _uploadTimeout = Duration(minutes: 10);
  static Timer? _retryTimer;

  static String _getIdentityBackupUrl(String backupId) =>
      '${RustApi.apiBaseUrl(protocol: 'https')}backup/identity/$backupId';

  static String _getArchiveBackupUrl(String backupDownloadToken, int? userId) =>
      '${RustApi.apiBaseUrl(protocol: 'https')}backup/archive/${userId == null ? '' : '${userId.toRadixString(16).padLeft(16, '0').toUpperCase()}/'}$backupDownloadToken';

  static final _backupUpdateController = StreamController<void>.broadcast();
  static Stream<void> get onBackupUpdated => _backupUpdateController.stream;

  static void _scheduleRetry() {
    if (_retryTimer?.isActive ?? false) return;
    _retryTimer = Timer(_retryDelay, () {
      _retryTimer = null;
      unawaited(makeBackup());
    });
  }

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

  static Future<void> _saveStatus(CurrentBackupStatus backup) async {
    await KeyValueStore.put(
      KeyValueKeys.currentBackupState,
      backup.toJson(),
    );
    _backupUpdateController.add(null);
  }

  static bool _isSuccessful(http.BaseResponse response) =>
      response.statusCode >= 200 && response.statusCode < 300;

  static Future<bool> _uploadIdentity(
    String backupId,
    List<int> encryptedBackup,
  ) async {
    final client = http.Client();
    try {
      final response = await client
          .put(
            Uri.parse(_getIdentityBackupUrl(backupId)),
            headers: const {'Content-Type': 'application/octet-stream'},
            body: encryptedBackup,
          )
          .timeout(_uploadTimeout);
      if (_isSuccessful(response)) return true;
      Log.error(
        'Identity backup upload failed with status ${response.statusCode}.',
      );
    } catch (error, stackTrace) {
      Log.error(
        'Identity backup upload failed.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      client.close();
    }
    return false;
  }

  static Future<bool> _uploadArchive(
    String backupDownloadToken,
    File archive,
    Map<String, String> headers,
  ) async {
    final client = http.Client();
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_getArchiveBackupUrl(backupDownloadToken, null)),
      )..headers.addAll(headers);
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          archive.path,
          filename: archive.uri.pathSegments.last,
        ),
      );

      final streamedResponse = await client
          .send(request)
          .timeout(
            _uploadTimeout,
          );
      final response = await http.Response.fromStream(
        streamedResponse,
      ).timeout(_uploadTimeout);
      if (_isSuccessful(response)) return true;
      Log.error(
        'Archive backup upload failed with status ${response.statusCode}.',
      );
    } catch (error, stackTrace) {
      Log.error(
        'Archive backup upload failed.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      client.close();
    }
    return false;
  }

  static Future<void> makeBackup({bool force = false}) async {
    await _protected.protect(() async {
      final backup = await getData();

      final lastDay = clock.clock.now().subtract(const Duration(days: 1));
      final lastWeek = clock.clock.now().subtract(const Duration(days: 7));

      if (force ||
          backup.identityState != LastBackupUploadState.success ||
          backup.identityLastSuccessFull == null ||
          backup.identityLastSuccessFull!.isBefore(lastWeek)) {
        final backupId = await RustBackupIdentity.getBackupId();
        if (backupId == null) {
          Log.warn('No backup password was set by the user.');
          backup.identityState = LastBackupUploadState.failed;
          await _saveStatus(backup);
          await UserService.update((u) => u.isBackupEnabled = false);
        } else {
          Log.info('Performing a identity backup.');
          List<int>? encryptedBackup;
          try {
            encryptedBackup = await RustBackupIdentity.getIdentityBackupBytes();
          } catch (error, stackTrace) {
            Log.error(
              'Creating identity backup failed.',
              error: error,
              stackTrace: stackTrace,
            );
            backup.identityState = LastBackupUploadState.failed;
            await _saveStatus(backup);
            _scheduleRetry();
          }

          if (encryptedBackup != null) {
            Log.info(
              'Identity backup has a size of ${encryptedBackup.length}.',
            );

            backup
              ..identityState = LastBackupUploadState.pending
              ..identitySize = encryptedBackup.length;
            await _saveStatus(backup);

            if (await _uploadIdentity(backupId, encryptedBackup)) {
              Log.info('Identity backup uploaded.');
              backup
                ..identityState = LastBackupUploadState.success
                ..identityLastSuccessFull = clock.clock.now();
            } else {
              backup.identityState = LastBackupUploadState.failed;
              _scheduleRetry();
            }
            await _saveStatus(backup);
          }
        }
      }

      if (force ||
          backup.archiveState != LastBackupUploadState.success ||
          backup.archiveLastSuccessFull == null ||
          backup.archiveLastSuccessFull!.isBefore(lastDay)) {
        Log.info('Creating a archive backup.');
        late final String backupArchive;
        late final String backupDownloadToken;
        try {
          (backupDownloadToken, backupArchive) =
              await RustBackupArchive.createBackupArchive();
        } catch (e) {
          Log.warn('Creating archive backup failed: $e');
          backup.archiveState = LastBackupUploadState.failed;
          await _saveStatus(backup);
          _scheduleRetry();
          return;
        }
        Log.info(
          'Archive backup has a size of ${File(backupArchive).statSync().size}.',
        );

        late final Map<String, String> headers;
        try {
          headers = await RustApi.authenticationHeaders();
        } catch (error) {
          Log.error('Could not load authentication headers', error: error);
          backup.archiveState = LastBackupUploadState.failed;
          await _saveStatus(backup);
          _scheduleRetry();
          return;
        }

        final archive = File(backupArchive);
        backup
          ..archiveState = LastBackupUploadState.pending
          ..archiveSize = archive.statSync().size;
        await _saveStatus(backup);

        if (await _uploadArchive(backupDownloadToken, archive, headers)) {
          Log.info('Backup archive uploaded.');
          backup
            ..archiveState = LastBackupUploadState.success
            ..archiveLastSuccessFull = clock.clock.now();
        } else {
          backup.archiveState = LastBackupUploadState.failed;
          _scheduleRetry();
        }
        await _saveStatus(backup);
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
        // The KeyManager was restored successfully, restore the archive now.
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

  static Future<RecoveryError?> tryToReinstallTheArchive() async {
    final userId = await RustKeyManager.getUserId();
    if (userId == null) return null;

    final state = BackupRecovery(
      username: '',
      userId: userId,
      password: '',
    )..state = BackupRecoveryState.archiveBackupStarted;
    await KeyValueStore.put(KeyValueKeys.backupRecoveryState, state.toJson());
    return _nextBackupStage();
  }

  static Future<RecoveryError?> startFullBackupRecovery(
    String username,
    String password,
  ) async {
    late final int userId;
    try {
      userId = await RustApi.getUserIdFromUsername(username: username);
    } catch (error) {
      Log.error('Could not resolve backup username', error: error);
      return RecoveryError.usernameNotValid;
    }

    final state = BackupRecovery(
      username: username,
      userId: userId,
      password: password,
    );

    await deleteLocalUserData(removeCredentials: true);
    await KeyValueStore.put(KeyValueKeys.backupRecoveryState, state.toJson());
    return _nextBackupStage();
  }

  static Future<RecoveryError?> startPasswordlessBackupRecovery(
    int userId,
    String username,
    Uint8List keyManagerBytes,
  ) async {
    final state = BackupRecovery(
      username: username,
      password: '',
      userId: userId,
    )..state = BackupRecoveryState.archiveBackupStarted;

    await deleteLocalUserData(removeCredentials: true);

    // Import KeyManager keys into secure storage & in-memory key manager
    await RustKeyManager.importSerialized(serializedBytes: keyManagerBytes);

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
      Log.warn('Error fetching backup: $e');
      return (null, RecoveryError.noInternet);
    }

    Log.info('Backup downlaod status: ${response.statusCode}');

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
