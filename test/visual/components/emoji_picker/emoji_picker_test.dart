/*
 * Modified version of https://github.com/Fintasys/emoji_picker_flutter
 * MIT License
 * Copyright (c) 2024 Stefan Humm
 */

import 'package:twonly/src/visual/components/emoji_picker/emoji_picker.dart';
import 'package:twonly/src/visual/components/emoji_picker/emoji_picker_internal_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Use for golden tests, helpful in debugging
// await expectLater(
//   find.byType(MaterialApp),
//   matchesGoldenFile('overlay.png'),
// );

void main() {
  group('EmojiPicker Tests', () {
    // Caches are static and would otherwise leak between test cases.
    setUp(EmojiPickerInternalUtils.resetCaches);

    testWidgets('Should allow user to select an emoji', (
      WidgetTester tester,
    ) async {
      final _controller = TextEditingController();
      Emoji? _emojiSelected;
      Category? _categorySelected;

      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmojiPicker(
              textEditingController: _controller,
              onEmojiSelected: (category, emoji) {
                _emojiSelected = emoji;
                _categorySelected = category;
              },
              config: const Config(
                height: 256,
                categoryViewConfig: CategoryViewConfig(
                  recentTabBehavior: RecentTabBehavior.NONE,
                ),
              ),
            ),
          ),
        ),
      );

      // Wait for the emojis to load if they are being loaded asynchronously
      await tester.pumpAndSettle();

      // Find an emoji in the picker
      final emoji = find.text('🙂').hitTestable();

      // Verify if we can find the emoji
      expect(emoji, findsOneWidget);

      // Tap on the emoji, this should trigger the selection action
      await tester.tap(emoji);

      // Call pumpAndSettle in case the UI needs to settle after an interaction
      await tester.pumpAndSettle();

      // Check if the emoji is added to the text controller
      expect(_controller.text, contains('🙂'));

      // Check if the emoji been passed to the 'onEmojiSelected' callback
      expect(
        _emojiSelected,
        equals(const Emoji('🙂', 'face | happy | slightly | smile | smiling')),
      );

      // Check if the category been passed to the 'onEmojiSelected' callback
      expect(_categorySelected, equals(Category.SMILEYS));
    });

    testWidgets('Shows the redesigned header and one continuous emoji list', (
      WidgetTester tester,
    ) async {
      var stickerPressed = false;
      final controller = EmojiPickerController(
        initialCategory: Category.SMILEYS,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmojiPicker(
              controller: controller,
              config: Config(
                height: 400,
                categoryViewConfig: const CategoryViewConfig(
                  recentTabBehavior: RecentTabBehavior.NONE,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  onStickerButtonPressed: () => stickerPressed = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emojiPickerDragHandle')), findsOneWidget);
      expect(find.text('Emoji'), findsOneWidget);
      expect(find.text('Sticker'), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      expect(const EmojiViewConfig().categorySpacing, 12);
      expect(const ResizeConfig().showDragHandle, isTrue);
      expect(const ResizeConfig().handleWidth, 60);
      expect(const ResizeConfig().handleHeight, 3);
      expect(const ResizeConfig().handleHitAreaHeight, 23);
      expect(const ResizeConfig().handleBorderRadius, 32);

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.indicator, isA<BoxDecoration>());
      expect(tabBar.dividerColor, Colors.transparent);

      await tester.tap(find.text('Sticker'));
      expect(stickerPressed, isTrue);

      await tester.tap(find.byIcon(const CategoryIcons().flagIcon));
      await tester.pumpAndSettle();

      expect(controller.currentCategory, Category.FLAGS);
      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(const Key('emojiScrollView')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(scrollable.position.pixels, greaterThan(0));
    });

    testWidgets('Drag handle grows picker from its configured height', (
      WidgetTester tester,
    ) async {
      var showing = true;
      late StateSetter setHarnessState;
      final pickerController = EmojiPickerController();
      const pickerColor = Color(0xFF123456);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setHarnessState = setState;
                return Offstage(
                  offstage: !showing,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: EmojiPicker(
                      controller: pickerController,
                      config: const Config(
                        height: 256,
                        resizeConfig: ResizeConfig(maxHeight: 420),
                        emojiViewConfig: EmojiViewConfig(
                          backgroundColor: pickerColor,
                        ),
                        categoryViewConfig: CategoryViewConfig(
                          recentTabBehavior: RecentTabBehavior.NONE,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final picker = find.byKey(const Key('emojiPickerResizableContainer'));
      expect(tester.getSize(picker).height, 256);

      final handleBackground = tester.widget<DecoratedBox>(
        find.byKey(const Key('emojiPickerDragHandleBackground')),
      );
      final handleDecoration = handleBackground.decoration as BoxDecoration;
      expect(handleDecoration.color, pickerColor);
      expect(
        handleDecoration.borderRadius,
        const BorderRadius.vertical(top: Radius.circular(18)),
      );
      final dragIndicator = tester.widget<Container>(
        find.byKey(const Key('emojiPickerDragIndicator')),
      );
      final dragDecoration = dragIndicator.decoration as BoxDecoration;
      expect(dragDecoration.color, ThemeData.dark().colorScheme.outline);
      expect(dragDecoration.borderRadius, BorderRadius.circular(32));

      await tester.drag(
        find.byKey(const Key('emojiPickerDragHandle')),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(picker).height, 356);

      setHarnessState(() => showing = false);
      await tester.pump();
      setHarnessState(() => showing = true);
      await tester.pump();

      expect(tester.getSize(picker).height, 256);
    });

    testWidgets('Drag handle can be hidden', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmojiPicker(
              config: Config(
                height: 256,
                resizeConfig: ResizeConfig(showDragHandle: false),
                categoryViewConfig: CategoryViewConfig(
                  recentTabBehavior: RecentTabBehavior.NONE,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emojiPickerDragHandle')), findsNothing);
      expect(
        tester
            .getSize(find.byKey(const Key('emojiPickerResizableContainer')))
            .height,
        256,
      );
    });

    testWidgets('Should allow to select an emoji with skintone on longPress', (
      WidgetTester tester,
    ) async {
      final _controller = TextEditingController();
      final _utils = EmojiPickerUtils();
      final emoji = const Emoji('👍', 'Thumbs Up', hasSkinTone: true);
      Emoji? _emojiSelected;
      Category? _categorySelected;

      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.only(top: 64.0),
              child: EmojiPicker(
                textEditingController: _controller,
                onEmojiSelected: (category, emoji) {
                  _emojiSelected = emoji;
                  _categorySelected = category;
                },
                config: const Config(
                  height: 500,
                  categoryViewConfig: CategoryViewConfig(
                    recentTabBehavior: RecentTabBehavior.NONE,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Wait for the emojis to load if they are being loaded asynchronously
      await tester.pumpAndSettle();

      // Find an emoji in the picker
      final emojiToFind = find.text(emoji.emoji);

      // Scroll until the emoji to be found appears.
      await tester.dragUntilVisible(
        emojiToFind,
        find.byKey(const Key('emojiScrollView')),
        const Offset(0, -300),
      );

      // Verify if we can find the emoji
      expect(emojiToFind, findsOneWidget);

      // Tap on the emoji, this should trigger the skintone overlay
      await tester.longPress(emojiToFind);

      // Call pumpAndSettle in case the UI needs to settle after an interaction
      await tester.pumpAndSettle();

      /// Check if all skin tones are rendered in overlay
      Finder? skinToneVariantToFind;
      for (var i = 0; i < SkinTone.values.length; i++) {
        skinToneVariantToFind = find.text(
          _utils.applySkinTone(emoji, SkinTone.values[i]).emoji,
        );
        // Verify if we can find the skintone variant
        expect(skinToneVariantToFind, findsOneWidget);
      }

      // Tap on the emoji, this should trigger the selection action
      await tester.tap(skinToneVariantToFind!);

      // Check if the emoji is added to the text controller
      expect(_controller.text, contains('👍🏿'));

      // Check if the emoji been passed to the 'onEmojiSelected' callback
      expect(_emojiSelected?.emoji, equals('👍🏿'));
      expect(
        _emojiSelected?.name,
        equals('+1 | good | hand | like | thumb | up | yes'),
      );
      expect(_emojiSelected?.hasSkinTone, equals(true));

      // Check if the category been passed to the 'onEmojiSelected' callback
      expect(_categorySelected, equals(Category.SMILEYS));
    });

    testWidgets('Clips overflow when constrained tighter than natural height', (
      WidgetTester tester,
    ) async {
      final _controller = TextEditingController();

      // Constrain the picker far below the natural sum of the category bar
      // and bottom action bar to force the inner Column to overflow (#256).
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 30,
                child: EmojiPicker(
                  textEditingController: _controller,
                  config: const Config(
                    height: 30,
                    categoryViewConfig: CategoryViewConfig(
                      recentTabBehavior: RecentTabBehavior.NONE,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // A RenderFlex overflow is reported in debug mode; drain it so the test
      // can assert the overflow is clipped rather than left painting stripes.
      final exception = tester.takeException();
      expect(
        exception == null || exception.toString().contains('overflowed'),
        isTrue,
      );

      // The inner view Column is wrapped in a ClipRect that clips the
      // overflow (#256). Match that specific ClipRect (the one whose direct
      // child is the Column) rather than the incidental ClipRects the grid
      // and scroll views introduce.
      expect(
        find.descendant(
          of: find.byType(EmojiContainer),
          matching: find.byWidgetPredicate(
            (widget) => widget is ClipRect && widget.child is Column,
          ),
        ),
        findsOneWidget,
      );
    });
  });
}
