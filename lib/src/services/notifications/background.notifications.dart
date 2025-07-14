import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cryptography_flutter_plus/cryptography_flutter_plus.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/model/protobuf/push_notification/push_notification.pb.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/utils/log.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> customLocalPushNotification(String title, String msg) async {
  const androidNotificationDetails = AndroidNotificationDetails(
    '1',
    'System',
    channelDescription: 'System messages.',
    importance: Importance.max,
    priority: Priority.max,
  );

  const darwinNotificationDetails = DarwinNotificationDetails();
  const notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
    iOS: darwinNotificationDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    999999 + Random.secure().nextInt(9999),
    title,
    msg,
    notificationDetails,
  );
}

Future<void> handlePushData(String pushDataB64) async {
  try {
    final pushData =
        EncryptedPushNotification.fromBuffer(base64.decode(pushDataB64));

    PushNotification? pushNotification;
    PushUser? foundPushUser;

    if (pushData.keyId == 0) {
      final key = 'InsecureOnlyUsedForAddingContact'.codeUnits;
      pushNotification = await tryDecryptMessage(key, pushData);
    } else {
      final pushUsers = await getPushKeys(SecureStorageKeys.receivingPushKeys);
      for (final pushUser in pushUsers) {
        for (final key in pushUser.pushKeys) {
          if (key.id == pushData.keyId) {
            pushNotification = await tryDecryptMessage(key.key, pushData);
            if (pushNotification != null) {
              foundPushUser = pushUser;
              break;
            }
          }
        }
        // found correct key and user
        if (foundPushUser != null) break;
      }
    }

    if (pushNotification != null) {
      if (pushNotification.kind == PushKind.testNotification) {
        await customLocalPushNotification(
          'Test notification',
          'This is a test notification.',
        );
      } else if (foundPushUser != null) {
        if (pushNotification.hasMessageId()) {
          if (pushNotification.messageId <= foundPushUser.lastMessageId) {
            Log.info(
              'Got a push notification for a message which was already opened.',
            );
            return;
          }
        }

        await showLocalPushNotification(foundPushUser, pushNotification);
      } else {
        await showLocalPushNotificationWithoutUserId(pushNotification);
      }
    }
  } catch (e) {
    await customLocalPushNotification(
      'Du hast eine neue Nachricht.',
      'Öffne twonly um mehr zu erfahren.',
    );
    Log.error(e);
  }
}

Future<PushNotification?> tryDecryptMessage(
    List<int> key, EncryptedPushNotification push) async {
  try {
    final chacha20 = FlutterChacha20.poly1305Aead();
    final secretKeyData = SecretKeyData(key);

    final secretBox = SecretBox(
      push.ciphertext,
      nonce: push.nonce,
      mac: Mac(push.mac),
    );

    final plaintext =
        await chacha20.decrypt(secretBox, secretKey: secretKeyData);
    return PushNotification.fromBuffer(plaintext);
  } catch (e) {
    // this error is allowed to happen...
    return null;
  }
}

Future<void> showLocalPushNotification(
  PushUser pushUser,
  PushNotification pushNotification,
) async {
  String? title;
  String? body;

  // do not show notification for blocked users...
  if (pushUser.blocked) {
    Log.info('Blocked a message from a blocked user!');
    return;
  }

  title = pushUser.displayName;
  body = getPushNotificationText(pushNotification);
  if (body == '') {
    Log.error('No push notification type defined!');
  }

  FilePathAndroidBitmap? styleInformation;
  final avatarPath = await getAvatarIcon(pushUser.userId.toInt());
  if (avatarPath != null) {
    styleInformation = FilePathAndroidBitmap(avatarPath);
  }

  final androidNotificationDetails = AndroidNotificationDetails(
    '0',
    'Messages',
    channelDescription: 'Messages from other users.',
    importance: Importance.max,
    priority: Priority.max,
    ticker: 'You got a new message.',
    largeIcon: styleInformation,
  );

  const darwinNotificationDetails = DarwinNotificationDetails();
  final notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
    iOS: darwinNotificationDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    pushUser.userId.toInt(),
    title,
    body,
    notificationDetails,
    payload: pushNotification.kind.name,
  );
}

