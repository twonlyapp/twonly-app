import 'dart:collection';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twonly/core/bridge.dart' show FlameState;
import 'package:twonly/core/bridge/groups.dart' show directChatId;
import 'package:twonly/core/bridge/stories.dart';
import 'package:twonly/core/bridge/user_config.dart';
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/model/story_availability.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/helpers/screenshot.helper.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/camera/share_image_contact_selection.view.dart';
import 'package:twonly/src/visual/views/camera/share_image_contact_selection_components/contact_group_shortcut_row.comp.dart';
import 'package:twonly/src/visual/views/camera/share_image_contact_selection_components/story_target_selector.comp.dart';

import '../helpers/native_database.dart';
import '../mocks/user_config.dart';

class _PostApi extends NativeTestApi {
  bool failSend = false;
  final sent =
      <({List<String> chats, StoryAudience? audience, Uint8List? metadata})>[];

  @override
  Future<Uint8List>
  crateBridgeWrapperSignalRustSignalGetUserPublicKey() async => Uint8List(32);
  @override
  Future<String?> crateBridgeApiRustApiCurrentUserAvatarPath() async => null;
  @override
  Future<Map<String, FlameState>> crateBridgeGroupsFlameStates({
    required List<String> groupIds,
  }) async => {};

  @override
  Future<void> crateBridgeApiRustApiSendMediaToGroups({
    required String mediaId,
    required List<String> groupIds,
    required bool widgetOnly,
    Uint8List? additionalMessageData,
    StoryAudience? storyAudience,
  }) async {
    if (failSend) throw StateError('send unavailable');
    sent.add((
      chats: groupIds,
      audience: storyAudience,
      metadata: additionalMessageData,
    ));
  }
}

