import 'dart:async';
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/views/chats/chat_messages_components/message_send_state_icon.dart';
import 'package:twonly/src/views/memories/memories_item_thumbnail.dart';
import 'package:twonly/src/views/memories/memories_photo_slider.view.dart';

class InChatMediaViewer extends StatefulWidget {
  const InChatMediaViewer({
    required this.message,
    required this.group,
    required this.mediaService,
    required this.color,
    required this.galleryItems,
    required this.canBeReopened,
    super.key,
  });

  final Message message;
  final Group group;
  final MediaFileService mediaService;
  final List<MemoryItem> galleryItems;
  final Color color;
  final bool canBeReopened;

  @override
  State<InChatMediaViewer> createState() => _InChatMediaViewerState();
}

class _InChatMediaViewerState extends State<InChatMediaViewer> {
  bool mirrorVideo = false;
  int? galleryItemIndex;
  StreamSubscription<Message?>? messageStream;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(loadIndexAsync());
    unawaited(initStream());
  }

  Future<void> loadIndexAsync() async {
    if (!widget.message.mediaStored) return;
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      /// when the galleryItems are updated this widget is not reloaded
      /// so using this timer as a workaround
      if (loadIndex()) {
        timer.cancel();
        setState(() {});
      }
    });
  }

  bool loadIndex() {
    if (widget.message.mediaStored) {
      final index = widget.galleryItems.indexWhere(
        (x) => x.mediaService.mediaFile.mediaId == (widget.message.mediaId),
      );
      if (index != -1) {
        galleryItemIndex = index;
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    super.dispose();
    messageStream?.cancel();
    _timer?.cancel();
    // videoController?.dispose();
  }

  Future<void> initStream() async {
    /// When the image is opened from the chat and then stored the
    /// image is not loaded so this will trigger an initAsync when mediaStored is changed

    /// image is already show
    if (widget.message.mediaStored) return;

    final stream = twonlyDB.messagesDao
        .getMessageById(widget.message.messageId)
        .watchSingleOrNull();
    messageStream = stream.listen((updated) async {
      if (updated != null) {
        if (updated.mediaStored) {
          await messageStream?.cancel();
          await loadIndexAsync();
        }
      }
    });
  }

  Future<void> onTap() async {
    if (galleryItemIndex == null) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, a1, a2) => MemoriesPhotoSliderView(
          galleryItems: widget.galleryItems,
          initialIndex: galleryItemIndex!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.message.mediaStored ||
        !widget.mediaService.imagePreviewAvailable) {
      return Container(
        constraints: const BoxConstraints(
          minHeight: 39,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.color,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: (widget.canBeReopened) ? 5 : 10.0,
            horizontal: 4,
          ),
          child: MessageSendStateIcon(
            [widget.message],
            [widget.mediaService.mediaFile],
            mainAxisAlignment: MainAxisAlignment.center,
            canBeReopened: widget.canBeReopened,
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.transparent,
        ),
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: galleryItemIndex != null
          ? MemoriesItemThumbnail(
              galleryItem: widget.galleryItems[galleryItemIndex!],
              onTap: onTap,
            )
          : null,
    );
  }
}
