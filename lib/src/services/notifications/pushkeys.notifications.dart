import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:cryptography_flutter_plus/cryptography_flutter_plus.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hashlib/random.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/model/protobuf/client/generated/push_notification.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

/// This function must be called after the database is setup
Future<void> setupNotificationWithUsers({
  bool force = false,
  int? forceContact,
}) async {
  var pushUsers = await getPushKeys(SecureStorageKeys.receivingPushKeys);

  // HotFIX: Search for user with id 0 if not there remove all
  // and create new push keys with all users.
  final pushUser = pushUsers.firstWhereOrNull((x) => x.userId == 0);
  if (pushUser == null) {
    Log.info('Clearing push keys');
    await setPushKeys(SecureStorageKeys.receivingPushKeys, []);
    pushUsers = await getPushKeys(SecureStorageKeys.receivingPushKeys)
      ..add(
        PushUser(
          userId: Int64(),
          displayName: 'NoUser',
          pushKeys: [],
        ),
      );
  }

  var wasChanged = false;

  final random = Random.secure();

  final contacts = await twonlyDB.contactsDao.getAllNotBlockedContacts();
  for (final contact in contacts) {
    final pushUser =
        pushUsers.firstWhereOrNull((x) => x.userId == contact.userId);

    if (pushUser != null && pushUser.pushKeys.isNotEmpty) {
      // make it harder to predict the change of the key
      final timeBefore =
          DateTime.now().subtract(Duration(days: 5 + random.nextInt(5)));
      final lastKey = pushUser.pushKeys.last;
      final createdAt = DateTime.fromMillisecondsSinceEpoch(
        lastKey.createdAtUnixTimestamp.toInt(),
      );

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
        Log.info('Creating new pushkey for ${contact.userId}');
      }
    } else {
      Log.info(
        'User ${contact.userId} not yet in pushkeys. Creating a new user.',
      );
      wasChanged = true;

      /// Insert a new push user
      final pushKey = PushKey(
        id: Int64(1),
        key: List<int>.generate(32, (index) => random.nextInt(256)),
        createdAtUnixTimestamp: Int64(DateTime.now().millisecondsSinceEpoch),
      );
      await sendNewPushKey(contact.userId, pushKey);
      pushUsers.add(
        PushUser(
          userId: Int64(contact.userId),
          displayName: getContactDisplayName(contact),
          blocked: contact.blocked,
          pushKeys: [pushKey],
        ),
      );
    }
  }

  if (wasChanged) {
    await setPushKeys(SecureStorageKeys.receivingPushKeys, pushUsers);
  }
}

Future<void> sendNewPushKey(int userId, PushKey pushKey) async {
  await sendCipherText(
    userId,
    EncryptedContent()
      ..pushKeys = (EncryptedContent_PushKeys()
        ..type = EncryptedContent_PushKeys_Type.UPDATE
        ..key = pushKey.key
        ..keyId = pushKey.id
        ..createdAt = pushKey.createdAtUnixTimestamp),
  );
}

Future<void> updatePushUser(Contact contact) async {
  final pushKeys = await getPushKeys(SecureStorageKeys.receivingPushKeys);

  final pushUser = pushKeys.firstWhereOrNull((x) => x.userId == contact.userId);

  if (pushUser == null) {
    pushKeys.add(
      PushUser(
        userId: Int64(contact.userId),
        displayName: getContactDisplayName(contact),
        pushKeys: [],
        blocked: contact.blocked,
        lastMessageId: uuid.v7(),
      ),
    );
  } else {
    pushUser
      ..displayName = getContactDisplayName(contact)
      ..blocked = contact.blocked;
  }

  await setPushKeys(SecureStorageKeys.receivingPushKeys, pushKeys);
}

