import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';

@DataClassName('SignalContactSignedPreKey')
class SignalContactSignedPreKeys extends Table {
  IntColumn get contactId =>
      integer().references(Contacts, #userId, onDelete: KeyAction.cascade)();
  IntColumn get signedPreKeyId => integer()();
  BlobColumn get signedPreKey => blob()();
  BlobColumn get signedPreKeySignature => blob()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {contactId};
}
