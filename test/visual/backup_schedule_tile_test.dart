import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/visual/views/settings/backup/components/backup_schedule.comp.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('eu.twonly/backup_schedule');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  testWidgets('refreshes the schedule on tap and app resume', (tester) async {
    var state = 'notScheduled';
    var requests = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getSchedule');
      requests++;
      return {'state': state};
    });

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BackupScheduleTile())),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No background backup check is scheduled.'),
      findsOneWidget,
    );
    expect(requests, 1);

    state = 'running';
    await tester.tap(find.byTooltip('Refresh schedule'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Running now.'), findsOneWidget);
    expect(requests, 2);

    state = 'scheduled';
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Scheduled; waiting for the system.'), findsOneWidget);
    expect(requests, 3);
  });
}
