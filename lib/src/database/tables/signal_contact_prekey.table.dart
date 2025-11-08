import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';

@DataClassName('SignalContactPreKey')
class SignalContactPreKeys extends Table {
  IntColumn get contactId =>
      integer().references(Contacts, #userId, onDelete: KeyAction.cascade)();
  IntColumn get preKeyId => integer()();
  BlobColumn get preKey => blob()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {contactId, preKeyId};
}
