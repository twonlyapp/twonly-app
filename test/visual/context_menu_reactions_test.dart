import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/visual/context_menu/context_menu.helper.dart';
import 'package:twonly/src/visual/themes/light.dart';

void main() {
  Future<List<String>> pumpMenu(
    WidgetTester tester, {
    Set<String> selected = const {},
    List<String>? itemsTapped,
    List<bool>? moreOpened,
  }) async {
    final reacted = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: ContextMenu(
                reactions: () => ContextMenuReactions(
                  // Plain text emojis keep Lottie out of the test.
                  emojis: const ['a', 'b', 'c', 'd', 'e', 'f'],
                  selected: selected,
                  moreLabel: 'More',
                  onSelected: (emoji) async => reacted.add(emoji),
                  onMore: () async => moreOpened?.add(true),
                ),
                items: () => [
                  ContextMenuItem(
                    title: 'Reply',
                    icon: FontAwesomeIcons.reply,
                    onTap: () async => itemsTapped?.add('Reply'),
                  ),
                  ContextMenuItem(
                    title: 'Delete',
                    icon: FontAwesomeIcons.trash,
                    destructive: true,
                    onTap: () async => itemsTapped?.add('Delete'),
                  ),
                ],
                child: Container(
                  width: 200,
                  height: 60,
                  color: Colors.blue,
                  child: const Text('Message'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return reacted;
  }

  testWidgets('sliding the held finger to an emoji reacts with it', (
    tester,
  ) async {
    final reacted = await pumpMenu(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Message')),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Reply'), findsOneWidget);

    // Slide left to right across the bar, ending on 'c'.
    await gesture.moveTo(tester.getCenter(find.text('a')));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('b')));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('c')));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reacted, ['c']);
    expect(find.text('Reply'), findsNothing);
  });

  testWidgets('the held finger picks by x anywhere on the screen', (
    tester,
  ) async {
    final reacted = await pumpMenu(tester);

    final start = tester.getCenter(find.text('Message'));
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // Far above the bar at the top of the screen, only lined up with 'd'.
    final x = tester.getCenter(find.text('d')).dx;
    await gesture.moveTo(Offset(x, 10));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reacted, ['d']);
  });

  testWidgets('the held finger still picks over the menu card', (
    tester,
  ) async {
    final reacted = await pumpMenu(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Message')),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    await gesture.moveTo(tester.getCenter(find.text('Reply')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reacted, hasLength(1));
  });

  testWidgets('nothing is picked while the menu still animates in', (
    tester,
  ) async {
    final reacted = await pumpMenu(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Message')),
    );
    // Long press fires at 500 ms; the bar is still popping in after 520.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.moveTo(tester.getCenter(find.text('b')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reacted, isEmpty);
    expect(find.text('Reply'), findsOneWidget);
  });

  testWidgets('a pick made during the animation applies once it ends', (
    tester,
  ) async {
    final reacted = await pumpMenu(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Message')),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.moveTo(tester.getCenter(find.text('e')));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reacted, ['e']);
  });

  testWidgets('swiping down pauses the pick, swiping up resumes it', (
    tester,
  ) async {
    final reacted = await pumpMenu(tester);

    final start = tester.getCenter(find.text('Message'));
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    final c = tester.getCenter(find.text('c'));
    await gesture.moveTo(c);
    await tester.pump();
    // Below the menu card: paused, so letting go here would send nothing.
    await gesture.moveTo(Offset(c.dx, 599));
    await tester.pumpAndSettle();
    // Back up: the pick continues where the finger is.
    await gesture.moveTo(tester.getCenter(find.text('b')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reacted, ['b']);
  });

  testWidgets('letting go while paused sends nothing', (tester) async {
    final reacted = await pumpMenu(tester);

    final start = tester.getCenter(find.text('Message'));
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    final c = tester.getCenter(find.text('c'));
    await gesture.moveTo(c);
    await tester.pump();
    await gesture.moveTo(Offset(c.dx, 599));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reacted, isEmpty);
    expect(find.text('Reply'), findsOneWidget);
  });

  /// Moves [gesture] from [from] to [to] in [steps] events spread over
  /// [duration], starting at [at]; returns the time after the last event.
  Future<Duration> slide(
    WidgetTester tester,
    TestGesture gesture,
    Offset from,
    Offset to, {
    required Duration at,
    required Duration duration,
    int steps = 8,
  }) async {
    for (var i = 1; i <= steps; i++) {
      final time = at + duration * (i / steps);
      await gesture.moveTo(
        Offset.lerp(from, to, i / steps)!,
        timeStamp: time,
      );
      await tester.pump();
    }
    return at + duration;
  }

  testWidgets('a quick swipe down pauses the pick anywhere', (tester) async {
    final reacted = await pumpMenu(tester);

    final start = tester.getCenter(find.text('Message'));
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    final c = tester.getCenter(find.text('c'));
    var t = await slide(
      tester,
      gesture,
      start,
      c,
      at: Duration.zero,
      duration: const Duration(milliseconds: 400),
    );
    // 120 px down in 60 ms, still well above the menu's bottom edge.
    t = await slide(
      tester,
      gesture,
      c,
      c + const Offset(0, 120),
      at: t + const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 60),
    );
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reacted, isEmpty);
    expect(find.text('Reply'), findsOneWidget);
  });

  testWidgets('a slow drag down onto the menu keeps picking', (tester) async {
    final reacted = await pumpMenu(tester);

    final start = tester.getCenter(find.text('Message'));
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    final reply = tester.getCenter(find.text('Reply'));
    await slide(
      tester,
      gesture,
      start,
      reply,
      at: Duration.zero,
      duration: const Duration(milliseconds: 800),
      steps: 16,
    );
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reacted, hasLength(1));
  });

  testWidgets('swiping back up after a pause resumes the pick', (
    tester,
  ) async {
    final reacted = await pumpMenu(tester);

    final start = tester.getCenter(find.text('Message'));
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    final c = tester.getCenter(find.text('c'));
    var t = await slide(
      tester,
      gesture,
      start,
      c,
      at: Duration.zero,
      duration: const Duration(milliseconds: 400),
    );
    final low = c + const Offset(0, 120);
    t = await slide(
      tester,
      gesture,
      c,
      low,
      at: t + const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 60),
    );
    final b = tester.getCenter(find.text('b'));
    await slide(
      tester,
      gesture,
      low,
      b,
      at: t + const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 300),
    );
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reacted, ['b']);
  });

  testWidgets('lifting the finger on the message keeps the menu open', (
    tester,
  ) async {
    final tapped = <String>[];
    final reacted = await pumpMenu(tester, itemsTapped: tapped);

    await tester.longPress(find.text('Message'));
    await tester.pumpAndSettle();
    expect(reacted, isEmpty);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(tapped, ['Delete']);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('the more button opens the picker after closing', (
    tester,
  ) async {
    final opened = <bool>[];
    await pumpMenu(tester, moreOpened: opened);

    await tester.longPress(find.text('Message'));
    await tester.pumpAndSettle();
    // The more button is the slot right of the last emoji.
    final last = tester.getRect(find.text('f'));
    final slot =
        tester.getRect(find.text('f')).left -
        tester.getRect(find.text('e')).left;
    await tester.tapAt(last.center + Offset(slot, 0));
    await tester.pumpAndSettle();
    expect(opened, [true]);
  });

  testWidgets('tapping the scrim closes the menu', (tester) async {
    await pumpMenu(tester);

    await tester.longPress(find.text('Message'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Reply'), findsNothing);
  });

  bool hasLiftCard(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(find.byType(DecoratedBox))
      .map((box) => box.decoration)
      .whereType<BoxDecoration>()
      .any((d) => d.color == lightTheme.scaffoldBackgroundColor);

  testWidgets('a lifted list row is drawn on a card, not dimmed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: Center(
            child: ContextMenu(
              items: () => [
                ContextMenuItem(
                  title: 'Archive',
                  icon: Icons.archive_outlined,
                  onTap: () async {},
                ),
              ],
              child: const SizedBox(
                width: 800,
                height: 72,
                child: ListTile(title: Text('Chat row')),
              ),
            ),
          ),
        ),
      ),
    );
    expect(hasLiftCard(tester), isFalse);

    await tester.longPress(find.text('Chat row'));
    await tester.pumpAndSettle();

    expect(find.text('Archive'), findsOneWidget);
    expect(hasLiftCard(tester), isTrue);
  });

  testWidgets('a lifted message gets no extra card', (tester) async {
    await pumpMenu(tester);
    await tester.longPress(find.text('Message'));
    await tester.pumpAndSettle();

    expect(find.text('Reply'), findsOneWidget);
    expect(hasLiftCard(tester), isFalse);
  });
}
