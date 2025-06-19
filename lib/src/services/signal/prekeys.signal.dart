import 'package:drift/drift.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as server;

class OtherPreKeys {
  OtherPreKeys({
    required this.preKeys,
    required this.signedPreKey,
    required this.signedPreKeyId,
    required this.signedPreKeySignature,
  });
  final List<server.Response_PreKey> preKeys;
  final int signedPreKeyId;
  final List<int> signedPreKey;
  final List<int> signedPreKeySignature;
}

Mutex requestNewKeys = Mutex();
DateTime lastPreKeyRequest = DateTime.now().subtract(Duration(hours: 1));
DateTime lastSignedPreKeyRequest = DateTime.now().subtract(Duration(hours: 1));

Future requestNewPrekeysForContact(int contactId) async {
  if (lastPreKeyRequest
      .isAfter(DateTime.now().subtract(Duration(seconds: 60)))) {
    Log.info("last pre request was 60s before");
    return;
  }
  lastPreKeyRequest = DateTime.now();
  requestNewKeys.protect(() async {
    final otherKeys = await apiService.getPreKeysByUserId(contactId);
    if (otherKeys != null) {
      Log.info(
          "got fresh ${otherKeys.preKeys.length}  pre keys from other $contactId!");
      final preKeys = otherKeys.preKeys
          .map(
            (preKey) => SignalContactPreKeysCompanion(
              contactId: Value(contactId),
              preKey: Value(Uint8List.fromList(preKey.prekey)),
              preKeyId: Value(preKey.id.toInt()),
            ),
          )
          .toList();
      await twonlyDB.signalDao.insertPreKeys(preKeys);
    } else {
      Log.error("could not load new pre keys for user $contactId");
    }
  });
}

Future<SignalContactPreKey?> getPreKeyByContactId(int contactId) async {
  int count = await twonlyDB.signalDao.countPreKeysByContactId(contactId);
  if (count < 10) {
    Log.info("Requesting new prekeys: $count < 10");
    requestNewPrekeysForContact(contactId);
  }
  return twonlyDB.signalDao.popPreKeyByContactId(contactId);
}

Future requestNewSignedPreKeyForContact(int contactId) async {
  if (lastSignedPreKeyRequest
      .isAfter(DateTime.now().subtract(Duration(seconds: 60)))) {
    Log.info("last signed pre request was 60s before");
    return;
  }
  lastSignedPreKeyRequest = DateTime.now();
  await requestNewKeys.protect(() async {
    final signedPreKey = await apiService.getSignedKeyByUserId(contactId);
    if (signedPreKey != null) {
      Log.info("got fresh signed pre keys from other $contactId!");
      await twonlyDB.signalDao.insertOrUpdateSignedPreKeyByContactId(
          SignalContactSignedPreKeysCompanion(
        contactId: Value(contactId),
        signedPreKey: Value(Uint8List.fromList(signedPreKey.signedPrekey)),
        signedPreKeySignature:
            Value(Uint8List.fromList(signedPreKey.signedPrekeySignature)),
        signedPreKeyId: Value(signedPreKey.signedPrekeyId.toInt()),
      ));
    } else {
      Log.error("could not load new signed pre key for user $contactId");
    }
  });
}

Future<SignalContactSignedPreKey?> getSignedPreKeyByContactId(
  int contactId,
) async {
  SignalContactSignedPreKey? signedPreKey =
      await twonlyDB.signalDao.getSignedPreKeyByContactId(contactId);

  if (signedPreKey != null) {
    DateTime fortyEightHoursAgo = DateTime.now().subtract(Duration(hours: 48));
    bool isOlderThan48Hours =
        (signedPreKey.createdAt).isBefore(fortyEightHoursAgo);
    if (isOlderThan48Hours) {
      requestNewSignedPreKeyForContact(contactId);
    }
  } else {
    requestNewSignedPreKeyForContact(contactId);
    Log.error("Contact $contactId does not have a signed pre key!");
  }
  return signedPreKey;
}
