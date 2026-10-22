import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/bridge/database/messages.dart' as rust_messages;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/context_menu/context_menu.helper.dart';

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
    // `late` so the ancestor lookup only runs if the menu is actually
    // opened, rather than once per row on every rebuild.
    late final navigator = Navigator.of(context);
    return ContextMenu(
      items: () => [
        if (!group.archived)
          ContextMenuItem(
            title: context.lang.contextMenuArchiveUser,
            onTap: () async {
              const update = GroupPatch(archived: true);
              await rust_groups.updateGroup(
                id: group.groupId,
                patch: update,
                transaction: currentDatabaseSession(),
              );
            },
            icon: Icons.archive_outlined,
          ),
        if (group.archived)
          ContextMenuItem(
            title: context.lang.contextMenuUndoArchiveUser,
            onTap: () async {
              const update = GroupPatch(archived: false);
              await rust_groups.updateGroup(
                id: group.groupId,
                patch: update,
                transaction: currentDatabaseSession(),
              );
            },
            icon: Icons.unarchive_outlined,
          ),
        ContextMenuItem(
          title: context.lang.contextMenuOpenChat,
          onTap: () => navigator.context.push(
            Routes.chatsMessages(group.groupId),
            extra: group,
          ),
          icon: FontAwesomeIcons.comments,
        ),
        if (!group.archived)
          ContextMenuItem(
            title: group.pinned
                ? context.lang.contextMenuUnpin
                : context.lang.contextMenuPin,
            onTap: () async {
              final update = GroupPatch(pinned: !group.pinned);
              await rust_groups.updateGroup(
                id: group.groupId,
                patch: update,
                transaction: currentDatabaseSession(),
              );
            },
            icon: group.pinned
                ? FontAwesomeIcons.thumbtackSlash
                : FontAwesomeIcons.thumbtack,
          ),
        ContextMenuItem(
          title: context.lang.delete,
          icon: FontAwesomeIcons.trashCan,
          onTap: () async {
            final ok = await showAlertDialog(
              navigator.context,
              navigator.context.lang.deleteTitle,
              navigator.context.lang.groupContextMenuDeleteGroup,
            );
            if (ok) {
              await rust_messages.clearChatMessages(
                group: group.groupId,
                transaction: currentDatabaseSession(),
              );
            }
          },
        ),
      ],
      child: child,
    );
  }
}
