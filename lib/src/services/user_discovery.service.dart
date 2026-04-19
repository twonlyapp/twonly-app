import 'dart:typed_data';

import 'package:twonly/core/bridge/wrapper/user_discovery.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/client/generated/user_discovery/types.pb.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/qr.dart';
import 'package:twonly/src/utils/storage.dart';

class UserDiscoveryService {
  static Future<void> initializeOrUpdate({
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

  static Future<Uint8List?> getCurrentVersion() async {
    try {
      return await FlutterUserDiscovery.getCurrentVersion();
    } catch (e) {
      Log.error(e);
      return null;
    }
  }

  static Future<UserDiscoveryVersion?> getCurrentVersionTyped() async {
    final version = await getCurrentVersion();
    if (version == null) return null;
    return UserDiscoveryVersion.fromBuffer(version);
  }

  static Future<void> disable() async {
    await updateUserdata((u) {
      u.isUserDiscoveryEnabled = false;
      return u;
    });
  }
}
