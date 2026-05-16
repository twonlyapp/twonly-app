import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/friendly_message_time.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/message_send_state_icon.dart';
import 'package:twonly/src/visual/views/memories/components/memory_thumbnail.comp.dart';
import 'package:twonly/src/visual/views/memories/synchronized_viewer.view.dart';

class InChatMediaViewer extends StatefulWidget {
  const InChatMediaViewer({
    required this.message,
    required this.group,
    required this.mediaService,
    required this.color,
    required this.galleryItems,
    required this.canBeReopened,
    required this.borderRadius,
    required this.info,
    super.key,
  });

  final Message message;
  final Group group;
  final MediaFileService mediaService;
  final List<MemoryItem> galleryItems;
  final Color color;
  final bool canBeReopened;
  final BorderRadius borderRadius;
  final BubbleInfo info;

  @override
  State<InChatMediaViewer> createState() => _InChatMediaViewerState();
}

class _InChatMediaViewerState extends State<InChatMediaViewer> {
  bool mirrorVideo = false;
  int? galleryItemIndex;
  StreamSubscription<Message?>? messageStream;
  Timer? _timer;
  late final ValueNotifier<String?> _activeMediaIdNotifier = ValueNotifier(
    widget.message.mediaId,
  );

  @override
  void initState() {
    super.initState();
    unawaited(loadIndexAsync());
    unawaited(initStream());
  }

  @override
  void didUpdateWidget(InChatMediaViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.mediaStored != oldWidget.message.mediaStored ||
        widget.galleryItems != oldWidget.galleryItems) {
      if (widget.message.mediaStored) {
        unawaited(loadIndexAsync());
      }
    }
  }

  Future<void> loadIndexAsync() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      /// when the galleryItems are updated this widget is not reloaded
      /// so using this timer as a workaround
      if (loadIndex()) {
        timer.cancel();
        if (mounted) setState(() {});
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
    messageStream?.cancel();
    _timer?.cancel();
    _activeMediaIdNotifier.dispose();
    super.dispose();
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
    _activeMediaIdNotifier.value = widget.message.mediaId;

    await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) {
          return SynchronizedImageViewerScreen(
            galleryItems: widget.galleryItems,
            initialIndex: galleryItemIndex!,
            activeMediaIdNotifier: _activeMediaIdNotifier,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
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
          color: widget.info.color.withValues(alpha: 0.3),
          border: Border.all(
            color: widget.info.color.withValues(alpha: 0.4),
          ),
          borderRadius: widget.borderRadius,
        ),
        child: Padding(
          padding: widget.info.padding,
          child: Row(
            children: [
              MessageSendStateIcon(
                [widget.message],
                [widget.mediaService.mediaFile],
                mainAxisAlignment: widget.message.senderId == null
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                canBeReopened: widget.canBeReopened,
              ),
              if (widget.info.displayTime || widget.message.modifiedAt != null)
                FriendlyMessageTime(
                  message: widget.message,
                  color: isDarkMode(context)
                      ? Colors.white.withAlpha(100)
                      : Colors.black.withAlpha(100),
                ),
            ],
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
        borderRadius: widget.borderRadius,
      ),
      child: galleryItemIndex != null
          ? MemoriesThumbnailComp(
              galleryItem: widget.galleryItems[galleryItemIndex!],
              onTap: onTap,
              activeMediaIdNotifier: _activeMediaIdNotifier,
            )
          : null,
    );
  }
}
