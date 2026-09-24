import 'dart:async';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/core/bridge/wrapper/signal.dart';
import 'package:twonly/core/signal/engine.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart';
import 'package:twonly/src/services/signal/consts.signal.dart';
import 'package:twonly/src/services/signal/protocol_state.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/utils/log.dart';

class _SignalUpgradeState {
  final lock = Mutex();
  final activeV1Contacts = <int>{};
  Timer? idleTimer;
}

/// Production isolates have one database, while integration tests host
/// multiple clients in zones in the same isolate. Keeping the queue per
/// database prevents one client's activity from being migrated in another
/// client's Signal store.
final Map<TwonlyDB, _SignalUpgradeState> _signalUpgradeStates = {};

_SignalUpgradeState get _signalUpgradeState => _signalUpgradeStates.putIfAbsent(
  twonlyDB,
  _SignalUpgradeState.new,
);

const _signalUpgradeIdleDelay = Duration(milliseconds: 500);

Future<bool> processSignalUserData(Response_UserData userData) async {
  return lockingSignalProtocol.protect(() async {
    return _processSignalUserData(userData);
  });
}

/// Adds a V1 session to the active migration set without starting migration.
/// Incoming batches use this so migration cannot begin midway through a slow
/// decryption pass.
void queueSignalSessionUpgrade(int contactId) {
  final state = _signalUpgradeState;
  state.activeV1Contacts.add(contactId);
}

/// Starts or resets the idle window for queued active V1 sessions.
void scheduleActiveSignalSessionUpgrades() {
  final state = _signalUpgradeState;
  state.idleTimer?.cancel();
  state.idleTimer = Timer(_signalUpgradeIdleDelay, () {
    state.idleTimer = null;
    unawaited(upgradeActiveSignalSessionsToV2());
  });
}

/// Marks an outgoing V1 session as active and schedules its migration.
void scheduleSignalSessionUpgrade(int contactId) {
  queueSignalSessionUpgrade(contactId);
  scheduleActiveSignalSessionUpgrades();
}

/// Runs pending active-session upgrades immediately after the mailbox drains.
void flushActiveSignalSessionUpgrades() {
  final state = _signalUpgradeState;
  state.idleTimer?.cancel();
  state.idleTimer = null;
  unawaited(upgradeActiveSignalSessionsToV2());
}

/// Upgrades active V1 contacts that currently publish a PQXDH bundle.
///
/// The legacy session is deliberately retained: messages that were already in
/// flight before the upgrade can still be decrypted, while newly queued
/// messages use the contact's updated v2 session.
Future<void> upgradeActiveSignalSessionsToV2() async {
  final state = _signalUpgradeState;
  try {
    await state.lock.protect(() async {
      // Activity may arrive during an upgrade. Drain until every contact
      // queued by that activity has been considered.
      while (state.activeV1Contacts.isNotEmpty) {
        final contactIds = Set<int>.of(state.activeV1Contacts);
        state.activeV1Contacts.removeAll(contactIds);

        for (final contactId in contactIds) {
          try {
            final contact = await twonlyDB.contactsDao.getContactById(
              contactId,
            );
            if (contact == null ||
                contact.signalVersion != SignalVersion.v1 ||
                contact.accountDeleted) {
              continue;
            }

            final userData = await apiService.getUserById(contactId);
            if (userData == null || !userData.hasPqcBundle()) continue;

            if (await processSignalUserData(userData)) {
              Log.info('Upgraded active Signal session with $contactId to v2.');
            }
          } catch (error) {
            // Further traffic queues the contact again, so temporary failures
            // cannot leave an active session on V1 indefinitely.
            Log.warn(
              'Could not upgrade active Signal session with $contactId: '
              '$error',
            );
          }
        }
      }
    });
  } catch (error) {
    // This function is started without awaiting it from the message loop.
    Log.warn('Could not start Signal session upgrades: $error');
  }
}

/// Replaces the current session with a freshly downloaded pre-key bundle.
Future<bool> resetSignalSession(int contactId) async {
  final userData = await apiService.getUserById(contactId);
  if (userData == null) return false;

  return lockingSignalProtocol.protect(() async {
    if (userData.hasPqcBundle()) {
      await RustSignal.resetContactSession(contactId: contactId);
    } else {
      final signalStore = await getSignalStore();
      await signalStore?.deleteAllSessions(contactId.toString());
    }
    final reset = await _processSignalUserData(userData);
    if (reset) {
      recordResyncAttempt(
        contactId,
        userData.hasPqcBundle() ? SignalVersion.v2 : SignalVersion.v1,
        success: true,
      );
    }
    return reset;
  });
}

ECPublicKey _decodePublicKey(List<int> bytes, String fieldName) {
  if (bytes.length != 33 || bytes.first != Curve.djbType) {
    throw InvalidKeyException(
      '$fieldName must be a serialized 33-byte Curve25519 public key '
      '(received ${bytes.length} bytes)',
    );
  }
  return Curve.decodePoint(Uint8List.fromList(bytes), 0);
}

Future<bool> _processSignalUserData(Response_UserData userData) async {
  if (userData.hasPqcBundle()) {
    return _processSignalUserDataV2(userData);
  }
  return _processSignalUserDataV1(userData);
}

