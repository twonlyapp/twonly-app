import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/contact/contact_group_settings.view.dart';

class _AvatarApi implements RustLibApi {
  final paths = <int, String>{};

  @override
  Future<String?> crateBridgeApiRustApiEnsureAvatarPng({
    required int contactId,
  }) async => paths[contactId];

  @override
  Future<void> crateBridgeApiRustApiRefreshWidgetManifest() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final api = _AvatarApi();
  late Directory directory;
  late TwonlyDB database;
  late ContactGroup contactGroup;

  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() async {
    await locator.reset();
    database = TwonlyDB.forTesting(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    locator.registerSingleton<TwonlyDB>(database);
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
    final id = await database.contactGroupsDao.createContactGroup(
      name: 'Favorites',
      textColor: 0xFF000000,
      backgroundColor: 0,
      showAsShortcut: false,
      showAsLabel: true,
      shareStories: false,
    );
    await database.contactGroupsDao.replaceMembers(
      id,
      userIds: [7],
      groupIds: ['old-team'],
    );
    contactGroup = await (database.select(
      database.contactGroups,
    )..where((group) => group.id.equals(id))).getSingle();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('eu.twonly/runtime_storage'),
          (_) async => null,
        );
  });

  tearDown(() async {
    await database.close();
    await locator.reset();
    await directory.delete(recursive: true);
    AppEnvironment.initTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('eu.twonly/runtime_storage'),
          null,
        );
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ContactGroupSettingsView(contactGroup: contactGroup),
      ),
    );
    await settle(tester);
  }

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

  Future<void> toggleArchived(WidgetTester tester) async {
    await tester.tap(find.text('Show archived users'));
    await settle(tester);
  }

  testWidgets('archived members are hidden until the switch is enabled', (
    tester,
  ) async {
    await pumpEditor(tester);
    expect(find.text('Alice'), findsNothing);
    expect(find.text('Old team'), findsNothing);
    expect(memberTile('Bob'), findsOneWidget);
    // Accepted contacts without a direct chat remain available.
    expect(memberTile('Carol'), findsOneWidget);
    expect(memberTile('Team'), findsOneWidget);
    expect(find.text('Pending'), findsNothing);

    await toggleArchived(tester);
    expect(memberTile('Alice'), findsOneWidget);
    expect(memberTile('Old team'), findsOneWidget);
    expect(selected(tester, 'Alice'), isTrue);
    expect(selected(tester, 'Old team'), isTrue);
    expect(avatarPaths(tester, 'Bob'), [api.paths[8]]);
    expect(avatarPaths(tester, 'Carol'), [api.paths[9]]);

    await toggleArchived(tester);
    expect(find.text('Alice'), findsNothing);
    await toggleArchived(tester);
    expect(selected(tester, 'Alice'), isTrue);
    expect(selected(tester, 'Old team'), isTrue);
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
    await database.groupsDao.updateGroup(
      'team',
      const GroupsCompanion(groupName: Value('A team')),
    );
    await settle(tester);
    expect(avatarPaths(tester, 'A team'), [api.paths[8], api.paths[7]]);
    expect(avatarPaths(tester, 'Bob'), [api.paths[8]]);
    expect(avatarPaths(tester, 'Carol'), [api.paths[9]]);
  });

  testWidgets('archive changes update the open member list', (tester) async {
    await pumpEditor(tester);
    await database.groupsDao.updateGroup(
      'bob',
      const GroupsCompanion(archived: Value(true)),
    );
    await settle(tester);
    expect(memberTile('Bob'), findsNothing);

    await database.groupsDao.updateGroup(
      'bob',
      const GroupsCompanion(archived: Value(false)),
    );
    await settle(tester);
    expect(avatarPaths(tester, 'Bob'), [api.paths[8]]);
  });

  testWidgets('saving preserves selected members hidden by archive status', (
    tester,
  ) async {
    await pumpEditor(tester);
    await tester.tap(find.text('Bob'));
    await tester.tap(find.byType(MyButton));
    await settle(tester);
    final members = await database.contactGroupsDao.getMembers(contactGroup.id);
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
