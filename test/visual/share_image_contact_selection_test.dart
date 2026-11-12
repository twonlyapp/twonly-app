import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge.dart' show FlameState;
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/camera/share_image_contact_selection.view.dart';

import '../helpers/native_database.dart';
import '../mocks/user_config.dart';

class _SelectionApi extends NativeTestApi {
  bool delayFlames = false;
  final pending = <Completer<Map<String, FlameState>>>[];

  @override
  Future<Uint8List>
  crateBridgeWrapperSignalRustSignalGetUserPublicKey() async => Uint8List(32);

  @override
  Future<String?> crateBridgeApiRustApiCurrentUserAvatarPath() async => null;

  @override
  Future<Map<String, FlameState>> crateBridgeGroupsFlameStates({
    required List<String> groupIds,
  }) {
    if (!delayFlames) return Future.value({});
    final completer = Completer<Map<String, FlameState>>();
    pending.add(completer);
    return completer.future;
  }
}

void main() {
  final api = _SelectionApi();
  setUpAll(() => initializeNativeDatabase(api: api));
  tearDown(locator.reset);

  testWidgets('selections and search update without another native reply', (
    tester,
  ) async {
    locator.registerSingleton<UserService>(UserService());
    userService.currentUser = testUserConfig(
      userId: 1,
      username: 'me',
      displayName: 'Me',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
      appVersion: 180,
    );
    await tester.runAsync(() async {
      final database = await TestDatabase.create();
      await database.customStatement(
        'INSERT INTO groups(group_id, group_name, pinned, last_message_exchange) '
        "VALUES ('pinned', 'Favorite', 1, 0), "
        "('anna', 'Anna', 0, 2), ('ben', 'Ben', 0, 1)",
      );
    });
    final selected = HashSet<String>();
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShareImageView(
          selectedGroupIds: selected,
          updateSelectedGroupIds: (id, checked) {
            if (checked) {
              selected.add(id);
            } else {
              selected.remove(id);
            }
          },
          mediaStoreFuture: null,
          mediaFileService: MediaFileService(
            const MediaFile(
              mediaId: 'media',
              typeName: 'image',
              cloudStateName: 'none',
              requiresAuthentication: true,
              stored: true,
              isDraftMedia: false,
              isWidgetMedia: false,
              isFavorite: false,
              hasCropAnalyzed: false,
              hasThumbnail: false,
              galleryExportPending: false,
              createdAtSeconds: 0,
            ),
          ),
          additionalData: null,
          sendToWidget: false,
        ),
      ),
    );
    await pumpNative(
      tester,
      until: () => find.text('Ben').evaluate().isNotEmpty,
    );
    // Any new native lookup stays pending throughout the interactions.
    api.delayFlames = true;

    Checkbox checkbox(String name) => tester.widget<Checkbox>(
      find.descendant(
        of: find.ancestor(of: find.text(name), matching: find.byType(ListTile)),
        matching: find.byType(Checkbox),
      ),
    );

    await tester.tap(find.text('Anna'));
    await tester.pump();
    expect(checkbox('Anna').value, isTrue);
    expect(find.text('Send (1)'), findsOneWidget);

    await tester.tap(find.text('Ben'));
    await tester.pump();
    expect(checkbox('Anna').value, isTrue);
    expect(checkbox('Ben').value, isTrue);
    expect(find.text('Send (2)'), findsOneWidget);

    await tester.tap(find.text('Anna'));
    await tester.pump();
    expect(checkbox('Anna').value, isFalse);
    expect(checkbox('Ben').value, isTrue);

    await tester.tap(find.text('Favorite'));
    await tester.pump();
    expect(selected, {'pinned', 'ben'});
    // Selecting above the list promotes Ben immediately.
    final list = tester.widget<UserList>(find.byType(UserList));
    expect(list.groups.map((group) => group.groupId), ['ben', 'anna']);

    await tester.enterText(find.byType(TextField), 'Anna');
    await tester.pump();
    expect(find.text('Ben'), findsNothing);
    expect(find.text('Favorite'), findsNothing);
    expect(
      find.descendant(of: find.byType(UserList), matching: find.text('Anna')),
      findsOneWidget,
    );
    expect(api.pending, isEmpty);

    await tester.pumpWidget(const SizedBox());
  });
}
