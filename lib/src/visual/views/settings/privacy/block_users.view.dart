import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/src/utils/contact_name.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/context_menu/user.context_menu.dart';
import 'package:twonly/src/visual/decorations/input_text.decoration.dart';

class BlockUsersView extends StatefulWidget {
  const BlockUsersView({super.key});

  @override
  State<BlockUsersView> createState() => _PrivacyViewBlockUsers();
}

class _PrivacyViewBlockUsers extends State<BlockUsersView> {
  late Stream<List<Contact>> allUsers;
  List<Contact> filteredUsers = [];
  String filter = '';

  @override
  void initState() {
    super.initState();
    allUsers = watchRustDatabase(
      (control) => rust_contacts.watchContacts(
        input: db_contacts.ContactQuery(
          filter: db_contacts.ContactFilter.all,
          ids: Int64List(0),
        ),
        control: control,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsPrivacyBlockUsers),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          bottom: 20,
          left: 10,
          top: 20,
          right: 10,
        ),
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
                    return getContactDisplayName(
                      contact,
                    ).toLowerCase().contains(filter.toLowerCase());
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
    );
  }
}

class UserList extends StatelessWidget {
  const UserList(this.users, {super.key});
  final List<Contact> users;

  Future<void> block(BuildContext context, int userId, bool? value) async {
    if (value != null) {
      final update = ContactPatch(blocked: value);
      await rust_contacts.updateContact(
        id: userId,
        patch: update,
        transaction: currentDatabaseSession(),
      );
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
      itemBuilder: (context, i) {
        final user = users[i];
        return UserContextMenu(
          key: ValueKey(user.userId),
          contact: user,
          child: ListTile(
            title: Row(
              children: [
                Text(getContactDisplayName(user)),
              ],
            ),
            leading: AvatarIcon(contactId: user.userId, fontSize: 15),
            trailing: Checkbox.adaptive(
              value: user.blocked,
              onChanged: (value) async {
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
