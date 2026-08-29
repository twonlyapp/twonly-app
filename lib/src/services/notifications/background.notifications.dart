import 'dart:async';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> customLocalPushNotification(String title, String msg) async {
  final androidNotificationDetails = AndroidNotificationDetails(
    '1',
    'System',
    channelDescription: 'System messages.',
    importance: Importance.high,
    priority: Priority.high,
    styleInformation: BigTextStyleInformation(msg),
    icon: 'ic_launcher_foreground',
  );

  const darwinNotificationDetails = DarwinNotificationDetails();
  final notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
    iOS: darwinNotificationDetails,
  );

  final id = Random.secure().nextInt(9999);

  await flutterLocalNotificationsPlugin.show(
    id,
    title,
    msg,
    notificationDetails,
  );
}
