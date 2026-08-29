import 'package:twonly/core/bridge/callbacks.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/callbacks/logging.callbacks.dart';
import 'package:twonly/src/services/api/mediafiles/upload.api.dart';
import 'package:twonly/src/services/flame.service.dart';
import 'package:twonly/src/services/key_verification.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/avatars.dart';

Future<void> _apiMediaAction(
  String kind,
  String mediaId,
  int contactId,
  String messageId,
) async {
  final media = await twonlyDB.mediaFilesDao.getMediaFileById(mediaId);
  if (media == null) return;
  switch (kind) {
    case 'stored':
      await MediaFileService(media).storeMediaFile();
    case 'reupload':
      await reuploadMediaFile(contactId, media, messageId);
  }
}

Future<void> initFlutterCallbacksForRust() async {
  await initFlutterCallbacks(
    callbackId: isolateCallbackId,
    loggingGetStreamSink: LoggingCallbacks.getStreamSink,
    apiMediaAction: _apiMediaAction,
    apiVerificationProof: KeyVerificationService.handleVerificationProof,
    apiCreatePushAvatars: (contactId) =>
        createPushAvatars(forceForUserId: contactId),
    apiMediaReceived: (groupId, timestamp) => incFlameCounter(
      groupId,
      true,
      DateTime.fromMillisecondsSinceEpoch(timestamp),
    ),
    apiUserConfigChanged: UserService.handleRustUserConfigChanged,
  );
}
