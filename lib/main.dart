import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mutex/mutex.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twonly/app.dart';
import 'package:twonly/core/bridge.dart' as bridge;
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/callbacks/callbacks.dart';
import 'package:twonly/src/constants/secure_storage.keys.dart';
import 'package:twonly/src/database/signal/signal_signed_pre_key_store.dart'
    show getSignalSignedPreKeyStoreOld;
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/signal_identity.model.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/providers/image_editor.provider.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/services/api/mediafiles/download.api.dart';
import 'package:twonly/src/services/api/mediafiles/media_background.api.dart';
import 'package:twonly/src/services/api/mediafiles/upload.api.dart';
import 'package:twonly/src/services/background/callback_dispatcher.background.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/memories/memories.service.dart';
import 'package:twonly/src/services/notifications/fcm.notifications.dart';
import 'package:twonly/src/services/notifications/setup.notifications.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/services/user_discovery.service.dart';
import 'package:twonly/src/utils/avatars.dart';
import 'package:twonly/src/utils/exclusive_access.utils.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/secure_storage.dart';
import 'package:twonly/src/utils/startup_guard.dart';
import 'package:twonly/src/visual/views/onboarding/setup.view.dart';

final _initMutex = Mutex();

/// This function is used to initialized the absolute minimum so it
/// can also be used by the backend without the UI was loaded.
Future<bool> twonlyMinimumInitialization() async {
  Log.info('twonlyMinimumInitialization: called');
  final hasStorageError = await exclusiveAccess(
    lockName: 'init',
    mutex: _initMutex,
    action: () async {
      Log.info('twonlyMinimumInitialization: started');
      setupLocator();

      Log.info('twonlyMinimumInitialization: RustLib.init()');
      await RustLib.init();

      Log.info('twonlyMinimumInitialization: initFlutterCallbacksForRust()');
      await initFlutterCallbacksForRust();

      Log.info('twonlyMinimumInitialization: bridge.initializeTwonlyFlutter()');
      try {
        await bridge.initializeTwonlyFlutter(
          config: bridge.InitConfig(
            databaseDir: AppEnvironment.supportDir,
            dataDir: AppEnvironment.supportDir,
          ),
        );
      } catch (e) {
        Log.error(e);
        return true;
      }
      Log.info('twonlyMinimumInitialization: finished');
      return false;
    },
  );
  return hasStorageError;
}

void main() async {
  final binding = SentryWidgetsFlutterBinding.ensureInitialized();
  await AppEnvironment.init();
  final stopwatch = Stopwatch()..start();

  unawaited(StartupGuard.markAppStartup());

  var storageError = await twonlyMinimumInitialization();
  await initFCMService();

  var userExists = false;

  var recoveryPossible = false;

  if (!storageError) {
    try {
      userExists = await userService.tryInit();
    } catch (e) {
      Log.error('Failed to initialize user session due to storage error: $e');
      storageError = true;
    }
  }

  if (!userExists && !storageError) {
    try {
      final userId = await RustKeyManager.getUserId();
      if (userId != null) {
        recoveryPossible = true;
      }
    } catch (e) {
      Log.error('Could not check KeyManager userId for iOS recovery: $e');
    }
  }

  Log.info('User loaded.');

  final settingsController = SettingsChangeProvider()..loadSettings();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  unawaited(initFileDownloader());

  if (userExists) {
    if (userService.currentUser.allowErrorTrackingViaSentry) {
      AppState.allowErrorTrackingViaSentry = true;
      await SentryFlutter.init(
        (options) => options
          ..dsn =
              'https://6b24a012c85144c9b522440a1d17d01c@glitchtip.twonly.eu/4'
          ..tracesSampleRate = 0.1
          ..enableAutoSessionTracking = false,
      );
    }

    await runMigrations();
    // We wait for the first frame to be rendered before starting heavy tasks.
    // This ensures the splash screen is dismissed on Android immediately.
    binding.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 1));
      unawaited(postStartupTasks());
      unawaited(apiService.connect());
    });
  }

  await apiService.listenToNetworkChanges();

  stopwatch.stop();

  Log.info(
    'Initialization finished after ${stopwatch.elapsed}. Calling runApp...',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsController),
        ChangeNotifierProvider(create: (_) => CustomChangeProvider()),
        ChangeNotifierProvider(create: (_) => ImageEditorProvider()),
        ChangeNotifierProvider(create: (_) => PurchasesProvider()),
      ],
      child: App(
        storageError: storageError,
        recoveryPossible: recoveryPossible,
      ),
    ),
  );
}

