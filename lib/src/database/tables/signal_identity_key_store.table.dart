import 'package:drift/drift.dart';

@DataClassName('SignalIdentityKeyStore')
class SignalIdentityKeyStores extends Table {
  IntColumn get deviceId => integer()();
  TextColumn get name => text()();
  BlobColumn get identityKey => blob()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {deviceId, name};
}
