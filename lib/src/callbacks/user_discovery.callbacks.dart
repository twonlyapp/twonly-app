import 'package:drift/drift.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart'
    show Curve, IdentityKey;
// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/ecc/ed25519.dart';
import 'package:twonly/core/bridge.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

class UserDiscoveryCallbacks {
  static Future<Uint8List?> signData(
    Uint8List inputData,
  ) async {
    var privKey = (await getSignalIdentityKeyPair())?.getPrivateKey();
    if (privKey == null) return null;
    final random = getRandomUint8List(32);
    final signature = sign(
      privKey.serialize(),
      inputData,
      random,
    );
    privKey = null;
    return signature;
  }

  static Future<bool> verifySignature(
    Uint8List inputData,
    Uint8List pubKey,
    Uint8List signature,
  ) async {
    return Curve.verifySignature(
      IdentityKey.fromBytes(pubKey, 0).publicKey,
      inputData,
      signature,
    );
  }

  static Future<bool> verifyStoredPubKey(
    int contactId,
    Uint8List pubKey,
  ) async {
    final storedPublicKey = await getPublicKeyFromContact(contactId);
    if (storedPublicKey != null) {
      return storedPublicKey == pubKey;
    } else {
      return false;
    }
  }

  static Future<bool> setShares(List<Uint8List> shares) async {
    try {
      // First remove all old shares then insert all the new shares
      await twonlyDB.delete(twonlyDB.userDiscoveryShares).go();
      await twonlyDB.batch((b) {
        b.insertAll(
          twonlyDB.userDiscoveryShares,
          shares
              .map((s) => UserDiscoverySharesCompanion(share: Value(s)))
              .toList(),
        );
      });
      return true;
    } catch (e) {
      Log.error(e);
      return false;
    }
  }

  static Future<Uint8List?> userDiscoveryGetShareForContact(
    int contactId,
  ) async {
    return twonlyDB.transaction(() async {
      // 1. Check if this contact already has a share assigned
      final existing =
          await (twonlyDB.select(twonlyDB.userDiscoveryShares)
                ..where((tbl) => tbl.contactId.equals(contactId))
                ..limit(1))
              .getSingleOrNull();

      if (existing != null) {
        return existing.share;
      }

      // 2. No share found. Find an available one (where contactId is null)
      final available =
          await (twonlyDB.select(twonlyDB.userDiscoveryShares)
                ..where((tbl) => tbl.contactId.isNull())
                ..limit(1))
              .getSingleOrNull();

      if (available != null) {
        // 3. Assign the contactId to this available share
        await (twonlyDB.update(
          twonlyDB.userDiscoveryShares,
        )..where((tbl) => tbl.shareId.equals(available.shareId))).write(
          UserDiscoverySharesCompanion(
            contactId: Value(contactId),
          ),
        );

        return available.share;
      }

      return null; // 4. No existing or available shares found
    });
  }

  static Future<bool> pushOwnPromotion(
    int contactId,
    int version, // Maps to versionId or logic control
    Uint8List promotion,
  ) async {
    try {
      await twonlyDB
          .into(twonlyDB.userDiscoveryOwnPromotions)
          .insert(
            UserDiscoveryOwnPromotionsCompanion.insert(
              contactId: contactId,
              promotion: promotion,
            ),
          );
      return true;
    } catch (e) {
      Log.error(e);
      return false;
    }
  }

  static Future<List<Uint8List>> getOwnPromotionsAfterVersion(
    int version,
  ) async {
    final query = twonlyDB.select(twonlyDB.userDiscoveryOwnPromotions)
      ..where((tbl) => tbl.versionId.isBiggerThanValue(version));

    final rows = await query.get();
    return rows.map((r) => r.promotion).toList();
  }

