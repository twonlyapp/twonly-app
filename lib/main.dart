import 'package:camera/camera.dart';
import 'package:twonly/src/providers/api_provider.dart';
import 'package:twonly/src/providers/db_provider.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

late DbProvider dbProvider;
late ApiProvider apiProvider;

void main() async {
  // Set up the SettingsController, which will glue user settings to multiple
  // Flutter Widgets.
  final settingsController = SettingsController(SettingsService());

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    debugPrint(
        '${record.level.name}: twonly:${record.loggerName}: ${record.message}');
  });

  var cameras = await availableCameras();

  // Create or open the database
  dbProvider = DbProvider();
  await dbProvider.ready;

  // Create an option to select different servers.
  var apiUrl = "ws://api.theconnectapp.de/v-1/";
  if (true) {
    // Overwrite the domain in your local network so you can test the app locally
    apiUrl = "ws://10.99.0.6:3030/api/client";
  }

  apiProvider = ApiProvider(apiUrl: apiUrl, backupApiUrl: null);

  // Workmanager.executeTask((task, inputData) async {
  //   await _HomeState().manager();
  //   print('Background Services are Working!');//This is Working
  //   return true;
  // });

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(MyApp(settingsController: settingsController, cameras: cameras));
}
