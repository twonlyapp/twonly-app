import 'dart:typed_data';

import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/user_discovery.service.dart';
import 'package:twonly/src/utils/log.dart';

Future<void> checkForUserDiscoveryChanges(
  int fromUserId,
  List<int> receivedVersion,
) async {
  final currentVersion = await UserDiscoveryService.shouldRequestNewMessages(
    fromUserId,
    receivedVersion,
  );

  if (currentVersion != null) {
    await sendCipherText(
      fromUserId,
      EncryptedContent(
        userDiscoveryRequest: EncryptedContent_UserDiscoveryRequest(
          currentVersion: currentVersion.toList(),
        ),
      ),
    );
  }
}

Future<void> handleUserDiscoveryRequest(
  int fromUserId,
  EncryptedContent_UserDiscoveryRequest request,
) async {
  if (!gUser.isUserDiscoveryEnabled) {
    Log.warn('Got a user discovery request while it is disabled');
    return;
  }
  final contact = await twonlyDB.contactsDao.getContactById(fromUserId);
  if (contact == null) return;

  if (contact.mediaSendCounter < gUser.minimumRequiredImagesExchanged) {
    Log.warn(
      'Got a request to update user discovery, but mediaSendCounter (${contact.mediaSendCounter}) < ${gUser.minimumRequiredImagesExchanged}',
    );
    return;
  }

  final newMessages = await UserDiscoveryService.getNewMessages(
    fromUserId,
    request.currentVersion,
  );
  if (newMessages != null && newMessages.isNotEmpty) {
    await sendCipherText(
      fromUserId,
      EncryptedContent(
        userDiscoveryUpdate: EncryptedContent_UserDiscoveryUpdate(
          messages: newMessages,
        ),
      ),
    );
  } else {
    Log.info('Got update request, but there are no new updates for the user');
  }
}

Future<void> handleUserDiscoveryUpdate(
  int fromUserId,
  EncryptedContent_UserDiscoveryUpdate update,
) async {
  if (!gUser.isUserDiscoveryEnabled) {
    Log.warn('Got a user discovery update while it is disabled');
    return;
  }
  await UserDiscoveryService.handleNewMessages(
    fromUserId,
    update.messages.map(Uint8List.fromList).toList(),
  );
}
