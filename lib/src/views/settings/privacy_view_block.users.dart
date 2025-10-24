import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/user_context_menu.component.dart';

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
              ),
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
      (a, b) => getContactDisplayName(a).compareTo(getContactDisplayName(b)),
    );

    return ListView.builder(
      restorationId: 'new_message_users_list',
      itemCount: users.length,
      itemBuilder: (BuildContext context, int i) {
        final user = users[i];
        return UserContextMenu(
          contact: user,
          child: ListTile(
            title: Row(
              children: [
                Text(getContactDisplayName(user)),
              ],
            ),
            leading: AvatarIcon(contact: user, fontSize: 15),
            trailing: Checkbox(
              value: user.blocked,
              onChanged: (bool? value) async {
                await block(context, user.userId, value);
              },
            ),
            onTap: () async {
              await block(context, user.userId, !user.blocked);
            },
          ),
        );
      },
    );
  }
}
