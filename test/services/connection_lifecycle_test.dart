import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/services/api/connection_lifecycle.dart';

void main() {
  test(
    'duplicate network notifications coalesce while route changes reconnect',
    () async {
      var updates = 0;
      final lifecycle = ConnectionLifecycle(
        readNetworkAvailable: () async => true,
        applyNetworkAvailable: (_) async {
          updates++;
        },
        applyBackground: (_) async {},
        onError: (error, stack) => fail('$error'),
      );
      await Future.wait([
        lifecycle.networkChanged(identity: 'wifi'),
        lifecycle.networkChanged(identity: 'wifi'),
        lifecycle.networkChanged(identity: 'mobile'),
      ]);
      expect(updates, 2);
    },
  );
  test(
    'resume waits for pause and refreshes reachability before reconnecting',
    () async {
      final paused = Completer<void>();
      final calls = <String>[];
      final lifecycle = ConnectionLifecycle(
        readNetworkAvailable: () async {
          calls.add('read network');
          return true;
        },
        applyNetworkAvailable: (available) async =>
            calls.add('network $available'),
        applyBackground: (background) async {
          calls.add('background $background');
          if (background) await paused.future;
        },
        onError: (error, stack) => fail('$error'),
      );
      final pause = lifecycle.setBackground(true);
      final resume = lifecycle.setBackground(false);
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['background true']);
      paused.complete();
      await pause;
      await resume;
      expect(calls, [
        'background true',
        'read network',
        'network true',
        'background false',
      ]);
    },
  );

  test('focus changes do not trigger a reachability refresh', () async {
    var queries = 0;
    final lifecycle = ConnectionLifecycle(
      readNetworkAvailable: () async {
        queries++;
        return true;
      },
      applyNetworkAvailable: (_) async {},
      applyBackground: (_) async {},
      onError: (error, stack) => fail('$error'),
    );
    await lifecycle.setBackground(false);
    await lifecycle.setBackground(false);
    expect(queries, 0);
  });

  test(
    'failed connectivity query releases an old offline flag on resume',
    () async {
      final errors = <Object>[];
      final calls = <String>[];
      final lifecycle = ConnectionLifecycle(
        readNetworkAvailable: () async =>
            throw StateError('platform unavailable'),
        applyNetworkAvailable: (available) async =>
            calls.add('network $available'),
        applyBackground: (background) async =>
            calls.add('background $background'),
        onError: (error, stack) => errors.add(error),
      );
      await lifecycle.setBackground(true);
      await lifecycle.setBackground(false);
      expect(errors, hasLength(1));
      expect(calls, ['background true', 'network true', 'background false']);
    },
  );

  test(
    'failed bridge update does not prevent subsequent network updates',
    () async {
      final errors = <Object>[];
      final applied = <bool>[];
      var online = false;
      final lifecycle = ConnectionLifecycle(
        readNetworkAvailable: () async => online,
        applyNetworkAvailable: (available) async => applied.add(available),
        applyBackground: (_) async => throw StateError('bridge unavailable'),
        onError: (error, stack) => errors.add(error),
      );
      await lifecycle.setBackground(true);
      await lifecycle.networkChanged();
      online = true;
      await lifecycle.networkChanged();
      expect(errors, hasLength(1));
      expect(applied, [false, true]);
    },
  );
}
