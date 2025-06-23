import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart' as my;
import 'package:twonly/src/model/protobuf/push_notification/push_notification.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/utils/log.dart';

/// This function must be called after the database is setup
Future setupNotificationWithUsers(
    {bool force = false, int? forceContact}) async {
  var pushUsers = await getPushKeys(SecureStorageKeys.receivingPushKeys);

  // HotFIX: Search for user with id 0 if not there remove all
  // and create new push keys with all users.
  PushUser? pushUser = pushUsers.firstWhereOrNull((x) => x.userId == 0);
  if (pushUser == null) {
    Log.info("Clearing push keys");
    await setPushKeys(SecureStorageKeys.receivingPushKeys, []);
    pushUsers = await getPushKeys(SecureStorageKeys.receivingPushKeys);
    pushUsers.add(PushUser(
      userId: Int64(0),
      displayName: "NoUser",
      pushKeys: [],
    ));
  }

  var wasChanged = false;

  final random = Random.secure();

  final contacts = await twonlyDB.contactsDao.getAllNotBlockedContacts();
  for (final contact in contacts) {
    PushUser? pushUser =
        pushUsers.firstWhereOrNull((x) => x.userId == contact.userId);

    if (pushUser != null) {
      // make it harder to predict the change of the key
      final timeBefore =
          DateTime.now().subtract(Duration(days: 5 + random.nextInt(5)));
      final lastKey = pushUser.pushKeys.last;
      final createdAt = DateTime.fromMillisecondsSinceEpoch(
          lastKey.createdAtUnixTimestamp.toInt());

      if (force ||
          (forceContact == contact.userId) ||
          createdAt.isBefore(timeBefore)) {
        final pushKey = PushKey(
          id: lastKey.id + random.nextInt(5),
          key: List<int>.generate(32, (index) => random.nextInt(256)),
          createdAtUnixTimestamp: Int64(DateTime.now().millisecondsSinceEpoch),
        );
        await sendNewPushKey(contact.userId, pushKey);
        // only store a maximum of two keys
        pushUser.pushKeys.clear();
        pushUser.pushKeys.add(lastKey);
        pushUser.pushKeys.add(pushKey);
        wasChanged = true;
        Log.info("Creating new pushkey for ${contact.userId}");
      }
    } else {
      Log.info(
        "User ${contact.userId} not yet in pushkeys. Creating a new user.",
      );
      wasChanged = true;

      /// Insert a new push user
      final pushKey = PushKey(
        id: Int64(1),
        key: List<int>.generate(32, (index) => random.nextInt(256)),
        createdAtUnixTimestamp: Int64(DateTime.now().millisecondsSinceEpoch),
      );
      await sendNewPushKey(contact.userId, pushKey);
      pushUsers.add(PushUser(
        userId: Int64(contact.userId),
        displayName: getContactDisplayName(contact),
        blocked: contact.blocked,
        pushKeys: [pushKey],
        lastMessageId: null,
      ));
    }
  }

  if (wasChanged) {
    await setPushKeys(SecureStorageKeys.receivingPushKeys, pushUsers);
  }
}

Future sendNewPushKey(int userId, PushKey pushKey) async {
  await encryptAndSendMessageAsync(
    null,
    userId,
    my.MessageJson(
      kind: MessageKind.pushKey,
      content: my.PushKeyContent(
        keyId: pushKey.id.toInt(),
        key: pushKey.key,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        pushKey.createdAtUnixTimestamp.toInt(),
      ),
    ),
    willNotGetACKByUser: true, // hot fix, this can be removed later...
  );
}

Future updatePushUser(Contact contact) async {
  var pushKeys = await getPushKeys(SecureStorageKeys.receivingPushKeys);

  PushUser? pushUser =
      pushKeys.firstWhereOrNull((x) => x.userId == contact.userId);

  if (pushUser == null) {
    pushKeys.add(PushUser(
      userId: Int64(contact.userId),
      displayName: getContactDisplayName(contact),
      pushKeys: [],
      blocked: contact.blocked,
      lastMessageId: Int64(0),
    ));
  } else {
    pushUser.displayName = getContactDisplayName(contact);
    pushUser.blocked = contact.blocked;
  }

  await setPushKeys(SecureStorageKeys.receivingPushKeys, pushKeys);
}

