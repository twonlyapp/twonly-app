import 'dart:convert' show utf8;
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge.dart' as bridge;
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/core/bridge/wrapper/signal.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/core/signal/engine.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/callbacks/callbacks.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as api_pb;
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as msg_pb;
import 'package:twonly/src/services/api/api.service.dart';
import 'package:twonly/src/services/signal/encryption.signal.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/utils/log.dart';

class _MigrationApiService extends ApiService {
  final Map<int, api_pb.Response_UserData> users = {};
  final List<int> requestedUserIds = [];

  @override
  Future<api_pb.Response_UserData?> getUserById(int userId) async {
    requestedUserIds.add(userId);
    return users[userId];
  }
}

api_pb.Response_UserData _userDataFromBundle(
  int userId,
  FrbPreKeyBundle bundle,
) => api_pb.Response_UserData(
  userId: Int64(userId),
  username: utf8.encode('contact_$userId'),
  registrationId: Int64(bundle.registrationId),
  publicIdentityKey: bundle.identityKey,
  pqcBundle: api_pb.Response_PqcBundle(
    prekey: api_pb.Response_PqcPreKey(
      eccPreKeyId: bundle.preKeyId != null ? Int64(bundle.preKeyId!) : null,
      eccPreKey: bundle.preKeyPublic,
      kyberPreKeyId: Int64(bundle.kyberPreKeyId),
      kyberPreKey: bundle.kyberPreKeyPublic,
      kyberPreKeySignature: bundle.kyberPreKeySignature,
    ),
    eccSignedPrekeyId: Int64(bundle.signedPreKeyId),
    eccSignedPrekey: bundle.signedPreKeyPublic,
    eccSignedPrekeySignature: bundle.signedPreKeySignature,
  ),
);

