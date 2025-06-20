import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/services/notification.service.dart';
import 'package:twonly/src/utils/log.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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

Future handlePushData(String pushDataJson) async {
  try {
    String jsonString = utf8.decode(base64.decode(pushDataJson));
    final pushData = PushNotification.fromJson(jsonDecode(jsonString));

    PushKind? pushKind;
    PushUser? pushUser;
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
              pushUser = pushKeys[userId]!;
              fromUserId = userId;
              break;
            }
          }
        }
        // found correct key and user
        if (pushUser != null) break;
      }
    }

    if (pushKind != null) {
      if (pushKind == PushKind.testNotification) {
        await customLocalPushNotification(
            "Test notification", "This is a test notification.");
      } else if (pushUser != null && fromUserId != null) {
        await showLocalPushNotification(pushUser, fromUserId, pushKind);
      } else {
        await showLocalPushNotificationWithoutUserId(pushKind);
      }
    }
  } catch (e) {
    Log.error(e);
  }
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
    // this error is allowed to happen...
    return null;
  }
}

Future showLocalPushNotification(
  PushUser pushUser,
  int fromUserId,
  PushKind pushKind,
) async {
  String? title;
  String? body;

  // do not show notification for blocked users...
  if (pushUser.blocked) {
    Log.info("Blocked a message from a blocked user!");
    return;
  }

  title = pushUser.displayName;
  body = getPushNotificationText(pushKind);
  if (body == "") {
    Log.error("No push notification type defined!");
  }

  FilePathAndroidBitmap? styleInformation;
  String? avatarPath = await getAvatarIcon(fromUserId);
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
    Log.error("No push notification type defined!");
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

Future<String?> getAvatarIcon(int contactId) async {
  final directory = await getApplicationCacheDirectory();
  final avatarsDirectory = Directory('${directory.path}/avatars');
  final filePath = '${avatarsDirectory.path}/$contactId.png';
  final file = File(filePath);
  if (file.existsSync()) {
    return filePath;
  }
  return null;
}

String getPushNotificationTextWithoutUserId(PushKind pushKind) {
  Map<String, String> pushNotificationText;

  String systemLanguage = Platform.localeName;

  if (systemLanguage.contains("de")) {
    pushNotificationText = {
      PushKind.text.name: "Du hast eine neue Nachricht erhalten.",
      PushKind.twonly.name: "Du hast ein neues twonly erhalten.",
      PushKind.video.name: "Du hast ein neues Video erhalten.",
      PushKind.image.name: "Du hast ein neues Bild erhalten.",
      PushKind.contactRequest.name:
          "Du hast eine neue Kontaktanfrage erhalten.",
      PushKind.acceptRequest.name: "Deine Kontaktanfrage wurde angenommen.",
      PushKind.storedMediaFile.name: "Dein Bild wurde gespeichert.",
      PushKind.reaction.name: "Du hast eine Reaktion auf dein Bild erhalten.",
      PushKind.reopenedMedia.name: "Dein Bild wurde erneut geöffnet.",
      PushKind.reactionToVideo.name:
          "Du hast eine Reaktion auf dein Video erhalten.",
      PushKind.reactionToText.name:
          "Du hast eine Reaktion auf deinen Text erhalten.",
      PushKind.reactionToImage.name:
          "Du hast eine Reaktion auf dein Bild erhalten.",
      PushKind.response.name: "Du hast eine Antwort erhalten.",
    };
  } else {
    pushNotificationText = {
      PushKind.text.name: "You have received a new message.",
      PushKind.twonly.name: "You have received a new twonly.",
      PushKind.video.name: "You have received a new video.",
      PushKind.image.name: "You have received a new image.",
      PushKind.contactRequest.name: "You have received a new contact request.",
      PushKind.acceptRequest.name: "Your contact request has been accepted.",
      PushKind.storedMediaFile.name: "Your image has been saved.",
      PushKind.reaction.name: "You have received a reaction to your image.",
      PushKind.reopenedMedia.name: "Your image has been reopened.",
      PushKind.reactionToVideo.name:
          "You have received a reaction to your video.",
      PushKind.reactionToText.name:
          "You have received a reaction to your text.",
      PushKind.reactionToImage.name:
          "You have received a reaction to your image.",
      PushKind.response.name: "You have received a response.",
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
      PushKind.contactRequest.name: "möchte sich mit dir vernetzen.",
      PushKind.acceptRequest.name: "ist jetzt mit dir vernetzt.",
      PushKind.storedMediaFile.name: "hat dein Bild gespeichert.",
      PushKind.reaction.name: "hat auf dein Bild reagiert.",
      PushKind.reopenedMedia.name: "hat dein Bild erneut geöffnet.",
      PushKind.reactionToVideo.name: "hat auf dein Video reagiert.",
      PushKind.reactionToText.name: "hat auf deinen Text reagiert.",
      PushKind.reactionToImage.name: "hat auf dein Bild reagiert.",
      PushKind.response.name: "hat dir geantwortet.",
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
      PushKind.reaction.name: "has reacted to your image.",
      PushKind.reopenedMedia.name: "has reopened your image.",
      PushKind.reactionToVideo.name: "has reacted to your video.",
      PushKind.reactionToText.name: "has reacted to your text.",
      PushKind.reactionToImage.name: "has reacted to your image.",
      PushKind.response.name: "has responded.",
    };
  }
  return pushNotificationText[pushKind.name] ?? "";
}
