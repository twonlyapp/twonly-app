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
import 'package:path_provider/path_provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart' as my;
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/utils/log.dart';

class PushUser {
  String displayName;
  bool blocked;
  List<PushKeyMeta> keys;

  PushUser({
    required this.displayName,
    required this.blocked,
    required this.keys,
  });

  // Factory method to create a User from JSON
  factory PushUser.fromJson(Map<String, dynamic> json) {
    return PushUser(
      displayName: json['displayName'],
      blocked: json['blocked'] ?? false,
      keys: (json['keys'] as List)
          .map((keyJson) => PushKeyMeta.fromJson(keyJson))
          .toList(),
    );
  }

  // Method to convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'blocked': blocked,
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

  final contacts = await twonlyDB.contactsDao.getAllNotBlockedContacts();
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
        blocked: contact.blocked,
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
  await encryptAndSendMessageAsync(
    null,
    userId,
    my.MessageJson(
      kind: MessageKind.pushKey,
      content: my.PushKeyContent(keyId: pushKey.id, key: pushKey.key),
      timestamp: pushKey.createdAt,
    ),
  );
}

Future updatePushUser(Contact contact) async {
  var receivingPushKeys = await getPushKeys("receivingPushKeys");

  if (receivingPushKeys[contact.userId] == null) {
    receivingPushKeys[contact.userId] = PushUser(
      displayName: getContactDisplayName(contact),
      keys: [],
      blocked: contact.blocked,
    );
  } else {
    receivingPushKeys[contact.userId]!.displayName =
        getContactDisplayName(contact);
    receivingPushKeys[contact.userId]!.blocked = contact.blocked;
  }

  await setPushKeys("receivingPushKeys", receivingPushKeys);
}

Future handleNewPushKey(int fromUserId, my.PushKeyContent pushKey) async {
  var pushKeys = await getPushKeys("sendingPushKeys");

  if (pushKeys[fromUserId] == null) {
    pushKeys[fromUserId] = PushUser(displayName: "-", keys: [], blocked: false);
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
  testNotification,
  reopenedMedia,
  reactionToVideo,
  reactionToText,
  reactionToImage,
  response,
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
Future<Uint8List?> getPushData(int toUserId, PushKind kind) async {
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
      Log.error("Using insecure key as the receiver does not send a push key!");
      await encryptAndSendMessageAsync(
        null,
        toUserId,
        my.MessageJson(
          kind: MessageKind.requestPushKey,
          content: my.MessageContent(),
          timestamp: DateTime.now(),
        ),
      );
    }
  } else {
    try {
      key = pushKeys[toUserId]!.keys.last.key;
      keyId = pushKeys[toUserId]!.keys.last.id;
    } catch (e) {
      Log.error("No push notification key found for user $toUserId");
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
  return Utf8Encoder().convert(jsonEncode(res.toJson()));
}

Future<Map<int, PushUser>> getPushKeys(String storageKey) async {
  var storage = FlutterSecureStorage();
  String? pushKeysJson = await storage.read(
    key: storageKey,
    iOptions: IOSOptions(
      groupId: "CN332ZUGRP.eu.twonly.shared",
      synchronizable: false,
      accessibility: KeychainAccessibility.first_unlock,
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
  var storage = FlutterSecureStorage();
  Map<String, dynamic> jsonToSend = {};
  pushKeys.forEach((key, value) {
    jsonToSend[key.toString()] = value.toJson();
  });

  await storage.delete(
    key: storageKey,
    iOptions: IOSOptions(
      groupId: "CN332ZUGRP.eu.twonly.shared",
      synchronizable: false,
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  String jsonString = jsonEncode(jsonToSend);
  await storage.write(
    key: storageKey,
    value: jsonString,
    iOptions: IOSOptions(
      groupId: "CN332ZUGRP.eu.twonly.shared",
      synchronizable: false,
      accessibility: KeychainAccessibility.first_unlock,
    ),
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

Future createPushAvatars() async {
  if (!Platform.isAndroid) {
    return; // avatars currently only shown in Android...
  }
  final contacts = await twonlyDB.contactsDao.getAllNotBlockedContacts();

  for (final contact in contacts) {
    if (contact.avatarSvg == null) return null;

    final PictureInfo pictureInfo =
        await vg.loadPicture(SvgStringLoader(contact.avatarSvg!), null);

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
    final filePath = '${avatarsDirectory.path}/${contact.userId}.png';
    await File(filePath).writeAsBytes(pngBytes);
    pictureInfo.picture.dispose();
  }
}