  static Future<bool> storeOtherPromotion(
    OtherPromotion promotion,
  ) async {
    try {
      await twonlyDB
          .into(twonlyDB.userDiscoveryOtherPromotions)
          .insertOnConflictUpdate(
            UserDiscoveryOtherPromotionsCompanion(
              promotionId: Value(promotion.promotionId),
              publicId: Value(promotion.publicId),
              fromContactId: Value(promotion.fromContactId),
              threshold: Value(promotion.threshold),
              announcementShare: Value(promotion.announcementShare),
              publicKeyVerifiedTimestamp: Value(
                promotion.publicKeyVerifiedTimestamp == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        promotion.publicKeyVerifiedTimestamp!,
                      ),
              ),
            ),
          );
      return true;
    } catch (e) {
      Log.error(e);
      return false;
    }
  }

  static Future<List<OtherPromotion>> getOtherPromotionsByPublicId(
    int publicId,
  ) async {
    final rows = await (twonlyDB.select(
      twonlyDB.userDiscoveryOtherPromotions,
    )..where((tbl) => tbl.publicId.equals(publicId))).get();

    return rows
        .map(
          (row) => OtherPromotion(
            promotionId: row.promotionId,
            publicId: row.publicId,
            fromContactId: row.fromContactId,
            threshold: row.threshold,
            announcementShare: row.announcementShare,
            publicKeyVerifiedTimestamp:
                row.publicKeyVerifiedTimestamp?.millisecondsSinceEpoch,
          ),
        )
        .toList();
  }

  static Future<AnnouncedUser?> getAnnouncedUserByPublicId(
    int publicId,
  ) async {
    final row = await (twonlyDB.select(
      twonlyDB.userDiscoveryAnnouncedUsers,
    )..where((tbl) => tbl.publicId.equals(publicId))).getSingleOrNull();
    if (row == null) return null;
    return AnnouncedUser(
      userId: row.announcedUserId,
      publicKey: row.announcedPublicKey,
      publicId: row.publicId,
    );
  }

  static Future<bool> pushNewUserRelation(
    int fromContactId,
    AnnouncedUser announcedUser,
    int? publicKeyVerifiedTimestamp,
  ) async {
    try {
      await twonlyDB.transaction(() async {
        // 1. Ensure the user exists in the AnnouncedUsers table
        await twonlyDB
            .into(twonlyDB.userDiscoveryAnnouncedUsers)
            .insertOnConflictUpdate(
              UserDiscoveryAnnouncedUser(
                announcedUserId: announcedUser.userId,
                announcedPublicKey: announcedUser.publicKey,
                publicId: announcedUser.publicId,
              ),
            );

        // 2. Insert or update the relation
        await twonlyDB
            .into(twonlyDB.userDiscoveryUserRelations)
            .insertOnConflictUpdate(
              UserDiscoveryUserRelationsCompanion.insert(
                announcedUserId: announcedUser.userId,
                fromContactId: fromContactId,
                publicKeyVerifiedTimestamp: Value(
                  publicKeyVerifiedTimestamp != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                          publicKeyVerifiedTimestamp,
                        )
                      : null,
                ),
              ),
            );
      });
      return true;
    } catch (e) {
      Log.error(e);
      return false;
    }
  }

  // static Future<Map<AnnouncedUser, List<(int, DateTime?)>>>
  // getAllAnnouncedUsers() async {
  //   final query = twonlyDB.select(twonlyDB.userDiscoveryAnnouncedUsers).join([
  //     innerJoin(
  //       twonlyDB.userDiscoveryUserRelations,
  //       twonlyDB.userDiscoveryUserRelations.announcedUserId.equalsExp(
  //         twonlyDB.userDiscoveryAnnouncedUsers.announcedUserId,
  //       ),
  //     ),
  //   ]);

  //   final results = await query.get();
  //   final map = <UserDiscoveryAnnouncedUser, List<(int, DateTime?)>>{};

  //   for (final row in results) {
  //     final user = row.readTable(twonlyDB.userDiscoveryAnnouncedUsers);
  //     final relation = row.readTable(twonlyDB.userDiscoveryUserRelations);

  //     map.putIfAbsent(user, () => []).add(
  //       (relation.fromContactId, relation.publicKeyVerifiedTimestamp),
  //     );
  //   }

  //   return map;
  // }

  static Future<Uint8List?> getContactVersion(int contactId) async {
    final row = await (twonlyDB.select(
      twonlyDB.contacts,
    )..where((tbl) => tbl.userId.equals(contactId))).getSingleOrNull();
    return row?.userDiscoveryVersion;
  }

  static Future<bool> setContactVersion(int contactId, Uint8List update) async {
    try {
      await (twonlyDB.update(twonlyDB.contacts)
            ..where((tbl) => tbl.userId.equals(contactId)))
          .write(ContactsCompanion(userDiscoveryVersion: Value(update)));
      return true;
    } catch (e) {
      Log.error(e);
      return false;
    }
  }
}
