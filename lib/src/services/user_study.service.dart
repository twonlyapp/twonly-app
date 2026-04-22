import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

const userStudySurveyKey = 'user_study_survey';

// PLEASE DO NOT SPAM OR TRY SENDING DIRECTLY TO THIS URL!
// You're just making my master's thesis more difficult and destroy scientific data. :/
const surveyUrlBase = 'https://survey.twonly.org/upload.php';

Future<void> handleUserStudyUpload() async {
  try {
    final token = userService.currentUser.userStudyParticipantsToken;
    if (token == null) return;

    // in case the survey was taken offline try again
    final userStudySurvey = await KeyValueStore.get(userStudySurveyKey);
    if (userStudySurvey != null) {
      final response = await http.post(
        Uri.parse('$surveyUrlBase/create/$token'),
        body: jsonEncode(userStudySurvey),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode != 200) {
        Log.warn(
          'Got different status code for survey upload: ${response.statusCode}',
        );
        return;
      }
      await KeyValueStore.delete(userStudySurveyKey);
    }

    if (userService.currentUser.lastUserStudyDataUpload != null &&
        isToday(userService.currentUser.lastUserStudyDataUpload!)) {
      // Only send updates once a day.
      // This enables to see if improvements to actually work.
      return;
    }

    final contacts = await twonlyDB.contactsDao.getAllContacts();
    final verifications = await twonlyDB.keyVerificationDao
        .getFirstVerificationTypeByContacts();

    final udFriendsShared = await twonlyDB.contactsDao
        .getContactsAnnouncedViaUserDiscovery();

    final udAllAnnouncedUsers = await twonlyDB.userDiscoveryDao
        .getAllAnnouncedUsersWithRelations();

    var udUnknownAnnouncedUsers = 0;

    for (final udUser in udAllAnnouncedUsers.keys) {
      if (!contacts.any((c) => c.userId == udUser.announcedUserId)) {
        udUnknownAnnouncedUsers += 1;
      }
    }

    final dataCollection = {
      'total_contacts': contacts.length,

      'user_discovery_enabled': userService.currentUser.isUserDiscoveryEnabled,
      'user_discovery_minimum_images':
          userService.currentUser.minimumRequiredImagesExchanged,
      'user_discovery_threshold':
          userService.currentUser.userDiscoveryThreshold,

      'user_discovery_count_friends_shared': udFriendsShared.length,

      'user_discovery_count_announced_users': udAllAnnouncedUsers.length,
      'user_discovery_count_unknown_announced_users': udUnknownAnnouncedUsers,

      'accepted_contacts': contacts.where((c) => c.accepted).length,
      'verified_contacts': verifications.length,
      'verified_contacts_via_migrated_from_old_version': verifications.values
          .where((c) => c == VerificationType.migratedFromOldVersion)
          .length,
      'verified_contacts_via_qr_scanned': verifications.values
          .where((c) => c == VerificationType.qrScanned)
          .length,
      'verified_contacts_via_link': verifications.values
          .where((c) => c == VerificationType.link)
          .length,
      'verified_contacts_via_secret_qr_token': verifications.values
          .where((c) => c == VerificationType.secretQrToken)
          .length,
      'verified_contacts_via_contact_shared_by_verified': verifications.values
          .where((c) => c == VerificationType.contactSharedByVerified)
          .length,
    };

    final response = await http.post(
      Uri.parse('$surveyUrlBase/push/$token'),
      body: jsonEncode(dataCollection),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      await updateUser((u) {
        u.lastUserStudyDataUpload = DateTime.now();
      });
    }
    if (response.statusCode == 404) {
      // Token is unknown to the server...
      await updateUser((u) {
        u
          ..lastUserStudyDataUpload = null
          ..userStudyParticipantsToken = null;
      });
    }
  } catch (e) {
    Log.error(e);
  }
}
