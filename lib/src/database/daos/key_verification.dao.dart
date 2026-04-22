import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';

part 'key_verification.dao.g.dart';

@DriftAccessor(
  tables: [Contacts, VerificationTokens, KeyVerifications, GroupMembers],
)
class KeyVerificationDao extends DatabaseAccessor<TwonlyDB>
    with _$KeyVerificationDaoMixin {
  // ignore: matching_super_parameters
  KeyVerificationDao(super.db);

  Future<List<VerificationToken>> getRecentVerificationTokens() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return (select(
      verificationTokens,
    )..where((t) => t.createdAt.isBiggerOrEqualValue(cutoff))).get();
  }

  Future<int> insertVerificationToken(Uint8List token) {
    return into(verificationTokens).insert(
      VerificationTokensCompanion.insert(token: token),
    );
  }

  /// Returns a map of contactId → the verification type of the earliest
  /// [KeyVerification] row for that contact.
  Future<Map<int, VerificationType>>
  getFirstVerificationTypeByContacts() async {
    final rows = await (select(
      keyVerifications,
    )..orderBy([(kv) => OrderingTerm.asc(kv.createdAt)])).get();

    final result = <int, VerificationType>{};
    for (final row in rows) {
      result.putIfAbsent(row.contactId, () => row.type);
    }
    return result;
  }

  Future<bool> isContactVerified(int contactId) async {
    final row =
        await (select(keyVerifications)
              ..where((kv) => kv.contactId.equals(contactId))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Stream<List<KeyVerification>> watchContactVerification(int contactId) {
    return (select(
      keyVerifications,
    )..where((kv) => kv.contactId.equals(contactId))).watch();
  }

  Stream<bool> watchAllGroupMembersVerified(String groupId) {
    final gm = groupMembers;
    final kv = keyVerifications;

    final query = (select(gm)..where((m) => m.groupId.equals(groupId))).join([
      leftOuterJoin(kv, kv.contactId.equalsExp(gm.contactId)),
    ]);

    return query.watch().map(
      (rows) =>
          rows.isNotEmpty && rows.every((r) => r.readTableOrNull(kv) != null),
    );
  }

  Future<void> addKeyVerification(int contactId, VerificationType type) async {
    await into(keyVerifications).insertOnConflictUpdate(
      KeyVerificationsCompanion(
        contactId: Value(contactId),
        type: Value(type),
      ),
    );
  }
}
