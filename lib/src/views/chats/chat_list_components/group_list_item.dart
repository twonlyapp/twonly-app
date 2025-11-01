import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
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
import 'package:twonly/src/views/contact/contact.view.dart';
import 'package:twonly/src/views/groups/group.view.dart';

class GroupListItem extends StatefulWidget {
  const GroupListItem({
    required this.group,
    super.key,
  });
  final Group group;

  @override
  State<GroupListItem> createState() => _UserListItem();
}

class _UserListItem extends State<GroupListItem> {
  Message? _currentMessage;

  List<Message> _messagesNotOpened = [];
  late StreamSubscription<List<Message>> _messagesNotOpenedStream;

  Message? _lastMessage;
  Reaction? _lastReaction;
  late StreamSubscription<Message?> _lastMessageStream;
  late StreamSubscription<Reaction?> _lastReactionStream;
  late StreamSubscription<List<MediaFile>> _lastMediaFilesStream;

  List<Message> _previewMessages = [];
  final List<MediaFile> _previewMediaFiles = [];
  bool _hasNonOpenedMediaFile = false;

  @override
  void initState() {
    super.initState();
    initStreams();
  }

  @override
  void dispose() {
    _messagesNotOpenedStream.cancel();
    _lastReactionStream.cancel();
    _lastMessageStream.cancel();
    _lastMediaFilesStream.cancel();
    super.dispose();
  }

  void initStreams() {
    _lastMessageStream = twonlyDB.messagesDao
        .watchLastMessage(widget.group.groupId)
        .listen((update) {
      protectUpdateState.protect(() async {
        await updateState(update, _messagesNotOpened);
      });
    });

    _lastReactionStream = twonlyDB.reactionsDao
        .watchLastReactions(widget.group.groupId)
        .listen((update) {
      setState(() {
        _lastReaction = update;
      });
      // protectUpdateState.protect(() async {
      //   await updateState(lastMessage, update, messagesNotOpened);
      // });
    });

    _messagesNotOpenedStream = twonlyDB.messagesDao
        .watchMessageNotOpened(widget.group.groupId)
        .listen((update) {
      protectUpdateState.protect(() async {
        await updateState(_lastMessage, update);
      });
    });

    _lastMediaFilesStream =
        twonlyDB.mediaFilesDao.watchNewestMediaFiles().listen((mediaFiles) {
      for (final mediaFile in mediaFiles) {
        final index = _previewMediaFiles
            .indexWhere((t) => t.mediaId == mediaFile.mediaId);
        if (index >= 0) {
          _previewMediaFiles[index] = mediaFile;
        }
      }
      setState(() {});
    });
  }

  Mutex protectUpdateState = Mutex();

  Future<void> updateState(
    Message? newLastMessage,
    List<Message> newMessagesNotOpened,
  ) async {
    if (newLastMessage == null) {
      // there are no messages at all
      _currentMessage = null;
      _previewMessages = [];
    } else if (newMessagesNotOpened.isNotEmpty) {
      // Filter for the preview non opened messages. First messages which where send but not yet opened by the other side.
      final receivedMessages =
          newMessagesNotOpened.where((x) => x.senderId != null).toList();

      if (receivedMessages.isNotEmpty) {
        _previewMessages = receivedMessages;
        _currentMessage = receivedMessages.first;
      } else {
        _previewMessages = newMessagesNotOpened;
        _currentMessage = newMessagesNotOpened.first;
      }
    } else {
      // there are no not opened messages show just the last message in the table
      _currentMessage = newLastMessage;
      _previewMessages = [newLastMessage];
    }

    final msgs =
        _previewMessages.where((x) => x.type == MessageType.media).toList();
    if (msgs.isNotEmpty &&
        msgs.first.type == MessageType.media &&
        msgs.first.senderId != null &&
        msgs.first.openedAt == null) {
      _hasNonOpenedMediaFile = true;
    } else {
      _hasNonOpenedMediaFile = false;
    }

    for (final message in _previewMessages) {
      if (message.mediaId != null &&
          !_previewMediaFiles.any((t) => t.mediaId == message.mediaId)) {
        final mediaFile =
            await twonlyDB.mediaFilesDao.getMediaFileById(message.mediaId!);
        if (mediaFile != null) {
          _previewMediaFiles.add(mediaFile);
        }
      }
    }

    _lastMessage = newLastMessage;
    _messagesNotOpened = newMessagesNotOpened;
    if (mounted) setState(() {});
  }

  Future<void> onTap() async {
    if (_currentMessage == null) {
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

    if (_hasNonOpenedMediaFile) {
      final msgs =
          _previewMessages.where((x) => x.type == MessageType.media).toList();
      final mediaFile =
          await twonlyDB.mediaFilesDao.getMediaFileById(msgs.first.mediaId!);
      if (mediaFile?.downloadState == null) return;
      if (mediaFile!.downloadState! == DownloadState.pending) {
        await startDownloadMedia(mediaFile, true);
        return;
      }
      if (mediaFile.downloadState! == DownloadState.ready) {
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
    return GroupContextMenu(
      group: widget.group,
      child: ListTile(
        title: Text(
          substringBy(widget.group.groupName, 30),
        ),
        subtitle: (_currentMessage == null)
            ? (widget.group.totalMediaCounter == 0)
                ? Text(context.lang.chatsTapToSend)
                : LastMessageTime(dateTime: widget.group.lastMessageExchange)
            : Row(
                children: [
                  MessageSendStateIcon(
                    _previewMessages,
                    _previewMediaFiles,
                    lastReaction: _lastReaction,
                  ),
                  const Text('•'),
                  const SizedBox(width: 5),
                  if (_currentMessage != null)
                    LastMessageTime(message: _currentMessage),
                  FlameCounterWidget(
                    groupId: widget.group.groupId,
                    prefix: true,
                  ),
                ],
              ),
        leading: GestureDetector(
          onTap: () async {
            Widget pushWidget = GroupView(widget.group);

            if (widget.group.isDirectChat) {
              final contacts = await twonlyDB.groupsDao
                  .getGroupContact(widget.group.groupId);
              pushWidget = ContactView(contacts.first.userId);
            }
            if (!context.mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return pushWidget;
                },
              ),
            );
          },
          child: AvatarIcon(group: widget.group),
        ),
        trailing: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  if (_hasNonOpenedMediaFile) {
                    return ChatMessagesView(widget.group);
                  } else {
                    return CameraSendToView(widget.group);
                  }
                },
              ),
            );
          },
          icon: FaIcon(
            _hasNonOpenedMediaFile
                ? FontAwesomeIcons.solidComments
                : FontAwesomeIcons.camera,
            color: context.color.outline.withAlpha(150),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
