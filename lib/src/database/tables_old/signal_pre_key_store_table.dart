import 'package:drift/drift.dart';

@DataClassName('SignalPreKeyStore')
class SignalPreKeyStores extends Table {
  IntColumn get preKeyId => integer()();
  BlobColumn get preKey => blob()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {preKeyId};
}
