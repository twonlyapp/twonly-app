import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/utils/misc.dart';

Future initMediaStorage() async {
  final storage = getSecureStorage();
  var containsEncryptionKey =
      await storage.containsKey(key: 'hive_encryption_key');
  if (!containsEncryptionKey) {
    var key = Hive.generateSecureKey();
    await storage.write(
      key: 'hive_encryption_key',
      value: base64UrlEncode(key),
    );
  }
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
}

Future<Box> getMediaStorage() async {
  try {
    await initMediaStorage();
    final storage = getSecureStorage();

    var encryptionKey =
        base64Url.decode((await storage.read(key: 'hive_encryption_key'))!);

    return await Hive.openBox(
      'media_storage',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  } catch (e) {
    await customLocalPushNotification("Secure Storage Error",
        "Settings > Apps > twonly > Storage and Cache > Press clear on both");
    Logger("hive.dart").shout(e);
    throw Exception(e);
  }
}
