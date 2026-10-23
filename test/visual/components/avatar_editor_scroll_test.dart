import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/core/services/avatars.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/views/settings/profile/modify_avatar.view.dart';

import '../../mocks/user_config.dart';

class _AvatarApi implements RustLibApi {
  @override
  Future<CustomAvatarInfo> crateBridgeApiRustApiGetCustomAvatar() async =>
      const CustomAvatarInfo(acceptedContactsOnly: true, sourceRevision: 0);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => RustLib.initMock(api: _AvatarApi()));
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
  });
  tearDown(() async => locator.reset());

  testWidgets(
    'compact editor keeps category icons small and updates the preview',
    (tester) async {
      tester.view.physicalSize = const Size(360, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ModifyAvatarView(),
        ),
      );
      await tester.pumpAndSettle();
      // MyButton absorbs its child's hit tests and handles taps on the wrapper.
      await tester.tapAt(tester.getCenter(find.text('Customize')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final customizer = tester.widget<AvatarMakerCustomizer>(
        find.byType(AvatarMakerCustomizer),
      );
      expect(
        tester.getSize(find.byType(AvatarMakerCustomizer)),
        const Size(342, 240),
      );
      final categoryIcons = find.descendant(
        of: find.byType(TabBar),
        matching: find.byType(SvgPicture),
      );
      expect(categoryIcons, findsNWidgets(12));
      for (final icon in categoryIcons.evaluate()) {
        expect(tester.getSize(find.byWidget(icon.widget)).height, 24);
      }
      final controller = customizer.controller!;
      final initialSvg = controller.displayedAvatarSVG;
      final option = find
          .descendant(
            of: find.byType(GridView).first,
            matching: find.byType(InkWell),
          )
          .first;
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      await tester.tap(
        option,
      );
      await tester.pumpAndSettle();
      expect(controller.displayedAvatarSVG, isNot(initialSvg));
      await tester.ensureVisible(find.byType(AvatarMakerAvatar));
      await tester.pumpAndSettle();
      final preview = tester.widget<SvgPicture>(
        find.descendant(
          of: find.byType(AvatarMakerAvatar),
          matching: find.byType(SvgPicture),
        ),
      );
      expect(
        preview.bytesLoader,
        SvgStringLoader(controller.displayedAvatarSVG),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
