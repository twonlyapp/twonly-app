import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:twonly/core/bridge/wrapper/user_discovery.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/tables/user_discovery.table.dart';
import 'package:twonly/src/database/twonly.db.dart';

part 'key_verification.dao.g.dart';

enum VerificationStatus { trusted, partialTrusted, notTrusted }

@DriftAccessor(
  tables: [
    Contacts,
    VerificationTokens,
    KeyVerifications,
    GroupMembers,
    UserDiscoveryUserRelations,
  ],
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

  Future<List<KeyVerification>> getContactVerification(int contactId) async {
    return (select(
      keyVerifications,
    )..where((kv) => kv.contactId.equals(contactId))).get();
  }

  Stream<List<(Contact, DateTime)>> watchTransferredTrustVerifications(
    int contactId,
  ) {
    final kv = keyVerifications;
    final ur = userDiscoveryUserRelations;

    final query =
        (select(contacts)..where((u) => u.userId.equals(contactId).not())).join(
          [
            innerJoin(
              ur,
              ur.fromContactId.equalsExp(contacts.userId),
            ),
            innerJoin(kv, kv.contactId.equalsExp(ur.fromContactId)),
          ],
        )..where(
          ur.announcedUserId.equals(contactId) &
              ur.publicKeyVerifiedTimestamp.isNotNull(),
        );

    return query.watch().map((rows) {
      return rows.map((row) {
        final contact = row.readTable(contacts);
        final timestamp = row.readTable(ur).publicKeyVerifiedTimestamp!;
        return (contact, timestamp);
      }).toList();
    });
  }

  Future<int> getTransferredTrustVerificationsCount() async {
    final kv = keyVerifications;
    final ur = userDiscoveryUserRelations;

    final query = selectOnly(ur, distinct: true)
      ..addColumns([ur.announcedUserId])
      ..join([
        innerJoin(contacts, contacts.userId.equalsExp(ur.fromContactId)),
        innerJoin(kv, kv.contactId.equalsExp(ur.fromContactId)),
      ])
      ..where(
        ur.publicKeyVerifiedTimestamp.isNotNull() &
            ur.announcedUserId.equalsExp(ur.fromContactId).not(),
      );

    final rows = await query.get();
    return rows.length;
  }

  Stream<VerificationStatus> watchAllGroupMembersVerified(String groupId) {
    final gm = groupMembers;
    final directKv = alias(keyVerifications, 'directKv');
    final ur = userDiscoveryUserRelations;
    final verifierKv = alias(keyVerifications, 'verifierKv');

    final query = select(gm).join([
      leftOuterJoin(directKv, directKv.contactId.equalsExp(gm.contactId)),
      leftOuterJoin(
        ur,
        ur.announcedUserId.equalsExp(gm.contactId) &
            ur.publicKeyVerifiedTimestamp.isNotNull() &
            ur.fromContactId.equalsExp(gm.contactId).not(),
      ),
      leftOuterJoin(
        verifierKv,
        verifierKv.contactId.equalsExp(ur.fromContactId),
      ),
    ])..where(gm.groupId.equals(groupId));

    return query.watch().map((rows) {
      if (rows.isEmpty) return VerificationStatus.notTrusted;

      final memberTrustMap = <int, ({bool direct, bool partial})>{};

      for (final row in rows) {
        final contactId = row.readTable(gm).contactId;
        final isDirect = row.readTableOrNull(directKv) != null;
        final isPartial = row.readTableOrNull(verifierKv) != null;

        final current =
            memberTrustMap[contactId] ?? (direct: false, partial: false);
        memberTrustMap[contactId] = (
          direct: current.direct || isDirect,
          partial: current.partial || isPartial,
        );
      }

      final allDirect = memberTrustMap.values.every((m) => m.direct);
      if (allDirect) return VerificationStatus.trusted;

      final allAtLeastPartial = memberTrustMap.values.every(
        (m) => m.direct || m.partial,
      );
      if (allAtLeastPartial) return VerificationStatus.partialTrusted;

      return VerificationStatus.notTrusted;
    });
  }

  Future<void> addKeyVerification(int contactId, VerificationType type) async {
    await into(keyVerifications).insertOnConflictUpdate(
      KeyVerificationsCompanion(
        contactId: Value(contactId),
        type: Value(type),
      ),
    );
    if (userService.currentUser.isUserDiscoveryEnabled) {
      await FlutterUserDiscovery.updateVerificationStateForUser(
        contactId: contactId,
        publicKeyVerifiedTimestamp: clock.now().millisecondsSinceEpoch,
      );
    }
  }
}
