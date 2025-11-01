import 'dart:async';

import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/utils/log.dart';

DateTime lastPushKeyRequest = DateTime.now().subtract(const Duration(hours: 1));

Future<void> handlePushKey(
  int contactId,
  EncryptedContent_PushKeys pushKeys,
) async {
  switch (pushKeys.type) {
    case EncryptedContent_PushKeys_Type.REQUEST:
      Log.info('Got a pushkey request from $contactId');
      if (lastPushKeyRequest
          .isBefore(DateTime.now().subtract(const Duration(seconds: 60)))) {
        lastPushKeyRequest = DateTime.now();
        unawaited(setupNotificationWithUsers(forceContact: contactId));
      }

    case EncryptedContent_PushKeys_Type.UPDATE:
      Log.info('Got a pushkey update from $contactId');
      await handleNewPushKey(contactId, pushKeys.keyId.toInt(), pushKeys.key);
  }
}
