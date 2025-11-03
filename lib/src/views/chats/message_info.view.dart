import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_messages_components/bottom_sheets/message_history.bottom_sheet.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_list_entry.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/better_list_title.dart';

class MessageInfoView extends StatefulWidget {
  const MessageInfoView({
    required this.message,
    required this.group,
    required this.galleryItems,
    super.key,
  });

  final Message message;
  final Group group;
  final List<MemoryItem> galleryItems;

  @override
  State<MessageInfoView> createState() => _MessageInfoViewState();
}

class _MessageInfoViewState extends State<MessageInfoView> {
  StreamSubscription<List<(MessageAction, Contact)>>? actionsStream;
  StreamSubscription<List<MessageHistory>>? historyStream;
  StreamSubscription<List<(GroupMember, Contact)>>? groupMemberStream;

  List<(MessageAction, Contact)> messageActions = [];
  List<MessageHistory> messageHistory = [];
  List<(GroupMember, Contact)> groupMembers = [];

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  @override
  void dispose() {
    actionsStream?.cancel();
    historyStream?.cancel();
    groupMemberStream?.cancel();
    super.dispose();
  }

  Future<void> initAsync() async {
    final streamActions =
        twonlyDB.messagesDao.watchMessageActions(widget.message.messageId);
    actionsStream = streamActions.listen((update) {
      setState(() {
        messageActions = update;
      });
    });

    final streamGroup =
        twonlyDB.messagesDao.watchMembersByGroupId(widget.message.groupId);
    groupMemberStream = streamGroup.listen((update) {
      setState(() {
        groupMembers = update;
      });
    });

    final streamHistory =
        twonlyDB.messagesDao.watchMessageHistory(widget.message.messageId);
    historyStream = streamHistory.listen((update) {
      setState(() {
        messageHistory = update;
      });
    });
  }

  List<Widget> getReceivedColumns(BuildContext context) {
    if (widget.message.senderId != null) return [];

    final columns = <Widget>[
      const SizedBox(height: 10),
      const Divider(),
      const SizedBox(height: 20),
      Text(context.lang.sentTo),
      const SizedBox(height: 10),
    ];

    for (final groupMember in groupMembers) {
      final ackByServer = messageActions.firstWhereOrNull(
        (t) =>
            t.$1.type == MessageActionType.ackByServerAt &&
            t.$2.userId == groupMember.$2.userId,
      );
      final ackByUser = messageActions.firstWhereOrNull(
        (t) =>
            t.$1.type == MessageActionType.ackByUserAt &&
            t.$2.userId == groupMember.$2.userId,
      );
      final openedByUser = messageActions.firstWhereOrNull(
        (t) =>
            t.$1.type == MessageActionType.openedAt &&
            t.$2.userId == groupMember.$2.userId,
      );

      var actionTypeText = context.lang.waitingForInternet;
      var actionAt = widget.message.createdAt;
      if (ackByServer != null) {
        actionTypeText = context.lang.sent;
        actionAt = ackByServer.$1.actionAt;
      }
      if (ackByUser != null) {
        actionTypeText = context.lang.received;
        actionAt = ackByUser.$1.actionAt;
      }
      if (openedByUser != null) {
        actionTypeText = context.lang.opened;
        actionAt = openedByUser.$1.actionAt;
      }

      columns.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              AvatarIcon(
                contactId: groupMember.$2.userId,
                fontSize: 15,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getContactDisplayName(groupMember.$2),
                      style: const TextStyle(fontSize: 17),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    friendlyDateTime(context, actionAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(actionTypeText),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return columns;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            Stack(
              children: [
                ChatListEntry(
                  group: widget.group,
                  message: widget.message,
                  galleryItems: widget.galleryItems,
                ),
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      // In case in ChatListEntry is a image, this prevents to open the image preview.
                    },
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${context.lang.sent}: ${friendlyDateTime(context, widget.message.createdAt)}',
            ),
            if (widget.message.senderId != null &&
                widget.message.ackByServer != null)
              Text(
                '${context.lang.received}: ${friendlyDateTime(context, widget.message.ackByServer!)}',
              ),
            if (messageHistory.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
              BetterListTile(
                icon: FontAwesomeIcons.pencil,
                padding: EdgeInsets.zero,
                text: context.lang.editHistory,
                onTap: () async {
                  // ignore: inference_failure_on_function_invocation
                  await showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.black,
                    builder: (BuildContext context) {
                      return MessageHistoryView(
                        message: widget.message,
                        changes: messageHistory,
                        group: widget.group,
                      );
                    },
                  );
                },
              ),
            ],
            ...getReceivedColumns(context),
          ],
        ),
      ),
    );
  }
}
