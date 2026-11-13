import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twonly/app.dart';
import 'package:twonly/core/bridge/database.dart';
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/json/onboarding_state.model.dart';
import 'package:twonly/src/services/api/api.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/onboarding/onboarding.view.dart';
import 'package:twonly/src/visual/views/onboarding/register.view.dart';
import 'package:twonly/src/visual/views/unlock_twonly.view.dart';

import '../mocks/user_config.dart';

class _Session implements DatabaseSession {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StartupApi implements RustLibApi {
  late Future<int> Function() readCount;
  int attempts = 0;
  int credentialRemovals = 0;

  @override
  Future<void>
  crateBridgeWrapperKeyManagerRustKeyManagerRemoveLocalCredentials() async {
    credentialRemovals++;
  }

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
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
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
    api
      ..attempts = 0
      ..credentialRemovals = 0;
    SharedPreferences.setMockInitialValues({});
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

  testWidgets(
    'registration clears old files and restarts before opening its form',
    (tester) async {
      userService.isUserCreated = false;
      final oldFile = File('${directory.path}/old-account-photo.jpg')
        ..writeAsStringSync('old account');
      var restarts = 0;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => directory.path,
      );
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('restart'),
        (_) async {
          restarts++;
          expect(oldFile.existsSync(), isFalse);
          expect(api.credentialRemovals, 1);
          return 'ok';
        },
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(app());
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(RegisterView), findsNothing);
      await tester.runAsync(() async {
        tester.widget<OnboardingView>(find.byType(OnboardingView)).onRegister();
        for (var attempt = 0; attempt < 100 && restarts == 0; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pump();
      expect(restarts, 1);
      expect(find.byType(RegisterView), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a fresh process consumes the registration request and opens its form',
    (tester) async {
      userService.isUserCreated = false;
      await tester.runAsync(() async {
        await KeyValueStore.putAtomically(
          KeyValueKeys.onboardingState,
          OnboardingState(openRegistration: true).toJson(),
        );
        await tester.pumpWidget(app());
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(RegisterView), findsOneWidget);
      expect(api.credentialRemovals, 0);
      expect(
        File(
          '${directory.path}/keyvalue/${KeyValueKeys.onboardingState}.json',
        ).existsSync(),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
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
    // The retry goes back to the splash screen while it loads.
    expect(find.byType(FilledButton), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == defaultPrimaryColor,
      ),
      findsOneWidget,
    );
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

  testWidgets('startup recovers from temporary SQLite contention', (
    tester,
  ) async {
    api.readCount = () async {
      if (api.attempts < 3) {
        throw AnyhowException(
          'error returned from database: (code: 5) database is locked',
        );
      }
      return 1;
    };
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(api.attempts, 3);
    expect(find.byType(UnlockTwonlyView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('persistent SQLite contention still offers a manual retry', (
    tester,
  ) async {
    api.readCount = () async => throw AnyhowException(
      'error returned from database: (code: 5) database is locked',
    );
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(api.attempts, 3);
    expect(find.byType(FilledButton), findsOneWidget);
    api.readCount = () async => 1;
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(UnlockTwonlyView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pending SQLite retry stops when startup is backgrounded', (
    tester,
  ) async {
    api.readCount = () async => throw AnyhowException(
      'error returned from database: (code: 5) database is locked',
    );
    await tester.pumpWidget(app());
    await tester.pump();
    expect(api.attempts, 1);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 1));
    expect(api.attempts, 1);
    api.readCount = () async => 1;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(api.attempts, 2);
    expect(find.byType(UnlockTwonlyView), findsOneWidget);
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

  testWidgets(
    'backgrounding startup defers its timeout and retries on resume',
    (
      tester,
    ) async {
      final pending = Completer<int>();
      api.readCount = () => pending.future;
      await tester.pumpWidget(app());
      await tester.pump();
      expect(api.attempts, 1);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 11));
      await tester.pump();
      expect(find.byType(FilledButton), findsNothing);
      expect(tester.takeException(), isNull);

      api.readCount = () async => 1;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(api.attempts, 2);
      expect(find.byType(UnlockTwonlyView), findsOneWidget);

      // The retired attempt cannot replace the successfully initialized route.
      pending.complete(0);
      await tester.pumpAndSettle();
      expect(find.byType(UnlockTwonlyView), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('startup created in the background waits until resume', (
    tester,
  ) async {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    api.readCount = () async => 1;
    await tester.pumpWidget(app());
    await tester.pump(const Duration(seconds: 11));
    expect(api.attempts, 0);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(api.attempts, 1);
    expect(find.byType(UnlockTwonlyView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
