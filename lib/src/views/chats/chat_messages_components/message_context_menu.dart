// ignore_for_file: inference_failure_on_function_invocation

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pbserver.dart'
    as pb;
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/image_editor/data/layer.dart';
import 'package:twonly/src/views/camera/image_editor/modules/all_emojis.dart';
import 'package:twonly/src/views/chats/message_info.view.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';

class MessageContextMenu extends StatelessWidget {
  const MessageContextMenu({
    required this.message,
    required this.group,
    required this.child,
    required this.onResponseTriggered,
    super.key,
  });
  final Group group;
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
        if (!message.isDeletedFromSender)
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

              await twonlyDB.reactionsDao
                  .updateMyReaction(message.messageId, layer.text);

              await sendCipherTextToGroup(
                message.groupId,
                pb.EncryptedContent(
                  reaction: pb.EncryptedContent_Reaction(
                    targetMessageId: message.messageId,
                    emoji: layer.text,
                    remove: false,
                  ),
                ),
                null,
              );
            },
            child: const FaIcon(FontAwesomeIcons.faceLaugh),
          ),
        if (!message.isDeletedFromSender)
          PieAction(
            tooltip: Text(context.lang.reply),
            onSelect: onResponseTriggered,
            child: const FaIcon(FontAwesomeIcons.reply),
          ),
        if (!message.isDeletedFromSender &&
            message.senderId == null &&
            message.type == MessageType.text)
          PieAction(
            tooltip: Text(context.lang.edit),
            onSelect: () async {
              await editTextMessage(context, message);
            },
            child: const FaIcon(FontAwesomeIcons.pencil),
          ),
        if (message.content != null)
          PieAction(
            tooltip: Text(context.lang.copy),
            onSelect: () async {
              await Clipboard.setData(ClipboardData(text: message.content!));
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
              customOk:
                  (message.senderId == null && !message.isDeletedFromSender)
                      ? context.lang.deleteOkBtnForAll
                      : context.lang.deleteOkBtnForMe,
            );
            if (delete) {
              if (message.senderId == null && !message.isDeletedFromSender) {
                await twonlyDB.messagesDao.handleMessageDeletion(
                  null,
                  message.messageId,
                  DateTime.now(),
                );
                await sendCipherTextToGroup(
                  message.groupId,
                  pb.EncryptedContent(
                    messageUpdate: pb.EncryptedContent_MessageUpdate(
                      type: pb.EncryptedContent_MessageUpdate_Type.DELETE,
                      senderMessageId: message.messageId,
                    ),
                  ),
                  null,
                );
              } else {
                await twonlyDB.messagesDao
                    .deleteMessagesById(message.messageId);
              }
            }
          },
          child: const FaIcon(FontAwesomeIcons.trash),
        ),
        if (!message.isDeletedFromSender)
          PieAction(
            tooltip: Text(context.lang.info),
            onSelect: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return MessageInfoView(
                      message: message,
                      group: group,
                    );
                  },
                ),
              );
            },
            child: const FaIcon(FontAwesomeIcons.circleInfo),
          ),
      ],
      child: child,
    );
  }
}

Future<void> editTextMessage(BuildContext context, Message message) async {
  var newText = message.content;
  final controller = TextEditingController(text: message.content);
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.multiline,
                      maxLines: 4,
                      minLines: 1,
                      onChanged: (value) => setState(() {
                        newText = value;
                      }),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(context.lang.cancel),
          ),
          TextButton(
            onPressed: () async {
              if (newText != null &&
                  newText != message.content &&
                  newText != '') {
                final timestamp = DateTime.now();

                await twonlyDB.messagesDao.handleTextEdit(
                  null,
                  message.messageId,
                  newText!,
                  timestamp,
                );
                await sendCipherTextToGroup(
                  message.groupId,
                  pb.EncryptedContent(
                    messageUpdate: pb.EncryptedContent_MessageUpdate(
                      type: pb.EncryptedContent_MessageUpdate_Type.EDIT_TEXT,
                      senderMessageId: message.messageId,
                      text: newText,
                      timestamp: Int64(
                        timestamp.millisecondsSinceEpoch,
                      ),
                    ),
                  ),
                  null,
                );
              }
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            child: Text(context.lang.ok),
          ),
        ],
      );
    },
  );
}
