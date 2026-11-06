import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:twonly/core/bridge.dart' show VacationWindow;
import 'package:twonly/core/bridge/groups.dart' show VacationOptions;
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/pro_badge.element.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/settings/chat/on_vacation.view.dart';

import '../mocks/user_config.dart';

class _VacationApi implements RustLibApi {
  VacationWindow? vacation;
  int candidates = 3;
  int? startResult;
  Exception? startError;
  final starts = <(int, String)>[];
  int ends = 0;

  void reset() {
    vacation = null;
    candidates = 3;
    startResult = null;
    startError = null;
    starts.clear();
    ends = 0;
  }

  @override
  VacationOptions crateBridgeGroupsVacationOptions() => const VacationOptions(
    icons: ['🏕️', '✈️', '⛵'],
    minDays: 3,
    maxDays: 8,
    minFlames: 5,
  );

  @override
  Future<VacationWindow?> crateBridgeGroupsOwnVacation() async => vacation;

  @override
  Future<int> crateBridgeGroupsVacationCandidateCount() async => candidates;

  @override
  Future<int> crateBridgeGroupsStartVacation({
    required int days,
    required String icon,
  }) async {
    starts.add((days, icon));
    final error = startError;
    if (error != null) throw error;
    final frozen = startResult ?? candidates;
    if (frozen > 0) {
      final now = DateTime.now();
      vacation = VacationWindow(
        from: now.millisecondsSinceEpoch ~/ 1000,
        until:
            DateTime(now.year, now.month, now.day + days)
                .millisecondsSinceEpoch ~/
            1000,
        icon: icon,
      );
    }
    return frozen;
  }

  @override
  Future<int> crateBridgeGroupsEndVacation() async {
    ends++;
    vacation = null;
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final api = _VacationApi();

  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);

  Future<void> setPlan(String plan) async {
    await locator.reset();
    locator.registerSingleton<UserService>(UserService());
    userService.currentUser = testUserConfig(
      userId: 1,
      username: 'me',
      displayName: 'Me',
      subscriptionPlan: plan,
      currentSetupPage: null,
      appVersion: 180,
    );
  }

  setUp(() async {
    api.reset();
    await setPlan('Pro');
  });

  tearDown(locator.reset);

  // The icons animate forever, so the tree never settles; step time instead.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> open(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const OnVacationView()),
        GoRoute(
          path: Routes.settingsSubscription,
          builder: (_, _) => const Scaffold(body: Text('subscription page')),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await settle(tester);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final label = find.text(text).last;
    // MyButton keeps its label out of hit testing; tap the button itself.
    final button = find.ancestor(of: label, matching: find.byType(MyButton));
    final target = tester.any(button) ? button : label;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await settle(tester);
  }

  Future<void> tapDay(WidgetTester tester, int day) async {
    final dot = find.byKey(ValueKey('vacationDay$day'));
    await tester.ensureVisible(dot);
    await tester.tap(dot);
    await settle(tester);
  }

  Finder icon(String emoji) => find.byWidgetPredicate(
    (widget) => widget is EmojiAnimationComp && widget.emoji == emoji,
  );

