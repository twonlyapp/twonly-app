import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twonly/core/bridge/database/stickers.dart' as rust_stickers;
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/core/services/avatars.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/visual/components/sticker_picker.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/memories/sticker_source_picker.view.dart';
import 'package:twonly/src/visual/views/settings/profile/modify_avatar.view.dart';

import '../../helpers/native_database.dart';
import '../../mocks/user_config.dart';

class _AvatarApi extends NativeTestApi {
  Uint8List? stickerInput;
  String? photoInput;
  bool? audience;

  @override
  Future<CustomAvatarInfo> crateBridgeApiRustApiGetCustomAvatar() async =>
      const CustomAvatarInfo(acceptedContactsOnly: false, sourceRevision: 0);

  @override
  Future<CustomAvatarInfo> crateBridgeApiRustApiCreateCustomAvatarFromSticker({
    required List<int> webp,
    required bool acceptedContactsOnly,
  }) async {
    stickerInput = Uint8List.fromList(webp);
    audience = acceptedContactsOnly;
    return CustomAvatarInfo(
      webp: stickerInput,
      acceptedContactsOnly: acceptedContactsOnly,
      sourceRevision: 1,
    );
  }

  @override
  Future<CustomAvatarInfo> crateBridgeApiRustApiCreateCustomAvatar({
    required String imagePath,
    required bool acceptedContactsOnly,
  }) async {
    photoInput = imagePath;
    audience = acceptedContactsOnly;
    return CustomAvatarInfo(
      webp: File(imagePath).readAsBytesSync(),
      acceptedContactsOnly: acceptedContactsOnly,
      sourceRevision: 1,
    );
  }
}

void main() {
  final api = _AvatarApi();
  final image = File('assets/images/default_avatar.png').readAsBytesSync();

  setUpAll(() async {
    AppEnvironment.initTesting();
    await initializeNativeDatabase(api: api);
  });
  tearDownAll(RustLib.dispose);
  setUp(() async {
    api
      ..stickerInput = null
      ..photoInput = null
      ..audience = null;
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    await TestDatabase.create();
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

  Future<void> openAvatar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 700);
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
    await pumpNative(tester);
    await tester.ensureVisible(find.widgetWithText(MyButton, 'Stickers'));
    await tester.pumpAndSettle();
  }

  Future<void> disposeAvatar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpNative(tester);
  }

  testWidgets('avatar buttons share a row and saved sticker uses its cutout', (
    tester,
  ) async {
    await runNative(
      tester,
      () => rust_stickers.saveSticker(
        webp: image,
        width: 1,
        height: 1,
        transaction: currentDatabaseSession(),
      ),
    );
    await openAvatar(tester);
    final stickersButton = find.widgetWithText(MyButton, 'Stickers');
    final photoButton = find.widgetWithText(MyButton, 'Choose photo');
    expect(
      tester.getCenter(stickersButton).dy,
      tester.getCenter(photoButton).dy,
    );
    await tester.tap(stickersButton);
    await pumpNative(tester);
    expect(find.byType(StickerPicker), findsOneWidget);
    expect(find.text('Emoji'), findsNothing);
    await tester.tap(find.byKey(ValueKey(sha256.convert(image).toString())));
    await pumpNative(tester);
    expect(api.stickerInput, image);
    expect(api.photoInput, isNull);
    expect(api.audience, isFalse);
    expect(find.byType(StickerPicker), findsNothing);
    expect(find.widgetWithText(MyButton, 'Remove'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeAvatar(tester);
  });

  testWidgets(
    'photo opens shared Memories picker with Gallery and can cancel',
    (
      tester,
    ) async {
      await openAvatar(tester);
      await tester.tap(find.widgetWithText(MyButton, 'Choose photo'));
      await pumpNative(tester);
      final source = find.byType(StickerSourcePickerView);
      expect(source, findsOneWidget);
      expect(tester.widget<StickerSourcePickerView>(source).forAvatar, isTrue);
      expect(find.text('Gallery'), findsOneWidget);
      await tester.pageBack();
      await pumpNative(tester);
      expect(api.photoInput, isNull);
      expect(api.stickerInput, isNull);
      await tester.tap(find.widgetWithText(MyButton, 'Choose photo'));
      await pumpNative(tester);
      Navigator.of(tester.element(source)).pop(
        File('assets/images/default_avatar.png').absolute.path,
      );
      await pumpNative(tester);
      expect(api.photoInput, endsWith('default_avatar.png'));
      expect(api.stickerInput, isNull);
      expect(api.audience, isFalse);
      expect(find.widgetWithText(MyButton, 'Change photo'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeAvatar(tester);
    },
  );
}
