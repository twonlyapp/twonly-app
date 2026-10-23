import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/views/settings/help/help.view.dart';

import '../mocks/user_config.dart';

void main() {
  setUp(() async {
    await locator.reset();
    locator.registerSingleton<UserService>(UserService());
    PackageInfo.setMockInitialValues(
      appName: 'twonly',
      packageName: 'eu.twonly',
      version: '0.6.3',
      buildNumber: '192',
      buildSignature: '',
    );
  });
  tearDown(locator.reset);

  for (final plan in SubscriptionPlan.values) {
    testWidgets('error tracking control for ${plan.name}', (tester) async {
      userService.currentUser = testUserConfig(
        userId: 1,
        username: 'me',
        displayName: 'Me',
        subscriptionPlan: plan.name,
        currentSetupPage: null,
        appVersion: 192,
      )..allowErrorTrackingViaSentry = true;

      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HelpView(),
        ),
      );
      await tester.pumpAndSettle();

      final control = tester.widget<Switch>(find.byType(Switch));
      final row = tester.widget<ListTile>(
        find.ancestor(of: find.byType(Switch), matching: find.byType(ListTile)),
      );
      expect(control.value, isTrue);
      if (plan == SubscriptionPlan.Tester) {
        expect(control.onChanged, isNull);
        expect(row.onTap, isNull);
        await tester.tap(find.byType(Switch));
        await tester.pump();
        expect(userService.currentUser.allowErrorTrackingViaSentry, isTrue);
      } else {
        expect(control.onChanged, isNotNull);
        expect(row.onTap, isNotNull);
      }
    });
  }
}
