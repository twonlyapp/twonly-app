import 'package:drift/drift.dart';

@DataClassName('LocalSticker')
class Stickers extends Table {
  TextColumn get contentHash => text().withLength(min: 64, max: 64)();
  BlobColumn get webp => blob()();
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  IntColumn get usageCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastUsedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {contentHash};
}