Future<void> runMigrations() async {
  if (userService.currentUser.appVersion < 90) {
    // BUG: Requested media files for reupload where not reuploaded because the wrong state...
    await twonlyDB.mediaFilesDao.updateAllRetransmissionUploadingState();
    await UserService.update((u) => u.appVersion = 90);
  }

  if (userService.currentUser.appVersion < 91) {
    // BUG: Requested media files for reupload where not reuploaded because the wrong state...
    await makeMigrationToVersion91();
    await UserService.update((u) => u.appVersion = 91);
  }

  if (userService.currentUser.appVersion < 109) {
    final contacts = await twonlyDB.contactsDao.getAllContacts();
    for (final contact in contacts) {
      if (contact.verified) {
        await twonlyDB.keyVerificationDao.addKeyVerification(
          contact.userId,
          VerificationType.migratedFromOldVersion,
        );
      }
    }
    await UserService.update((u) {
      u
        ..appVersion = 109
        ..skipSetupPages = true;
      if (u.avatarSvg == null) {
        u.currentSetupPage = SetupPages.profile.name;
      } else {
        u.currentSetupPage = SetupPages.shareYourFriends.name;
      }
    });
  }
  if (userService.currentUser.appVersion < 113) {
    var migrationSuccess = true;
    final signalIdentity = await SecureStorage.instance.read(
      // ignore: deprecated_member_use_from_same_package
      key: SecureStorageKeys.signalIdentity,
    );

    if (signalIdentity != null) {
      try {
        final decoded = jsonDecode(signalIdentity);
        final identity = SignalIdentity.fromJson(
          decoded as Map<String, dynamic>,
        );

        await RustKeyManager.importSignalIdentity(
          identityKeyPairStructure: identity.identityKeyPairU8List,
          registrationId: identity.registrationId,
          signedPreKeyStore: await getSignalSignedPreKeyStoreOld(),
        );
        Log.info('Importing signal identiy to the rust key manager');

        // Clean up old keys after successful migration
        await SecureStorage.instance.delete(
          // ignore: deprecated_member_use_from_same_package
          key: SecureStorageKeys.signalIdentity,
        );
        await SecureStorage.instance.delete(
          // ignore: deprecated_member_use_from_same_package
          key: SecureStorageKeys.signalSignedPreKey,
        );
      } catch (e) {
        Log.error('Failed to migrate signal identity: $e');
        migrationSuccess = false;
      }
    }

    if (migrationSuccess) {
      await UserService.update((u) {
        u
          ..appVersion = 113
          ..canUseLoginTokenForAuth = false
          // As usernames changes where not considered in the old version force users
          // to reenter there passwords.
          // ignore: deprecated_member_use_from_same_package
          ..twonlySafeBackup?.encryptionKey = []
          // ignore: deprecated_member_use_from_same_package
          ..twonlySafeBackup?.backupId = [];
      });
    }
  }
  if (userService.currentUser.appVersion < 114) {
    final allMedia = await twonlyDB.mediaFilesDao
        .select(twonlyDB.mediaFiles)
        .get();
    for (final media in allMedia) {
      if (media.createdAtMonth == null) {
        final monthStr = DateFormat('MMMM yyyy').format(media.createdAt);
        await twonlyDB.mediaFilesDao.updateMedia(
          media.mediaId,
          MediaFilesCompanion(createdAtMonth: Value(monthStr)),
        );
      }
    }
    await UserService.update((u) => u.appVersion = 114);
  }

  if (userService.currentUser.appVersion < 115) {
    var migrationSuccess = true;
    try {
      final rustStore = await RustKeyManager.loadSignedPrekeys();
      for (final entry in rustStore.entries) {
        final companion = SignalSignedPreKeyStoresCompanion(
          signedPreKeyId: Value(entry.key),
          signedPreKey: Value(entry.value),
        );
        await twonlyDB
            .into(twonlyDB.signalSignedPreKeyStores)
            .insert(
              companion,
              mode: InsertMode.insertOrReplace,
            );
        await RustKeyManager.removeSignedPrekey(signedPreKeyId: entry.key);
      }
    } catch (e) {
      Log.error('Failed to migrate signed prekeys to Drift: $e');
      migrationSuccess = false;
    }
    if (migrationSuccess) {
      await UserService.update((u) => u.appVersion = 115);
    }
  }

  if (kDebugMode) {
    assert(
      AppState.latestAppVersionId == 115,
      'Forgot to update the target version in runMigrations() after incrementing AppState.latestAppVersionId.',
    );
    assert(
      AppState.latestAppVersionId == userService.currentUser.appVersion,
      "Migration incomplete: currentUser.appVersion (${userService.currentUser.appVersion}) does not match AppState.latestAppVersionId (${AppState.latestAppVersionId}). Ensure the user's appVersion is updated in the migration block.",
    );
  }
}

Future<void> postStartupTasks() async {
  Log.info('Post startup started.');
  unawaited(MemoriesService.prewarmCache());

  // 1. Immediate background cleanup (Non-blocking for UI)
  await twonlyDB.messagesDao.purgeMessageTable();
  unawaited(twonlyDB.receiptsDao.purgeReceivedReceipts());
  unawaited(MediaFileService.purgeTempFolder());

  // 2. Service initializations
  unawaited(setupPushNotification());
  unawaited(finishStartedPreprocessing());
  unawaited(createPushAvatars());

  unawaited(UserDiscoveryService.verifyInitializationOnStartup());

  await Future.delayed(const Duration(seconds: 10));
  unawaited(initializeBackgroundTaskManager());
  // 3. Delayed tasks (Wait for app to settle)
  await Future.delayed(const Duration(minutes: 2));
  unawaited(BackupService.makeBackup());
  unawaited(cleanLogFile());
}
