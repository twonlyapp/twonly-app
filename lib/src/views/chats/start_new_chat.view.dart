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
import 'package:twonly/src/views/components/user_context_menu.component.dart';

class StartNewChatView extends StatefulWidget {
  const StartNewChatView({super.key});
  @override
  State<StartNewChatView> createState() => _StartNewChatView();
}

class _StartNewChatView extends State<StartNewChatView> {
  List<Contact> contacts = [];
  List<Contact> allContacts = [];
  final TextEditingController searchUserName = TextEditingController();
  late StreamSubscription<List<Contact>> contactSub;

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
                    context.lang.shareImageSearchAllContacts,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: UserList(
                  contacts,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserList extends StatelessWidget {
  const UserList(
    this.users, {
    super.key,
  });
  final List<Contact> users;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      restorationId: 'new_message_users_list',
      itemCount: users.length + 2,
      itemBuilder: (BuildContext context, int i) {
        if (i == 0) {
          return ListTile(
            key: const Key('add_new_contact'),
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
        if (i == 1) {
          return const Divider();
        }
        final user = users[i - 2];
        return UserContextMenu(
          key: Key(user.userId.toString()),
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
            leading: AvatarIcon(
              contact: user,
              fontSize: 13,
            ),
            onTap: () async {
              var directChat =
                  await twonlyDB.groupsDao.getDirectChat(user.userId);
              if (directChat == null) {
                await twonlyDB.groupsDao.createNewDirectChat(
                  user.userId,
                  GroupsCompanion(
                    groupName: Value(
                      getContactDisplayName(user),
                    ),
                  ),
                );
                directChat =
                    await twonlyDB.groupsDao.getDirectChat(user.userId);
              }
              if (!context.mounted) return;
              await Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return ChatMessagesView(directChat!);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
