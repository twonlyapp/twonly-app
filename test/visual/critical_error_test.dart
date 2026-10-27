import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/critical_error.view.dart';

void main() {
  testWidgets('new registration requires confirmation and can be cancelled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CriticalErrorView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final register = find.text('Register New Account');
    Finder button(Finder label) =>
        find.ancestor(of: label, matching: find.byType(MyButton));
    await tester.scrollUntilVisible(register, 200);
    await tester.tap(button(register));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.textContaining('delete all local account data'),
      findsOneWidget,
    );

    await tester.tap(button(find.text('Cancel')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(register, findsOneWidget);

    // Dismissing the dialog also leaves the account untouched.
    await tester.tap(button(register));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(AlertDialog))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
