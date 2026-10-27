import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/services/notifications/fcm_token_registration.dart';

void main() {
  late StreamController<String> updates;
  late FcmTokenRegistration registration;
  late String currentToken;
  late List<String> saved;
  late List<String> uploaded;
  late Future<String?> Function() read;
  late Future<void> Function() remove;
  late Future<void> Function(String) upload;
  late bool authenticated;
  late int subscriptions;

  setUp(() {
    updates = StreamController<String>.broadcast(sync: true);
    currentToken = 'current';
    saved = [];
    uploaded = [];
    read = () async => currentToken;
    remove = () async => currentToken = 'replacement';
    upload = (token) async => uploaded.add(token);
    authenticated = true;
    subscriptions = 0;
    registration = FcmTokenRegistration(
      readToken: () => read(),
      deleteToken: () => remove(),
      tokenRefreshes: () {
        subscriptions++;
        return updates.stream;
      },
      saveToken: (token) async => saved.add(token),
      isAuthenticated: () async => authenticated,
      uploadToken: (token) => upload(token),
      onError: (error, stackTrace) => fail('$error'),
      tokenTimeout: const Duration(milliseconds: 500),
      requestTimeout: const Duration(milliseconds: 500),
    );
  });

  tearDown(() async {
    await registration.dispose();
    await updates.close();
  });

  test(
    're-registers unchanged tokens and subscribes to refresh only once',
    () async {
      await registration.refresh();
      await registration.refresh();
      expect(uploaded, ['current', 'current']);
      expect(subscriptions, 1);
    },
  );

  test('a reset discards the token read that started before it', () async {
    final reading = Completer<void>();
    final oldToken = Completer<String?>();
    read = () {
      reading.complete();
      return oldToken.future;
    };
    final refresh = registration.refresh();
    await reading.future;
    final reset = registration.reset();
    read = () async => currentToken;
    oldToken.complete('retired');
    await refresh;
    await reset;
    expect(saved, ['replacement']);
    expect(uploaded, ['replacement']);
  });

  test(
    'concurrent reset requests perform one deletion and registration',
    () async {
      var deletions = 0;
      final deleting = Completer<void>();
      remove = () async {
        deletions++;
        await deleting.future;
        currentToken = 'replacement';
      };
      final first = registration.reset();
      final second = registration.reset();
      expect(identical(first, second), isTrue);
      deleting.complete();
      await Future.wait([first, second]);
      expect(deletions, 1);
      expect(uploaded, ['replacement']);
    },
  );

  test(
    'refresh during an upload registers the latest SDK token afterward',
    () async {
      final started = Completer<void>();
      final uploading = Completer<void>();
      upload = (token) async {
        uploaded.add(token);
        if (token == 'current') {
          started.complete();
          await uploading.future;
        }
      };
      final refresh = registration.refresh();
      await started.future;
      currentToken = 'latest';
      updates.add('stale event payload');
      uploading.complete();
      await refresh;
      expect(uploaded, ['current', 'latest']);
      expect(saved.last, 'latest');
    },
  );

  test('a failed upload does not block later registration attempts', () async {
    upload = (_) async => throw StateError('offline');
    await expectLater(registration.refresh(), throwsStateError);
    upload = (token) async => uploaded.add(token);
    await registration.refresh();
    expect(uploaded, ['current']);
    expect(saved, ['current', 'current']);
  });

  test(
    'offline refresh persists the token for a later authenticated attempt',
    () async {
      authenticated = false;
      await registration.refresh();
      expect(saved, ['current']);
      expect(uploaded, isEmpty);
      authenticated = true;
      await registration.refresh();
      expect(uploaded, ['current']);
    },
  );

  test('a stalled SDK read times out and its late token is ignored', () async {
    final stalled = Completer<String?>();
    read = () => stalled.future;
    final timeout = expectLater(
      registration.refresh(),
      throwsA(isA<TimeoutException>()),
    );
    await timeout;
    stalled.complete('retired');
    read = () async => 'recovered';
    await registration.refresh();
    expect(saved, ['recovered']);
    expect(uploaded, ['recovered']);
  });

  test(
    'an incomplete deletion releases recovery and retains the saved token',
    () async {
      await registration.refresh();
      final stalled = Completer<void>();
      remove = () => stalled.future;
      final timeout = expectLater(
        registration.reset(),
        throwsA(isA<TimeoutException>()),
      );
      await timeout;
      expect(saved, ['current']);
      stalled.complete();
      currentToken = 'recovered';
      await registration.refresh();
      expect(uploaded, ['current', 'recovered']);
    },
  );
}
