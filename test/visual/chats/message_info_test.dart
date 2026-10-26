import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/bridge/database/messages.dart' as rust_messages;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/visual/components/recipient_status_row.comp.dart';
import 'package:twonly/src/visual/loader/three_rotating_dots.loader.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/message_info.view.dart';

import '../../helpers/native_database.dart';
import '../../mocks/user_config.dart';

class _MessageInfoApi extends NativeTestApi {
  @override
  Future<String?> crateBridgeApiRustApiEnsureAvatarPng({
    required int contactId,
  }) async => File('assets/images/default_avatar.png').absolute.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Group group;
  late StoredMessage message;
  setUpAll(() => initializeNativeDatabase(api: _MessageInfoApi()));
  tearDownAll(RustLib.dispose);
  setUp(() async {
    await locator.reset();
    locator.registerSingleton<UserService>(UserService());
    userService.currentUser = testUserConfig(
      userId: 1,
      username: 'me',
      displayName: 'Me',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
      appVersion: 192,
    );
    await TestDatabase.create();
    await rust_groups.upsertGroup(
      patch: const GroupPatch(groupId: 'chat', groupName: 'Chat'),
      transaction: currentDatabaseSession(),
    );
    group = (await rust_groups.getGroup(
      id: 'chat',
      transaction: currentDatabaseSession(),
    ))!;
    await testDatabase.customStatement(
      "INSERT INTO messages(group_id, message_id, type, content) VALUES ('chat', 'message', 'text', 'Hello')",
    );
    message = (await rust_messages.getMessage(
      id: 'message',
      transaction: currentDatabaseSession(),
    ))!;
  });
  tearDown(locator.reset);

  Future<void> openInfo(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MessageInfoView(
          message: message,
          group: group,
          galleryItems: const [],
        ),
      ),
    );
    await pumpNative(
      tester,
      until: () => find.byType(ThreeRotatingDots).evaluate().isNotEmpty,
    );
  }

  testWidgets('delivery updates the bubble while message info stays open', (
    tester,
  ) async {
    await openInfo(tester);
    expect(find.byType(ThreeRotatingDots), findsOneWidget);
    await runNative(
      tester,
      () => rust_messages.updateMessages(
        id: message.messageId,
        byMedia: false,
        patch: const MessagePatch(ackByServer: NullableInt(value: 123)),
        transaction: currentDatabaseSession(),
      ),
    );
    await pumpNative(
      tester,
      until: () => find.byType(ThreeRotatingDots).evaluate().isEmpty,
    );
    expect(find.byType(ThreeRotatingDots), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('developer IDs appear immediately after a config update', (
    tester,
  ) async {
    await openInfo(tester);
    expect(find.text('ID: message'), findsNothing);
    userService.currentUser.isDeveloper = true;
    userService.triggerUserUpdate();
    await tester.pump();
    expect(find.text('ID: message'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('removed members are absent from pending message recipients', (
    tester,
  ) async {
    await runNative(tester, () async {
      await testDatabase.customStatement(
        "INSERT INTO contacts(user_id, username) VALUES (7, 'Remaining'), (8, 'Removed')",
      );
      await testDatabase.customStatement(
        "INSERT INTO group_members(group_id, contact_id, member_state) VALUES ('chat', 7, 'normal'), ('chat', 8, 'leftGroup')",
      );
    });
    await openInfo(tester);
    await pumpNative(
      tester,
      until: () => find.byType(RecipientStatusRow).evaluate().isNotEmpty,
    );

    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('Removed'), findsNothing);
    expect(find.text('Waiting for internet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('removing a member updates an already open message info', (
    tester,
  ) async {
    await runNative(tester, () async {
      await testDatabase.customStatement(
        "INSERT INTO contacts(user_id, username) VALUES (7, 'Remaining'), (8, 'Removed')",
      );
      await testDatabase.customStatement(
        "INSERT INTO group_members(group_id, contact_id) VALUES ('chat', 7), ('chat', 8)",
      );
    });
    await openInfo(tester);
    await pumpNative(
      tester,
      until: () => find.byType(RecipientStatusRow).evaluate().length == 2,
    );
    expect(find.text('Waiting for internet'), findsNWidgets(2));

    await runNative(
      tester,
      () => testDatabase.customStatement(
        "UPDATE group_members SET member_state = 'leftGroup' WHERE group_id = 'chat' AND contact_id = 8",
      ),
    );
    await pumpNative(
      tester,
      until: () => find.byType(RecipientStatusRow).evaluate().length == 1,
    );

    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('Removed'), findsNothing);
    expect(find.text('Waiting for internet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