Future<bool> _processSignalUserDataV2(Response_UserData userData) async {
  try {
    final tempIdentityKey = IdentityKey(
      _decodePublicKey(userData.publicIdentityKey, 'identity key'),
    );

    final contact = await twonlyDB.contactsDao.getContactById(
      userData.userId.toInt(),
    );

    // Only the one-time V1 -> V2 migration needs to compare against the
    // legacy Dart identity store. Established V2 contacts are authenticated
    // by the identity retained in the Rust store; consulting the obsolete
    // Dart store here can make a valid V2 reset fail on legacy/corrupt data.
    if (contact?.signalVersion != SignalVersion.v2) {
      final signalStore = await getSignalStore();
      final existingIdentity = await signalStore?.getIdentity(
        SignalProtocolAddress(userData.userId.toString(), defaultDeviceId),
      );

      if (existingIdentity != null && existingIdentity != tempIdentityKey) {
        Log.error(
          'Identity key mismatch for contact ${userData.userId}! Existing V1 key does not match the incoming V2 identity key.',
        );
        return false;
      }
    }

    int? tempEccPreKeyId;
    Uint8List? tempEccPreKeyPublic;
    if (userData.pqcBundle.hasPrekey()) {
      tempEccPreKeyId = userData.pqcBundle.prekey.eccPreKeyId.toInt();
      tempEccPreKeyPublic = Uint8List.fromList(
        userData.pqcBundle.prekey.eccPreKey,
      );
    } else if (userData.prekeys.isNotEmpty) {
      tempEccPreKeyId = userData.prekeys.first.id.toInt();
      tempEccPreKeyPublic = _decodePublicKey(
        userData.prekeys.first.prekey,
        'prekey',
      ).serialize();
    }

    final tempKyberPreKeyId = userData.pqcBundle.hasPrekey()
        ? userData.pqcBundle.prekey.kyberPreKeyId.toInt()
        : userData.pqcBundle.kyberSignedPrekeyId.toInt();
    final tempKyberPreKeyPublic = userData.pqcBundle.hasPrekey()
        ? Uint8List.fromList(userData.pqcBundle.prekey.kyberPreKey)
        : Uint8List.fromList(userData.pqcBundle.kyberSignedPrekey);
    final tempKyberPreKeySignature = userData.pqcBundle.hasPrekey()
        ? Uint8List.fromList(userData.pqcBundle.prekey.kyberPreKeySignature)
        : Uint8List.fromList(userData.pqcBundle.kyberSignedPrekeySignature);

    final rustBundle = FrbPreKeyBundle(
      registrationId: userData.registrationId.toInt(),
      deviceId: 1,
      preKeyId: tempEccPreKeyId,
      preKeyPublic: tempEccPreKeyPublic,
      signedPreKeyId: userData.pqcBundle.eccSignedPrekeyId.toInt(),
      signedPreKeyPublic: Uint8List.fromList(
        userData.pqcBundle.eccSignedPrekey,
      ),
      signedPreKeySignature: Uint8List.fromList(
        userData.pqcBundle.eccSignedPrekeySignature,
      ),
      identityKey: tempIdentityKey.publicKey.serialize(),
      kyberPreKeyId: tempKyberPreKeyId,
      kyberPreKeyPublic: tempKyberPreKeyPublic,
      kyberPreKeySignature: tempKyberPreKeySignature,
    );

    await RustSignal.processPrekeyBundle(
      name: userData.userId.toString(),
      deviceId: 1,
      bundle: rustBundle,
    );

    if (contact != null && contact.signalVersion != SignalVersion.v2) {
      await twonlyDB.contactsDao.updateContact(
        contact.userId,
        const ContactsCompanion(signalVersion: drift.Value(SignalVersion.v2)),
      );
    }

    return true;
  } catch (e) {
    Log.error('could not process pqc bundle: $e');
    return false;
  }
}

Future<bool> _processSignalUserDataV1(Response_UserData userData) async {
  try {
    final SignalProtocolStore? signalStore = await getSignalStore();

    if (signalStore == null) {
      return false;
    }

    final targetAddress = getSignalAddress(userData.userId.toInt());

    final sessionBuilder = SessionBuilder.fromSignalStore(
      signalStore,
      targetAddress,
    );

    ECPublicKey? tempPrePublicKey;
    int? tempPreKeyId;

    if (userData.prekeys.isNotEmpty) {
      tempPrePublicKey = _decodePublicKey(
        userData.prekeys.first.prekey,
        'prekey',
      );
      tempPreKeyId = userData.prekeys.first.id.toInt();
    }

    final tempSignedPreKeyId = userData.signedPrekeyId.toInt();

    final tempSignedPreKeyPublic = _decodePublicKey(
      userData.signedPrekey,
      'signed prekey',
    );

    final tempSignedPreKeySignature = Uint8List.fromList(
      userData.signedPrekeySignature,
    );

    final tempIdentityKey = IdentityKey(
      _decodePublicKey(userData.publicIdentityKey, 'identity key'),
    );

    final preKeyBundle = PreKeyBundle(
      userData.registrationId.toInt(),
      defaultDeviceId,
      tempPreKeyId,
      tempPrePublicKey,
      tempSignedPreKeyId,
      tempSignedPreKeyPublic,
      tempSignedPreKeySignature,
      tempIdentityKey,
    );

    await sessionBuilder.processPreKeyBundle(preKeyBundle);
    return true;
  } catch (e) {
    Log.error('could not process pre key bundle: $e');
    return false;
  }
}

Future<Uint8List?> getPublicKeyFromContact(int contactId) async {
  final signalStore = await getSignalStore();
  if (signalStore == null) return null;
  try {
    final targetIdentity = await signalStore.getIdentity(
      SignalProtocolAddress(
        contactId.toString(),
        defaultDeviceId,
      ),
    );
    if (targetIdentity != null) {
      return targetIdentity.publicKey.serialize();
    }
    return null;
  } catch (e) {
    return null;
  }
}

Future<bool> handleSessionResync(int fromUserId) async {
  final userData = await apiService.getUserById(fromUserId);
  if (userData != null) {
    Log.info('Got new session data from the server to re-sync the session');
    return processSignalUserData(userData);
  }
  Log.info('Could not download userdata from the server.');
  return false;
}
