import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/settings/developer/developer.view.dart';

import '../helpers/native_database.dart';
import '../mocks/user_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ownId = 1000000001;

  setUpAll(initializeNativeDatabase);
  tearDownAll(RustLib.dispose);

  setUp(() async {
    await locator.reset();
    locator.registerSingleton<UserService>(
      UserService()
        ..currentUser = testUserConfig(
          userId: ownId,
          username: 'me',
          displayName: 'Me',
          subscriptionPlan: 'Free',
          currentSetupPage: null,
          appVersion: 207,
        ),
    );
    final database = await TestDatabase.create();
    await database.customStatement('''
      INSERT INTO contacts(user_id, username, accepted, user_discovery_excluded)
      VALUES (1000000000, 'existing', 1, 0),
        (-1, 'debug_contact_01', 1, 1),
        (-2, 'debug_contact_02', 1, 1),
        (-3, 'unrelated', 0, 0)
    ''');
  });

  tearDown(locator.reset);

  Future<List<Contact>> contacts() => rust_contacts.listContacts(
    input: ContactQuery(filter: ContactFilter.all, ids: Int64List(0)),
    transaction: currentDatabaseSession(),
  );

  testWidgets(
    'mock contacts replace invalid IDs, preserve existing accounts, and open chats',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DeveloperSettingsView(),
        ),
      );
      await tester.pumpAndSettle();
      final generate = find.text('Generate 40 Mock Contacts');
      await tester.scrollUntilVisible(generate, 300);

      Future<void> generateContacts() async {
        await tester.tap(generate);
        await tester.pump();
        await pumpNative(
          tester,
          until: () =>
              find.byType(CircularProgressIndicator).evaluate().isEmpty,
        );
      }

      await generateContacts();
      var rows = await runNative(tester, contacts);
      var mocks = rows
          .where((contact) => contact.username.startsWith('debug_contact_'))
          .toList();
      expect(rows, hasLength(42));
      expect(mocks, hasLength(40));
      expect(mocks.every((contact) => contact.userId >= 0), isTrue);
      expect(mocks.every((contact) => contact.accepted), isTrue);
      expect(mocks.any((contact) => contact.userId == ownId), isFalse);
      expect(
        rows.singleWhere((contact) => contact.userId == 1000000000).username,
        'existing',
      );
      expect(
        rows.singleWhere((contact) => contact.userId == -3).username,
        'unrelated',
      );

      // Exercise the Rust path that rejected the earlier negative IDs.
      for (final contact in mocks) {
        final group = await runNative(
          tester,
          () => rust_groups.createDirectGroup(
            contact: contact.userId,
            ownId: ownId,
            patch: GroupPatch(groupName: contact.username),
            transaction: currentDatabaseSession(),
          ),
        );
        expect(group.isDirectChat, isTrue);
      }

      await tester.pumpAndSettle();
      await generateContacts();
      rows = await runNative(tester, contacts);
      mocks = rows
          .where((contact) => contact.username.startsWith('debug_contact_'))
          .toList();
      expect(rows, hasLength(82));
      expect(mocks, hasLength(80));
      expect(mocks.map((contact) => contact.userId).toSet(), hasLength(80));
      expect(mocks.map((contact) => contact.username).toSet(), hasLength(80));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