Future handleNewPushKey(int fromUserId, my.PushKeyContent pushKey) async {
  var pushKeys = await getPushKeys(SecureStorageKeys.sendingPushKeys);

  PushUser? pushUser = pushKeys.firstWhereOrNull((x) => x.userId == fromUserId);

  if (pushUser == null) {
    final contact = await twonlyDB.contactsDao
        .getContactByUserId(fromUserId)
        .getSingleOrNull();
    if (contact == null) return;
    pushKeys.add(PushUser(
      userId: Int64(fromUserId),
      displayName: getContactDisplayName(contact),
      pushKeys: [],
      blocked: contact.blocked,
      lastMessageId: Int64(0),
    ));
    pushUser = pushKeys.firstWhereOrNull((x) => x.userId == fromUserId);
  }

  if (pushUser == null) {
    Log.error("could not store new push key as no user was found");
  }

  // only store the newest key...
  pushUser!.pushKeys.clear();
  pushUser.pushKeys.add(
    PushKey(
      id: Int64(pushKey.keyId),
      key: pushKey.key,
      createdAtUnixTimestamp: Int64(DateTime.now().millisecondsSinceEpoch),
    ),
  );

  await setPushKeys(SecureStorageKeys.sendingPushKeys, pushKeys);
}

Future updateLastMessageId(int fromUserId, int messageId) async {
  List<PushUser> pushUsers =
      await getPushKeys(SecureStorageKeys.receivingPushKeys);

  PushUser? pushUser =
      pushUsers.firstWhereOrNull((x) => x.userId == fromUserId);
  if (pushUser == null) {
    setupNotificationWithUsers();
    return;
  }

  if (pushUser.lastMessageId < Int64(messageId)) {
    pushUser.lastMessageId = Int64(messageId);
    await setPushKeys(SecureStorageKeys.receivingPushKeys, pushUsers);
  }
}

/// this will trigger a push notification
/// push notification only containing the message kind and username
Future<Uint8List?> getPushData(int toUserId, PushNotification content) async {
  final List<PushUser> pushKeys =
      await getPushKeys(SecureStorageKeys.sendingPushKeys);

  List<int> key = "InsecureOnlyUsedForAddingContact".codeUnits;
  int keyId = 0;

  PushUser? pushUser = pushKeys.firstWhereOrNull((x) => x.userId == toUserId);

  if (pushUser == null) {
    // user does not have send any push keys
    // only allow accept request and contact request to be send in an insecure way :/
    // In future find a better way, e.g. use the signal protocol in a native way..
    if (content.kind != PushKind.acceptRequest &&
        content.kind != PushKind.contactRequest &&
        content.kind != PushKind.testNotification) {
      // this will be enforced after every app uses this system... :/
      // return null;
      Log.error("Using insecure key as the receiver does not send a push key!");
      await encryptAndSendMessageAsync(
        null,
        toUserId,
        my.MessageJson(
          kind: MessageKind.requestPushKey,
          content: my.MessageContent(),
          timestamp: DateTime.now(),
        ),
      );
    }
  } else {
    try {
      key = pushUser.pushKeys.last.key;
      keyId = pushUser.pushKeys.last.id.toInt();
    } catch (e) {
      Log.error("No push notification key found for user $toUserId");
      return null;
    }
  }

  final chacha20 = Chacha20.poly1305Aead();
  final nonce = chacha20.newNonce();
  final secretBox = await chacha20.encrypt(
    content.writeToBuffer(),
    secretKey: SecretKeyData(key),
    nonce: nonce,
  );
  final res = EncryptedPushNotification(
    keyId: Int64(keyId),
    nonce: nonce,
    ciphertext: secretBox.cipherText,
    mac: secretBox.mac.bytes,
  );
  return res.writeToBuffer();
}

Future<List<PushUser>> getPushKeys(String storageKey) async {
  var storage = FlutterSecureStorage();
  String? pushKeysProto = await storage.read(
    key: storageKey,
    iOptions: IOSOptions(
      groupId: "CN332ZUGRP.eu.twonly.shared",
      synchronizable: false,
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  if (pushKeysProto == null) return [];
  Uint8List pushKeysRaw = base64Decode(pushKeysProto);
  return PushUsers.fromBuffer(pushKeysRaw).users;
}

Future setPushKeys(String storageKey, List<PushUser> pushKeys) async {
  var storage = FlutterSecureStorage();

  await storage.delete(
    key: storageKey,
    iOptions: IOSOptions(
      groupId: "CN332ZUGRP.eu.twonly.shared",
      synchronizable: false,
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  String jsonString = base64Encode(PushUsers(users: pushKeys).writeToBuffer());
  await storage.write(
    key: storageKey,
    value: jsonString,
    iOptions: IOSOptions(
      groupId: "CN332ZUGRP.eu.twonly.shared",
      synchronizable: false,
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
}
