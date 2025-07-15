import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/message_retransmissions.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/log.dart';

part 'message_retransmissions.dao.g.dart';

@DriftAccessor(tables: [MessageRetransmissions])
class MessageRetransmissionDao extends DatabaseAccessor<TwonlyDatabase>
    with _$MessageRetransmissionDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  MessageRetransmissionDao(super.db);

  Future<int?> insertRetransmission(
      MessageRetransmissionsCompanion message) async {
    try {
      return await into(messageRetransmissions).insert(message);
    } catch (e) {
      Log.error('Error while inserting message for retransmission: $e');
      return null;
    }
  }

  Future<List<int>> getRetransmitAbleMessages() async {
    final countDeleted = await (delete(messageRetransmissions)
          ..where((t) =>
              t.encryptedHash.isNull() & t.acknowledgeByServerAt.isNotNull()))
        .go();

    if (countDeleted > 0) {
      Log.info('Deleted $countDeleted faulty retransmissions');
    }

    return (await (select(messageRetransmissions)
              ..where((t) => t.acknowledgeByServerAt.isNull()))
            .get())
        .map((msg) => msg.retransmissionId)
        .toList();
  }

  SingleOrNullSelectable<MessageRetransmission> getRetransmissionById(
      int retransmissionId) {
    return select(messageRetransmissions)
      ..where((t) => t.retransmissionId.equals(retransmissionId));
  }

  Future<void> updateRetransmission(
    int retransmissionId,
    MessageRetransmissionsCompanion updatedValues,
  ) {
    return (update(messageRetransmissions)
          ..where((c) => c.retransmissionId.equals(retransmissionId)))
        .write(updatedValues);
  }

  Future<int> resetAckStatusFor(int fromUserId, Uint8List encryptedHash) async {
    return ((update(messageRetransmissions))
          ..where((m) =>
              m.contactId.equals(fromUserId) &
              m.encryptedHash.equals(encryptedHash)))
        .write(
      const MessageRetransmissionsCompanion(
        acknowledgeByServerAt: Value(null),
      ),
    );
  }

  Future<MessageRetransmission?> getRetransmissionFromHash(
      int fromUserId, Uint8List encryptedHash) async {
    return ((select(messageRetransmissions))
          ..where((m) =>
              m.contactId.equals(fromUserId) &
              m.encryptedHash.equals(encryptedHash)))
        .getSingleOrNull();
  }

  Future<void> deleteRetransmissionById(int retransmissionId) {
    return (delete(messageRetransmissions)
          ..where((t) => t.retransmissionId.equals(retransmissionId)))
        .go();
  }

  Future<void> deleteRetransmissionByMessageId(int messageId) {
    return (delete(messageRetransmissions)
          ..where((t) => t.messageId.equals(messageId)))
        .go();
  }
}
