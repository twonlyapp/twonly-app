import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/signal_contact_prekey.table.dart';
import 'package:twonly/src/database/tables/signal_contact_signed_prekey.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';

part 'signal.dao.g.dart';

@DriftAccessor(
  tables: [
    SignalContactPreKeys,
    SignalContactSignedPreKeys,
  ],
)
class SignalDao extends DatabaseAccessor<TwonlyDB> with _$SignalDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  // ignore: matching_super_parameters
  SignalDao(super.db);
  Future<void> deleteAllByContactId(int contactId) async {
    await (delete(signalContactPreKeys)
          ..where((t) => t.contactId.equals(contactId)))
        .go();
    await (delete(signalContactSignedPreKeys)
          ..where((t) => t.contactId.equals(contactId)))
        .go();
  }

  Future<void> deleteAllPreKeysByContactId(int contactId) async {
    await (delete(signalContactPreKeys)
          ..where((t) => t.contactId.equals(contactId)))
        .go();
  }

  // 1: Count the number of pre-keys by contact ID
  Future<int> countPreKeysByContactId(int contactId) {
    return (select(signalContactPreKeys)
          ..where((tbl) => tbl.contactId.equals(contactId)))
        .get()
        .then((rows) => rows.length);
  }

  // 2: Pop a pre-key by contact ID
  Future<SignalContactPreKey?> popPreKeyByContactId(int contactId) async {
    final preKey =
        await ((select(signalContactPreKeys)..where((tbl) => tbl.contactId.equals(contactId)))
              ..limit(1))
            .getSingleOrNull();

    if (preKey != null) {
      // remove the pre key...
      await (delete(signalContactPreKeys)
            ..where(
              (tbl) =>
                  tbl.contactId.equals(contactId) &
                  tbl.preKeyId.equals(preKey.preKeyId),
            ))
          .go();
      return preKey;
    }
    return null;
  }

  // 3: Insert multiple pre-keys
  Future<void> insertPreKeys(
    List<SignalContactPreKeysCompanion> preKeys,
  ) async {
    for (final preKey in preKeys) {
      try {
        await into(signalContactPreKeys).insert(preKey);
      } catch (e) {
        Log.error('$e');
      }
    }
  }

  // 4: Get signed pre-key by contact ID
  Future<SignalContactSignedPreKey?> getSignedPreKeyByContactId(int contactId) {
    return (select(signalContactSignedPreKeys)
          ..where((tbl) => tbl.contactId.equals(contactId)))
        .getSingleOrNull();
  }

  // 5: Insert or update signed pre-key by contact ID
  Future<void> insertOrUpdateSignedPreKeyByContactId(
    SignalContactSignedPreKeysCompanion signedPreKey,
  ) async {
    await (delete(signalContactSignedPreKeys)
          ..where((t) => t.contactId.equals(signedPreKey.contactId.value)))
        .go();
    await into(signalContactSignedPreKeys).insert(signedPreKey);
  }

  Future<void> purgePreKeysFromContact(int contactId) async {
    await (delete(signalContactPreKeys)
          ..where(
            (t) => (t.contactId.equals(contactId)),
          ))
        .go();
  }

  Future<void> purgeOutDatedPreKeys() async {
    // other pre keys are valid 100 days
    await (delete(signalContactPreKeys)
          ..where(
            (t) => (t.createdAt.isSmallerThanValue(
              clock.now().subtract(
                    const Duration(days: 100),
                  ),
            )),
          ))
        .go();
    // own pre keys are valid for 180 days
    await (delete(twonlyDB.signalPreKeyStores)
          ..where(
            (t) => (t.createdAt.isSmallerThanValue(
              clock.now().subtract(
                    const Duration(days: 365),
                  ),
            )),
          ))
        .go();
  }
}
