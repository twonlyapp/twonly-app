import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mutex/mutex.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twonly/app.dart';
import 'package:twonly/core/bridge.dart' as bridge;
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/callbacks/callbacks.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/providers/image_editor.provider.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/services/api/mediafiles/download.api.dart';
import 'package:twonly/src/services/api/mediafiles/media_background.api.dart';
import 'package:twonly/src/services/api/mediafiles/upload.api.dart';
import 'package:twonly/src/services/background/callback_dispatcher.background.dart';
import 'package:twonly/src/services/backup/create.backup.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
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
Future<void> twonlyMinimumInitialization() async {
  Log.info('twonlyMinimumInitialization: called');
  await exclusiveAccess(
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
      await bridge.initializeTwonlyFlutter(
        config: bridge.TwonlyConfig(
          databasePath: '${AppEnvironment.supportDir}/twonly.sqlite',
          dataDirectory: AppEnvironment.supportDir,
        ),
      );
      Log.info('twonlyMinimumInitialization: finished');
    },
  );
}

void main() async {
  final binding = SentryWidgetsFlutterBinding.ensureInitialized();
  await AppEnvironment.init();
  final stopwatch = Stopwatch()..start();

  unawaited(StartupGuard.markAppStartup());

  await twonlyMinimumInitialization();

  unawaited(initFCMService());

  var userExists = false;
  var storageError = false;

  try {
    userExists = await userService.tryInit();
  } catch (e) {
    Log.error('Failed to initialize user session due to storage error: $e');
    storageError = true;
  }

  if (Platform.isIOS && userExists) {
    final dbFile = File('${AppEnvironment.supportDir}/twonly.sqlite');
    if (!dbFile.existsSync()) {
      Log.error('[twonly] IOS: App was removed and then reinstalled again...');
      await SecureStorage.instance.deleteAll();
      userExists = false;
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
      child: App(storageError: storageError),
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
}

Future<void> postStartupTasks() async {
  Log.info('Post startup started.');
  // 1. Immediate background cleanup (Non-blocking for UI)
  await twonlyDB.messagesDao.purgeMessageTable();
  unawaited(twonlyDB.receiptsDao.purgeReceivedReceipts());
  unawaited(UserDiscoveryService.removeDeletedContacts());
  unawaited(MediaFileService.purgeTempFolder());

  // 2. Service initializations
  unawaited(setupPushNotification());
  unawaited(finishStartedPreprocessing());
  unawaited(createPushAvatars());

  await Future.delayed(const Duration(seconds: 10));
  unawaited(initializeBackgroundTaskManager());
  // 3. Delayed tasks (Wait for app to settle)
  await Future.delayed(const Duration(minutes: 2));
  unawaited(performTwonlySafeBackup());
  unawaited(cleanLogFile());
}
