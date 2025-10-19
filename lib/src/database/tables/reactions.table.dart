import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';

@DataClassName('Reaction')
class Reactions extends Table {
  TextColumn get messageId =>
      text().references(Messages, #messageId, onDelete: KeyAction.cascade)();

  TextColumn get emoji => text()();

  // in case senderId is null, it was send by user itself
  IntColumn get senderId => integer()
      .nullable()
      .references(Contacts, #userId, onDelete: KeyAction.cascade)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {messageId, senderId, createdAt};
}
