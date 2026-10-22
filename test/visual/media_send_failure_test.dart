import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/bridge/database/messages.dart' as rust_messages;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/model/message_enums.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/friendly_message_time.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/message_send_state_icon.dart';

import '../helpers/native_database.dart';

void main() {
  setUp(() async {
    await locator.reset();
    await TestDatabase.create();
    await testDatabase.insert(
      const ContactPatch(userId: 7, username: 'receiver'),
    );
    for (final direct in [true, false]) {
      final id = direct ? 'direct' : 'group';
      await testDatabase.insert(
        GroupPatch(groupId: id, groupName: id, isDirectChat: direct),
      );
      await testDatabase.insert(
        MessagePatch(messageId: id, groupId: id, type: 'media'),
      );
    }
  });

  tearDown(() async {
    await locator.reset();
  });

  Future<void> fail(String messageId) => testDatabase.customStatement(
    'INSERT INTO message_actions (message_id, contact_id, type) VALUES (?, ?, ?)',
    [messageId, 7, MessageActionType.sendFailed.name],
  );

  testWidgets('a direct failure replaces the sending spinner', (tester) async {
    final message = (await runNative(
      tester,
      () => rust_messages.getMessage(
        id: 'direct',
        transaction: currentDatabaseSession(),
      ),
    ))!.copyWith(mediaId: const NullableText(value: 'shared-media'));
    await runNative(tester, () => fail('direct'));
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: MessageSendStateIcon([message], const [])),
      ),
    );
    await pumpNative(tester);
    expect(find.text('Send failed'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('stored media and audio can show failure beside their time', (
    tester,
  ) async {
    final message = (await runNative(
      tester,
      () => rust_messages.getMessage(
        id: 'direct',
        transaction: currentDatabaseSession(),
      ),
    ))!;
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
    await pumpNative(tester);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byTooltip('Send failed'), findsOneWidget);
  });

  testWidgets('a group with no eligible recipients does not keep spinning', (
    tester,
  ) async {
    await runNative(tester, () => fail('group'));
    await runNative(
      tester,
      () => testDatabase.insert(
        MediaFilePatch(
          mediaId: 'shared-media',
          type: MediaType.image.name,
          uploadState: NullableText(value: UploadState.storedOnly.name),
        ),
      ),
    );
    final media = (await runNative(
      tester,
      () => rust_mediafiles.getMediaFile(
        id: 'shared-media',
        transaction: currentDatabaseSession(),
      ),
    ))!;
    final group = (await runNative(
      tester,
      () => rust_groups.getGroup(
        id: 'group',
        transaction: currentDatabaseSession(),
      ),
    ))!;
    final message = (await runNative(
      tester,
      () => rust_messages.getMessage(
        id: 'group',
        transaction: currentDatabaseSession(),
      ),
    ))!.copyWith(mediaId: const NullableText(value: 'shared-media'));
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
    await pumpNative(tester);
    expect(find.text('Sent'), findsOneWidget);
    expect(find.text('Send failed'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
