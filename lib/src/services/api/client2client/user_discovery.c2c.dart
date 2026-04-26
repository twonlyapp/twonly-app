import 'dart:typed_data';

import 'package:twonly/locator.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/messages.api.dart';
import 'package:twonly/src/services/user_discovery.service.dart';
import 'package:twonly/src/utils/log.dart';

final _requestedUpdates = <int>{};

Future<void> checkForUserDiscoveryChanges(
  int fromUserId,
  List<int> receivedVersion,
) async {
  final currentVersion = await UserDiscoveryService.shouldRequestNewMessages(
    fromUserId,
    receivedVersion,
  );

  if (currentVersion != null) {
    if (_requestedUpdates.contains(fromUserId)) {
      /// Only request a new version once per app session
      return;
    }
    Log.info('Having old version from contact. Requesting new version.');
    _requestedUpdates.add(fromUserId);
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
  Log.info('Got a user discovery request');

  if (!userService.currentUser.isUserDiscoveryEnabled) {
    Log.warn('Got a user discovery request while it is disabled');
    return;
  }
  final contact = await twonlyDB.contactsDao.getContactById(fromUserId);
  if (contact == null) return;

  if (contact.mediaSendCounter <
          userService.currentUser.minimumRequiredImagesExchanged ||
      contact.userDiscoveryExcluded) {
    Log.warn(
      'Got a request to update user discovery, but mediaSendCounter (${contact.mediaSendCounter}) < ${userService.currentUser.minimumRequiredImagesExchanged} or user is excluded ${contact.userDiscoveryExcluded}',
    );
    return;
  }

  final newMessages = await UserDiscoveryService.getNewMessages(
    fromUserId,
    request.currentVersion,
  );
  if (newMessages != null && newMessages.isNotEmpty) {
    Log.info('Sending ${newMessages.length} user discovery messages');
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
  if (!userService.currentUser.isUserDiscoveryEnabled) {
    Log.warn('Got a user discovery update while it is disabled');
    return;
  }
  Log.info('Got ${update.messages.length} user discovery messages');
  await UserDiscoveryService.handleNewMessages(
    fromUserId,
    update.messages.map(Uint8List.fromList).toList(),
  );
}
