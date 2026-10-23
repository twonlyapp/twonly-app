import 'dart:convert';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as contacts;
import 'package:twonly/core/bridge/database/groups.dart' as groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/model/protobuf/client/generated/qr.pb.dart';
import 'package:twonly/src/services/intent/links.intent.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/qr.utils.dart';

import '../helpers/native_database.dart';
import '../mocks/user_config.dart';

final _peerKey = Uint8List.fromList(List.filled(33, 5));

class _QrApi extends NativeTestApi {
  bool requestSucceeds = true;
  int requests = 0;
  final proofs = <pb.EncryptedContent>[];

  @override
  Future<bool> crateBridgeApiRustApiTryRequestContactById({
    required int contactId,
    required List<int> expectedPublicKey,
  }) async {
    expectSync(contactId, 7);
    expectSync(expectedPublicKey, _peerKey);
    requests++;
    if (requestSucceeds) {
      await testDatabase.customStatement(
        'UPDATE contacts SET requested_by_user = 1 WHERE user_id = 7',
      );
    }
    return requestSucceeds;
  }

  @override
  Future<Uint8List>
  crateBridgeWrapperSignalRustSignalGetUserPublicKey() async =>
      Uint8List.fromList(List.filled(33, 8));

  @override
  Future<Uint8List?> crateBridgeWrapperSignalRustSignalGetContactPublicKey({
    required int contactId,
  }) async => _peerKey;

  @override
  Future<Uint8List?> crateBridgeApiRustApiSendEncryptedContent({
    required int contactId,
    required List<int> content,
    String? messageId,
    bool? onlySendIfNoReceiptsAreOpen,
    bool? onlyReturnEncryptedData,
    bool? blocking,
  }) async {
    proofs.add(pb.EncryptedContent.fromBuffer(content));
    return null;
  }
}

String profileLink(PublicProfile profile) =>
    '${QrCodeUtils.linkPrefix}${base64Url.encode(QREnvelope(data: profile.writeToBuffer()).writeToBuffer())}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final api = _QrApi();
  final now = DateTime.utc(2026, 10, 24, 12);

  PublicProfile profile({Duration age = Duration.zero}) => PublicProfile(
    userId: Int64(7),
    username: 'alice',
    publicIdentityKey: _peerKey,
    secretVerificationToken: List.filled(16, 17),
    timestamp: Int64(now.subtract(age).millisecondsSinceEpoch),
  );

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
      ..requestSucceeds = true
      ..requests = 0
      ..proofs.clear();
  });
  tearDown(locator.reset);

  test(
    'only tokens from the last five minutes qualify for automatic acceptance',
    () {
      withClock(Clock.fixed(now), () {
        expect(QrCodeUtils.hasFreshVerificationToken(profile()), isTrue);
        expect(
          QrCodeUtils.hasFreshVerificationToken(
            profile(age: const Duration(minutes: 5)),
          ),
          isTrue,
        );
        expect(
          QrCodeUtils.hasFreshVerificationToken(
            profile(age: const Duration(minutes: 5, milliseconds: 1)),
          ),
          isFalse,
        );
        expect(
          QrCodeUtils.hasFreshVerificationToken(
            profile(age: const Duration(milliseconds: -1)),
          ),
          isFalse,
        );
        expect(
          QrCodeUtils.hasFreshVerificationToken(profile()..clearTimestamp()),
          isFalse,
        );
        expect(
          QrCodeUtils.hasFreshVerificationToken(
            profile()..clearSecretVerificationToken(),
          ),
          isFalse,
        );
      });
    },
  );

  test(
    'a fresh scan sends proof and waits for acceptance before creating a chat',
    () async {
      final result = await withClock(
        Clock.fixed(now),
        () => QrCodeUtils.handleQrCodeLink(profileLink(profile())),
      );

      expect(result.status, QrCodeLinkStatus.contactRequested);
      final contact = (await contacts.getContact(
        id: 7,
        transaction: currentDatabaseSession(),
      ))!;
      expect(contact.acceptedFlag, 0);
      expect(contact.requestedFlag, 0);
      expect(contact.requestedByUser, 1);
      expect(api.requests, 1);
      expect(
        api.proofs.single.keyVerificationProof.calculatedMac,
        hasLength(32),
      );
      expect(
        await groups.listGroups(
          input: const GroupQuery(
            filter: GroupFilter.directContact,
            contactId: 7,
          ),
          transaction: currentDatabaseSession(),
        ),
        isEmpty,
      );
      final verification = await testDatabase
          .customSelect(
            'SELECT type FROM key_verifications WHERE contact_id = 7',
          )
          .getSingle();
      expect(verification.read<String>('type'), 'qrScanned');
    },
  );

  test('older QR codes keep the manual contact request flow', () async {
    final result = await withClock(
      Clock.fixed(now),
      () => QrCodeUtils.handleQrCodeLink(
        profileLink(profile(age: const Duration(minutes: 6))),
      ),
    );
    expect(result.status, QrCodeLinkStatus.newContact);
    expect(api.requests, 0);
    expect(
      await contacts.getContact(id: 7, transaction: currentDatabaseSession()),
      isNull,
    );
  });

  test('a failed session request does not accept and can be retried', () async {
    api.requestSucceeds = false;
    final link = profileLink(profile());
    final failed = await withClock(
      Clock.fixed(now),
      () => QrCodeUtils.handleQrCodeLink(link),
    );
    expect(failed.status, QrCodeLinkStatus.error);
    expect(
      (await contacts.getContact(
        id: 7,
        transaction: currentDatabaseSession(),
      ))!.acceptedFlag,
      0,
    );
    expect(
      await groups.listGroups(
        input: const GroupQuery(
          filter: GroupFilter.directContact,
          contactId: 7,
        ),
        transaction: currentDatabaseSession(),
      ),
      isEmpty,
    );
    api.requestSucceeds = true;
    final retried = await withClock(
      Clock.fixed(now),
      () => QrCodeUtils.handleQrCodeLink(link),
    );
    expect(retried.status, QrCodeLinkStatus.contactRequested);
  });

  testWidgets('a fresh QR deep link stays on the current screen', (
    tester,
  ) async {
    late BuildContext context;
    var openedChat = false;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (builderContext, state) {
            context = builderContext;
            return const Scaffold(body: Text('Home'));
          },
        ),
        GoRoute(
          path: '/chats/messages/:groupId',
          builder: (context, state) {
            openedChat = true;
            return const Scaffold(body: Text('Chat opened'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final handled = await tester.runAsync(
      () => withClock(
        Clock.fixed(now),
        () => handleIntentUrl(context, Uri.parse(profileLink(profile()))),
      ),
    );
    await tester.pumpAndSettle();
    expect(handled, isTrue);
    expect(find.text('Home'), findsOneWidget);
    expect(openedChat, isFalse);
    expect(router.routeInformationProvider.value.uri.path, '/');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
