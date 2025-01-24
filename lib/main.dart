import 'package:flutter/foundation.dart';
import 'package:twonly/src/providers/api_provider.dart';
import 'package:twonly/src/providers/db_provider.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/utils/misc.dart';
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

late DbProvider dbProvider;
late ApiProvider apiProvider;

void main() async {
  final settingsController = SettingsController(SettingsService());

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = kReleaseMode ? Level.INFO : Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (kReleaseMode) {
      writeLogToFile(record);
    } else {
      debugPrint(
          '${record.level.name}: twonly:${record.loggerName}: ${record.message}');
    }
  });

  dbProvider = DbProvider();
  // Database is just a file, so this will not block the loading of the app much
  await dbProvider.ready;

  var apiUrl = "ws://api.twonly.eu/api/client";
  var backupApiUrl = "ws://api2.twonly.eu/api/client";
  if (!kReleaseMode) {
    // Overwrite the domain in your local network so you can test the app locally
    apiUrl = "ws://10.99.0.6:3030/api/client";
  }

  apiProvider = ApiProvider(apiUrl: apiUrl, backupApiUrl: backupApiUrl);

  // Workmanager.executeTask((task, inputData) async {
  //   await _HomeState().manager();
  //   print('Background Services are Working!');//This is Working
  //   return true;
  // });

  runApp(MyApp(settingsController: settingsController));
}
