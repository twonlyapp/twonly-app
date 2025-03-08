import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/database/contacts_db.dart';
import 'package:twonly/src/database/messages_db.dart';
import 'package:twonly/src/model/json/message.dart';

part 'database.g.dart';

// You can then create a database class that includes this table
@DriftDatabase(tables: [Contacts, Messages])
class TwonlyDatabase extends _$TwonlyDatabase {
  TwonlyDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'twonly_main_db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  // ------------

  Stream<List<Message>> watchMessageNotOpened(int userId) {
    return (select(messages)
          ..where((t) => t.openedAt.isNull() & t.contactId.equals(userId)))
        .watch();
  }

  Stream<Message?> watchLastMessage(int userId) {
    return (select(messages)
          ..where((t) => t.contactId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.sendAt)])
          ..limit(1))
        .watchSingleOrNull();
  }

  // ------------

  Future<int> insertContact(ContactsCompanion contact) {
    return into(contacts).insert(contact);
  }

  SingleOrNullSelectable<Contact> getContactByUserId(int userId) {
    return select(contacts)..where((t) => t.userId.equals(userId));
  }

  // Stream<int> getMaxTotalMediaCounter() {
  //   return customSelect(
  //     'SELECT MAX(totalMediaCounter) AS maxTotal FROM contacts',
  //     readsFrom: {contacts},
  //   ).watchSingle().asyncMap((result) {
  //     return result.read<int>('maxTotal');
  //   });
  // }

  Future deleteContactByUserId(int userId) {
    return (delete(contacts)..where((t) => t.userId.equals(userId))).go();
  }

  Future updateContact(int userId, ContactsCompanion updatedValues) {
    return (update(contacts)..where((c) => c.userId.equals(userId)))
        .write(updatedValues);
  }

  Stream<List<Contact>> watchNotAcceptedContacts() {
    return (select(contacts)..where((t) => t.accepted.equals(false))).watch();
  }

  Stream<List<Contact>> watchContactsForChatList() {
    return (select(contacts)
          ..where((t) => t.accepted.equals(true) & t.blocked.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.lastMessage)]))
        .watch();
  }

  Stream<int?> watchContactsBlocked() {
    final count = contacts.blocked.count(distinct: true);
    final query = selectOnly(contacts)..where(contacts.blocked.equals(true));
    query.addColumns([count]);
    return query.map((row) => row.read(count)).watchSingle();
  }

  Stream<int?> watchContactsRequested() {
    final count = contacts.requested.count(distinct: true);
    final query = selectOnly(contacts)..where(contacts.requested.equals(true));
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
