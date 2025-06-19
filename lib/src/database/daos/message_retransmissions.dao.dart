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
      Log.error("Error while inserting message for retransmission: $e");
      return null;
    }
  }

  Future<List<int>> getRetransmitAbleMessages() async {
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

  Future updateRetransmission(
    int retransmissionId,
    MessageRetransmissionsCompanion updatedValues,
  ) {
    return (update(messageRetransmissions)
          ..where((c) => c.retransmissionId.equals(retransmissionId)))
        .write(updatedValues);
  }

  Future resetAckStatusForAllMessages() {
    return ((update(messageRetransmissions))
          ..where((m) => m.willNotGetACKByUser.equals(false)))
        .write(
      MessageRetransmissionsCompanion(
        acknowledgeByServerAt: Value(null),
      ),
    );
  }

  Future deleteRetransmissionById(int retransmissionId) {
    return (delete(messageRetransmissions)
          ..where((t) => t.retransmissionId.equals(retransmissionId)))
        .go();
  }

  Future deleteRetransmissionByMessageId(int messageId) {
    return (delete(messageRetransmissions)
          ..where((t) => t.messageId.equals(messageId)))
        .go();
  }
}
