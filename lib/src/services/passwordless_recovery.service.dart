import 'dart:async';
import 'dart:convert' show base64Url, utf8;

import 'package:cryptography_plus/cryptography_plus.dart'
    show Hkdf, Hmac, Mac, SecretBox, SecretKey, Xchacha20;
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:twonly/core/bridge/wrapper.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/core/user_config.dart' show PasswordlessRecoveryConfig;
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart'
    show getContactDisplayName;
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/onboarding_state.model.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/model/protobuf/client/generated/passwordless_recovery.pb.dart';
import 'package:twonly/src/providers/routing.provider.dart';
import 'package:twonly/src/services/user.service.dart';

import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/help_a_friend.passwordless_recovery.view.dart';

enum SecondFactorType { email, pin, none }

class PasswordlessRecoveryService {
  static final StreamController<String> onEmailTokenReceived =
      StreamController<String>.broadcast();

  static String? lastEmailToken;

  static String linkPrefix = 'https://me.twonly.eu/r/#';

  static final Set<String> _handledNotificationIds = {};

  static Future<void> handleRecoveryLink(String link) async {
    final hashIndex = link.indexOf('#');
    if (hashIndex == -1) return;

    final fragment = link.substring(hashIndex + 1);
    final parts = fragment.split('/');
    if (parts.length < 2) {
      if (fragment.isNotEmpty) {
        lastEmailToken = fragment;
        onEmailTokenReceived.add(fragment);
      }
      return;
    }

    final notificationId = parts[0];
    final base64Key = parts[1];

    if (_handledNotificationIds.contains(notificationId)) {
      Log.info(
        'Notification ID $notificationId was already handled, skipping.',
      );
      return;
    }
    _handledNotificationIds.add(notificationId);

    final encryptionKey = base64Url.decode(base64Url.normalize(base64Key));

    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      unawaited(
        context.navPush(
          HelpAFriendPasswordlessRecoveryView(
            notificationId: notificationId,
            encryptionKey: encryptionKey,
          ),
        ),
      );
    }
  }

  static Future<bool> submitRecoveryShare(
    String notificationId,
    List<int> encryptionKey,
    Contact contact,
  ) async {
    try {
      final share = contact.recoveryContactsSecretShare;
      if (share == null) {
        Log.warn('Contact does not have a recovery share stored.');
        return false;
      }

      final trustedFriend = TrustedFriendShare_User(
        userId: Int64(userService.currentUser.userId),
        displayName: userService.currentUser.displayName,
        avatar: userService.currentUser.avatarSvg != null
            ? utf8.encode(userService.currentUser.avatarSvg!)
            : null,
      );

      final shareUser = TrustedFriendShare_User(
        userId: Int64(contact.userId),
        displayName: getContactDisplayName(contact),
        avatar: contact.avatarSvgCompressed,
      );

      final trustedFriendShare = TrustedFriendShare(
        trustedFriend: trustedFriend,
        shareUser: shareUser,
        threshold: contact.recoveryContactsThreshold,
        sharedSecretData: share,
      );

      final xchacha20 = Xchacha20.poly1305Aead();
      final secretBox = await xchacha20.encrypt(
        trustedFriendShare.writeToBuffer(),
        secretKey: SecretKey(encryptionKey),
        nonce: xchacha20.newNonce(),
      );

      final envelope = EncryptedEnvelope(
        encryptedData: secretBox.cipherText,
        iv: secretBox.nonce,
        mac: secretBox.mac.bytes,
      );

      await RustApi.submitRecoveryShare(
        notificationId: notificationId,
        encryptedMessage: envelope.writeToBuffer(),
      );
      return true;
    } catch (e) {
      Log.error('Failed to submit recovery share', error: e);
      return false;
    }
  }

  static Future<bool> enablePasswordlessRecovery({
    required List<int> trustedFriendIds,
    required SecondFactorType secondFactorType,
    required String secondFactorValue,
    required int threshold,
  }) async {
    // 1. Get all currently trusted friends contacts and send them delete messages
    final oldTrustedFriends = await (twonlyDB.select(
      twonlyDB.contacts,
    )..where((t) => t.recoveryIsTrustedFriend.equals(true))).get();

    for (final contact in oldTrustedFriends) {
      try {
        await RustApi.sendEncryptedContent(
          contactId: contact.userId,
          content: pb.EncryptedContent(
            passwordlessRecovery: pb.EncryptedContent_PasswordLessRecovery(
              delete: true,
            ),
          ).writeToBuffer(),
          onlySendIfNoReceiptsAreOpen: false,
          onlyReturnEncryptedData: false,
          blocking: true,
        );
      } catch (e) {
        Log.error(
          'Failed to send delete PasswordLessRecovery message to contact ${contact.userId}: $e',
        );
      }
    }

    // 1. Reset current recovery data to ensure a clean state

    await twonlyDB.contactsDao.resetRecoveryDataForAllContacts();
    await UserService.update((u) => u.passwordLessRecovery = null);

    final config = PasswordlessRecoveryConfig(threshold: threshold);
    final xchacha20 = Xchacha20.poly1305Aead();

    // 2. If enabled, handle the second factor and create serverKey

    Uint8List? serverKey;
    Uint8List? encryptedServerKey;

    SecretKey? secondFactorEncryptedServerKeyKey;
    String? emailHint;

    switch (secondFactorType) {
      case SecondFactorType.email:
        config.email = secondFactorValue.toLowerCase();
        emailHint = createEmailHint(config.email!);

        // E-Mail Protection:
        // - Server can only learn the email during recovery. Ensured as the server gets the NONCE to decrypt only during recovery.
        // - Trusted-friends: Server key is only sent to the mail, they would need access to the user's mail account.
        config.serverKeyProtection = getRandomUint8List(32);

        final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
        secondFactorEncryptedServerKeyKey = await hkdf.deriveKey(
          secretKey: SecretKey(config.serverKeyProtection!),
          nonce: utf8.encode(config.email!),
        );

      case SecondFactorType.pin:

        // The pin seed - never shared with the server - ensures that the server is unable to brute-force real user's pin
        config
          ..serverKeyProtection = getRandomUint8List(32)
          // As the pin is heavily protected against brute-forcing e.g. will be deleted by the server after 10 tries, the
          // unlock token is required to prevent a malicious user (except the trusted friends) to trigger this deletion.
          ..pinUnlockToken = getRandomUint8List(32);

        // Brute-force protection for the user's pin:
        //  - Server: Does not know the seed.
        //  - Trusted friends:  Can only check the result 10 times before the server deletes the key. As they do not have
        //  the mac and the cipher text they are unable to brute-force the pin locally. And the server only allows 10 tries.
        final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
        secondFactorEncryptedServerKeyKey = await hkdf.deriveKey(
          secretKey: SecretKey(config.serverKeyProtection!),
          nonce: utf8.encode(secondFactorValue),
        );

      case SecondFactorType.none:
    }

    if (secondFactorEncryptedServerKeyKey != null) {
      // The server key is used to encrypt the RecoveryData of the users. This ensures that when the trusted friends
      // collaborate, they additionally need the serverKey to decrypt the user's key.
      serverKey = getRandomUint8List(32);

      final secretBox = await xchacha20.encrypt(
        serverKey,
        secretKey: secondFactorEncryptedServerKeyKey,
        nonce: xchacha20.newNonce(),
      );

      // The server only gets the encrypted server key, the mac, and the nonce.
      // This ensures that the server never learns the user's original pin, as he is missing the serverKeyProtection and also unable to
      // brute-force the email of the user.
      encryptedServerKey = Uint8List.fromList([
        ...secretBox.cipherText,
        ...secretBox.mac.bytes,
        ...secretBox.nonce,
      ]);

      config.encryptedServerKey = encryptedServerKey;
    }

    // 3. Using shamir's secret to generate the shares for the users.

    // 3.1. Create the SharedSecretData

    var recoveryData = RecoveryData(
      userId: Int64(userService.currentUser.userId),
      keyManager: await RustKeyManager.serialize(),
    ).writeToBuffer();

    if (serverKey != null) {
      // Second factor was enabled, so encrypt the recoveryData using the serverKey.

      final secretBox = await xchacha20.encrypt(
        recoveryData,
        secretKey: SecretKey(serverKey),
        nonce: xchacha20.newNonce(),
      );

      recoveryData = EncryptedEnvelope(
        encryptedData: secretBox.cipherText,
        iv: secretBox.nonce,
        mac: secretBox.mac.bytes,
      ).writeToBuffer();
    }

    final sharedSecretData = SharedSecretData(
      recoveryData: recoveryData,
      serverKeyProtection: config.serverKeyProtection,
      pinUnlockToken: config.pinUnlockToken,
      emailHint: emailHint,
    ).writeToBuffer();

    // 3.2. Use the amount of trusted friends to generate the shares

    final List<Uint8List> shares;
    try {
      shares = await RustUtils.generateShares(
        secret: sharedSecretData,
        total: trustedFriendIds.length,
        threshold: threshold,
      );

      if (shares.length != trustedFriendIds.length) {
        Log.error('shares.length != trustedFriendIds.length');
        return false;
      }
    } catch (e) {
      Log.error('Failed to generate secret shares: $e');
      return false;
    }

    await UserService.update((u) => u.passwordLessRecovery = config);

    // 3.4. Store the shares in the contact's rows
    for (final contactId in trustedFriendIds) {
      await twonlyDB.contactsDao.updateContact(
        contactId,
        ContactsCompanion(
          recoveryIsTrustedFriend: const Value(true),
          recoveryLastHeartbeat: const Value(null),
          recoverySecretShare: Value(shares.removeLast()),
        ),
      );
    }

    unawaited(
      // ignore: inference_failure_on_untyped_parameter
      RustApi.performPasswordlessRecoveryHeartbeat().catchError((e) {
        Log.warn('Failed to perform passwordless recovery heartbeat: $e');
      }),
    );

    // The passwordless is configured successfully.
    return true;
  }

  static Future<bool> testPin(String pin) async {
    final config = userService.currentUser.passwordLessRecovery;
    if (config?.serverKeyProtection == null ||
        config?.encryptedServerKey == null) {
      return false;
    }

    try {
      final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
      final secondFactorEncryptedServerKeyKey = await hkdf.deriveKey(
        secretKey: SecretKey(config!.serverKeyProtection!),
        nonce: utf8.encode(pin),
      );

      final xchacha20 = Xchacha20.poly1305Aead();

      final combined = config.encryptedServerKey!;
      final nonceBytes = combined.sublist(combined.length - 24);
      final macBytes = combined.sublist(
        combined.length - 40,
        combined.length - 24,
      );
      final cipherText = combined.sublist(0, combined.length - 40);

      final secretBox = SecretBox(
        cipherText,
        nonce: nonceBytes,
        mac: Mac(macBytes),
      );

      await xchacha20.decrypt(
        secretBox,
        secretKey: secondFactorEncryptedServerKeyKey,
      );

      return true;
    } catch (e) {
      Log.error('Failed to test pin: $e');
      return false;
    }
  }

  static Future<bool> checkAndStorePasswordlessMessages(
    OnboardingState state,
  ) async {
    if (!state.serverRegistered ||
        state.notificationId == null ||
        state.downloadAuthToken == null ||
        state.encryptionKey == null) {
      return false;
    }

    final alreadyReceivedIds = Int64List.fromList(
      state.receivedShares.map((share) => share.messageId).toList(),
    );

    late final List<FrbPasswordlessNotificationMessage> messages;
    try {
      messages = await RustApi.checkForPasswordlessNotification(
        notificationId: state.notificationId!,
        downloadAuthToken: state.downloadAuthToken!,
        alreadyReceivedMessageIds: alreadyReceivedIds,
      );
    } catch (error) {
      Log.error(
        'Failed to load passwordless recovery messages',
        error: error,
      );
      return false;
    }

    if (messages.isEmpty) {
      return false;
    }

    final xchacha20 = Xchacha20.poly1305Aead();
    final secretKey = SecretKey(state.encryptionKey!);
    var didUpdate = false;

    for (final msg in messages) {
      final msgId = msg.id;

      try {
        final envelope = EncryptedEnvelope.fromBuffer(msg.encryptedMessage);
        final secretBox = SecretBox(
          envelope.encryptedData,
          nonce: envelope.iv,
          mac: Mac(envelope.mac),
        );
        final plaintext = await xchacha20.decrypt(
          secretBox,
          secretKey: secretKey,
        );

        final share = TrustedFriendShare.fromBuffer(plaintext);

        final receivedShare = ReceivedRecoveryShare(
          messageId: msgId,
          trustedFriendDisplayName: share.trustedFriend.displayName,
          trustedFriendAvatarSvg: share.trustedFriend.hasAvatar()
              ? share.trustedFriend.avatar
              : null,
          myDisplayName: share.shareUser.displayName,
          myUserId: share.shareUser.userId.toInt(),
          myAvatarSvg: share.shareUser.hasAvatar()
              ? share.shareUser.avatar
              : null,
          threshold: share.threshold,
          sharedSecretDataBytes: share.sharedSecretData,
        );

        state.receivedShares.add(receivedShare);
        didUpdate = true;

        Log.info(
          'Received recovery share from ${share.trustedFriend.displayName} '
          'for user ${share.shareUser.displayName}',
        );
      } catch (e) {
        Log.error(
          'Failed to decrypt/parse passwordless notification message $msgId: $e',
        );
      }
    }

    if (didUpdate) {
      await KeyValueStore.update<OnboardingState>(
        key: KeyValueKeys.onboardingState,
        update: (s) => s.receivedShares = state.receivedShares,
      );
    }

    return didUpdate;
  }

  static Future<void> migratePasswordlessRecovery() async {
    final config = userService.currentUser.passwordLessRecovery;
    if (config == null) return;

    final oldTrustedFriends = await (twonlyDB.select(
      twonlyDB.contacts,
    )..where((t) => t.recoveryIsTrustedFriend.equals(true))).get();
    final trustedFriendIds = oldTrustedFriends.map((e) => e.userId).toList();

    if (trustedFriendIds.isEmpty) return;

    if (config.email != null) {
      await enablePasswordlessRecovery(
        trustedFriendIds: trustedFriendIds,
        secondFactorType: SecondFactorType.email,
        secondFactorValue: config.email!,
        threshold: config.threshold,
      );
    } else if (config.pinUnlockToken == null) {
      await enablePasswordlessRecovery(
        trustedFriendIds: trustedFriendIds,
        secondFactorType: SecondFactorType.none,
        secondFactorValue: '',
        threshold: config.threshold,
      );
    } else {
      // It's PIN, we can't migrate it because we don't have the PIN. We delete it so the user has to do it again.
      for (final contact in oldTrustedFriends) {
        try {
          await RustApi.sendEncryptedContent(
            contactId: contact.userId,
            content: pb.EncryptedContent(
              passwordlessRecovery: pb.EncryptedContent_PasswordLessRecovery(
                delete: true,
              ),
            ).writeToBuffer(),
            onlySendIfNoReceiptsAreOpen: false,
            onlyReturnEncryptedData: false,
            blocking: true,
          );
        } catch (e) {
          Log.error(
            'Failed to send delete PasswordLessRecovery message to contact ${contact.userId}: $e',
          );
        }
      }

      await twonlyDB.contactsDao.resetRecoveryDataForAllContacts();
      await UserService.update((u) => u.passwordLessRecovery = null);
    }
  }
}
