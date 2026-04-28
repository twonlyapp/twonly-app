import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:twonly/core/bridge/wrapper/user_discovery.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/user_discovery/types.pb.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';

class UserDiscoveryService {
  static Future<void> checkForNewAnnouncedUsers() async {
    final announcedUsers = await twonlyDB.userDiscoveryDao
        .getNewAnnouncementsWithoutData();

    for (final announcedUser in announcedUsers) {
      final userdata = await apiService.getUserById(
        announcedUser.announcedUserId,
      );
      if (userdata == null) continue;
      if (!userdata.publicIdentityKey.equals(
        announcedUser.announcedPublicKey.toList(),
      )) {
        if (kDebugMode) {
          Log.warn(
            '${userdata.publicIdentityKey} != ${announcedUser.announcedPublicKey.toList()}',
          );
        }
        Log.error(
          'Server delivered a different public key then received from the announcement.',
        );
        continue;
      }

      Log.info('Updating the username from the announced user');

      // Updating the username, so the data will not be requested again..
      await twonlyDB.userDiscoveryDao.updateAnnouncedUser(
        announcedUser.announcedUserId,
        UserDiscoveryAnnouncedUsersCompanion(
          username: Value(utf8.decode(userdata.username)),
        ),
      );
    }
  }

  static Future<void> initializeOrUpdate({
    required int threshold,
    required bool sharePromotion,
  }) async {
    try {
      await FlutterUserDiscovery.initializeOrUpdate(
        threshold: threshold,
        userId: userService.currentUser.userId,
        publicKey: await getUserPublicKey(),
        sharePromotion: sharePromotion,
      );
      await UserService.update(
        (u) => u
          ..isUserDiscoveryEnabled = true
          ..userDiscoverySharePromotion = sharePromotion
          ..userDiscoveryThreshold = threshold,
      );
    } catch (e) {
      Log.error(e);
    }
  }

  static Future<Uint8List?> getCurrentVersion() async {
    try {
      return await FlutterUserDiscovery.getCurrentVersion();
    } catch (e) {
      Log.error(e);
      return null;
    }
  }

  static Future<UserDiscoveryVersion?> getCurrentVersionTyped() async {
    final version = await getCurrentVersion();
    if (version == null) return null;
    return UserDiscoveryVersion.fromBuffer(version);
  }

  static Future<UserDiscoveryVersion?> getContactVersionTyped(
    int contactId,
  ) async {
    final contact = await twonlyDB.contactsDao.getContactById(contactId);
    if (contact == null || contact.userDiscoveryVersion == null) return null;
    return UserDiscoveryVersion.fromBuffer(contact.userDiscoveryVersion!);
  }

  static UserDiscoveryVersion? getContactVersionTypedFromContact(
    Contact contact,
  ) {
    if (contact.userDiscoveryVersion == null) return null;
    return UserDiscoveryVersion.fromBuffer(contact.userDiscoveryVersion!);
  }

  static Future<Uint8List?> shouldRequestNewMessages(
    int fromUserId,
    List<int> receivedVersion,
  ) async {
    try {
      return await FlutterUserDiscovery.shouldRequestNewMessages(
        contactId: fromUserId,
        version: receivedVersion,
      );
    } catch (e) {
      Log.error(e);
      return null;
    }
  }

  static Future<List<Uint8List>?> getNewMessages(
    int fromUserId,
    List<int> receivedVersion,
  ) async {
    try {
      return await FlutterUserDiscovery.getNewMessages(
        contactId: fromUserId,
        receivedVersion: receivedVersion,
      );
    } catch (e) {
      Log.error(e);
      return null;
    }
  }

  static Future<void> handleNewMessages(
    int fromUserId,
    List<Uint8List> messages,
  ) async {
    try {
      final verifications = await twonlyDB.keyVerificationDao
          .getContactVerification(fromUserId);

      return await FlutterUserDiscovery.handleNewMessages(
        contactId: fromUserId,
        messages: messages,
        publicKeyVerifiedTimestamp:
            verifications.lastOrNull?.createdAt.millisecondsSinceEpoch,
      );
    } catch (e) {
      Log.error(e);
    }
  }

  static Future<void> changeExclusionForContact(
    int contactId,
    bool exclude,
  ) async {
    // Remove old versions from the user...
    await (twonlyDB.update(
      twonlyDB.userDiscoveryOwnPromotions,
    )..where((t) => t.contactId.equals(contactId))).write(
      UserDiscoveryOwnPromotionsCompanion(promotion: Value(Uint8List(0))),
    );

    await twonlyDB.contactsDao.updateContact(
      contactId,
      ContactsCompanion(
        userDiscoveryExcluded: Value(exclude),
        userDiscoveryVersion: const Value(
          null, // If the user is included again, this will trigger a new request of his original announcement
        ),
      ),
    );
  }

  static Future<void> disable() async {
    await UserService.update((u) {
      u.isUserDiscoveryEnabled = false;
    });
  }
}
