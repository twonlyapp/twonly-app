import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/providers/image_editor.provider.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/services/api/mediafiles/media_background.api.dart';
import 'package:twonly/src/services/api/mediafiles/upload.api.dart';
import 'package:twonly/src/services/background/callback_dispatcher.background.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/memories/memories.service.dart';
import 'package:twonly/src/services/migrations.service.dart';
import 'package:twonly/src/services/notifications/fcm.notifications.dart';
import 'package:twonly/src/services/notifications/setup.notifications.dart';
import 'package:twonly/src/services/user_discovery.service.dart';
import 'package:twonly/src/utils/avatars.dart';
import 'package:twonly/src/utils/exclusive_access.utils.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/startup_guard.dart';

final _initMutex = Mutex();

/// This function is used to initialized the absolute minimum so it
/// can also be used by the backend without the UI was loaded.
Future<bool> twonlyMinimumInitialization() async {
  Log.info('twonlyMinimumInitialization: called');
  final hasStorageError = await exclusiveAccess(
    lockName: 'init',
    mutex: _initMutex,
    action: () async {
      Log.info('twonlyMinimumInitialization started');
      setupLocator();

      await RustLib.init();

      await initFlutterCallbacksForRust();

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
  await FcmNotificationService.initStartup();
  await setupPushNotification();

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
    unawaited(FcmNotificationService.initAfterUserLoaded());

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

Future<void> postStartupTasks() async {
  Log.info('Post startup started.');
  unawaited(MemoriesService.prewarmCache());

  // 1. Immediate background cleanup (Non-blocking for UI)
  await twonlyDB.messagesDao.purgeMessageTable();
  unawaited(twonlyDB.receiptsDao.purgeReceivedReceipts());
  unawaited(MediaFileService.purgeTempFolder());

  // 2. Service initializations
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
