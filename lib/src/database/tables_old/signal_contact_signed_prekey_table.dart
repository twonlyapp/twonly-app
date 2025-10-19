import 'package:drift/drift.dart';

@DataClassName('SignalContactSignedPreKey')
class SignalContactSignedPreKeys extends Table {
  IntColumn get contactId => integer()();
  IntColumn get signedPreKeyId => integer()();
  BlobColumn get signedPreKey => blob()();
  BlobColumn get signedPreKeySignature => blob()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {contactId};
}
