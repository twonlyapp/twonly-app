import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/group.services.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/better_list_title.dart';
import 'package:twonly/src/views/components/verified_shield.dart';
import 'package:twonly/src/views/contact/contact.view.dart';
import 'package:twonly/src/views/groups/group_create_select_members.view.dart';
import 'package:twonly/src/views/groups/group_member.context.dart';
import 'package:twonly/src/views/settings/profile/profile.view.dart';

class GroupView extends StatefulWidget {
  const GroupView(this.group, {super.key});

  final Group group;

  @override
  State<GroupView> createState() => _GroupViewState();
}

class _GroupViewState extends State<GroupView> {
  late Group group;

  List<(Contact, GroupMember)> members = [];

  late StreamSubscription<Group?> groupSub;
  late StreamSubscription<List<(Contact, GroupMember)>> membersSub;

  @override
  void initState() {
    group = widget.group;
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
    final groupStream = twonlyDB.groupsDao.watchGroup(widget.group.groupId);
    groupSub = groupStream.listen((update) {
      if (update != null) {
        setState(() {
          group = update;
        });
      }
    });
    final membersStream =
        twonlyDB.groupsDao.watchGroupMembers(widget.group.groupId);
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
    final newGroupName = await showGroupNameChangeDialog(context, group);

    if (context.mounted &&
        newGroupName != null &&
        newGroupName != '' &&
        newGroupName != group.groupName) {
      if (!await updateGroupeName(group, newGroupName)) {
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
        builder: (context) => GroupCreateSelectMembersView(group: group),
      ),
    ) as List<int>?;
    if (selectedUserIds == null) return;
    if (!await addNewGroupMembers(group, selectedUserIds)) {
      if (mounted) {
        showNetworkIssue(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: AvatarIcon(
              group: group,
              fontSize: 30,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: VerifiedShield(key: GlobalKey(), group: group),
              ),
              Text(
                substringBy(group.groupName, 25),
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 50),
          if (group.isGroupAdmin)
            BetterListTile(
              icon: FontAwesomeIcons.pencil,
              text: context.lang.groupNameInput,
              onTap: _updateGroupName,
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
          if (group.isGroupAdmin)
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
            trailing: (group.isGroupAdmin) ? Text(context.lang.admin) : null,
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
              group: group,
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
          BetterListTile(
            icon: FontAwesomeIcons.rightFromBracket,
            color: Colors.red,
            text: context.lang.leaveGroup,
            onTap: () => {},
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
    builder: (BuildContext context) {
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
    const SnackBar(
      content: Text('Network issue. Try again later.'),
      duration: Duration(seconds: 3),
    ),
  );
}