void main() {
  if (!Platform.isMacOS) {
    return;
  }

  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late TwonlyDB db;
  late _MigrationApiService api;

  setUpAll(() async {
    Log.init();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final dylibPath =
        '${Directory.current.path}/rust/target/debug/librust_lib_twonly.dylib';
    if (File(dylibPath).existsSync()) {
      await RustLib.init(externalLibrary: ExternalLibrary.open(dylibPath));
    } else {
      await RustLib.init();
    }
    await initFlutterCallbacksForRust();

    tempDir = Directory.systemTemp.createTempSync('twonly_pqc_migration_test_');
    AppEnvironment.initTesting(
      customCacheDir: tempDir.path,
      customSupportDir: tempDir.path,
    );

    await bridge.initializeTwonlyFlutter(
      config: bridge.InitConfig(
        databaseDir: tempDir.path,
        dataDir: tempDir.path,
      ),
    );

    db = TwonlyDB(NativeDatabase.memory());
    api = _MigrationApiService();
    locator
      ..registerFactory<TwonlyDB>(() => db)
      ..registerSingleton<ApiService>(api);
  });

  setUp(() async {
    api
      ..users.clear()
      ..requestedUserIds.clear();
    await createIfNotExistsSignalIdentity();
    await RustKeyManager.setUserId(userId: 1);
  });

  tearDownAll(() async {
    await db.close();
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  test('PQC Migration Test: V1 to V2', () async {
    const contactId = 999;

    // 1. Setup contact as V1
    await db.contactsDao.insertContact(
      ContactsCompanion.insert(
        userId: const Value(contactId),
        username: 'test_pqc_user',
        accepted: const Value(true),
        signalVersion: const Value(SignalVersion.v1),
      ),
    );

    var contact = await db.contactsDao.getContactById(contactId);
    expect(contact, isNotNull);
    expect(contact!.signalVersion, SignalVersion.v1);

    // 2. Generate a valid PQC bundle via RustSignal
    final generatedBundle = await RustSignal.generateBundle();

    final userData = api_pb.Response_UserData(
      userId: Int64(contactId),
      username: utf8.encode('test_pqc_user'),
      registrationId: Int64(generatedBundle.registrationId),
      publicIdentityKey: generatedBundle.identityKey,
      pqcBundle: api_pb.Response_PqcBundle(
        prekey: api_pb.Response_PqcPreKey(
          eccPreKeyId: generatedBundle.preKeyId != null
              ? Int64(generatedBundle.preKeyId!)
              : null,
          eccPreKey: generatedBundle.preKeyPublic,
          kyberPreKeyId: Int64(generatedBundle.kyberPreKeyId),
          kyberPreKey: generatedBundle.kyberPreKeyPublic,
          kyberPreKeySignature: generatedBundle.kyberPreKeySignature,
        ),
        eccSignedPrekeyId: Int64(generatedBundle.signedPreKeyId),
        eccSignedPrekey: generatedBundle.signedPreKeyPublic,
        eccSignedPrekeySignature: generatedBundle.signedPreKeySignature,
      ),
    );

    // 3. Process the UserData containing the PQC bundle
    final success = await processSignalUserData(userData);
    expect(success, isTrue, reason: 'Failed to process PQC user data');

    // 4. Verify contact was upgraded to V2
    contact = await db.contactsDao.getContactById(contactId);
    expect(contact, isNotNull);
    expect(contact!.signalVersion, SignalVersion.v2);
  });

  test('PQC Encryption and Decryption V2', () async {
    const contactId = 888;

    // Setup contact as V2
    await db.contactsDao.insertContact(
      ContactsCompanion.insert(
        userId: const Value(contactId),
        username: 'test_pqc_user_2',
        accepted: const Value(true),
        signalVersion: const Value(SignalVersion.v2),
      ),
    );

    // Generate bundle and process it for the contact to establish a session
    final generatedBundle = await RustSignal.generateBundle();

    final userData = api_pb.Response_UserData(
      userId: Int64(contactId),
      username: utf8.encode('test_pqc_user_2'),
      registrationId: Int64(generatedBundle.registrationId),
      publicIdentityKey: generatedBundle.identityKey,
      pqcBundle: api_pb.Response_PqcBundle(
        prekey: api_pb.Response_PqcPreKey(
          eccPreKeyId: generatedBundle.preKeyId != null
              ? Int64(generatedBundle.preKeyId!)
              : null,
          eccPreKey: generatedBundle.preKeyPublic,
          kyberPreKeyId: Int64(generatedBundle.kyberPreKeyId),
          kyberPreKey: generatedBundle.kyberPreKeyPublic,
          kyberPreKeySignature: generatedBundle.kyberPreKeySignature,
        ),
        eccSignedPrekeyId: Int64(generatedBundle.signedPreKeyId),
        eccSignedPrekey: generatedBundle.signedPreKeyPublic,
        eccSignedPrekeySignature: generatedBundle.signedPreKeySignature,
      ),
    );

    final success = await processSignalUserData(userData);
    expect(success, isTrue);

    // Encrypt a message
    final plaintext = msg_pb.EncryptedContent(
      textMessage: msg_pb.EncryptedContent_TextMessage(
        text: 'Hello PQC World!',
      ),
    ).writeToBuffer();

    final encryptedResult = await signalEncryptMessageV2(contactId, plaintext);
    expect(encryptedResult, isNotNull);
    expect(encryptedResult!.type, msg_pb.Message_Type.CIPHERTEXT_V2);
    expect(encryptedResult.ciphertext, isNotEmpty);
  });

  test('only active V1 sessions are upgraded', () async {
    const activeContactIds = [701, 702];
    const inactiveContactId = 703;

    for (final contactId in [...activeContactIds, inactiveContactId]) {
      await db.contactsDao.insertContact(
        ContactsCompanion.insert(
          userId: Value(contactId),
          username: 'contact_$contactId',
          accepted: const Value(true),
          signalVersion: const Value(SignalVersion.v1),
        ),
      );
      api.users[contactId] = _userDataFromBundle(
        contactId,
        await RustSignal.generateBundle(),
      );
    }

    activeContactIds.forEach(scheduleSignalSessionUpgrade);
    await upgradeActiveSignalSessionsToV2();

    for (final contactId in activeContactIds) {
      expect(
        (await db.contactsDao.getContactById(contactId))!.signalVersion,
        SignalVersion.v2,
      );
    }
    expect(
      (await db.contactsDao.getContactById(inactiveContactId))!.signalVersion,
      SignalVersion.v1,
    );
    expect(api.requestedUserIds, unorderedEquals(activeContactIds));
  });
}
