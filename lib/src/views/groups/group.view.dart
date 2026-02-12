import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/group.services.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/better_list_title.dart';
import 'package:twonly/src/views/components/select_chat_deletion_time.comp.dart';
import 'package:twonly/src/views/components/verified_shield.dart';
import 'package:twonly/src/views/contact/contact.view.dart';
import 'package:twonly/src/views/groups/group_create_select_members.view.dart';
import 'package:twonly/src/views/groups/group_member.context.dart';
import 'package:twonly/src/views/settings/profile/profile.view.dart';

class GroupView extends StatefulWidget {
  const GroupView(this.groupId, {super.key});

  final String groupId;

  @override
  State<GroupView> createState() => _GroupViewState();
}

class _GroupViewState extends State<GroupView> {
  Group? _group;

  List<(Contact, GroupMember)> members = [];

  late StreamSubscription<Group?> groupSub;
  late StreamSubscription<List<(Contact, GroupMember)>> membersSub;

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  @override
  void dispose() {
    groupSub.cancel();
    membersSub.cancel();
    super.dispose();
  }

  Future<void> initAsync() async {
    final groupStream = twonlyDB.groupsDao.watchGroup(widget.groupId);
    groupSub = groupStream.listen((update) {
      if (update != null) {
        setState(() {
          _group = update;
        });
      }
    });
    final membersStream = twonlyDB.groupsDao.watchGroupMembers(widget.groupId);
    membersSub = membersStream.listen((update) {
      setState(() {
        members = update;
        members.sort(
          (b, a) => a.$2.memberState!.index.compareTo(b.$2.memberState!.index),
        );
      });
    });
  }

  Future<void> _updateGroupName() async {
    final newGroupName = await showGroupNameChangeDialog(context, _group!);

    if (context.mounted &&
        newGroupName != null &&
        newGroupName != '' &&
        newGroupName != _group!.groupName) {
      if (!await updateGroupName(_group!, newGroupName)) {
        if (mounted) {
          showNetworkIssue(context);
        }
      }
    }
  }

  Future<void> _addNewGroupMembers() async {
    final selectedUserIds = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupCreateSelectMembersView(
          groupId: _group?.groupId,
        ),
      ),
    ) as List<int>?;
    if (selectedUserIds == null) return;
    if (!await addNewGroupMembers(_group!, selectedUserIds)) {
      if (mounted) {
        showNetworkIssue(context);
      }
    }
  }

  Future<void> _leaveGroup() async {
    final ok = await showAlertDialog(
      context,
      context.lang.leaveGroupSureTitle,
      context.lang.leaveGroupSureBody,
      customOk: context.lang.leaveGroupSureOkBtn,
    );
    if (!ok) return;

    // 1. Check if I am the only admin, while there are still normal members
    // -> ERROR first select new admin

    if (members.isNotEmpty) {
      // In case there are other members, check that there is at least one other admin before I leave the group.

      if (_group!.isGroupAdmin) {
        if (!members.any((m) => m.$2.memberState == MemberState.admin)) {
          if (!mounted) return;
          await showAlertDialog(
            context,
            context.lang.leaveGroupSelectOtherAdminTitle,
            context.lang.leaveGroupSelectOtherAdminBody,
            customCancel: '',
          );
          return;
        }
      }
    }

    late bool success;

    if (_group!.isGroupAdmin) {
      // Current user is a admin, to the state can be updated by the user him self.
      final keyPair =
          IdentityKeyPair.fromSerialized(_group!.myGroupPrivateKey!);
      success = await removeMemberFromGroup(
        _group!,
        keyPair.getPublicKey().serialize(),
        gUser.userId,
      );
    } else {
      success = await leaveAsNonAdminFromGroup(_group!);
    }

    if (!success) {
      if (mounted) {
        showNetworkIssue(context);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_group == null) {
      return Container();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: AvatarIcon(
              group: _group,
              fontSize: 30,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: VerifiedShield(key: Key(_group!.groupId), group: _group),
              ),
              Text(
                substringBy(_group!.groupName, 25),
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 50),
          if (_group!.isGroupAdmin && !_group!.leftGroup)
            BetterListTile(
              icon: FontAwesomeIcons.pencil,
              text: context.lang.groupNameInput,
              onTap: _updateGroupName,
            ),
          SelectChatDeletionTimeListTitle(
            groupId: widget.groupId,
            disabled: !_group!.isGroupAdmin,
          ),
          const Divider(),
          ListTile(
            title: Padding(
              padding: const EdgeInsets.only(left: 17),
              child: Text(
                '${members.length + 1} ${context.lang.groupMembers}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_group!.isGroupAdmin && !_group!.leftGroup)
            BetterListTile(
              icon: FontAwesomeIcons.plus,
              text: context.lang.addMember,
              onTap: _addNewGroupMembers,
            ),
          BetterListTile(
            padding: const EdgeInsets.only(left: 13),
            leading: const AvatarIcon(
              myAvatar: true,
              fontSize: 16,
            ),
            text: context.lang.you,
            trailing: (_group!.isGroupAdmin) ? Text(context.lang.admin) : null,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileView(),
                ),
              );
            },
          ),
          ...members.map((member) {
            return GroupMemberContextMenu(
              key: ValueKey(member.$1.userId),
              group: _group!,
              contact: member.$1,
              member: member.$2,
              child: BetterListTile(
                padding: const EdgeInsets.only(left: 13),
                leading: AvatarIcon(
                  contactId: member.$1.userId,
                  fontSize: 16,
                ),
                text: getContactDisplayName(member.$1, maxLength: 25),
                trailing: (member.$2.memberState == MemberState.admin)
                    ? Text(context.lang.admin)
                    : null,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ContactView(member.$1.userId),
                    ),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),
          if (!_group!.leftGroup)
            BetterListTile(
              icon: FontAwesomeIcons.rightFromBracket,
              color: Colors.red,
              text: context.lang.leaveGroup,
              onTap: _leaveGroup,
            )
          else
            ListTile(
              title: Padding(
                padding: const EdgeInsets.only(left: 17),
                child: Text(
                  context.lang.groupYouAreNowLongerAMember,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<String?> showGroupNameChangeDialog(
  BuildContext context,
  Group group,
) {
  final controller = TextEditingController(text: group.groupName);

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(context.lang.groupNameInput),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: context.lang.groupNameInput),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(context.lang.cancel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(context.lang.ok),
            onPressed: () {
              Navigator.of(context).pop(controller.text);
            },
          ),
        ],
      );
    },
  );
}

void showNetworkIssue(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.lang.groupNetworkIssue),
      duration: const Duration(seconds: 3),
    ),
  );
}
