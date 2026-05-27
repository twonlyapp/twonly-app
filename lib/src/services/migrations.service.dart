import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/secure_storage.keys.dart';
import 'package:twonly/src/database/signal/signal_signed_pre_key_store.dart'
    show getSignalSignedPreKeyStoreOld;
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/signal_identity.model.dart';
import 'package:twonly/src/services/api/mediafiles/download.api.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/secure_storage.dart';
import 'package:twonly/src/visual/views/onboarding/setup.view.dart';

Future<void> runMigrations() async {
  if (userService.currentUser.appVersion < 90) {
    // BUG: Requested media files for reupload where not reuploaded because the wrong state...
    await twonlyDB.mediaFilesDao.updateAllRetransmissionUploadingState();
    await UserService.update((u) => u.appVersion = 90);
  }

  if (userService.currentUser.appVersion < 91) {
    // BUG: Requested media files for reupload where not reuploaded because the wrong state...
    await makeMigrationToVersion91();
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
    var migrationSuccess = true;
    final signalIdentity = await SecureStorage.instance.read(
      // ignore: deprecated_member_use_from_same_package
      key: SecureStorageKeys.signalIdentity,
    );

    if (signalIdentity != null) {
      try {
        final decoded = jsonDecode(signalIdentity);
        final identity = SignalIdentity.fromJson(
          decoded as Map<String, dynamic>,
        );

        await RustKeyManager.importSignalIdentity(
          identityKeyPairStructure: identity.identityKeyPairU8List,
          registrationId: identity.registrationId,
          signedPreKeyStore: await getSignalSignedPreKeyStoreOld(),
        );
        Log.info('Importing signal identify to the rust key manager');

        // Clean up old keys after successful migration
        await SecureStorage.instance.delete(
          // ignore: deprecated_member_use_from_same_package
          key: SecureStorageKeys.signalIdentity,
        );
        await SecureStorage.instance.delete(
          // ignore: deprecated_member_use_from_same_package
          key: SecureStorageKeys.signalSignedPreKey,
        );
      } catch (e) {
        Log.error('Failed to migrate signal identity: $e');
        migrationSuccess = false;
      }
    }

    if (migrationSuccess) {
      await UserService.update((u) {
        u
          ..appVersion = 113
          ..canUseLoginTokenForAuth = false
          // As usernames changes where not considered in the old version force users
          // to reenter there passwords.
          // ignore: deprecated_member_use_from_same_package
          ..twonlySafeBackup?.encryptionKey = []
          // ignore: deprecated_member_use_from_same_package
          ..twonlySafeBackup?.backupId = [];
      });
    }
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
    var migrationSuccess = true;
    try {
      final rustStore = await RustKeyManager.loadSignedPrekeys();
      for (final entry in rustStore.entries) {
        final companion = SignalSignedPreKeyStoresCompanion(
          signedPreKeyId: Value(entry.key),
          signedPreKey: Value(entry.value),
        );
        await twonlyDB
            .into(twonlyDB.signalSignedPreKeyStores)
            .insert(
              companion,
              mode: InsertMode.insertOrReplace,
            );
        await RustKeyManager.removeSignedPrekey(signedPreKeyId: entry.key);
      }
    } catch (e) {
      Log.error('Failed to migrate signed prekeys to Drift: $e');
      migrationSuccess = false;
    }
    if (migrationSuccess) {
      await UserService.update((u) => u.appVersion = 115);
    }
  }

  if (kDebugMode) {
    assert(
      AppState.latestAppVersionId == 116,
      'Forgot to update the target version in runMigrations() after incrementing AppState.latestAppVersionId.',
    );
    assert(
      AppState.latestAppVersionId == userService.currentUser.appVersion,
      "Migration incomplete: currentUser.appVersion (${userService.currentUser.appVersion}) does not match AppState.latestAppVersionId (${AppState.latestAppVersionId}). Ensure the user's appVersion is updated in the migration block.",
    );
  }
}
