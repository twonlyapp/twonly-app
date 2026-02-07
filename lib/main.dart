import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twonly/app.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/providers/image_editor.provider.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/services/api.service.dart';
import 'package:twonly/src/services/api/mediafiles/media_background.service.dart';
import 'package:twonly/src/services/api/mediafiles/upload.service.dart';
import 'package:twonly/src/services/fcm.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/notifications/setup.notifications.dart';
import 'package:twonly/src/services/twonly_safe/create_backup.twonly_safe.dart';
import 'package:twonly/src/utils/avatars.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';

void main() async {
  SentryWidgetsFlutterBinding.ensureInitialized();

  await initFCMService();

  final user = await getUser();
  if (user != null) {
    gUser = user;

    if (user.allowErrorTrackingViaSentry) {
      globalAllowErrorTrackingViaSentry = true;
      await SentryFlutter.init(
        (options) => options
          ..dsn =
              'https://6b24a012c85144c9b522440a1d17d01c@glitchtip.twonly.eu/4'
          ..tracesSampleRate = 0.1
          ..enableAutoSessionTracking = false,
      );
    }

    unawaited(performTwonlySafeBackup());
  }

  globalApplicationCacheDirectory = (await getApplicationCacheDirectory()).path;
  globalApplicationSupportDirectory =
      (await getApplicationSupportDirectory()).path;

  initLogger();

  final settingsController = SettingsChangeProvider();

  await settingsController.loadSettings();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  unawaited(setupPushNotification());

  gCameras = await availableCameras();

  apiService = ApiService();
  twonlyDB = TwonlyDB();

  if (user != null) {
    if (gUser.appVersion < 90) {
      // BUG: Requested media files for reupload where not reuploaded because the wrong state...
      await twonlyDB.mediaFilesDao.updateAllRetransmissionUploadingState();
      await updateUserdata((u) {
        u.appVersion = 90;
        return u;
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
