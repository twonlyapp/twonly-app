import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';

class ResponseContainer extends StatefulWidget {
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
  State<ResponseContainer> createState() => _ResponseContainerState();
}

class _ResponseContainerState extends State<ResponseContainer> {
  double? minWidth;
  final GlobalKey _message = GlobalKey();
  final GlobalKey _preview = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messageBox =
          _message.currentContext?.findRenderObject() as RenderBox?;
      final previewBox =
          _preview.currentContext?.findRenderObject() as RenderBox?;
      if (messageBox == null || previewBox == null) {
        return;
      }
      setState(() {
        if (messageBox.size.width > previewBox.size.width) {
          minWidth = messageBox.size.width;
        } else {
          minWidth = previewBox.size.width;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.msg.quotesMessageId == null) {
      if (widget.child == null) {
        return Container();
      }
      return widget.child!;
    }
    return GestureDetector(
      onTap: widget.scrollToMessage == null
          ? null
          : () => widget.scrollToMessage!(widget.msg.quotesMessageId!),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: getMessageColor(widget.msg),
          borderRadius: widget.borderRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4, left: 4),
              child: Container(
                key: _preview,
                width: minWidth,
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
                  group: widget.group,
                  messageId: widget.msg.quotesMessageId,
                  showBorder: false,
                ),
              ),
            ),
            SizedBox(
              key: _message,
              width: minWidth,
              child: widget.child,
            ),
          ],
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
    super.key,
  });

  final Message? message;
  final String? messageId;
  final Group group;
  final bool showBorder;

  @override
  State<ResponsePreview> createState() => _ResponsePreviewState();
}

class _ResponsePreviewState extends State<ResponsePreview> {
  Message? _message;
  MediaFileService? _mediaService;
  String _username = '';

  @override
  void initState() {
    _message = widget.message;
    initAsync();
    super.initState();
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
      if (_message!.type == MessageType.text) {
        if (_message!.content != null) {
          subtitle = truncateString(_message!.content!);
        }
      }
      if (_message!.type == MessageType.media && _mediaService != null) {
        subtitle = _mediaService!.mediaFile.type == MediaType.video
            ? context.lang.video
            : context.lang.image;
      }

      if (_message!.senderId == null) {
        _username = context.lang.you;
        // _username = _message!.senderId.toString();
      }

      color = getMessageColor(_message!);

      if (!_message!.mediaStored) {
        return Container(
          padding: widget.showBorder
              ? const EdgeInsets.only(left: 10, right: 10)
              : const EdgeInsets.symmetric(horizontal: 5),
          decoration: (widget.showBorder)
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: color,
                      width: 2,
                    ),
                  ),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (subtitle != null) Text(subtitle),
            ],
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.only(left: 10),
      width: 200,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: color,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (subtitle != null) Text(subtitle),
              ],
            ),
          ),
          if (_mediaService != null)
            SizedBox(
              height: widget.showBorder ? 100 : 210,
              child: Image.file(
                _mediaService!.mediaFile.type == MediaType.video
                    ? _mediaService!.thumbnailPath
                    : _mediaService!.storedPath,
              ),
            ),
        ],
      ),
    );
  }
}
