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
import 'package:twonly/src/services/backup/backup_fallback_policy.dart';
import 'package:twonly/src/services/backup/backup_schedule.dart';
import 'package:twonly/src/services/backup/native_backup_schedule.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

class BackupService {
  static final Mutex _protected = Mutex();
  static const _retryDelay = Duration(minutes: 15);
  static Timer? _retryTimer;
  static bool _startupFallbackPending = false;
  static Future<void>? _startupFallbackCheck;
  static final _schedule = BackupSchedule(
    isVisible: () => !AppState.isAppInBackground,
    perform: _performBackup,
    loadForced: () async =>
        (await KeyValueStore.get(
          KeyValueKeys.forcedBackupPending,
        ))?['pending'] ==
        true,
    saveForced: (force) => KeyValueStore.putAtomically(
      KeyValueKeys.forcedBackupPending,
      {'pending': force},
    ),
  );

  static Future<void> resumePendingBackup() async {
    await _schedule.resume();
    await _checkStartupFallback();
    // A native job may have updated status while Flutter was suspended.
    _backupUpdateController.add(null);
  }

  /// Called once after startup. If startup finished while backgrounded, keep
  /// the check pending until the next visible session.
  static Future<void> checkStartupBackupFallback() async {
    _startupFallbackPending = true;
    await _checkStartupFallback();
  }

  static Future<void> _checkStartupFallback() async {
    if (!_startupFallbackPending || AppState.isAppInBackground) return;
    if (_protected.isLocked) {
      _startupFallbackPending = false;
      return;
    }
    await (_startupFallbackCheck ??= Future<void>.microtask(
      _evaluateStartupFallback,
    ).whenComplete(() => _startupFallbackCheck = null));
  }

  static Future<void> _evaluateStartupFallback() async {
    try {
      if (!userService.isUserCreated ||
          !userService.currentUser.isBackupEnabled ||
          await getBackupRecoveryData() != null) {
        _startupFallbackPending = false;
        return;
      }
      final stored = await KeyValueStore.get(
        KeyValueKeys.backupFallbackMonitoring,
      );
      final now = clock.clock.now();
      final since = stored?['since'] as String?;
      final monitoringSince = since == null ? null : DateTime.tryParse(since);
      if (monitoringSince == null) {
        await KeyValueStore.putAtomically(
          KeyValueKeys.backupFallbackMonitoring,
          {'since': now.toIso8601String()},
        );
      }
      final schedule = await NativeBackupScheduler.getSchedule();
      // Read after the OS query: a native worker or a manual request may have
      // completed while the channel was answering.
      final backup = await getData();
      if (AppState.isAppInBackground) return;
      if (!_startupFallbackPending) return;
      _startupFallbackPending = false;
      if (BackupFallbackPolicy.shouldRun(
        backup: backup,
        schedule: schedule,
        now: clock.clock.now(),
        monitoringSince: monitoringSince ?? now,
      )) {
        Log.info('Starting foreground backup fallback after startup.');
        await makeBackup();
      }
    } catch (error, stackTrace) {
      Log.warn('Could not check startup backup fallback.', error, stackTrace);
    }
  }

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
    await KeyValueStore.putAtomically(
      KeyValueKeys.backupFallbackMonitoring,
      {'since': clock.clock.now().toIso8601String()},
    );
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

  /// Setup/settings requests and an admitted startup fallback run while visible.
  /// Routine automatic backups belong to the native OS schedulers.
  static Future<void> makeBackup({bool force = false}) =>
      _schedule.request(force: force);

  static Future<bool> _performBackup(bool force) =>
      _protected.protect(() async {
        if (AppState.isAppInBackground) return false;
        if (!userService.isUserCreated ||
            !userService.currentUser.isBackupEnabled) {
          return true;
        }
        if (await getBackupRecoveryData() != null) return false;
        // A manual/persisted foreground request already covers this startup;
        // do not immediately repeat it from an in-flight fallback check.
        _startupFallbackPending = false;
        try {
          final completed = await RustBackupArchive.uploadBackup(force: force);
          if (!completed) _scheduleRetry();
          return completed;
        } catch (error, stackTrace) {
          Log.warn('Backup deferred; will retry.', error, stackTrace);
          _scheduleRetry();
          return false;
        } finally {
          _backupUpdateController.add(null);
        }
      });

