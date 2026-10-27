import 'dart:convert';
import 'dart:io';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/core/user_config.dart' hide ThemeMode;
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/json/onboarding_state.model.dart';
import 'package:twonly/src/model/protobuf/client/generated/passwordless_recovery.pb.dart';
import 'package:twonly/src/providers/routing.provider.dart';
import 'package:twonly/src/services/passwordless_recovery.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/help_a_friend.passwordless_recovery.view.dart';

import '../helpers/native_database.dart';
import '../mocks/user_config.dart';

UserConfig _user() => testUserConfig(
  userId: 1,
  username: 'me',
  displayName: 'Me',
  subscriptionPlan: 'Free',
  currentSetupPage: null,
  appVersion: 100,
);

class _RecoveryApi extends NativeTestApi {
  UserConfig config = _user();
  List<Contact> contactsWhenEnabled = [];
  int heartbeats = 0;
  List<FrbPasswordlessNotificationMessage> messages = [];
  List<int> excludedMessageIds = [];

  @override
  Future<UserConfig?> crateBridgeUserConfigUserConfigApiLoad() async => config;

  @override
  UserConfig crateBridgeUserConfigUserConfigApiClone({
    required UserConfig config,
  }) => _user()..passwordLessRecovery = config.passwordLessRecovery;

  @override
  Future<UserConfig> crateBridgeUserConfigUserConfigApiUpdate({
    required UserConfig base,
    required UserConfig config,
  }) async {
    if (config.passwordLessRecovery != null) {
      contactsWhenEnabled = await rust_contacts.listContacts(
        input: db_contacts.ContactQuery(
          filter: db_contacts.ContactFilter.all,
          ids: Int64List(0),
        ),
        transaction: currentDatabaseSession(),
      );
    }
    return this.config = config;
  }

  @override
  Future<Uint8List>
  crateBridgeWrapperKeyManagerRustKeyManagerSerialize() async =>
      Uint8List.fromList([42]);

  @override
  Future<List<Uint8List>> crateBridgeWrapperRustUtilsGenerateShares({
    required List<int> secret,
    required int total,
    required int threshold,
  }) async =>
      List.generate(total, (index) => Uint8List.fromList([index + 1, 42]));

  @override
  Future<void>
  crateBridgeApiRustApiPerformPasswordlessRecoveryHeartbeat() async {
    heartbeats++;
  }

  @override
  Future<List<FrbPasswordlessNotificationMessage>>
  crateBridgeApiRustApiCheckForPasswordlessNotification({
    required String notificationId,
    required List<int> downloadAuthToken,
    required Int64List alreadyReceivedMessageIds,
  }) async {
    excludedMessageIds = alreadyReceivedMessageIds
        .map((id) => id.toInt())
        .toList();
    return messages
        .where((message) => !excludedMessageIds.contains(message.id))
        .toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final api = _RecoveryApi();
  late Directory directory;
  final key = List<int>.filled(32, 42);
  String link(String id) =>
      '${PasswordlessRecoveryService.linkPrefix}$id/${base64Url.encode(key)}';

  setUpAll(() => initializeNativeDatabase(api: api));
  tearDownAll(RustLib.dispose);
  setUp(() async {
    await locator.reset();
    await TestDatabase.create();
    locator.registerSingleton<UserService>(UserService());
    api
      ..config = _user()
      ..contactsWhenEnabled = []
      ..heartbeats = 0
      ..messages = [];
    userService.currentUser = api.config;
    directory = Directory.systemTemp.createTempSync(
      'twonly-recovery-delivery-',
    );
    AppEnvironment.initTesting(
      customSupportDir: directory.path,
      customCacheDir: directory.path,
    );
  });
  tearDown(() async {
    await locator.reset();
    directory.deleteSync(recursive: true);
  });

  test('every trusted friend has a share before recovery is enabled', () async {
    for (final id in [2, 3, 4]) {
      await testDatabase.insert(
        ContactPatch(userId: id, username: 'friend_$id'),
      );
    }
    final success =
        await PasswordlessRecoveryService.enablePasswordlessRecovery(
          trustedFriendIds: [2, 3, 4],
          secondFactorType: SecondFactorType.none,
          secondFactorValue: '',
          threshold: 2,
        );
    expect(success, isTrue);
    expect(api.contactsWhenEnabled, hasLength(3));
    expect(
      api.contactsWhenEnabled.every(
        (contact) =>
            contact.recoveryIsTrustedFriend &&
            contact.recoverySecretShare != null,
      ),
      isTrue,
    );
    expect(api.heartbeats, 1);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: rootNavigatorKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(),
      ),
    );
  }

