import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge.dart' show FlameState;
import 'package:twonly/src/visual/components/animate_icon.comp.dart';
import 'package:twonly/src/visual/components/flame_counter.comp.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> show(WidgetTester tester, FlameState state) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FlameCounterWidget(state: state)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  Finder emoji(String value) => find.byWidgetPredicate(
    (widget) => widget is EmojiAnimationComp && widget.emoji == value,
  );

  test('the vacation icons are animated and bundled', () async {
    for (final icon in ['🏕️', '✈️', '⛵']) {
      final asset = EmojiAnimationComp.animatedIcons[icon];
      expect(asset, isNotNull, reason: icon);
      expect(isOneEmoji(icon), isTrue, reason: icon);
      expect(EmojiAnimationComp.supported(icon), isTrue, reason: icon);
      final bytes = await rootBundle.load('assets/animated_icons/$asset');
      expect(bytes.lengthInBytes, greaterThan(0), reason: icon);
    }
  });

  test('an announced icon falls back when it cannot be shown', () {
    expect(vacationIconOrDefault('⛵'), '⛵');
    // From a newer release: not animated here, still an emoji.
    expect(vacationIconOrDefault('🏝️'), '🏝️');
    for (final junk in [null, '', 'beach', '🏕️🏕️🏕️', 'x' * 40]) {
      expect(vacationIconOrDefault(junk), '🏕️', reason: '$junk');
    }
  });

  testWidgets('a frozen streak shows the vacation instead of the flame', (
    tester,
  ) async {
    await show(
      tester,
      const FlameState(
        counter: 50,
        isExpiring: false,
        isBestFriend: true,
        vacationIcon: '✈️',
      ),
    );

    expect(find.text('50'), findsOneWidget);
    expect(emoji('✈️'), findsOneWidget);
    expect(emoji('🔥'), findsNothing);
    expect(emoji('❤️‍🔥'), findsNothing);
    expect(emoji('⌛'), findsNothing);
  });

  testWidgets('the number stays visible at 100 while frozen', (tester) async {
    await show(
      tester,
      const FlameState(
        counter: 100,
        isExpiring: false,
        isBestFriend: false,
        vacationIcon: '⛵',
      ),
    );
    expect(find.text('100'), findsOneWidget);
    expect(emoji('⛵'), findsOneWidget);
    expect(emoji('💯'), findsNothing);

    await show(
      tester,
      const FlameState(counter: 100, isExpiring: false, isBestFriend: false),
    );
    expect(find.text('100'), findsNothing);
    expect(emoji('💯'), findsOneWidget);
  });

  testWidgets('without a vacation the flame is unchanged', (tester) async {
    await show(
      tester,
      const FlameState(counter: 12, isExpiring: true, isBestFriend: false),
    );
    expect(find.text('12'), findsOneWidget);
    expect(emoji('🔥'), findsOneWidget);
    expect(emoji('⌛'), findsOneWidget);
  });

  testWidgets('an icon this release cannot animate still fits', (
    tester,
  ) async {
    await show(
      tester,
      const FlameState(
        counter: 7,
        isExpiring: false,
        isBestFriend: false,
        vacationIcon: '🏝️',
      ),
    );
    expect(emoji('🏝️'), findsOneWidget);
    expect(find.byType(FittedBox), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(FittedBox)).height, 15);
  });

  testWidgets('junk from a peer shows the default icon', (tester) async {
    await show(
      tester,
      const FlameState(
        counter: 7,
        isExpiring: false,
        isBestFriend: false,
        vacationIcon: 'definitely not an emoji',
      ),
    );
    expect(emoji('🏕️'), findsOneWidget);
    expect(find.textContaining('definitely'), findsNothing);
  });

  testWidgets('no streak shows nothing, vacation or not', (tester) async {
    await show(
      tester,
      const FlameState(
        counter: 0,
        isExpiring: false,
        isBestFriend: false,
        vacationIcon: '🏕️',
      ),
    );
    expect(find.byType(EmojiAnimationComp), findsNothing);
  });
}
