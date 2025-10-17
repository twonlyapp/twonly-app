import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts_table.dart';
import 'package:twonly/src/database/tables/messages_table.dart';

@DataClassName('MessageRetransmission')
class MessageRetransmissions extends Table {
  IntColumn get retransmissionId => integer().autoIncrement()();
  IntColumn get contactId =>
      integer().references(Contacts, #userId, onDelete: KeyAction.cascade)();

  IntColumn get messageId => integer()
      .nullable()
      .references(Messages, #messageId, onDelete: KeyAction.cascade)();

  BlobColumn get plaintextContent => blob()();
  BlobColumn get pushData => blob().nullable()();
  BlobColumn get encryptedHash => blob().nullable()();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastRetry => dateTime().nullable()();

  DateTimeColumn get acknowledgeByServerAt => dateTime().nullable()();
}
