import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twonly/core/bridge/database/stickers.dart' as rust_stickers;
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/database/app/stickers/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/core/services/stickers.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/stickers/sticker.service.dart';
import 'package:twonly/src/services/stickers/sticker_cache.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/visual/components/emoji_picker.bottom.dart';
import 'package:twonly/src/visual/components/emoji_picker/emoji_picker.dart';
import 'package:twonly/src/visual/components/location_sticker.dart';
import 'package:twonly/src/visual/components/sticker_picker.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_sticker.entry.dart';
import 'package:twonly/src/visual/views/memories/sticker_source_picker.view.dart';

import '../../helpers/native_database.dart';
import '../../mocks/user_config.dart';

// Rust tests exercise the real WebP codec; here a PNG-backed mock lets us test
// the complete dialog, database replacement and picker refresh.
class _StickerApi extends NativeTestApi {
  bool failRotation = false;
  final rotationInputs = <Uint8List>[];

  @override
  Future<StickerOutput> crateBridgeApiRustApiRotateSticker({
    required List<int> webp,
  }) async {
    rotationInputs.add(Uint8List.fromList(webp));
    if (failRotation) throw StateError('rotation failed');
    final rotated = img.copyRotate(
      img.decodeImage(Uint8List.fromList(webp))!,
      angle: 90,
    );
    final bytes = img.encodePng(rotated);
    final digest = sha256.convert(bytes);
    return StickerOutput(
      webp: bytes,
      sha256: Uint8List.fromList(digest.bytes),
      contentHash: digest.toString(),
      width: rotated.width,
      height: rotated.height,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// A small valid image for exercising image widgets; protocol codec validation
// and real transparent WebP inference are covered by the Rust sticker tests.
final Uint8List _image = File(
  'assets/images/default_avatar.png',
).readAsBytesSync();

StickerData _sticker() => StickerData(
  version: 1,
  webp: _image,
  sha256: sha256.convert(_image).bytes,
  width: 1,
  height: 1,
);

Widget _app(Widget child) => MaterialApp(
  theme: lightTheme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Align(alignment: Alignment.bottomCenter, child: child),
  ),
);

Future<void> _settle(WidgetTester tester) => pumpNative(tester);

void main() {
  late TestDatabase database;
  final api = _StickerApi();

  setUpAll(() async {
    AppEnvironment.initTesting();
    await initializeNativeDatabase(api: api);
  });
  tearDownAll(RustLib.dispose);

  setUp(() async {
    api
      ..failRotation = false
      ..rotationInputs.clear();
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    database = await TestDatabase.create();

    await database.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await locator.reset();
  });

  testWidgets('editor picker excludes location even when enabled in privacy', (
    tester,
  ) async {
    locator.registerSingleton<UserService>(UserService());
    userService
      ..isUserCreated = true
      ..currentUser = testUserConfig(
        userId: 1,
        username: 'me',
        displayName: 'Me',
        subscriptionPlan: 'Free',
        currentSetupPage: null,
        appVersion: 100,
      );
    userService.currentUser.enableLocationSticker = true;
    const channel = MethodChannel('eu.twonly/location_metadata');
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return null;
    });
    try {
      await tester.pumpWidget(
        _app(const EmojiPickerBottom(allowStickers: true)),
      );
      await _settle(tester);
      await tester.tap(find.text('Sticker'));
      await _settle(tester);
      expect(find.byType(StickerPicker), findsOneWidget);
      expect(find.byType(LocationSticker), findsNothing);
      expect(calls, isEmpty);
    } finally {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    }
  });

