import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/database/twonly.db.dart';

void main() {
  late TwonlyDB db;

  setUp(() async {
    db = TwonlyDB.forTesting(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );

    for (final contactId in [10, 11, 12]) {
      await db.contactsDao.insertContact(
        ContactsCompanion.insert(
          userId: Value(contactId),
          username: 'contact-$contactId',
        ),
      );
    }
  });

  tearDown(() => db.close());

  Future<void> addReceipt(
    int contactId,
    int retryCount, {
    bool mediaUpload = false,
  }) async {
    await db.receiptsDao.insertReceipt(
      ReceiptsCompanion(
        contactId: Value(contactId),
        message: Value(Uint8List.fromList([contactId])),
        retryCount: Value(retryCount),
        willBeRetriedByMediaUpload: Value(mediaUpload),
      ),
    );
  }

  test(
    'detects multiple message retries above the ratchet threshold',
    () async {
      await addReceipt(10, 21);
      await addReceipt(10, 30);
      await addReceipt(11, 21);
      await addReceipt(11, 20);
      await addReceipt(12, 25, mediaUpload: true);
      await addReceipt(12, 25, mediaUpload: true);

      final contactIds = await db.receiptsDao
          .getContactsWithStuckSignalMessages(
            retryThreshold: 20,
          );

      expect(contactIds, [10]);
    },
  );

  test('clears message counters after a successful session reset', () async {
    await addReceipt(10, 21);
    await addReceipt(10, 30);
    await addReceipt(10, 25, mediaUpload: true);

    await db.receiptsDao.resetMessageRetryCountsForContact(10);

    final receipts = await (db.select(
      db.receipts,
    )..where((receipt) => receipt.contactId.equals(10))).get();
    final messageReceipts = receipts.where(
      (receipt) => !receipt.willBeRetriedByMediaUpload,
    );
    final mediaReceipt = receipts.singleWhere(
      (receipt) => receipt.willBeRetriedByMediaUpload,
    );

    expect(
      messageReceipts.map((receipt) => receipt.retryCount),
      everyElement(0),
    );
    expect(mediaReceipt.retryCount, 25);
  });
}
