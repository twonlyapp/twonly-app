import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/chats/chat_messages.view.dart';

class ResponseContainer extends StatelessWidget {
  const ResponseContainer({
    required this.msg,
    required this.group,
    required this.child,
    required this.mediaService,
    required this.borderRadius,
    this.scrollToMessage,
    super.key,
  });

  final Message msg;
  final Widget? child;
  final Group group;
  final MediaFileService? mediaService;
  final BorderRadius borderRadius;
  final void Function(String)? scrollToMessage;

  @override
  Widget build(BuildContext context) {
    if (msg.quotesMessageId == null) {
      if (child == null) {
        return Container();
      }
      return child!;
    }
    return GestureDetector(
      onTap: scrollToMessage == null
          ? null
          : () => scrollToMessage!(msg.quotesMessageId!),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: getMessageColor(msg.senderId != null),
          borderRadius: borderRadius,
        ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4, left: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.color.surface.withAlpha(150),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: ResponsePreview(
                    group: group,
                    messageId: msg.quotesMessageId,
                    showBorder: false,
                    showLeftBorder: false,
                    colorUsername: false,
                  ),
                ),
              ),
              if (child != null) child!,
            ],
          ),
        ),
      ),
    );
  }
}

class ResponsePreview extends StatefulWidget {
  const ResponsePreview({
    required this.group,
    required this.showBorder,
    this.message,
    this.messageId,
    this.showLeftBorder = true,
    this.colorUsername = false,
    super.key,
  });

  final Message? message;
  final String? messageId;
  final Group group;
  final bool showBorder;
  final bool showLeftBorder;
  final bool colorUsername;

  @override
  State<ResponsePreview> createState() => _ResponsePreviewState();
}

class _ResponsePreviewState extends State<ResponsePreview> {
  Message? _message;
  MediaFileService? _mediaService;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _message = widget.message;
    initAsync();
  }

  Future<void> initAsync() async {
    _message ??= await twonlyDB.messagesDao
        .getMessageById(widget.messageId!)
        .getSingleOrNull();
    if (_message?.mediaId != null) {
      _mediaService = await MediaFileService.fromMediaId(_message!.mediaId!);
    }
    if (_message?.senderId != null) {
      final contact = await twonlyDB.contactsDao
          .getContactByUserId(_message!.senderId!)
          .getSingleOrNull();
      if (contact != null) {
        _username = getContactDisplayName(contact);
      }
    }
    if (_message == null && mounted) {
      _username = context.lang.quotedMessageWasDeleted;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    String? subtitle;
    var color = const Color.fromARGB(233, 68, 137, 255);

    if (_message != null) {
      if (_message!.type == MessageType.text.name) {
        if (_message!.content != null) {
          subtitle = truncateString(_message!.content!);
        }
      }
      if (_message!.type == MessageType.media.name && _mediaService != null) {
        switch (_mediaService!.mediaFile.type) {
          case MediaType.image:
            subtitle = context.lang.image;
          case MediaType.video:
            subtitle = context.lang.video;
          case MediaType.gif:
            subtitle = 'Gif';
          case MediaType.audio:
            subtitle = 'Audio';
        }
      }
      if (_message!.type == MessageType.contacts.name) {
        subtitle = context.lang.contacts;
      }
      if (_message!.type == MessageType.restoreFlameCounter.name) {
        if (_message!.additionalMessageData != null) {
          try {
            final data = AdditionalMessageData.fromBuffer(
              _message!.additionalMessageData!,
            );
            subtitle = context.lang.chatEntryFlameRestored(
              data.restoredFlameCounter.toInt(),
            );
          } catch (e) {
            subtitle = context.lang.replyFlameRestored;
          }
        } else {
          subtitle = context.lang.replyFlameRestored;
        }
      }
      if (_message!.type == MessageType.askAboutUser.name) {
        subtitle = context.lang.replyAskAFriend;
      }

      if (_message!.senderId == null) {
        _username = context.lang.you;
      }

      color = getMessageColor(_message!.senderId != null);
    }

    final hasImage =
        _message != null &&
        _message!.mediaStored &&
        _mediaService != null &&
        _mediaService!.mediaFile.type != MediaType.audio;

    Widget? imageWidget;
    if (hasImage) {
      final isVideo = _mediaService!.mediaFile.type == MediaType.video;
      final pathToCheck = isVideo
          ? _mediaService!.thumbnailPath
          : _mediaService!.storedPath;
      if (pathToCheck.existsSync() && pathToCheck.lengthSync() > 0) {
        imageWidget = Container(
          height: 40,
          width: 40,
          margin: const EdgeInsets.only(left: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              pathToCheck,
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    }

    return Container(
      padding: EdgeInsets.only(
        left: widget.showLeftBorder ? 8 : 4,
        right: 6,
        top: 4,
        bottom: 4,
      ),
      constraints: BoxConstraints(
        minWidth: 60,
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      decoration: widget.showLeftBorder
          ? BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: color,
                  width: 2.5,
                ),
              ),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.colorUsername ? color : null,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (imageWidget != null) imageWidget,
        ],
      ),
    );
  }
}
