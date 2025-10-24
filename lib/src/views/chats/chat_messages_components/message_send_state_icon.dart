import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/animate_icon.dart';

enum MessageSendState {
  received,
  receivedOpened,
  receiving,
  send,
  sendOpened,
  sending,
}

Future<MessageSendState> messageSendStateFromMessage(Message msg) async {
  MessageSendState state;

  final ackByServer = await twonlyDB.messagesDao.haveAllMembers(
    msg.groupId,
    msg.messageId,
    MessageActionType.ackByServerAt,
  );

  if (!ackByServer) {
    if (msg.senderId == null) {
      state = MessageSendState.sending;
    } else {
      state = MessageSendState.receiving;
    }
  } else {
    if (msg.senderId == null) {
      // message send
      if (msg.openedAt == null) {
        state = MessageSendState.send;
      } else {
        state = MessageSendState.sendOpened;
      }
    } else {
      // message received
      if (msg.openedAt == null) {
        state = MessageSendState.received;
      } else {
        state = MessageSendState.receivedOpened;
      }
    }
  }
  return state;
}

class MessageSendStateIcon extends StatefulWidget {
  const MessageSendStateIcon(
    this.messages, {
    super.key,
    this.canBeReopened = false,
    this.mainAxisAlignment = MainAxisAlignment.end,
  });
  final List<Message> messages;
  final MainAxisAlignment mainAxisAlignment;
  final bool canBeReopened;

  @override
  State<MessageSendStateIcon> createState() => _MessageSendStateIconState();
}

class _MessageSendStateIconState extends State<MessageSendStateIcon> {
  List<Widget> icons = <Widget>[];
  String text = '';
  Widget? textWidget;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    final kindsAlreadyShown = HashSet<MessageType>();

    for (final message in widget.messages) {
      if (icons.length == 2) break;
      if (kindsAlreadyShown.contains(message.type)) continue;
      kindsAlreadyShown.add(message.type);

      final state = await messageSendStateFromMessage(message);

      final mediaFile = message.mediaId == null
          ? null
          : await MediaFileService.fromMediaId(message.mediaId!);

      if (!mounted) return;

      final color =
          getMessageColorFromType(message, mediaFile?.mediaFile, context);

      Widget icon = const Placeholder();
      textWidget = null;

      switch (state) {
        case MessageSendState.receivedOpened:
          icon = Icon(Icons.crop_square, size: 14, color: color);
          if (message.content != null) {
            if (isEmoji(message.content!)) {
              icon = Text(
                message.content!,
                style: const TextStyle(fontSize: 12),
              );
            }
          }
          text = context.lang.messageSendState_Received;
          if (widget.canBeReopened) {
            textWidget = Text(
              context.lang.doubleClickToReopen,
              style: const TextStyle(fontSize: 9),
            );
          }
        case MessageSendState.sendOpened:
          icon = FaIcon(FontAwesomeIcons.paperPlane, size: 12, color: color);
          text = context.lang.messageSendState_Opened;
        case MessageSendState.received:
          icon = Icon(Icons.square_rounded, size: 14, color: color);
          text = context.lang.messageSendState_Received;
          if (message.type == MessageType.media) {
            if (mediaFile!.mediaFile.downloadState == DownloadState.pending) {
              text = context.lang.messageSendState_TapToLoad;
            }
            if (mediaFile.mediaFile.downloadState ==
                DownloadState.downloading) {
              text = context.lang.messageSendState_Loading;
              icon = getLoaderIcon(color);
            }
          }
        case MessageSendState.send:
          icon =
              FaIcon(FontAwesomeIcons.solidPaperPlane, size: 12, color: color);
          text = context.lang.messageSendState_Send;
        case MessageSendState.sending:
          icon = getLoaderIcon(color);
          text = context.lang.messageSendState_Sending;
        case MessageSendState.receiving:
          icon = getLoaderIcon(color);
          text = context.lang.messageSendState_Received;
      }

      if (message.mediaStored) {
        icon = FaIcon(FontAwesomeIcons.floppyDisk, size: 12, color: color);
        text = context.lang.messageStoredInGallery;
      }

      if (mediaFile != null) {
        if (mediaFile.mediaFile.stored) {
          icon = FaIcon(FontAwesomeIcons.repeat, size: 12, color: color);
          text = context.lang.messageReopened;
        }

        if (mediaFile.mediaFile.reuploadRequestedBy != null) {
          icon =
              FaIcon(FontAwesomeIcons.clockRotateLeft, size: 12, color: color);
          textWidget = Text(
            context.lang.retransmissionRequested,
            style: const TextStyle(fontSize: 9),
          );
        }
      }

      if (message.type == MessageType.media) {
        icons.insert(0, icon);
      } else {
        icons.add(icon);
      }
    }

    setState(() {});
  }

  Widget getLoaderIcon(Color color) {
    return Row(
      children: [
        SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 1, color: color),
        ),
        const SizedBox(width: 2),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (icons.isEmpty) return Container();

    var icon = icons[0];

    if (icons.length == 2) {
      icon = Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // First icon (bottom icon)
          icons[0],

          Transform(
            transform: Matrix4.identity()
              ..scaleByDouble(0.7, 0.7, 0.7, 0.7) // Scale to half
              ..translateByDouble(3, 5, 0, 1),
            // Move down by 10 pixels (adjust as needed)
            alignment: Alignment.center,
            child: icons[1],
          ),
          // Second icon (top icon, slightly offset)
        ],
      );
    }

    return Row(
      mainAxisAlignment: widget.mainAxisAlignment,
      children: [
        icon,
        const SizedBox(width: 3),
        if (textWidget != null)
          textWidget!
        else
          Text(
            text,
            style: const TextStyle(fontSize: 12),
          ),
        const SizedBox(width: 5),
      ],
    );
  }
}
