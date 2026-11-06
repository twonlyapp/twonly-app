import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';

import '../../mocks/database_watch.dart';
import '../../mocks/user_config.dart';

class _AvatarApi implements RustLibApi {
  String? path;
  Exception? error;
  int attempts = 0;
  late StreamController<List<String>> changes;

  @override
  DatabaseWatch crateBridgeDatabaseDatabaseWatchNew() => TestDatabaseWatch();

  @override
  Stream<List<String>> crateBridgeWrapperAppDatabaseRustAppDatabaseChanges({
    required DatabaseWatch control,
  }) => changes.stream;

  @override
  Future<String?> crateBridgeApiRustApiCurrentUserAvatarPath() async {
    attempts++;
    if (error case final error?) throw error;
    return path;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final api = _AvatarApi();
  final photoPath = File('assets/images/default_avatar.png').absolute.path;

  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() async {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await locator.reset();
    locator.registerSingleton<UserService>(UserService());
    userService.currentUser = testUserConfig(
      userId: 1,
      username: 'me',
      displayName: 'Me',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
      appVersion: 100,
    );
    api
      ..path = null
      ..error = null
      ..attempts = 0
      ..changes = StreamController<List<String>>.broadcast();
  });

  tearDown(() async {
    await api.changes.close();
    await locator.reset();
  });

  Future<void> pumpAvatar(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AvatarIcon(myAvatar: true)),
    );
    await tester.pump();
  }

  void expectPhoto(WidgetTester tester) {
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as FileImage).file.path, photoPath);
    expect(find.byType(SvgPicture), findsNothing);
  }

  testWidgets('shows a photo avatar without a public SVG avatar', (
    tester,
  ) async {
    api.path = photoPath;
    await pumpAvatar(tester);
    expectPhoto(tester);
  });

  testWidgets('refreshes when a photo-only avatar is added or removed', (
    tester,
  ) async {
    await pumpAvatar(tester);
    expect(find.byType(SvgPicture), findsOneWidget);

    api.path = photoPath;
    api.changes.add(['own_custom_avatar']);
    await tester.pump();
    await tester.pump();
    expectPhoto(tester);

    api.path = null;
    api.changes.add(['own_custom_avatar']);
    await tester.pump();
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('retries a temporarily unavailable own avatar', (tester) async {
    api.error = AnyhowException('Try again (os error 11)');
    await pumpAvatar(tester);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(api.attempts, 1);

    api
      ..error = null
      ..path = photoPath;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(api.attempts, 2);
    expectPhoto(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('avatar retries pause in the background and recover on resume', (
    tester,
  ) async {
    api.error = AnyhowException('Try again (os error 11)');
    await pumpAvatar(tester);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    expect(api.attempts, 1);

    api
      ..error = null
      ..path = photoPath;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expectPhoto(tester);
  });

  testWidgets('disposing an avatar cancels its pending retry', (tester) async {
    api.error = AnyhowException('Try again (os error 11)');
    await pumpAvatar(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
    expect(api.attempts, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed refresh keeps the displayed avatar while retrying', (
    tester,
  ) async {
    api.path = photoPath;
    await pumpAvatar(tester);
    expectPhoto(tester);

    api.error = AnyhowException('Try again (os error 11)');
    api.changes.add(['own_custom_avatar']);
    await tester.pump();
    expectPhoto(tester);

    api.error = null;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expectPhoto(tester);
  });

  testWidgets('persistent resource errors stop retrying after five retries', (
    tester,
  ) async {
    api.error = AnyhowException('Try again (os error 11)');
    await pumpAvatar(tester);
    for (final seconds in [1, 2, 4, 8, 16]) {
      await tester.pump(Duration(seconds: seconds));
      await tester.pump();
    }
    expect(api.attempts, 6);
    await tester.pump(const Duration(minutes: 1));
    expect(api.attempts, 6);
    expect(tester.takeException(), isNull);
  });
}
