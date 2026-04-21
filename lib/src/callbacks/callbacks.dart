import 'package:twonly/core/bridge/callbacks.dart';
import 'package:twonly/src/callbacks/logging.callbacks.dart';
import 'package:twonly/src/callbacks/user_discovery.callbacks.dart';

Future<void> initFlutterCallbacksForRust() async {
  await initFlutterCallbacks(
    loggingGetStreamSink: LoggingCallbacks.getStreamSink,
    userDiscoverySetShares: UserDiscoveryCallbacks.setShares,
    userDiscoveryGetShareForContact:
        UserDiscoveryCallbacks.userDiscoveryGetShareForContact,
    userDiscoveryPushOwnPromotionAndClearOldVersion:
        UserDiscoveryCallbacks.userDiscoveryPushOwnPromotionAndClearOldVersion,
    userDiscoveryPushNewUserRelation:
        UserDiscoveryCallbacks.pushNewUserRelation,
    userDiscoveryGetOwnPromotionsAfterVersion:
        UserDiscoveryCallbacks.getOwnPromotionsAfterVersion,
    userDiscoveryStoreOtherPromotion:
        UserDiscoveryCallbacks.storeOtherPromotion,
    userDiscoveryGetOtherPromotionsByPublicId:
        UserDiscoveryCallbacks.getOtherPromotionsByPublicId,
    userDiscoveryGetAnnouncedUserByPublicId:
        UserDiscoveryCallbacks.getAnnouncedUserByPublicId,
    userDiscoveryGetContactVersion: UserDiscoveryCallbacks.getContactVersion,
    userDiscoverySetContactVersion: UserDiscoveryCallbacks.setContactVersion,
    userDiscoverySignData: UserDiscoveryCallbacks.signData,
    userDiscoveryVerifySignature: UserDiscoveryCallbacks.verifySignature,
    userDiscoveryVerifyStoredPubkey: UserDiscoveryCallbacks.verifyStoredPubKey,
  );
}
