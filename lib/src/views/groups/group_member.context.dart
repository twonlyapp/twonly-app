import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/group.services.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/components/context_menu.component.dart';
import 'package:twonly/src/views/groups/group.view.dart';

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

  Future<void> _makeContactAdmin(BuildContext context) async {
    final ok = await showAlertDialog(
      context,
      context.lang.makeAdminRightsTitle(getContactDisplayName(contact)),
      context.lang.makeAdminRightsBody(getContactDisplayName(contact)),
      customOk: context.lang.makeAdminRightsOkBtn,
    );
    if (ok) {
      if (!await manageAdminState(
        group,
        member,
        contact.userId,
        false,
      )) {
        if (context.mounted) {
          showNetworkIssue(context);
        }
      }
    }
  }

  Future<void> _removeContactAsAdmin(BuildContext context) async {
    final ok = await showAlertDialog(
      context,
      context.lang.revokeAdminRightsTitle(getContactDisplayName(contact)),
      '',
      customOk: context.lang.revokeAdminRightsOkBtn,
    );
    if (ok) {
      if (!await manageAdminState(
        group,
        member,
        contact.userId,
        true,
      )) {
        if (context.mounted) {
          showNetworkIssue(context);
        }
      }
    }
  }

  Future<void> _removeContactFromGroup(BuildContext context) async {
    final ok = await showAlertDialog(
      context,
      context.lang.removeContactFromGroupTitle(getContactDisplayName(contact)),
      '',
    );
    if (ok) {
      if (!await removeMemberFromGroup(
        group,
        member,
        contact.userId,
      )) {
        if (context.mounted) {
          showNetworkIssue(context);
        }
      }
    }
  }

  Future<void> _makeContactRequest(BuildContext context) async {
    await twonlyDB.contactsDao.updateContact(
      member.contactId,
      const ContactsCompanion(
        requested: Value(true),
      ),
    );
    await sendCipherText(
      member.contactId,
      EncryptedContent(
        contactRequest: EncryptedContent_ContactRequest(
          type: EncryptedContent_ContactRequest_Type.REQUEST,
        ),
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.lang.contactRequestSend),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

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
            onTap: () => _makeContactRequest(context),
            icon: FontAwesomeIcons.userPlus,
          ),
        if (member.groupPublicKey != null &&
            group.isGroupAdmin &&
            member.memberState == MemberState.normal)
          ContextMenuItem(
            title: context.lang.makeAdmin,
            onTap: () => _makeContactAdmin(context),
            icon: FontAwesomeIcons.key,
          ),
        if (member.groupPublicKey != null &&
            group.isGroupAdmin &&
            member.memberState == MemberState.admin)
          ContextMenuItem(
            title: context.lang.removeAdmin,
            onTap: () => _removeContactAsAdmin(context),
            icon: FontAwesomeIcons.key,
          ),
        if (group.isGroupAdmin)
          ContextMenuItem(
            title: context.lang.removeFromGroup,
            onTap: () => _removeContactFromGroup(context),
            icon: FontAwesomeIcons.rightFromBracket,
          ),
      ],
      child: child,
    );
  }
}
