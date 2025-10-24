import 'package:drift/drift.dart';

class Contacts extends Table {
  IntColumn get userId => integer()();

  TextColumn get username => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get nickName => text().nullable()();
  TextColumn get avatarSvg => text().nullable()();

  IntColumn get senderProfileCounter =>
      integer().withDefault(const Constant(0))();

  BoolColumn get accepted => boolean().withDefault(const Constant(false))();
  BoolColumn get requested => boolean().withDefault(const Constant(false))();
  BoolColumn get blocked => boolean().withDefault(const Constant(false))();
  BoolColumn get verified => boolean().withDefault(const Constant(false))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId};
}
