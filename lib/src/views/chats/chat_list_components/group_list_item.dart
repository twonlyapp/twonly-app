import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/mediafiles/download.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/camera_send_to_view.dart';
import 'package:twonly/src/views/chats/chat_list_components/last_message_time.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';
import 'package:twonly/src/views/chats/chat_messages_components/message_send_state_icon.dart';
import 'package:twonly/src/views/chats/media_viewer.view.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/flame.dart';
import 'package:twonly/src/views/components/group_context_menu.component.dart';

class GroupListItem extends StatefulWidget {
  const GroupListItem({
    required this.group,
    required this.firstUserListItemKey,
    super.key,
  });
  final Group group;
  final GlobalKey? firstUserListItemKey;

  @override
  State<GroupListItem> createState() => _UserListItem();
}

class _UserListItem extends State<GroupListItem> {
  MessageSendState state = MessageSendState.send;
  Message? currentMessage;

  List<Message> messagesNotOpened = [];
  late StreamSubscription<List<Message>> messagesNotOpenedStream;

  List<Message> lastMessages = [];
  late StreamSubscription<List<Message>> lastMessageStream;

  List<Message> previewMessages = [];
  bool hasNonOpenedMediaFile = false;

  @override
  void initState() {
    super.initState();
    initStreams();
  }

  @override
  void dispose() {
    messagesNotOpenedStream.cancel();
    lastMessageStream.cancel();
    super.dispose();
  }

  void initStreams() {
    lastMessageStream = twonlyDB.messagesDao
        .watchLastMessage(widget.group.groupId)
        .listen((update) {
      updateState(update, messagesNotOpened);
    });

    messagesNotOpenedStream = twonlyDB.messagesDao
        .watchMessageNotOpened(widget.group.groupId)
        .listen((update) {
      updateState(lastMessages, update);
    });
  }

  void updateState(
    List<Message> newLastMessages,
    List<Message> newMessagesNotOpened,
  ) {
    if (newLastMessages.isEmpty) {
      // there are no messages at all
      currentMessage = null;
      previewMessages = [];
    } else if (newMessagesNotOpened.isEmpty) {
      // there are no not opened messages show just the last message in the table
      currentMessage = newLastMessages.last;
      previewMessages = newLastMessages;
    } else {
      // filter first for received messages
      final receivedMessages =
          newMessagesNotOpened.where((x) => x.senderId != null).toList();

      if (receivedMessages.isNotEmpty) {
        previewMessages = receivedMessages;
        currentMessage = receivedMessages.first;
      } else {
        previewMessages = newMessagesNotOpened;
        currentMessage = newMessagesNotOpened.first;
      }
    }

    final msgs =
        previewMessages.where((x) => x.type == MessageType.media).toList();
    if (msgs.isNotEmpty &&
        msgs.first.type == MessageType.media &&
        msgs.first.senderId != null &&
        msgs.first.openedAt == null) {
      hasNonOpenedMediaFile = true;
    } else {
      hasNonOpenedMediaFile = false;
    }

    lastMessages = newLastMessages;
    messagesNotOpened = newMessagesNotOpened;
    setState(() {
      // sets lastMessages, messagesNotOpened and currentMessage
    });
  }

  Future<void> onTap() async {
    if (currentMessage == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return CameraSendToView(widget.group);
          },
        ),
      );
      return;
    }

    if (hasNonOpenedMediaFile) {
      final msgs =
          previewMessages.where((x) => x.type == MessageType.media).toList();
      final mediaFile =
          await twonlyDB.mediaFilesDao.getMediaFileById(msgs.first.mediaId!);
      if (mediaFile?.downloadState == null) return;
      if (mediaFile!.downloadState! == DownloadState.pending) {
        await startDownloadMedia(mediaFile, true);
        return;
      }
      if (mediaFile.downloadState! == DownloadState.downloaded) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return MediaViewerView(widget.group);
            },
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ChatMessagesView(widget.group);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          bottom: 0,
          left: 50,
          child: SizedBox(
            key: widget.firstUserListItemKey,
            height: 20,
            width: 20,
          ),
        ),
        GroupContextMenu(
          group: widget.group,
          child: ListTile(
            title: Text(
              widget.group.groupName,
            ),
            subtitle: (currentMessage == null)
                ? Text(context.lang.chatsTapToSend)
                : Row(
                    children: [
                      MessageSendStateIcon(previewMessages),
                      const Text('•'),
                      const SizedBox(width: 5),
                      if (currentMessage != null)
                        LastMessageTime(message: currentMessage!),
                      FlameCounterWidget(
                        groupId: widget.group.groupId,
                        prefix: true,
                      ),
                    ],
                  ),
            leading: AvatarIcon(group: widget.group),
            trailing: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      if (hasNonOpenedMediaFile) {
                        return ChatMessagesView(widget.group);
                      } else {
                        return CameraSendToView(widget.group);
                      }
                    },
                  ),
                );
              },
              icon: FaIcon(
                hasNonOpenedMediaFile
                    ? FontAwesomeIcons.solidComments
                    : FontAwesomeIcons.camera,
                color: context.color.outline.withAlpha(150),
              ),
            ),
            onTap: onTap,
          ),
        ),
      ],
    );
  }
}
