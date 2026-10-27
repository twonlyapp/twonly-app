import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/app.dart';
import 'package:twonly/core/bridge/database.dart';
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/services/api/api.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/views/unlock_twonly.view.dart';

import '../mocks/user_config.dart';

class _Session implements DatabaseSession {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StartupApi implements RustLibApi {
  late Future<int> Function() readCount;
  int attempts = 0;

  @override
  DatabaseSession crateBridgeDatabaseDatabaseSessionNew() => _Session();

  @override
  Future<int> crateBridgeDatabaseContactsCountContacts({
    required ContactCount metric,
    required DatabaseSession transaction,
  }) {
    attempts++;
    return readCount();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ApiService implements ApiService {
  @override
  ApiEventKind? get permanentRejection => null;

  @override
  Stream<ApiEvent> get events => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final api = _StartupApi();
  late Directory directory;

  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);
  setUp(() async {
    await locator.reset();
    directory = Directory.systemTemp.createTempSync('twonly-startup-');
    AppEnvironment.initTesting(
      customCacheDir: directory.path,
      customSupportDir: directory.path,
    );
    final user = testUserConfig(
      userId: 1,
      username: 'me',
      displayName: 'Me',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
      appVersion: 194,
    )..screenLockEnabled = true;
    locator.registerSingleton<UserService>(
      UserService()
        ..isUserCreated = true
        ..currentUser = user,
    );
    api.attempts = 0;
    locator.registerSingleton<ApiService>(_ApiService());
    for (final name in [
      'com.llfbandit.app_links/events',
      'flutter_sharing_intent/events-sharing',
      'flutter_sharing_intent',
    ]) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
  });
  tearDown(() async {
    await locator.reset();
    directory.deleteSync(recursive: true);
  });

  Widget app() => const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AppMainWidget(initialPage: 1),
  );

  testWidgets('failed screen initialization can be retried successfully', (
    tester,
  ) async {
    api.readCount = () async => throw StateError('database read failed');
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.byType(FilledButton), findsOneWidget);
    expect(api.attempts, 1);
    expect(tester.takeException(), isNull);

    final pending = Completer<int>();
    api.readCount = () => pending.future;
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(1);
    await tester.pumpAndSettle();
    expect(api.attempts, 2);
    expect(find.byType(UnlockTwonlyView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stalled initialization times out and ignores its late result', (
    tester,
  ) async {
    final pending = Completer<int>();
    api.readCount = () => pending.future;
    await tester.pumpWidget(app());
    await tester.pump();
    expect(api.attempts, 1);
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();
    expect(find.byType(FilledButton), findsOneWidget);
    pending.complete(1);
    await tester.pumpAndSettle();
    expect(find.byType(UnlockTwonlyView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initialization finishing after disposal does not update state', (
    tester,
  ) async {
    final pending = Completer<int>();
    api.readCount = () => pending.future;
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(1);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
