import 'package:clock/clock.dart';
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
          ..where(
            (t) =>
                t.openedAt.isNull() &
                t.groupId.equals(groupId) &
                t.isDeletedFromSender.equals(false),
          )
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
            mediaFiles.type.equals(MediaType.audio.name).not() &
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
    return ((select(messages)
          ..where(
            (t) =>
                t.groupId.equals(groupId) &
                (t.isDeletedFromSender.equals(true) |
                    (t.type.equals(MessageType.text.name).not() |
                        t.type.equals(MessageType.media.name).not()) |
                    (t.type.equals(MessageType.text.name) &
                        t.content.isNotNull()) |
                    (t.type.equals(MessageType.media.name) &
                        t.mediaId.isNotNull())),
          ))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

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

  Future<void> purgeMessageTable() async {
    final allGroups = await select(groups).get();

    for (final group in allGroups) {
      final deletionTime = clock.now().subtract(
            Duration(
              milliseconds: group.deleteMessagesAfterMilliseconds,
            ),
          );
      await (delete(messages)
            ..where(
              (m) =>
                  m.groupId.equals(group.groupId) &
                  (m.mediaStored.equals(true) &
                          m.isDeletedFromSender.equals(true) |
                      m.mediaStored.equals(false)) &
                  (m.openedAt.isSmallerThanValue(deletionTime) |
                      (m.isDeletedFromSender.equals(true) &
                          m.createdAt.isSmallerThanValue(deletionTime))),
            ))
          .go();
    }
  }

  Future<void> openedAllTextMessages(String groupId) {
    final updates = MessagesCompanion(openedAt: Value(clock.now()));
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
    if (msg.mediaId != null && contactId != null) {
      // contactId -> When a image is send to multiple and one message is delete the image should be still available...
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
    // Directly show as message opened as soon as one person has opened it
    final openedByAll =
        await haveAllMembers(messageId, MessageActionType.openedAt)
            ? clock.now()
            : null;
    await twonlyDB.messagesDao.updateMessageId(
      messageId,
      MessagesCompanion(
        openedAt: Value(clock.now()),
        openedByAll: Value(openedByAll),
      ),
    );
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
    await twonlyDB.messagesDao.updateMessageId(
      messageId,
      MessagesCompanion(ackByServer: Value(clock.now())),
    );
  }

  Future<bool> haveAllMembers(
    String messageId,
    MessageActionType action,
  ) async {
    final message =
        await twonlyDB.messagesDao.getMessageById(messageId).getSingleOrNull();
    if (message == null) return true;
    final members =
        await twonlyDB.groupsDao.getGroupNonLeftMembers(message.groupId);

    final actions = await (select(messageActions)
          ..where(
            (t) => t.type.equals(action.name) & t.messageId.equals(messageId),
          ))
        .get();

    return members.length == actions.length;
  }

  Future<void> updateMessageId(
    String messageId,
    MessagesCompanion updatedValues,
  ) async {
    await (update(messages)..where((c) => c.messageId.equals(messageId)))
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
          lastMessageExchange: Value(clock.now()),
          archived: const Value(false),
          deletedContent: const Value(false),
        ),
      );

      if (message.senderId.present) {
        await twonlyDB.groupsDao.updateMember(
          message.groupId.value,
          message.senderId.value!,
          GroupMembersCompanion(
            lastMessage: Value(clock.now()),
          ),
        );
      }

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

  Future<void> deleteMessagesById(String messageId) {
    return (delete(messages)..where((t) => t.messageId.equals(messageId))).go();
  }

  Future<void> deleteMessagesByGroupId(String groupId) {
    return (delete(messages)..where((t) => t.groupId.equals(groupId))).go();
  }

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
}
