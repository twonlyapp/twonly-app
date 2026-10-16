import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/passwordless_recovery.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/services/user_discovery.service.dart';
import 'package:twonly/src/visual/views/onboarding/setup.view.dart';

Future<void> runMigrations() async {
  if (userService.currentUser.appVersion < 90) {
    // BUG: Requested media files for reupload where not reuploaded because the
    // wrong state. The Rust upload loop now treats `uploading` as resumable and
    // recovers these on its own, so this migration only records the version.
    await UserService.update((u) => u.appVersion = 90);
  }

  if (userService.currentUser.appVersion < 91) {
    // BUG: Requested media files for reupload where not reuploaded because the wrong state...
    await RustApi.retryPendingMediaReuploads();
    await UserService.update((u) => u.appVersion = 91);
  }

  if (userService.currentUser.appVersion < 109) {
    final contacts = await twonlyDB.contactsDao.getAllContacts();
    for (final contact in contacts) {
      if (contact.verified) {
        await twonlyDB.keyVerificationDao.addKeyVerification(
          contact.userId,
          VerificationType.migratedFromOldVersion,
        );
      }
    }
    await UserService.update((u) {
      u
        ..appVersion = 109
        ..skipSetupPages = true;
      if (u.avatarSvg == null) {
        u.currentSetupPage = SetupPages.profile.name;
      } else {
        u.currentSetupPage = SetupPages.shareYourFriends.name;
      }
    });
  }
  if (userService.currentUser.appVersion < 113) {
    await UserService.update((u) {
      u
        ..appVersion = 113
        ..canUseLoginTokenForAuth = false
        // As usernames changes where not considered in the old version force users
        // to reenter there passwords.
        ..twonlySafeBackup?.encryptionKey = Uint8List(0)
        ..twonlySafeBackup?.backupId = Uint8List(0);
    });
  }

  if (userService.currentUser.appVersion < 114) {
    final allMedia = await twonlyDB.mediaFilesDao
        .select(twonlyDB.mediaFiles)
        .get();
    for (final media in allMedia) {
      if (media.createdAtMonth == null) {
        final monthStr = DateFormat('MMMM yyyy').format(media.createdAt);
        await twonlyDB.mediaFilesDao.updateMedia(
          media.mediaId,
          MediaFilesCompanion(createdAtMonth: Value(monthStr)),
        );
      }
    }
    await UserService.update((u) => u.appVersion = 114);
  }

  if (userService.currentUser.appVersion < 115) {
    await UserService.update((u) => u.appVersion = 115);
  }

  if (userService.currentUser.appVersion < 116) {
    if (userService.currentUser.userDiscoveryThreshold == 2) {
      if (userService.currentUser.isUserDiscoveryEnabled) {
        await UserDiscoveryService.initializeOrUpdate(
          threshold: 3,
          sharePromotion: userService.currentUser.userDiscoverySharePromotion,
        );
      } else {
        await UserService.update((u) => u..userDiscoveryThreshold = 3);
      }
    }
    await UserService.update((u) => u.appVersion = 116);
  }

  if (userService.currentUser.appVersion < 117) {
    final contacts = await twonlyDB.contactsDao.getAllContacts();
    final contactCount = contacts.where((c) => c.accepted).length;
    await UserService.update((u) {
      u.appVersion = 117;
      if (contactCount > 5) {
        u.askForFriendPromotions = false;
      }
    });
  }

  if (userService.currentUser.appVersion < 118) {
    await PasswordlessRecoveryService.migratePasswordlessRecovery();
    await UserService.update((u) => u.appVersion = 118);
  }

  if (userService.currentUser.appVersion < 119) {
    await UserService.update((u) => u.appVersion = 119);
  }

  if (kDebugMode) {
    assert(
      AppState.latestAppVersionId == 119,
      'Forgot to update the target version in runMigrations() after incrementing AppState.latestAppVersionId.',
    );
    assert(
      AppState.latestAppVersionId == userService.currentUser.appVersion,
      "Migration incomplete: currentUser.appVersion (${userService.currentUser.appVersion}) does not match AppState.latestAppVersionId (${AppState.latestAppVersionId}). Ensure the user's appVersion is updated in the migration block.",
    );
  }
}
