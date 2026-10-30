import 'dart:async';
import 'dart:convert' show base64, base64Url, utf8;
import 'dart:typed_data';

import 'package:collection/collection.dart' show mergeSort;
import 'package:cryptography_plus/cryptography_plus.dart'
    show Hkdf, Hmac, Mac, SecretBox, SecretKey, Xchacha20;
import 'package:fixnum/fixnum.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/recovery.dart' as rust_recovery;
import 'package:twonly/core/bridge/wrapper.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/recovery/table.dart' as db_recovery;
import 'package:twonly/core/user_config.dart' show PasswordlessRecoveryConfig;
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/model/json/onboarding_state.model.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/model/protobuf/client/generated/passwordless_recovery.pb.dart';
import 'package:twonly/src/providers/routing.provider.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/contact_name.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/help_a_friend.passwordless_recovery.view.dart';

enum SecondFactorType { email, pin, none }

enum RecoveryPollResult { unchanged, updated, expired }

/// What the received recovery shares currently add up to.
class RecoveryShareAnalysis {
  const RecoveryShareAnalysis({
    this.shares = const [],
    this.threshold = 0,
    this.secret,
    this.secretId,
    this.ignoredShares = 0,
    this.tooManyShares = false,
  });

  /// The shares of the account most helpers agree on, each one once. Once
  /// [secret] is rebuilt, only the shares it was rebuilt from.
  final List<ReceivedRecoveryShare> shares;

  /// How many shares that account needs, or 0 before any usable share.
  final int threshold;

  /// The data rebuilt from [shares], once enough of them fit together.
  final SharedSecretData? secret;

  /// Identifies [secret] in `rejectedSecrets` of [PasswordlessRecoveryService.analyzeShares].
  final String? secretId;

  /// Shares left out: duplicates, shares for another account or threshold,
  /// and shares that do not fit the rebuilt data.
  final int ignoredShares;

  /// Too many conflicting shares arrived to try every combination.
  final bool tooManyShares;

  ReceivedRecoveryShare? get account => shares.isEmpty ? null : shares.first;

  bool get thresholdReached => threshold > 0 && shares.length >= threshold;
}

class PasswordlessRecoveryService {
  /// The server forgets a recovery link after seven days, so the app starts
  /// the session over then as well.
  static const recoverySessionLifetime = Duration(days: 7);

  static final StreamController<String> onEmailTokenReceived =
      StreamController<String>.broadcast();

  static String? lastEmailToken;

  static String linkPrefix = 'https://me.twonly.eu/r/#';

  static final Set<String> _openNotificationIds = {};

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

    if (_openNotificationIds.contains(notificationId)) {
      Log.info(
        'Recovery screen for $notificationId is already open, skipping.',
      );
      return;
    }

