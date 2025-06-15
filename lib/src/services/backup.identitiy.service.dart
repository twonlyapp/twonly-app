import 'package:twonly/src/utils/storage.dart';

Future<bool> isIdentityBackupEnabled() async {
  final user = await getUser();
  if (user == null) return false;
  return user.identityBackupEnabled;
}

Future<DateTime?> getLastIdentityBackup() async {
  final user = await getUser();
  if (user == null) return null;
  return user.identityBackupLastBackupTime;
}

Future enableIdentityBackup() async {
  await updateUserdata((user) {
    user.identityBackupEnabled = false;
    return user;
  });
}