Future<void> handleNewPushKey(int fromUserId, int keyId, List<int> key) async {
  final pushKeys = await getPushKeys(SecureStorageKeys.sendingPushKeys);

  var pushUser = pushKeys.firstWhereOrNull((x) => x.userId == fromUserId);

  if (pushUser == null) {
    final contact = await twonlyDB.contactsDao
        .getContactByUserId(fromUserId)
        .getSingleOrNull();
    if (contact == null) return;
    pushKeys.add(
      PushUser(
        userId: Int64(fromUserId),
        displayName: getContactDisplayName(contact),
        pushKeys: [],
        blocked: contact.blocked,
        lastMessageId: uuid.v7(),
      ),
    );
    pushUser = pushKeys.firstWhereOrNull((x) => x.userId == fromUserId);
  }

  if (pushUser == null) {
    Log.error('could not store new push key as no user was found');
  }

  // only store the newest key...
  pushUser!.pushKeys.clear();
  pushUser.pushKeys.add(
    PushKey(
      id: Int64(keyId),
      key: key,
      createdAtUnixTimestamp: Int64(DateTime.now().millisecondsSinceEpoch),
    ),
  );

  await setPushKeys(SecureStorageKeys.sendingPushKeys, pushKeys);
}

Future<void> updateLastMessageId(int fromUserId, String messageId) async {
  final pushUsers = await getPushKeys(SecureStorageKeys.receivingPushKeys);

  final pushUser = pushUsers.firstWhereOrNull((x) => x.userId == fromUserId);
  if (pushUser == null) {
    unawaited(setupNotificationWithUsers());
    return;
  }

  if (isUUIDNewer(messageId, pushUser.lastMessageId)) {
    pushUser.lastMessageId = messageId;
    await setPushKeys(SecureStorageKeys.receivingPushKeys, pushUsers);
  }
}

Future<PushNotification?> getPushNotificationFromEncryptedContent(
  int toUserId,
  String? messageId,
  EncryptedContent content,
) async {
  PushKind? kind;
  String? additionalContent;

  if (content.hasReaction()) {
    if (content.reaction.remove) return null;

    final msg = await twonlyDB.messagesDao
        .getMessageById(content.reaction.targetMessageId)
        .getSingleOrNull();
    if (msg == null || msg.senderId == null || msg.senderId != toUserId) {
      return null;
    }
    if (msg.content != null) {
      kind = PushKind.reactionToText;
    } else if (msg.mediaId != null) {
      final media = await twonlyDB.mediaFilesDao.getMediaFileById(msg.mediaId!);
      if (media == null) return null;
      switch (media.type) {
        case MediaType.image:
          kind = PushKind.reactionToImage;
        case MediaType.audio:
          kind = PushKind.reactionToAudio;
        case MediaType.video:
          kind = PushKind.reactionToVideo;
        case MediaType.gif:
          kind = PushKind.reaction;
      }
    }
    additionalContent = content.reaction.emoji;
  }

  if (content.hasTextMessage()) {
    kind = PushKind.text;
    if (content.textMessage.hasQuoteMessageId()) {
      kind = PushKind.response;
    }
    final group = await twonlyDB.groupsDao.getGroup(content.groupId);
    if (group != null && !group.isDirectChat) {
      additionalContent = group.groupName;
    }
  }
  if (content.hasMedia()) {
    switch (content.media.type) {
      case EncryptedContent_Media_Type.REUPLOAD:
        return null;
      case EncryptedContent_Media_Type.IMAGE:
        kind = PushKind.image;
      case EncryptedContent_Media_Type.VIDEO:
        kind = PushKind.video;
      case EncryptedContent_Media_Type.GIF:
        kind = PushKind.image;
      case EncryptedContent_Media_Type.AUDIO:
        kind = PushKind.audio;
    }
    if (content.media.requiresAuthentication) {
      kind = PushKind.twonly;
    }
    final group = await twonlyDB.groupsDao.getGroup(content.groupId);
    if (group != null && !group.isDirectChat) {
      additionalContent = group.groupName;
    }
  }

  if (content.hasContactRequest()) {
    switch (content.contactRequest.type) {
      case EncryptedContent_ContactRequest_Type.REQUEST:
        kind = PushKind.contactRequest;
      case EncryptedContent_ContactRequest_Type.ACCEPT:
        kind = PushKind.acceptRequest;
      case EncryptedContent_ContactRequest_Type.REJECT:
        return null;
    }
  }

  if (content.hasMediaUpdate()) {
    switch (content.mediaUpdate.type) {
      case EncryptedContent_MediaUpdate_Type.REOPENED:
        kind = PushKind.reopenedMedia;
      case EncryptedContent_MediaUpdate_Type.STORED:
        kind = PushKind.storedMediaFile;
      case EncryptedContent_MediaUpdate_Type.DECRYPTION_ERROR:
        return null;
    }
  }

  if (content.hasGroupCreate()) {
    kind = PushKind.addedToGroup;
    final group = await twonlyDB.groupsDao.getGroup(content.groupId);
    additionalContent = group!.groupName;
  }

  if (kind == null) return null;

  final pushNotification = PushNotification()..kind = kind;
  if (additionalContent != null) {
    pushNotification.additionalContent = additionalContent;
  }
  if (messageId != null) {
    pushNotification.messageId = messageId;
  }
  return pushNotification;
}

