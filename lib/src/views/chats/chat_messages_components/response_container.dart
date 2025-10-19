import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/message_old.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';

class ResponseContainer extends StatefulWidget {
  const ResponseContainer({
    required this.msg,
    required this.contact,
    required this.child,
    required this.scrollToMessage,
    super.key,
  });

  final ChatMessage msg;
  final Widget child;
  final Contact contact;
  final void Function(int) scrollToMessage;

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
    if (widget.msg.responseTo == null) {
      return widget.child;
    }
    return GestureDetector(
      onTap: () => widget.scrollToMessage(widget.msg.responseTo!.messageId),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: getMessageColor(widget.msg.message),
          borderRadius: BorderRadius.circular(12),
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
                  contact: widget.contact,
                  message: widget.msg.responseTo!,
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
    required this.message,
    required this.contact,
    required this.showBorder,
    super.key,
  });

  final Message message;
  final Contact contact;
  final bool showBorder;

  @override
  State<ResponsePreview> createState() => _ResponsePreviewState();
}

class _ResponsePreviewState extends State<ResponsePreview> {
  File? thumbnailPath;

  @override
  void initState() {
    super.initState();
    unawaited(initAsync());
  }

  Future<void> initAsync() async {
    final items = await MemoryItem.convertFromMessages([widget.message]);
    if (items.length == 1 && mounted) {
      setState(() {
        thumbnailPath = items.values.first.thumbnailPath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String? subtitle;

    if (widget.message.kind == MessageKind.textMessage) {
      if (widget.message.contentJson != null) {
        final content = MessageContent.fromJson(
          MessageKind.textMessage,
          jsonDecode(widget.message.contentJson!) as Map,
        );
        if (content is TextMessageContent) {
          subtitle = truncateString(content.text);
        }
      }
    }
    if (widget.message.kind == MessageKind.media) {
      final content = MessageContent.fromJson(
        MessageKind.media,
        jsonDecode(widget.message.contentJson!) as Map,
      );
      if (content is MediaMessageContent) {
        subtitle = content.isVideo ? 'Video' : 'Image';
      }
    }

    var username = 'You';
    if (widget.message.messageOtherId != null) {
      username = getContactDisplayName(widget.contact);
    }

    final color = getMessageColor(widget.message);

    if (!widget.message.mediaStored) {
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
              username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) Text(subtitle),
          ],
        ),
      );
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
                  username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (subtitle != null) Text(subtitle),
              ],
            ),
          ),
          if (thumbnailPath != null)
            SizedBox(
              height: widget.showBorder ? 100 : 210,
              child: Image.file(thumbnailPath!),
            ),
        ],
      ),
    );
  }
}
