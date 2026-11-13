import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/visual/components/chat_deletion_time_sheet.comp.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_chip.element.dart';
import 'package:twonly/src/visual/themes/dark.dart';
import 'package:twonly/src/visual/themes/light.dart';

void main() {
  for (final (locale, size, scale, dark) in [
    ('en', const Size(390, 844), 1.0, false),
    ('de', const Size(390, 844), 1.0, true),
    ('ar', const Size(390, 844), 1.0, false),
    ('en', const Size(320, 640), 1.5, false),
  ]) {
    testWidgets('custom sheet fits $locale at $size with text scale $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);
      int? result;
      late AppLocalizations lang;

      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? darkTheme : lightTheme,
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: child!,
          ),
          home: Builder(
            builder: (context) {
              lang = AppLocalizations.of(context)!;
              return Scaffold(
                body: MyButton(
                  onPressed: () async {
                    result = await showModalBottomSheet<int>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      showDragHandle: true,
                      builder: (_) => ChatDeletionTimeSheet(
                        initialMilliseconds: const Duration(
                          minutes: 90,
                        ).inMilliseconds,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byType(MyButton));
      await tester.pumpAndSettle();
      expect(find.byType(ChatDeletionTimeSheet), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '120');
      await tester.pumpAndSettle();
      final save = find.ancestor(
        of: find.text(lang.save),
        matching: find.byType(MyButton),
      );
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // The editor stays in the same sheet, including its unit selection.
      expect(
        tester
            .widget<MyChip>(
              find.ancestor(
                of: find.text(lang.chatDeletionUnitHours),
                matching: find.byType(MyChip),
              ),
            )
            .selected,
        isTrue,
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(result, const Duration(hours: 120).inMilliseconds);
      expect(find.byType(ChatDeletionTimeSheet), findsNothing);
    });
  }
}
