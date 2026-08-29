import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:twonly/core/bridge/wrapper/user_discovery.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/user_discovery/types.pb.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';

class UserDiscoveryService {
  static Future<void> checkForNewAnnouncedUsers() async {
    final announcedUsers = await twonlyDB.userDiscoveryDao
        .getNewAnnouncementsWithoutData();

    for (final announcedUser in announcedUsers) {
      final FrbUserData? userdata;
      try {
        userdata = await RustApi.getUserById(
          userId: announcedUser.announcedUserId,
        );
      } catch (_) {
        continue;
      }
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

  static bool shouldRequestManualApproval(Contact c) {
    final u = userService.currentUser;
    if (!c.accepted || c.blocked) return false;
    if (!u.isUserDiscoveryEnabled) return false;
    if (c.mediaSendCounter < u.requiredSendImages) return false;
    if (c.userDiscoveryExcluded) return false;
    if (!u.userDiscoveryRequiresManualApproval) return false;
    if (c.userDiscoveryManualApproved == true) return false;
    return true;
  }

  static Future<void> initializeOrUpdate({
    required int threshold,
    required bool sharePromotion,
  }) async {
    await UserService.update(
      (u) => u
        ..isUserDiscoveryEnabled = true
        ..userDiscoverySharePromotion = sharePromotion
        ..userDiscoveryThreshold = threshold
        ..userDiscoveryInitializationError = false,
    );
    Log.info('UserDiscoveryService: initializeOrUpdate finished');
  }

  static Future<Uint8List?> getCurrentVersion() async {
    try {
      return await FlutterUserDiscovery.getCurrentVersion(
        callbackId: isolateCallbackId,
      ).timeout(const Duration(seconds: 5));
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

  static UserDiscoveryVersion? getContactVersionTypedFromContact(
    Contact contact,
  ) {
    if (contact.userDiscoveryVersion == null) return null;
    return UserDiscoveryVersion.fromBuffer(contact.userDiscoveryVersion!);
  }

  static Future<void> changeExclusionForContact(
    int contactId,
    bool exclude,
  ) async {
    await FlutterUserDiscovery.changeExclusionForContact(
      callbackId: isolateCallbackId,
      contactId: contactId,
      exclude: exclude,
    );
  }

  static Future<void> disable() async {
    await UserService.update((u) {
      u.isUserDiscoveryEnabled = false;
    });
  }
}
