import 'package:drift/drift.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/reactions.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';

part 'reactions.dao.g.dart';

@DriftAccessor(tables: [Reactions])
class ReactionsDao extends DatabaseAccessor<TwonlyDB> with _$ReactionsDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  // ignore: matching_super_parameters
  ReactionsDao(super.db);

  Future<void> updateReaction(
    int contactId,
    String messageId,
    String groupId,
    String? emoji,
  ) async {
    final msg =
        await twonlyDB.messagesDao.getMessageById(messageId).getSingleOrNull();
    if (msg == null || msg.groupId != groupId) return;

    try {
      await (delete(reactions)
            ..where(
              (t) =>
                  t.senderId.equals(contactId) & t.messageId.equals(messageId),
            ))
          .go();
      if (emoji != null) {
        await into(reactions).insert(ReactionsCompanion(
          messageId: Value(messageId),
          emoji: Value(emoji),
          senderId: Value(contactId),
        ));
      }
    } catch (e) {
      Log.error(e);
    }
  }
}
