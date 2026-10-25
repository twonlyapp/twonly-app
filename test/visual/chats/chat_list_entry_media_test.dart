import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/chat_list_entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_media_entry.dart';

import '../../helpers/native_database.dart';
import '../chat_media_entry_test.dart' show buildGroup;

void main() {
  late Directory support;
  late StreamSubscription<LogRecord> subscription;
  late Level previousLevel;
  final records = <LogRecord>[];

  setUpAll(initializeNativeDatabase);
  tearDownAll(RustLib.dispose);
  setUp(() async {
    await TestDatabase.create();
    support = Directory.systemTemp.createTempSync('chat-media-watch-');
    AppEnvironment.initTesting(customSupportDir: support.path);
    previousLevel = Logger.root.level;
    Logger.root.level = Level.ALL;
    records.clear();
    subscription = Logger.root.onRecord.listen(records.add);
    await testDatabase.customStatement(
      'INSERT INTO media_files(media_id, type, stored) VALUES '
      "('first', 'video', 1), ('second', 'video', 1)",
    );
  });
  tearDown(() async {
    await subscription.cancel();
    Logger.root.level = previousLevel;
    support.deleteSync(recursive: true);
  });

  Widget app(String? mediaId) => MaterialApp(
    theme: lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ChatListEntry(
        group: buildGroup(),
        hideReactions: true,
        message: StoredMessage(
          groupId: 'group-1',
          messageId: 'message-1',
          type: 'media',
          mediaId: mediaId,
          mediaStored: true,
          mediaReopened: false,
          isDeletedFromSender: false,
          isWidgetMedia: false,
          isStory: false,
          openedAtSeconds: databaseNullableSeconds(DateTime(2026)),
          createdAtSeconds: databaseSeconds(DateTime(2026)),
        ),
      ),
    ),
  );

  testWidgets('deleting media clears the tile without reporting an app error', (
    tester,
  ) async {
    await tester.pumpWidget(app('first'));
    await pumpNative(
      tester,
      until: () => find.byType(ChatMediaEntry).evaluate().isNotEmpty,
    );
    expect(find.byType(ChatMediaEntry), findsOneWidget);

    await runNative(
      tester,
      () => testDatabase.customStatement(
        "DELETE FROM media_files WHERE media_id = 'first'",
      ),
    );
    await pumpNative(
      tester,
      until: () => find.byType(ChatMediaEntry).evaluate().isEmpty,
    );
    expect(find.byType(ChatMediaEntry), findsNothing);
    expect(records.where((record) => record.level >= Level.SEVERE), isEmpty);
    await tester.pumpWidget(const SizedBox());
    await pumpNative(tester);
  });

  testWidgets('a reused message tile watches its replacement media', (
    tester,
  ) async {
    await tester.pumpWidget(app('first'));
    await pumpNative(
      tester,
      until: () => find.byType(ChatMediaEntry).evaluate().isNotEmpty,
    );
    expect(
      tester
          .widget<ChatMediaEntry>(find.byType(ChatMediaEntry))
          .mediaService
          .mediaFile
          .mediaId,
      'first',
    );

    await tester.pumpWidget(app('second'));
    await pumpNative(
      tester,
      until: () => find.byType(ChatMediaEntry).evaluate().isNotEmpty,
    );
    expect(
      tester
          .widget<ChatMediaEntry>(find.byType(ChatMediaEntry))
          .mediaService
          .mediaFile
          .mediaId,
      'second',
    );

    // A late change to the old row must not clear the replacement tile.
    await runNative(
      tester,
      () => testDatabase.customStatement(
        "DELETE FROM media_files WHERE media_id = 'first'",
      ),
    );
    await pumpNative(tester);
    expect(
      tester
          .widget<ChatMediaEntry>(find.byType(ChatMediaEntry))
          .mediaService
          .mediaFile
          .mediaId,
      'second',
    );
    await tester.pumpWidget(app(null));
    expect(find.byType(ChatMediaEntry), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await pumpNative(tester);
  });
}
