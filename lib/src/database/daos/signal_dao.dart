import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/signal_contact_prekey_table.dart';
import 'package:twonly/src/database/tables/signal_contact_signed_prekey_table.dart';
import 'package:twonly/src/database/twonly_database.dart';

part 'signal_dao.g.dart';

@DriftAccessor(tables: [SignalContactPreKeys, SignalContactSignedPreKeys])
class SignalDao extends DatabaseAccessor<TwonlyDatabase> with _$SignalDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  SignalDao(super.db);

  Future deleteAllByContactId(int contactId) async {
    await (delete(signalContactPreKeys)
          ..where((t) => t.contactId.equals(contactId)))
        .go();
    await (delete(signalContactSignedPreKeys)
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
            ..where((tbl) =>
                tbl.contactId.equals(contactId) &
                tbl.preKeyId.equals(preKey.preKeyId)))
          .go();
      return preKey;
    }
    return null;
  }

  // 3: Insert multiple pre-keys
  Future<void> insertPreKeys(
      List<SignalContactPreKeysCompanion> preKeys) async {
    await batch((batch) {
      batch.insertAll(signalContactPreKeys, preKeys);
    });
  }

  // 4: Get signed pre-key by contact ID
  Future<SignalContactSignedPreKey?> getSignedPreKeyByContactId(int contactId) {
    return (select(signalContactSignedPreKeys)
          ..where((tbl) => tbl.contactId.equals(contactId)))
        .getSingleOrNull();
  }

  // 5: Insert or update signed pre-key by contact ID
  Future<void> insertOrUpdateSignedPreKeyByContactId(
      SignalContactSignedPreKeysCompanion signedPreKey) async {
    final existingKey =
        await getSignedPreKeyByContactId(signedPreKey.contactId.value);
    if (existingKey != null) {
      await update(signalContactSignedPreKeys).replace(signedPreKey);
    } else {
      await into(signalContactSignedPreKeys).insert(signedPreKey);
    }
  }
}
