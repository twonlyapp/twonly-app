import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database/contact_groups.dart'
    as rust_contact_groups;
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/bridge/stories.dart';
import 'package:twonly/core/database/app/contact_groups/table.dart'
    as db_contact_groups;
import 'package:twonly/core/database/app/contact_groups/table.dart';
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/visual/components/custom_color_picker_dialog.comp.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_chip.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/camera/share_image_contact_selection_components/story_target_selector.comp.dart';
import 'package:twonly/src/visual/views/contact/contact_group_settings.view.dart';

import '../helpers/native_database.dart';

class _AvatarApi extends NativeTestApi {
  final paths = <int, String>{};
  final storyAudiences = <StoryAudience>[];

  @override
  Future<String?> crateBridgeApiRustApiEnsureAvatarPng({
    required int contactId,
  }) async => paths[contactId];

  @override
  Future<void> crateBridgeApiRustApiRefreshWidgetManifest() async {}

  @override
  Future<List<String>> crateBridgeStoriesStoryAudienceChats({
    required StoryAudience audience,
  }) async {
    storyAudiences.add(audience);
    return [for (final id in audience.contactGroupIds) 'story-group:$id'];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final api = _AvatarApi();
  late Directory directory;
  late TestDatabase database;
  late ContactGroup contactGroup;

  setUpAll(() => initializeNativeDatabase(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() async {
    await locator.reset();
    api.storyAudiences.clear();
    database = await TestDatabase.create();

    directory = await Directory.systemTemp.createTemp('contact-group-test-');
    AppEnvironment.initTesting(customSupportDir: directory.path);
    for (final id in [7, 8, 9]) {
      api.paths[id] = (await File(
        'assets/images/default_avatar.png',
      ).copy('${directory.path}/$id.png')).path;
    }
    for (final statement in [
      '''
         INSERT INTO contacts(user_id, username, accepted) VALUES
         (7, 'Alice', 1), (8, 'Bob', 1), (9, 'Carol', 1), (10, 'Pending', 0)''',
      '''
         INSERT INTO groups(group_id, group_name, is_direct_chat, archived)
         VALUES ('alice', 'Alice', 1, 1), ('bob', 'Bob', 1, 0),
         ('team', 'Team', 0, 0), ('old-team', 'Old team', 0, 1)''',
      '''
         INSERT INTO group_members(group_id, contact_id) VALUES
         ('alice', 7), ('bob', 8), ('team', 7), ('team', 8),
         ('old-team', 7), ('old-team', 8)''',
    ]) {
      await database.customStatement(statement);
    }
    final id = await rust_contact_groups.createContactGroup(
      transaction: currentDatabaseSession(),
      input: const db_contact_groups.ContactGroupInput(
        name: 'Favorites',
        textColor: 0xFF000000,
        backgroundColor: 0,
        showAsShortcut: false,
        showAsLabel: true,
        shareStories: false,
      ),
    );
    await rust_contact_groups.replaceContactGroupMembers(
      transaction: currentDatabaseSession(),
      id: id,
      userIds: Int64List.fromList([7].toList()),
      groupIds: ['old-team'].toList(),
    );
    contactGroup = (await rust_contact_groups.getContactGroup(
      id: id,
      transaction: currentDatabaseSession(),
    ))!;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('eu.twonly/runtime_storage'),
          (_) async => null,
        );
  });

  tearDown(() async {
    await locator.reset();
    await directory.delete(recursive: true);
    AppEnvironment.initTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('eu.twonly/runtime_storage'),
          null,
        );
  });

  Future<void> settle(WidgetTester tester) => pumpNative(tester);

  Finder memberTile(String name) => find.ancestor(
    of: find.text(name),
    matching: find.byType(ListTile),
  );

  bool selected(WidgetTester tester, String name) => tester
      .widget<Checkbox>(
        find.descendant(of: memberTile(name), matching: find.byType(Checkbox)),
      )
      .value!;

  List<String> avatarPaths(WidgetTester tester, String name) => tester
      .widgetList<Image>(
        find.descendant(of: memberTile(name), matching: find.byType(Image)),
      )
      .map((image) => (image.image as FileImage).file.path)
      .toList();

