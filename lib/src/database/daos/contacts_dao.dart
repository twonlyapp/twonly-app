import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';

part 'contacts_dao.g.dart';

@DriftAccessor(tables: [Contacts])
class ContactsDao extends DatabaseAccessor<TwonlyDatabase>
    with _$ContactsDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  // ignore: matching_super_parameters
  ContactsDao(super.db);

  Future<int> insertContact(ContactsCompanion contact) async {
    try {
      return await into(contacts).insert(contact);
    } catch (e) {
      return 0;
    }
  }

  Future<int> incFlameCounter(
    int contactId,
    bool received,
    DateTime timestamp,
  ) async {
    final contact = (await (select(contacts)
              ..where((t) => t.userId.equals(contactId)))
            .get())
        .first;

    final totalMediaCounter = contact.totalMediaCounter + 1;
    var flameCounter = contact.flameCounter;

    if (contact.lastMessageReceived != null &&
        contact.lastMessageSend != null) {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final twoDaysAgo = startOfToday.subtract(const Duration(days: 2));
      if (contact.lastMessageSend!.isBefore(twoDaysAgo) ||
          contact.lastMessageReceived!.isBefore(twoDaysAgo)) {
        flameCounter = 0;
      }
    }

    var lastMessageSend = const Value<DateTime?>.absent();
    var lastMessageReceived = const Value<DateTime?>.absent();
    var lastFlameCounterChange = const Value<DateTime?>.absent();

    if (contact.lastFlameCounterChange != null) {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      if (contact.lastFlameCounterChange!.isBefore(startOfToday)) {
        // last flame update was yesterday. check if it can be updated.
        var updateFlame = false;
        if (received) {
          if (contact.lastMessageSend != null &&
              contact.lastMessageSend!.isAfter(startOfToday)) {
            // today a message was already send -> update flame
            updateFlame = true;
          }
        } else if (contact.lastMessageReceived != null &&
            contact.lastMessageReceived!.isAfter(startOfToday)) {
          // today a message was already received -> update flame
          updateFlame = true;
        }
        if (updateFlame) {
          flameCounter += 1;
          lastFlameCounterChange = Value(timestamp);
        }
      }
    } else {
      // There where no message until no...
      lastFlameCounterChange = Value(timestamp);
    }

    if (received) {
      lastMessageReceived = Value(timestamp);
    } else {
      lastMessageSend = Value(timestamp);
    }

    return (update(contacts)..where((t) => t.userId.equals(contactId))).write(
      ContactsCompanion(
        totalMediaCounter: Value(totalMediaCounter),
        lastFlameCounterChange: lastFlameCounterChange,
        lastMessageReceived: lastMessageReceived,
        lastMessageSend: lastMessageSend,
        flameCounter: Value(flameCounter),
      ),
    );
  }

  SingleOrNullSelectable<Contact> getContactByUserId(int userId) {
    return select(contacts)..where((t) => t.userId.equals(userId));
  }

  Future<void> deleteContactByUserId(int userId) {
    return (delete(contacts)..where((t) => t.userId.equals(userId))).go();
  }

  Future<void> updateContact(
    int userId,
    ContactsCompanion updatedValues,
  ) async {
    await (update(contacts)..where((c) => c.userId.equals(userId)))
        .write(updatedValues);
    if (updatedValues.blocked.present ||
        updatedValues.displayName.present ||
        updatedValues.nickName.present) {
      final contact = await getContactByUserId(userId).getSingleOrNull();
      if (contact != null) {
        await updatePushUser(contact);
      }
    }
  }

  Stream<List<Contact>> watchNotAcceptedContacts() {
    return (select(contacts)
          ..where(
            (t) =>
                t.accepted.equals(false) &
                t.archived.equals(false) &
                t.blocked.equals(false),
          ))
        .watch();
    // return (select(contacts)).watch();
  }

  Stream<Contact?> watchContact(int userid) {
    return (select(contacts)..where((t) => t.userId.equals(userid)))
        .watchSingleOrNull();
  }

  Stream<List<Contact>> watchContactsForShareView() {
    return (select(contacts)
          ..where(
            (t) =>
                t.accepted.equals(true) &
                t.blocked.equals(false) &
                t.deleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.lastMessageExchange)]))
        .watch();
  }

  Stream<List<Contact>> watchContactsForStartNewChat() {
    return (select(contacts)
          ..where((t) => t.accepted.equals(true) & t.blocked.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.lastMessageExchange)]))
        .watch();
  }

  Stream<List<Contact>> watchContactsForChatList() {
    return (select(contacts)
          ..where(
            (t) =>
                t.accepted.equals(true) &
                t.blocked.equals(false) &
                t.archived.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.lastMessageExchange)]))
        .watch();
  }

  Future<List<Contact>> getAllNotBlockedContacts() {
    return (select(contacts)
          ..where((t) => t.blocked.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.lastMessageExchange)]))
        .get();
  }

  Stream<int?> watchContactsBlocked() {
    final count = contacts.userId.count();
    final query = selectOnly(contacts)
      ..where(contacts.blocked.equals(true))
      ..addColumns([count]);
    return query.map((row) => row.read(count)).watchSingle();
  }

  Stream<int?> watchContactsRequested() {
    final count = contacts.requested.count(distinct: true);
    final query = selectOnly(contacts)
      ..where(
        contacts.requested.equals(true) & contacts.accepted.equals(true).not(),
      )
      ..addColumns([count]);
    return query.map((row) => row.read(count)).watchSingle();
  }

  Stream<List<Contact>> watchAllContacts() {
    return select(contacts).watch();
  }

  Future<void> modifyFlameCounterForTesting() async {
    await update(contacts).write(
      ContactsCompanion(
        lastFlameCounterChange: Value(DateTime.now()),
        flameCounter: const Value(1337),
        lastFlameSync: const Value(null),
      ),
    );
  }

  Stream<int> watchFlameCounter(int userId) {
    return (select(contacts)
          ..where(
            (u) =>
                u.userId.equals(userId) &
                u.lastMessageReceived.isNotNull() &
                u.lastMessageSend.isNotNull(),
          ))
        .watchSingle()
        .asyncMap(getFlameCounterFromContact);
  }
}

String getContactDisplayName(Contact user) {
  var name = user.username;
  if (user.nickName != null && user.nickName != '') {
    name = user.nickName!;
  } else if (user.displayName != null) {
    name = user.displayName!;
  }
  if (user.deleted) {
    name = applyStrikethrough(name);
  }
  if (name.length > 12) {
    return '${name.substring(0, 12)}...';
  }
  return name;
}

String applyStrikethrough(String text) {
  return text.split('').map((char) => '$char\u0336').join();
}

int getFlameCounterFromContact(Contact contact) {
  if (contact.lastMessageSend == null || contact.lastMessageReceived == null) {
    return 0;
  }
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final twoDaysAgo = startOfToday.subtract(const Duration(days: 2));
  if (contact.lastMessageSend!.isAfter(twoDaysAgo) &&
      contact.lastMessageReceived!.isAfter(twoDaysAgo)) {
    return contact.flameCounter + 1;
  } else {
    return 0;
  }
}
