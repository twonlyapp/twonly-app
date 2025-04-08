import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/json_models/message.dart' as my;
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/utils/misc.dart';

class PushUser {
  String displayName;
  List<PushKeyMeta> keys;

  PushUser({
    required this.displayName,
    required this.keys,
  });

  // Factory method to create a User from JSON
  factory PushUser.fromJson(Map<String, dynamic> json) {
    return PushUser(
      displayName: json['displayName'],
      keys: (json['keys'] as List)
          .map((keyJson) => PushKeyMeta.fromJson(keyJson))
          .toList(),
    );
  }

  // Method to convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'keys': keys.map((key) => key.toJson()).toList(),
    };
  }
}

class PushKeyMeta {
  int id;
  List<int> key;
  DateTime createdAt;

  PushKeyMeta({
    required this.id,
    required this.key,
    required this.createdAt,
  });

  // Factory method to create Keys from JSON
  factory PushKeyMeta.fromJson(Map<String, dynamic> json) {
    return PushKeyMeta(
      id: json['id'],
      key: List<int>.from(json['key']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }

  // Method to convert Keys to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'createdAt': createdAt.millisecondsSinceEpoch, // Store as timestamp
    };
  }
}

/// This function must be called after the database is setup
Future setupNotificationWithUsers({bool force = false}) async {
  var pushKeys = await getPushKeys("receivingPushKeys");

  var wasChanged = false;

  final random = Random.secure();

  final contacts = await twonlyDatabase.contactsDao.getAllNotBlockedContacts();
  for (final contact in contacts) {
    if (pushKeys.containsKey(contact.userId)) {
      // make it harder to predict the change of the key
      final timeBefore =
          DateTime.now().subtract(Duration(days: 5 + random.nextInt(5)));
      final lastKey = pushKeys[contact.userId]!.keys.last;
      if (force || lastKey.createdAt.isBefore(timeBefore)) {
        final pushKey = PushKeyMeta(
          id: lastKey.id + 1,
          key: List<int>.generate(32, (index) => random.nextInt(256)),
          createdAt: DateTime.now(),
        );
        await sendNewPushKey(contact.userId, pushKey);
        pushKeys[contact.userId]!.keys.add(pushKey);
        pushKeys[contact.userId]!.displayName = getContactDisplayName(contact);
        wasChanged = true;
      }
    } else {
      /// Insert a new pushuser
      final pushKey = PushKeyMeta(
        id: 1,
        key: List<int>.generate(32, (index) => random.nextInt(256)),
        createdAt: DateTime.now(),
      );
      await sendNewPushKey(contact.userId, pushKey);
      final pushUser = PushUser(
        displayName: getContactDisplayName(contact),
        keys: [pushKey],
      );
      pushKeys[contact.userId] = pushUser;
      wasChanged = true;
    }
  }

  if (wasChanged) {
    await setPushKeys("receivingPushKeys", pushKeys);
  }
}

Future sendNewPushKey(int userId, PushKeyMeta pushKey) async {
  await encryptAndSendMessage(
    null,
    userId,
    my.MessageJson(
      kind: MessageKind.pushKey,
      content: my.PushKeyContent(keyId: pushKey.id, key: pushKey.key),
      timestamp: pushKey.createdAt,
    ),
  );
}

Future handleNewPushKey(int fromUserId, my.PushKeyContent pushKey) async {
  var pushKeys = await getPushKeys("sendingPushKeys");

  if (pushKeys[fromUserId] == null) {
    pushKeys[fromUserId] = PushUser(displayName: "-", keys: []);
  }

  // only store the newest key...
  pushKeys[fromUserId]!.keys = [
    PushKeyMeta(
      id: pushKey.keyId,
      key: pushKey.key,
      createdAt: DateTime.now(),
    ),
  ];

  await setPushKeys("sendingPushKeys", pushKeys);
}

enum PushKind {
  reaction,
  text,
  video,
  twonly,
  image,
  contactRequest,
  acceptRequest,
  storedMediaFile,
  testNotification
}

extension PushKindExtension on PushKind {
  String get name => toString().split('.').last;

