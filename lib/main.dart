import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/api_provider.dart';
import 'package:twonly/src/providers/db_provider.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/providers/download_change_provider.dart';
import 'package:twonly/src/providers/messages_change_provider.dart';
import 'package:twonly/src/providers/contacts_change_provider.dart';
import 'package:twonly/src/providers/send_next_media_to.dart';
import 'package:twonly/src/providers/settings_change_provider.dart';
import 'package:twonly/src/services/fcm_service.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'src/app.dart';

void main() async {
  final settingsController = SettingsChangeProvider();

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = kReleaseMode ? Level.INFO : Level.ALL;
  Logger.root.onRecord.listen((record) {
    writeLogToFile(record);
    if (kDebugMode) {
      print(
          '${record.level.name}: twonly:${record.loggerName}: ${record.message}');
    }
  });

  await setupPushNotification();
  await initMediaStorage();
  await initFCMService();

  dbProvider = DbProvider();
  await dbProvider.ready;

  apiProvider = ApiProvider();

  FlutterForegroundTask.initCommunicationPort();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MessagesChangeProvider()),
        ChangeNotifierProvider(create: (_) => DownloadChangeProvider()),
        ChangeNotifierProvider(create: (_) => ContactChangeProvider()),
        ChangeNotifierProvider(create: (_) => SendNextMediaTo()),
        ChangeNotifierProvider(create: (_) => settingsController),
      ],
      child: MyApp(),
    ),
  );
}
