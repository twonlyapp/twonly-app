import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/providers/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/providers/hive.dart';
import 'package:twonly/src/providers/settings_change_provider.dart';
import 'package:twonly/src/services/fcm_service.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFCMService();

  final settingsController = SettingsChangeProvider();
  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  Logger.root.level = kReleaseMode ? Level.INFO : Level.ALL;
  Logger.root.onRecord.listen((record) {
    writeLogToFile(record);
    if (kDebugMode) {
      print(
          '${record.level.name}: twonly:${record.loggerName}: ${record.message}');
    }
  });

  // await deleteLogFile();

  await setupPushNotification();
  await initMediaStorage();

  gCameras = await availableCameras();

  apiProvider = ApiProvider();
  twonlyDatabase = TwonlyDatabase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsController),
      ],
      child: MyApp(),
    ),
  );
}
