import 'package:drift/drift.dart';

@DataClassName('SignalSenderKeyStore')
class SignalSenderKeyStores extends Table {
  TextColumn get senderKeyName => text()();
  BlobColumn get senderKey => blob()();

  @override
  Set<Column> get primaryKey => {senderKeyName};
}
