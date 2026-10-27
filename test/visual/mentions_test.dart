import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/visual/components/mention_editing_controller.dart';
import 'package:twonly/src/visual/components/mention_suggestions.dart';
import 'package:twonly/src/visual/elements/better_text.element.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/message_context_menu.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/media_viewer_message_input.comp.dart';

import '../helpers/native_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Group group;
  setUpAll(initializeNativeDatabase);
  tearDownAll(RustLib.dispose);
  setUp(() async {
    await TestDatabase.create();
    await testDatabase.customStatement(
      "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('group', 'Friends', 0), ('direct', 'Alice', 1)",
    );
    await testDatabase.customStatement(
      "INSERT INTO contacts(user_id, username, display_name, nick_name) VALUES (2, 'alice', 'Alice', 'My friend'), (3, 'bob', 'Bob', NULL), (4, 'gone', 'Gone', NULL), (5, 'outside', 'Outside', NULL)",
    );
    await testDatabase.customStatement(
      "INSERT INTO group_members(group_id, contact_id, member_state) VALUES ('group', 2, NULL), ('group', 3, NULL), ('group', 4, 'leftGroup'), ('direct', 2, NULL)",
    );
    group = (await rust_groups.getGroup(
      id: 'group',
      transaction: currentDatabaseSession(),
    ))!;
  });

  Widget app(Widget child) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets(
    'suggestions show only local names of current group members and preserve IDs',
    (tester) async {
      final controller = MentionEditingController();
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        app(
          Column(
            children: [
              MentionSuggestions(
                group: group,
                controller: controller,
                focusNode: focus,
              ),
              TextField(
                controller: controller,
                focusNode: focus,
                autofocus: true,
              ),
            ],
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '@');
      await pumpNative(
        tester,
        until: () => find.text('My friend').evaluate().isNotEmpty,
      );
      expect(find.text('Bob'), findsOneWidget);
      for (final name in ['Alice', 'alice', 'Gone', 'Outside']) {
        expect(find.text(name), findsNothing, reason: name);
      }

      // Search can find the contact's username, but still displays only the local name.
      await tester.enterText(find.byType(TextField), 'Hi @ali');
      await tester.pump();
      expect(find.text('My friend'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
      await tester.tap(find.text('My friend'));
      await tester.pump();
      expect(controller.text, 'Hi @My friend ');
      expect(controller.messageText, 'Hi @[user:2] ');
      expect(focus.hasFocus, isTrue);
      expect(find.byType(ListTile), findsNothing);

      await runNative(
        tester,
        () => testDatabase.customStatement(
          "UPDATE contacts SET nick_name = 'Best friend' WHERE user_id = 2",
        ),
      );
      await pumpNative(
        tester,
        until: () => controller.text == 'Hi @Best friend ',
      );
      expect(controller.messageText, 'Hi @[user:2] ');

      await tester.enterText(find.byType(TextField), '${controller.text}@');
      await tester.pump();
      expect(find.text('Bob'), findsOneWidget);
      await runNative(
        tester,
        () => testDatabase.customStatement(
          "UPDATE group_members SET member_state = 'leftGroup' WHERE group_id = 'group' AND contact_id = 3",
        ),
      );
      await pumpNative(
        tester,
        until: () => find.text('Bob').evaluate().isEmpty,
      );
      expect(find.text('Best friend'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('direct chats do not offer mention suggestions', (tester) async {
    final direct = await runNative(
      tester,
      () => rust_groups.getGroup(
        id: 'direct',
        transaction: currentDatabaseSession(),
      ),
    );
    final controller = MentionEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      app(
        Column(
          children: [
            MentionSuggestions(
              group: direct!,
              controller: controller,
              focusNode: focus,
            ),
            TextField(
              controller: controller,
              focusNode: focus,
              autofocus: true,
            ),
          ],
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '@');
    await tester.pump();
    expect(find.byType(ListTile), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('media replies use the same picker and retain keyboard focus', (
    tester,
  ) async {
    final controller = MentionEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      app(
        Stack(
          children: [
            MediaViewerMessageInput(
              controller: controller,
              group: group,
              focusNode: focus,
              safeAreaBottomPadding: 0,
              onSubmitted: (_) {},
              onSendPressed: () {},
            ),
          ],
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '@bob');
    await pumpNative(
      tester,
      until: () => find.text('Bob').evaluate().isNotEmpty,
    );
    await tester.tap(find.text('Bob'));
    await tester.pump();
    expect(controller.messageText, '@[user:3] ');
    expect(focus.hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('copy produces readable local names without hidden IDs', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      app(
        MessageContextMenu(
          group: group,
          message: const StoredMessage(
            groupId: 'group',
            messageId: 'copy',
            type: 'text',
            content: 'Hi @[user:2] and @[user:99] @@[user:3]',
            mediaStored: false,
            mediaReopened: false,
            isDeletedFromSender: false,
            isWidgetMedia: false,
            isStory: false,
            createdAtSeconds: 1,
          ),
          galleryItems: const [],
          mediaFileService: null,
          onResponseTriggered: () {},
          child: const Text('Message'),
        ),
      ),
    );
    await tester.longPress(find.text('Message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy'));
    await pumpNative(tester, until: () => copied != null);
    expect(copied, 'Hi @My friend and @Unknown user @[user:3]');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'message rendering resolves renamed, former and unknown members without exposing IDs',
    (tester) async {
      await tester.pumpWidget(
        app(
          const BetterText(
            text:
                'Hi @[user:2], @[user:4] and @[user:99]. https://example.org @@[user:2]',
            textColor: Colors.black,
          ),
        ),
      );
      String rendered() => tester
          .widgetList<RichText>(find.byType(RichText))
          .map((widget) => widget.text.toPlainText())
          .join();
      await pumpNative(tester, until: () => rendered().contains('@My friend'));
      expect(
        rendered(),
        contains(
          'Hi @My friend, @Gone and @Unknown user. https://example.org @[user:2]',
        ),
      );
      await runNative(
        tester,
        () => testDatabase.customStatement(
          "UPDATE contacts SET nick_name = 'Renamed' WHERE user_id = 2",
        ),
      );
      await pumpNative(tester, until: () => rendered().contains('@Renamed'));
      expect(rendered(), isNot(contains('@[user:99]')));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
