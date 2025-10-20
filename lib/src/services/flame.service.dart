import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
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

    await sendCipherText(
      contact.userId,
      EncryptedContent(
        flameSync: EncryptedContent_FlameSync(
          flameCounter: Int64(flameCounter),
          lastFlameCounterChange:
              Int64(contact.lastFlameCounterChange!.millisecondsSinceEpoch),
          bestFriend: contact.userId == bestFriend.userId,
        ),
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
