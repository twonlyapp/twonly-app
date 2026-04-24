import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/utils/secure_storage.dart';

Future<bool> deleteLocalUserData() async {
  final appDir = await getApplicationSupportDirectory();
  if (appDir.existsSync()) {
    appDir.deleteSync(recursive: true);
  }
  await SecureStorage.instance.deleteAll();
  return true;
}
