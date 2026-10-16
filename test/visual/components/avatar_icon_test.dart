import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';

import '../../mocks/user_config.dart';

class _AvatarApi implements RustLibApi {
  String? path;

  @override
  Future<String?> crateBridgeApiRustApiCurrentUserAvatarPath() async => path;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final api = _AvatarApi();
  final photoPath = File('assets/images/default_avatar.png').absolute.path;

  setUpAll(() => RustLib.initMock(api: api));
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
    );
    api.path = null;
  });

  tearDown(() async {
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
    userService.triggerUserUpdate();
    await tester.pump();
    await tester.pump();
    expectPhoto(tester);

    api.path = null;
    userService.triggerUserUpdate();
    await tester.pump();
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(find.byType(SvgPicture), findsOneWidget);
  });
}
