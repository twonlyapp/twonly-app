import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:twonly/core/bridge/wrapper/user_discovery.dart';
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/protobuf/client/generated/user_discovery/types.pb.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/log.dart';

class UserDiscoveryService {
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
