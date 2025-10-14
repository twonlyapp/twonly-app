// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';
import 'dart:io';
import 'package:cryptography_flutter_plus/cryptography_flutter_plus.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/model/protobuf/backup/backup.pb.dart';
import 'package:twonly/src/services/twonly_safe/common.twonly_safe.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';

Future<void> recoverTwonlySafe(
  String username,
  String password,
  BackupServer? server,
) async {
  final (backupId, encryptionKey) = await getMasterKey(password, username);

  final backupServerUrl =
      await getTwonlySafeBackupUrlFromServer(backupId, server);

  if (backupServerUrl == null) {
    Log.error('Could not create backup url');
    throw Exception('Could not create backup server url');
  }

  late Uint8List backupData;
  late http.Response response;

  try {
    response = await http.get(
      Uri.parse(backupServerUrl),
      headers: {
        HttpHeaders.acceptHeader: 'application/octet-stream',
      },
    );
  } catch (e) {
    Log.error('Error fetching backup: $e');
    throw Exception('Backup server could not be reached. ($e)');
  }

  switch (response.statusCode) {
    case 200:
      backupData = response.bodyBytes;
    case 400:
      throw Exception('Bad Request: Validation failed.');
    case 404:
      throw Exception('No backup was found.');
    case 429:
      throw Exception('Too Many Requests: Rate limit reached.');
    default:
      throw Exception('Unexpected error: ${response.statusCode}');
  }

  return handleBackupData(encryptionKey, backupData);
}

Future<void> handleBackupData(
  Uint8List encryptionKey,
  Uint8List backupData,
) async {
  final encryptedBackup = TwonlySafeBackupEncrypted.fromBuffer(
    backupData,
  );

  final secretBox = SecretBox(
    encryptedBackup.cipherText,
    nonce: encryptedBackup.nonce,
    mac: Mac(encryptedBackup.mac),
  );

  final compressedBytes = await FlutterChacha20.poly1305Aead().decrypt(
    secretBox,
    secretKey: SecretKeyData(encryptionKey),
  );

  final plaintextBytes = gzip.decode(compressedBytes);

  final backupContent = TwonlySafeBackupContent.fromBuffer(
    plaintextBytes,
  );

  final baseDir = (await getApplicationSupportDirectory()).path;
  final originalDatabase = File(join(baseDir, 'twonly_database.sqlite'));
  await originalDatabase.writeAsBytes(backupContent.twonlyDatabase);

  /// When restoring the last message ID must be increased otherwise
  /// receivers would mark them as duplicates as they where already
  /// send.
  final database = TwonlyDatabase();
  var lastMessageSend = 0;
  int? randomUserId;

  final contacts = await database.contactsDao.getAllNotBlockedContacts();
  for (final contact in contacts) {
    randomUserId = contact.userId;
    final days = DateTime.now().difference(contact.lastMessageExchange).inDays;
    if (days < lastMessageSend) {
      lastMessageSend = days;
    }
  }

  if (randomUserId != null) {
    // for each day add 400 message ids
    final dummyMessagesCounter = (lastMessageSend + 1) * 400;
    Log.info(
      'Creating $dummyMessagesCounter dummy messages to increase message counter as last message was $lastMessageSend days ago.',
    );
    for (var i = 0; i < dummyMessagesCounter; i++) {
      await database.messagesDao.insertMessage(
        MessagesCompanion(
          contactId: Value(randomUserId),
          kind: const Value(MessageKind.ack),
          acknowledgeByServer: const Value(true),
          errorWhileSending: const Value(true),
        ),
      );
    }
    await database.messagesDao.deleteAllMessagesByContactId(randomUserId);
  }

  const storage = FlutterSecureStorage();

  final secureStorage = jsonDecode(backupContent.secureStorageJson);

  await storage.write(
    key: SecureStorageKeys.signalIdentity,
    value: secureStorage[SecureStorageKeys.signalIdentity] as String,
  );
  await storage.write(
    key: SecureStorageKeys.signalSignedPreKey,
    value: secureStorage[SecureStorageKeys.signalSignedPreKey] as String,
  );
  await storage.write(
    key: SecureStorageKeys.userData,
    value: secureStorage[SecureStorageKeys.userData] as String,
  );
  await updateUserdata((u) {
    u.deviceId += 1;
    return u;
  });
}
