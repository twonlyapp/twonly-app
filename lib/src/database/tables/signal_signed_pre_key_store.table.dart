import 'package:drift/drift.dart';

@DataClassName('SignalSignedPreKeyStore')
class SignalSignedPreKeyStores extends Table {
  IntColumn get signedPreKeyId => integer()();
  BlobColumn get signedPreKey => blob()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {signedPreKeyId};
}