  static PushKind fromString(String name) {
    return PushKind.values.firstWhere((e) => e.name == name);
  }
}

class PushNotification {
  final int keyId;
  final List<int> nonce;
  final List<int> cipherText;
  final List<int> mac;

  PushNotification({
    required this.keyId,
    required this.nonce,
    required this.cipherText,
    required this.mac,
  });

  // Convert a PushNotification instance to a Map
  Map<String, dynamic> toJson() {
    return {
      'keyId': keyId,
      'nonce': base64Encode(nonce),
      'cipherText': base64Encode(cipherText),
      'mac': base64Encode(mac),
    };
  }

  // Create a PushNotification instance from a Map
  factory PushNotification.fromJson(Map<String, dynamic> json) {
    return PushNotification(
      keyId: json['keyId'],
      nonce: base64Decode(json['nonce']),
      cipherText: base64Decode(json['cipherText']),
      mac: base64Decode(json['mac']),
    );
  }
}

/// this will trigger a push notification
/// push notification only containing the message kind and username
Future<List<int>?> getPushData(int toUserId, PushKind kind) async {
  final Map<int, PushUser> pushKeys = await getPushKeys("sendingPushKeys");

  List<int> key = "InsecureOnlyUsedForAddingContact".codeUnits;
  int keyId = 0;

  if (pushKeys[toUserId] == null) {
    // user does not have send any push keys
    // only allow accept request and contactrequest to be send in an insecure way :/
    // In future find a better way, e.g. use the signal protocol in a native way..
    if (kind != PushKind.acceptRequest &&
        kind != PushKind.contactRequest &&
        kind != PushKind.testNotification) {
      // this will be enforced after every app uses this system... :/
      // return null;
      Logger("notification_service").shout(
          "Using insecure key as the receiver does not send a push key!");
    }
  } else {
    try {
      key = pushKeys[toUserId]!.keys.last.key;
      keyId = pushKeys[toUserId]!.keys.last.id;
    } catch (e) {
      Logger("notification_service")
          .shout("No push notification key found for user $toUserId");
      return null;
    }
  }

  final chacha20 = Chacha20.poly1305Aead();
  final nonce = chacha20.newNonce();
  final secretBox = await chacha20.encrypt(
    kind.name.codeUnits,
    secretKey: SecretKeyData(key),
    nonce: nonce,
  );
  final res = PushNotification(
    keyId: keyId,
    nonce: nonce,
    cipherText: secretBox.cipherText,
    mac: secretBox.mac.bytes,
  );

  return jsonEncode(res.toJson()).codeUnits;
}

Future<PushKind?> tryDecryptMessage(
    List<int> key, PushNotification noti) async {
  try {
    final chacha20 = Chacha20.poly1305Aead();
    SecretKeyData secretKeyData = SecretKeyData(key);

    SecretBox secretBox = SecretBox(
      noti.cipherText,
      nonce: noti.nonce,
      mac: Mac(noti.mac),
    );

    final plaintext =
        await chacha20.decrypt(secretBox, secretKey: secretKeyData);
    final plaintextString = utf8.decode(plaintext);
    return PushKindExtension.fromString(plaintextString);
  } catch (e) {
    Logger("notification-service").shout(e);
    return null;
  }
}

Future handlePushData(String pushDataJson) async {
  try {
    String jsonString = utf8.decode(base64.decode(pushDataJson));
    final pushData = PushNotification.fromJson(jsonDecode(jsonString));

    PushKind? pushKind;
    int? fromUserId;

    if (pushData.keyId == 0) {
      List<int> key = "InsecureOnlyUsedForAddingContact".codeUnits;
      pushKind = await tryDecryptMessage(key, pushData);
    } else {
      var pushKeys = await getPushKeys("receivingPushKeys");
      for (final userId in pushKeys.keys) {
        for (final key in pushKeys[userId]!.keys) {
          if (key.id == pushData.keyId) {
            pushKind = await tryDecryptMessage(key.key, pushData);
            if (pushKind != null) {
              fromUserId = userId;
              break;
            }
          }
        }
        // found correct key and user
        if (fromUserId != null) break;
      }
    }

    if (pushKind != null) {
      if (pushKind == PushKind.testNotification) {
        await customLocalPushNotification(
            "Test notification", "This is a test notification.");
      } else if (fromUserId != null) {
        await showLocalPushNotification(fromUserId, pushKind);
      } else {
        await showLocalPushNotificationWithoutUserId(pushKind);
        await setupNotificationWithUsers();
      }
    }
  } catch (e) {
    Logger("notification-service").shout(e);
  }
}