  static Future<BackupRecovery?> getBackupRecoveryData() async {
    final stateJson = await KeyValueStore.get(KeyValueKeys.backupRecoveryState);
    if (stateJson == null) return null;
    return BackupRecovery.fromJson(stateJson);
  }

  static Future<RecoveryError?> _nextBackupStage({
    void Function(RecoveryProgress)? onProgress,
  }) async {
    return _protected.protect(() async {
      final recoveryData = await getBackupRecoveryData();
      if (recoveryData == null) return null;

      if (recoveryData.state == BackupRecoveryState.identityBackupStarted) {
        onProgress?.call(RecoveryProgress.restoringIdentity);
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

        Log.info('Downloaded identity backup.');

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
        // The identity is staged; restore its matching archive now.
        onProgress?.call(RecoveryProgress.downloadingArchive);
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

          onProgress?.call(RecoveryProgress.extractingData);

          final archiveFile = File('${AppEnvironment.cacheDir}/archive.bin')
            ..writeAsBytesSync(backupArchive.$1!);

          await RustBackupArchive.restoreBackupArchive(
            filePath: archiveFile.path,
          );
          Log.info('Restored the backup archive.');
          await UserService.update((u) {
            u.deviceId += 1;
          });
          Log.info('Bumped the device id after the recovery.');
          await KeyValueStore.delete(
            KeyValueKeys.backupRecoveryState,
          );
          Log.info('Recovery finished, restarting the app.');
        } catch (e) {
          Log.error(e);
          return RecoveryError.unkownError;
        }
      }

      return null;
    });
  }

  static Future<RecoveryError?> tryToReinstallTheArchive({
    void Function(RecoveryProgress)? onProgress,
  }) async {
    final userId = await RustKeyManager.getUserId();
    if (userId == null) return null;

    // Select the current identity rather than a previous recovery attempt.
    await RustKeyManager.importSerialized(
      serializedBytes: await RustKeyManager.serialize(),
    );

    final state = BackupRecovery(
      username: '',
      userId: userId,
      password: '',
    )..state = BackupRecoveryState.archiveBackupStarted;
    await KeyValueStore.put(KeyValueKeys.backupRecoveryState, state.toJson());
    return _nextBackupStage(onProgress: onProgress);
  }

  static Future<RecoveryError?> startFullBackupRecovery(
    String username,
    String password, {
    void Function(RecoveryProgress)? onProgress,
  }) async {
    onProgress?.call(RecoveryProgress.resolvingAccount);
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

    await KeyValueStore.put(KeyValueKeys.backupRecoveryState, state.toJson());
    return _nextBackupStage(onProgress: onProgress);
  }

  static Future<RecoveryError?> startPasswordlessBackupRecovery(
    int userId,
    String username,
    Uint8List keyManagerBytes, {
    void Function(RecoveryProgress)? onProgress,
  }) async {
    final state = BackupRecovery(
      username: username,
      password: '',
      userId: userId,
    )..state = BackupRecoveryState.archiveBackupStarted;

    onProgress?.call(RecoveryProgress.restoringIdentity);
    // Stage the recovered identity while preserving the current database keys.
    await RustKeyManager.importSerialized(serializedBytes: keyManagerBytes);
    Log.info('Staged the recovered key manager.');

    await KeyValueStore.put(KeyValueKeys.backupRecoveryState, state.toJson());
    Log.info('Stored the recovery state, entering the archive stage.');
    return _nextBackupStage(onProgress: onProgress);
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

/// Granular steps of a backup recovery, reported via the `onProgress`
/// callback so the UI can show the user what is currently happening.
enum RecoveryProgress {
  resolvingAccount,
  restoringIdentity,
  downloadingArchive,
  extractingData,
}
