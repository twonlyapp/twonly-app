import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/labels.table.dart';
import 'package:twonly/src/database/twonly.db.dart';

part 'labels.dao.g.dart';

@DriftAccessor(
  tables: [
    Labels,
    ContactLabels,
  ],
)
class LabelsDao extends DatabaseAccessor<TwonlyDB> with _$LabelsDaoMixin {
  LabelsDao(super.db);

  Stream<List<Label>> watchAllLabels() {
    return (select(labels)..orderBy([(t) => OrderingTerm(expression: t.name)])).watch();
  }

  Future<List<Label>> getAllLabels() {
    return (select(labels)..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
  }

  Stream<List<Label>> watchContactLabels(int contactId) {
    final query = select(contactLabels).join([
      innerJoin(labels, labels.id.equalsExp(contactLabels.labelId)),
    ])..where(contactLabels.contactId.equals(contactId));

    return query.watch().map(
          (rows) => rows.map((row) => row.readTable(labels)).toList(),
        );
  }

  Future<List<Label>> getContactLabels(int contactId) {
    final query = select(contactLabels).join([
      innerJoin(labels, labels.id.equalsExp(contactLabels.labelId)),
    ])..where(contactLabels.contactId.equals(contactId));

    return query.get().then(
          (rows) => rows.map((row) => row.readTable(labels)).toList(),
        );
  }

  Future<void> setContactLabels(int contactId, List<int> labelIds) async {
    final sanitizedLabelIds = labelIds.take(3).toList();
    await transaction(() async {
      await (delete(contactLabels)..where((t) => t.contactId.equals(contactId))).go();
      if (sanitizedLabelIds.isNotEmpty) {
        await batch((b) {
          b.insertAll(
            contactLabels,
            sanitizedLabelIds.map(
              (lId) => ContactLabelsCompanion.insert(
                contactId: contactId,
                labelId: lId,
              ),
            ),
          );
        });
      }
    });
  }

  Future<int> createLabel(String name, int textColor, int backgroundColor) {
    final sanitizedName = name.length > 8 ? name.substring(0, 8) : name;
    return into(labels).insert(
      LabelsCompanion.insert(
        name: sanitizedName,
        textColor: textColor,
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<bool> updateLabel(int id, String name, int textColor, int backgroundColor) {
    final sanitizedName = name.length > 8 ? name.substring(0, 8) : name;
    return (update(labels)..where((t) => t.id.equals(id)))
        .write(
          LabelsCompanion(
            name: Value(sanitizedName),
            textColor: Value(textColor),
            backgroundColor: Value(backgroundColor),
          ),
        )
        .then((rows) => rows > 0);
  }

  Future<int> deleteLabel(int id) {
    return (delete(labels)..where((t) => t.id.equals(id))).go();
  }
}
