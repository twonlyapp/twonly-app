import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/model/json/message.dart' as my;

Future syncFlameCounters() async {
  var user = await getUser();
  if (user == null) return;

  List<Contact> contacts =
      await twonlyDatabase.contactsDao.getAllNotBlockedContacts();
  if (contacts.isEmpty) return;
  int maxMessageCounter = contacts.map((x) => x.totalMediaCounter).max;
  Contact bestFriend =
      contacts.firstWhere((x) => x.totalMediaCounter == maxMessageCounter);

  if (user.myBestFriendContactId != bestFriend.userId) {
    user.myBestFriendContactId = bestFriend.userId;
    await updateUser(user);
  }

  for (Contact contact in contacts) {
    if (contact.lastFlameCounterChange == null) continue;
    if (contact.lastFlameSync != null) {
      if (isToday(contact.lastFlameSync!)) continue;
    }

    int flameCounter = getFlameCounterFromContact(contact) - 1;

    // only sync when flame counter is higher than three days
    if (flameCounter < 1 && bestFriend.userId != contact.userId) continue;

    encryptAndSendMessage(
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

    await twonlyDatabase.contactsDao.updateContact(
      contact.userId,
      ContactsCompanion(
        lastFlameSync: Value(DateTime.now()),
      ),
    );
  }
}
