import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mutex/mutex.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twonly/app.dart';
import 'package:twonly/core/bridge.dart' as bridge;
import 'package:twonly/core/bridge/wrapper/app_database.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/callbacks/callbacks.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/providers/image_editor.provider.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/services/home_widget.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/memories/memories.service.dart';
import 'package:twonly/src/services/migrations.service.dart';
import 'package:twonly/src/services/notifications/fcm.notifications.dart';
import 'package:twonly/src/services/notifications/native.notifications.dart';
import 'package:twonly/src/services/notifications/setup.notifications.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/startup_guard.dart';
import 'package:twonly/src/visual/themes/light.dart';

final _initMutex = Mutex();

/// This function is used to initialize the absolute minimum so it
/// can also be used by the backend without the UI was loaded.
Future<bool> twonlyMinimumInitialization() async {
  Log.info('twonlyMinimumInitialization: called');
  final hasStorageError = await _initMutex.protect(() async {
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
      Log.enableRustSink();
      if (!await RustAppDatabase.legacyImportComplete()) {
        final legacyFile = File(
          '${AppEnvironment.supportDir}/twonly.sqlite',
        );
        if (legacyFile.existsSync()) {
          final legacyDatabase = TwonlyDB(NativeDatabase(legacyFile));
          // Opening the database applies every existing Drift migration up
          // to v25 before Rust copies the application tables.
          await legacyDatabase.customSelect('PRAGMA user_version').getSingle();
          await legacyDatabase.close();
        }
        await RustAppDatabase.migrateLegacyDatabase();
      }
    } catch (e) {
      // Tracing is initialized before the rest of the Rust context, so even
      // failed initialization can persist the buffered startup diagnostics.
      Log.enableRustSink();
      Log.error(e);
      return true;
    }
    Log.info('twonlyMinimumInitialization: finished');
    return false;
  });
  return hasStorageError;
}

/// What the UI needs to know before it can pick a route.
class StartupResult {
  const StartupResult({
    required this.storageError,
    required this.recoveryPossible,
  });
  final bool storageError;
  final bool recoveryPossible;
}

void main() {
  SentryWidgetsFlutterBinding.ensureInitialized();

  // `App` used to set this as it mounted, which was at the same moment the
  // engine started. It now mounts only once startup finishes, and the API can
  // authenticate before that — `ApiService.onAuthenticated` skips its
  // foreground work while this is true, so it has to be correct from the start.
  AppState.isAppInBackground = false;

  // Registering the services is a few map insertions and needs nothing from
  // storage, but it has to happen before the settings provider can read the
  // user's theme.
  setupLocator();
  final settingsController = SettingsChangeProvider()..loadSettings();

  // A platform call that nothing below depends on.
  unawaited(
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  );

  // Storage, Rust, Firebase and the network are all reached from `_startup`,
  // and the app renders a splash until it completes. Nothing here is awaited,
  // so the first frame is drawn while that work is still running instead of
  // after it — the native splash used to stay up for the whole chain.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsController),
        ChangeNotifierProvider(create: (_) => CustomChangeProvider()),
        ChangeNotifierProvider(create: (_) => ImageEditorProvider()),
        ChangeNotifierProvider(create: (_) => PurchasesProvider()),
      ],
      child: TwonlyBootstrap(startup: _startup(settingsController)),
    ),
  );
}

/// Everything the app cannot run without, off the first-frame path.
///
/// Never completes with an error: a failure here has to reach the UI as a
/// storage error, because a rejected future would leave the splash up forever.
Future<StartupResult> _startup(SettingsChangeProvider settings) async {
  final stopwatch = Stopwatch()..start();
  try {
    await AppEnvironment.init();

    // Preload available cameras in the background to speed up camera tab startup
    unawaited(
      availableCameras().then((cameras) {
        AppEnvironment.cameras = cameras;
      }),
    );
    unawaited(StartupGuard.markAppStartup());

    // Firebase and the local notification plugin are platform-side setup that
    // touches neither storage nor Rust, so they run alongside the Rust
    // initialization rather than queueing behind it. Both are awaited before
    // this returns, because the home view subscribes to them as it mounts.
    // Failing to set up notifications must not stop the rest of the app.
    final notificationSetup =
        Future.wait<void>([
          FcmNotificationService.initStartup(),
          setupPushNotification(),
        ]).then((_) {}).catchError((Object error, StackTrace stackTrace) {
          Log.error(
            'Notification setup failed',
            error: error,
            stackTrace: stackTrace,
          );
        });

    var storageError = await twonlyMinimumInitialization();

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

    await notificationSetup;
    NativeNotificationService.init();

    // The theme was read before the user was known, so re-read it now that it
    // is. Repainting the splash costs nothing; the app UI is built after this.
    settings.loadSettings();

    if (userExists) {
      unawaited(FcmNotificationService.initAfterUserLoaded());

      if (userService.currentUser.allowErrorTrackingViaSentry) {
        AppState.allowErrorTrackingViaSentry = true;
        // Not awaited: error reporting does not have to be live before the
        // first screen is.
        unawaited(
          SentryFlutter.init(
            (options) => options
              ..dsn =
                  'https://6b24a012c85144c9b522440a1d17d01c@glitchtip.twonly.eu/4'
              ..tracesSampleRate = 0.1
              ..enableAutoSessionTracking = false,
          ),
        );
      }

      // Data migrations have to finish before any screen reads the database.
      await runMigrations();

      // Heavy background work waits for the app to settle rather than
      // competing with the first frames of the real UI.
      unawaited(
        Future<void>.delayed(
          const Duration(seconds: 1),
        ).then((_) => postStartupTasks()),
      );
    }

    unawaited(apiService.listenToNetworkChanges());

    stopwatch.stop();
    Log.info('Startup finished after ${stopwatch.elapsed}.');

    return StartupResult(
      storageError: storageError,
      recoveryPossible: recoveryPossible,
    );
  } catch (error, stackTrace) {
    Log.error('Startup failed', error: error, stackTrace: stackTrace);
    return const StartupResult(storageError: true, recoveryPossible: false);
  }
}

/// Shows the splash until [startup] resolves, then hands over to [App].
class TwonlyBootstrap extends StatelessWidget {
  const TwonlyBootstrap({required this.startup, super.key});

  final Future<StartupResult> startup;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StartupResult>(
      future: startup,
      builder: (context, snapshot) {
        final result = snapshot.data;
        if (result == null) return const _SplashView();
        return App(
          storageError: result.storageError,
          recoveryPossible: result.recoveryPossible,
        );
      },
    );
  }
}

/// The first frame. Painted in the same color as the Android launch theme's
/// `windowSplashScreenBackground` and the iOS launch screen, so handing over
/// from the OS splash is not visible.
class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'twonly',
      home: ColoredBox(
        color: defaultPrimaryColor,
        child: SizedBox.expand(),
      ),
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
  unawaited(HomeWidgetService.purgeExpiredMedia());
  unawaited(HomeWidgetService.syncPermissions());

  // 2. Service initializations
  unawaitedRustCall(
    RustApi.finishStartedMediaUploads(),
    'finishStartedMediaUploads',
  );
  unawaited(
    newsService.init().then((_) {
      final lastDownload = newsService.lastDownloadedAt;
      if (lastDownload == null ||
          DateTime.now().difference(lastDownload) >= const Duration(days: 7)) {
        newsService.fetchFeed();
      }
    }),
  );

  // 3. Delayed tasks (Wait for app to settle)
  await Future.delayed(const Duration(minutes: 2));
  unawaited(BackupService.makeBackup());
  unawaited(cleanLogFile());
}