  testWidgets('recovery link can be reopened after cancelling', (tester) async {
    await pumpApp(tester);
    final url = link('retry');
    await PasswordlessRecoveryService.handleRecoveryLink(url);
    await tester.pumpAndSettle();
    expect(find.byType(HelpAFriendPasswordlessRecoveryView), findsOneWidget);
    // Duplicate platform intents must not stack screens.
    await PasswordlessRecoveryService.handleRecoveryLink(url);
    rootNavigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.byType(HelpAFriendPasswordlessRecoveryView), findsNothing);
    await PasswordlessRecoveryService.handleRecoveryLink(url);
    await tester.pumpAndSettle();
    expect(find.byType(HelpAFriendPasswordlessRecoveryView), findsOneWidget);
    rootNavigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'a delivery before navigation is ready does not consume the link',
    (tester) async {
      final url = link('startup');
      await PasswordlessRecoveryService.handleRecoveryLink(url);
      await pumpApp(tester);
      await PasswordlessRecoveryService.handleRecoveryLink(url);
      await tester.pumpAndSettle();
      expect(find.byType(HelpAFriendPasswordlessRecoveryView), findsOneWidget);
      rootNavigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'invalid encryption keys do not prevent a corrected link opening',
    (tester) async {
      await pumpApp(tester);
      for (final suffix in [
        '%',
        base64Url.encode([42]),
      ]) {
        await PasswordlessRecoveryService.handleRecoveryLink(
          '${PasswordlessRecoveryService.linkPrefix}corrected/$suffix',
        );
      }
      await PasswordlessRecoveryService.handleRecoveryLink(link('corrected'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpAFriendPasswordlessRecoveryView), findsOneWidget);
      rootNavigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'polling receives multiple helpers and excludes only received message IDs',
    () async {
      final state = OnboardingState(
        notificationId: 'multiple',
        downloadAuthToken: key,
        encryptionKey: key,
        serverRegistered: true,
      );
      for (final id in [2, 3]) {
        final plaintext = TrustedFriendShare(
          trustedFriend: TrustedFriendShare_User(
            userId: Int64(id),
            displayName: 'Friend $id',
          ),
          shareUser: TrustedFriendShare_User(
            userId: Int64(1),
            displayName: 'Me',
          ),
          threshold: 2,
          sharedSecretData: [id, 42],
        ).writeToBuffer();
        final box = await Xchacha20.poly1305Aead().encrypt(
          plaintext,
          secretKey: SecretKey(key),
        );
        api.messages.add(
          FrbPasswordlessNotificationMessage(
            id: id,
            encryptedMessage: EncryptedEnvelope(
              encryptedData: box.cipherText,
              iv: box.nonce,
              mac: box.mac.bytes,
            ).writeToBuffer(),
          ),
        );
      }
      expect(
        await PasswordlessRecoveryService.checkAndStorePasswordlessMessages(
          state,
        ),
        isTrue,
      );
      expect(
        state.receivedShares.map((share) => share.trustedFriendDisplayName),
        ['Friend 2', 'Friend 3'],
      );
      expect(
        await PasswordlessRecoveryService.checkAndStorePasswordlessMessages(
          state,
        ),
        isFalse,
      );
      expect(api.excludedMessageIds, [2, 3]);
      expect(state.receivedShares, hasLength(2));
    },
  );
}
