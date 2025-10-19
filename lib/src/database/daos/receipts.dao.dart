import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/tables/receipts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';

part 'receipts.dao.g.dart';

@DriftAccessor(tables: [Receipts, Messages])
class ReceiptsDao extends DatabaseAccessor<TwonlyDB> with _$ReceiptsDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  // ignore: matching_super_parameters
  ReceiptsDao(super.db);

  Future<void> confirmReceipt(String receiptId, int fromUserId) async {
    final receipt = await (select(receipts)
          ..where((t) =>
              t.receiptId.equals(receiptId) & t.contactId.equals(fromUserId)))
        .getSingleOrNull();

    if (receipt == null) return;

    if (receipt.messageId != null) {
      await (update(messages)
            ..where((t) => t.messageId.equals(receipt.messageId!)))
          .write(
        const MessagesCompanion(
          acknowledgeByUser: Value(true),
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

  Future<Receipt?> insertReceipt(ReceiptsCompanion entry) async {
    try {
      final id = await into(receipts).insert(entry);
      return await (select(receipts)..where((t) => t.rowId.equals(id)))
          .getSingle();
    } catch (e) {
      Log.error(e);
      return null;
    }
  }
}
