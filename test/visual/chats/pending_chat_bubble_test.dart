import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show DatabaseConnection, Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twonly/core/bridge.dart' show FlameState;
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/loader/three_rotating_dots.loader.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/chat_messages.view.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/chat_list_entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_sticker.entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/message_input.dart';

import '../../mocks/user_config.dart';

class _OutgoingApi implements RustLibApi {
  final List<Message> requests = [];
  final List<Completer<String>> completions = [];

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
      Message(
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
        createdAt: DateTime.fromMillisecondsSinceEpoch(timestampMs!),
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

  setUpAll(() {
    AppEnvironment.initTesting();
    RustLib.initMock(api: api);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('simform_audio_waveforms'),
      (_) async => null,
    );
  });
  tearDownAll(RustLib.dispose);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    api.requests.clear();
    api.completions.clear();
    await locator.reset();
    locator
      ..registerSingleton<TwonlyDB>(
        TwonlyDB.forTesting(
          DatabaseConnection(
            NativeDatabase.memory(),
            closeStreamsSynchronously: true,
          ),
        ),
      )
      ..registerSingleton<UserService>(UserService());
    userService.currentUser = testUserConfig(
      userId: 1,
      username: 'me',
      displayName: 'Me',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
      appVersion: 180,
    )..typingIndicators = false;
    await twonlyDB.groupsDao.createNewGroup(
      GroupsCompanion.insert(
        groupId: 'chat',
        groupName: 'Chat',
        isDirectChat: const Value(true),
      ),
    );
    group = (await twonlyDB.groupsDao.getGroup('chat'))!;
  });

  tearDown(() async {
    await twonlyDB.close();
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
            contentHash: sha256.convert(bytes).toString(),
            webp: bytes,
            width: 64,
            height: 64,
            usageCount: 0,
            createdAt: now,
            lastUsedAt: now,
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
        final message = api.requests.single;
        final bubble = find.byKey(Key(message.messageId));
        expect(bubble, findsOneWidget);
        expect(find.byType(ThreeRotatingDots), findsOneWidget);
        expect(api.completions.single.isCompleted, isFalse);
        expect(
          await twonlyDB.messagesDao
              .getMessageById(message.messageId)
              .getSingleOrNull(),
          isNull,
        );
        if (isSticker) expect(find.byType(ChatStickerEntry), findsOneWidget);

        // Bridge completion alone must not remove the pending bubble.
        if (isSticker) {
          api.completions.single.complete(message.messageId);
          await tester.pump();
          expect(bubble, findsOneWidget);
        }
        await tester.pump(const Duration(milliseconds: 160));
        final originalElement = tester.element(bubble);
        final originalSize = tester.getSize(bubble);
        final originalPosition = tester.getTopLeft(bubble);

        await twonlyDB.into(twonlyDB.messages).insert(message);
        await flush(tester);
        if (!isSticker) {
          // The stored row can also arrive before the bridge result.
          api.completions.single.complete(message.messageId);
          await tester.pump();
        }
        expect(bubble, findsOneWidget);
        expect(tester.element(bubble), same(originalElement));
        expect(tester.getSize(bubble), originalSize);
        expect(tester.getTopLeft(bubble), originalPosition);
        expect(find.byType(ThreeRotatingDots), findsOneWidget);

        await (twonlyDB.update(twonlyDB.messages)
              ..where((row) => row.messageId.equals(message.messageId)))
            .write(MessagesCompanion(ackByServer: Value(DateTime.now())));
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
    await twonlyDB.into(twonlyDB.messages).insert(message);
    api.completions.last.complete(message.messageId);
    await flush(tester);
    expect(bubble, findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await flush(tester);
  });
}
