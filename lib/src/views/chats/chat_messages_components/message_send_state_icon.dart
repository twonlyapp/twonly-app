import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/animate_icon.dart';
import 'package:twonly/src/views/settings/subscription/subscription.view.dart';

enum MessageSendState {
  received,
  receivedOpened,
  receiving,
  send,
  sendOpened,
  sending,
}

MessageSendState messageSendStateFromMessage(Message msg) {
  if (msg.senderId == null) {
    /// messages was send by me, look up if every messages was received by the server...
    if (msg.ackByServer == null) {
      return MessageSendState.sending;
    }
    if (msg.openedAt != null) {
      return MessageSendState.sendOpened;
    } else {
      return MessageSendState.send;
    }
  }

  // message received
  if (msg.openedAt == null) {
    return MessageSendState.received;
  } else {
    return MessageSendState.receivedOpened;
  }
}

class MessageSendStateIcon extends StatefulWidget {
  const MessageSendStateIcon(
    this.messages,
    this.mediaFiles, {
    super.key,
    this.canBeReopened = false,
    this.lastReaction,
    this.mainAxisAlignment = MainAxisAlignment.end,
  });
  final List<Message> messages;
  final List<MediaFile> mediaFiles;
  final Reaction? lastReaction;
  final MainAxisAlignment mainAxisAlignment;
  final bool canBeReopened;

  @override
  State<MessageSendStateIcon> createState() => _MessageSendStateIconState();
}

class _MessageSendStateIconState extends State<MessageSendStateIcon> {
  @override
  void initState() {
    super.initState();
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
    var icons = <Widget>[];
    var text = '';
    Widget? textWidget;
    textWidget = null;
    final kindsAlreadyShown = HashSet<MessageType>();

    var hasLoader = false;
    GestureTapCallback? onTap;

    for (final message in widget.messages) {
      if (icons.length == 2) break;
      if (kindsAlreadyShown.contains(message.type)) continue;
      kindsAlreadyShown.add(message.type);

      final state = messageSendStateFromMessage(message);

      final mediaFile = message.mediaId == null
          ? null
          : widget.mediaFiles
              .firstWhereOrNull((t) => t.mediaId == message.mediaId);

      final color = getMessageColorFromType(message, mediaFile, context);

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
          if (message.type == MessageType.media && mediaFile != null) {
            if (mediaFile.downloadState == DownloadState.pending) {
              text = context.lang.messageSendState_TapToLoad;
            }
            if (mediaFile.downloadState == DownloadState.downloading) {
              text = context.lang.messageSendState_Loading;
              icon = getLoaderIcon(color);
              hasLoader = true;
            }
          }
        case MessageSendState.send:
          icon =
              FaIcon(FontAwesomeIcons.solidPaperPlane, size: 12, color: color);
          text = context.lang.messageSendState_Send;
        case MessageSendState.sending:
          icon = getLoaderIcon(color);
          text = context.lang.messageSendState_Sending;

          if (mediaFile != null) {
            if (mediaFile.uploadState == UploadState.uploadLimitReached) {
              icon = FaIcon(
                FontAwesomeIcons.triangleExclamation,
                size: 12,
                color: color,
              );

              textWidget = Text(
                context.lang.uploadLimitReached,
                style: const TextStyle(fontSize: 9),
              );

              onTap = () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const SubscriptionView();
                    },
                  ),
                );
              };
            }
            if (mediaFile.uploadState == UploadState.preprocessing) {
              text = 'Wird verarbeitet';
            }
          }

          hasLoader = true;
        case MessageSendState.receiving:
          icon = getLoaderIcon(color);
          text = context.lang.messageSendState_Received;
          hasLoader = true;
      }

      if (message.mediaStored) {
        icon = FaIcon(FontAwesomeIcons.floppyDisk, size: 12, color: color);
        text = context.lang.messageStoredInGallery;
      }

      if (mediaFile != null) {
        if (mediaFile.reopenByContact) {
          icon = FaIcon(FontAwesomeIcons.repeat, size: 12, color: color);
          text = context.lang.messageReopened;
        }

        if (mediaFile.downloadState == DownloadState.reuploadRequested) {
          icon =
              FaIcon(FontAwesomeIcons.clockRotateLeft, size: 12, color: color);
          textWidget = Text(
            context.lang.retransmissionRequested,
            style: const TextStyle(fontSize: 9),
          );
        }
      }

      if (message.isDeletedFromSender) {
        icon = FaIcon(FontAwesomeIcons.trash, size: 10, color: color);
        text = context.lang.messageWasDeletedShort;
      }

      if (hasLoader) {
        icons = [icon];
        break;
      }

      if (message.type == MessageType.media) {
        icons.insert(0, icon);
      } else {
        icons.add(icon);
      }
    }

    if (widget.lastReaction != null &&
        !widget.messages.any((t) => t.openedAt == null)) {
      /// No messages are still open, so check if the reaction is the last message received.

      if (!widget.messages
          .any((m) => m.createdAt.isAfter(widget.lastReaction!.createdAt))) {
        if (EmojiAnimation.animatedIcons
            .containsKey(widget.lastReaction!.emoji)) {
          icons = [
            SizedBox(
              height: 18,
              child: EmojiAnimation(emoji: widget.lastReaction!.emoji),
            ),
          ];
        } else {
          icons = [
            SizedBox(
              height: 18,
              child: Center(
                child: Text(
                  widget.lastReaction!.emoji,
                  style: const TextStyle(fontSize: 15),
                  strutStyle: const StrutStyle(
                    forceStrutHeight: true,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ];
        }
        // Log.info("DISPLAY REACTION");
      }
    }

    if (icons.isEmpty) return Container();

    var icon = icons[0];

    if (icons.length == 2) {
      icon = Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Transform.scale(
            scale: 1.3,
            child: icons[1],
          ),
          icons[0],
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: widget.mainAxisAlignment,
        children: [
          icon,
          const SizedBox(width: 3),
          if (textWidget != null)
            textWidget
          else
            Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }
}
