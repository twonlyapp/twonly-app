import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/visual/components/release_notes.comp.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

const _releaseNotes = ReleaseNotesData(
  version: '1.2.3',
  title: "What's new",
  introduction: 'A short introduction.',
  additionalChangesTitle: 'Also improved',
  closeLabel: 'Close',
  features: [
    ReleaseNoteFeature(
      icon: Icon(Icons.star_rounded),
      title: 'First feature',
      description: 'A short feature description.',
    ),
  ],
  additionalChanges: ['One more improvement'],
);

void main() {
  testWidgets('shows generic release notes at 80 percent height', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showReleaseNotesBottomSheet(
              context,
              _releaseNotes,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('v1.2.3'), findsOneWidget);
    expect(find.text("What's new"), findsOneWidget);
    expect(find.text('First feature'), findsOneWidget);
    expect(find.text('One more improvement'), findsOneWidget);
    expect(find.byType(MyButton), findsOneWidget);

    final sheet = find.byType(ReleaseNotesBottomSheet);
    final mediaSize = MediaQuery.sizeOf(tester.element(sheet));
    expect(tester.getSize(sheet).height, closeTo(mediaSize.height * 0.8, 0.1));

    await tester.tap(find.byType(MyButton));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
  });
}
