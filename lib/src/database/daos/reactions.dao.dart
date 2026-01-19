import 'package:drift/drift.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/tables/reactions.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/views/components/animate_icon.dart';

part 'reactions.dao.g.dart';

@DriftAccessor(tables: [Reactions, Contacts])
class ReactionsDao extends DatabaseAccessor<TwonlyDB> with _$ReactionsDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  // ignore: matching_super_parameters
  ReactionsDao(super.db);

  Future<void> updateReaction(
    int contactId,
    String messageId,
    String groupId,
    String emoji,
    bool remove,
  ) async {
    if (!isOneEmoji(emoji)) {
      Log.error('Did not update reaction as it is not an emoji!');
      return;
    }
    final msg =
        await twonlyDB.messagesDao.getMessageById(messageId).getSingleOrNull();
    if (msg == null || msg.groupId != groupId) return;

    try {
      if (remove) {
        await (delete(reactions)
              ..where(
                (t) =>
                    t.senderId.equals(contactId) &
                    t.messageId.equals(messageId) &
                    t.emoji.equals(emoji),
              ))
            .go();
      } else {
        await into(reactions).insertOnConflictUpdate(
          ReactionsCompanion(
            messageId: Value(messageId),
            emoji: Value(emoji),
            senderId: Value(contactId),
          ),
        );
      }
    } catch (e) {
      Log.error(e);
    }
  }

  Future<void> updateMyReaction(
    String messageId,
    String emoji,
    bool remove,
  ) async {
    if (!isOneEmoji(emoji)) {
      Log.error('Did not update reaction as it is not an emoji!');
      return;
    }
    final msg =
        await twonlyDB.messagesDao.getMessageById(messageId).getSingleOrNull();
    if (msg == null) return;

    try {
      await (delete(reactions)
            ..where(
              (t) =>
                  t.senderId.isNull() &
                  t.messageId.equals(messageId) &
                  t.emoji.equals(emoji),
            ))
          .go();
      if (!remove) {
        await into(reactions).insert(
          ReactionsCompanion(
            messageId: Value(messageId),
            emoji: Value(emoji),
            senderId: const Value(null),
          ),
        );
      }
    } catch (e) {
      Log.error(e);
    }
  }

  Stream<List<Reaction>> watchReactions(String messageId) {
    return (select(reactions)
          ..where((t) => t.messageId.equals(messageId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<Reaction?> watchLastReactions(String groupId) {
    final query = (select(reactions)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .join(
      [
        innerJoin(
          messages,
          messages.messageId.equalsExp(reactions.messageId),
          useColumns: false,
        ),
      ],
    )
      ..where(messages.groupId.equals(groupId))
      // ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      ..limit(1);
    return query.map((row) => row.readTable(reactions)).watchSingleOrNull();
  }

  Stream<List<(Reaction, Contact?)>> watchReactionWithContacts(
    String messageId,
  ) {
    final query = (select(reactions)).join(
      [leftOuterJoin(contacts, contacts.userId.equalsExp(reactions.senderId))],
    )..where(reactions.messageId.equals(messageId));

    return query
        .map((row) => (row.readTable(reactions), row.readTableOrNull(contacts)))
        .watch();
  }
}
