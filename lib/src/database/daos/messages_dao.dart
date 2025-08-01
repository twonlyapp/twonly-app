import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts_table.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/log.dart';

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
                  t.mediaStored.equals(true) |
                  t.openedAt.isBiggerThanValue(
                      DateTime.now().subtract(const Duration(days: 1)))))
          ..orderBy([(t) => OrderingTerm.asc(t.sendAt)]))
        .watch();
  }

  Future<void> removeOldMessages() {
    return (update(messages)
          ..where((t) =>
              (t.openedAt.isSmallerThanValue(
                    DateTime.now().subtract(const Duration(days: 1)),
                  ) |
                  (t.sendAt.isSmallerThanValue(
                          DateTime.now().subtract(const Duration(days: 1))) &
                      t.errorWhileSending.equals(true))) &
              t.kind.equals(MessageKind.textMessage.name)))
        .write(const MessagesCompanion(contentJson: Value(null)));
  }

  Future<void> handleMediaFilesOlderThan30Days() {
    /// media files will be deleted by the server after 30 days, so delete them here also
    return (update(messages)
          ..where(
            (t) => (t.kind.equals(MessageKind.media.name) &
                t.openedAt.isNull() &
                t.messageOtherId.isNull() &
                (t.sendAt.isSmallerThanValue(
                  DateTime.now().subtract(
                    const Duration(days: 30),
                  ),
                ))),
          ))
        .write(const MessagesCompanion(errorWhileSending: Value(true)));
  }

  Future<List<Message>> getAllMessagesPendingDownloading() {
    return (select(messages)
          ..where(
            (t) =>
                t.downloadState.equals(DownloadState.downloaded.index).not() &
                t.messageOtherId.isNotNull() &
                t.errorWhileSending.equals(false) &
                t.kind.equals(MessageKind.media.name),
          ))
        .get();
  }

  Future<List<Message>> getAllNonACKMessagesFromUser() {
    return (select(messages)
          ..where((t) =>
              t.acknowledgeByUser.equals(false) &
              t.messageOtherId.isNull() &
              t.errorWhileSending.equals(false) &
              t.sendAt.isBiggerThanValue(
                DateTime.now().subtract(const Duration(minutes: 10)),
              )))
        .get();
  }

  Stream<List<Message>> getAllStoredMediaFiles() {
    return (select(messages)
          ..where((t) => t.mediaStored.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.sendAt)]))
        .watch();
  }

  Future<List<Message>> getAllMessagesPendingUpload() {
    return (select(messages)
          ..where(
            (t) =>
                t.acknowledgeByServer.equals(false) &
                t.messageOtherId.isNull() &
                t.mediaUploadId.isNotNull() &
                t.downloadState.equals(DownloadState.pending.index) &
                t.errorWhileSending.equals(false) &
                t.kind.equals(MessageKind.media.name),
          ))
        .get();
  }

  Future<void> openedAllNonMediaMessages(int contactId) {
    final updates = MessagesCompanion(openedAt: Value(DateTime.now()));
    return (update(messages)
          ..where((t) =>
              t.contactId.equals(contactId) &
              t.messageOtherId.isNotNull() &
              t.openedAt.isNull() &
              t.kind.equals(MessageKind.media.name).not()))
        .write(updates);
  }

  Future<void> resetPendingDownloadState() {
    // All media files in the downloading state are reset to the pending state
    // When the app is used in mobile network, they will not be downloaded at the start
    // if they are not yet downloaded...
    const updates =
        MessagesCompanion(downloadState: Value(DownloadState.pending));
    return (update(messages)
          ..where((t) =>
              t.messageOtherId.isNotNull() &
              t.downloadState.equals(DownloadState.downloading.index) &
              t.kind.equals(MessageKind.media.name)))
        .write(updates);
  }

  Future<void> openedAllNonMediaMessagesFromOtherUser(int contactId) {
    final updates = MessagesCompanion(openedAt: Value(DateTime.now()));
    return (update(messages)
          ..where((t) =>
              t.contactId.equals(contactId) &
              t.messageOtherId
                  .isNull() & // only mark messages open that where send
              t.openedAt.isNull() &
              t.kind.equals(MessageKind.media.name).not()))
        .write(updates);
  }

  Future<void> updateMessageByOtherUser(
      int userId, int messageId, MessagesCompanion updatedValues) {
    return (update(messages)
          ..where((c) =>
              c.contactId.equals(userId) & c.messageId.equals(messageId)))
        .write(updatedValues);
  }

  Future<void> updateMessageByOtherMessageId(
      int userId, int messageOtherId, MessagesCompanion updatedValues) {
    return (update(messages)
          ..where((c) =>
              c.contactId.equals(userId) &
              c.messageOtherId.equals(messageOtherId)))
        .write(updatedValues);
  }

  Future<void> updateMessageByMessageId(
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
      Log.error('Error while inserting message: $e');
      return null;
    }
  }

  Future<void> deleteMessagesByContactId(int contactId) {
    return (delete(messages)
          ..where((t) =>
              t.contactId.equals(contactId) & t.mediaStored.equals(false)))
        .go();
  }

  Future<void> deleteMessagesByContactIdAndOtherMessageId(
      int contactId, int messageOtherId) {
    return (delete(messages)
          ..where((t) =>
              t.contactId.equals(contactId) &
              t.messageOtherId.equals(messageOtherId)))
        .go();
  }

  Future<void> deleteMessagesByMessageId(int messageId) {
    return (delete(messages)..where((t) => t.messageId.equals(messageId))).go();
  }

  Future<void> deleteAllMessagesByContactId(int contactId) {
    return (delete(messages)..where((t) => t.contactId.equals(contactId))).go();
  }

  Future<bool> containsOtherMessageId(
    int fromUserId,
    int messageOtherId,
  ) async {
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

  Future<List<Message>> getMessagesByMediaUploadId(int mediaUploadId) async {
    return (select(messages)
          ..where((t) => t.mediaUploadId.equals(mediaUploadId)))
        .get();
  }

  SingleOrNullSelectable<Message> getMessageByOtherMessageId(
      int fromUserId, int messageId) {
    return select(messages)
      ..where((t) =>
          t.messageOtherId.equals(messageId) & t.contactId.equals(fromUserId));
  }

  SingleOrNullSelectable<Message> getMessageByIdAndContactId(
      int fromUserId, int messageId) {
    return select(messages)
      ..where((t) =>
          t.messageId.equals(messageId) & t.contactId.equals(fromUserId));
  }
}
