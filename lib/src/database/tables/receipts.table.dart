import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';

@DataClassName('Receipt')
class Receipts extends Table {
  TextColumn get receiptId => text()();

  IntColumn get contactId =>
      integer().references(Contacts, #userId, onDelete: KeyAction.cascade)();

  // in case a message is deleted, it should be also deleted from the receipts table
  TextColumn get messageId => text()
      .nullable()
      .references(Messages, #messageId, onDelete: KeyAction.cascade)();

  /// This is the protobuf 'Message'
  BlobColumn get message => blob()();

  BoolColumn get contactWillSendsReceipt =>
      boolean().withDefault(const Constant(true))();

  DateTimeColumn get ackByServerAt => dateTime().nullable()();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastRetry => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {receiptId};
}
