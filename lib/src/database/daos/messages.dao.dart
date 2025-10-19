import 'package:drift/drift.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafile.service.dart';
import 'package:twonly/src/utils/log.dart';

part 'messages.dao.g.dart';

@DriftAccessor(
  tables: [
    Messages,
    Contacts,
    MediaFiles,
    MessageHistories,
    Groups,
  ],
)
class MessagesDao extends DatabaseAccessor<TwonlyDB> with _$MessagesDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  // ignore: matching_super_parameters
  MessagesDao(super.db);

  // Stream<List<Message>> watchMessageNotOpened(int contactId) {
  //   return (select(messages)
  //         ..where(
  //           (t) =>
  //               t.openedAt.isNull() &
  //               t.contactId.equals(contactId) &
  //               t.errorWhileSending.equals(false),
  //         )
  //         ..orderBy([(t) => OrderingTerm.desc(t.sendAt)]))
  //       .watch();
  // }

  // Stream<List<Message>> watchMediaMessageNotOpened(int contactId) {
  //   return (select(messages)
  //         ..where(
  //           (t) =>
  //               t.openedAt.isNull() &
  //               t.contactId.equals(contactId) &
  //               t.errorWhileSending.equals(false) &
  //               t.messageOtherId.isNotNull() &
  //               t.kind.equals(MessageKind.media.name),
  //         )
  //         ..orderBy([(t) => OrderingTerm.asc(t.sendAt)]))
  //       .watch();
  // }

  // Stream<List<Message>> watchLastMessage(int contactId) {
  //   return (select(messages)
  //         ..where((t) => t.contactId.equals(contactId))
  //         ..orderBy([(t) => OrderingTerm.desc(t.sendAt)])
  //         ..limit(1))
  //       .watch();
  // }

  // Stream<List<Message>> watchAllMessagesFrom(int contactId) {
  //   return (select(messages)
  //         ..where(
  //           (t) =>
  //               t.contactId.equals(contactId) &
  //               t.contentJson.isNotNull() &
  //               (t.openedAt.isNull() |
  //                   t.mediaStored.equals(true) |
  //                   t.openedAt.isBiggerThanValue(
  //                     DateTime.now().subtract(const Duration(days: 1)),
  //                   )),
  //         )
  //         ..orderBy([(t) => OrderingTerm.asc(t.sendAt)]))
  //       .watch();
  // }

  // Future<void> removeOldMessages() {
  //   return (update(messages)
  //         ..where(
  //           (t) =>
  //               (t.openedAt.isSmallerThanValue(
  //                     DateTime.now().subtract(const Duration(days: 1)),
  //                   ) |
  //                   (t.sendAt.isSmallerThanValue(
  //                         DateTime.now().subtract(const Duration(days: 3)),
  //                       ) &
  //                       t.errorWhileSending.equals(true))) &
  //               t.kind.equals(MessageKind.textMessage.name),
  //         ))
  //       .write(const MessagesCompanion(contentJson: Value(null)));
  // }

  // Future<void> handleMediaFilesOlderThan30Days() {
  //   /// media files will be deleted by the server after 30 days, so delete them here also
  //   return (update(messages)
  //         ..where(
  //           (t) => (t.kind.equals(MessageKind.media.name) &
  //               t.openedAt.isNull() &
  //               t.messageOtherId.isNull() &
  //               (t.sendAt.isSmallerThanValue(
  //                 DateTime.now().subtract(
  //                   const Duration(days: 30),
  //                 ),
  //               ))),
  //         ))
  //       .write(const MessagesCompanion(errorWhileSending: Value(true)));
  // }

  // Future<List<Message>> getAllMessagesPendingDownloading() {
  //   return (select(messages)
  //         ..where(
  //           (t) =>
  //               t.downloadState.equals(DownloadState.downloaded.index).not() &
  //               t.messageOtherId.isNotNull() &
  //               t.errorWhileSending.equals(false) &
  //               t.kind.equals(MessageKind.media.name),
  //         ))
  //       .get();
  // }

  // Future<List<Message>> getAllNonACKMessagesFromUser() {
  //   return (select(messages)
  //         ..where(
  //           (t) =>
  //               t.acknowledgeByUser.equals(false) &
  //               t.messageOtherId.isNull() &
  //               t.errorWhileSending.equals(false) &
  //               t.sendAt.isBiggerThanValue(
  //                 DateTime.now().subtract(const Duration(minutes: 10)),
  //               ),
  //         ))
  //       .get();
  // }

  // Stream<List<Message>> getAllStoredMediaFiles() {
  //   return (select(messages)
  //         ..where((t) => t.mediaStored.equals(true))
  //         ..orderBy([(t) => OrderingTerm.desc(t.sendAt)]))
  //       .watch();
  // }

  // Future<List<Message>> getAllMessagesPendingUpload() {
  //   return (select(messages)
  //         ..where(
  //           (t) =>
  //               t.acknowledgeByServer.equals(false) &
  //               t.messageOtherId.isNull() &
  //               t.mediaUploadId.isNotNull() &
  //               t.downloadState.equals(DownloadState.pending.index) &
  //               t.errorWhileSending.equals(false) &
  //               t.kind.equals(MessageKind.media.name),
  //         ))
  //       .get();
  // }

  // Future<void> openedAllNonMediaMessages(int contactId) {
  //   final updates = MessagesCompanion(openedAt: Value(DateTime.now()));
  //   return (update(messages)
  //         ..where(
  //           (t) =>
  //               t.contactId.equals(contactId) &
  //               t.messageOtherId.isNotNull() &
  //               t.openedAt.isNull() &
  //               t.kind.equals(MessageKind.media.name).not(),
  //         ))
  //       .write(updates);
  // }

  Future<void> handleMessageDeletion(
    int contactId,
    String messageId,
    DateTime timestamp,
  ) async {
    final msg = await getMessageById(messageId).getSingleOrNull();
    if (msg == null || msg.senderId != contactId) return;
    if (msg.mediaId != null) {
      await (delete(mediaFiles)..where((t) => t.mediaId.equals(msg.mediaId!)))
          .go();
      await removeMediaFile(msg.mediaId!);
    }
    await (delete(messageHistories)
          ..where((t) => t.messageId.equals(messageId)))
        .go();

    await (update(messages)
          ..where(
            (t) => t.messageId.equals(messageId) & t.senderId.equals(contactId),
          ))
        .write(
      MessagesCompanion(
        isDeletedFromSender: const Value(true),
        content: const Value(null),
        modifiedAt: Value(timestamp),
        mediaId: const Value(null),
      ),
    );
  }

  Future<void> handleTextEdit(
    int contactId,
    String messageId,
    String text,
    DateTime timestamp,
  ) async {
    final msg = await getMessageById(messageId).getSingleOrNull();
    if (msg == null || msg.content == null || msg.senderId == contactId) {
      return;
    }
    await into(messageHistories).insert(
      MessageHistoriesCompanion(
        messageId: Value(messageId),
        content: Value(msg.content),
      ),
    );
    await (update(messages)
          ..where(
            (t) => t.messageId.equals(messageId) & t.senderId.equals(contactId),
          ))
        .write(
      MessagesCompanion(
        content: Value(text),
        modifiedAt: Value(timestamp),
      ),
    );
  }

  Future<void> handleMessageOpened(
    String groupId,
    String messageId,
    DateTime timestamp,
  ) async {
    final msg = await getMessageById(messageId).getSingleOrNull();
    if (msg == null) return;
    await (update(messages)
          ..where(
            (t) =>
                t.groupId.equals(groupId) &
                t.messageId.equals(messageId) &
                t.senderId.isNull(),
          ))
        .write(
      MessagesCompanion(
        openedAt: Value(timestamp),
        openedByCounter: Value(msg.openedByCounter + 1),
      ),
    );
  }

  // Future<void> updateMessageByOtherUser(
  //   int userId,
  //   int messageId,
  //   MessagesCompanion updatedValues,
  // ) {
  //   return (update(messages)
  //         ..where(
  //           (c) => c.contactId.equals(userId) & c.messageId.equals(messageId),
  //         ))
  //       .write(updatedValues);
  // }

  // Future<void> updateMessageByOtherMessageId(
  //   int userId,
  //   int messageOtherId,
  //   MessagesCompanion updatedValues,
  // ) {
  //   return (update(messages)
  //         ..where(
  //           (c) =>
  //               c.contactId.equals(userId) &
  //               c.messageOtherId.equals(messageOtherId),
  //         ))
  //       .write(updatedValues);
  // }

  Future<void> updateMessageId(
    String messageId,
    MessagesCompanion updatedValues,
  ) {
    return (update(messages)..where((c) => c.messageId.equals(messageId)))
        .write(updatedValues);
  }

  Future<Message?> insertMessage(MessagesCompanion message) async {
    try {
      final rowId = await into(messages).insert(message);

      await twonlyDB.groupsDao.updateGroup(
        message.groupId.value,
        GroupsCompanion(
          lastMessageExchange: Value(DateTime.now()),
          archived: const Value(false),
        ),
      );

      return await (select(messages)..where((t) => t.rowId.equals(rowId)))
          .getSingle();
    } catch (e) {
      Log.error('Could not insert message: $e');
      return null;
    }
  }

  // Future<void> deleteMessagesByContactId(int contactId) {
  //   return (delete(messages)
  //         ..where(
  //           (t) => t.contactId.equals(contactId) & t.mediaStored.equals(false),
  //         ))
  //       .go();
  // }

  // Future<void> deleteMessagesByContactIdAndOtherMessageId(
  //   int contactId,
  //   int messageOtherId,
  // ) {
  //   return (delete(messages)
  //         ..where(
  //           (t) =>
  //               t.contactId.equals(contactId) &
  //               t.messageOtherId.equals(messageOtherId),
  //         ))
  //       .go();
  // }

  // Future<void> deleteMessagesByMessageId(int messageId) {
  //   return (delete(messages)..where((t) => t.messageId.equals(messageId))).go();
  // }

  // Future<void> deleteAllMessagesByContactId(int contactId) {
  //   return (delete(messages)..where((t) => t.contactId.equals(contactId))).go();
  // }

  // Future<bool> containsOtherMessageId(
  //   int fromUserId,
  //   int messageOtherId,
  // ) async {
  //   final query = select(messages)
  //     ..where(
  //       (t) =>
  //           t.messageOtherId.equals(messageOtherId) &
  //           t.contactId.equals(fromUserId),
  //     );
  //   final entry = await query.get();
  //   return entry.isNotEmpty;
  // }

  SingleOrNullSelectable<Message> getMessageById(String messageId) {
    return select(messages)..where((t) => t.messageId.equals(messageId));
  }

  // Future<List<Message>> getMessagesByMediaUploadId(int mediaUploadId) async {
  //   return (select(messages)
  //         ..where((t) => t.mediaUploadId.equals(mediaUploadId)))
  //       .get();
  // }

  // SingleOrNullSelectable<Message> getMessageByOtherMessageId(
  //   int fromUserId,
  //   int messageId,
  // ) {
  //   return select(messages)
  //     ..where(
  //       (t) =>
  //           t.messageOtherId.equals(messageId) & t.contactId.equals(fromUserId),
  //     );
  // }

  // SingleOrNullSelectable<Message> getMessageByIdAndContactId(
  //   int fromUserId,
  //   int messageId,
  // ) {
  //   return select(messages)
  //     ..where(
  //       (t) => t.messageId.equals(messageId) & t.contactId.equals(fromUserId),
  //     );
  // }
}
