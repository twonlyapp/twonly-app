import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts_table.dart';
import 'package:twonly/src/database/twonly_database.dart';

part 'contacts_dao.g.dart';

@DriftAccessor(tables: [Contacts])
class ContactsDao extends DatabaseAccessor<TwonlyDatabase>
    with _$ContactsDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  ContactsDao(TwonlyDatabase db) : super(db);

  Future<int> insertContact(ContactsCompanion contact) async {
    try {
      return await into(contacts).insert(contact);
    } catch (e) {
      return 0;
    }
  }

  Future incFlameCounter(
      int contactId, bool received, DateTime timestamp) async {
    Contact contact = (await (select(contacts)
              ..where((t) => t.userId.equals(contactId)))
            .get())
        .first;

    int totalMediaCounter = contact.totalMediaCounter + 1;
    int flameCounter = contact.flameCounter;

    if (contact.lastMessageReceived != null &&
        contact.lastMessageSend != null) {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final twoDaysAgo = startOfToday.subtract(Duration(days: 2));
      if (contact.lastMessageSend!.isBefore(twoDaysAgo) ||
          contact.lastMessageReceived!.isBefore(twoDaysAgo)) {
        flameCounter = 0;
      }
    }

    Value<DateTime?> lastMessageSend = Value.absent();
    Value<DateTime?> lastMessageReceived = Value.absent();
    Value<DateTime?> lastFlameCounterChange = Value.absent();

    if (contact.lastFlameCounterChange != null) {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      if (contact.lastFlameCounterChange!.isBefore(startOfToday)) {
        // last flame update was yesterday. check if it can be updated.
        bool updateFlame = false;
        if (received) {
          if (contact.lastMessageSend!.isAfter(startOfToday)) {
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

  Future deleteContactByUserId(int userId) {
    return (delete(contacts)..where((t) => t.userId.equals(userId))).go();
  }

  Future updateContact(int userId, ContactsCompanion updatedValues) {
    return (update(contacts)..where((c) => c.userId.equals(userId)))
        .write(updatedValues);
  }

  Future newMessageExchange(int userId) {
    return updateContact(
        userId, ContactsCompanion(lastMessageExchange: Value(DateTime.now())));
  }

  Stream<List<Contact>> watchNotAcceptedContacts() {
    return (select(contacts)..where((t) => t.accepted.equals(false))).watch();
    // return (select(contacts)).watch();
  }

  Stream<Contact> watchContact(int userid) {
    return (select(contacts)..where((t) => t.userId.equals(userid)))
        .watchSingle();
  }

  Stream<List<Contact>> watchContactsForChatList() {
    return (select(contacts)
          ..where((t) => t.accepted.equals(true) & t.blocked.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.lastMessageExchange)]))
        .watch();
  }

  Future<List<Contact>> getAllNotBlockedContacts() {
    return (select(contacts)
          ..where((t) => t.accepted.equals(true) & t.blocked.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.lastMessageExchange)]))
        .get();
  }

  Stream<int?> watchContactsBlocked() {
    final count = contacts.blocked.count(distinct: true);
    final query = selectOnly(contacts)..where(contacts.blocked.equals(true));
    query.addColumns([count]);
    return query.map((row) => row.read(count)).watchSingle();
  }

  Stream<int?> watchContactsRequested() {
    final count = contacts.requested.count(distinct: true);
    final query = selectOnly(contacts)
      ..where(contacts.requested.equals(true) &
          contacts.accepted.equals(true).not());
    query.addColumns([count]);
    return query.map((row) => row.read(count)).watchSingle();
  }

  Stream<List<Contact>> watchAllContacts() {
    return select(contacts).watch();
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
        .asyncMap((contact) {
      return getFlameCounterFromContact(contact);
    });
  }
}
