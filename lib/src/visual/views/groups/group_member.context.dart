import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/core/bridge/groups.dart' as rust_groups;
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/context_menu/context_menu.helper.dart';
import 'package:twonly/src/visual/views/groups/group.view.dart';

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
      if (!await rust_groups.manageAdminState(
        groupId: group.groupId,
        contactId: contact.userId,
        remove: false,
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
      if (!await rust_groups.manageAdminState(
        groupId: group.groupId,
        contactId: contact.userId,
        remove: true,
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
      if (!await rust_groups.removeMemberFromGroup(
        groupId: group.groupId,
        contactId: contact.userId,
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
        accepted: Value(false),
        requested: Value(false),
        deletedByUser: Value(false),
      ),
    );
    await RustApi.sendEncryptedContent(
      contactId: member.contactId,
      content: EncryptedContent(
        contactRequest: EncryptedContent_ContactRequest(
          type: EncryptedContent_ContactRequest_Type.REQUEST,
        ),
      ).writeToBuffer(),
      onlySendIfNoReceiptsAreOpen: false,
      onlyReturnEncryptedData: false,
      blocking: true,
    );
    if (context.mounted) {
      showSnackbar(
        context,
        context.lang.contactRequestSend,
        level: SnackbarLevel.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // `late` so the ancestor lookup only runs if the menu is actually
    // opened, rather than once per row on every rebuild.
    late final navigator = Navigator.of(context);
    return ContextMenu(
      items: () => [
        if (contact.accepted)
          ContextMenuItem(
            title: context.lang.contextMenuOpenChat,
            onTap: () async {
              final directChat = await twonlyDB.groupsDao.getDirectChat(
                contact.userId,
              );
              if (directChat == null) {
                // create
                return;
              }
              if (!navigator.mounted) return;
              await navigator.context.push(
                Routes.chatsMessages(directChat.groupId),
              );
            },
            icon: FontAwesomeIcons.message,
          ),
        if (!contact.accepted)
          ContextMenuItem(
            title: context.lang.createContactRequest,
            onTap: () => _makeContactRequest(navigator.context),
            icon: FontAwesomeIcons.userPlus,
          ),
        if (member.groupPublicKey != null &&
            group.isGroupAdmin &&
            (member.memberState ?? MemberState.normal) == MemberState.normal)
          ContextMenuItem(
            title: context.lang.makeAdmin,
            onTap: () => _makeContactAdmin(navigator.context),
            icon: FontAwesomeIcons.key,
          ),
        if (member.groupPublicKey != null &&
            group.isGroupAdmin &&
            member.memberState == MemberState.admin)
          ContextMenuItem(
            title: context.lang.removeAdmin,
            onTap: () => _removeContactAsAdmin(navigator.context),
            icon: FontAwesomeIcons.key,
          ),
        if (group.isGroupAdmin)
          ContextMenuItem(
            title: context.lang.removeFromGroup,
            onTap: () => _removeContactFromGroup(navigator.context),
            icon: FontAwesomeIcons.rightFromBracket,
          ),
      ],
      child: child,
    );
  }
}
