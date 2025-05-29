import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/views/components/flame.dart';
import 'package:twonly/src/views/components/initialsavatar.dart';
import 'package:twonly/src/views/components/user_context_menu.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_messages_view.dart';
import 'package:twonly/src/views/chats/search_username_view.dart';

class StartNewChat extends StatefulWidget {
  const StartNewChat({super.key});
  @override
  State<StartNewChat> createState() => _StartNewChat();
}

class _StartNewChat extends State<StartNewChat> {
  List<Contact> contacts = [];
  List<Contact> allContacts = [];
  final TextEditingController searchUserName = TextEditingController();
  late StreamSubscription<List<Contact>> contactSub;

  @override
  void initState() {
    super.initState();

    Stream<List<Contact>> stream =
        twonlyDatabase.contactsDao.watchContactsForShareView();

    contactSub = stream.listen((update) {
      update.sort((a, b) =>
          getContactDisplayName(a).compareTo(getContactDisplayName(b)));
      setState(() {
        allContacts = update;
      });
      filterUsers();
    });
  }

  @override
  void dispose() {
    super.dispose();
    contactSub.cancel();
  }

  Future filterUsers() async {
    if (searchUserName.value.text.isEmpty) {
      setState(() {
        contacts = allContacts;
      });
      return;
    }
    List<Contact> usersFiltered = allContacts
        .where((user) => getContactDisplayName(user)
            .toLowerCase()
            .contains(searchUserName.value.text.toLowerCase()))
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
        child: PieCanvas(
          theme: getPieCanvasTheme(context),
          child: Padding(
            padding: EdgeInsets.only(bottom: 40, left: 10, top: 20, right: 10),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    onChanged: (_) {
                      filterUsers();
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
                )
              ],
            ),
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
            key: Key("add_new_contact"),
            title: Text(context.lang.startNewChatNewContact),
            leading: CircleAvatar(
              child: FaIcon(
                FontAwesomeIcons.userPlus,
                size: 13,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchUsernameView(),
                ),
              );
            },
          );
        }
        if (i == 1) {
          return Divider();
        }
        Contact user = users[i - 2];
        int flameCounter = getFlameCounterFromContact(user);
        return UserContextMenu(
          key: Key(user.userId.toString()),
          contact: user,
          child: ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(getContactDisplayName(user)),
                if (flameCounter >= 1)
                  FlameCounterWidget(
                    user,
                    flameCounter,
                    prefix: true,
                  ),
                Spacer(),
                IconButton(
                    icon: FaIcon(FontAwesomeIcons.boxOpen,
                        size: 13,
                        color: user.archived ? null : Colors.transparent),
                    onPressed: user.archived
                        ? () async {
                            final update =
                                ContactsCompanion(archived: Value(false));
                            await twonlyDatabase.contactsDao
                                .updateContact(user.userId, update);
                          }
                        : null)
              ],
            ),
            leading: ContactAvatar(
              contact: user,
              fontSize: 13,
            ),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) {
                  return ChatMessagesView(user);
                }),
              );
            },
          ),
        );
      },
    );
  }
}