  testWidgets(
    'tabs and resized drag handle stay in place across picker modes',
    (tester) async {
      var showStickers = false;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              return EmojiPicker(
                alternateView: showStickers
                    ? StickerPicker(
                        onEmojiPressed: () =>
                            setState(() => showStickers = false),
                        onStickerSelected: (_) {},
                      )
                    : null,
                config: Config(
                  height: 300,
                  checkPlatformCompatibility: false,
                  bottomActionBarConfig: BottomActionBarConfig(
                    onStickerButtonPressed: () =>
                        setState(() => showStickers = true),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await _settle(tester);
      final container = find.byKey(const Key('emojiPickerResizableContainer'));
      final handle = find.byKey(const Key('emojiPickerDragHandle'));
      await tester.drag(handle, const Offset(0, -80));
      await _settle(tester);
      final height = tester.getSize(container).height;
      expect(height, greaterThan(300));
      final emojiRect = tester.getRect(find.text('Emoji'));
      final stickerRect = tester.getRect(find.text('Sticker'));
      final handleRect = tester.getRect(handle);
      await tester.tap(find.text('Sticker'));
      await _settle(tester);
      expect(tester.getRect(find.text('Emoji')), emojiRect);
      expect(tester.getRect(find.text('Sticker')), stickerRect);
      expect(tester.getRect(handle), handleRect);
      expect(tester.getSize(container).height, height);
      await tester.tap(find.text('Emoji'));
      await _settle(tester);
      expect(tester.getSize(container).height, height);
      expect(tester.getRect(handle), handleRect);
    },
  );

  testWidgets('scrolling the stickers expands the picker like the emoji', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        EmojiPicker(
          alternateView: StickerPicker(
            onEmojiPressed: () {},
            onStickerSelected: (_) {},
          ),
          config: const Config(
            height: 300,
            checkPlatformCompatibility: false,
            resizeConfig: ResizeConfig(expandOnScroll: true, maxHeight: 420),
          ),
        ),
      ),
    );
    await _settle(tester);
    final container = find.byKey(const Key('emojiPickerResizableContainer'));
    final grid = find.byType(GridView);
    final gesture = await tester.startGesture(tester.getCenter(grid));
    await gesture.moveBy(const Offset(0, -20));
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    expect(tester.getSize(container).height, greaterThan(300));
    expect(tester.getSize(container).height, lessThan(420));
    await gesture.moveBy(const Offset(0, -200));
    await tester.pump();
    expect(tester.getSize(container).height, 420);
    await gesture.up();
    await _settle(tester);
  });