    final List<int> encryptionKey;
    try {
      encryptionKey = base64Url.decode(base64Url.normalize(base64Key));
    } on FormatException {
      Log.warn('Recovery link contains an invalid encryption key.');
      return;
    }
    if (notificationId.isEmpty ||
        parts.length != 2 ||
        encryptionKey.length != 32) {
      Log.warn('Recovery link contains invalid recovery data.');
      return;
    }

    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      // Suppress duplicate intent deliveries while the screen is open, but
      // allow reopening after cancellation or a failed submission.
      _openNotificationIds.add(notificationId);
      unawaited(
        context
            .navPush(
              HelpAFriendPasswordlessRecoveryView(
                notificationId: notificationId,
                encryptionKey: encryptionKey,
              ),
            )
            .whenComplete(() => _openNotificationIds.remove(notificationId)),
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
    final trustedFriendIdsBeforeReset = (await rust_recovery.recoveryFriendIds(
      transaction: currentDatabaseSession(),
    )).map((id) => id.toInt()).toList();

    for (final contactId in trustedFriendIdsBeforeReset) {
      try {
        await RustApi.sendEncryptedContent(
          contactId: contactId,
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
          'Failed to send delete PasswordLessRecovery message to contact $contactId: $e',
        );
      }
    }

    // 1. Reset current recovery data to ensure a clean state

    await rust_contacts.resetContactsRecovery(
      transaction: currentDatabaseSession(),
    );
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

    // 3.4. Store the shares in the contact's rows
    // Publish the configuration only after every share is committed. A
    // connection heartbeat must never see a partially configured helper list
    // and then postpone sending the remaining shares for 24 hours.
    final reversedShares = shares.reversed.toList(growable: false);
    if (trustedFriendIds.length != reversedShares.length) {
      throw ArgumentError('Recovery share count does not match contacts');
    }
    await rust_recovery.storeRecoveryShares(
      shares: [
        for (var i = 0; i < trustedFriendIds.length; i++)
          db_recovery.RecoveryShare(
            contactId: trustedFriendIds[i],
            secret: reversedShares[i],
          ),
      ],
      transaction: currentDatabaseSession(),
    );

    await UserService.update((u) => u.passwordLessRecovery = config);

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

  static Future<RecoveryPollResult> checkAndStorePasswordlessMessages(
    OnboardingState state,
  ) async {
    if (!state.serverRegistered ||
        state.notificationId == null ||
        state.downloadAuthToken == null ||
        state.encryptionKey == null) {
      return RecoveryPollResult.unchanged;
    }

    final alreadyReceivedIds = Int64List.fromList([
      ...state.receivedShares.map((share) => share.messageId),
      ...state.ignoredMessageIds,
    ]);

    late final List<FrbPasswordlessNotificationMessage> messages;
    try {
      messages = await RustApi.checkForPasswordlessNotification(
        notificationId: state.notificationId!,
        downloadAuthToken: state.downloadAuthToken!,
        alreadyReceivedMessageIds: alreadyReceivedIds,
      );
    } catch (error) {
      // The server purges a recovery link after seven days and from then on
      // answers as for one it never knew.
      if (apiErrorCodeOf(error) == ErrorCode.NoRecoveryData.value) {
        return RecoveryPollResult.expired;
      }
      // This runs on a 10s poll, so a socket that is still connecting or
      // briefly offline is expected. The next tick retries.
      Log.warn('Failed to load passwordless recovery messages', error);
      return RecoveryPollResult.unchanged;
    }

    if (messages.isEmpty) {
      return RecoveryPollResult.unchanged;
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

        // Setup never allows fewer than two helpers. A share claiming one
        // would rebuild to whatever its sender put into it.
        if (share.threshold < 2) {
          Log.warn('Ignoring recovery share $msgId with threshold below 2');
          state.ignoredMessageIds.add(msgId);
          didUpdate = true;
          continue;
        }

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
        state.ignoredMessageIds.add(msgId);
        didUpdate = true;
      }
    }

    if (didUpdate) {
      await KeyValueStore.update<OnboardingState>(
        key: KeyValueKeys.onboardingState,
        update: (s) => s
          ..receivedShares = state.receivedShares
          ..ignoredMessageIds = state.ignoredMessageIds,
      );
    }

    return didUpdate
        ? RecoveryPollResult.updated
        : RecoveryPollResult.unchanged;
  }

  /// Whether the server confirms that the recovered [keyManager] belongs to
  /// [userId], checked through its login token before anything is staged.
  ///
  /// A server from before this check answers BadRequest. Recovery then goes
  /// ahead unchecked, so an app released first does not lock users out.
  static Future<bool> recoveredKeysBelongTo(
    int userId,
    Uint8List keyManager,
  ) async {
    try {
      return await RustApi.verifyRecoveredIdentity(
        userId: userId,
        serializedKeyManager: keyManager,
      );
    } catch (error) {
      if (apiErrorCodeOf(error) == ErrorCode.BadRequest.value) {
        Log.warn('The server cannot check recovered keys yet');
        return true;
      }
      rethrow;
    }
  }

  static bool isRecoverySessionExpired(OnboardingState state, {DateTime? now}) {
    final startedAt = state.recoveryStartedAt;
    return startedAt != null &&
        (now ?? DateTime.now()).difference(startedAt) >=
            recoverySessionLifetime;
  }

  /// Drops the recovery link together with everything received through it.
  static Future<void> resetRecoverySession(OnboardingState state) async {
    void reset(OnboardingState s) => s
      ..notificationId = null
      ..downloadAuthToken = null
      ..encryptionKey = null
      ..serverRegistered = false
      ..emailRecoveryRequested = false
      ..receivedShares = []
      ..ignoredMessageIds = []
      ..recoveryStartedAt = null;

    reset(state);
    lastEmailToken = null;
    await KeyValueStore.update<OnboardingState>(
      key: KeyValueKeys.onboardingState,
      update: reset,
    );
  }

