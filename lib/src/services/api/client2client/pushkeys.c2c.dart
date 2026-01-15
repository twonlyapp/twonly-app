import 'dart:async';

import 'package:clock/clock.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/utils/log.dart';

DateTime lastPushKeyRequest = clock.now().subtract(const Duration(hours: 1));

Future<void> handlePushKey(
  int contactId,
  EncryptedContent_PushKeys pushKeys,
) async {
  switch (pushKeys.type) {
    case EncryptedContent_PushKeys_Type.REQUEST:
      Log.info('Got a pushkey request from $contactId');
      if (lastPushKeyRequest
          .isBefore(clock.now().subtract(const Duration(seconds: 60)))) {
        lastPushKeyRequest = clock.now();
        unawaited(setupNotificationWithUsers(forceContact: contactId));
      }

    case EncryptedContent_PushKeys_Type.UPDATE:
      Log.info('Got a pushkey update from $contactId');
      await handleNewPushKey(contactId, pushKeys.keyId.toInt(), pushKeys.key);
  }
}
