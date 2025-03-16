import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/contacts_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/json_models/message.dart' as my;

/// Streams are created so that app can respond to notification-related events
/// since the plugin is initialized in the `main` function
final StreamController<NotificationResponse> selectNotificationStream =
    StreamController<NotificationResponse>.broadcast();

const MethodChannel platform = MethodChannel('twonly.eu/notifications');

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
      AndroidInitializationSettings("ic_launcher_foreground");

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

String getPushNotificationText(String key, String userName) {
  String systemLanguage = Platform.localeName;

  Map<String, String> pushNotificationText;

  if (systemLanguage.contains("de")) {
    pushNotificationText = {
      "newTextMessage": "%userName% hat dir eine Nachricht gesendet.",
      "newTwonly": "%userName% hat dir ein twonly gesendet.",
      "newVideo": "%userName% hat dir ein Video gesendet.",
      "newImage": "%userName% hat dir ein Bild gesendet.",
      "contactRequest": "%userName% möchte sich mir dir vernetzen.",
      "acceptRequest": "%userName% ist jetzt mit dir vernetzt.",
    };
  } else {
    pushNotificationText = {
      "newTextMessage": "%userName% has sent you a message.",
      "newTwonly": "%userName% has sent you a twonly.",
      "newVideo": "%userName% has sent you a video.",
      "newImage": "%userName% has sent you an image.",
      "contactRequest": "%userName% wants to connect with you.",
      "acceptRequest": "%userName% is now connected with you.",
    };
  }

  // Replace %userName% with the actual user name
  return pushNotificationText[key]?.replaceAll("%userName%", userName) ?? "";
}

Future localPushNotificationNewMessage(
    int fromUserId, my.MessageJson message, int messageId) async {
  Contact? user = await twonlyDatabase.contactsDao
      .getContactByUserId(fromUserId)
      .getSingleOrNull();

  if (user == null) return;

  String msg = "";

  final content = message.content;

  if (content is my.TextMessageContent) {
    msg =
        getPushNotificationText("newTextMessage", getContactDisplayName(user));
  } else if (content is my.MediaMessageContent) {
    if (content.isRealTwonly) {
      msg = getPushNotificationText("newTwonly", getContactDisplayName(user));
    } else if (content.isVideo) {
      msg = getPushNotificationText("newVideo", getContactDisplayName(user));
    } else {
      msg = getPushNotificationText("newImage", getContactDisplayName(user));
    }
  }

  if (message.kind == my.MessageKind.contactRequest) {
    msg =
        getPushNotificationText("contactRequest", getContactDisplayName(user));
  }

  if (message.kind == my.MessageKind.acceptRequest) {
    msg = getPushNotificationText("acceptRequest", getContactDisplayName(user));
  }

  if (msg == "") {
    Logger("localPushNotificationNewMessage")
        .shout("No push notification type defined!");
  }

  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    '0',
    'Messages',
    channelDescription: 'Messages from other users.',
    importance: Importance.max,
    priority: Priority.max,
    ticker: 'You got a new message.',
  );
  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails);
  await flutterLocalNotificationsPlugin.show(
    messageId,
    getContactDisplayName(user),
    msg,
    notificationDetails,
    payload: message.kind.index.toString(),
  );
}
