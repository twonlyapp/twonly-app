// ignore_for_file: unused_import

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
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
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFCMService();

  initLogger();

  final user = await getUser();
  if (user != null) {
    gUser = user;
  }

  final settingsController = SettingsChangeProvider();

  await settingsController.loadSettings();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // unawaited(setupPushNotification());

  gCameras = await availableCameras();

  // try {
  //   File(join((await getApplicationSupportDirectory()).path, 'twonly.sqlite'))
  //       .deleteSync();
  // } catch (e) {}
  // await updateUserdata((u) {
  //   u.appVersion = 0;
  //   return u;
  // });

  apiService = ApiService();
  twonlyDB = TwonlyDB();

  await initFileDownloader();
  unawaited(finishStartedPreprocessing());

  unawaited(MediaFileService.purgeTempFolder());
  await twonlyDB.messagesDao.purgeMessageTable();

  // await twonlyDB.messagesDao.resetPendingDownloadState();
  // await twonlyDB.messageRetransmissionDao.purgeOldRetransmissions();
  // await twonlyDB.signalDao.purgeOutDatedPreKeys();

  // unawaited(purgeSendMediaFiles());

  // unawaited(performTwonlySafeBackup());

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
