import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/src/services/webxdc/webxdc_host.dart';
import 'package:twonly/src/utils/database_values.dart';

import '../helpers/native_database.dart';

class _WarmUpApi extends NativeTestApi {
  int reads = 0;
  bool failRead = false;

  @override
  Future<bool> crateBridgeDatabaseWebxdcHasRecentWebxdcMessages({
    required int since,
    required DatabaseSession transaction,
  }) {
    reads++;
    if (failRead) throw StateError('Database unavailable');
    return super.crateBridgeDatabaseWebxdcHasRecentWebxdcMessages(
      since: since,
      transaction: transaction,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('eu.twonly/webxdc');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final api = _WarmUpApi();
  final now = DateTime.utc(2026, 10, 30, 12);
  final calls = <MethodCall>[];

  Future<void> warmUp() => withClock(
    Clock.fixed(now),
    WebxdcHost.warmUpForRecentGames,
  );

  Future<void> insertGame(
    DateTime activity, {
    bool deleted = false,
    bool hasInstance = true,
  }) async {
    await testDatabase.customStatement(
      '''
         INSERT INTO messages(group_id, message_id, type, created_at, is_deleted_from_sender)
         VALUES ('chat', 'game', 'webxdcApp', ?, ?)''',
      [databaseSeconds(activity), deleted],
    );
    if (hasInstance) {
      await testDatabase.customStatement(
        '''
           INSERT INTO webxdc_instances(instance_id, group_id, app_id, version, origin_token, created_at)
           VALUES ('game', 'chat', 'arbitrary-game', 1, 'origin', ?)''',
        [databaseSeconds(now.subtract(const Duration(days: 7)))],
      );
    }
  }

  setUpAll(() => initializeNativeDatabase(api: api));
  tearDownAll(RustLib.dispose);
  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    api
      ..reads = 0
      ..failRead = false;
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    await TestDatabase.create();
    await testDatabase.customStatement(
      "INSERT INTO groups(group_id, group_name) VALUES ('chat', 'Chat')",
    );
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'warms for a recent game even when newer messages are ordinary text',
    () async {
      await insertGame(now.subtract(const Duration(hours: 23)));
      await testDatabase.customStatement(
        '''
         INSERT INTO messages(group_id, message_id, type, content, created_at)
         VALUES ('chat', 'newer-text', 'text', 'Hello', ?)''',
        [databaseSeconds(now)],
      );

      await warmUp();

      expect(calls.map((call) => call.method), ['warmUp']);
    },
  );

  for (final seconds in [0, 1]) {
    test(
      '24-hour cutoff ${seconds == 0 ? 'includes its boundary' : 'excludes older games'}',
      () async {
        await insertGame(
          now.subtract(Duration(hours: 24, seconds: seconds)),
        );

        await warmUp();

        expect(calls, hasLength(seconds == 0 ? 1 : 0));
      },
    );
  }

  test('does not warm without a game in the messages', () async {
    await warmUp();
    expect(calls, isEmpty);
  });

  test('does not warm for a deleted game', () async {
    await insertGame(now, deleted: true);
    await warmUp();
    expect(calls, isEmpty);
  });

  test('does not warm for a card whose instance is gone', () async {
    await insertGame(now, hasInstance: false);
    await warmUp();
    expect(calls, isEmpty);
  });

  test('skips both the database and runtime on iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await insertGame(now);
    await warmUp();
    expect(api.reads, 0);
    expect(calls, isEmpty);
  });

  test('a database failure does not fail background startup', () async {
    api.failRead = true;
    await warmUp();
    expect(api.reads, 1);
    expect(calls, isEmpty);
  });

  test('a native warm-up failure does not fail background startup', () async {
    await insertGame(now);
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'unavailable');
    });
    await warmUp();
  });
}
