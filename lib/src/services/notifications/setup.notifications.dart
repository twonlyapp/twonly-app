import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/globals.dart';

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
        'notification action tapped with input: ${notificationResponse.input}');
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

Future<void> createPushAvatars() async {
  if (!Platform.isAndroid) {
    return; // avatars currently only shown in Android...
  }
  final contacts = await twonlyDB.contactsDao.getAllNotBlockedContacts();

  for (final contact in contacts) {
    if (contact.avatarSvg == null) return;

    final pictureInfo =
        await vg.loadPicture(SvgStringLoader(contact.avatarSvg!), null);

    final image = await pictureInfo.picture.toImage(300, 300);

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    // Get the directory to save the image
    final directory = await getApplicationCacheDirectory();
    final avatarsDirectory = Directory('${directory.path}/avatars');

    // Create the avatars directory if it does not exist
    if (!avatarsDirectory.existsSync()) {
      await avatarsDirectory.create(recursive: true);
    }
    final filePath = '${avatarsDirectory.path}/${contact.userId}.png';
    await File(filePath).writeAsBytes(pngBytes);
    pictureInfo.picture.dispose();
  }
}
