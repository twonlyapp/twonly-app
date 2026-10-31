import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as contacts;
import 'package:twonly/core/database/app/user_discovery/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/visual/components/verification_badge.comp.dart';
import 'package:twonly/src/visual/components/verification_failure_dialog.comp.dart';
import 'package:twonly/src/visual/elements/svg_icon.element.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/contact/add_new_contact_components/friend_suggestions.comp.dart';

import '../helpers/native_database.dart';
import '../mocks/user_config.dart';

final _announcedKey = Uint8List.fromList(List.filled(33, 5));

class _DiscoveryApi extends NativeTestApi {
  Uint8List responseKey = Uint8List.fromList(_announcedKey);
  final requests = <(int, List<int>)>[];

  @override
  Future<FrbUserData> crateBridgeApiRustApiGetUserById({
    required int userId,
  }) async {
    expectSync(userId, 7);
    return FrbUserData(
      userId: userId,
      username: Uint8List.fromList(utf8.encode('carol')),
      publicIdentityKey: responseKey,
    );
  }

  @override
  Future<bool> crateBridgeApiRustApiTryRequestContactById({
    required int contactId,
    required List<int> expectedPublicKey,
  }) async {
    requests.add((contactId, List.of(expectedPublicKey)));
    await testDatabase.customStatement(
      'UPDATE contacts SET requested_by_user = 1 WHERE user_id = ?',
      [contactId],
    );
    // Model the identity snapshot refreshed by native session establishment.
    await testDatabase.customStatement(
      'UPDATE user_discovery_announced_users SET session_identity_key = ? '
      'WHERE announced_user_id = ?',
      [Uint8List.fromList(expectedPublicKey), contactId],
    );
    return true;
  }
}

void main() {
  final api = _DiscoveryApi();

  setUpAll(() => initializeNativeDatabase(api: api));
  tearDownAll(RustLib.dispose);
  setUp(() async {
    await TestDatabase.create();
    await locator.reset();
    locator.registerSingleton<UserService>(UserService());
    userService.currentUser = testUserConfig(
      userId: 42,
      username: 'me',
      displayName: 'Me',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
      appVersion: 192,
    );
    api
      ..responseKey = Uint8List.fromList(_announcedKey)
      ..requests.clear();
    await testDatabase.customStatement(
      "INSERT INTO contacts(user_id, username, accepted) VALUES (8, 'bob', 1)",
    );
    await testDatabase.customStatement(
      "INSERT INTO key_verifications(contact_id, type) VALUES (8, 'manual')",
    );
    await testDatabase.customStatement(
      'INSERT INTO user_discovery_announced_users( '
      'announced_user_id, announced_public_key, public_id, username) '
      "VALUES (7, ?, 70, 'carol')",
      [_announcedKey],
    );
    await testDatabase.customStatement(
      'INSERT INTO user_discovery_user_relations( '
      'announced_user_id, from_contact_id, public_key_verified_timestamp) '
      'VALUES (7, 8, 123)',
    );
  });
  tearDown(locator.reset);

  Future<void> requestSuggestion(WidgetTester tester) async {
    final user = UserDiscoveryAnnouncedUser(
      announcedUserId: 7,
      announcedPublicKey: _announcedKey,
      publicId: 70,
      username: 'carol',
      wasShownToTheUser: true,
      isHidden: false,
      wasAskedFriends: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: FriendSuggestionsComp({user: const []})),
      ),
    );
    await pumpNative(tester);
    final context = tester.element(find.byType(FriendSuggestionsComp));
    await tester.tap(
      find.text(AppLocalizations.of(context)!.friendSuggestionsRequest),
    );
    await pumpNative(tester);
  }

  for (final (description, key, verified) in [
    ('a changed identity key', Uint8List.fromList(List.filled(33, 9)), false),
    ('a matching identity key', Uint8List.fromList(_announcedKey), true),
  ]) {
    testWidgets('adds a contact with $description and applies matching trust', (
      tester,
    ) async {
      api.responseKey = key;

      await requestSuggestion(tester);
      await pumpNative(tester, until: () => api.requests.isNotEmpty);

      expect(find.byType(VerificationFailureDialog), findsNothing);
      expect(api.requests.single.$1, 7);
      expect(api.requests.single.$2, orderedEquals(key));
      final contact = await runNative(
        tester,
        () => contacts.getContact(id: 7, transaction: currentDatabaseSession()),
      );
      expect(contact!.username, 'carol');
      expect(contact.requestedByUser, 1);
      final evidence = await runNative(
        tester,
        () => testDatabase
            .customSelect(
              'SELECT COUNT(*) AS n FROM valid_discovery_verifications '
              'WHERE announced_user_id = 7',
            )
            .getSingle(),
      );
      expect(evidence.read<int>('n'), verified ? 1 : 0);

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: VerificationBadgeComp(
              contact: contact,
              showOnlyIfVerified: true,
              clickable: false,
            ),
          ),
        ),
      );
      await pumpNative(
        tester,
        until: verified
            ? () => find.byType(SvgIcon).evaluate().isNotEmpty
            : null,
      );
      expect(find.byType(SvgIcon), verified ? findsOneWidget : findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
