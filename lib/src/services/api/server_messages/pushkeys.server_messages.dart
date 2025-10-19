import 'dart:async';

import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';

DateTime lastPushKeyRequest = DateTime.now().subtract(const Duration(hours: 1));

Future<void> handlePushKey(
  int contactId,
  EncryptedContent_PushKeys pushKeys,
) async {
  switch (pushKeys.type) {
    case EncryptedContent_PushKeys_Type.REQUEST:
      if (lastPushKeyRequest
          .isBefore(DateTime.now().subtract(const Duration(seconds: 60)))) {
        lastPushKeyRequest = DateTime.now();
        unawaited(setupNotificationWithUsers(forceContact: contactId));
      }

    case EncryptedContent_PushKeys_Type.UPDATE:
      await handleNewPushKey(contactId, pushKeys.keyId.toInt(), pushKeys.key);
  }
}