Future<Map<int, PushUser>> getPushKeys(String storageKey) async {
  var storage = getSecureStorage();
  String? pushKeysJson = await storage.read(
    key: storageKey,
    iOptions: IOSOptions(
      groupId: "CN332ZUGRP.eu.twonly.shared",
      synchronizable: false,
    ),
  );
  Map<int, PushUser> pushKeys = <int, PushUser>{};
  if (pushKeysJson != null) {
    Map<String, dynamic> jsonMap = jsonDecode(pushKeysJson);
    jsonMap.forEach((key, value) {
      pushKeys[int.parse(key)] = PushUser.fromJson(value);
    });
  }
  return pushKeys;
}

Future setPushKeys(String storageKey, Map<int, PushUser> pushKeys) async {
  var storage = getSecureStorage();
  Map<String, dynamic> jsonToSend = {};
  pushKeys.forEach((key, value) {
    jsonToSend[key.toString()] = value.toJson();
  });

  String jsonString = jsonEncode(jsonToSend);
  await storage.write(
    key: storageKey,
    value: jsonString,
    iOptions: IOSOptions(
        groupId: "CN332ZUGRP.eu.twonly.shared", synchronizable: false),
  );
}

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
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings("ic_launcher_foreground");

  final List<DarwinNotificationCategory> darwinNotificationCategories =
      <DarwinNotificationCategory>[];

  /// Note: permissions aren't requested here just to demonstrate that can be
  /// done later
  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    requestProvisionalPermission: false,
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

Future showLocalPushNotification(
  int fromUserId,
  PushKind pushKind,
) async {
  String? title;
  String? body;

  Contact? user = await twonlyDatabase.contactsDao
      .getContactByUserId(fromUserId)
      .getSingleOrNull();

  if (user == null) return;

  title = getContactDisplayName(user);
  body = getPushNotificationText(pushKind);
  if (body == "") {
    Logger("localPushNotificationNewMessage")
        .shout("No push notification type defined!");
  }

  FilePathAndroidBitmap? styleInformation;
  String? avatarPath = await getAvatarIcon(user);
  if (avatarPath != null) {
    styleInformation = FilePathAndroidBitmap(avatarPath);
  }

  AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails('0', 'Messages',
          channelDescription: 'Messages from other users.',
          importance: Importance.max,
          priority: Priority.max,
          ticker: 'You got a new message.',
          largeIcon: styleInformation);

  const DarwinNotificationDetails darwinNotificationDetails =
      DarwinNotificationDetails();
  NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails, iOS: darwinNotificationDetails);

  await flutterLocalNotificationsPlugin.show(
    fromUserId,
    title,
    body,
    notificationDetails,
    payload: pushKind.name,
  );
}

Future showLocalPushNotificationWithoutUserId(
  PushKind pushKind,
) async {
  String? title;
  String? body;

  body = getPushNotificationTextWithoutUserId(pushKind);
  if (body == "") {
    Logger("localPushNotificationNewMessage")
        .shout("No push notification type defined!");
  }

  AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails('0', 'Messages',
          channelDescription: 'Messages from other users.',
          importance: Importance.max,
          priority: Priority.max,
          ticker: 'You got a new message.');

  const DarwinNotificationDetails darwinNotificationDetails =
      DarwinNotificationDetails();
  NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails, iOS: darwinNotificationDetails);

  await flutterLocalNotificationsPlugin.show(
    2,
    title,
    body,
    notificationDetails,
    payload: pushKind.name,
  );
}

