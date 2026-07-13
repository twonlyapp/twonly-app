import 'dart:async';
import 'dart:convert' show base64Url, utf8;

import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart' hide Hmac;
import 'package:cryptography_plus/cryptography_plus.dart'
    show Hmac, Mac, SecretBox, SecretKey, Xchacha20;
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/core/bridge/wrapper.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart'
    show getContactDisplayName;
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/onboarding_state.model.dart';
import 'package:twonly/src/model/json/userdata.model.dart'
    show PasswordLessRecovery;
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/model/protobuf/client/generated/passwordless_recovery.pb.dart';
import 'package:twonly/src/providers/routing.provider.dart';
import 'package:twonly/src/services/api/messages.api.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/avatars.dart' show getAvatarSvg;
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/help_a_friend.passwordless_recovery.view.dart';

enum SecondFactorType { email, pin, none }

class PasswordlessRecoveryService {
  static final StreamController<String> onEmailTokenReceived =
      StreamController<String>.broadcast();

  static String linkPrefix = 'https://me.twonly.eu/r/#';

  static final Set<String> _handledNotificationIds = {};

  static Future<void> handleRecoveryLink(String link) async {
    final hashIndex = link.indexOf('#');
    if (hashIndex == -1) return;

    final fragment = link.substring(hashIndex + 1);
    final parts = fragment.split('/');
    if (parts.length < 2) {
      if (fragment.isNotEmpty) {
        onEmailTokenReceived.add(fragment);
        final context = rootNavigatorKey.currentContext;
        if (context != null && context.mounted) {
          unawaited(context.push(Routes.recoverPasswordless, extra: fragment));
        }
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
        avatar: contact.avatarSvgCompressed != null
            ? utf8.encode(getAvatarSvg(contact.avatarSvgCompressed!))
            : null,
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

      final res = await apiService.submitRecoveryShare(
        notificationId: notificationId,
        encryptedMessage: envelope.writeToBuffer(),
      );
      return res.isSuccess;
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
        await sendCipherText(
          contact.userId,
          pb.EncryptedContent(
            passwordlessRecovery: pb.EncryptedContent_PasswordLessRecovery(
              delete: true,
            ),
          ),
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

    final config = PasswordLessRecovery(threshold);
    final xchacha20 = Xchacha20.poly1305Aead();

    // 2. If enabled, handle the second factor and create serverKey

    Uint8List? serverKey;
    Uint8List? encryptedServerKey;

    SecretKey? secondFactorEncryptedServerKeyKey;
    String? emailHint;

    switch (secondFactorType) {
      case SecondFactorType.email:

        // The serverKey is encrypted with the email; this protects the server from seeing the user's email address, while
        // also ensuring that the server can only send the real secret to the user's configured email, as a different
        // email will result in a different secret key.
        // This is only stored so the user can see there email, and verify that he has set the valid mail...
        config.email = secondFactorValue;
        emailHint = createEmailHint(secondFactorValue);

        // E-Mail Protection:
        // - Server can only learn the email during recovery. Ensured as the server gets the NONCE and MAC to decrpyt during recovery.
        // - Trusted-friends: Server key is send to the mail, they whould need access to the user's mail account.
        secondFactorEncryptedServerKeyKey = SecretKey(
          Uint8List.fromList(sha256.convert(utf8.encode(config.email!)).bytes),
        );

      case SecondFactorType.pin:

        // The pin seed - never shared with the server - ensures that the server is unable to brute-force real user's pin.
        config.pinSeed = getRandomUint8List(32);

        // As the pin is heavily protected against brute-forcing e.g. will be deleted by the server after X tries, the
        // unlock token is required to prevent a malicous user (except the trusted friends) to triger this deletion.
        config.pinUnlockToken = getRandomUint8List(32);

        // Brute-force protection for the user's pin:
        //  - Server: Does not know the seed.
        //  - Trusted friends:
        //  Can only check the result X times before the server deletes the key. As they do not have
        //  the mac and the cypher text they are unable to brute-force the pin localy. And the server only allows 10
        //  tries.
        final pinProtectionKey = await Hmac.sha256().calculateMac(
          Uint8List.fromList(utf8.encode(secondFactorValue)),
          secretKey: SecretKey(config.pinSeed!),
        );

        // To restore the user has to provide the server with this encryption key. The server then can verify the
        // correct pin was entered, when decrypting the server key as he also receives the mac and nonce from the user
        // during recovery. Only when the mac is correct the server provides the user with the serverKey.
        secondFactorEncryptedServerKeyKey = SecretKey(pinProtectionKey.bytes);

      case SecondFactorType.none:
    }

    if (secondFactorEncryptedServerKeyKey != null) {
      // The server key is used to encrypt the RecoveryData of the users. This ensures that when the trusted friends
      // colaberate, they additional need the serverKey to decrypt the user's key.
      serverKey = getRandomUint8List(32);

      final secretBox = await xchacha20.encrypt(
        serverKey,
        secretKey: secondFactorEncryptedServerKeyKey,
        nonce: xchacha20.newNonce(),
      );

      // The server only gets the encrypted server key and the mac. Because the server does not know the nonce (192-bit
      // because of XChaCha), he is unable to decrypt the server key without the help of the trusted friends. This
      // ensures that the server never learns the users orginal pin, as he is missing the pin_seed and also unable to
      // brute-force the email of the user as he does not have the nonce.
      encryptedServerKey = Uint8List.fromList([
        ...secretBox.cipherText,
        ...secretBox.mac.bytes,
      ]);

      config
        ..encryptedServerKeyNonce = secretBox.nonce
        ..encryptedServerKey = encryptedServerKey;
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
      pinSeed: config.pinSeed,
      pinUnlockToken: config.pinUnlockToken,
      emailHint: emailHint,
      encryptedServerKeyNonce: config.encryptedServerKeyNonce,
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

    unawaited(performHeartbeat());

    // The passwordless is configured sucessfully.
    return true;
  }

  static Future<bool> testPin(String pin) async {
    final config = userService.currentUser.passwordLessRecovery;
    if (config?.pinSeed == null || config?.encryptedServerKey == null) {
      return false;
    }

    try {
      final pinProtectionKey = await Hmac.sha256().calculateMac(
        Uint8List.fromList(utf8.encode(pin)),
        secretKey: SecretKey(config!.pinSeed!),
      );

      final secondFactorEncryptedServerKeyKey = SecretKey(
        pinProtectionKey.bytes,
      );

      final xchacha20 = Xchacha20.poly1305Aead();

      final combined = config.encryptedServerKey!;
      final cipherText = combined.sublist(0, combined.length - 16);
      final macBytes = combined.sublist(combined.length - 16);

      final secretBox = SecretBox(
        cipherText,
        nonce: config.encryptedServerKeyNonce!,
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

  static Future<void> performHeartbeat() async {
    final config = userService.currentUser.passwordLessRecovery;

    if (config != null) {
      final lastHeartbeat = config.lastServerHeartbeat;
      final isOlderThanAMonth =
          lastHeartbeat != null &&
          clock.now().difference(lastHeartbeat).inDays > 20;

      if ((lastHeartbeat == null || isOlderThanAMonth) &&
          config.encryptedServerKey != null) {
        final res = await apiService.registerPasswordLessRecovery(
          config.encryptedServerKey!,
          config.pinUnlockToken,
        );

        if (res.isSuccess) {
          await UserService.update((u) {
            u.passwordLessRecovery?.lastServerHeartbeat = clock.now();
          });
        }
      }

      final lastContactHeartbeat = config.lastContactHeartbeat;
      final isContactHeartbeatOlderThan24h =
          lastContactHeartbeat == null ||
          clock.now().difference(lastContactHeartbeat).inHours >= 24;

      if (isContactHeartbeatOlderThan24h) {
        // Get all contacts where recoveryLastHeartbeat is NULL. Then for each contacts send.
        // recoveryLastHeartbeat is ONLY updated in case the contact has responded.
        final pendingShares =
            await (twonlyDB.select(twonlyDB.contacts)..where(
                  (t) =>
                      t.recoveryIsTrustedFriend.equals(true) &
                      t.recoveryLastHeartbeat.isNull() &
                      t.recoverySecretShare.isNotNull(),
                ))
                .get();

        for (final contact in pendingShares) {
          try {
            await sendCipherText(
              contact.userId,
              pb.EncryptedContent(
                passwordlessRecovery: pb.EncryptedContent_PasswordLessRecovery(
                  recoverySecretShare: contact.recoverySecretShare,
                  delete: false,
                  threshold: Int64(config.threshold),
                ),
              ),
            );
          } catch (e) {
            Log.error(
              'Failed to send PasswordLessRecovery share to contact ${contact.userId}: $e',
            );
          }
        }

        await UserService.update((u) {
          u.passwordLessRecovery?.lastContactHeartbeat = clock.now();
        });
      }
    }

    // Send heartbeat to the friends I am a trusted friend.
    final oneWeekAgo = clock.now().subtract(const Duration(days: 7));
    final trustedFriendsToNotify =
        await (twonlyDB.select(twonlyDB.contacts)..where(
              (t) =>
                  t.recoveryContactsSecretShare.isNotNull() &
                  (t.recoveryContactsLastHeartbeat.isNull() |
                      t.recoveryContactsLastHeartbeat.isSmallerThanValue(
                        oneWeekAgo,
                      )),
            ))
            .get();

    for (final contact in trustedFriendsToNotify) {
      try {
        final share = contact.recoveryContactsSecretShare!;
        final hash = sha256.convert(share).bytes;

        await sendCipherText(
          contact.userId,
          pb.EncryptedContent(
            passwordlessRecoveryHeartbeat:
                pb.EncryptedContent_PasswordLessRecoveryHeartbeat(
                  hash: hash,
                ),
          ),
        );

        await twonlyDB.contactsDao.updateContact(
          contact.userId,
          ContactsCompanion(
            recoveryContactsLastHeartbeat: Value(clock.now()),
          ),
        );
      } catch (e) {
        Log.error(
          'Failed to send PasswordLessRecoveryHeartbeat to contact ${contact.userId}: $e',
        );
      }
    }
  }

  static Future<void> handlePasswordlessRecovery(
    int fromUserId,
    pb.EncryptedContent_PasswordLessRecovery msg,
    String receiptId,
  ) async {
    if (msg.delete) {
      Log.info(
        '[$receiptId] Received request to delete passwordless recovery share from contact $fromUserId',
      );
      await twonlyDB.contactsDao.updateContact(
        fromUserId,
        const ContactsCompanion(
          recoveryContactsSecretShare: Value(null),
          recoveryContactsLastHeartbeat: Value(null),
        ),
      );
    } else if (msg.hasRecoverySecretShare() && msg.hasThreshold()) {
      Log.info(
        '[$receiptId] Received new passwordless recovery share from contact $fromUserId',
      );
      await twonlyDB.contactsDao.updateContact(
        fromUserId,
        ContactsCompanion(
          recoveryContactsSecretShare: Value(
            Uint8List.fromList(msg.recoverySecretShare),
          ),
          recoveryContactsThreshold: Value(msg.threshold.toInt()),
          recoveryContactsLastHeartbeat: const Value(
            null, // this will trigger that a heartbeat will be send...
          ),
        ),
      );
    }
    unawaited(performHeartbeat());
  }

  static Future<void> handlePasswordlessRecoveryHeartbeat(
    int fromUserId,
    pb.EncryptedContent_PasswordLessRecoveryHeartbeat msg,
    String receiptId,
  ) async {
    Log.info(
      '[$receiptId] Received passwordless recovery heartbeat from contact $fromUserId',
    );
    final contact = await twonlyDB.contactsDao.getContactById(fromUserId);
    final storedShare = contact?.recoverySecretShare;

    if (storedShare == null) {
      unawaited(
        sendCipherText(
          fromUserId,
          pb.EncryptedContent(
            passwordlessRecovery: pb.EncryptedContent_PasswordLessRecovery(
              delete: true,
            ),
          ),
        ),
      );
      Log.warn(
        '[$receiptId] Received passwordless recovery heartbeat from $fromUserId but we did not send him a secret share.',
      );
      return;
    }

    final computedHash = sha256.convert(storedShare).bytes;
    final recoveryLastHeartbeat =
        const ListEquality().equals(computedHash, msg.hash)
        ? clock.now()
        : null; // The stored share not valid (maybe a old backup was restored). This will cause the performHeartbeat to resend him his share
    Log.info(
      '[$receiptId] Got heartbeat: ($recoveryLastHeartbeat)',
    );
    await twonlyDB.contactsDao.updateContact(
      fromUserId,
      ContactsCompanion(
        recoveryLastHeartbeat: Value(recoveryLastHeartbeat),
      ),
    );
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

    final alreadyReceivedIds = state.receivedShares
        .map((s) => Int64(s.messageId))
        .toList();

    final response = await apiService.checkForPasswordlessNotification(
      notificationId: state.notificationId!,
      downloadAuthToken: state.downloadAuthToken!,
      alreadyReceivedIds: alreadyReceivedIds,
    );

    if (response == null || response.messages.isEmpty) {
      return false;
    }

    final xchacha20 = Xchacha20.poly1305Aead();
    final secretKey = SecretKey(state.encryptionKey!);
    var didUpdate = false;

    for (final msg in response.messages) {
      final msgId = msg.id.toInt();

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
}
