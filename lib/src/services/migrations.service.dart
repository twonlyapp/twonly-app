import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:intl/intl.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/key_verifications.dart'
    as rust_key_verifications;
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/core/database/app/mediafiles/table.dart'
    as db_mediafiles;
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/contact_enums.dart';
import 'package:twonly/src/services/passwordless_recovery.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/services/user_discovery.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
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
    final contacts = await rust_contacts.listContacts(
      input: db_contacts.ContactQuery(
        filter: db_contacts.ContactFilter.all,
        ids: Int64List(0),
      ),
      transaction: currentDatabaseSession(),
    );
    for (final contact in contacts) {
      if (contact.verified) {
        await rust_key_verifications.changeKeyVerification(
          contact: contact.userId,
          kind: VerificationType.migratedFromOldVersion.name,
          updateDiscovery: userService.currentUser.isUserDiscoveryEnabled,
          verifiedAt: clock.now().millisecondsSinceEpoch,
          callbackId: isolateCallbackId,
          transaction: currentDatabaseSession(),
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
    final dates =
        (await rust_mediafiles.missingMediaMonthDates(
              transaction: currentDatabaseSession(),
            ))
            .map(
              (seconds) =>
                  DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000),
            )
            .toList();
    await rust_mediafiles.fillMediaMonths(
      labels: [
        for (final entry in {
          for (final date in dates) date: DateFormat('MMMM yyyy').format(date),
        }.entries)
          db_mediafiles.MediaMonthLabel(
            createdAt: entry.key.millisecondsSinceEpoch ~/ 1000,
            month: entry.value,
          ),
      ],
      transaction: currentDatabaseSession(),
    );
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
    final contacts = await rust_contacts.listContacts(
      input: db_contacts.ContactQuery(
        filter: db_contacts.ContactFilter.all,
        ids: Int64List(0),
      ),
      transaction: currentDatabaseSession(),
    );
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
