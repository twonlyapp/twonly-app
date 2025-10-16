import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart' as my;
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

Future<void> syncFlameCounters() async {
  final user = await getUser();
  if (user == null) return;

  final contacts = await twonlyDB.contactsDao.getAllNotBlockedContacts();
  if (contacts.isEmpty) return;
  final maxMessageCounter = contacts.map((x) => x.totalMediaCounter).max;
  final bestFriend =
      contacts.firstWhere((x) => x.totalMediaCounter == maxMessageCounter);

  if (user.myBestFriendContactId != bestFriend.userId) {
    await updateUserdata((user) {
      user.myBestFriendContactId = bestFriend.userId;
      return user;
    });
  }

  for (final contact in contacts) {
    if (contact.lastFlameCounterChange == null || contact.deleted) continue;
    if (!isToday(contact.lastFlameCounterChange!)) continue;
    if (contact.lastFlameSync != null) {
      if (isToday(contact.lastFlameSync!)) continue;
    }

    final flameCounter = getFlameCounterFromContact(contact) - 1;

    // only sync when flame counter is higher than three days
    if (flameCounter < 1 && bestFriend.userId != contact.userId) continue;

    await encryptAndSendMessageAsync(
      null,
      contact.userId,
      my.MessageJson(
        kind: MessageKind.flameSync,
        content: my.FlameSyncContent(
          flameCounter: flameCounter,
          lastFlameCounterChange: contact.lastFlameCounterChange!,
          bestFriend: contact.userId == bestFriend.userId,
        ),
        timestamp: DateTime.now(),
      ),
    );

    await twonlyDB.contactsDao.updateContact(
      contact.userId,
      ContactsCompanion(
        lastFlameSync: Value(DateTime.now()),
      ),
    );
  }
}
