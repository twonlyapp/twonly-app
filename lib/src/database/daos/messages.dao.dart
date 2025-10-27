import 'package:drift/drift.dart';
import 'package:hashlib/random.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/tables/reactions.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/log.dart';

part 'messages.dao.g.dart';

@DriftAccessor(
  tables: [
    Messages,
    Contacts,
    MediaFiles,
    Reactions,
    MessageHistories,
    GroupMembers,
    MessageActions,
    Groups,
  ],
)
class MessagesDao extends DatabaseAccessor<TwonlyDB> with _$MessagesDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  // ignore: matching_super_parameters
  MessagesDao(super.db);

  Stream<List<Message>> watchMessageNotOpened(String groupId) {
    return (select(messages)
          ..where((t) => t.openedAt.isNull() & t.groupId.equals(groupId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<Message>> watchMediaNotOpened(String groupId) {
    final query = select(messages).join([
      leftOuterJoin(mediaFiles, mediaFiles.mediaId.equalsExp(messages.mediaId)),
    ])
      ..where(
        mediaFiles.downloadState
                .equals(DownloadState.reuploadRequested.name)
                .not() &
            messages.openedAt.isNull() &
            messages.groupId.equals(groupId) &
            messages.mediaId.isNotNull() &
            messages.senderId.isNotNull() &
            messages.type.equals(MessageType.media.name),
      );
    return query.map((row) => row.readTable(messages)).watch();
  }

  Stream<Message?> watchLastMessage(String groupId) {
    return (select(messages)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Stream<List<Message>> watchByGroupId(String groupId) {
    return ((select(messages)..where((t) => t.groupId.equals(groupId)))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  // Stream<List<GroupMember>> watchMembersByGroupId(String groupId) {
  //   return (select(groupMembers)..where((t) => t.groupId.equals(groupId)))
  //       .watch();
  // }

  Stream<List<(GroupMember, Contact)>> watchMembersByGroupId(String groupId) {
    final query = (select(groupMembers).join([
      leftOuterJoin(
        contacts,
        contacts.userId.equalsExp(groupMembers.contactId),
      ),
    ])
      ..where(groupMembers.groupId.equals(groupId)));
    return query
        .map((row) => (row.readTable(groupMembers), row.readTable(contacts)))
        .watch();
  }

  Stream<List<MessageAction>> watchMessageActionChanges(String messageId) {
    return (select(messageActions)..where((t) => t.messageId.equals(messageId)))
        .watch();
  }

  Stream<Message?> watchMessageById(String messageId) {
    return (select(messages)..where((t) => t.messageId.equals(messageId)))
        .watchSingleOrNull();
  }

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

  Future<void> openedAllTextMessages(String groupId) {
    final updates = MessagesCompanion(openedAt: Value(DateTime.now()));
    return (update(messages)
          ..where(
            (t) =>
                t.groupId.equals(groupId) &
                t.senderId.isNotNull() &
                t.openedAt.isNull() &
                t.type.equals(MessageType.text.name),
          ))
        .write(updates);
  }

  Future<void> handleMessageDeletion(
    int? contactId,
    String messageId,
    DateTime timestamp,
  ) async {
    final msg = await getMessageById(messageId).getSingleOrNull();
    if (msg == null || msg.senderId != contactId) {
      Log.error('Message does not exists or contact is not owner.');
      return;
    }
    if (msg.mediaId != null) {
      await (delete(mediaFiles)..where((t) => t.mediaId.equals(msg.mediaId!)))
          .go();

      final mediaService = await MediaFileService.fromMediaId(msg.mediaId!);
      if (mediaService != null) {
        mediaService.fullMediaRemoval();
      }
    }
    await (delete(messageHistories)
          ..where((t) => t.messageId.equals(messageId)))
        .go();

    await (update(messages)
          ..where(
            (t) => t.messageId.equals(messageId),
          ))
        .write(
      const MessagesCompanion(
        isDeletedFromSender: Value(true),
        content: Value(null),
        mediaId: Value(null),
      ),
    );
  }

  Future<void> handleTextEdit(
    int? contactId,
    String messageId,
    String text,
    DateTime timestamp,
  ) async {
    final msg = await getMessageById(messageId).getSingleOrNull();
    if (msg == null || msg.content == null || msg.senderId != contactId) {
      return;
    }
    await into(messageHistories).insert(
      MessageHistoriesCompanion(
        messageId: Value(messageId),
        content: Value(msg.content),
        createdAt: Value(timestamp),
      ),
    );
    await (update(messages)
          ..where(
            (t) => t.messageId.equals(messageId),
          ))
        .write(
      MessagesCompanion(
        content: Value(text),
        modifiedAt: Value(timestamp),
      ),
    );
  }

  Future<void> handleMessageOpened(
    int contactId,
    String messageId,
    DateTime timestamp,
  ) async {
    await into(messageActions).insertOnConflictUpdate(
      MessageActionsCompanion(
        messageId: Value(messageId),
        contactId: Value(contactId),
        type: const Value(MessageActionType.openedAt),
        actionAt: Value(timestamp),
      ),
    );
    if (await haveAllMembers(messageId, MessageActionType.openedAt)) {
      await twonlyDB.messagesDao.updateMessageId(
        messageId,
        MessagesCompanion(openedAt: Value(DateTime.now())),
      );
    }
  }

  Future<void> handleMessageAckByServer(
    int contactId,
    String messageId,
    DateTime timestamp,
  ) async {
    await into(messageActions).insertOnConflictUpdate(
      MessageActionsCompanion(
        messageId: Value(messageId),
        contactId: Value(contactId),
        type: const Value(MessageActionType.ackByServerAt),
        actionAt: Value(timestamp),
      ),
    );
    if (await haveAllMembers(messageId, MessageActionType.ackByServerAt)) {
      await twonlyDB.messagesDao.updateMessageId(
        messageId,
        MessagesCompanion(ackByServer: Value(DateTime.now())),
      );
    }
  }

  Future<bool> haveAllMembers(
    String messageId,
    MessageActionType action,
  ) async {
    final message =
        await twonlyDB.messagesDao.getMessageById(messageId).getSingleOrNull();
    if (message == null) return true;
    final members = await twonlyDB.groupsDao.getGroupMembers(message.groupId);

    final actions = await (select(messageActions)
          ..where(
            (t) => t.type.equals(action.name) & t.messageId.equals(messageId),
          ))
        .get();

    return members.length == actions.length;
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

  Future<void> updateMessagesByMediaId(
    String mediaId,
    MessagesCompanion updatedValues,
  ) {
    return (update(messages)..where((c) => c.mediaId.equals(mediaId)))
        .write(updatedValues);
  }

  Future<Message?> insertMessage(MessagesCompanion message) async {
    try {
      var insertMessage = message;

      if (message.messageId == const Value.absent()) {
        insertMessage = message.copyWith(
          messageId: Value(uuid.v7()),
        );
      }

      final rowId = await into(messages).insert(insertMessage);

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

  Future<MessageAction?> getLastMessageAction(String messageId) async {
    return (((select(messageActions)
          ..where(
            (t) => t.messageId.equals(messageId),
          ))
          ..orderBy([(t) => OrderingTerm.desc(t.actionAt)]))
          ..limit(1))
        .getSingleOrNull();
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

  Future<void> deleteMessagesById(String messageId) {
    return (delete(messages)..where((t) => t.messageId.equals(messageId))).go();
  }

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

  Future<List<Message>> getMessagesByMediaId(String mediaId) async {
    return (select(messages)..where((t) => t.mediaId.equals(mediaId))).get();
  }

  Stream<List<(MessageAction, Contact)>> watchMessageActions(String messageId) {
    final query = (select(messageActions).join([
      leftOuterJoin(
        contacts,
        contacts.userId.equalsExp(messageActions.contactId),
      ),
    ])
      ..where(messageActions.messageId.equals(messageId)));
    return query
        .map((row) => (row.readTable(messageActions), row.readTable(contacts)))
        .watch();
  }

  Stream<List<MessageHistory>> watchMessageHistory(String messageId) {
    return (select(messageHistories)
          ..where((t) => t.messageId.equals(messageId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
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
