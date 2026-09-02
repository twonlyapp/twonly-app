import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/mediafiles/media_download_policy.dart'
    as received;
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/better_text.element.dart';
import 'package:twonly/src/visual/themes/colors.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/in_chat_media_viewer.dart';
import 'package:twonly/src/visual/views/chats/media_viewer.view.dart';

class ChatMediaEntry extends StatefulWidget {
  const ChatMediaEntry({
    required this.message,
    required this.group,
    required this.galleryItems,
    required this.mediaService,
    required this.borderRadius,
    required this.info,
    this.useSharedData = false,
    super.key,
  });

  final Message message;
  final Group group;
  final List<MemoryItem> galleryItems;
  final MediaFileService mediaService;
  final BorderRadius borderRadius;
  final BubbleInfo info;
  final bool useSharedData;

  @override
  State<ChatMediaEntry> createState() => _ChatMediaEntryState();
}

class _ChatMediaEntryState extends State<ChatMediaEntry> {
  GlobalKey reopenMediaFile = GlobalKey();
  bool _canBeReopened = false;

  /// Decoded once per message instead of on every rebuild; the buffer only
  /// changes when the message itself does.
  String? _link;

  @override
  void initState() {
    super.initState();
    _decodeAdditionalData();
    unawaited(initAsync());
  }

  @override
  void didUpdateWidget(ChatMediaEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.additionalMessageData !=
        widget.message.additionalMessageData) {
      _decodeAdditionalData();
    }
  }

  void _decodeAdditionalData() {
    final addData = widget.message.additionalMessageData;
    if (addData == null) {
      _link = null;
      return;
    }
    final data = AdditionalMessageData.fromBuffer(addData);
    _link = data.hasLink() ? data.link : null;
  }

  Future<void> initAsync() async {
    if (widget.message.senderId == null ||
        widget.message.mediaStored ||
        widget.message.isWidgetMedia) {
      return;
    }
    if (widget.mediaService.mediaFile.requiresAuthentication ||
        widget.mediaService.mediaFile.displayLimitInMilliseconds != null) {
      return;
    }
    // Async check keeps media discovery off the UI thread.
    // ignore: avoid_slow_async_io
    if (await widget.mediaService.tempPath.exists() && mounted) {
      setState(() {
        _canBeReopened = true;
      });
    }
  }

  Future<void> onDoubleTap() async {
    if (widget.message.isWidgetMedia ||
        widget.message.openedAt == null ||
        widget.message.mediaStored) {
      return;
    }
    if (widget.mediaService.canBeOpenedAgain &&
        widget.message.senderId != null) {
      await RustApi.sendEncryptedContent(
        contactId: widget.message.senderId!,
        content: EncryptedContent(
          mediaUpdate: EncryptedContent_MediaUpdate(
            type: EncryptedContent_MediaUpdate_Type.REOPENED,
            targetMessageId: widget.message.messageId,
          ),
        ).writeToBuffer(),
        onlySendIfNoReceiptsAreOpen: false,
        onlyReturnEncryptedData: false,
        blocking: true,
      );
      await twonlyDB.messagesDao.updateMessageId(
        widget.message.messageId,
        const MessagesCompanion(openedAt: Value(null)),
      );
    }
  }

  Future<void> onTap() async {
    if (widget.message.isWidgetMedia) return;
    if ((widget.mediaService.mediaFile.downloadState == DownloadState.ready) &&
        widget.message.openedAt == null) {
      if (!mounted) return;
      await context.navPush(
        MediaViewerView(widget.group, initialMessage: widget.message),
      );
    } else if (widget.mediaService.mediaFile.downloadState ==
        DownloadState.pending) {
      await received.startDownloadMedia(widget.mediaService.mediaFile, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getMessageColorFromType(
      widget.message,
      widget.mediaService.mediaFile,
      context,
    );

    var imageBorderRadius = widget.borderRadius;

    Widget additionalMessageData = Container();

    final link = _link;
    if (link != null && widget.message.mediaStored) {
      imageBorderRadius = widget.borderRadius.copyWith(
        bottomLeft: const Radius.circular(5),
        bottomRight: const Radius.circular(5),
      );

      additionalMessageData = Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        padding: widget.info.padding,
        decoration: BoxDecoration(
          color: widget.info.color,
          borderRadius: widget.borderRadius.copyWith(
            topLeft: const Radius.circular(5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BetterText(text: link, textColor: widget.info.textColor),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: widget.message.senderId == null
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          key: reopenMediaFile,
          onDoubleTap: onDoubleTap,
          onTap: (widget.message.type == MessageType.media.name) ? onTap : null,
          child: SizedBox(
            width: (widget.info.minWidth > 150)
                ? widget.info.minWidth
                : (widget.message.mediaStored &&
                      widget.mediaService.imagePreviewAvailable)
                ? 150
                : null,
            height:
                (widget.message.mediaStored &&
                    widget.mediaService.imagePreviewAvailable)
                ? 271
                : null,
            child: Align(
              alignment: Alignment.centerRight,
              child: ClipRRect(
                borderRadius: imageBorderRadius,
                child: InChatMediaViewer(
                  message: widget.message,
                  group: widget.group,
                  mediaService: widget.mediaService,
                  color: color,
                  galleryItems: widget.galleryItems,
                  canBeReopened: _canBeReopened,
                  borderRadius: imageBorderRadius,
                  info: widget.info,
                  useSharedData: widget.useSharedData,
                ),
              ),
            ),
          ),
        ),
        additionalMessageData,
      ],
    );
  }
}
