import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart' hide Message;
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/services/notifications/setup.notifications.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

Future<void> handleContactRequest(
  int fromUserId,
  EncryptedContent_ContactRequest contactRequest,
) async {
  switch (contactRequest.type) {
    case EncryptedContent_ContactRequest_Type.REQUEST:
      Log.info('Got a contact request from $fromUserId');
      // Request the username by the server so an attacker can not
      // forge the displayed username in the contact request
      final username = await apiService.getUsername(fromUserId);
      if (username.isSuccess) {
        // ignore: avoid_dynamic_calls
        final name = username.value.userdata.username as Uint8List;
        await twonlyDB.contactsDao.insertContact(
          ContactsCompanion(
            username: Value(utf8.decode(name)),
            userId: Value(fromUserId),
            requested: const Value(true),
          ),
        );
      }
      await setupNotificationWithUsers();
    case EncryptedContent_ContactRequest_Type.ACCEPT:
      Log.info('Got a contact accept from $fromUserId');
      await twonlyDB.contactsDao.updateContact(
        fromUserId,
        const ContactsCompanion(
          requested: Value(false),
          accepted: Value(true),
        ),
      );
    case EncryptedContent_ContactRequest_Type.REJECT:
      Log.info('Got a contact reject from $fromUserId');
      await twonlyDB.contactsDao.deleteContactByUserId(fromUserId);
  }
}

Future<void> handleContactUpdate(
  int fromUserId,
  EncryptedContent_ContactUpdate contactUpdate,
  int? senderProfileCounter,
) async {
  switch (contactUpdate.type) {
    case EncryptedContent_ContactUpdate_Type.REQUEST:
      Log.info('Got a contact update request from $fromUserId');
      await notifyContactsAboutProfileChange(onlyToContact: fromUserId);

    case EncryptedContent_ContactUpdate_Type.UPDATE:
      Log.info('Got a contact update $fromUserId');
      if (contactUpdate.hasAvatarSvg() &&
          contactUpdate.hasDisplayName() &&
          senderProfileCounter != null) {
        await twonlyDB.contactsDao.updateContact(
          fromUserId,
          ContactsCompanion(
            avatarSvg: Value(contactUpdate.avatarSvg),
            displayName: Value(contactUpdate.displayName),
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
  final contact = await twonlyDB.contactsDao
      .getContactByUserId(contactId)
      .getSingleOrNull();

  if (contact == null || contact.lastFlameCounterChange != null) return;

  var updates = ContactsCompanion(
    alsoBestFriend: Value(flameSync.bestFriend),
  );
  if (isToday(contact.lastFlameCounterChange!) &&
      isToday(fromTimestamp(flameSync.lastFlameCounterChange))) {
    if (flameSync.flameCounter > contact.flameCounter) {
      updates = ContactsCompanion(
        flameCounter: Value(flameSync.flameCounter.toInt()),
      );
    }
  }
  await twonlyDB.contactsDao.updateContact(contactId, updates);
}

Future<int?> checkForProfileUpdate(
  int fromUserId,
  EncryptedContent content,
) async {
  int? senderProfileCounter;

  if (content.hasSenderProfileCounter() && !content.hasContactUpdate()) {
    senderProfileCounter = content.senderProfileCounter.toInt();
    final contact = await twonlyDB.contactsDao
        .getContactByUserId(fromUserId)
        .getSingleOrNull();
    if (contact != null) {
      if (contact.senderProfileCounter < senderProfileCounter) {
        await sendCipherText(
          fromUserId,
          EncryptedContent()
            ..contactUpdate = (EncryptedContent_ContactUpdate()
              ..type = EncryptedContent_ContactUpdate_Type.REQUEST),
        );
      }
    }
  }

  return senderProfileCounter;
}
