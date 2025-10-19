
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';

Future<void> handleMedia(int fromUserId, String groupId, EncryptedContent_Media media) async {
TODO
}

Future<void> handleMediaUpdate(int fromUserId, String groupId, EncryptedContent_MediaUpdate mediaUpdate) async {
TODO


  // switch (message.kind) {
  //   case MessageKind.receiveMediaError:
  // if (message.messageReceiverId != null) {
  //   final openedMessage = await twonlyDB.messagesDao
  //       .getMessageByIdAndContactId(fromUserId, message.messageReceiverId!)
  //       .getSingleOrNull();

  //   if (openedMessage != null) {
  //     /// message found

  //     /// checks if
  //     ///   1. this was a media upload
  //     ///   2. the media was not already retransmitted
  //     ///   3. the media was send in the last two days
  //     if (openedMessage.mediaUploadId != null &&
  //         openedMessage.mediaRetransmissionState ==
  //             MediaRetransmitting.none &&
  //         openedMessage.sendAt
  //             .isAfter(DateTime.now().subtract(const Duration(days: 2)))) {
  //       // reset the media upload state to pending,
  //       // this will cause the media to be re-encrypted again
  //       await twonlyDB.mediaUploadsDao.updateMediaUpload(
  //         openedMessage.mediaUploadId!,
  //         const MediaUploadsCompanion(
  //           state: Value(
  //             UploadState.pending,
  //           ),
  //         ),
  //       );
  //       // reset the message upload so the upload will be done again
  //       await twonlyDB.messagesDao.updateMessageByOtherUser(
  //         fromUserId,
  //         message.messageReceiverId!,
  //         const MessagesCompanion(
  //           downloadState: Value(DownloadState.pending),
  //           mediaRetransmissionState:
  //               Value(MediaRetransmitting.retransmitted),
  //         ),
  //       );
  //       unawaited(retryMediaUpload(false));
  //     } else {
  //       await twonlyDB.messagesDao.updateMessageByOtherUser(
  //         fromUserId,
  //         message.messageReceiverId!,
  //         const MessagesCompanion(
  //           errorWhileSending: Value(true),
  //         ),
  //       );
  //     }
  //   }
  // }


 if (message.kind == MessageKind.storedMediaFile) {
    if (message.messageReceiverId != null) {
      /// stored media file just updates the message
      await twonlyDB.messagesDao.updateMessageByOtherUser(
        fromUserId,
        message.messageReceiverId!,
        const MessagesCompanion(
          mediaStored: Value(true),
          errorWhileSending: Value(false),
        ),
      );
      final msg = await twonlyDB.messagesDao
          .getMessageByIdAndContactId(
            fromUserId,
            message.messageReceiverId!,
          )
          .getSingleOrNull();
      if (msg != null && msg.mediaUploadId != null) {
        final filePath = await getMediaFilePath(msg.mediaUploadId, 'send');
        if (filePath.contains('mp4')) {
          unawaited(createThumbnailsForVideo(File(filePath)));
        } else {
          unawaited(createThumbnailsForImage(File(filePath)));
        }
      }
    }
  } else if (message.content != null) {}
}
