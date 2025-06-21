import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/providers/image_editor.provider.dart';
import 'package:twonly/src/services/api/media_download.dart';
import 'package:twonly/src/services/api/media_upload.dart';
import 'package:twonly/src/services/api.service.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/services/fcm.service.dart';
import 'package:twonly/src/services/notifications/setup.notifications.dart';
import 'package:twonly/src/services/twonly_safe/create_backup.twonly_safe.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFCMService();

  initLogger();

  final user = await getUser();
  if (user != null) {
    if (user.isDemoUser) {
      await deleteLocalUserData();
    }
  }

  final settingsController = SettingsChangeProvider();
  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  setupPushNotification();

  gCameras = await availableCameras();

  apiService = ApiService();
  twonlyDB = TwonlyDatabase();
  await twonlyDB.messagesDao.resetPendingDownloadState();
  await twonlyDB.messagesDao.handleMediaFilesOlderThan7Days();
  await twonlyDB.signalDao.purgeOutDatedPreKeys();

  // purge media files in the background
  purgeReceivedMediaFiles();
  purgeSendMediaFiles();

  performTwonlySafeBackup();

  await initFileDownloader();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsController),
        ChangeNotifierProvider(create: (_) => CustomChangeProvider()),
        ChangeNotifierProvider(create: (_) => ImageEditorProvider()),
      ],
      child: App(),
    ),
  );
}
