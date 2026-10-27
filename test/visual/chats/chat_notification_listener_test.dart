import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/chat_notification_listener.dart';

import '../../mocks/database_watch.dart';

class _NotificationApi implements RustLibApi {
  late StreamController<List<String>> changes;
  final cleared = <String>[];
  Completer<void>? pendingClear;

  @override
  DatabaseWatch crateBridgeDatabaseDatabaseWatchNew() => TestDatabaseWatch();

  @override
  Stream<List<String>> crateBridgeWrapperAppDatabaseRustAppDatabaseChanges({
    required DatabaseWatch control,
  }) => changes.stream;

  @override
  Future<List<String>> crateBridgeApiRustApiClearConversationNotifications({
    required String conversationId,
  }) async {
    cleared.add(conversationId);
    await pendingClear?.future;
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final api = _NotificationApi();
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);
  setUp(() {
    api
      ..changes = StreamController<List<String>>.broadcast(sync: true)
      ..cleared.clear()
      ..pendingClear = null;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
  tearDown(() async => api.changes.close());

  Widget chat(String id) => ChatNotificationListener(
    conversationId: id,
    child: const Scaffold(body: Text('Chat')),
  );

  for (final id in ['direct', 'group']) {
    testWidgets('$id clears activity arriving after the chat opened', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: chat(id)));
      await tester.pumpAndSettle();
      expect(api.cleared, [id]);

      api.changes.add(['reactions']);
      await tester.pump();
      expect(api.cleared, [id]);

      // Recording the reaction touches the outbox even if the message was
      // already read and its message stream does not emit another value.
      api.changes.add(['reactions', 'notification_outbox']);
      await tester.pump();
      expect(api.cleared, [id, id]);

      api.changes.add([]); // Reconnected or missed commit notifications.
      await tester.pump();
      expect(api.cleared, [id, id, id]);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(api.changes.hasListener, isFalse);
      api.changes.add(['notification_outbox']);
      await tester.pump();
      expect(api.cleared, hasLength(3));
    });
  }

  testWidgets('only the foreground chat clears alerts and clears on return', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: chat('direct')),
    );
    await tester.pumpAndSettle();
    api.cleared.clear();

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    api.changes.add(['notification_outbox']);
    await tester.pump();
    expect(api.cleared, isEmpty);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(api.cleared, ['direct']);

    final pushed = navigator.currentState!.push<void>(
      MaterialPageRoute(builder: (_) => chat('group')),
    );
    await tester.pumpAndSettle();
    api.cleared.clear();
    api.changes.add(['notification_outbox']);
    await tester.pump();
    expect(api.cleared, ['group']);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    await pushed;
    expect(api.cleared.last, 'direct');
    api.cleared.clear();
    api.changes.add(['notification_outbox']);
    await tester.pump();
    expect(api.cleared, ['direct']);
  });

  testWidgets('arrivals during an ongoing clear get a second pass', (
    tester,
  ) async {
    api.pendingClear = Completer<void>();
    await tester.pumpWidget(MaterialApp(home: chat('group')));
    expect(api.cleared, ['group']);
    api.changes
      ..add(['notification_outbox'])
      ..add(['notification_outbox']);
    await tester.pump();
    expect(api.cleared, ['group']);
    api.pendingClear!.complete();
    await tester.pump();
    expect(api.cleared, ['group', 'group']);
  });
}
