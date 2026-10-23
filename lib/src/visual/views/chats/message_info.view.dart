import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/bridge/database/messages.dart' as rust_messages;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/mediafiles/table.dart'
    as db_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/model/message_enums.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/recipient_status_row.comp.dart';
import 'package:twonly/src/visual/elements/better_list_title.element.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/bottom_sheets/message_history.bottom_sheet.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/chat_list_entry.dart';

class MessageInfoView extends StatefulWidget {
  const MessageInfoView({
    required this.message,
    required this.group,
    required this.galleryItems,
    super.key,
  });

  final StoredMessage message;
  final Group group;
  final List<MemoryItem> galleryItems;

  @override
  State<MessageInfoView> createState() => _MessageInfoViewState();
}

class _MessageInfoViewState extends State<MessageInfoView> {
  StreamSubscription<List<StoredMessage>>? messageStream;
  StreamSubscription<void>? userStream;
  StreamSubscription<List<(MessageAction, Contact)>>? actionsStream;
  StreamSubscription<List<MessageHistory>>? historyStream;
  StreamSubscription<List<(GroupMember, Contact)>>? groupMemberStream;
  StreamSubscription<MediaFile?>? mediaFileStream;

  List<(MessageAction, Contact)> messageActions = [];
  List<MessageHistory> messageHistory = [];
  List<(GroupMember, Contact)> groupMembers = [];
  MediaFile? mediaFile;
  int? mediaSizeInBytes;
  late StoredMessage message;

  @override
  void initState() {
    super.initState();
    message = widget.message;
    userStream = userService.onUserUpdated.listen((_) {
      if (mounted) setState(() {});
    });
    initAsync();
  }

  @override
  void dispose() {
    messageStream?.cancel();
    userStream?.cancel();
    actionsStream?.cancel();
    historyStream?.cancel();
    groupMemberStream?.cancel();
    mediaFileStream?.cancel();
    super.dispose();
  }

  Future<void> initAsync() async {
    messageStream =
        watchRustDatabase(
          (control) => rust_messages.watchMessages(
            input: MessageQuery(
              filter: MessageFilter.ids,
              ids: [widget.message.messageId],
              nowMs: DateTime.now().millisecondsSinceEpoch,
            ),
            control: control,
          ),
        ).listen((update) {
          if (!mounted || update.isEmpty) return;
          setState(() => message = update.single);
        });

    final streamActions = watchRustDatabase(
      (control) => rust_messages
          .watchMessageActions(id: widget.message.messageId, control: control)
          .map(messageActionsWithContacts),
    );
    actionsStream = streamActions.listen((update) {
      if (!mounted) return;
      setState(() {
        messageActions = update;
      });
    });

    final streamGroup =
        watchRustDatabase(
          (control) => rust_groups
              .watchGroupContacts(
                input: db_groups.GroupMembersQuery(
                  groupId: widget.message.groupId,
                  activeOnly: false,
                ),
                control: control,
              )
              .map(joinedGroupContacts),
        ).map(
          (rows) => rows.map((row) => (row.$2, row.$1)).toList(growable: false),
        );
    groupMemberStream = streamGroup.listen((update) {
      if (!mounted) return;
      setState(() {
        groupMembers = update;
      });
    });

    final streamHistory = watchRustDatabase(
      (control) => rust_messages.watchMessageHistory(
        id: widget.message.messageId,
        control: control,
      ),
    );
    historyStream = streamHistory.listen((update) {
      if (!mounted) return;
      setState(() {
        messageHistory = update;
      });
    });

    final mediaId = widget.message.mediaId;
    if (mediaId != null) {
      final streamMedia = watchRustDatabase(
        (control) => rust_mediafiles
            .watchMediaFiles(
              input: db_mediafiles.MediaQuery(
                filter: db_mediafiles.MediaFilter.ids,
                ids: [mediaId].toList(),
              ),
              control: control,
            )
            .map(orderedMediaFiles),
      ).map((rows) => rows.isEmpty ? null : rows.single);
      mediaFileStream = streamMedia.listen((update) {
        if (!mounted) return;
        setState(() {
          mediaFile = update;
          mediaSizeInBytes = update == null ? null : mediaSize(update);
        });
      });
    }
  }

  /// Rust records the size when it writes the plaintext, but media that was
  /// sent or received before it did so only carries a size once it was stored,
  /// so a copy that is still on disk is measured directly.
  int? mediaSize(MediaFile media) {
    if (media.sizeInBytes != null) return media.sizeInBytes;
    final service = MediaFileService(media);
    for (final file in [
      service.storedPath,
      service.tempPath,
      service.originalPath,
    ]) {
      final stat = file.statSync();
      if (stat.type == FileSystemEntityType.file) return stat.size;
    }
    return null;
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
      final sendFailed = messageActions.firstWhereOrNull(
        (t) =>
            t.$1.type == MessageActionType.sendFailed &&
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
      if (sendFailed != null) {
        actionTypeText = context.lang.mediaSendFailed;
        actionAt = sendFailed.$1.actionAt;
      }

      columns.add(
        RecipientStatusRow(
          key: ValueKey(groupMember.$1.contactId),
          contact: groupMember.$2,
          status: actionTypeText,
          at: actionAt,
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
                  message: message,
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
              '${context.lang.sent}: ${friendlyDateTime(context, message.createdAt)}',
            ),
            if (message.senderId != null && message.ackByServer != null)
              Text(
                '${context.lang.received}: ${friendlyDateTime(context, message.ackByServer!)}',
              ),
            if (mediaSizeInBytes != null)
              Text(
                '${context.lang.fileSize}: ${formatBytes(mediaSizeInBytes!)}',
              ),
            if (userService.currentUser.isDeveloper)
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: widget.message.messageId),
                  );
                  await HapticFeedback.heavyImpact();
                },
                child: Text('ID: ${widget.message.messageId}'),
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
                    backgroundColor: context.color.surface,
                    builder: (context) {
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
