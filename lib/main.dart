import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twonly/app.dart';
import 'package:twonly/core/bridge.dart' as bridge;
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/callbacks/callbacks.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/providers/image_editor.provider.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/services/api.service.dart';
import 'package:twonly/src/services/api/mediafiles/download.service.dart';
import 'package:twonly/src/services/api/mediafiles/media_background.service.dart';
import 'package:twonly/src/services/api/mediafiles/upload.service.dart';
import 'package:twonly/src/services/background/callback_dispatcher.background.dart';
import 'package:twonly/src/services/backup/create.backup.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/notifications/fcm.notifications.dart';
import 'package:twonly/src/services/notifications/setup.notifications.dart';
import 'package:twonly/src/utils/avatars.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';

void main() async {
  SentryWidgetsFlutterBinding.ensureInitialized();

  await RustLib.init();
  await AppEnvironment.init();

  initLogger();

  await initFlutterCallbacksForRust();

  await bridge.initializeTwonlyFlutter(
    config: bridge.TwonlyConfig(
      databasePath: '${AppEnvironment.supportDir}/twonly.sqlite',
      dataDirectory: AppEnvironment.supportDir,
    ),
  );

  await initFCMService();

  var user = await getUser();

  if (Platform.isIOS && user != null) {
    final db = File('${AppEnvironment.supportDir}/twonly.sqlite');
    if (!db.existsSync()) {
      Log.error('[twonly] IOS: App was removed and then reinstalled again...');
      await const FlutterSecureStorage().deleteAll();
      user = await getUser();
    }
  }

  if (user != null) {
    AppSession.currentUser = user;

    if (user.allowErrorTrackingViaSentry) {
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
  } else {
    Log.info('User is not yet register. Ensure all local data is removed.');
    await deleteLocalUserData();
  }

  final settingsController = SettingsChangeProvider();

  await settingsController.loadSettings();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  unawaited(setupPushNotification());

  apiService = ApiService();
  twonlyDB = TwonlyDB();

  if (user != null) {
    if (AppSession.currentUser.appVersion < 90) {
      // BUG: Requested media files for reupload where not reuploaded because the wrong state...
      await twonlyDB.mediaFilesDao.updateAllRetransmissionUploadingState();
      await updateUser((u) {
        u.appVersion = 90;
      });
    }
    if (AppSession.currentUser.appVersion < 91) {
      // BUG: Requested media files for reupload where not reuploaded because the wrong state...
      await makeMigrationToVersion91();
      await updateUser((u) {
        u.appVersion = 91;
      });
    }
  }

  await twonlyDB.messagesDao.purgeMessageTable();
  await twonlyDB.receiptsDao.purgeReceivedReceipts();
  unawaited(MediaFileService.purgeTempFolder());

  await initFileDownloader();
  unawaited(finishStartedPreprocessing());

  unawaited(createPushAvatars());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsController),
        ChangeNotifierProvider(create: (_) => CustomChangeProvider()),
        ChangeNotifierProvider(create: (_) => ImageEditorProvider()),
        ChangeNotifierProvider(create: (_) => PurchasesProvider()),
      ],
      child: const App(),
    ),
  );
}
