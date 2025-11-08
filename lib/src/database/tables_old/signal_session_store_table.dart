import 'package:drift/drift.dart';

@DataClassName('SignalSessionStore')
class SignalSessionStores extends Table {
  IntColumn get deviceId => integer()();
  TextColumn get name => text()();
  BlobColumn get sessionRecord => blob()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {deviceId, name};
}
