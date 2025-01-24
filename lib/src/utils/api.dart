import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:twonly/main.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/signal/signal_helper.dart';
import 'package:twonly/src/providers/api_provider.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/model/user_data_json.dart';

Future<bool> addNewContact(String username) async {
  final res = await apiProvider.getUserData(username);

  if (res.isSuccess) {
    if (await SignalHelper.addNewContact(res.value.userdata)) {
      await dbProvider.db!.insert(DbContacts.tableName, {
        DbContacts.columnDisplayName: username,
        DbContacts.columnUserId: res.value.userdata.userId.toInt()
      });
    }
  }
  return res.isSuccess;
}

Future<Result> createNewUser(String username, String inviteCode) async {
  final storage = getSecureStorage();

  await SignalHelper.createIfNotExistsSignalIdentity();

  final res = await apiProvider.register(username, inviteCode);

  if (res.isSuccess) {
    Logger("create_new_user").info("Got user_id ${res.value} from server");
    final userData = UserData(
        userId: res.value.userid, username: username, displayName: username);
    storage.write(key: "user_data", value: jsonEncode(userData));
  }

  return res;
}