Future customLocalPushNotification(String title, String msg) async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    '1',
    'System',
    channelDescription: 'System messages.',
    importance: Importance.max,
    priority: Priority.max,
  );

  const DarwinNotificationDetails darwinNotificationDetails =
      DarwinNotificationDetails();
  const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails, iOS: darwinNotificationDetails);

  await flutterLocalNotificationsPlugin.show(
    999999 + Random.secure().nextInt(9999),
    title,
    msg,
    notificationDetails,
  );
}

String getPushNotificationTextWithoutUserId(PushKind pushKind) {
  Map<String, String> pushNotificationText;

  String systemLanguage = Platform.localeName;

  if (systemLanguage.contains("de")) {
    pushNotificationText = {
      PushKind.text.name: "Du hast eine Nachricht erhalten.",
      PushKind.twonly.name: "Du hast ein twonly erhalten.",
      PushKind.video.name: "Du hast ein Video erhalten.",
      PushKind.image.name: "Du hast ein Bild erhalten.",
      PushKind.contactRequest.name: "Du hast eine Kontaktanfrage erhalten.",
      PushKind.acceptRequest.name: "Deine Kontaktanfrage wurde angenommen.",
      PushKind.storedMediaFile.name: "Dein Bild wurde gespeichert.",
      PushKind.reaction.name: "Du hast eine Reaktion auf dein Bild erhalten."
    };
  } else {
    pushNotificationText = {
      PushKind.text.name: "You got a message.",
      PushKind.twonly.name: "You got a twonly.",
      PushKind.video.name: "You got a video.",
      PushKind.image.name: "You got an image.",
      PushKind.contactRequest.name: "You got a contact request.",
      PushKind.acceptRequest.name: "Your contact request has been accepted.",
      PushKind.storedMediaFile.name: "Your image has been saved.",
      PushKind.reaction.name: "You got a reaction to your image."
    };
  }
  return pushNotificationText[pushKind.name] ?? "";
}

String getPushNotificationText(PushKind pushKind) {
  String systemLanguage = Platform.localeName;

  Map<String, String> pushNotificationText;

  if (systemLanguage.contains("de")) {
    pushNotificationText = {
      PushKind.text.name: "hat dir eine Nachricht gesendet.",
      PushKind.twonly.name: "hat dir ein twonly gesendet.",
      PushKind.video.name: "hat dir ein Video gesendet.",
      PushKind.image.name: "hat dir ein Bild gesendet.",
      PushKind.contactRequest.name: "möchte sich mir dir vernetzen.",
      PushKind.acceptRequest.name: "ist jetzt mit dir vernetzt.",
      PushKind.storedMediaFile.name: "hat dein Bild gespeichert.",
      PushKind.reaction.name: "hat auf dein Bild reagiert."
    };
  } else {
    pushNotificationText = {
      PushKind.text.name: "has sent you a message.",
      PushKind.twonly.name: "has sent you a twonly.",
      PushKind.video.name: "has sent you a video.",
      PushKind.image.name: "has sent you an image.",
      PushKind.contactRequest.name: "wants to connect with you.",
      PushKind.acceptRequest.name: "is now connected with you.",
      PushKind.storedMediaFile.name: "has stored your image.",
      PushKind.reaction.name: "has reacted to your image."
    };
  }
  return pushNotificationText[pushKind.name] ?? "";
}

Future<String?> getAvatarIcon(Contact user) async {
  if (user.avatarSvg == null) return null;

  final PictureInfo pictureInfo =
      await vg.loadPicture(SvgStringLoader(user.avatarSvg!), null);

  final ui.Image image = await pictureInfo.picture.toImage(300, 300);

  final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List pngBytes = byteData!.buffer.asUint8List();

  // Get the directory to save the image
  final directory = await getApplicationCacheDirectory();
  final avatarsDirectory = Directory('${directory.path}/avatars');

  // Create the avatars directory if it does not exist
  if (!await avatarsDirectory.exists()) {
    await avatarsDirectory.create(recursive: true);
  }

  final filePath = '${avatarsDirectory.path}/${user.userId}.png';
  final file = File(filePath);
  await file.writeAsBytes(pngBytes);

  pictureInfo.picture.dispose();

  return filePath;
}
