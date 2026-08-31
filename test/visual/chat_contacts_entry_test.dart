import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_contacts.entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';

import '../mocks/user_config.dart';

Message buildMessage(List<int>? payload) => Message(
  groupId: 'group-1',
  messageId: 'msg-1',
  senderId: 42,
  type: MessageType.contacts.name,
  additionalMessageData: payload == null ? null : Uint8List.fromList(payload),
  mediaStored: false,
  mediaReopened: false,
  isDeletedFromSender: false,
  createdAt: DateTime.now(),
);

BubbleInfo buildInfo() => BubbleInfo()
  ..text = ''
  ..textColor = Colors.white
  ..displayTime = true
  ..displayUserName = ''
  ..color = Colors.blue
  ..expanded = false
  ..spacerWidth = 0
  ..padding = EdgeInsets.zero
  ..minWidth = 0;

void main() {
  setUp(() async {
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
      userId: 0x133337,
      username: 'test_user',
      displayName: 'Test User',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
      appVersion: 62,
    );
  });

  Future<void> pump(WidgetTester tester, List<int>? payload) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsChangeProvider>(
        create: (_) => SettingsChangeProvider()..loadSettings(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ChatContactsEntry(
              message: buildMessage(payload),
              borderRadius: BorderRadius.circular(12),
              info: buildInfo(),
              contactsById: const {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders a shared contact', (tester) async {
    final payload = AdditionalMessageData(
      type: AdditionalMessageData_Type.CONTACTS,
      contacts: [
        SharedContact(
          userId: Int64(4711),
          publicIdentityKey: [1, 2, 3],
          displayName: 'Shared Person',
        ),
      ],
    ).writeToBuffer();

    await pump(tester, payload);
    expect(find.textContaining('Shared Person'), findsOneWidget);
  });

  testWidgets('stays visible when the payload carries no contacts', (
    tester,
  ) async {
    final payload = AdditionalMessageData(
      type: AdditionalMessageData_Type.CONTACTS,
    ).writeToBuffer();

    await pump(tester, payload);
    expect(tester.getSize(find.byType(ChatContactsEntry)), isNot(Size.zero));
  });
}
