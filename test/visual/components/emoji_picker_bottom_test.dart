import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/visual/components/emoji_picker.bottom.dart';
import 'package:twonly/src/visual/components/emoji_picker/emoji_picker_internal_utils.dart';
import 'package:twonly/src/visual/themes/light.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EmojiPickerInternalUtils.resetCaches();
  });

  Future<void> openSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.7;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const EmojiPickerBottom(),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  double sheetHeight(WidgetTester tester) =>
      tester.getSize(find.byType(AnimatedContainer).first).height;

  testWidgets('dragging the line up makes the picker taller', (tester) async {
    await openSheet(tester);
    final before = sheetHeight(tester);
    expect(before, 480);

    final line =
        tester.getTopLeft(find.byType(AnimatedContainer).first) +
        const Offset(200, 10);
    await tester.timedDragFrom(
      line,
      const Offset(0, -250),
      const Duration(milliseconds: 800),
    );
    await tester.pumpAndSettle();

    expect(sheetHeight(tester), closeTo(before + 250, 30));
  });

  testWidgets('flicking the line down at the usual height closes it', (
    tester,
  ) async {
    await openSheet(tester);
    final line =
        tester.getTopLeft(find.byType(AnimatedContainer).first) +
        const Offset(200, 10);
    await tester.flingFrom(line, const Offset(0, 200), 1500);
    await tester.pumpAndSettle();

    expect(find.byType(EmojiPickerBottom), findsNothing);
  });
}
