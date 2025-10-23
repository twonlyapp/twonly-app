import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';

class GroupContextMenu extends StatefulWidget {
  const GroupContextMenu({
    required this.group,
    required this.child,
    super.key,
  });
  final Widget child;
  final Group group;

  @override
  State<GroupContextMenu> createState() => _GroupContextMenuState();
}

class _GroupContextMenuState extends State<GroupContextMenu> {
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
        if (!widget.group.archived)
          PieAction(
            tooltip: Text(context.lang.contextMenuArchiveUser),
            onSelect: () async {
              const update = GroupsCompanion(archived: Value(true));
              if (context.mounted) {
                await twonlyDB.groupsDao
                    .updateGroup(widget.group.groupId, update);
              }
            },
            child: const FaIcon(FontAwesomeIcons.boxArchive),
          ),
        if (widget.group.archived)
          PieAction(
            tooltip: Text(context.lang.contextMenuUndoArchiveUser),
            onSelect: () async {
              const update = GroupsCompanion(archived: Value(false));
              if (context.mounted) {
                await twonlyDB.groupsDao
                    .updateGroup(widget.group.groupId, update);
              }
            },
            child: const FaIcon(FontAwesomeIcons.boxOpen),
          ),
        PieAction(
          tooltip: Text(context.lang.contextMenuOpenChat),
          onSelect: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ChatMessagesView(widget.group);
                },
              ),
            );
          },
          child: const FaIcon(FontAwesomeIcons.solidComments),
        ),
        PieAction(
          tooltip: Text(
            widget.group.pinned
                ? context.lang.contextMenuUnpin
                : context.lang.contextMenuPin,
          ),
          onSelect: () async {
            final update = GroupsCompanion(pinned: Value(!widget.group.pinned));
            if (context.mounted) {
              await twonlyDB.groupsDao
                  .updateGroup(widget.group.groupId, update);
            }
          },
          child: FaIcon(
            widget.group.pinned
                ? FontAwesomeIcons.thumbtackSlash
                : FontAwesomeIcons.thumbtack,
          ),
        ),
      ],
      child: widget.child,
    );
  }
}
