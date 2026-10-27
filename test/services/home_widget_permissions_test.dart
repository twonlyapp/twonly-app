import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/src/services/home_widget.service.dart';

class _WidgetApi implements RustLibApi {
  Future<void> Function()? sync;

  @override
  Future<void> crateBridgeApiRustApiSyncWidgetPermissions() async {
    await sync?.call();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('eu.twonly/runtime_storage');
  final api = _WidgetApi();
  final calls = <String>[];

  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() {
    api.sync = null;
    calls.clear();
    HomeWidgetService.invalidate();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call.method);
      return null;
    });
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  for (final message in [
    'attempted to acquire a connection on a closed pool',
    'retry when active',
  ]) {
    test('in-flight sync tolerates $message and succeeds on resume', () async {
      final started = Completer<void>();
      final pending = Completer<void>();
      api.sync = () {
        started.complete();
        return pending.future;
      };

      // Startup/resume callers do not await the sync. Closing the pool during
      // its bridge call must not escape as an unhandled root-zone exception.
      unawaited(HomeWidgetService.syncPermissions());
      await started.future;
      pending.completeError(Exception(message));
      await Future<void>.delayed(Duration.zero);
      expect(calls, isNot(contains('reloadWidgets')));

      api.sync = null;
      await HomeWidgetService.syncPermissions();
      expect(calls.where((method) => method == 'reloadWidgets'), hasLength(1));
    });
  }

  test('unexpected sync errors remain visible to the caller', () async {
    final error = StateError('widget database query failed');
    api.sync = () async => throw error;

    await expectLater(
      HomeWidgetService.syncPermissions(),
      throwsA(same(error)),
    );
    expect(calls, isNot(contains('reloadWidgets')));
  });
}