  Future<void> pumpView(WidgetTester tester, Widget view) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: view,
      ),
    );
    await settle(tester);
  }

  Future<void> pumpEditor(WidgetTester tester) async {
    await pumpView(
      tester,
      ContactGroupSettingsView(contactGroup: contactGroup),
    );
    await pumpNative(
      tester,
      until: () =>
          avatarPaths(tester, 'Bob').isNotEmpty &&
          avatarPaths(tester, 'Carol').isNotEmpty &&
          memberTile('Old team').evaluate().isNotEmpty &&
          selected(tester, 'Alice') &&
          selected(tester, 'Old team'),
    );
  }

  test('a story audience always comes from explicitly selected groups', () {
    final target = StoryTarget();
    expect(target.toAudience(), isNull);
    target.contactGroupIds.addAll([1, 2]);
    expect(target.toAudience()!.all, isFalse);
    expect(target.toAudience()!.contactGroupIds.map((id) => id.toInt()), [
      1,
      2,
    ]);
    target.clear();
    expect(target.toAudience(), isNull);
  });

  testWidgets('the story picker creates and selects a story-only group', (
    tester,
  ) async {
    final target = StoryTarget();
    await pumpView(
      tester,
      Scaffold(
        body: StoryTargetSelector(
          target: target,
          enabled: true,
          onChanged: () {},
          onAudienceChanged: (_) {},
        ),
      ),
    );
    expect(find.text('All contacts'), findsNothing);
    expect(find.byType(MyChip), findsOneWidget);
    expect(target.isEmpty, isTrue);

    await tester.tap(find.text('New story group'));
    await settle(tester);
    final features = tester.widgetList<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect((features.first.title! as Text).data, 'Share stories');
    expect(features.map((feature) => feature.value), [true, false, false]);
    expect(find.text('Background color'), findsNothing);
    expect(find.text('Text color'), findsNothing);
    expect(find.byType(MyInput), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).first, 'Close friends');
    await settle(tester);
    await tester.tap(memberTile('Bob'));
    await tester.tap(find.byType(MyButton));
    await pumpNative(tester, until: () => target.contactGroupIds.isNotEmpty);
    await settle(tester);

    final saved = (await runNative(
      tester,
      () => rust_contact_groups.getContactGroup(
        id: target.contactGroupIds.single,
        transaction: currentDatabaseSession(),
      ),
    ))!;
    expect(saved.shareStories, isTrue);
    expect(saved.showAsLabel, isFalse);
    expect(saved.showAsShortcut, isFalse);
    final members = await runNative(
      tester,
      () => rust_contact_groups.getContactGroupMembers(
        id: saved.id,
        transaction: currentDatabaseSession(),
      ),
    );
    expect(members.map((member) => member.userId), [8]);
    expect(api.storyAudiences.last.all, isFalse);
    expect(
      api.storyAudiences.last.contactGroupIds.map((id) => id.toInt()),
      [saved.id],
    );
    expect(find.text('All contacts'), findsNothing);

    await tester.tap(find.text('Close friends'));
    await settle(tester);
    expect(target.isEmpty, isTrue);
  });

  testWidgets('members follow exchange counts and retain alphabetical ties', (
    tester,
  ) async {
    await runNative(tester, () async {
      for (final (id, count) in [('bob', 30), ('team', 20), ('alice', 10)]) {
        await rust_groups.updateGroup(
          id: id,
          patch: GroupPatch(totalMediaCounter: count),
          transaction: currentDatabaseSession(),
        );
      }
    });
    await pumpEditor(tester);
    List<String> memberOrder() => [
      for (final tile in tester.widgetList<ListTile>(find.byType(ListTile)))
        if (tile.key is ValueKey<String>) (tile.key! as ValueKey<String>).value,
    ];
    expect(memberOrder(), [
      'contact:8',
      'group:team',
      'contact:7',
      'contact:9',
      'group:old-team',
    ]);

    await runNative(
      tester,
      () => rust_groups.updateGroup(
        id: 'alice',
        patch: const GroupPatch(totalMediaCounter: 40),
        transaction: currentDatabaseSession(),
      ),
    );
    await settle(tester);
    expect(memberOrder(), [
      'contact:7',
      'contact:8',
      'group:team',
      'contact:9',
      'group:old-team',
    ]);
    expect(selected(tester, 'Alice'), isTrue);
    expect(selected(tester, 'Old team'), isTrue);
  });

  testWidgets('label colors use bottom sheets and survive disabling labels', (
    tester,
  ) async {
    await pumpEditor(tester);
    expect(find.byType(MyInput), findsNWidgets(2));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await settle(tester);
    expect(find.byType(Wrap), findsNothing);

    await tester.tap(find.text('Text color'));
    await settle(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
    final textColor = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).color ==
              const Color(0xFF4A148C),
    );
    await tester.tap(textColor);
    await settle(tester);
    expect(find.byType(BottomSheet), findsNothing);

    await tester.tap(find.text('Background color'));
    await settle(tester);
    await tester.tap(find.byTooltip('Custom Color'));
    await settle(tester);
    expect(find.byType(CustomColorPickerDialog), findsOneWidget);
    await tester.tap(
      find.ancestor(of: find.text('Ok'), matching: find.byType(MyButton)),
    );
    await settle(tester);
    expect(find.byType(BottomSheet), findsNothing);
    await tester.tap(find.text('Background color'));
    await settle(tester);
    await tester.tap(find.byTooltip('No background'));
    await settle(tester);

    await tester.tap(find.text('Show as visible label'));
    await settle(tester);
    expect(find.text('Background color'), findsNothing);
    expect(find.text('Text color'), findsNothing);
    await tester.tap(find.text('Show as visible label'));
    await settle(tester);
    expect(find.text('Background color'), findsOneWidget);
    expect(find.text('Text color'), findsOneWidget);
    await tester.tap(find.byType(MyButton));
    await settle(tester);
    final saved = (await runNative(
      tester,
      () => rust_contact_groups.getContactGroup(
        id: contactGroup.id,
        transaction: currentDatabaseSession(),
      ),
    ))!;
    expect(saved.textColor, 0xFF4A148C);
    expect(saved.backgroundColor, 0);
    expect(saved.showAsLabel, isTrue);
    expect(saved.name, 'Favorites');
  });

  testWidgets('archived contacts and groups are shown immediately', (
    tester,
  ) async {
    await pumpEditor(tester);
    expect(find.text('Show archived users'), findsNothing);
    expect(memberTile('Alice'), findsOneWidget);
    expect(memberTile('Old team'), findsOneWidget);
    expect(memberTile('Bob'), findsOneWidget);
    // Accepted contacts without a direct chat remain available.
    expect(memberTile('Carol'), findsOneWidget);
    expect(memberTile('Team'), findsOneWidget);
    expect(find.text('Pending'), findsNothing);

    expect(selected(tester, 'Alice'), isTrue);
    expect(selected(tester, 'Old team'), isTrue);
    expect(avatarPaths(tester, 'Bob'), [api.paths[8]]);
    expect(avatarPaths(tester, 'Carol'), [api.paths[9]]);
  });

  testWidgets(
    'direct chat contacts remain available with stale accepted flags',
    (
      tester,
    ) async {
      await runNative(tester, () async {
        await database.customStatement(
          'UPDATE contacts SET accepted = 0 WHERE user_id IN (7, 8)',
        );
        await database.customStatement(
          "INSERT INTO group_members(group_id, contact_id) VALUES ('team', 10)",
        );
      });
      await pumpEditor(tester);
      expect(memberTile('Alice'), findsOneWidget);
      expect(memberTile('Bob'), findsOneWidget);
      expect(memberTile('Carol'), findsOneWidget);
      // A shared group alone does not make a pending contact eligible.
      expect(memberTile('Pending'), findsNothing);
      expect(selected(tester, 'Alice'), isTrue);

      await tester.tap(memberTile('Bob'));
      await tester.tap(find.byType(MyButton));
      await settle(tester);
      final members = await runNative(
        tester,
        () => rust_contact_groups.getContactGroupMembers(
          id: contactGroup.id,
          transaction: currentDatabaseSession(),
        ),
      );
      expect(
        members.where((member) => member.userId != null).map((m) => m.userId),
        unorderedEquals([7, 8]),
      );
    },
  );

  testWidgets('direct chats do not revive blocked or deleted contacts', (
    tester,
  ) async {
    await runNative(tester, () async {
      for (final statement in [
        '''
      INSERT INTO contacts(user_id, username, blocked, deleted_by_user,
                           account_deleted) VALUES
      (11, 'Blocked', 1, 0, 0), (12, 'Removed', 0, 1, 0),
      (13, 'Deleted account', 0, 0, 1), (14, 'Deleted chat', 0, 0, 0)''',
        '''
      INSERT INTO groups(group_id, group_name, is_direct_chat, deleted_content)
      VALUES ('blocked', 'Blocked', 1, 0), ('removed', 'Removed', 1, 0),
      ('deleted-account', 'Deleted account', 1, 0),
      ('deleted-chat', 'Deleted chat', 1, 1)''',
        '''
      INSERT INTO group_members(group_id, contact_id) VALUES
      ('blocked', 11), ('removed', 12), ('deleted-account', 13),
      ('deleted-chat', 14)''',
      ]) {
        await database.customStatement(statement);
      }
    });
    await pumpEditor(tester);
    for (final id in [11, 12, 13, 14]) {
      expect(find.byKey(ValueKey('contact:$id')), findsNothing);
    }
    expect(memberTile('Bob'), findsOneWidget);
  });

  testWidgets('contact state updates keep direct chat members visible', (
    tester,
  ) async {
    await pumpEditor(tester);
    await runNative(
      tester,
      () => rust_contacts.updateContact(
        id: 8,
        patch: const ContactPatch(accepted: false),
        transaction: currentDatabaseSession(),
      ),
    );
    await settle(tester);
    expect(memberTile('Bob'), findsOneWidget);

    await runNative(
      tester,
      () => rust_contacts.updateContact(
        id: 8,
        patch: const ContactPatch(blocked: true),
        transaction: currentDatabaseSession(),
      ),
    );
    await settle(tester);
    expect(memberTile('Bob'), findsNothing);
  });

  testWidgets('avatars follow names after filtering and reordering', (
    tester,
  ) async {
    await pumpEditor(tester);
    await tester.enterText(find.byType(TextField).last, 'car');
    await settle(tester);
    expect(memberTile('Bob'), findsNothing);
    expect(avatarPaths(tester, 'Carol'), [api.paths[9]]);

    await tester.enterText(find.byType(TextField).last, '');
    await settle(tester);
    await runNative(
      tester,
      () => rust_groups.updateGroup(
        id: 'team',
        patch: const GroupPatch(groupName: 'A team'),
        transaction: currentDatabaseSession(),
      ),
    );
    await settle(tester);
    expect(avatarPaths(tester, 'A team'), [api.paths[8], api.paths[7]]);
    expect(avatarPaths(tester, 'Bob'), [api.paths[8]]);
    expect(avatarPaths(tester, 'Carol'), [api.paths[9]]);
  });

  testWidgets('archive changes keep members visible and selected', (
    tester,
  ) async {
    await pumpEditor(tester);
    await tester.tap(memberTile('Bob'));
    await runNative(
      tester,
      () => rust_groups.updateGroup(
        id: 'bob',
        patch: const GroupPatch(archived: true),
        transaction: currentDatabaseSession(),
      ),
    );
    await settle(tester);
    expect(memberTile('Bob'), findsOneWidget);
    expect(selected(tester, 'Bob'), isTrue);

    await runNative(
      tester,
      () => rust_groups.updateGroup(
        id: 'bob',
        patch: const GroupPatch(archived: false),
        transaction: currentDatabaseSession(),
      ),
    );
    await pumpNative(
      tester,
      until: () => avatarPaths(tester, 'Bob').isNotEmpty,
    );
    expect(avatarPaths(tester, 'Bob'), [api.paths[8]]);
    expect(selected(tester, 'Bob'), isTrue);
  });

  testWidgets('saving preserves selected archived members', (
    tester,
  ) async {
    await pumpEditor(tester);
    await tester.tap(find.text('Bob'));
    await tester.tap(find.byType(MyButton));
    await settle(tester);
    final members = await runNative(
      tester,
      () => rust_contact_groups.getContactGroupMembers(
        id: contactGroup.id,
        transaction: currentDatabaseSession(),
      ),
    );
    expect(
      members
          .where((member) => member.userId != null)
          .map((member) => member.userId),
      unorderedEquals([7, 8]),
    );
    expect(
      members
          .where((member) => member.groupId != null)
          .map((member) => member.groupId),
      ['old-team'],
    );
  });
}
