import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twonly/core/bridge.dart' show FlameState;
import 'package:twonly/core/bridge/database.dart';
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/bridge/database/messages.dart' as rust_messages;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/core/database/app/stickers/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/visual/loader/three_rotating_dots.loader.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/chat_messages.view.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/chat_list_entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_sticker.entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_webxdc.entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/friendly_message_time.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/message_input.dart';

import '../../helpers/native_database.dart';
import '../../mocks/user_config.dart';

class _OutgoingApi extends NativeTestApi {
  final List<StoredMessage> requests = [];
  final List<Completer<String>> completions = [];
  bool failMessageWatch = false;
  bool failGroupContactRead = false;
  Completer<void>? messageWatchGate;
  final openedMessages = <String>[];

  @override
  Future<GroupMembersWithContacts> crateBridgeDatabaseGroupsGetGroupContacts({
    required GroupMembersQuery input,
    required DatabaseSession transaction,
  }) {
    if (failGroupContactRead) {
      throw StateError('pool timed out while waiting for an open connection');
    }
    return super.crateBridgeDatabaseGroupsGetGroupContacts(
      input: input,
      transaction: transaction,
    );
  }

  @override
  Future<void> crateBridgeApiRustApiNotifyMessagesOpened({
    required int contactId,
    required List<String> messageIds,
  }) async {
    openedMessages.addAll(messageIds);
  }

  @override
  Stream<List<StoredMessage>> crateBridgeDatabaseMessagesWatchMessages({
    required MessageQuery input,
    required DatabaseWatch control,
  }) async* {
    if (failMessageWatch) {
      failMessageWatch = false;
      throw StateError('Conversation query failed');
    }
    final gate = messageWatchGate;
    if (gate != null) await gate.future;
    yield* super.crateBridgeDatabaseMessagesWatchMessages(
      input: input,
      control: control,
    );
  }

  @override
  Stream<List<String>> crateBridgeWrapperAppDatabaseRustAppDatabaseChanges({
    required DatabaseWatch control,
  }) => const Stream.empty();

  @override
  Future<FlameState> crateBridgeGroupsFlameState({
    required String groupId,
  }) async =>
      const FlameState(counter: 0, isExpiring: false, isBestFriend: false);

  @override
  Future<List<String>> crateBridgeApiRustApiClearConversationNotifications({
    required String conversationId,
  }) async => [];

