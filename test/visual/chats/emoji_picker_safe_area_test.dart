import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/visual/views/chats/chat_components/chat_body_safe_area.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'picker paints navigation area with $brightness theme and keyboard transitions',
      (tester) async {
        final theme = ThemeData(brightness: brightness);
        Future<void> pump({bool showing = true, bool keyboard = false}) =>
            tester.pumpWidget(
              MaterialApp(
                theme: theme,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: const Size(800, 600),
                    padding: EdgeInsets.only(bottom: keyboard ? 0 : 34),
                    viewPadding: const EdgeInsets.only(bottom: 34),
                    viewInsets: EdgeInsets.only(bottom: keyboard ? 250 : 0),
                  ),
                  child: Scaffold(
                    resizeToAvoidBottomInset: !showing,
                    body: ChatBodySafeArea(
                      showingPicker: showing,
                      child: const SizedBox.expand(key: Key('chatCanvas')),
                    ),
                  ),
                ),
              ),
            );
        await pump();
        final canvas = tester.getRect(find.byKey(const Key('chatCanvas')));
        final backgrounds = find.descendant(
          of: find.byType(ChatBodySafeArea),
          matching: find.byType(ColoredBox),
        );
        expect(
          tester.widget<ColoredBox>(backgrounds.first).color,
          theme.colorScheme.surfaceContainer,
        );
        expect(
          tester.widget<ColoredBox>(backgrounds.last).color,
          theme.scaffoldBackgroundColor,
        );
        expect(tester.getRect(backgrounds.first).bottom - canvas.bottom, 34);
        await pump(keyboard: true);
        expect(
          tester.getRect(find.byKey(const Key('chatCanvas'))).height,
          canvas.height,
        );
        await pump(showing: false);
        expect(
          tester.widget<ColoredBox>(backgrounds.first).color,
          theme.scaffoldBackgroundColor,
        );
      },
    );
  }
}
