import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/database/tables/contacts_table.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';

part 'messages_dao.g.dart';

@DriftAccessor(tables: [Messages, Contacts])
class MessagesDao extends DatabaseAccessor<TwonlyDatabase>
    with _$MessagesDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  MessagesDao(super.db);

  Stream<List<Message>> watchMessageNotOpened(int contactId) {
    return (select(messages)
          ..where((t) =>
              t.openedAt.isNull() &
              t.contactId.equals(contactId) &
              t.errorWhileSending.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.sendAt)]))
        .watch();
  }

  Stream<List<Message>> watchMediaMessageNotOpened(int contactId) {
    return (select(messages)
          ..where((t) =>
              t.openedAt.isNull() &
              t.contactId.equals(contactId) &
              t.errorWhileSending.equals(false) &
              t.messageOtherId.isNotNull() &
              t.kind.equals(MessageKind.media.name))
          ..orderBy([(t) => OrderingTerm.asc(t.sendAt)]))
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
          ..where((t) =>
              t.contactId.equals(contactId) &
              t.contentJson.isNotNull() &
              (t.openedAt.isNull() |
                  t.openedAt.isBiggerThanValue(
                      DateTime.now().subtract(Duration(days: 1)))))
          ..orderBy([(t) => OrderingTerm.desc(t.sendAt)]))
        .watch();
  }

  Future removeOldMessages() {
    return (update(messages)
          ..where((t) =>
              (t.openedAt.isSmallerThanValue(
                    DateTime.now().subtract(Duration(days: 1)),
                  ) |
                  (t.sendAt.isSmallerThanValue(
                          DateTime.now().subtract(Duration(days: 1))) &
                      t.errorWhileSending.equals(true))) &
              t.kind.equals(MessageKind.textMessage.name)))
        .write(MessagesCompanion(contentJson: Value(null)));
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

  Future<List<Message>> getAllMessagesPendingUploadOlderThanAMinute() {
    return (select(messages)
          ..where(
            (t) =>
                t.acknowledgeByServer.equals(false) &
                t.messageOtherId.isNull() &
                t.errorWhileSending.equals(false) &
                t.sendAt.isSmallerThanValue(
                    DateTime.now().subtract(Duration(minutes: 5))) &
                t.kind.equals(MessageKind.media.name),
          ))
        .get();
  }

  Future openedAllNonMediaMessages(int contactId) {
    final updates = MessagesCompanion(openedAt: Value(DateTime.now()));
    return (update(messages)
          ..where((t) =>
              t.contactId.equals(contactId) &
              t.messageOtherId.isNotNull() &
              t.openedAt.isNull() &
              t.kind.equals(MessageKind.media.name).not()))
        .write(updates);
  }

  Future resetPendingDownloadState() {
    // All media files in the downloading state are reseteded to the pending state
    // When the app is used in mobile network, they will not be downloaded at the start
    // if they are not yet downloaded...
    final updates =
        MessagesCompanion(downloadState: Value(DownloadState.pending));
    return (update(messages)
          ..where((t) =>
              t.messageOtherId.isNotNull() &
              t.downloadState.equals(DownloadState.downloading.index) &
              t.kind.equals(MessageKind.media.name)))
        .write(updates);
  }

  Future openedAllNonMediaMessagesFromOtherUser(int contactId) {
    final updates = MessagesCompanion(openedAt: Value(DateTime.now()));
    return (update(messages)
          ..where((t) =>
              t.contactId.equals(contactId) &
              t.openedAt.isNull() &
              t.kind.equals(MessageKind.media.name).not()))
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
      await (update(contacts)
            ..where((c) => c.userId.equals(message.contactId.value)))
          .write(ContactsCompanion(lastMessageExchange: Value(DateTime.now())));

      return await into(messages).insert(message);
    } catch (e) {
      Logger("twonlyDatabase").shout("Error while inserting message: $e");
      return null;
    }
  }

  Future deleteMessageById(int messageId) {
    return (delete(messages)..where((t) => t.messageId.equals(messageId))).go();
  }

  Future deleteMessagesByContactId(int contactId) {
    return (delete(messages)..where((t) => t.contactId.equals(contactId))).go();
  }

  Future<bool> containsOtherMessageId(
      int fromUserId, int messageOtherId) async {
    final query = select(messages)
      ..where((t) =>
          t.messageOtherId.equals(messageOtherId) &
          t.contactId.equals(fromUserId));
    final entry = await query.get();
    return entry.isNotEmpty;
  }

  SingleOrNullSelectable<Message> getMessageByMessageId(int messageId) {
    return select(messages)..where((t) => t.messageId.equals(messageId));
  }

  SingleOrNullSelectable<Message> getMessageByOtherMessageId(
      int fromUserId, int messageId) {
    return select(messages)
      ..where((t) =>
          t.messageOtherId.equals(messageId) & t.contactId.equals(fromUserId));
  }
}