  @override
  Future<String> crateBridgeApiRustApiInsertAndSendText({
    required String groupId,
    required String text,
    String? quoteMessageId,
    Uint8List? additionalMessageData,
    String? messageId,
    int? timestampMs,
  }) {
    requests.add(
      StoredMessage(
        groupId: groupId,
        messageId: messageId!,
        type: 'text',
        content: text,
        quotesMessageId: quoteMessageId,
        additionalMessageData: additionalMessageData,
        mediaStored: false,
        mediaReopened: false,
        isDeletedFromSender: false,
        isWidgetMedia: false,
        isStory: false,
        createdAtSeconds: databaseSeconds(
          DateTime.fromMillisecondsSinceEpoch(timestampMs!),
        ),
      ),
    );
    final completion = Completer<String>();
    completions.add(completion);
    return completion.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final api = _OutgoingApi();
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Group group;

  setUpAll(() async {
    AppEnvironment.initTesting();
    await initializeNativeDatabase(api: api);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('simform_audio_waveforms'),
      (_) async => null,
    );
  });
  tearDownAll(RustLib.dispose);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    api
      ..requests.clear()
      ..openedMessages.clear()
      ..completions.clear()
      ..failMessageWatch = false
      ..failGroupContactRead = false
      ..messageWatchGate = null;
    await locator.reset();
    await TestDatabase.create();
    locator.registerSingleton<UserService>(UserService());
    userService.currentUser = testUserConfig(
      userId: 1,
      username: 'me',
      displayName: 'Me',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
      appVersion: 180,
    )..typingIndicators = false;
    await rust_groups.upsertGroup(
      patch: const GroupPatch(
        groupId: 'chat',
        groupName: 'Chat',
        isDirectChat: true,
      ),
      transaction: currentDatabaseSession(),
    );
    group = (await rust_groups.getGroup(
      id: 'chat',
      transaction: currentDatabaseSession(),
    ))!;
  });

  tearDown(() async {
    await locator.reset();
  });

  Future<void> flush(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(
        const Duration(milliseconds: 40),
      ),
    );
    await tester.pump();
  }

  Future<void> openChat(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsChangeProvider>(
        create: (_) => SettingsChangeProvider()..loadSettings(),
        child: MaterialApp(
          theme: lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChatMessagesView('chat', initialGroup: group),
        ),
      ),
    );
    await flush(tester);
  }

  testWidgets('one game card moves with the latest turn and updates its subtitle and side', (
    tester,
  ) async {
    final wasInBackground = AppState.isAppInBackground;
    AppState.isAppInBackground = false;
    addTearDown(() => AppState.isAppInBackground = wasInBackground);
    final start = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60;
    await runNative(tester, () async {
      await testDatabase.customStatement(
        "INSERT INTO contacts(user_id,username) VALUES (7,'player')",
      );
      await testDatabase.customStatement(
        "INSERT INTO group_members(group_id,contact_id) VALUES ('chat',7)",
      );
      await testDatabase.customStatement(
        "INSERT INTO webxdc_apps(app_id,version,name,bundle_sha256,bundle_bytes,cached_at) VALUES ('arbitrary-game',1,'Connect Four','hash',1,0)",
      );
      await testDatabase.customStatement(
        "INSERT INTO messages(message_id,group_id,sender_id,type,created_at) VALUES ('timeline-card','chat',7,'webxdcApp',?)",
        [start],
      );
      await testDatabase.customStatement(
        "INSERT INTO webxdc_instances(instance_id,group_id,app_id,version,origin_token) VALUES ('timeline-card','chat','arbitrary-game',1,'timeline-origin')",
      );
      await testDatabase.customStatement(
        "INSERT INTO messages(message_id,group_id,type,content,created_at) VALUES ('between','chat','text','Between game turns',?)",
        [start + 15],
      );
    });

    Future<void> turn(
      String id,
      int? sender,
      int offset,
      String summary,
    ) => withDatabaseTransaction(() async {
      await testDatabase.customStatement(
        "INSERT INTO webxdc_updates(instance_id,serial,message_id,sender_id,payload,info,received_at) SELECT 'timeline-card',COALESCE(MAX(serial),0)+1,?,?,'{}','Automatic move text',? FROM webxdc_updates WHERE instance_id = 'timeline-card'",
        [id, sender, start + offset],
      );
      await testDatabase.customStatement(
        "DELETE FROM messages WHERE message_id IN (SELECT message_id || '-info' FROM webxdc_updates WHERE instance_id = 'timeline-card')",
      );
      await testDatabase.customStatement(
        "INSERT INTO messages(message_id,group_id,sender_id,type,content,created_at,additional_message_data) VALUES (?,'chat',?,'text',?,?,?)",
        [
          '$id-info',
          sender,
          'Move: $summary',
          start + offset,
          AdditionalMessageData(
            webxdcOrigin: WebxdcOrigin(
              instanceId: 'timeline-card',
              appId: 'arbitrary-game',
              notificationContent:
                  '{"webxdc_game":"played","instance_id":"timeline-card"}',
            ),
          ).writeToBuffer(),
        ],
      );
      await testDatabase.customStatement(
        "UPDATE messages SET created_at = ? WHERE message_id = 'timeline-card'",
        [start + offset],
      );
      await testDatabase.customStatement(
        "UPDATE webxdc_instances SET summary = ? WHERE instance_id = 'timeline-card'",
        [summary],
      );
    });
    await runNative(tester, () => turn('first', 7, 5, 'Your turn'));
    await openChat(tester);
    final card = find.byType(ChatWebxdcEntry);
    await pumpNative(
      tester,
      until: () =>
          find.text('Played.').evaluate().isNotEmpty &&
          find.text('Between game turns').evaluate().isNotEmpty,
    );
    expect(card, findsOneWidget);
    expect(find.text('Automatic move text'), findsNothing);
    expect(tester.getCenter(card).dx, lessThan(400));
    final gameTime = find.descendant(
      of: card,
      matching: find.byType(FriendlyMessageTime),
    );
    expect(gameTime, findsOneWidget);
    expect(
      tester.widget<FriendlyMessageTime>(gameTime).message.createdAtSeconds,
      start + 5,
    );
    expect(find.text('Your turn'), findsNothing);
    expect(
      tester.getTopLeft(card).dy,
      lessThan(tester.getTopLeft(find.text('Between game turns')).dy),
    );
    await pumpNative(
      tester,
      until: () => api.openedMessages.contains('first-info'),
    );

    await runNative(tester, () => turn('mine', null, 30, "Player's turn"));
    await pumpNative(
      tester,
      until: () =>
          find.text('You have played.').evaluate().isNotEmpty &&
          tester.getCenter(card).dx > 400,
    );
    expect(card, findsOneWidget);
    expect(find.text('Automatic move text'), findsNothing);
    expect(find.text("Move: Player's turn"), findsNothing);
    expect(
      tester.getTopLeft(card).dy,
      greaterThan(tester.getTopLeft(find.text('Between game turns')).dy),
    );

    expect(gameTime, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.byType(ThreeRotatingDots)),
      findsOneWidget,
    );
    await runNative(tester, () async {
      await testDatabase.customStatement(
        "UPDATE messages SET ack_by_server = ? WHERE message_id = 'mine-info'",
        [start + 31],
      );
    });
    await pumpNative(
      tester,
      until: () => find
          .descendant(
            of: card,
            matching: find.byIcon(FontAwesomeIcons.check.data),
          )
          .evaluate()
          .isNotEmpty,
    );
    await runNative(tester, () async {
      await testDatabase.customStatement(
        "INSERT INTO message_actions(message_id,contact_id,type,action_at) VALUES ('mine-info',7,'ackByUserAt',?)",
        [start + 31],
      );
    });
    await pumpNative(
      tester,
      until: () => find
          .descendant(
            of: card,
            matching: find.byIcon(FontAwesomeIcons.checkDouble.data),
          )
          .evaluate()
          .isNotEmpty,
    );
    expect(
      find.descendant(of: card, matching: find.byType(ThreeRotatingDots)),
      findsNothing,
    );
    await runNative(
      tester,
      () => testDatabase.customStatement(
        "UPDATE messages SET opened_at = ? WHERE message_id = 'mine-info'",
        [start + 32],
      ),
    );
    await pumpNative(
      tester,
      until: () => find
          .descendant(
            of: card,
            matching: find.byIcon(FontAwesomeIcons.solidEye.data),
          )
          .evaluate()
          .isNotEmpty,
    );

    await runNative(
      tester,
      () => testDatabase.customStatement(
        "INSERT INTO messages(message_id,group_id,type,content,created_at) VALUES ('mine-following','chat','text','After my move',?)",
        [start + 33],
      ),
    );
    await pumpNative(tester, until: () => gameTime.evaluate().isEmpty);
    expect(
      find.descendant(
        of: card,
        matching: find.byIcon(FontAwesomeIcons.solidEye.data),
      ),
      findsNothing,
    );
    await runNative(
      tester,
      () => testDatabase.customStatement(
        "DELETE FROM messages WHERE message_id = 'mine-following'",
      ),
    );
    await pumpNative(tester, until: () => gameTime.evaluate().isNotEmpty);

    await runNative(tester, () => turn('reply', 7, 30, 'Your next turn'));
    await pumpNative(
      tester,
      until: () =>
          find.text('Played.').evaluate().isNotEmpty &&
          tester.getCenter(card).dx < 400,
    );
    await pumpNative(
      tester,
      until: () => api.openedMessages.contains('reply-info'),
    );
    // A second activity from the same player within the same second must still
    // refresh the card and receive its own read acknowledgement.
    await runNative(tester, () => turn('capture', 7, 30, 'Your next turn'));
    await pumpNative(
      tester,
      until: () => api.openedMessages.contains('capture-info'),
    );
    expect(card, findsOneWidget);
    expect(find.text('Automatic move text'), findsNothing);
    expect(api.openedMessages.where((id) => id == 'reply-info'), hasLength(1));
    final entry = tester.widget<ChatListEntry>(
      find.byKey(const Key('timeline-card')),
    );
    expect(entry.message.messageId, 'timeline-card');
    expect(entry.message.activityMessageId, 'capture-info');
    expect(entry.message.senderId, 7);
    expect(entry.message.originalSenderId, 7);
    expect(entry.message.createdAtSeconds, start + 30);
    expect(gameTime, findsOneWidget);
    expect(
      find.descendant(of: gameTime, matching: find.byType(FaIcon)),
      findsNothing,
    );
    await runNative(
      tester,
      () => testDatabase.customStatement(
        "INSERT INTO messages(message_id,group_id,sender_id,type,content,created_at) VALUES ('following','chat',7,'text','After the game',?)",
        [start + 35],
      ),
    );
    await pumpNative(tester, until: () => gameTime.evaluate().isEmpty);
    expect(find.text('Played.'), findsOneWidget);
    expect(gameTime, findsNothing);
    await runNative(
      tester,
      () => testDatabase.customStatement(
        "DELETE FROM messages WHERE message_id = 'following'",
      ),
    );
    await pumpNative(tester, until: () => gameTime.evaluate().isNotEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await flush(tester);
  });

  testWidgets(
    'chat bootstrap uses recovering watches when one-shot contact reads fail',
    (tester) async {
      await runNative(
        tester,
        () => testDatabase.insert(
          StoredMessage(
            groupId: 'chat',
            messageId: 'recovering-chat',
            type: 'text',
            content: 'Available during recovery',
            mediaStored: false,
            mediaReopened: false,
            isDeletedFromSender: false,
            isWidgetMedia: false,
            isStory: false,
            createdAtSeconds: databaseSeconds(DateTime.now()),
          ),
        ),
      );
      api.failGroupContactRead = true;
      await openChat(tester);
      await pumpNative(
        tester,
        until: () =>
            find.byKey(const Key('recovering-chat')).evaluate().isNotEmpty,
      );
      expect(find.byType(MessageInput), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await flush(tester);
    },
  );

  testWidgets(
    'conversation opens without a loader before its first message snapshot',
    (
      tester,
    ) async {
      final gate = Completer<void>();
      api.messageWatchGate = gate;
      await openChat(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.byType(MessageInput), findsOneWidget);
      expect(find.byKey(const Key('overview_chat')), findsNothing);
      gate.complete();
      await pumpNative(
        tester,
        until: () =>
            find.byKey(const Key('overview_chat')).evaluate().isNotEmpty,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(const SizedBox.shrink());
      await flush(tester);
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets(
    'failed initial conversation query can retry and load stored messages',
    (tester) async {
      await runNative(
        tester,
        () => testDatabase.insert(
          StoredMessage(
            groupId: 'chat',
            messageId: 'existing',
            type: 'text',
            content: 'Already stored',
            mediaStored: false,
            mediaReopened: false,
            isDeletedFromSender: false,
            isWidgetMedia: false,
            isStory: false,
            createdAtSeconds: databaseSeconds(DateTime.now()),
          ),
        ),
      );
      api.failMessageWatch = true;
      await openChat(tester);
      expect(find.text('Try again'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Try again'));
      await pumpNative(
        tester,
        until: () => find.byKey(const Key('existing')).evaluate().isNotEmpty,
      );
      expect(find.byKey(const Key('existing')), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(const SizedBox.shrink());
      await flush(tester);
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  for (final isSticker in [false, true]) {
    testWidgets(
      '${isSticker ? 'sticker' : 'text'} shows immediately and persists in place',
      (tester) async {
        await openChat(tester);
        LocalSticker? sticker;
        if (isSticker) {
          final bytes = File(
            'assets/images/default_avatar.png',
          ).readAsBytesSync();
          final now = DateTime.now();
          sticker = LocalSticker(
            webp: bytes,
            metadata: StickerMetadata(
              contentHash: sha256.convert(bytes).toString(),
              width: 64,
              height: 64,
              usageCount: 0,
              createdAt: databaseSeconds(now),
              lastUsedAt: databaseSeconds(now),
            ),
          );
        }
        if (isSticker) {
          tester
              .widget<MessageInput>(find.byType(MessageInput))
              .onMessageSend(
                text: '🖼️',
                sticker: sticker,
              );
        } else {
          final composer = tester.widget<TextField>(find.byType(TextField));
          composer.controller!.text = 'Immediate message';
          composer.onSubmitted!('Immediate message');
          expect(composer.controller!.text, isEmpty);
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        final message = api.requests.single;
        final bubble = find.byKey(Key(message.messageId));
        expect(bubble, findsOneWidget);
        final animation = find.descendant(
          of: find.byKey(Key('anim_${message.messageId}')),
          matching: find.byType(ScaleTransition),
        );
        expect(
          tester.widget<ScaleTransition>(animation).scale.value,
          allOf(greaterThan(0), lessThan(1)),
        );
        expect(find.byType(ThreeRotatingDots), findsOneWidget);
        expect(api.completions.single.isCompleted, isFalse);
        expect(
          await runNative(
            tester,
            () => rust_messages.getMessage(
              id: message.messageId,
              transaction: currentDatabaseSession(),
            ),
          ),
          isNull,
        );
        if (isSticker) expect(find.byType(ChatStickerEntry), findsOneWidget);

        // Bridge completion alone must not remove the pending bubble.
        if (isSticker) {
          api.completions.single.complete(message.messageId);
          await tester.pump();
          expect(bubble, findsOneWidget);
        }
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          tester.widget<ScaleTransition>(animation).scale.value,
          allOf(greaterThan(0), lessThan(1)),
        );
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.widget<ScaleTransition>(animation).scale.value, 1);
        final originalElement = tester.element(bubble);
        final originalAnimationElement = tester.element(
          find.byKey(Key('anim_${message.messageId}')),
        );
        final originalSize = tester.getSize(bubble);
        final originalPosition = tester.getTopLeft(bubble);

        await runNative(tester, () => testDatabase.insert(message));
        await flush(tester);
        if (!isSticker) {
          // The stored row can also arrive before the bridge result.
          api.completions.single.complete(message.messageId);
          await tester.pump();
        }
        expect(bubble, findsOneWidget);
        expect(tester.element(bubble), same(originalElement));
        expect(
          tester.element(find.byKey(Key('anim_${message.messageId}'))),
          same(originalAnimationElement),
        );
        expect(tester.widget<ScaleTransition>(animation).scale.value, 1);
        expect(tester.getSize(bubble), originalSize);
        expect(tester.getTopLeft(bubble), originalPosition);
        expect(find.byType(ThreeRotatingDots), findsOneWidget);

        await runNative(
          tester,
          () => rust_messages.updateMessages(
            id: message.messageId,
            byMedia: false,
            patch: MessagePatch(
              ackByServer: NullableInt(
                value: databaseNullableSeconds(DateTime.now()),
              ),
            ),
            transaction: currentDatabaseSession(),
          ),
        );
        await flush(tester);
        expect(find.byType(ThreeRotatingDots), findsNothing);
        expect(
          tester.widget<ChatListEntry>(bubble).message.ackByServer,
          isNotNull,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await flush(tester);
      },
    );
  }

  testWidgets('a persistence failure offers retry with the original identity', (
    tester,
  ) async {
    await openChat(tester);
    tester
        .widget<MessageInput>(find.byType(MessageInput))
        .onMessageSend(
          text: 'Retry this message',
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    final message = api.requests.single;
    final bubble = find.byKey(Key(message.messageId));
    expect(bubble, findsOneWidget);
    api.completions.single.completeError(StateError('Database unavailable'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(bubble, findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(bubble, findsOneWidget);
    expect(api.requests.last, message);
    await runNative(tester, () => testDatabase.insert(message));
    api.completions.last.complete(message.messageId);
    await flush(tester);
    expect(bubble, findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await flush(tester);
  });
}
