import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:twonly/src/utils/avatars.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/secure_storage.dart';
import 'package:twonly/src/visual/views/onboarding/setup.view.dart';

/// This function is used to initialized the absolute minimum so it
/// can also be used by the backend without the UI was loaded.
Future<void> twonlyMinimumInitialization() async {
  SentryWidgetsFlutterBinding.ensureInitialized();

  await AppEnvironment.init();
  Log.init();
  setupLocator();

  await RustLib.init();

  await initFlutterCallbacksForRust();

  await bridge.initializeTwonlyFlutter(
    config: bridge.TwonlyConfig(
      databasePath: '${AppEnvironment.supportDir}/twonly.sqlite',
      dataDirectory: AppEnvironment.supportDir,
    ),
  );
}

void main() async {
  await twonlyMinimumInitialization();

  await initFCMService();

  var userExists = false;
  var storageError = false;

  try {
    userExists = await userService.tryInit();
  } catch (e) {
    Log.error('Failed to initialize user session due to storage error: $e');
    storageError = true;
  }

  final dbExists = File(
    '${AppEnvironment.supportDir}/twonly.sqlite',
  ).existsSync();

  if (Platform.isIOS && userExists) {
    if (!dbExists) {
      Log.error('[twonly] IOS: App was removed and then reinstalled again...');
      await SecureStorage.instance.deleteAll();
      userExists = false;
    }
  }

  final settingsController = SettingsChangeProvider()..loadSettings();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initFileDownloader();

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

    unawaited(performTwonlySafeBackup());
    unawaited(initializeBackgroundTaskManager());

    await runMigrations();

    await twonlyDB.messagesDao.purgeMessageTable();
    await twonlyDB.receiptsDao.purgeReceivedReceipts();

    unawaited(MediaFileService.purgeTempFolder());

    unawaited(setupPushNotification());
    unawaited(finishStartedPreprocessing());
    unawaited(createPushAvatars());
  }

  await apiService.listenToNetworkChanges();
  unawaited(apiService.connect());

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
        u.currentSetupPage = SetupPages.userDiscovery.name;
      }
    });
  }
}