Future<void> requestNewPushKeysForUser(int toUserId) async {
  await sendCipherText(
    toUserId,
    EncryptedContent()
      ..pushKeys = (EncryptedContent_PushKeys()
        ..type = EncryptedContent_PushKeys_Type.REQUEST),
  );
}

/// this will trigger a push notification
/// push notification only containing the message kind and username
Future<Uint8List?> encryptPushNotification(
  int toUserId,
  PushNotification content,
) async {
  final pushKeys = await getPushKeys(SecureStorageKeys.sendingPushKeys);

  var key = 'InsecureOnlyUsedForAddingContact'.codeUnits;
  var keyId = 0;

  final pushUser = pushKeys.firstWhereOrNull((x) => x.userId == toUserId);

  if (pushUser == null) {
    // user does not have send any push keys
    // only allow accept request and contact request to be send in an insecure way :/
    // In future find a better way, e.g. use the signal protocol in a native way..
    if (content.kind != PushKind.acceptRequest &&
        content.kind != PushKind.contactRequest &&
        content.kind != PushKind.testNotification) {
      // this will be enforced after every app uses this system... :/
      // return null;
      Log.warn('Using insecure key as the receiver does not send a push key!');
      await requestNewPushKeysForUser(toUserId);
    }
  } else {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      pushUser.pushKeys.last.createdAtUnixTimestamp.toInt(),
    );
    final timeBefore = DateTime.now().subtract(const Duration(days: 8));
    if (createdAt.isBefore(timeBefore)) {
      await requestNewPushKeysForUser(toUserId);
    }
    try {
      key = pushUser.pushKeys.last.key;
      keyId = pushUser.pushKeys.last.id.toInt();
    } catch (e) {
      Log.error('No push notification key found for user $toUserId');
      return null;
    }
  }

  final chacha20 = FlutterChacha20.poly1305Aead();
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
  const storage = FlutterSecureStorage();
  try {
    final pushKeysProto = await storage.read(
      key: storageKey,
      iOptions: const IOSOptions(
        groupId: 'CN332ZUGRP.eu.twonly.shared',
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
    if (pushKeysProto == null) return [];
    final pushKeysRaw = base64Decode(pushKeysProto);
    return PushUsers.fromBuffer(pushKeysRaw).users;
  } catch (e) {
    Log.error(e);
  }
  return [];
}

Future<void> setPushKeys(String storageKey, List<PushUser> pushKeys) async {
  const storage = FlutterSecureStorage();

  try {
    await storage.delete(
      key: storageKey,
      iOptions: const IOSOptions(
        groupId: 'CN332ZUGRP.eu.twonly.shared',
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
  } catch (e) {
    Log.error(e);
  }

  final jsonString = base64Encode(PushUsers(users: pushKeys).writeToBuffer());
  try {
    await storage.write(
      key: storageKey,
      value: jsonString,
      iOptions: const IOSOptions(
        groupId: 'CN332ZUGRP.eu.twonly.shared',
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
  } catch (e) {
    Log.error(e);
  }
}
