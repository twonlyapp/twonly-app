import 'package:drift/drift.dart';

@DataClassName('SignalContactPreKey')
class SignalContactPreKeys extends Table {
  IntColumn get contactId => integer()();
  IntColumn get preKeyId => integer()();
  BlobColumn get preKey => blob()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {contactId, preKeyId};
}
