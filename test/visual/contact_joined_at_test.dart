import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/utils/misc.dart';

void main() {
  testWidgets('formats contact join age into friendly calendar ranges', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 10, 5, 12);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (buildContext) {
            context = buildContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    withClock(Clock.fixed(now), () {
      expect(formatJoinedAt(context, now), 'Joined today');
      expect(
        formatJoinedAt(context, now.subtract(const Duration(days: 20))),
        'Joined 20 days ago',
      );
      expect(
        formatJoinedAt(context, now.subtract(const Duration(days: 60))),
        'Joined 2 months ago',
      );
      expect(
        formatJoinedAt(context, now.subtract(const Duration(days: 730))),
        'Joined 2 years ago',
      );
    });
  });
}