  /// Works out which received shares belong together and rebuilds the
  /// recovery data from them.
  ///
  /// Nothing authenticates the account and threshold a share names, so
  /// shares are grouped by both, the group most helpers agree on first.
  /// Within a group every combination is tried, which keeps a duplicate, a
  /// stale share from an earlier setup or a forged one from spoiling the
  /// rest. [rejectedSecrets] holds the `secretId` of data a later check
  /// refused, so the next candidate is used instead.
  static Future<RecoveryShareAnalysis> analyzeShares(
    List<ReceivedRecoveryShare> received, {
    Set<String> rejectedSecrets = const {},
  }) async {
    final seen = <String>{};
    final groups = <(int, int), List<ReceivedRecoveryShare>>{};
    for (final share in received) {
      if (share.threshold < 2 ||
          !seen.add(base64.encode(share.sharedSecretDataBytes))) {
        continue;
      }
      groups
          .putIfAbsent((share.myUserId, share.threshold), () => [])
          .add(share);
    }
    if (groups.isEmpty) {
      return RecoveryShareAnalysis(ignoredShares: received.length);
    }

    // Larger groups first; the stable sort keeps arrival order among equals.
    final ordered = groups.values.toList();
    mergeSort(ordered, compare: (a, b) => b.length.compareTo(a.length));

    var tooManyShares = false;
    for (final group in ordered) {
      final threshold = group.first.threshold;
      if (group.length < threshold) continue;

      final List<RecoveredSecretCandidate> candidates;
      try {
        candidates = await RustUtils.recoverSecretCandidates(
          shares: [
            for (final share in group)
              Uint8List.fromList(share.sharedSecretDataBytes),
          ],
          threshold: threshold,
        );
      } catch (e) {
        Log.warn('Could not combine the recovery shares: $e');
        tooManyShares = true;
        continue;
      }

      for (final candidate in candidates) {
        final secretId = base64.encode(candidate.secret);
        if (rejectedSecrets.contains(secretId)) continue;
        final secret = _parseSharedSecret(
          candidate.secret,
          group.first.myUserId,
        );
        if (secret == null) continue;

        final used = [for (final i in candidate.shareIndexes) group[i]];
        return RecoveryShareAnalysis(
          shares: used,
          threshold: threshold,
          secret: secret,
          secretId: secretId,
          ignoredShares: received.length - used.length,
        );
      }
    }

    final leading = ordered.first;
    return RecoveryShareAnalysis(
      shares: leading,
      threshold: leading.first.threshold,
      ignoredShares: received.length - leading.length,
      tooManyShares: tooManyShares,
    );
  }

  /// Accepts rebuilt data only in the shape the owner's app writes it. A
  /// combination containing a share that does not belong yields random bytes,
  /// which fail here.
  static SharedSecretData? _parseSharedSecret(List<int> bytes, int userId) {
    try {
      final secret = SharedSecretData.fromBuffer(bytes);
      if (secret.recoveryData.isEmpty) return null;

      if (secret.hasServerKeyProtection()) {
        // A second factor is either a PIN, with its unlock token, or an email.
        if (secret.serverKeyProtection.length != 32 ||
            secret.hasPinUnlockToken() == secret.hasEmailHint() ||
            (secret.hasPinUnlockToken() &&
                secret.pinUnlockToken.length != 32)) {
          return null;
        }
        final envelope = EncryptedEnvelope.fromBuffer(secret.recoveryData);
        if (envelope.iv.length != 24 || envelope.mac.length != 16) {
          return null;
        }
      } else {
        final recovery = RecoveryData.fromBuffer(secret.recoveryData);
        if (recovery.userId.toInt() != userId || recovery.keyManager.isEmpty) {
          return null;
        }
      }
      return secret;
    } on Object {
      return null;
    }
  }

  static Future<void> migratePasswordlessRecovery() async {
    final config = userService.currentUser.passwordLessRecovery;
    if (config == null) return;

    final trustedFriendIdsBeforeReset = (await rust_recovery.recoveryFriendIds(
      transaction: currentDatabaseSession(),
    )).map((id) => id.toInt()).toList();
    final trustedFriendIds = trustedFriendIdsBeforeReset;

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
      for (final contactId in trustedFriendIdsBeforeReset) {
        try {
          await RustApi.sendEncryptedContent(
            contactId: contactId,
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
            'Failed to send delete PasswordLessRecovery message to contact $contactId: $e',
          );
        }
      }

      await rust_contacts.resetContactsRecovery(
        transaction: currentDatabaseSession(),
      );
      await UserService.update((u) => u.passwordLessRecovery = null);
    }
  }
}
