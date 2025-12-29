import 'package:drift/drift.dart';
import 'package:hashlib/random.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/tables/receipts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';

part 'receipts.dao.g.dart';

@DriftAccessor(tables: [Receipts, Messages, MessageActions, ReceivedReceipts])
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
      var insertEntry = entry;
      if (entry.receiptId == const Value.absent()) {
        insertEntry = entry.copyWith(
          receiptId: Value(uuid.v4()),
        );
      }
      final id = await into(receipts).insert(insertEntry);
      return await (select(receipts)..where((t) => t.rowId.equals(id)))
          .getSingle();
    } catch (e) {
      // ignore error, receipts is already in the database...
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

  Future<List<Receipt>> getReceiptsForRetransmission() async {
    final markedRetriesTime = DateTime.now().subtract(
      const Duration(
        // give the server time to transmit all messages to the client
        seconds: 20,
      ),
    );
    return (select(receipts)
          ..where(
            (t) =>
                t.ackByServerAt.isNull() |
                t.markForRetry.isSmallerThanValue(markedRetriesTime),
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

  Future<void> markMessagesForRetry(int contactId) async {
    await (update(receipts)..where((c) => c.contactId.equals(contactId))).write(
      ReceiptsCompanion(
        markForRetry: Value(DateTime.now()),
      ),
    );
  }

  Future<bool> isDuplicated(String receiptId) async {
    return await (select(receivedReceipts)
              ..where((t) => t.receiptId.equals(receiptId)))
            .getSingleOrNull() !=
        null;
  }

  Future<void> gotReceipt(String receiptId) async {
    await into(receivedReceipts)
        .insert(ReceivedReceiptsCompanion(receiptId: Value(receiptId)));
  }
}
