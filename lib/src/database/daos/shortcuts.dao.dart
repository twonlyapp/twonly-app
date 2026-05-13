import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/shortcuts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';

part 'shortcuts.dao.g.dart';

@DriftAccessor(
  tables: [
    Shortcuts,
    ShortcutMembers,
  ],
)
class ShortcutsDao extends DatabaseAccessor<TwonlyDB> with _$ShortcutsDaoMixin {
  ShortcutsDao(super.db);

  Stream<List<Shortcut>> watchAllShortcuts() {
    return (select(shortcuts)..orderBy([
          (t) =>
              OrderingTerm(expression: t.usageCounter, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Future<Shortcut?> getShortcutByEmoji(String emoji) {
    return (select(
      shortcuts,
    )..where((t) => t.emoji.equals(emoji))).getSingleOrNull();
  }

  Future<void> createShortcut(String emoji) async {
    try {
      await into(shortcuts).insert(
        ShortcutsCompanion.insert(emoji: emoji),
      );
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> addShortcutMembers(int shortcutId, List<String> groupIds) async {
    await batch((b) {
      b.insertAll(
        shortcutMembers,
        groupIds.map(
          (gId) => ShortcutMembersCompanion.insert(
            shortcutId: shortcutId,
            groupId: gId,
          ),
        ),
      );
    });
  }

  Future<List<ShortcutMember>> getShortcutMembers(int shortcutId) {
    return (select(
      shortcutMembers,
    )..where((t) => t.shortcutId.equals(shortcutId))).get();
  }

  Future<void> incrementUsage(int shortcutId) async {
    await customStatement(
      'UPDATE shortcuts SET usage_counter = usage_counter + 1 WHERE id = ?',
      [shortcutId],
    );
    // Notify updates to trigger streams
    notifyUpdates({TableUpdate.onTable(shortcuts, kind: UpdateKind.update)});
  }

  Future<void> updateShortcut(int shortcutId, String emoji) async {
    await (update(shortcuts)..where((t) => t.id.equals(shortcutId))).write(
      ShortcutsCompanion(emoji: Value(emoji)),
    );
  }

  Future<void> deleteShortcutMembers(int shortcutId) async {
    await (delete(
      shortcutMembers,
    )..where((t) => t.shortcutId.equals(shortcutId))).go();
  }

  Future<void> deleteShortcut(int shortcutId) async {
    await (delete(shortcuts)..where((t) => t.id.equals(shortcutId))).go();
  }
}
