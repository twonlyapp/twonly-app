import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/bridge/live_location.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/live_location.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/bottom_sheets/share_location.bottom_sheet.dart';

import '../helpers/native_database.dart';
import '../mocks/user_config.dart';

class _LocationApi extends NativeTestApi {
  final events = <String>[];
  LiveLocationSession? current;
  List<String>? groups;
  int? duration;
  String? title;

  @override
  Future<LiveLocationSession?>
  crateBridgeLiveLocationLiveLocationState() async => current;

  @override
  Future<LiveLocationSession> crateBridgeLiveLocationStartLiveLocation({
    required List<String> groupIds,
    required int durationSeconds,
    required String text,
  }) async {
    events.add('persist-start');
    groups = groupIds;
    duration = durationSeconds;
    title = text;
    return current = LiveLocationSession(
      sessionId: 'session',
      expiresAtMs: DateTime.now().millisecondsSinceEpoch + 600000,
      groupIds: {...?current?.groupIds, ...groupIds}.toList(),
    );
  }

  @override
  Future<void> crateBridgeLiveLocationStopLiveLocation({
    required String sessionId,
  }) async {
    events.add('persist-stop:$sessionId');
    current = null;
  }

  @override
  Future<void> crateBridgeLiveLocationStopLiveLocationInChat({
    required String sessionId,
    required String groupId,
  }) async {
    events.add('persist-stop-chat:$groupId');
    final session = current;
    if (session == null || session.sessionId != sessionId) return;
    final remaining = session.groupIds
        .where((group) => group != groupId)
        .toList();
    current = remaining.isEmpty
        ? null
        : LiveLocationSession(
            sessionId: session.sessionId,
            expiresAtMs: session.expiresAtMs,
            groupIds: remaining,
          );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const location = MethodChannel('eu.twonly/location_metadata');
  const permissions = MethodChannel('flutter.baseflow.com/permissions/methods');
  final api = _LocationApi();
  var precise = true;
  var notifications = true;
  var nativeStarts = true;
  final nativeCalls = <MethodCall>[];

  setUpAll(() => initializeNativeDatabase(api: api));
  tearDownAll(RustLib.dispose);
  setUp(() async {
    await locator.reset();
    locator.registerSingleton<UserService>(UserService());
    userService.currentUser = testUserConfig(
      userId: 1,
      username: 'me',
      displayName: 'Me',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
      appVersion: 100,
    )..language = 'en';
    AppEnvironment.initTesting();
    api
      ..events.clear()
      ..current = null
      ..groups = null
      ..duration = null;
    precise = true;
    notifications = true;
    nativeStarts = true;
    nativeCalls.clear();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(location, (
      call,
    ) async {
      nativeCalls.add(call);
      switch (call.method) {
        case 'requestPrecisePermission':
          return precise;
        case 'startLiveLocation':
          api.events.add('native-start');
          return nativeStarts;
        case 'stopLiveLocation':
          api.events.add('native-stop');
          return true;
      }
      throw MissingPluginException(call.method);
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(permissions, (
      call,
    ) async {
      if (call.method == 'requestPermissions') {
        return {17: notifications ? 1 : 0};
      }
      throw MissingPluginException(call.method);
    });
  });
  tearDown(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(location, null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(permissions, null);
    await locator.reset();
  });

  Future<void> start() => LiveLocationService.start(
    groupId: 'chat-a',
    durationSeconds: 7200,
    title: 'Live location',
    body: 'Sharing with your chats',
    stopLabel: 'Stop sharing',
  );

  test(
    'starts sharing only in the current chat and passes its deadline to native',
    () async {
      await start();
      expect(api.groups, ['chat-a']);
      expect(api.duration, 7200);
      expect(api.title, 'Live location');
      expect(api.events, ['persist-start', 'native-start']);
      final args = nativeCalls.last.arguments as Map;
      expect(args['session_id'], api.current!.sessionId);
      expect(args['expires_at_ms'], api.current!.expiresAtMs);
      expect(args['directory'], AppEnvironment.supportDir);
      expect(args['stop'], 'Stop sharing');
    },
  );

  test(
    'denied precise permission never starts sharing or asks for notifications',
    () async {
      precise = false;
      await expectLater(start(), throwsA(isA<PlatformException>()));
      expect(api.events, isEmpty);
      expect(nativeCalls.map((call) => call.method), [
        'requestPrecisePermission',
      ]);
    },
  );

  test('denied notification permission never creates a share', () async {
    notifications = false;
    await expectLater(start(), throwsA(isA<PlatformException>()));
    expect(api.events, isEmpty);
  });

  test('failed native start stops the persisted session', () async {
    nativeStarts = false;
    await expectLater(start(), throwsA(isA<PlatformException>()));
    expect(api.events, [
      'persist-start',
      'native-start',
      'persist-stop-chat:chat-a',
    ]);
    expect(api.current, isNull);
  });

  test(
    'stopping persists the terminal state before releasing the OS worker',
    () async {
      await LiveLocationService.stop('session');
      expect(api.events, ['persist-stop:session', 'native-stop']);
      expect((nativeCalls.single.arguments as Map)['session_id'], 'session');
    },
  );

  test(
    'failed additional-chat start preserves the existing chat share',
    () async {
      api.current = LiveLocationSession(
        sessionId: 'session',
        expiresAtMs: DateTime.now().millisecondsSinceEpoch + 600000,
        groupIds: ['chat-b'],
      );
      nativeStarts = false;
      await expectLater(start(), throwsA(isA<PlatformException>()));
      expect(api.current!.groupIds, ['chat-b']);
      expect(api.events.last, 'persist-stop-chat:chat-a');
    },
  );

  test(
    'stopping in one chat keeps the worker running for the other chat',
    () async {
      api.current = LiveLocationSession(
        sessionId: 'session',
        expiresAtMs: DateTime.now().millisecondsSinceEpoch + 600000,
        groupIds: ['chat-a', 'chat-b'],
      );
      await LiveLocationService.stopInChat('session', 'chat-a');
      expect(api.current!.groupIds, ['chat-b']);
      expect(api.events, ['persist-stop-chat:chat-a', 'native-start']);
      await LiveLocationService.stopInChat('session', 'chat-b');
      expect(api.current, isNull);
      expect(api.events.last, 'native-stop');
    },
  );

  Future<Group> chat() async {
    final db = await TestDatabase.create();
    await db.insert(
      const GroupPatch(groupId: 'chat-a', groupName: 'Chat A'),
    );
    final group = (await rust_groups.getGroup(
      id: 'chat-a',
      transaction: currentDatabaseSession(),
    ))!;

    return group;
  }

  Future<void> showSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ShareLocationView(group: await runNative(tester, chat)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the sheet shows durations without any chat selector', (
    tester,
  ) async {
    await showSheet(tester);
    expect(find.byType(ChoiceChip), findsNWidgets(5));
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.byType(ListView), findsNothing);
    expect(find.text('Start sharing'), findsOneWidget);
  });

  testWidgets('a share in another chat leaves Start sharing available', (
    tester,
  ) async {
    api.current = LiveLocationSession(
      sessionId: 'session',
      expiresAtMs: DateTime.now().millisecondsSinceEpoch + 600000,
      groupIds: ['chat-b'],
    );
    await showSheet(tester);
    expect(find.text('Start sharing'), findsOneWidget);
    await tester.tap(
      find.ancestor(
        of: find.text('Start sharing'),
        matching: find.byType(MyButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(api.groups, ['chat-a']);
    expect(api.current!.groupIds.toSet(), {'chat-a', 'chat-b'});
  });

  testWidgets('an existing share in this chat offers a Stop control', (
    tester,
  ) async {
    api.current = LiveLocationSession(
      sessionId: 'session',
      expiresAtMs: DateTime.now().millisecondsSinceEpoch + 600000,
      groupIds: ['chat-a', 'chat-b'],
    );
    await showSheet(tester);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Start sharing'), findsNothing);
    await tester.tap(
      find.ancestor(
        of: find.text('Stop sharing'),
        matching: find.byType(MyButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(api.current!.groupIds, ['chat-b']);
    expect(find.text('Start sharing'), findsOneWidget);
  });

  test('startup without a share never touches native location', () async {
    await LiveLocationService.restore();
    expect(nativeCalls, isEmpty);
  });

  test(
    'startup restores an existing session without another permission request',
    () async {
      api.current = LiveLocationSession(
        sessionId: 'restored',
        expiresAtMs: DateTime.now().millisecondsSinceEpoch + 600000,
        groupIds: ['chat-a'],
      );
      await LiveLocationService.restore();
      expect(nativeCalls.map((call) => call.method), ['startLiveLocation']);
      expect((nativeCalls.single.arguments as Map)['session_id'], 'restored');
    },
  );

  test(
    'failed restoration ends the share instead of leaving an active card',
    () async {
      api.current = const LiveLocationSession(
        sessionId: 'restored',
        expiresAtMs: 1,
        groupIds: ['chat-a'],
      );
      nativeStarts = false;
      await LiveLocationService.restore();
      expect(api.events, ['native-start', 'persist-stop:restored']);
      expect(api.current, isNull);
    },
  );

  List<int> encode(LiveLocationData data) => AdditionalMessageData(
    type: AdditionalMessageData_Type.LIVE_LOCATION,
    liveLocation: data,
  ).writeToBuffer();

  test('decodes waiting, current-point and stopped text-message metadata', () {
    final data = LiveLocationData(
      sessionId: 'session',
      messageId: 'message',
      expiresAtMs: Int64(1000),
      updatedAtMs: Int64(1),
    );
    expect(LiveLocationService.decode(encode(data))!.hasLatitude(), isFalse);
    data
      ..latitude = 52.52
      ..longitude = 13.405
      ..accuracy = 8
      ..fixTimestampMs = Int64(1);
    expect(LiveLocationService.decode(encode(data))!.latitude, 52.52);
    data.stopped = true;
    expect(LiveLocationService.decode(encode(data))!.stopped, isTrue);
  });

  test('malformed and incomplete coordinates never reach the map', () {
    expect(LiveLocationService.decode(null), isNull);
    expect(LiveLocationService.decode([255]), isNull);
    expect(
      LiveLocationService.decode(AdditionalMessageData().writeToBuffer()),
      isNull,
    );
    final data = LiveLocationData(
      sessionId: 'session',
      messageId: 'message',
      expiresAtMs: Int64(1000),
      latitude: 52.52,
    );
    expect(LiveLocationService.decode(encode(data)), isNull);
    data.longitude = 181;
    expect(LiveLocationService.decode(encode(data)), isNull);
    data
      ..longitude = 13.4
      ..latitude = double.nan;
    expect(LiveLocationService.decode(encode(data)), isNull);
  });
}
