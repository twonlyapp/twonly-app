// ignore_for_file: inference_failure_on_function_invocation

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/message_old.dart';
import 'package:twonly/src/model/protobuf/push_notification/push_notification.pbserver.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/image_editor/data/layer.dart';
import 'package:twonly/src/views/camera/image_editor/modules/all_emojis.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';

class MessageContextMenu extends StatelessWidget {
  const MessageContextMenu({
    required this.message,
    required this.child,
    required this.onResponseTriggered,
    super.key,
  });
  final Widget child;
  final Message message;
  final VoidCallback onResponseTriggered;

  @override
  Widget build(BuildContext context) {
    return PieMenu(
      onPressed: () => (),
      onToggle: (menuOpen) async {
        if (menuOpen) {
          await HapticFeedback.heavyImpact();
        }
      },
      actions: [
        PieAction(
          tooltip: Text(context.lang.react),
          onSelect: () async {
            final layer = await showModalBottomSheet(
              context: context,
              backgroundColor: Colors.black,
              builder: (BuildContext context) {
                return const Emojis();
              },
            ) as EmojiLayerData?;
            if (layer == null) return;

            await sendTextMessage(
              message.contactId,
              TextMessageContent(
                text: layer.text,
                responseToMessageId: message.messageOtherId,
                responseToOtherMessageId:
                    (message.messageOtherId == null) ? message.messageId : null,
              ),
              (message.messageOtherId != null)
                  ? PushNotification(
                      kind: (message.kind == MessageKind.textMessage)
                          ? PushKind.reactionToText
                          : (getMediaContent(message)!.isVideo)
                              ? PushKind.reactionToVideo
                              : PushKind.reactionToImage,
                      reactionContent: layer.text,
                    )
                  : null,
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
          onSelect: () async {
            final text = getMessageText(message);
            await Clipboard.setData(ClipboardData(text: text));
            await HapticFeedback.heavyImpact();
          },
          child: const FaIcon(FontAwesomeIcons.solidCopy),
        ),
        PieAction(
          tooltip: Text(context.lang.delete),
          onSelect: () async {
            final delete = await showAlertDialog(
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
