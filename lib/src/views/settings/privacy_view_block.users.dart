import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/initialsavatar.dart';
import 'package:twonly/src/views/components/user_context_menu.dart';

class PrivacyViewBlockUsers extends StatefulWidget {
  const PrivacyViewBlockUsers({super.key});

  @override
  State<PrivacyViewBlockUsers> createState() => _PrivacyViewBlockUsers();
}

class _PrivacyViewBlockUsers extends State<PrivacyViewBlockUsers> {
  late Stream<List<Contact>> allUsers;
  List<Contact> filteredUsers = [];
  String filter = '';

  @override
  void initState() {
    super.initState();
    allUsers = twonlyDB.contactsDao.watchAllContacts();
    loadAsync();
  }

  Future<void> loadAsync() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsPrivacyBlockUsers),
      ),
      body: PieCanvas(
        theme: getPieCanvasTheme(context),
        child: Padding(
          padding:
              const EdgeInsets.only(bottom: 20, left: 10, top: 20, right: 10),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  onChanged: (value) => setState(() {
                    filter = value;
                  }),
                  decoration: getInputDecoration(
                    context,
                    context.lang.searchUsernameInput,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.lang.settingsPrivacyBlockUsersDesc,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Expanded(
                child: StreamBuilder(
                  stream: allUsers,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container();
                    }

                    final filteredContacts = snapshot.data!.where((contact) {
                      return getContactDisplayName(contact)
                          .toLowerCase()
                          .contains(filter.toLowerCase());
                    }).toList();

                    return UserList(
                      List.from(filteredContacts),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class UserList extends StatelessWidget {
  const UserList(this.users, {super.key});
  final List<Contact> users;

  Future<void> block(BuildContext context, int userId, bool? value) async {
    if (value != null) {
      final update = ContactsCompanion(blocked: Value(value));
      await twonlyDB.contactsDao.updateContact(userId, update);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Step 1: Sort the users alphabetically
    users.sort(
        (a, b) => getContactDisplayName(a).compareTo(getContactDisplayName(b)));

    return ListView.builder(
      restorationId: 'new_message_users_list',
      itemCount: users.length,
      itemBuilder: (BuildContext context, int i) {
        final user = users[i];
        return UserContextMenuBlocked(
          contact: user,
          child: ListTile(
            title: Row(children: [
              Text(getContactDisplayName(user)),
            ]),
            leading: ContactAvatar(contact: user, fontSize: 15),
            trailing: Checkbox(
              value: user.blocked,
              onChanged: (bool? value) {
                block(context, user.userId, value);
              },
            ),
            onTap: () {
              block(context, user.userId, !user.blocked);
            },
          ),
        );
      },
    );
  }
}
