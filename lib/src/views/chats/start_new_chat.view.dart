import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/add_new_user.view.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/flame.dart';
import 'package:twonly/src/views/components/group_context_menu.component.dart';
import 'package:twonly/src/views/components/user_context_menu.component.dart';
import 'package:twonly/src/views/groups/group_create_select_members.view.dart';

class StartNewChatView extends StatefulWidget {
  const StartNewChatView({super.key});
  @override
  State<StartNewChatView> createState() => _StartNewChatView();
}

class _StartNewChatView extends State<StartNewChatView> {
  List<Contact> filteredContacts = [];
  List<Group> filteredGroups = [];
  List<Contact> allContacts = [];
  List<Group> allNonDirectGroups = [];
  final TextEditingController searchUserName = TextEditingController();
  late StreamSubscription<List<Contact>> contactSub;
  late StreamSubscription<List<Group>> allNonDirectGroupsSub;

  @override
  void initState() {
    super.initState();

    contactSub =
        twonlyDB.contactsDao.watchAllAcceptedContacts().listen((update) async {
      update.sort(
        (a, b) => getContactDisplayName(a).compareTo(getContactDisplayName(b)),
      );
      setState(() {
        allContacts = update;
      });
      await filterUsers();
    });

    allNonDirectGroupsSub =
        twonlyDB.groupsDao.watchGroupsForStartNewChat().listen((update) async {
      setState(() {
        allNonDirectGroups = update;
      });
      await filterUsers();
    });
  }

  @override
  void dispose() {
    allNonDirectGroupsSub.cancel();
    contactSub.cancel();
    super.dispose();
  }

  Future<void> filterUsers() async {
    if (searchUserName.value.text.isEmpty) {
      setState(() {
        filteredContacts = allContacts;
        filteredGroups = [];
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
    final groupsFiltered = allNonDirectGroups
        .where(
          (g) => g.groupName
              .toLowerCase()
              .contains(searchUserName.value.text.toLowerCase()),
        )
        .toList();
    setState(() {
      filteredContacts = usersFiltered;
      filteredGroups = groupsFiltered;
    });
  }

  Future<void> _onTapUser(Contact user) async {
    var directChat = await twonlyDB.groupsDao.getDirectChat(user.userId);
    if (directChat == null) {
      await twonlyDB.groupsDao.createNewDirectChat(
        user.userId,
        GroupsCompanion(
          groupName: Value(
            getContactDisplayName(user),
          ),
        ),
      );
      directChat = await twonlyDB.groupsDao.getDirectChat(user.userId);
    }
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ChatMessagesView(directChat!);
        },
      ),
    );
  }

  Future<void> _onTapGroup(Group group) async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ChatMessagesView(group);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.startNewChatTitle),
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
                    context.lang.startNewChatSearchHint,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  restorationId: 'new_message_users_list',
                  itemCount:
                      filteredContacts.length + 3 + filteredGroups.length,
                  itemBuilder: (BuildContext context, int i) {
                    if (searchUserName.text.isEmpty) {
                      if (i == 0) {
                        return ListTile(
                          title: Text(context.lang.newGroup),
                          leading: const CircleAvatar(
                            child: FaIcon(
                              FontAwesomeIcons.userGroup,
                              size: 13,
                            ),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const GroupCreateSelectMembersView(),
                              ),
                            );
                          },
                        );
                      }
                      if (i == 1) {
                        return ListTile(
                          title: Text(context.lang.startNewChatNewContact),
                          leading: const CircleAvatar(
                            child: FaIcon(
                              FontAwesomeIcons.userPlus,
                              size: 13,
                            ),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddNewUserView(),
                              ),
                            );
                          },
                        );
                      }
                      if (i == 2) {
                        return const Divider();
                      }
                      i = i - 3;
                    } else {
                      if (i == 0) {
                        return filteredContacts.isNotEmpty
                            ? ListTile(
                                title: Text(
                                  context.lang.contacts,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : Container();
                      } else {
                        i -= 1;
                      }
                    }

                    if (i < filteredContacts.length) {
                      return UserContextMenu(
                        key: Key(filteredContacts[i].userId.toString()),
                        contact: filteredContacts[i],
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(getContactDisplayName(filteredContacts[i])),
                              FlameCounterWidget(
                                contactId: filteredContacts[i].userId,
                                prefix: true,
                              ),
                            ],
                          ),
                          leading: AvatarIcon(
                            contactId: filteredContacts[i].userId,
                            fontSize: 13,
                          ),
                          onTap: () => _onTapUser(filteredContacts[i]),
                        ),
                      );
                    }
                    i -= filteredContacts.length;

                    if (i == 0) {
                      return filteredGroups.isNotEmpty
                          ? ListTile(
                              title: Text(
                                context.lang.groups,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Container();
                    }

                    i -= 1;

                    if (i < filteredGroups.length) {
                      return GroupContextMenu(
                        key: Key(filteredGroups[i].groupId),
                        group: filteredGroups[i],
                        child: ListTile(
                          title: Text(
                            filteredGroups[i].groupName,
                          ),
                          leading: AvatarIcon(
                            group: filteredGroups[i],
                            fontSize: 13,
                          ),
                          onTap: () => _onTapGroup(filteredGroups[i]),
                        ),
                      );
                    }
                    return Container();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
