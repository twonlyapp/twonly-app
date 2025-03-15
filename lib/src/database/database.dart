import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:logging/logging.dart';
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

  Stream<List<Message>> watchMessageNotOpened(int contactId) {
    return (select(messages)
          ..where((t) => t.openedAt.isNull() & t.contactId.equals(contactId)))
        .watch();
  }

  Stream<Message?> watchLastMessage(int contactId) {
    return (select(messages)
          ..where((t) => t.contactId.equals(contactId))
          ..orderBy([(t) => OrderingTerm.desc(t.sendAt)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Stream<List<Message>> watchAllMessagesFrom(int contactId) {
    return (select(messages)..where((t) => t.contactId.equals(contactId)))
        .watch();
  }

  Future<List<Message>> getAllMessagesForRetransmitting() {
    return (select(messages)..where((t) => t.acknowledgeByServer.equals(false)))
        .get();
  }

  Future openedAllTextMessages(int contactId) {
    final updates = MessagesCompanion(openedAt: Value(DateTime.now()));
    return (update(messages)
          ..where((t) =>
              t.contactId.equals(contactId) &
              t.openedAt.isNull() &
              t.kind.equals(MessageKind.textMessage.name)))
        .write(updates);
  }

  Future updateMessageByOtherUser(
      int userId, int messageId, MessagesCompanion updatedValues) {
    return (update(messages)
          ..where((c) =>
              c.contactId.equals(userId) & c.messageId.equals(messageId)))
        .write(updatedValues);
  }

  Future updateMessageByOtherMessageId(
      int userId, int messageOtherId, MessagesCompanion updatedValues) {
    return (update(messages)
          ..where((c) =>
              c.contactId.equals(userId) &
              c.messageOtherId.equals(messageOtherId)))
        .write(updatedValues);
  }

  Future updateMessageByMessageId(
      int messageId, MessagesCompanion updatedValues) {
    return (update(messages)..where((c) => c.messageId.equals(messageId)))
        .write(updatedValues);
  }

  Future<int?> insertMessage(MessagesCompanion message) async {
    try {
      return await into(messages).insert(message);
    } catch (e) {
      Logger("twonlyDatabase").shout("Error while inserting message: $e");
      return null;
    }
  }

  Future deleteMessageById(int messageId) {
    return (delete(messages)..where((t) => t.messageId.equals(messageId))).go();
  }

  // ------------

  Future<int> insertContact(ContactsCompanion contact) async {
    try {
      return await into(contacts).insert(contact);
    } catch (e) {
      return 0;
    }
  }

  Future incTotalMediaCounter(int contactId) async {
    return (update(contacts)..where((t) => t.userId.equals(contactId)))
        .write(ContactsCompanion(
      totalMediaCounter: Value(
        (await (select(contacts)..where((t) => t.userId.equals(contactId)))
                    .get())
                .first
                .totalMediaCounter +
            1,
      ),
    ));
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
    // return (select(contacts)).watch();
  }

  Stream<Contact> watchContact(int userid) {
    return (select(contacts)..where((t) => t.userId.equals(userid)))
        .watchSingle();
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
