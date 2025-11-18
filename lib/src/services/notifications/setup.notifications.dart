// ignore_for_file: unreachable_from_main

import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final StreamController<NotificationResponse> selectNotificationStream =
    StreamController<NotificationResponse>.broadcast();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    print(
      'notification action tapped with input: ${notificationResponse.input}',
    );
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

int id = 0;

Future<void> setupPushNotification() async {
  const initializationSettingsAndroid =
      AndroidInitializationSettings('ic_launcher_foreground');

  final darwinNotificationCategories = <DarwinNotificationCategory>[];

  /// Note: permissions aren't requested here just to demonstrate that can be
  /// done later
  final initializationSettingsDarwin = DarwinInitializationSettings(
    notificationCategories: darwinNotificationCategories,
  );

  final initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: selectNotificationStream.add,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
}
