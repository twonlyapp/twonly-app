import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart' hide Message;
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/utils/avatars.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

Future<bool> handleNewContactRequest(int fromUserId) async {
  final contact = await twonlyDB.contactsDao
      .getContactByUserId(fromUserId)
      .getSingleOrNull();
  if (contact != null) {
    if (contact.accepted) {
      // contact was already accepted, so just accept the request in the background.
      await sendCipherText(
        contact.userId,
        EncryptedContent(
          contactRequest: EncryptedContent_ContactRequest(
            type: EncryptedContent_ContactRequest_Type.ACCEPT,
          ),
        ),
      );
      return true;
    }
  }
  // Request the username by the server so an attacker can not
  // forge the displayed username in the contact request
  final user = await apiService.getUserById(fromUserId);
  if (user == null) {
    return false;
  }
  await twonlyDB.contactsDao.insertOnConflictUpdate(
    ContactsCompanion(
      username: Value(utf8.decode(user.username)),
      userId: Value(fromUserId),
      requested: const Value(true),
      deletedByUser: const Value(false),
    ),
  );
  await setupNotificationWithUsers();

  return true;
}

Future<bool> handleContactRequest(
  int fromUserId,
  EncryptedContent_ContactRequest contactRequest,
) async {
  switch (contactRequest.type) {
    case EncryptedContent_ContactRequest_Type.REQUEST:
      Log.info('Got a contact request from $fromUserId');
      return handleNewContactRequest(fromUserId);
    case EncryptedContent_ContactRequest_Type.ACCEPT:
      Log.info('Got a contact accept from $fromUserId');
      await twonlyDB.contactsDao.updateContact(
        fromUserId,
        const ContactsCompanion(
          requested: Value(false),
          accepted: Value(true),
          deletedByUser: Value(false),
        ),
      );
      final contact = await twonlyDB.contactsDao
          .getContactByUserId(fromUserId)
          .getSingleOrNull();
      await twonlyDB.groupsDao.createNewDirectChat(
        fromUserId,
        GroupsCompanion(
          groupName: Value(getContactDisplayName(contact!)),
        ),
      );
    case EncryptedContent_ContactRequest_Type.REJECT:
      Log.info('Got a contact reject from $fromUserId');
      await twonlyDB.contactsDao.updateContact(
        fromUserId,
        const ContactsCompanion(
          accepted: Value(false),
          requested: Value(false),
          deletedByUser: Value(true),
        ),
      );
  }
  return true;
}

Future<void> handleContactUpdate(
  int fromUserId,
  EncryptedContent_ContactUpdate contactUpdate,
  int? senderProfileCounter,
) async {
  switch (contactUpdate.type) {
    case EncryptedContent_ContactUpdate_Type.REQUEST:
      Log.info('Got a contact update request from $fromUserId');
      await sendContactMyProfileData(fromUserId);

    case EncryptedContent_ContactUpdate_Type.UPDATE:
      Log.info('Got a contact update $fromUserId');
      if (contactUpdate.hasAvatarSvgCompressed() &&
          contactUpdate.hasDisplayName() &&
          contactUpdate.hasUsername() &&
          senderProfileCounter != null) {
        await twonlyDB.contactsDao.updateContact(
          fromUserId,
          ContactsCompanion(
            avatarSvgCompressed:
                Value(Uint8List.fromList(contactUpdate.avatarSvgCompressed)),
            displayName: Value(contactUpdate.displayName),
            username: Value(contactUpdate.username),
            senderProfileCounter: Value(senderProfileCounter),
          ),
        );
        unawaited(createPushAvatars());
      }
  }
}

Future<void> handleFlameSync(
  int contactId,
  EncryptedContent_FlameSync flameSync,
) async {
  Log.info('Got a flameSync from $contactId');

  final group = await twonlyDB.groupsDao.getDirectChat(contactId);
  if (group == null || group.lastFlameCounterChange == null) return;

  var updates = GroupsCompanion(
    alsoBestFriend: Value(flameSync.bestFriend),
  );
  if (isToday(group.lastFlameCounterChange!) &&
          isToday(fromTimestamp(flameSync.lastFlameCounterChange)) ||
      flameSync.forceUpdate) {
    if (flameSync.flameCounter > group.flameCounter) {
      updates = updates.copyWith(
        flameCounter: Value(flameSync.flameCounter.toInt()),
      );
    }
    if (flameSync.flameCounter > group.maxFlameCounter) {
      updates = updates.copyWith(
        maxFlameCounter: Value(flameSync.flameCounter.toInt()),
      );
    }
  }
  await twonlyDB.groupsDao.updateGroup(group.groupId, updates);
}

Future<int?> checkForProfileUpdate(
  int fromUserId,
  EncryptedContent content,
) async {
  int? senderProfileCounter;

  if (content.hasSenderProfileCounter()) {
    senderProfileCounter = content.senderProfileCounter.toInt();
    if (!content.hasContactUpdate()) {
      final contact = await twonlyDB.contactsDao
          .getContactByUserId(fromUserId)
          .getSingleOrNull();
      if (contact != null) {
        if (contact.senderProfileCounter < senderProfileCounter) {
          await sendCipherText(
            fromUserId,
            EncryptedContent(
              contactUpdate: EncryptedContent_ContactUpdate(
                type: EncryptedContent_ContactUpdate_Type.REQUEST,
              ),
            ),
          );
        }
      }
    }
  }

  return senderProfileCounter;
}
