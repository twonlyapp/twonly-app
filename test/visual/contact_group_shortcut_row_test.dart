import 'dart:collection';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/visual/elements/my_chip.element.dart';
import 'package:twonly/src/visual/views/camera/share_image_contact_selection_components/contact_group_shortcut_row.comp.dart';
import 'package:twonly/src/visual/views/camera/share_image_contact_selection_components/first_seen_order.dart';

class _LightSettings extends SettingsChangeProvider {
  @override
  ThemeMode get themeMode => ThemeMode.light;
}

ContactGroup contactGroup(int id) => ContactGroup(
  id: id,
  name: 'group $id',
  textColor: 0,
  backgroundColor: 0,
  showAsShortcut: true,
  showAsLabel: true,
  shareStories: false,
  usageCounter: 0,
  createdAt: DateTime(2026),
);

void main() {
  group('inFirstSeenOrder', () {
    test('keeps the first order, drops what is gone, appends what is new', () {
      final seen = <int>[];
      List<int> ids(List<ContactGroup> groups) =>
          inFirstSeenOrder(groups, seen).map((g) => g.id).toList();

      expect(ids([contactGroup(1), contactGroup(2), contactGroup(3)]), [
        1,
        2,
        3,
      ]);
      // Group 3 got used the most and now arrives first.
      expect(ids([contactGroup(3), contactGroup(1), contactGroup(2)]), [
        1,
        2,
        3,
      ]);
      expect(ids([contactGroup(4), contactGroup(3), contactGroup(1)]), [
        1,
        3,
        4,
      ]);
    });
  });

  group('ContactGroupShortcutRow', () {
    late TwonlyDB database;

    setUp(() async {
      await locator.reset();
      database = TwonlyDB.forTesting(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      locator.registerSingleton<TwonlyDB>(database);
      await database.customStatement(
        "INSERT INTO groups(group_id, group_name) VALUES ('a1', 'A1'), "
        "('a2', 'A2'), ('b1', 'B1')",
      );
      // A is used more, so it comes first.
      await database.customStatement(
        'INSERT INTO contact_groups(id, name, emoji, text_color, '
        'background_color, show_as_shortcut, usage_counter) VALUES '
        "(1, 'A', '🅰', 0, 0, 1, 1), (2, 'B', '🅱', 0, 0, 1, 0)",
      );
      await database.customStatement(
        'INSERT INTO contact_group_members(contact_group_id, group_id) VALUES '
        "(1, 'a1'), (1, 'a2'), (2, 'b1')",
      );
    });

    tearDown(() => database.close());

    Future<HashSet<String>> pump(
      WidgetTester tester, {
      Set<String> selected = const {},
    }) async {
      final selectedGroupIds = HashSet<String>.of(selected);
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsChangeProvider>(
          create: (_) => _LightSettings(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => ContactGroupShortcutRow(
                  selectedGroupIds: selectedGroupIds,
                  updateSelectedGroupIds: (groupId, checked) => setState(() {
                    if (checked) {
                      selectedGroupIds.add(groupId);
                    } else {
                      selectedGroupIds.remove(groupId);
                    }
                  }),
                ),
              ),
            ),
          ),
        ),
      );
      await settle(tester);
      return selectedGroupIds;
    }

    MyChip chip(WidgetTester tester, String label) => tester.widget<MyChip>(
      find.ancestor(of: find.text(label), matching: find.byType(MyChip)),
    );

    testWidgets('a shortcut is on only while all its chats are selected', (
      tester,
    ) async {
      await pump(tester, selected: {'a1'});
      expect(chip(tester, '🅰').selected, isFalse);

      await pump(tester, selected: {'a1', 'a2', 'b1'});
      expect(chip(tester, '🅰').selected, isTrue);
      expect(chip(tester, '🅱').selected, isTrue);
    });

    testWidgets('tapping selects its chats, tapping again clears them', (
      tester,
    ) async {
      final selected = await pump(tester, selected: {'b1'});

      await tester.tap(find.text('🅰'));
      await settle(tester);
      expect(selected, {'a1', 'a2'});
      expect(chip(tester, '🅰').selected, isTrue);

      await tester.tap(find.text('🅰'));
      await settle(tester);
      expect(selected, isEmpty);
      expect(chip(tester, '🅰').selected, isFalse);
    });

    testWidgets('a chip stays in place when using it makes it the most used', (
      tester,
    ) async {
      await pump(tester);
      double left(String label) => tester.getTopLeft(find.text(label)).dx;
      expect(left('🅰'), lessThan(left('🅱')));

      await tester.tap(find.text('🅱'));
      await settle(tester);
      await tester.tap(find.text('🅱'));
      await settle(tester);
      await tester.tap(find.text('🅱'));
      await settle(tester);

      final counters = await tester.runAsync(
        () => database
            .customSelect(
              'SELECT usage_counter FROM contact_groups WHERE id = 2',
            )
            .getSingle(),
      );
      expect(counters!.read<int>('usage_counter'), 2);
      expect(left('🅰'), lessThan(left('🅱')));
    });
  });
}

/// Lets the database answer, which only happens outside fake time.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }
}
