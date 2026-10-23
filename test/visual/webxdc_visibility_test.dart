import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/webxdc/webxdc_host.dart';
import 'package:twonly/src/visual/views/webxdc/webxdc_app.view.dart';

import '../helpers/native_database.dart';

class _WebxdcApi extends NativeTestApi {
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
  final platformCalls = <MethodCall>[];
  final hcppCalls = <MethodCall>[];
  setUpAll(() => initializeNativeDatabase(api: api));
  tearDownAll(RustLib.dispose);
  setUp(() async {
    api.visibleInstances.clear();
    platformCalls.clear();
    hcppCalls.clear();
    WebxdcHost.hybridComposition = false;
    await locator.reset();
    await TestDatabase.create();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform_views,
          (call) async {
            platformCalls.add(call);
            if (call.method == 'create') return 0;
            if (call.method == 'resize') {
              final arguments = call.arguments as Map<Object?, Object?>;
              return {
                'width': arguments['width'],
                'height': arguments['height'],
              };
            }
            return null;
          },
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform_views_2,
          (call) async {
            hcppCalls.add(call);
            return null;
          },
        );
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views_2, null);
    WebxdcHost.hybridComposition = false;

    await locator.reset();
  });

  for (final hcpp in [false, true]) {
    testWidgets(
      'Android ${hcpp ? 'HCPP' : 'texture'} forwards page taps after the opening transition has settled',
      (tester) async {
        WebxdcHost.hybridComposition = hcpp;
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            home: const Scaffold(body: Text('Chat')),
          ),
        );
        navigator.currentState!.push<void>(
          MaterialPageRoute(
            builder: (_) => const WebxdcAppView(
              launch: WebxdcLaunch(
                instanceId: 'game',
                appId: 'game',
                origin: 'origin',
                title: 'Game',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final surface = find.byType(AndroidViewSurface);
        await tester.tap(surface);
        await tester.pump();

        final calls = hcpp ? hcppCalls : platformCalls;
        final touches = calls
            .where((call) => call.method == 'touch')
            .map((call) => call.arguments as List<Object?>)
            .toList();
        expect(touches, hasLength(2));
        expect(touches.map((event) => event[3]), [0, 1]); // Down, up.
        final create = calls.singleWhere(
          (call) => call.method == 'create',
        );
        final parameters = create.arguments as Map<Object?, Object?>;
        expect(touches.every((event) => event[0] == parameters['id']), isTrue);

        await tester.pumpWidget(const SizedBox.shrink());
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }

  for (final appId in ['backend-uploaded-game', 'expenses']) {
    testWidgets(
      '$appId: only the foreground app route suppresses its alerts',
      (
        tester,
      ) async {
        final navigator = GlobalKey<NavigatorState>();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            home: WebxdcAppView(
              launch: WebxdcLaunch(
                instanceId: '$appId-chat-a',
                appId: appId,
                origin: 'origin',
                title: appId,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(api.visibleInstances.last, '$appId-chat-a');

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        expect(api.visibleInstances.last, isNull);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        expect(api.visibleInstances.last, isNull);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        expect(api.visibleInstances.last, '$appId-chat-a');

        final covered = navigator.currentState!.push<void>(
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Share')),
          ),
        );
        await tester.pumpAndSettle();
        expect(api.visibleInstances.last, isNull);
        navigator.currentState!.pop();
        await tester.pumpAndSettle();
        await covered;
        expect(api.visibleInstances.last, '$appId-chat-a');

        await tester.pumpWidget(const SizedBox.shrink());
        expect(api.visibleInstances.last, isNull);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );
  }
}
