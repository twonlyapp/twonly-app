import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart'
    show ChatListContact;
import 'package:twonly/src/utils/database_values.dart';

String getContactDisplayName(Contact user, {int? maxLength}) {
  return _displayName(
    user.username,
    user.nickName,
    user.displayName,
    user.accountDeleted,
    maxLength,
  );
}

String getChatListContactDisplayName(ChatListContact user, {int? maxLength}) =>
    _displayName(
      user.username,
      user.nickName,
      user.displayName,
      user.accountDeleted,
      maxLength,
    );

String _displayName(
  String username,
  String? nickName,
  String? displayName,
  bool accountDeleted,
  int? maxLength,
) {
  var name = username;
  if (nickName != null && nickName != '') {
    name = nickName;
  } else if (displayName != null) {
    name = displayName;
  }
  if (accountDeleted) name = applyStrikethrough(name);
  return maxLength == null ? name : substringBy(name, maxLength);
}

String substringBy(String string, int maxLength) {
  if (string.length > maxLength) {
    return '${string.substring(0, maxLength - 3)}...';
  }
  return string;
}

String applyStrikethrough(String text) {
  return text.split('').map((char) => '$char\u0336').join();
}
