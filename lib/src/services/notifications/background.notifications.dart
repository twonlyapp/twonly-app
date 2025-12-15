import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cryptography_flutter_plus/cryptography_flutter_plus.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/localization/generated/app_localizations_de.dart';
import 'package:twonly/src/localization/generated/app_localizations_en.dart';
import 'package:twonly/src/model/protobuf/client/generated/push_notification.pb.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

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
          if (isUUIDNewer(
            foundPushUser.lastMessageId,
            pushNotification.messageId,
          )) {
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
    Log.error(e);
    await customLocalPushNotification(
      'Du hast eine neue Nachricht.',
      'Öffne twonly um mehr zu erfahren.',
    );
  }
}

Future<PushNotification?> tryDecryptMessage(
  List<int> key,
  EncryptedPushNotification push,
) async {
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

  final lang = getLocalizations();

  final androidNotificationDetails = AndroidNotificationDetails(
    '0',
    lang.notificationCategoryMessageTitle,
    channelDescription: lang.notificationCategoryMessageDesc,
    importance: Importance.max,
    priority: Priority.max,
    ticker: 'You got a new message.',
    largeIcon: styleInformation,
    icon: 'ic_launcher_foreground',
  );

  const darwinNotificationDetails = DarwinNotificationDetails();
  final notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
    iOS: darwinNotificationDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    pushUser.userId.toInt() %
        // ignore: avoid_js_rounded_ints
        2373257871630019505, // Invalid argument (id): must fit within the size of a 32-bit integer
    title,
    body,
    notificationDetails,
    // payload: pushNotification.kind.name,
  );
}

Future<void> showLocalPushNotificationWithoutUserId(
  PushNotification pushNotification,
) async {
  String? body;

  body = getPushNotificationText(pushNotification);

  final lang = getLocalizations();

  final title = lang.notificationTitleUnknownUser;

  if (body == '') {
    Log.error('No push notification type defined!');
  }

  final androidNotificationDetails = AndroidNotificationDetails(
    '0',
    lang.notificationCategoryMessageTitle,
    channelDescription: lang.notificationCategoryMessageDesc,
    importance: Importance.max,
    priority: Priority.max,
    ticker: 'You got a new message.',
  );

  const darwinNotificationDetails = DarwinNotificationDetails();
  final notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
    iOS: darwinNotificationDetails,
  );

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

AppLocalizations getLocalizations() {
  final systemLanguage = Platform.localeName;
  if (systemLanguage.contains('de')) return AppLocalizationsDe();
  return AppLocalizationsEn();
}

String getPushNotificationText(PushNotification pushNotification) {
  final lang = getLocalizations();

  var inGroup = '';

  if (pushNotification.hasAdditionalContent()) {
    inGroup =
        ' ${lang.notificationFillerIn} ${pushNotification.additionalContent}';
  }

  final pushNotificationText = {
    PushKind.text.name: lang.notificationText(inGroup),
    PushKind.twonly.name: lang.notificationTwonly(inGroup),
    PushKind.video.name: lang.notificationVideo(inGroup),
    PushKind.image.name: lang.notificationImage(inGroup),
    PushKind.audio.name: lang.notificationAudio(inGroup),
    PushKind.contactRequest.name: lang.notificationContactRequest,
    PushKind.acceptRequest.name: lang.notificationAcceptRequest,
    PushKind.storedMediaFile.name: lang.notificationStoredMediaFile,
    PushKind.reaction.name: lang.notificationReaction,
    PushKind.reopenedMedia.name: lang.notificationReopenedMedia,
    PushKind.reactionToVideo.name:
        lang.notificationReactionToVideo(pushNotification.additionalContent),
    PushKind.reactionToAudio.name:
        lang.notificationReactionToAudio(pushNotification.additionalContent),
    PushKind.reactionToText.name:
        lang.notificationReactionToText(pushNotification.additionalContent),
    PushKind.reactionToImage.name:
        lang.notificationReactionToImage(pushNotification.additionalContent),
    PushKind.response.name: lang.notificationResponse(inGroup),
    PushKind.addedToGroup.name:
        lang.notificationAddedToGroup(pushNotification.additionalContent),
  };

  return pushNotificationText[pushNotification.kind.name] ?? '';
}
