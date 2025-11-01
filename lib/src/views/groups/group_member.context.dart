import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';
import 'package:twonly/src/views/components/context_menu.component.dart';

class GroupMemberContextMenu extends StatelessWidget {
  const GroupMemberContextMenu({
    required this.contact,
    required this.member,
    required this.child,
    required this.group,
    super.key,
  });
  final Contact contact;
  final GroupMember member;
  final Group group;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ContextMenu(
      items: [
        if (contact.accepted)
          ContextMenuItem(
            title: context.lang.contextMenuOpenChat,
            onTap: () async {
              final directChat =
                  await twonlyDB.groupsDao.getDirectChat(contact.userId);
              if (directChat == null) {
                // create
                return;
              }
              if (!context.mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatMessagesView(directChat),
                ),
              );
            },
            icon: FontAwesomeIcons.message,
          ),
        if (!contact.accepted)
          ContextMenuItem(
            title: context.lang.createContactRequest,
            onTap: () async {
              // onResponseTriggered();
            },
            icon: FontAwesomeIcons.userPlus,
          ),
        if (group.isGroupAdmin && member.memberState == MemberState.normal)
          ContextMenuItem(
            title: context.lang.makeAdmin,
            onTap: () async {
              // onResponseTriggered();
            },
            icon: FontAwesomeIcons.key,
          ),
        if (group.isGroupAdmin && member.memberState == MemberState.admin)
          ContextMenuItem(
            title: context.lang.removeAdmin,
            onTap: () async {
              // onResponseTriggered();
            },
            icon: FontAwesomeIcons.key,
          ),
        if (group.isGroupAdmin)
          ContextMenuItem(
            title: context.lang.removeFromGroup,
            onTap: () async {
              // onResponseTriggered();
            },
            icon: FontAwesomeIcons.rightFromBracket,
          ),
      ],
      child: child,
    );
  }
}
