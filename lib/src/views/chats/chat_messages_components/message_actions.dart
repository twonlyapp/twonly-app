import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/protobuf/push_notification/push_notification.pbserver.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/image_editor/data/layer.dart';
import 'package:twonly/src/views/camera/image_editor/modules/all_emojis.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';

class MessageActions extends StatefulWidget {
  final Widget child;
  final Message message;
  final VoidCallback onResponseTriggered;

  const MessageActions({
    super.key,
    required this.child,
    required this.message,
    required this.onResponseTriggered,
  });

  @override
  State<MessageActions> createState() => _SlidingResponseWidgetState();
}

class _SlidingResponseWidgetState extends State<MessageActions> {
  double _offsetX = 0.0;
  bool gotFeedback = false;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offsetX += details.delta.dx;
      if (_offsetX > 40) {
        _offsetX = 40;
        if (!gotFeedback) {
          HapticFeedback.heavyImpact();
          gotFeedback = true;
        }
      }
      if (_offsetX < 30) {
        gotFeedback = false;
      }
      if (_offsetX <= 0) _offsetX = 0;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_offsetX >= 40) {
      widget.onResponseTriggered();
    }
    setState(() {
      _offsetX = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Transform.translate(
          offset: Offset(_offsetX, 0),
          child: GestureDetector(
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: MessageContextMenu(
              message: widget.message,
              onResponseTriggered: widget.onResponseTriggered,
              child: widget.child,
            ),
          ),
        ),
        if (_offsetX >= 40)
          Positioned(
            left: 20,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.reply,
                  size: 14,
                  // color: Colors.green,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class MessageContextMenu extends StatelessWidget {
  final Widget child;
  final Message message;
  final VoidCallback onResponseTriggered;

  const MessageContextMenu({
    super.key,
    required this.message,
    required this.child,
    required this.onResponseTriggered,
  });

  @override
  Widget build(BuildContext context) {
    return PieMenu(
      onPressed: () => (),
      onToggle: (menuOpen) {
        if (menuOpen) {
          HapticFeedback.heavyImpact();
        }
      },
      actions: [
        PieAction(
          tooltip: Text(context.lang.react),
          onSelect: () async {
            EmojiLayerData? layer = await showModalBottomSheet(
              context: context,
              backgroundColor: Colors.black,
              builder: (BuildContext context) {
                return const Emojis();
              },
            );
            if (layer == null) return;
            Log.info(layer.text);

            sendTextMessage(
              message.contactId,
              TextMessageContent(
                  text: layer.text,
                  responseToMessageId: message.messageOtherId,
                  responseToOtherMessageId: (message.messageOtherId == null)
                      ? message.messageId
                      : null),
              PushNotification(
                kind: (message.kind == MessageKind.textMessage)
                    ? PushKind.reactionToText
                    : (getMediaContent(message)!.isVideo)
                        ? PushKind.reactionToVideo
                        : PushKind.reactionToText,
                reactionContent: layer.text,
              ),
            );
          },
          child: const FaIcon(FontAwesomeIcons.faceLaugh),
        ),
        PieAction(
          tooltip: Text(context.lang.reply),
          onSelect: onResponseTriggered,
          child: const FaIcon(FontAwesomeIcons.reply),
        ),
        PieAction(
          tooltip: Text(context.lang.copy),
          onSelect: () {
            final text = getMessageText(message);
            Clipboard.setData(ClipboardData(text: text));
            HapticFeedback.heavyImpact();
          },
          child: const FaIcon(FontAwesomeIcons.solidCopy),
        ),
        PieAction(
          tooltip: Text(context.lang.delete),
          onSelect: () async {
            bool delete = await showAlertDialog(
              context,
              context.lang.deleteTitle,
              null,
              customOk: context.lang.deleteOkBtn,
            );
            if (delete) {
              await twonlyDB.messagesDao
                  .deleteMessagesByMessageId(message.messageId);
            }
          },
          child: const FaIcon(FontAwesomeIcons.trash),
        ),
        // PieAction(
        //   tooltip: Text(context.lang.info),
        //   onSelect: () {},
        //   child: const FaIcon(FontAwesomeIcons.circleInfo),
        // ),
      ],
      child: child,
    );
  }
}
