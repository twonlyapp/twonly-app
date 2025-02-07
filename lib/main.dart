import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/api_provider.dart';
import 'package:twonly/src/providers/db_provider.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/providers/download_change_provider.dart';
import 'package:twonly/src/providers/messages_change_provider.dart';
import 'package:twonly/src/providers/contacts_change_provider.dart';
import 'package:twonly/src/providers/settings_change_provider.dart';
import 'package:twonly/src/utils/misc.dart';
import 'src/app.dart';

late DbProvider dbProvider;
late ApiProvider apiProvider;

/// Streams are created so that app can respond to notification-related events
/// since the plugin is initialized in the `main` function
final StreamController<NotificationResponse> selectNotificationStream =
    StreamController<NotificationResponse>.broadcast();

const MethodChannel platform =
    MethodChannel('dexterx.dev/flutter_local_notifications_example');

const String portName = 'notification_send_port';

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
    this.data,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
  final Map<String, dynamic>? data;
}

String? selectedNotificationPayload;

/// A notification action which triggers a url launch event
const String urlLaunchActionId = 'id_1';

/// A notification action which triggers a App navigation event
const String navigationActionId = 'id_3';

/// Defines a iOS/MacOS notification category for text input actions.
const String darwinNotificationCategoryText = 'textCategory';

/// Defines a iOS/MacOS notification category for plain actions.
const String darwinNotificationCategoryPlain = 'plainCategory';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    print(
        'notification action tapped with input: ${notificationResponse.input}');
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

int id = 0;

Future<void> setupPushNotification() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings("logo");

  final List<DarwinNotificationCategory> darwinNotificationCategories =
      <DarwinNotificationCategory>[
    DarwinNotificationCategory(
      darwinNotificationCategoryText,
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.text(
          'text_1',
          'Action 1',
          buttonTitle: 'Send',
          placeholder: 'Placeholder',
        ),
      ],
    ),
    DarwinNotificationCategory(
      darwinNotificationCategoryPlain,
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain('id_1', 'Action 1'),
        DarwinNotificationAction.plain(
          'id_2',
          'Action 2 (destructive)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.destructive,
          },
        ),
        DarwinNotificationAction.plain(
          navigationActionId,
          'Action 3 (foreground)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.foreground,
          },
        ),
        DarwinNotificationAction.plain(
          'id_4',
          'Action 4 (auth required)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.authenticationRequired,
          },
        ),
      ],
      options: <DarwinNotificationCategoryOption>{
        DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
      },
    )
  ];

  /// Note: permissions aren't requested here just to demonstrate that can be
  /// done later
  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
    notificationCategories: darwinNotificationCategories,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: selectNotificationStream.add,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
}

void main() async {
  final settingsController = SettingsChangeProvider();

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

  setupPushNotification();

  await initMediaStorage();

  dbProvider = DbProvider();
  // Database is just a file, so this will not block the loading of the app much
  await dbProvider.ready;

  var apiUrl = "ws://api.twonly.eu/api/client";
  var backupApiUrl = "ws://api2.twonly.eu/api/client";
  // if (!kReleaseMode) {
  // Overwrite the domain in your local network so you can test the app locally
  apiUrl = "ws://10.99.0.6:3030/api/client";
  // }

  apiProvider = ApiProvider(apiUrl: apiUrl, backupApiUrl: backupApiUrl);

  // Workmanager.executeTask((task, inputData) async {
  //   await _HomeState().manager();
  //   print('Background Services are Working!');//This is Working
  //   return true;
  // });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MessagesChangeProvider()),
        ChangeNotifierProvider(create: (_) => DownloadChangeProvider()),
        ChangeNotifierProvider(create: (_) => ContactChangeProvider()),
        ChangeNotifierProvider(create: (_) => settingsController),
      ],
      child: MyApp(),
    ),
  );
}
