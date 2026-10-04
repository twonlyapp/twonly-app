/*
 * Modified version of https://github.com/Fintasys/emoji_picker_flutter
 * MIT License
 * Copyright (c) 2024 Stefan Humm
 */

import 'package:twonly/src/visual/components/emoji_picker/emoji_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmojiTextEditingController', () {
    testWidgets('should apply emojiTextStyle to emojis', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final emojiStyle = const TextStyle(color: Colors.red);
            final regularStyle = const TextStyle(color: Colors.black);
            final controller = EmojiTextEditingController(
              text: 'Hello 👋 World',
              emojiTextStyle: emojiStyle,
            );

            final span = controller.buildTextSpan(
              context: context,
              style: regularStyle,
              withComposing: false,
            );

            expect(span.children?.length, 3);
            // Hello
            expect(span.children?[0].style?.color, Colors.black);
            // Emoji
            expect(span.children?[1].style?.color, Colors.red);
            expect(
              span.children?[1].style?.fontFamilyFallback,
              DefaultEmojiTextStyle.fontFamilyFallback,
            );
            // World
            expect(span.children?[2].style?.color, Colors.black);

            return const Placeholder();
          },
        ),
      );
    });
  });
}
