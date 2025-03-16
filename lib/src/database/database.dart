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
          ..where((t) => t.openedAt.isNull() & t.contactId.equals(contactId))
          ..orderBy([(t) => OrderingTerm.desc(t.sendAt)]))
        .watch();
  }

  Stream<List<Message>> watchMediaMessageNotOpened(int contactId) {
    return (select(messages)
          ..where((t) =>
              t.openedAt.isNull() &
              t.contactId.equals(contactId) &
              t.kind.equals(MessageKind.media.name))
          ..orderBy([(t) => OrderingTerm.desc(t.sendAt)]))
        .watch();
  }

  Stream<List<Message>> watchLastMessage(int contactId) {
    return (select(messages)
          ..where((t) => t.contactId.equals(contactId))
          ..orderBy([(t) => OrderingTerm.desc(t.sendAt)])
          ..limit(1))
        .watch();
  }

  Stream<List<Message>> watchAllMessagesFrom(int contactId) {
    return (select(messages)
          ..where((t) => t.contactId.equals(contactId))
          ..orderBy([(t) => OrderingTerm.desc(t.sendAt)]))
        .watch();
  }

  Future<List<Message>> getAllMessagesPendingDownloading() {
    return (select(messages)
          ..where(
            (t) =>
                t.downloadState.equals(DownloadState.downloaded.index).not() &
                t.messageOtherId.isNotNull() &
                t.kind.equals(MessageKind.media.name),
          ))
        .get();
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

  SingleOrNullSelectable<Message> getMessageByMessageId(int messageId) {
    return select(messages)..where((t) => t.messageId.equals(messageId));
  }

  // ------------

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
    Value<DateTime?> lastMessage = Value.absent();

    if (contact.lastMessage != null) {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      if (contact.lastMessage!.isBefore(startOfToday)) {
        // last flame update was yesterday. check if it can be updated.
        bool updateFlame = false;
        if (received) {
          if (contact.lastMessageSend!.isAfter(startOfToday)) {
            // today a message was already send -> update flame
            updateFlame = true;
          }
        } else if (contact.lastMessageReceived!.isAfter(startOfToday)) {
          // today a message was already received -> update flame
          updateFlame = true;
        }
        if (updateFlame) {
          flameCounter += 1;
          lastMessage = Value(timestamp);
        }
      }
    } else {
      // There where no message until no...
      lastMessage = Value(timestamp);
    }

    if (received) {
      lastMessageReceived = Value(timestamp);
    } else {
      lastMessageSend = Value(timestamp);
    }

    return (update(contacts)..where((t) => t.userId.equals(contactId))).write(
      ContactsCompanion(
        totalMediaCounter: Value(totalMediaCounter),
        lastMessage: lastMessage,
        lastMessageReceived: lastMessageReceived,
        lastMessageSend: lastMessageSend,
        flameCounter: Value(flameCounter),
      ),
    );

    // twonlyDatabase.updateContact(
    //   fromUserId,
    //   ContactsCompanion(
    //     lastMessageReceived: Value(message.timestamp),
    //   ),
    // );
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
          ..orderBy([(t) => OrderingTerm.desc(t.lastMessage)]))
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
