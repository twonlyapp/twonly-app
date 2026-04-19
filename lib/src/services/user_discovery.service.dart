import 'package:twonly/core/bridge/wrapper/user_discovery.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/qr.dart';
import 'package:twonly/src/utils/storage.dart';

Future<void> initializeOrUpdateUserDiscovery({
  required int threshold,
  required int minimumRequiredImagesExchanged,
}) async {
  try {
    await FlutterUserDiscovery.initializeOrUpdate(
      threshold: threshold,
      userId: gUser.userId,
      publicKey: await getUserPublicKey(),
    );
    await updateUserdata((u) {
      u
        ..isUserDiscoveryEnabled = true
        ..minimumRequiredImagesExchanged = minimumRequiredImagesExchanged;
      return u;
    });
  } catch (e) {
    Log.error(e);
  }
}
