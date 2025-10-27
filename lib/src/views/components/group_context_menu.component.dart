import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';
import 'package:twonly/src/views/components/context_menu.component.dart';

class GroupContextMenu extends StatelessWidget {
  const GroupContextMenu({
    required this.group,
    required this.child,
    super.key,
  });
  final Widget child;
  final Group group;

  @override
  Widget build(BuildContext context) {
    return ContextMenu(
      items: [
        if (!group.archived)
          ContextMenuItem(
            title: context.lang.contextMenuArchiveUser,
            onTap: () async {
              const update = GroupsCompanion(archived: Value(true));
              if (context.mounted) {
                await twonlyDB.groupsDao.updateGroup(group.groupId, update);
              }
            },
            icon: FontAwesomeIcons.boxArchive,
          ),
        if (group.archived)
          ContextMenuItem(
            title: context.lang.contextMenuUndoArchiveUser,
            onTap: () async {
              const update = GroupsCompanion(archived: Value(false));
              if (context.mounted) {
                await twonlyDB.groupsDao.updateGroup(group.groupId, update);
              }
            },
            icon: FontAwesomeIcons.boxOpen,
          ),
        ContextMenuItem(
          title: context.lang.contextMenuOpenChat,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ChatMessagesView(group);
                },
              ),
            );
          },
          icon: FontAwesomeIcons.comments,
        ),
        if (!group.archived)
          ContextMenuItem(
            title: group.pinned
                ? context.lang.contextMenuUnpin
                : context.lang.contextMenuPin,
            onTap: () async {
              final update = GroupsCompanion(pinned: Value(!group.pinned));
              if (context.mounted) {
                await twonlyDB.groupsDao.updateGroup(group.groupId, update);
              }
            },
            icon: group.pinned
                ? FontAwesomeIcons.thumbtackSlash
                : FontAwesomeIcons.thumbtack,
          ),
      ],
      child: child,
    );
  }
}
