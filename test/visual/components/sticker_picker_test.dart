import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/stickers/sticker.service.dart';
import 'package:twonly/src/visual/components/emoji_picker/emoji_picker.dart';
import 'package:twonly/src/visual/components/sticker_picker.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_sticker.entry.dart';
import 'package:twonly/src/visual/views/memories/sticker_source_picker.view.dart';

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

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

void main() {
  late TwonlyDB database;

  setUpAll(AppEnvironment.initTesting);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    database = TwonlyDB.forTesting(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    locator.registerSingleton<TwonlyDB>(database);
    await database.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await database.close();
    await locator.reset();
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
          message: Message(
            groupId: 'group',
            messageId: 'message',
            senderId: 42,
            type: 'text',
            mediaStored: false,
            mediaReopened: false,
            isDeletedFromSender: false,
            isWidgetMedia: false,
            isStory: false,
            createdAt: DateTime.now(),
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
    expect(
      await tester.runAsync(() => database.stickersDao.watchAll().first),
      isEmpty,
    );
    await tester.tap(find.byType(MyButton));
    await _settle(tester);
    expect(find.byType(Dialog), findsNothing);
    expect(
      await tester.runAsync(() => database.stickersDao.watchAll().first),
      hasLength(1),
    );
    await tester.tap(find.byType(ChatStickerEntry));
    await _settle(tester);
    expect(find.text('Remove from collection'), findsOneWidget);
    await tester.tap(find.byType(MyButton));
    await _settle(tester);
    expect(
      await tester.runAsync(() => database.stickersDao.watchAll().first),
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
    expect(
      await tester.runAsync(() => database.stickersDao.watchAll().first),
      hasLength(1),
    );
    await tester.tap(find.byType(MyButton));
    await _settle(tester);
    expect(find.byType(Dialog), findsNothing);
    expect(
      await tester.runAsync(() => database.stickersDao.watchAll().first),
      isEmpty,
    );
    expect(selected, isFalse);
    // Dispose the live Drift query while the test can still drain its timers.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
