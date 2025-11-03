import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/flame.dart';
import 'package:twonly/src/views/components/user_context_menu.component.dart';
import 'package:twonly/src/views/groups/group_create_select_group_name.view.dart';

class GroupCreateSelectMembersView extends StatefulWidget {
  const GroupCreateSelectMembersView({this.group, super.key});
  final Group? group;
  @override
  State<GroupCreateSelectMembersView> createState() => _StartNewChatView();
}

class _StartNewChatView extends State<GroupCreateSelectMembersView> {
  List<Contact> contacts = [];
  List<Contact> allContacts = [];
  final TextEditingController searchUserName = TextEditingController();
  late StreamSubscription<List<Contact>> contactSub;

  final HashSet<int> selectedUsers = HashSet();
  final HashSet<int> alreadyInGroup = HashSet();

  @override
  void initState() {
    super.initState();

    final stream = twonlyDB.contactsDao.watchAllAcceptedContacts();

    contactSub = stream.listen((update) async {
      update.sort(
        (a, b) => getContactDisplayName(a).compareTo(getContactDisplayName(b)),
      );
      setState(() {
        allContacts = update;
      });
      await filterUsers();
    });
    initAsync();
  }

  Future<void> initAsync() async {
    if (widget.group != null) {
      final members =
          await twonlyDB.groupsDao.getGroupContact(widget.group!.groupId);
      for (final member in members) {
        alreadyInGroup.add(member.userId);
      }
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    unawaited(contactSub.cancel());
    super.dispose();
  }

  Future<void> filterUsers() async {
    if (searchUserName.value.text.isEmpty) {
      setState(() {
        contacts = allContacts;
      });
      return;
    }
    final usersFiltered = allContacts
        .where(
          (user) => getContactDisplayName(user)
              .toLowerCase()
              .contains(searchUserName.value.text.toLowerCase()),
        )
        .toList();
    setState(() {
      contacts = usersFiltered;
    });
  }

  void toggleSelectedUser(int userId) {
    if (alreadyInGroup.contains(userId)) return;
    if (!selectedUsers.contains(userId)) {
      selectedUsers.add(userId);
    } else {
      selectedUsers.remove(userId);
    }
    setState(() {});
  }

  Future<void> submitChanges() async {
    if (widget.group != null) {
      Navigator.pop(context, selectedUsers.toList());
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupCreateSelectGroupNameView(
          selectedUsers: allContacts
              .where((t) => selectedUsers.contains(t.userId))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.group == null
                ? context.lang.selectMembers
                : context.lang.addMember,
          ),
        ),
        floatingActionButton: FilledButton.icon(
          onPressed: selectedUsers.isEmpty ? null : submitChanges,
          label: Text(
            widget.group == null ? context.lang.next : context.lang.updateGroup,
          ),
          icon: const FaIcon(FontAwesomeIcons.penToSquare),
        ),
        body: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.only(bottom: 40, left: 10, top: 20, right: 10),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    onChanged: (_) async {
                      await filterUsers();
                    },
                    controller: searchUserName,
                    decoration: getInputDecoration(
                      context,
                      context.lang.shareImageSearchAllContacts,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    restorationId: 'new_message_users_list',
                    itemCount:
                        contacts.length + (selectedUsers.isEmpty ? 0 : 2),
                    itemBuilder: (BuildContext context, int i) {
                      if (selectedUsers.isNotEmpty) {
                        final selected = selectedUsers.toList();
                        if (i == 0) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            constraints: const BoxConstraints(
                              maxHeight: 150,
                            ),
                            child: SingleChildScrollView(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Wrap will use the available width from constraints.maxWidth
                                  return Wrap(
                                    spacing: 8,
                                    children: selected.map((w) {
                                      return _Chip(
                                        contact: allContacts
                                            .firstWhere((t) => t.userId == w),
                                        onTap: toggleSelectedUser,
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                        if (i == 1) {
                          return const Divider();
                        }
                        i -= 2;
                      }
                      final user = contacts[i];
                      return UserContextMenu(
                        key: GlobalKey(),
                        contact: user,
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(getContactDisplayName(user)),
                              FlameCounterWidget(
                                contactId: user.userId,
                                prefix: true,
                              ),
                            ],
                          ),
                          subtitle: (alreadyInGroup.contains(user.userId))
                              ? Text(context.lang.alreadyInGroup)
                              : null,
                          leading: AvatarIcon(
                            contactId: user.userId,
                            fontSize: 13,
                          ),
                          trailing: Checkbox(
                            value: selectedUsers.contains(user.userId) |
                                alreadyInGroup.contains(user.userId),
                            side: WidgetStateBorderSide.resolveWith(
                              (states) {
                                if (states.contains(WidgetState.selected)) {
                                  return const BorderSide(width: 0);
                                }
                                return BorderSide(
                                  color: Theme.of(context).colorScheme.outline,
                                );
                              },
                            ),
                            onChanged: (bool? value) {
                              toggleSelectedUser(user.userId);
                            },
                          ),
                          onTap: () {
                            toggleSelectedUser(user.userId);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.contact,
    required this.onTap,
  });
  final Contact contact;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(contact.userId),
      child: Chip(
        avatar: AvatarIcon(
          contactId: contact.userId,
          fontSize: 10,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              getContactDisplayName(contact),
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 15),
            const FaIcon(
              FontAwesomeIcons.xmark,
              color: Colors.grey,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}
