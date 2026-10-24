import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/visual/components/mention_decoration.dart';
import 'package:twonly/src/visual/components/mention_editing_controller.dart';
import 'package:twonly/src/visual/components/mention_style.dart';
import 'package:twonly/src/visual/elements/better_text.element.dart';
import 'package:twonly/src/visual/themes/colors.dart';

void main() {
  testWidgets('message and composer backgrounds update when switching themes', (
    tester,
  ) async {
    final mode = ValueNotifier(ThemeMode.light);
    final controller = MentionEditingController()
      ..loadMessage('@[user:42]', (_) => 'Alice');
    addTearDown(mode.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: mode,
        builder: (context, value, child) => MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: value,
          home: Scaffold(
            body: Column(
              children: [
                const MentionBackground(
                  selections: [TextSelection(baseOffset: 0, extentOffset: 6)],
                  child: Text('@Alice'),
                ),
                MentionInputBackground(
                  controller: controller,
                  child: TextField(controller: controller),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    for (final (theme, opacity) in [
      (ThemeMode.light, 0.1),
      (ThemeMode.dark, 0.3),
      (ThemeMode.light, 0.1),
    ]) {
      mode.value = theme;
      await tester.pumpAndSettle();
      final color = Colors.black.withValues(alpha: opacity);
      expect(
        tester.renderObject(find.byType(MentionBackground)),
        paints..rrect(color: color),
      );
      final editable = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      expect(editable, paints..rrect(color: color));
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'mention colors follow sent and received bubble colors and theme updates',
    (tester) async {
      final color = ValueNotifier(AppColor.onChatBubbleSent.light);
      addTearDown(color.dispose);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ValueListenableBuilder<Color>(
              valueListenable: color,
              builder: (context, value, child) => BetterText(
                text: 'Hi @[user:42]!',
                textColor: value,
                contactsById: const {},
              ),
            ),
          ),
        ),
      );
      for (final textColor in [
        AppColor.onChatBubbleSent.light,
        AppColor.onChatBubbleReceived.light,
        AppColor.onChatBubbleSent.dark,
        AppColor.onChatBubbleReceived.dark,
      ]) {
        color.value = textColor;
        await tester.pump();
        final richText = tester.widget<RichText>(
          find.descendant(
            of: find.byType(BetterText),
            matching: find.byType(RichText),
          ),
        );
        final runs = <String, Color?>{};
        void visit(TextSpan span, TextStyle parent) {
          final style = parent.merge(span.style);
          if (span.text != null) runs[span.text!] = style.color;
          for (final child in span.children ?? <InlineSpan>[]) {
            if (child is TextSpan) visit(child, style);
          }
        }

        visit(richText.text as TextSpan, const TextStyle());
        expect(runs['Hi '], textColor);
        expect(runs['@Unknown user'], runs['Hi ']);
      }
      final reassemble = tester.binding.reassembleApplication();
      await tester.pump();
      await reassemble;
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final direction in TextDirection.values) {
    testWidgets('mention backgrounds follow wrapped, scaled $direction text', (
      tester,
    ) async {
      const prefix = 'Hello ';
      const name = '@صديقي Alice Smith';
      const selection = TextSelection(
        baseOffset: prefix.length,
        extentOffset: prefix.length + name.length,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 120,
                child: MentionBackground(
                  selections: const [selection],
                  child: Text.rich(
                    const TextSpan(
                      children: [
                        TextSpan(text: prefix),
                        TextSpan(text: name, style: mentionTextStyle),
                        TextSpan(text: '!'),
                      ],
                    ),
                    style: const TextStyle(fontSize: 17),
                    textDirection: direction,
                    textScaler: const TextScaler.linear(1.5),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText).last,
      );
      final boxes = paragraph.getBoxesForSelection(selection);
      expect(boxes.length, greaterThan(1));
      final matcher = paints;
      for (final box in boxes) {
        final background = RRect.fromRectAndRadius(
          box.toRect().inflate(1),
          const Radius.circular(4),
        );
        matcher.rrect(
          rrect: background,
          color: Colors.black.withValues(alpha: 0.1),
        );
      }
      expect(tester.renderObject(find.byType(MentionBackground)), matcher);
      expect(paragraph.text.toPlainText(), '$prefix$name!');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'editable backgrounds preserve offsets, composing text and deletion',
    (tester) async {
      final controller = MentionEditingController()
        ..loadMessage('Hi @[user:42] ', (_) => 'Alice');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MentionInputBackground(
              controller: controller,
              child: TextField(
                controller: controller,
                maxLines: 2,
                decoration: const InputDecoration(filled: true),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final editable = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      expect(editable.painter, isNotNull);
      expect(editable.text!.toPlainText(), 'Hi @Alice ');
      expect(
        controller.mentionSelections.single,
        const TextSelection(baseOffset: 3, extentOffset: 9),
      );
      expect(
        editable,
        paints..rrect(color: Colors.black.withValues(alpha: 0.1)),
      );
      controller.value = const TextEditingValue(
        text: 'Hi @Alice world',
        selection: TextSelection.collapsed(offset: 15),
        composing: TextRange(start: 10, end: 15),
      );
      await tester.pump();
      expect(editable.text!.toPlainText(), controller.text);
      expect(controller.messageText, 'Hi @[user:42] world');
      controller.value = const TextEditingValue(
        text: 'Hi @Alic world',
        selection: TextSelection.collapsed(offset: 8),
      );
      await tester.pump();
      expect(controller.text, 'Hi  world');
      expect(controller.mentionSelections, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
