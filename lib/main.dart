import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/providers/api/media_received.dart';
import 'package:twonly/src/providers/api/media_send.dart';
import 'package:twonly/src/providers/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/providers/connection_provider.dart';
import 'package:twonly/src/providers/hive.dart';
import 'package:twonly/src/providers/settings_change_provider.dart';
import 'package:twonly/src/services/fcm_service.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFCMService();

  final settingsController = SettingsChangeProvider();
  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  setupLogger();

  await setupPushNotification();
  await initMediaStorage();

  gCameras = await availableCameras();

  apiProvider = ApiProvider();
  twonlyDatabase = TwonlyDatabase();
  await twonlyDatabase.messagesDao.resetPendingDownloadState();
  await purgeReceivedMediaFiles();
  await purgeSendMediaFiles();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsController),
        ChangeNotifierProvider(create: (_) => ConnectionChangeProvider()),
      ],
      child: App(),
    ),
  );
}