  String day(DateTime date) => DateFormat.MMMEd('en').format(date);

  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  testWidgets('the picker starts at five days with the first icon', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('5 days'), findsWidgets);
    for (final emoji in ['🏕️', '✈️', '⛵']) {
      expect(icon(emoji), findsOneWidget);
    }
    final countsAgain = today().add(const Duration(days: 5));
    expect(
      find.text('Your flames count again from ${day(countsAgain)}.'),
      findsOneWidget,
    );
    expect(find.text('3 chats will be frozen.'), findsOneWidget);
    expect(find.textContaining('more than 4 flames'), findsOneWidget);
    // The button sizes to its label instead of the page width.
    final button = find.ancestor(
      of: find.text('Go on vacation'),
      matching: find.byType(MyButton),
    );
    expect(
      tester.getSize(button).width,
      lessThan(tester.getSize(find.byType(Scaffold)).width / 2),
    );
    expect(find.byType(ProBadge), findsOneWidget);
  });

  testWidgets('the chosen icon and length are what starts the vacation', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(icon('⛵'));
    await settle(tester);
    await tapDay(tester, 8);
    expect(find.text('8 days'), findsWidgets);

    await tapText(tester, 'Go on vacation');

    expect(api.starts, [(8, '⛵')]);
    expect(find.text('Enjoy your vacation! 3 chats are frozen.'), findsOneWidget);
    // The view switches to the running vacation.
    final lastDay = today().add(const Duration(days: 7));
    expect(find.text('On vacation until ${day(lastDay)}'), findsOneWidget);
    expect(find.text('End vacation'), findsOneWidget);
    expect(find.text('Go on vacation'), findsNothing);
  });

  testWidgets('the first three days are always part of it', (tester) async {
    await open(tester);

    for (final day in [1, 2, 3]) {
      await tapDay(tester, 8);
      await tapDay(tester, day);
      expect(find.text('3 days'), findsWidgets, reason: 'day $day');
    }

    await tapText(tester, 'Go on vacation');
    expect(api.starts, [(3, '🏕️')]);
  });

  testWidgets('every day of the vacation is a dot, starting today', (
    tester,
  ) async {
    await open(tester);

    for (var day = 1; day <= 8; day++) {
      final date = today().add(Duration(days: day - 1));
      final dot = find.byKey(ValueKey('vacationDay$day'));
      expect(dot, findsOneWidget);
      expect(
        find.descendant(of: dot, matching: find.text('$day')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dot,
          matching: find.text(
            DateFormat.E('en').format(date).replaceAll('.', ''),
          ),
        ),
        findsOneWidget,
      );
    }

    for (final length in [4, 6, 8, 5]) {
      await tapDay(tester, length);
      expect(find.text('$length days'), findsWidgets);
      final countsAgain = today().add(Duration(days: length));
      expect(
        find.text('Your flames count again from ${day(countsAgain)}.'),
        findsOneWidget,
      );
    }
  });

  testWidgets('dragging along the dots picks the day under the finger', (
    tester,
  ) async {
    await open(tester);

    final first = tester.getCenter(find.byKey(const ValueKey('vacationDay1')));
    final seventh = tester.getCenter(
      find.byKey(const ValueKey('vacationDay7')),
    );
    await tester.dragFrom(first, seventh - first);
    await settle(tester);
    expect(find.text('7 days'), findsWidgets);

    // Off either end it stays within three to eight days.
    await tester.dragFrom(seventh, const Offset(2000, 0));
    await settle(tester);
    expect(find.text('8 days'), findsWidgets);
    await tester.dragFrom(seventh, const Offset(-2000, 0));
    await settle(tester);
    expect(find.text('3 days'), findsWidgets);
  });

  for (final plan in ['Free', 'Unknown']) {
    testWidgets('the $plan plan is sent to the subscription page', (
      tester,
    ) async {
      await setPlan(plan);
      await open(tester);

      await tapText(tester, 'Go on vacation');

      expect(api.starts, isEmpty);
      expect(find.text('subscription page'), findsOneWidget);
    });
  }

  for (final plan in ['Plus', 'Family', 'Tester']) {
    testWidgets('the $plan plan can go on vacation', (tester) async {
      await setPlan(plan);
      await open(tester);

      await tapText(tester, 'Go on vacation');

      expect(api.starts, hasLength(1));
      expect(find.text('subscription page'), findsNothing);
    });
  }

  testWidgets('with nothing to freeze the button is disabled', (tester) async {
    api.candidates = 0;
    await open(tester);

    expect(find.text('No chat has more than 4 flames yet.'), findsOneWidget);
    await tapText(tester, 'Go on vacation');
    expect(api.starts, isEmpty);
  });

  testWidgets('a free user still sees the upsell with nothing to freeze', (
    tester,
  ) async {
    await setPlan('Free');
    api.candidates = 0;
    await open(tester);

    await tapText(tester, 'Go on vacation');
    expect(find.text('subscription page'), findsOneWidget);
  });

  testWidgets('streaks lost since the count was shown start no vacation', (
    tester,
  ) async {
    api.startResult = 0;
    await open(tester);

    await tapText(tester, 'Go on vacation');

    expect(api.starts, hasLength(1));
    expect(
      find.text(
        'None of your chats has more than 4 flames, so there is nothing to freeze.',
      ),
      findsOneWidget,
    );
    expect(find.text('Go on vacation'), findsOneWidget);
  });

  testWidgets('a refused start keeps the picker and says so', (tester) async {
    api.startError = Exception('already on vacation');
    await open(tester);

    await tapText(tester, 'Go on vacation');

    expect(
      find.text('Could not start your vacation. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Go on vacation'), findsOneWidget);
  });

  testWidgets('a running vacation can be ended after confirming', (
    tester,
  ) async {
    final lastDay = today().add(const Duration(days: 2));
    api.vacation = VacationWindow(
      from: today().millisecondsSinceEpoch ~/ 1000,
      until: lastDay.add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000,
      icon: '✈️',
    );
    await open(tester);

    expect(find.text('On vacation until ${day(lastDay)}'), findsOneWidget);
    expect(icon('✈️'), findsOneWidget);

    await tapText(tester, 'End vacation');
    expect(find.text('End your vacation?'), findsOneWidget);
    await tapText(tester, 'Cancel');
    expect(api.ends, 0);
    expect(find.text('End vacation'), findsOneWidget);

    await tapText(tester, 'End vacation');
    // The dialog's confirm button carries the same label.
    await tapText(tester, 'End vacation');

    expect(api.ends, 1);
    expect(find.text('Go on vacation'), findsOneWidget);
  });
}