Future<void> showLocalPushNotificationWithoutUserId(
  PushNotification pushNotification,
) async {
  String? title;
  String? body;

  body = getPushNotificationTextWithoutUserId(pushNotification.kind);
  if (body == '') {
    Log.error('No push notification type defined!');
  }

  const androidNotificationDetails = AndroidNotificationDetails(
    '0',
    'Messages',
    channelDescription: 'Messages from other users.',
    importance: Importance.max,
    priority: Priority.max,
    ticker: 'You got a new message.',
  );

  const darwinNotificationDetails = DarwinNotificationDetails();
  const notificationDetails = NotificationDetails(
      android: androidNotificationDetails, iOS: darwinNotificationDetails);

  await flutterLocalNotificationsPlugin.show(
    2,
    title,
    body,
    notificationDetails,
    payload: pushNotification.kind.name,
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

  final systemLanguage = Platform.localeName;

  if (systemLanguage.contains('de')) {
    pushNotificationText = {
      PushKind.text.name: 'Du hast eine neue Nachricht erhalten.',
      PushKind.twonly.name: 'Du hast ein neues twonly erhalten.',
      PushKind.video.name: 'Du hast ein neues Video erhalten.',
      PushKind.image.name: 'Du hast ein neues Bild erhalten.',
      PushKind.contactRequest.name:
          'Du hast eine neue Kontaktanfrage erhalten.',
      PushKind.acceptRequest.name: 'Deine Kontaktanfrage wurde angenommen.',
      PushKind.storedMediaFile.name: 'Dein Bild wurde gespeichert.',
      PushKind.reaction.name: 'Du hast eine Reaktion auf dein Bild erhalten.',
      PushKind.reopenedMedia.name: 'Dein Bild wurde erneut geöffnet.',
      PushKind.reactionToVideo.name:
          'Du hast eine Reaktion auf dein Video erhalten.',
      PushKind.reactionToText.name:
          'Du hast eine Reaktion auf deinen Text erhalten.',
      PushKind.reactionToImage.name:
          'Du hast eine Reaktion auf dein Bild erhalten.',
      PushKind.response.name: 'Du hast eine Antwort erhalten.',
    };
  } else {
    pushNotificationText = {
      PushKind.text.name: 'You have received a new message.',
      PushKind.twonly.name: 'You have received a new twonly.',
      PushKind.video.name: 'You have received a new video.',
      PushKind.image.name: 'You have received a new image.',
      PushKind.contactRequest.name: 'You have received a new contact request.',
      PushKind.acceptRequest.name: 'Your contact request has been accepted.',
      PushKind.storedMediaFile.name: 'Your image has been saved.',
      PushKind.reaction.name: 'You have received a reaction to your image.',
      PushKind.reopenedMedia.name: 'Your image has been reopened.',
      PushKind.reactionToVideo.name:
          'You have received a reaction to your video.',
      PushKind.reactionToText.name:
          'You have received a reaction to your text.',
      PushKind.reactionToImage.name:
          'You have received a reaction to your image.',
      PushKind.response.name: 'You have received a response.',
    };
  }
  return pushNotificationText[pushKind.name] ?? '';
}

String getPushNotificationText(PushNotification pushNotification) {
  final systemLanguage = Platform.localeName;

  Map<String, String> pushNotificationText;

  if (systemLanguage.contains('de')) {
    pushNotificationText = {
      PushKind.text.name: 'hat dir eine Nachricht gesendet.',
      PushKind.twonly.name: 'hat dir ein twonly gesendet.',
      PushKind.video.name: 'hat dir ein Video gesendet.',
      PushKind.image.name: 'hat dir ein Bild gesendet.',
      PushKind.contactRequest.name: 'möchte sich mit dir vernetzen.',
      PushKind.acceptRequest.name: 'ist jetzt mit dir vernetzt.',
      PushKind.storedMediaFile.name: 'hat dein Bild gespeichert.',
      PushKind.reaction.name: 'hat auf dein Bild reagiert.',
      PushKind.reopenedMedia.name: 'hat dein Bild erneut geöffnet.',
      PushKind.reactionToVideo.name:
          'hat mit {{reaction}} auf dein Video reagiert.',
      PushKind.reactionToText.name:
          'hat mit {{reaction}} auf deine Nachricht reagiert.',
      PushKind.reactionToImage.name:
          'hat mit {{reaction}} auf dein Bild reagiert.',
      PushKind.response.name: 'hat dir geantwortet.',
    };
  } else {
    pushNotificationText = {
      PushKind.text.name: 'has sent you a message.',
      PushKind.twonly.name: 'has sent you a twonly.',
      PushKind.video.name: 'has sent you a video.',
      PushKind.image.name: 'has sent you an image.',
      PushKind.contactRequest.name: 'wants to connect with you.',
      PushKind.acceptRequest.name: 'is now connected with you.',
      PushKind.storedMediaFile.name: 'has stored your image.',
      PushKind.reaction.name: 'has reacted to your image.',
      PushKind.reopenedMedia.name: 'has reopened your image.',
      PushKind.reactionToVideo.name:
          'has reacted with {{reaction}} to your video.',
      PushKind.reactionToText.name:
          'has reacted with {{reaction}} to your message.',
      PushKind.reactionToImage.name:
          'has reacted with {{reaction}} to your image.',
      PushKind.response.name: 'has responded.',
    };
  }
  var contentText = pushNotificationText[pushNotification.kind.name] ?? '';
  if (pushNotification.hasReactionContent()) {
    contentText = contentText.replaceAll(
        '{{reaction}}', pushNotification.reactionContent);
  }
  return contentText;
}
