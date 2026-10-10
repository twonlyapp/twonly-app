import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/webxdc/webxdc_host.dart';
import 'package:twonly/src/visual/views/webxdc/webxdc_app.view.dart';

class _WebxdcApi implements RustLibApi {
  final visibleInstances = <String?>[];

  @override
  void crateBridgeWebxdcSetVisibleInstance({String? instanceId}) {
    visibleInstances.add(instanceId);
  }

  @override
  Future<void> crateBridgeWebxdcCacheUpdate({
    required String instanceId,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final api = _WebxdcApi();
  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);
  setUp(() async {
    api.visibleInstances.clear();
    await locator.reset();
    locator.registerSingleton<TwonlyDB>(
      TwonlyDB.forTesting(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      ),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform_views,
          (_) async => null,
        );
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views, null);
    await twonlyDB.close();
    await locator.reset();
  });

  testWidgets('only the foreground game route suppresses its turn alerts', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const WebxdcAppView(
          launch: WebxdcLaunch(
            instanceId: 'connect4-chat-a',
            appId: 'connect4',
            origin: 'origin',
            title: 'Connect Four',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(api.visibleInstances.last, 'connect4-chat-a');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(api.visibleInstances.last, isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(api.visibleInstances.last, isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(api.visibleInstances.last, 'connect4-chat-a');

    final covered = navigator.currentState!.push<void>(
      MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Share'))),
    );
    await tester.pumpAndSettle();
    expect(api.visibleInstances.last, isNull);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    await covered;
    expect(api.visibleInstances.last, 'connect4-chat-a');

    await tester.pumpWidget(const SizedBox.shrink());
    expect(api.visibleInstances.last, isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('other apps keep their notification behavior while open', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      const MaterialApp(
        home: WebxdcAppView(
          launch: WebxdcLaunch(
            instanceId: 'expenses-chat-a',
            appId: 'expenses',
            origin: 'origin',
            title: 'Expenses',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(api.visibleInstances, everyElement(isNull));
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