void main() {
  final api = _PostApi();
  late String friendChat;
  late String otherChat;
  final send = find.byKey(const Key('shareMediaSend'));
  final time = find.byKey(const Key('storyAvailabilityButton'));
  setUpAll(() => initializeNativeDatabase(api: api));
  tearDown(locator.reset);
  setUp(() async {
    api.sent.clear();
    api.failSend = false;
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    locator.registerSingleton<UserService>(
      UserService()
        ..currentUser = testUserConfig(
          userId: 42,
          username: 'owner',
          displayName: 'Owner',
          appVersion: 0,
          subscriptionPlan: 'Free',
          currentSetupPage: null,
        ),
    );
    final db = await TestDatabase.create();
    friendChat = directChatId(userId: 42, otherUserId: 7);
    otherChat = directChatId(userId: 42, otherUserId: 8);
    await UserConfigApi.save(
      config: await UserConfigApi.create(
        userId: 42,
        username: 'owner',
        displayName: 'Owner',
        appVersion: 0,
      ),
    );
    await db.customStatement(
      "INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'friend', 1), (8, 'other', 1)",
    );
    await db.customStatement(
      "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES (?, 'Friend', 1), (?, 'Other friend', 1)",
      [friendChat, otherChat],
    );
    await db.customStatement(
      'INSERT INTO group_members(group_id, contact_id) VALUES (?, 7), (?, 8)',
      [friendChat, otherChat],
    );
    await db.customStatement(
      "INSERT INTO contact_groups(id, name, text_color, background_color, share_stories) VALUES (1, 'Friends', 0, 0, 1)",
    );
    await db.customStatement(
      'INSERT INTO contact_group_members(contact_group_id, user_id) VALUES (1, 7)',
    );
  });

  Future<void> open(
    WidgetTester tester, {
    AdditionalMessageData? metadata,
    bool selectStory = true,
    bool waitForSend = true,
    bool widgetMode = false,
    bool protected = false,
    Set<String> chats = const {},
  }) async {
    final selected = HashSet<String>.of(chats);
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: '/share',
        home: const Scaffold(),
        routes: {
          '/share': (_) => ShareImageView(
            selectedGroupIds: selected,
            updateSelectedGroupIds: (id, checked) {
              if (checked) {
                selected.add(id);
              } else {
                selected.remove(id);
              }
            },
            mediaFileService: MediaFileService(
              MediaFile(
                mediaId: 'photo',
                typeName: 'image',
                cloudStateName: 'none',
                requiresAuthentication: protected,
                stored: false,
                isDraftMedia: true,
                isWidgetMedia: false,
                isFavorite: false,
                hasCropAnalyzed: false,
                hasThumbnail: false,
                galleryExportPending: false,
                createdAtSeconds: 0,
              ),
            ),
            mediaStoreFuture: Future.value(ScreenshotImageHelper()),
            additionalData: metadata,
            sendToWidget: widgetMode,
          ),
        },
      ),
    );
    if (selectStory) {
      await pumpNative(
        tester,
        until: () => find.text('Friends').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('Friends'));
    }
    if (waitForSend) {
      await pumpNative(
        tester,
        until: () =>
            send.evaluate().isNotEmpty &&
            tester.widget<MyButton>(send).onPressed != null,
      );
    } else {
      await pumpNative(tester);
    }
  }

  Future<void> chooseSevenDays(WidgetTester tester) async {
    await tester.tap(time);
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 days'));
    await tester.pump();
    await tester.tap(
      find.ancestor(of: find.text('Save'), matching: find.byType(MyButton)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shares a story from the recipient screen with a remembered timer and hidden location',
    (tester) async {
      final now = clock.now();
      final metadata = AdditionalMessageData(
        photoLocation: PhotoLocationData(
          latitude: 52,
          longitude: 13,
          hideFilter: true,
        ),
      );
      await open(tester, metadata: metadata);
      expect(
        tester.widget<MyButton>(send).variant,
        MyButtonVariant.primaryMiddle,
      );
      expect(find.text('Included on Story map'), findsOneWidget);
      expect(
        tester.getTopLeft(time).dy,
        greaterThanOrEqualTo(
          tester.getBottomLeft(find.byType(ContactGroupShortcutRow)).dy,
        ),
      );
      expect(
        find.descendant(of: time, matching: find.text('24 hours')),
        findsOneWidget,
      );
      await chooseSevenDays(tester);
      expect(
        find.descendant(of: time, matching: find.text('7 days')),
        findsOneWidget,
      );
      await tester.tap(send);
      await pumpNative(
        tester,
        until: () => find.byType(ShareImageView).evaluate().isEmpty,
      );
      final sent = api.sent.single;
      expect(sent.chats, isEmpty);
      expect(sent.audience!.contactGroupIds, [BigInt.one]);
      final decoded = AdditionalMessageData.fromBuffer(sent.metadata!);
      final expiry = DateTime.fromMillisecondsSinceEpoch(
        decoded.storyExpiresAtMs.toInt(),
      );
      expect(
        expiry.difference(now).inSeconds,
        closeTo(const Duration(days: 7).inSeconds, 10),
      );
      expect(decoded.photoLocation.latitude, 52);
      expect(decoded.photoLocation.hideFilter, isTrue);
      expect(metadata.hasStoryExpiresAtMs(), isFalse);
      await tester.runAsync(
        () async => expect(
          (await StoryAvailability.load()).duration,
          const Duration(days: 7),
        ),
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'chats and story audiences send together and count overlapping recipients once',
    (tester) async {
      await open(tester, chats: {friendChat, otherChat});
      expect(find.text('Send (2)'), findsOneWidget);
      await tester.tap(send);
      await pumpNative(tester, until: () => api.sent.isNotEmpty);
      expect(api.sent.single.chats, unorderedEquals([friendChat, otherChat]));
      expect(api.sent.single.audience, isNotNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'an expired remembered deadline blocks story sending until changed',
    (tester) async {
      await tester.runAsync(
        () => StoryAvailability.until(
          clock.now().subtract(const Duration(days: 1)),
        ).save(),
      );
      await open(tester, waitForSend: false);
      await pumpNative(
        tester,
        until: () => find
            .text('Choose a future deadline within the next 30 days.')
            .evaluate()
            .isNotEmpty,
      );
      expect(tester.widget<MyButton>(send).onPressed, isNull);
      expect(api.sent, isEmpty);
      await chooseSevenDays(tester);
      expect(tester.widget<MyButton>(send).onPressed, isNotNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('a chat-only send carries no story deadline or audience', (
    tester,
  ) async {
    await open(tester, selectStory: false, chats: {friendChat});
    await tester.tap(send);
    await pumpNative(tester, until: () => api.sent.isNotEmpty);
    expect(api.sent.single.audience, isNull);
    expect(api.sent.single.metadata, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'an unsuccessful send keeps the story selection available to retry',
    (tester) async {
      await open(tester);
      api.failSend = true;
      await tester.tap(send);
      await pumpNative(
        tester,
        until: () => tester.widget<MyButton>(send).onPressed != null,
      );
      expect(find.byType(ShareImageView), findsOneWidget);
      expect(api.sent, isEmpty);
      api.failSend = false;
      await tester.tap(send);
      await pumpNative(
        tester,
        until: () => find.byType(ShareImageView).evaluate().isEmpty,
      );
      expect(api.sent, hasLength(1));
      expect(api.sent.single.audience!.contactGroupIds, [BigInt.one]);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('a remembered deadline keeps its exact date when sharing again', (
    tester,
  ) async {
    final deadline = clock.now().add(const Duration(days: 4));
    await tester.runAsync(() => StoryAvailability.until(deadline).save());
    await open(tester);
    await tester.tap(send);
    await pumpNative(tester, until: () => api.sent.isNotEmpty);
    final metadata = AdditionalMessageData.fromBuffer(
      api.sent.single.metadata!,
    );
    expect(
      metadata.storyExpiresAtMs.toInt(),
      (deadline.millisecondsSinceEpoch ~/ 1000) * 1000,
    );
    await tester.pumpWidget(const SizedBox());
  });

  for (final widgetMode in [false, true]) {
    testWidgets(
      'story controls are hidden for widget=$widgetMode and protected=${!widgetMode}',
      (tester) async {
        await open(
          tester,
          widgetMode: widgetMode,
          protected: !widgetMode,
          selectStory: false,
          waitForSend: false,
        );
        expect(find.byType(StoryTargetSelector), findsNothing);
        expect(time, findsNothing);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
