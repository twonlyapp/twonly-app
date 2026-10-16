import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/tables/receipts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';

part 'receipts.dao.g.dart';

@DriftAccessor(
  tables: [Receipts, Messages, MessageActions, ReceivedReceipts, Contacts],
)
class ReceiptsDao extends DatabaseAccessor<TwonlyDB> with _$ReceiptsDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  // ignore: matching_super_parameters
  ReceiptsDao(super.db);
Future<void> deleteReceipt(String receiptId) async {
    await (delete(receipts)..where(
          (t) => t.receiptId.equals(receiptId),
        ))
        .go();
  }

  Future<void> deleteReceiptsByMessageId(String messageId) async {
    await (delete(receipts)..where(
          (t) => t.messageId.equals(messageId),
        ))
        .go();
  }

  Future<void> deleteReceiptForUser(int contactId) async {
    await (delete(receipts)..where(
          (t) => t.contactId.equals(contactId),
        ))
        .go();
  }

  Future<void> purgeReceivedReceipts() async {
    await (delete(receivedReceipts)..where(
          (t) => (t.createdAt.isSmallerThanValue(
            clock.now().subtract(
              const Duration(days: 45),
            ),
          )),
        ))
        .go();

    final deletedContacts = await (select(
      contacts,
    )..where((t) => t.accountDeleted.equals(true))).get();

    for (final contact in deletedContacts) {
      await (delete(receipts)..where(
            (t) => t.contactId.equals(contact.userId),
          ))
          .go();
    }
  }
Future<Receipt?> getReceiptById(String receiptId) async {
    try {
      return await (select(receipts)..where(
            (t) => t.receiptId.equals(receiptId),
          ))
          .getSingleOrNull();
    } catch (e) {
      Log.error(e);
      return null;
    }
  }
Future<List<Receipt>> getReceiptsForMediaRetransmissions() async {
    final markedRetriesTime = clock.now().subtract(
      const Duration(
        // give the server time to transmit all messages to the client
        seconds: 20,
      ),
    );
    return (select(receipts)..where(
          (t) =>
              (t.markForRetry.isSmallerThanValue(markedRetriesTime) |
                  t.markForRetryAfterAccepted.isSmallerThanValue(
                    markedRetriesTime,
                  )) &
              t.willBeRetriedByMediaUpload.equals(true),
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
    await (update(
      receipts,
    )..where((c) => c.receiptId.equals(receiptId))).write(updates);
  }
Future<void> updateReceiptByContactAndMessageId(
    int contactId,
    String messageId,
    ReceiptsCompanion updates,
  ) async {
    await (update(
          receipts,
        )..where(
          (c) => c.contactId.equals(contactId) & c.messageId.equals(messageId),
        ))
        .write(updates);
  }
/// Claims a new delivery-receipt attempt after [cooldown] has elapsed.
  ///
  /// Updating the timestamp before sending prevents repeated server batches from
  /// starting multiple delivery-receipt attempts during the same cooldown.
}