  testWidgets('new sticker opens Memories with a Gallery option', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 300,
          child: StickerPicker(
            onEmojiPressed: () {},
            onStickerSelected: (_) {},
          ),
        ),
      ),
    );
    await _settle(tester);

    await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
    await _settle(tester);

    expect(find.byType(StickerSourcePickerView), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  });

  testWidgets('moves add action to the header once a sticker exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 300,
          child: StickerPicker(
            onEmojiPressed: () {},
            onStickerSelected: (_) {},
          ),
        ),
      ),
    );
    await _settle(tester);

    expect(find.byKey(const Key('stickerPickerEmptyAdd')), findsOneWidget);
    expect(find.byKey(const Key('stickerPickerHeaderAdd')), findsNothing);

    await tester.runAsync(() => StickerService.saveReceived(_sticker()));
    await _settle(tester);

    expect(find.byKey(const Key('stickerPickerEmptyAdd')), findsNothing);
    expect(find.byKey(const Key('stickerPickerHeaderAdd')), findsOneWidget);
  });

  testWidgets('chat tap previews without saving; buttons save then remove', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ChatStickerEntry(
          message: StoredMessage(
            groupId: 'group',
            messageId: 'message',
            senderId: 42,
            type: 'text',
            mediaStored: false,
            mediaReopened: false,
            isDeletedFromSender: false,
            isWidgetMedia: false,
            isStory: false,
            createdAtSeconds: databaseSeconds(DateTime.now()),
          ),
          sticker: _sticker(),
        ),
      ),
    );
    await _settle(tester);
    await tester.tap(find.byType(ChatStickerEntry));
    await _settle(tester);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Save sticker'), findsOneWidget);
    expect(find.text('Rotate sticker'), findsNothing);
    expect(
      await tester.runAsync(() => watchCachedStickers().first),
      isEmpty,
    );
    await tester.tap(find.byType(MyButton));
    await _settle(tester);
    expect(find.byType(Dialog), findsNothing);
    expect(
      await tester.runAsync(() => watchCachedStickers().first),
      hasLength(1),
    );
    await tester.tap(find.byType(ChatStickerEntry));
    await _settle(tester);
    expect(find.text('Remove from collection'), findsOneWidget);
    expect(find.text('Rotate sticker'), findsNothing);
    await tester.tap(find.byType(MyButton));
    await _settle(tester);
    expect(
      await tester.runAsync(() => watchCachedStickers().first),
      isEmpty,
    );
    expect(find.byType(ChatStickerEntry), findsOneWidget);
  });

  testWidgets('long press in collection previews deletion without selecting', (
    tester,
  ) async {
    await tester.runAsync(() => StickerService.saveReceived(_sticker()));
    var selected = false;
    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 300,
          child: StickerPicker(
            onEmojiPressed: () {},
            onStickerSelected: (_) => selected = true,
          ),
        ),
      ),
    );
    await _settle(tester);
    final tile = find.byKey(ValueKey(sha256.convert(_image).toString()));
    await tester.longPress(tile);
    await _settle(tester);
    expect(selected, isFalse);
    expect(find.text('Delete sticker'), findsOneWidget);
    expect(find.text('Rotate sticker'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Rotate sticker')).dy,
      greaterThan(tester.getBottomLeft(find.text('Delete sticker')).dy),
    );
    expect(
      await tester.runAsync(() => watchCachedStickers().first),
      hasLength(1),
    );
    await tester.tap(find.widgetWithText(MyButton, 'Delete sticker'));
    await _settle(tester);
    expect(find.byType(Dialog), findsNothing);
    expect(
      await tester.runAsync(() => watchCachedStickers().first),
      isEmpty,
    );
    expect(selected, isFalse);
    // Dispose the live Drift query while the test can still drain its timers.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'rotation updates preview and selection, then deletes the new hash',
    (
      tester,
    ) async {
      final source = img.Image(width: 3, height: 2, numChannels: 4)
        ..setPixelRgba(0, 0, 255, 0, 0, 255);
      final bytes = img.encodePng(source);
      final hash = sha256.convert(bytes).toString();
      await tester.runAsync(() async {
        await rust_stickers.saveSticker(
          webp: bytes,
          width: 3,
          height: 2,
          transaction: currentDatabaseSession(),
        );
        await rust_stickers.recordStickerUse(
          hash: hash,
          transaction: currentDatabaseSession(),
        );
      });
      LocalSticker? selected;
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 300,
            child: StickerPicker(
              onEmojiPressed: () {},
              onStickerSelected: (sticker) => selected = sticker,
            ),
          ),
        ),
      );
      await _settle(tester);
      await tester.longPress(find.byKey(ValueKey(hash)));
      await _settle(tester);
      await tester.tap(find.widgetWithText(MyButton, 'Rotate sticker'));
      await _settle(tester);
      expect(find.byType(Dialog), findsOneWidget);
      expect(selected, isNull);
      final rotated = (await tester.runAsync(
        () => watchCachedStickers().first,
      ))!.single;
      expect((rotated.width, rotated.height), (2, 3));
      expect(rotated.usageCount, 1);
      expect(rotated.contentHash, isNot(hash));
      final preview = tester.widget<Image>(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(Image),
        ),
      );
      expect((preview.image as MemoryImage).bytes, rotated.webp);
      await tester.tap(find.text('Close'));
      await _settle(tester);
      await tester.tap(find.byKey(ValueKey(rotated.contentHash)));
      expect(selected?.webp, rotated.webp);
      expect(
        StickerService.decodeAdditional(
          StickerService.encodeAdditional(selected!),
        )?.webp,
        rotated.webp,
      );
      await tester.longPress(find.byKey(ValueKey(rotated.contentHash)));
      await _settle(tester);
      await tester.tap(find.widgetWithText(MyButton, 'Rotate sticker'));
      await _settle(tester);
      expect(api.rotationInputs, [bytes, rotated.webp]);
      await tester.tap(find.widgetWithText(MyButton, 'Delete sticker'));
      await _settle(tester);
      expect(
        await tester.runAsync(() => watchCachedStickers().first),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('failed rotation keeps the original and allows retry', (
    tester,
  ) async {
    await tester.runAsync(() => StickerService.saveReceived(_sticker()));
    api.failRotation = true;
    final hash = sha256.convert(_image).toString();
    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 300,
          child: StickerPicker(
            onEmojiPressed: () {},
            onStickerSelected: (_) {},
          ),
        ),
      ),
    );
    await _settle(tester);
    await tester.longPress(find.byKey(ValueKey(hash)));
    await _settle(tester);
    await tester.tap(find.widgetWithText(MyButton, 'Rotate sticker'));
    await _settle(tester);
    expect(find.text('The sticker could not be rotated.'), findsOneWidget);
    expect(
      await tester.runAsync(
        () => rust_stickers.getSticker(
          hash: hash,
          transaction: currentDatabaseSession(),
        ),
      ),
      isNotNull,
    );
    api.failRotation = false;
    await tester.tap(find.widgetWithText(MyButton, 'Rotate sticker'));
    await _settle(tester);
    expect(find.text('The sticker could not be rotated.'), findsNothing);
    expect(api.rotationInputs, [_image, _image]);
    expect(
      await tester.runAsync(
        () => rust_stickers.getSticker(
          hash: hash,
          transaction: currentDatabaseSession(),
        ),
      ),
      isNull,
    );
    await tester.tap(find.widgetWithText(MyButton, 'Delete sticker'));
    await _settle(tester);
    expect(find.byType(Dialog), findsNothing);
    expect(
      await tester.runAsync(() => watchCachedStickers().first),
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
