import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/visual/components/chat_deletion_time_sheet.comp.dart';
import 'package:twonly/src/visual/components/select_chat_deletion_time.comp.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_chip.element.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/chat_group_action.dart';

import '../../helpers/native_database.dart';

class _TimerApi extends NativeTestApi {
  final sentUpdates = <EncryptedContent>[];
  final groupUpdates = <int>[];

  @override
  Future<void> crateBridgeApiRustApiSendEncryptedContentToGroup({
    required String groupId,
    required List<int> content,
    String? messageId,
    bool? onlySendIfNoReceiptsAreOpen,
  }) async {
    sentUpdates.add(EncryptedContent.fromBuffer(content));
  }

  @override
  Future<bool> crateBridgeGroupsUpdateChatDeletionTime({
    required String groupId,
    required int deleteMessagesAfterMilliseconds,
  }) async {
    groupUpdates.add(deleteMessagesAfterMilliseconds);
    await rust_groups.updateGroup(
      id: groupId,
      patch: GroupPatch(
        deleteMessagesAfterMilliseconds: deleteMessagesAfterMilliseconds,
      ),
      transaction: currentDatabaseSession(),
    );
    return true;
  }
}

void main() {
  final api = _TimerApi();
  late TestDatabase database;

  setUpAll(() => initializeNativeDatabase(api: api));
  tearDownAll(RustLib.dispose);
  setUp(() async {
    await locator.reset();
    database = await TestDatabase.create();
    api.sentUpdates.clear();
    api.groupUpdates.clear();
    await database.insert(
      GroupPatch(
        groupId: 'chat',
        groupName: 'Chat',
        isDirectChat: true,
        deleteMessagesAfterMilliseconds: const Duration(
          hours: 1,
        ).inMilliseconds,
      ),
    );
  });
  tearDown(locator.reset);

  Future<void> pumpSelector(
    WidgetTester tester, {
    bool disabled = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SelectChatDeletionTimeListTitle(
            groupId: 'chat',
            disabled: disabled,
          ),
        ),
      ),
    );
    await pumpNative(tester);
  }

  Future<void> openCustom(WidgetTester tester) async {
    await tester.tap(find.text('Delete chat after...'));
    await tester.pumpAndSettle();
    if (find.byType(TextField).evaluate().isEmpty) {
      await tester.tap(
        find.ancestor(
          of: find.text('Custom'),
          matching: find.byType(MyChip),
        ),
      );
      await tester.pumpAndSettle();
    }
    expect(find.byType(ChatDeletionTimeSheet), findsOneWidget);
    expect(find.text('Chat timer'), findsNothing);
  }

  Future<int> savedTime(WidgetTester tester) async {
    final group = await runNative(
      tester,
      () => rust_groups.getGroup(
        id: 'chat',
        transaction: currentDatabaseSession(),
      ),
    );
    return group!.deleteMessagesAfterMilliseconds;
  }

  Future<void> selectUnit(WidgetTester tester, String unit) async {
    await tester.tap(
      find.ancestor(
        of: find.text(unit),
        matching: find.byType(MyChip),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('custom direct timer is saved, announced and reopened exactly', (
    tester,
  ) async {
    await pumpSelector(tester);
    await openCustom(tester);
    await selectUnit(tester, 'Hours');
    await tester.enterText(find.byType(TextField), '1.5');
    await tester.tap(
      find.ancestor(of: find.text('Save'), matching: find.byType(MyButton)),
    );
    await pumpNative(tester, until: () => api.sentUpdates.isNotEmpty);
    await tester.pumpAndSettle();

    final expected = const Duration(minutes: 90).inMilliseconds;
    expect(await savedTime(tester), expected);
    expect(
      api.sentUpdates.single.groupUpdate.newDeleteMessagesAfterMilliseconds
          .toInt(),
      expected,
    );
    final history = await runNative(
      tester,
      () => database
          .customSelect(
            'SELECT new_delete_messages_after_milliseconds FROM group_histories',
          )
          .getSingle(),
    );
    expect(
      history.read<int>('new_delete_messages_after_milliseconds'),
      expected,
    );
    expect(find.text('90 minutes'), findsOneWidget);

    await openCustom(tester);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '1.5',
    );
    expect(find.text('Hours'), findsOneWidget);
    expect(find.text('Minutes'), findsNothing);
    expect(find.text('Months'), findsOneWidget);
    await tester.tap(
      find.ancestor(of: find.text('Cancel'), matching: find.byType(MyButton)),
    );
    await tester.pumpAndSettle();
    expect(await savedTime(tester), expected);
    expect(api.sentUpdates, hasLength(1));
  });

  testWidgets('custom group timer uses the group update path', (tester) async {
    await runNative(
      tester,
      () => rust_groups.updateGroup(
        id: 'chat',
        patch: const GroupPatch(isDirectChat: false),
        transaction: currentDatabaseSession(),
      ),
    );
    await pumpSelector(tester);
    await openCustom(tester);
    await selectUnit(tester, 'Months');
    await tester.enterText(find.byType(TextField), '2');
    await tester.tap(
      find.ancestor(of: find.text('Save'), matching: find.byType(MyButton)),
    );
    await pumpNative(tester, until: () => api.groupUpdates.isNotEmpty);
    await pumpNative(tester);
    await tester.pumpAndSettle();
    expect(api.groupUpdates, [const Duration(days: 60).inMilliseconds]);
    expect(await savedTime(tester), api.groupUpdates.single);
    expect(api.sentUpdates, isEmpty);
    expect(find.text('60 days'), findsOneWidget);
  });

  testWidgets(
    'invalid custom timers cannot save and cancellation keeps value',
    (
      tester,
    ) async {
      await pumpSelector(tester);
      await openCustom(tester);
      await selectUnit(tester, 'Days');
      for (final value in ['', '0', '366', '999999999999999999999999']) {
        await tester.enterText(find.byType(TextField), value);
        await tester.tap(
          find.ancestor(of: find.text('Save'), matching: find.byType(MyButton)),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Invalid duration.'),
          findsOneWidget,
        );
        expect(api.sentUpdates, isEmpty);
        expect(
          await savedTime(tester),
          const Duration(hours: 1).inMilliseconds,
        );
      }
      await tester.enterText(find.byType(TextField), '3');
      await tester.tap(
        find.ancestor(of: find.text('Cancel'), matching: find.byType(MyButton)),
      );
      await tester.pumpAndSettle();
      expect(await savedTime(tester), const Duration(hours: 1).inMilliseconds);
      expect(api.sentUpdates, isEmpty);
    },
  );

  testWidgets('a custom timer from another device is preserved on dismissal', (
    tester,
  ) async {
    final expected = const Duration(hours: 25).inMilliseconds;
    await runNative(
      tester,
      () => rust_groups.updateGroup(
        id: 'chat',
        patch: GroupPatch(deleteMessagesAfterMilliseconds: expected),
        transaction: currentDatabaseSession(),
      ),
    );
    await pumpSelector(tester);
    await pumpNative(
      tester,
      until: () => find.text('25 hours').evaluate().isNotEmpty,
    );
    await tester.tap(find.text('Delete chat after...'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '25',
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(await savedTime(tester), expected);
    expect(api.sentUpdates, isEmpty);
  });

  testWidgets(
    'preset selection still saves and disabled selectors stay closed',
    (
      tester,
    ) async {
      await pumpSelector(tester);
      await tester.tap(find.text('Delete chat after...'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(
          of: find.text('1 day').last,
          matching: find.byType(MyChip),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(of: find.text('Save'), matching: find.byType(MyButton)),
      );
      await pumpNative(tester, until: () => api.sentUpdates.isNotEmpty);
      await tester.pumpAndSettle();
      expect(await savedTime(tester), const Duration(days: 1).inMilliseconds);
      await pumpSelector(tester, disabled: true);
      await tester.tap(find.text('Delete chat after...'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatDeletionTimeSheet), findsNothing);
    },
  );
  testWidgets('history shows exact custom durations without rounding', (
    tester,
  ) async {
    for (final (duration, label) in [
      (const Duration(minutes: 90), '90 minutes'),
      (const Duration(hours: 25), '25 hours'),
      (const Duration(days: 14), '14 days'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ChatGroupAction(
              contactsById: const {},
              action: GroupHistory(
                groupHistoryId: 'history',
                groupId: 'chat',
                typeName: 'changeDisplayMaxTime',
                actionAtSeconds: 0,
                newDeleteMessagesAfterMilliseconds: duration.inMilliseconds,
              ),
            ),
          ),
        ),
      );
      expect(
        find.text('Chats will now be deleted after $label.'),
        findsOneWidget,
      );
    }
  });
}
