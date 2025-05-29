import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/providers/api/media_send.dart' as send;
import 'package:twonly/src/views/camera/camera_send_to_view.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/components/media_view_sizing.dart';
import 'package:twonly/src/views/components/message_send_state_icon.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/providers/api/media_received.dart' as received;
import 'package:twonly/src/views/gallery/gallery_main_view.dart';
import 'package:video_player/video_player.dart';

// class ChatMediaViewerFullScreen extends StatefulWidget {
//   const ChatMediaViewerFullScreen({
//     super.key,
//     required this.message,
//     required this.contact,
//     required this.color,
//   });
//   final Message message;
//   final Contact contact;
//   final Color color;

//   @override
//   State<ChatMediaViewerFullScreen> createState() =>
//       _ChatMediaViewerFullScreenState();
// }

// class _ChatMediaViewerFullScreenState extends State<ChatMediaViewerFullScreen> {
//   bool hideMediaFile = false;

//   Future deleteFiles(context) async {
//     bool confirmed = await showAlertDialog(
//         context, "Are you sure?", "The image will be irrevocably deleted.");

//     if (!confirmed) return;

//     await twonlyDatabase.messagesDao.updateMessageByMessageId(
//       widget.message.messageId,
//       MessagesCompanion(mediaStored: Value(false)),
//     );
//     await send.purgeSendMediaFiles();
//     await received.purgeReceivedMediaFiles();
//     if (context.mounted) {
//       Navigator.pop(context, true);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: MediaViewSizing(
//           bottomNavigation: Positioned(
//             bottom: 10,
//             left: 0,
//             right: 0,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 IconButton.outlined(
//                   onPressed: () {
//                     deleteFiles(context);
//                   },
//                   icon: FaIcon(FontAwesomeIcons.trashCan),
//                   style: ButtonStyle(
//                     padding: WidgetStateProperty.all<EdgeInsets>(
//                       EdgeInsets.symmetric(vertical: 10, horizontal: 20),
//                     ),
//                   ),
//                 ),
//                 IconButton.filled(
//                   icon: FaIcon(FontAwesomeIcons.camera),
//                   onPressed: () async {
//                     setState(() {
//                       hideMediaFile = true;
//                     });
//                     await Navigator.push(context, MaterialPageRoute(
//                       builder: (context) {
//                         return CameraSendToView(widget.contact);
//                       },
//                     ));
//                     setState(() {
//                       hideMediaFile = false;
//                     });
//                   },
//                   style: ButtonStyle(
//                       padding: WidgetStateProperty.all<EdgeInsets>(
//                         EdgeInsets.symmetric(vertical: 10, horizontal: 30),
//                       ),
//                       backgroundColor: WidgetStateProperty.all<Color>(
//                         Theme.of(context).colorScheme.primary,
//                       )),
//                 ),
//               ],
//             ),
//           ),
//           child: (hideMediaFile)
//               ? Container()
//               : Hero(
//                   tag: "chat_entry_${widget.message.messageId}",
//                   child: InChatMediaViewer(
//                     message: widget.message,
//                     contact: widget.contact,
//                     color: widget.color,
//                     isInFullscreen: true,
//                   ),
//                 )),
//     );
//   }
// }

class InChatMediaViewer extends StatefulWidget {
  const InChatMediaViewer({
    super.key,
    required this.message,
    required this.contact,
    required this.color,
    required this.galleryItems,
  });

  final Message message;
  final Contact contact;
  final List<GalleryItem> galleryItems;
  final Color color;

  @override
  State<InChatMediaViewer> createState() => _InChatMediaViewerState();
}

class _InChatMediaViewerState extends State<InChatMediaViewer> {
  File? image;
  File? video;
  bool isMounted = true;
  bool mirrorVideo = false;
  VideoPlayerController? videoController;
  StreamSubscription<Message?>? messageStream;

  @override
  void initState() {
    super.initState();
    initAsync(widget.message);
    initStream();
  }

  @override
  void dispose() {
    super.dispose();
    isMounted = false;
    messageStream?.cancel();
    videoController?.dispose();
  }

  Future initStream() async {
    /// When the image is opened from the chat and then stored the
    /// image is not loaded so this will trigger an initAsync when mediaStored is changed

    /// image is already show
    if (widget.message.mediaStored) return;

    final stream = twonlyDatabase.messagesDao
        .getMessageByMessageId(widget.message.messageId)
        .watchSingleOrNull();
    messageStream = stream.listen((updated) async {
      if (updated != null) {
        if (updated.mediaStored) {
          messageStream?.cancel();
          initAsync(updated);
        }
      }
    });
  }

  Future initAsync(Message message) async {
    if (!message.mediaStored) return;
    bool isSend = message.messageOtherId == null;
    final basePath = await send.getMediaFilePath(
      isSend ? message.mediaUploadId! : message.messageId,
      isSend ? "send" : "received",
    );
    if (!isMounted) return;
    final videoPath = File("$basePath.mp4");
    final imagePath = File("$basePath.png");
    if (videoPath.existsSync() && message.contentJson != null) {
      MessageContent? content = MessageContent.fromJson(
          MessageKind.media, jsonDecode(message.contentJson!));
      if (content is MediaMessageContent) {
        mirrorVideo = content.mirrorVideo;
      }
      videoController = VideoPlayerController.file(
        videoPath,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      videoController?.initialize().then((_) {
        videoController!.setVolume(0);
        videoController!.play();
        videoController!.setLooping(true);
      });

      setState(() {
        image = imagePath;
      });
    }
    if (imagePath.existsSync()) {
      setState(() {
        image = imagePath;
      });
    } else {
      print("Not found: $imagePath");
    }
  }

  Future onTap() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryPhotoViewWrapper(
          galleryItems: widget.galleryItems,
          // backgroundDecoration: const BoxDecoration(
          //   color: Colors.black,
          // ),
          initialIndex: widget.galleryItems.indexWhere((x) =>
              x.id ==
              (widget.message.mediaUploadId ?? widget.message.messageId)
                  .toString()),
          scrollDirection: Axis.horizontal,
        ),
      ),
    );
    // bool? removed = await Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) {
    //     return ChatMediaViewerFullScreen(
    //       message: widget.message,
    //       contact: widget.contact,
    //       color: widget.color,
    //     );
    //   }),
    // );

    // if (removed != null && removed) {
    //   image = null;
    //   videoController?.dispose();
    //   videoController = null;
    //   if (isMounted) setState(() {});
    // }
  }

  @override
  Widget build(BuildContext context) {
    if (image == null && video == null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.color,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: MessageSendStateIcon(
            [widget.message],
            mainAxisAlignment: MainAxisAlignment.center,
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.transparent,
          width: 1.0,
        ),
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: GestureDetector(
        onTap: ((image == null && videoController == null)) ? null : onTap,
        child: Stack(
          children: [
            if (image != null) Image.file(image!),
            if (videoController != null)
              Positioned.fill(
                child: Transform.flip(
                  flipX: mirrorVideo,
                  child: VideoPlayer(videoController!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
