import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/message_send_state_icon.dart';

Group _group() => Group(
  groupId: 'chat',
  groupName: 'Chat',
  draftMessage: 'Unsent',
  isGroupAdmin: true,
  isDirectChat: true,
  pinned: false,
  archived: false,
  joinedGroup: true,
  leftGroup: false,
  deletedContent: false,
  stateVersionId: 0,
  totalMediaCounter: 1,
  alsoBestFriend: false,
  deleteMessagesAfterMilliseconds: 0,
  createdAtSeconds: databaseSeconds(DateTime(2026)),
  flameCounter: 0,
  maxFlameCounter: 0,
  lastMessageExchangeSeconds: databaseSeconds(DateTime(2026)),
);

StoredMessage _mediaMessage({bool received = true, bool opened = true}) =>
    StoredMessage(
      groupId: 'chat',
      messageId: 'message',
      senderId: received ? 7 : null,
      type: 'media',
      mediaId: 'media',
      mediaStored: false,
      mediaReopened: false,
      isDeletedFromSender: false,
      isWidgetMedia: false,
      isStory: false,
      openedAtSeconds: opened ? databaseNullableSeconds(DateTime(2026)) : null,
      createdAtSeconds: databaseSeconds(DateTime(2026)),
    );

Widget _status(StoredMessage message, {bool showDraft = false}) => MaterialApp(
  theme: lightTheme,
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: MessageSendStateIcon(
      [message],
      const [],
      group: _group(),
      showDraft: showDraft,
    ),
  ),
);

void main() {
  final draftIcon = find.byIcon(FontAwesomeIcons.pen.data);
  for (final received in [true, false]) {
    testWidgets(
      '${received ? 'received' : 'sent'} opened media keeps its status with a saved draft',
      (tester) async {
        await tester.pumpWidget(_status(_mediaMessage(received: received)));
        await tester.pumpAndSettle();

        expect(find.text(received ? 'Received' : 'Opened'), findsOneWidget);
        expect(find.text('Draft: Unsent'), findsNothing);
        expect(draftIcon, findsNothing);
      },
    );
  }

  testWidgets('chat list previews still show the saved draft', (tester) async {
    await tester.pumpWidget(_status(_mediaMessage(), showDraft: true));
    await tester.pumpAndSettle();

    expect(find.text('Draft: Unsent'), findsOneWidget);
    expect(draftIcon, findsOneWidget);
  });

  testWidgets('unopened media takes priority over the chat list draft', (
    tester,
  ) async {
    await tester.pumpWidget(
      _status(_mediaMessage(opened: false), showDraft: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Received'), findsOneWidget);
    expect(find.text('Draft: Unsent'), findsNothing);
    expect(draftIcon, findsNothing);
  });
}
