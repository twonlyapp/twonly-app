import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

const userStudySurveyKey = 'user_study_survey';

// LEASE DO NOT SPAM OR TRY SENDING DIRECTLY TO THIS URL!
// You're just making my master's thesis more difficult and destroy scientific data. :/
const surveyUrlBase = 'https://survey.twonly.org/upload.php';

Future<void> handleUserStudyUpload() async {
  try {
    final token = appSession.currentUser.userStudyParticipantsToken;
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

    if (appSession.currentUser.lastUserStudyDataUpload != null &&
        isToday(appSession.currentUser.lastUserStudyDataUpload!)) {
      // Only send updates once a day.
      // This enables to see if improvements to actually work.
      return;
    }

    final contacts = await twonlyDB.contactsDao.getAllContacts();

    final dataCollection = {
      'total_contacts': contacts.length,
      'accepted_contacts': contacts.where((c) => c.accepted).length,
      'verified_contacts': contacts.where((c) => c.verified).length,
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
