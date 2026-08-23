import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/visual/elements/better_text.element.dart';

void main() {
  testWidgets('BetterText parses URLs correctly', (tester) async {
    const text =
        'Test: (https://google.com) and another link https://example.com/#fragment, plus www.test.com. Also check https://wikipedia.org/wiki/Test_(disambiguation) !';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BetterText(
            text: text,
            textColor: Colors.black,
          ),
        ),
      ),
    );

    final richTextFinder = find.byType(RichText);
    expect(richTextFinder, findsWidgets);

    final richTexts = tester.widgetList<RichText>(richTextFinder);
    final parsedTexts = <String>[];

    void extractTexts(InlineSpan span) {
      if (span is TextSpan) {
        if (span.text != null) parsedTexts.add(span.text!);
        if (span.children != null) {
          span.children!.forEach(extractTexts);
        }
      }
    }

    for (final richText in richTexts) {
      extractTexts(richText.text);
    }

    // BetterText creates one span for text, one for link, etc.
    // The URLs will be parsed as individual TextSpans inside the top-level TextSpan.
    expect(
      parsedTexts.contains('https://google.com'),
      isTrue,
      reason: 'Parenthesis should not be in the URL',
    );
    expect(
      parsedTexts.contains('https://example.com/#fragment'),
      isTrue,
      reason: 'Hashtag/fragment should be in the URL',
    );
    expect(
      parsedTexts.contains('www.test.com'),
      isTrue,
      reason: 'Trailing period should not be in the URL',
    );
    expect(
      parsedTexts.contains('https://wikipedia.org/wiki/Test_(disambiguation)'),
      isTrue,
      reason: 'Should parse URLs with parentheses correctly',
    );
  });
}
