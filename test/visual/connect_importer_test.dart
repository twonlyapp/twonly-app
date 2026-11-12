import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/settings/backup/connect_importer.view.dart';

import '../mocks/user_config.dart';

const _link =
    'https://me.twonly.eu/i/#v1/3f1c7a52-9a4e-4c1b-8d2e-5b6a7c8d9e0f/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

class _Purchases extends ChangeNotifier
    with DiagnosticableTreeMixin
    implements PurchasesProvider {
  @override
  SubscriptionPlan plan = SubscriptionPlan.Pro;

  void set(SubscriptionPlan value) {
    plan = value;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

late _Purchases _purchases;

Widget _app() => ChangeNotifierProvider<PurchasesProvider>.value(
  value: _purchases,
  child: MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ConnectImporterView(link: _link),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  // Tall enough that the whole screen, buttons included, is laid out.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app());
  await tester.tap(find.text('open'));
  // Not pumpAndSettle: the countdown schedules a frame every second.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

bool _connectEnabled(WidgetTester tester) {
  final button = tester.widget<Widget>(
    find.byKey(const Key('importer-connect')),
  );
  return (button as dynamic).onPressed != null;
}

void main() {
  setUp(() async {
    await locator.reset();
    locator.registerSingleton<UserService>(UserService());
    userService.currentUser = testUserConfig(
      userId: 1,
      username: 'me',
      displayName: 'Me',
      subscriptionPlan: 'Pro',
      currentSetupPage: null,
      appVersion: 1,
    )..isCloudBackupEnabled = true;
    _purchases = _Purchases();
  });

  tearDown(locator.reset);

  testWidgets('explains what connecting allows and names the lures', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text('Connect importer'), findsOneWidget);
    expect(find.textContaining('can only add new memories'), findsOneWidget);
    expect(
      find.textContaining('never access your existing uploads'),
      findsOneWidget,
    );
    expect(
      find.textContaining('never asks you to scan a code'),
      findsOneWidget,
    );
    expect(find.textContaining('import.twonly.eu'), findsOneWidget);
  });

  testWidgets('Connect stays disabled for ten seconds, counting down', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text('Connect (10)'), findsOneWidget);
    expect(_connectEnabled(tester), isFalse);
    await tester.pump(const Duration(seconds: 9));
    expect(find.text('Connect (1)'), findsOneWidget);
    expect(_connectEnabled(tester), isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Connect'), findsOneWidget);
    expect(_connectEnabled(tester), isTrue);
  });

  testWidgets('going to the background restarts the countdown', (
    tester,
  ) async {
    await _open(tester);
    await tester.pump(const Duration(seconds: 8));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 30));
    expect(_connectEnabled(tester), isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Connect (10)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 9));
    expect(_connectEnabled(tester), isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(_connectEnabled(tester), isTrue);
  });

  testWidgets('Connect is the primary button, above Cancel', (tester) async {
    await _open(tester);
    final connect = tester.widget<MyButton>(
      find.byKey(const Key('importer-connect')),
    );
    expect(connect.variant, MyButtonVariant.primary);
    expect(
      tester.getTopLeft(find.byKey(const Key('importer-connect'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('importer-cancel'))).dy,
      ),
    );
  });

  testWidgets('Cancel leaves without claiming anything', (tester) async {
    await _open(tester);
    await tester.tap(find.byKey(const Key('importer-cancel')));
    await tester.pumpAndSettle();
    // Back on the previous screen; a claim would have needed the Rust bridge,
    // which this test never initialises.
    expect(find.text('open'), findsOneWidget);
    expect(find.byType(ConnectImporterView), findsNothing);
  });

  testWidgets('on the free plan it says a subscription is needed', (
    tester,
  ) async {
    _purchases.plan = SubscriptionPlan.Free;
    await _open(tester);
    expect(find.text('Requires a subscription'), findsOneWidget);
    expect(find.byKey(const Key('importer-connect')), findsNothing);
    expect(find.text('Upgrade plan'), findsOneWidget);
    // Still there after the countdown would have run out.
    await tester.pump(const Duration(seconds: 11));
    expect(find.byKey(const Key('importer-connect')), findsNothing);
  });

  testWidgets('with the backup off it asks to turn the backup on', (
    tester,
  ) async {
    userService.currentUser.isCloudBackupEnabled = false;
    await _open(tester);
    expect(find.byKey(const Key('importer-missing')), findsOneWidget);
    expect(find.textContaining('Turn it on to connect'), findsOneWidget);
    expect(find.byKey(const Key('importer-connect')), findsNothing);
    expect(
      find.byKey(const Key('importer-fix-missing')),
      findsOneWidget,
    );
  });

  testWidgets('upgrading restarts the countdown before Connect works', (
    tester,
  ) async {
    _purchases.plan = SubscriptionPlan.Free;
    await _open(tester);
    await tester.pump(const Duration(seconds: 11));
    _purchases.set(SubscriptionPlan.Pro);
    await tester.pump();
    expect(find.byKey(const Key('importer-missing')), findsNothing);
    expect(find.text('Connect (10)'), findsOneWidget);
    expect(_connectEnabled(tester), isFalse);
    await tester.pump(const Duration(seconds: 10));
    expect(_connectEnabled(tester), isTrue);
  });
}
