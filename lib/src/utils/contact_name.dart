import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/src/utils/database_values.dart';

String getContactDisplayName(Contact user, {int? maxLength}) {
  var name = user.username;
  if (user.nickName != null && user.nickName != '') {
    name = user.nickName!;
  } else if (user.displayName != null) {
    name = user.displayName!;
  }
  if (user.accountDeleted) {
    name = applyStrikethrough(name);
  }
  if (maxLength != null) {
    name = substringBy(name, maxLength);
  }
  return name;
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
