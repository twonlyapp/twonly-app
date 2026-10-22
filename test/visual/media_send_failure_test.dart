import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/friendly_message_time.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/message_send_state_icon.dart';

void main() {
  setUp(() async {
    await locator.reset();
    locator.registerSingleton<TwonlyDB>(
      TwonlyDB.forTesting(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      ),
    );
    await twonlyDB
        .into(twonlyDB.contacts)
        .insert(
          ContactsCompanion.insert(
            userId: const Value(7),
            username: 'receiver',
          ),
        );
    for (final direct in [true, false]) {
      final id = direct ? 'direct' : 'group';
      await twonlyDB
          .into(twonlyDB.groups)
          .insert(
            GroupsCompanion.insert(
              groupId: id,
              groupName: id,
              isDirectChat: Value(direct),
            ),
          );
      await twonlyDB
          .into(twonlyDB.messages)
          .insert(
            MessagesCompanion.insert(messageId: id, groupId: id, type: 'media'),
          );
    }
  });

  tearDown(() async {
    await twonlyDB.close();
    await locator.reset();
  });

  Future<void> fail(String messageId) => twonlyDB
      .into(twonlyDB.messageActions)
      .insert(
        MessageActionsCompanion.insert(
          messageId: messageId,
          contactId: 7,
          type: MessageActionType.sendFailed,
        ),
      );

  test('only direct failures affect the overall delivery status', () async {
    await fail('direct');
    await fail('group');
    final actions = await twonlyDB.messagesDao.watchDeliveryActionsForMessages({
      'direct',
      'group',
    }).first;
    expect(actions.map((a) => a.messageId), ['direct']);
    final groupActions = await twonlyDB.messagesDao
        .watchMessageActions('group')
        .first;
    expect(groupActions.single.$1.type, MessageActionType.sendFailed);
  });

  testWidgets('a direct failure replaces the sending spinner', (tester) async {
    final message =
        (await twonlyDB.messagesDao.getMessageById('direct').getSingleOrNull())!
            .copyWith(mediaId: const Value('shared-media'));
    await fail('direct');
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: MessageSendStateIcon([message], const [])),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Send failed'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('stored media and audio can show failure beside their time', (
    tester,
  ) async {
    final message = (await twonlyDB.messagesDao
        .getMessageById('direct')
        .getSingleOrNull())!;
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ChatMessageActionScope(
            ackedMessageIds: const {},
            failedMessageIds: const {'direct'},
            child: FriendlyMessageTime(message: message),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byTooltip('Send failed'), findsOneWidget);
  });

  testWidgets('a group with no eligible recipients does not keep spinning', (
    tester,
  ) async {
    await fail('group');
    await twonlyDB
        .into(twonlyDB.mediaFiles)
        .insert(
          MediaFilesCompanion.insert(
            mediaId: 'shared-media',
            type: MediaType.image,
            uploadState: const Value(UploadState.storedOnly),
          ),
        );
    final media = await twonlyDB.select(twonlyDB.mediaFiles).getSingle();
    final group = await (twonlyDB.select(
      twonlyDB.groups,
    )..where((g) => g.groupId.equals('group'))).getSingle();
    final message =
        (await twonlyDB.messagesDao.getMessageById('group').getSingleOrNull())!
            .copyWith(mediaId: const Value('shared-media'));
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MessageSendStateIcon([message], [media], group: group),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sent'), findsOneWidget);
    expect(find.text('Send failed'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
