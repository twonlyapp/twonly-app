import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';

@DataClassName('Label')
class Labels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get textColor => integer()();
  IntColumn get backgroundColor => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ContactLabel')
class ContactLabels extends Table {
  IntColumn get contactId => integer().references(
        Contacts,
        #userId,
        onDelete: KeyAction.cascade,
      )();
  IntColumn get labelId => integer().references(
        Labels,
        #id,
        onDelete: KeyAction.cascade,
      )();

  @override
  Set<Column> get primaryKey => {contactId, labelId};
}
