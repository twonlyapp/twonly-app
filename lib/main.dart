// ignore_for_file: unused_import

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twonly/app.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/providers/image_editor.provider.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/services/api.service.dart';
import 'package:twonly/src/services/api/mediafiles/media_background.service.dart';
import 'package:twonly/src/services/api/mediafiles/upload.service.dart';
import 'package:twonly/src/services/fcm.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/notifications/setup.notifications.dart';
import 'package:twonly/src/services/twonly_safe/create_backup.twonly_safe.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';

void main() async {
  SentryWidgetsFlutterBinding.ensureInitialized();

  // try {
  //   File(join((await getApplicationSupportDirectory()).path, 'twonly.sqlite'))
  //       .deleteSync();
  // } catch (e) {}
  // await updateUserdata((u) {
  //   u.appVersion = 0;
  //   return u;
  // });

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

  await initFCMService();

  initLogger();

  final settingsController = SettingsChangeProvider();

  await settingsController.loadSettings();
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );

  unawaited(setupPushNotification());

  gCameras = await availableCameras();

  apiService = ApiService();
  twonlyDB = TwonlyDB();

  await twonlyDB.messagesDao.purgeMessageTable();
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
      ],
      child: const App(),
    ),
  );
}
