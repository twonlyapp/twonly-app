import 'package:flutter/material.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/utils/misc.dart';

class PrivacyViewBlockUsers extends StatefulWidget {
  const PrivacyViewBlockUsers({super.key});

  @override
  State<PrivacyViewBlockUsers> createState() => _PrivacyViewBlockUsers();
}

class _PrivacyViewBlockUsers extends State<PrivacyViewBlockUsers> {
  List<Contact> allUsers = [];
  List<Contact> filteredUsers = [];
  String lastQuery = "";

  @override
  void initState() {
    super.initState();
    loadAsync();
  }

  Future loadAsync() async {
    allUsers = await DbContacts.getAllUsers();
    _filterUsers(lastQuery);
  }

  Future _filterUsers(String query) async {
    lastQuery = query;
    if (query.isEmpty) {
      filteredUsers = allUsers;
      return;
    }
    filteredUsers = allUsers
        .where((user) =>
            user.displayName.toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsPrivacyBlockUsers),
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: 20, left: 10, top: 20, right: 10),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                onChanged: _filterUsers,
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
              child: UserList(
                List.from(filteredUsers),
                updateStatus: () {
                  loadAsync();
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class UserList extends StatelessWidget {
  const UserList(this.users, {super.key, required this.updateStatus});
  final List<Contact> users;
  final Function updateStatus;

  Future block(bool? value, int userId) async {
    if (value == null) return;
    await DbContacts.blockUser(userId, unblock: !value);
    updateStatus();
  }

  @override
  Widget build(BuildContext context) {
    // Step 1: Sort the users alphabetically
    users.sort((a, b) => a.displayName.compareTo(b.displayName));

    return ListView.builder(
      restorationId: 'new_message_users_list',
      itemCount: users.length,
      itemBuilder: (BuildContext context, int i) {
        Contact user = users[i];
        print(user.blocked);
        return ListTile(
          title: Row(children: [
            Text(user.displayName),
          ]),
          leading: InitialsAvatar(
            displayName: user.displayName,
            fontSize: 15,
          ),
          trailing: Checkbox(
            value: user.blocked,
            onChanged: (bool? value) {
              print(value);
              block(value, user.userId.toInt());
            },
          ),
          onTap: () {
            block(!user.blocked, user.userId.toInt());
          },
        );
      },
    );
  }
}
