import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/visual/components/contact_groups.comp.dart';

void main() {
  testWidgets(
    'a contact group without a background has no decoration or padding',
    (tester) async {
      final contactGroup = ContactGroup(
        id: 1,
        name: '😀',
        textColor: Colors.black.toARGB32(),
        backgroundColor: 0x00123456,
        showAsShortcut: true,
        showAsLabel: true,
        usageCounter: 0,
        createdAt: DateTime(2026),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContactGroupBadges(
              userId: 1,
              contactGroups: [contactGroup],
              padding: const EdgeInsets.all(10),
            ),
          ),
        ),
      );

      final badgeContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(ContactGroupBadges),
          matching: find.byType(Container),
        ),
      );

      expect(badgeContainer.decoration, isNull);
      expect(badgeContainer.padding, EdgeInsets.zero);
      expect(tester.widget<Text>(find.text('😀')).style?.fontSize, 12);
    },
  );
}
