import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/api.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/visual/components/mailbox_sync.comp.dart';

class _MailboxApi implements RustLibApi {
  final progress = StreamController<MailboxSyncProgress>.broadcast();

  @override
  Stream<MailboxSyncProgress> crateBridgeApiRustApiMailboxSyncProgress() =>
      progress.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MailboxApi api;

  setUp(() {
    api = _MailboxApi();
    RustLib.initMock(api: api);
  });

  tearDown(() async {
    await api.progress.close();
    RustLib.dispose();
  });

  testWidgets('mailbox progress covers the current route until sync finishes', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => Stack(
          children: [?child, const MailboxSyncOverlay()],
        ),
        home: Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => taps++,
              child: const Text('Preview Mailbox Sync'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);

    api.progress.add(
      const MailboxSyncProgress(active: true, total: 3000, remaining: 3000),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tapAt(tester.getCenter(find.text('Preview Mailbox Sync')));
    expect(taps, 0);

    api.progress.add(
      const MailboxSyncProgress(active: true, total: 3000, remaining: 1500),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      ).value,
      0.5,
    );

    api.progress.add(
      const MailboxSyncProgress(active: false, total: 0, remaining: 0),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.tap(find.text('Preview Mailbox Sync'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
