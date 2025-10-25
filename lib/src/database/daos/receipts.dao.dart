import 'package:drift/drift.dart';
import 'package:hashlib/random.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/tables/receipts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';

part 'receipts.dao.g.dart';

@DriftAccessor(tables: [Receipts, Messages, MessageActions])
class ReceiptsDao extends DatabaseAccessor<TwonlyDB> with _$ReceiptsDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  // ignore: matching_super_parameters
  ReceiptsDao(super.db);

  Future<void> confirmReceipt(String receiptId, int fromUserId) async {
    final receipt = await (select(receipts)
          ..where(
            (t) =>
                t.receiptId.equals(receiptId) & t.contactId.equals(fromUserId),
          ))
        .getSingleOrNull();

    if (receipt == null) return;

    if (receipt.messageId != null) {
      await into(messageActions).insert(
        MessageActionsCompanion(
          messageId: Value(receipt.messageId!),
          contactId: Value(fromUserId),
          type: const Value(MessageActionType.ackByUserAt),
        ),
      );
    }

    await (delete(receipts)
          ..where(
            (t) =>
                t.receiptId.equals(receiptId) & t.contactId.equals(fromUserId),
          ))
        .go();
  }

  Future<void> deleteReceipt(String receiptId) async {
    await (delete(receipts)
          ..where(
            (t) => t.receiptId.equals(receiptId),
          ))
        .go();
  }

  Future<Receipt?> insertReceipt(ReceiptsCompanion entry) async {
    try {
      final id = await into(receipts).insert(
        entry.copyWith(
          receiptId: Value(uuid.v4()),
        ),
      );
      return await (select(receipts)..where((t) => t.rowId.equals(id)))
          .getSingle();
    } catch (e) {
      Log.error(e);
      return null;
    }
  }

  Future<Receipt?> getReceiptById(String receiptId) async {
    try {
      return await (select(receipts)
            ..where(
              (t) => t.receiptId.equals(receiptId),
            ))
          .getSingleOrNull();
    } catch (e) {
      Log.error(e);
      return null;
    }
  }

  Future<List<Receipt>> getReceiptsNotAckByServer() async {
    return (select(receipts)
          ..where(
            (t) => t.ackByServerAt.isNull(),
          ))
        .get();
  }

  Stream<List<Receipt>> watchAll() {
    return select(receipts).watch();
  }

  Future<void> updateReceipt(
    String receiptId,
    ReceiptsCompanion updates,
  ) async {
    await (update(receipts)..where((c) => c.receiptId.equals(receiptId)))
        .write(updates);
  }
}
