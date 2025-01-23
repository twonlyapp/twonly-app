import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/utils.dart';
import 'package:twonly/src/views/search_username_view.dart';

class NewMessageView extends StatefulWidget {
  const NewMessageView({super.key});

  @override
  State<NewMessageView> createState() => _NewMessageView();
}

class _NewMessageView extends State<NewMessageView> {
  List<Contact> _knownUsers = [];
  List<Contact> _filteredUsers = [];
  String _lastSearchQuery = '';
  final TextEditingController searchUserName = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await DbContacts.getUsers();
    setState(() {
      _knownUsers = users;
      _filteredUsers = List.from(_knownUsers);
    });
  }

  Future _filterUsers(String query) async {
    if (query.isEmpty) {
      _filteredUsers = List.from(_knownUsers);
      return;
    }
    if (_lastSearchQuery.length < query.length) {
      _filteredUsers = _knownUsers
          .where((user) =>
              user.displayName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } else {
      _filteredUsers = _filteredUsers
          .where((user) =>
              user.displayName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    _lastSearchQuery = query;
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration getInputDecoration(hintText) {
      final primaryColor =
          Theme.of(context).colorScheme.primary; // Get the primary color
      return InputDecoration(
        hintText: hintText,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9.0),
          borderSide: BorderSide(color: primaryColor, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline, width: 1.0),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.newMessageTitle),
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
                        AppLocalizations.of(context)!.newMessageTitle))),
            const SizedBox(height: 10),
            // Step 4: Add buttons at the top
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton(
                  onPressed: () {
                    // Handle Neue Gruppe button press
                  },
                  child: Text('Neue Gruppe'),
                ),
                FilledButton(
                  onPressed: () {
                    // Handle Nach Nutzername suchen button press
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SearchUsernameView()),
                    );
                  },
                  child: Text('Nach Nutzername suchen'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: UserList(_filteredUsers),
            )
          ],
        ),
      ),
    );
  }
}

class UserList extends StatelessWidget {
  const UserList(this._knownUsers, {super.key});
  final List<Contact> _knownUsers;

  @override
  Widget build(BuildContext context) {
    // Step 1: Sort the users alphabetically
    _knownUsers.sort((a, b) => a.displayName.compareTo(b.displayName));

    // Step 2: Group users by their initials
    Map<String, List<String>> groupedUsers = {};
    for (var user in _knownUsers) {
      String initial = user.displayName[0].toUpperCase();
      if (!groupedUsers.containsKey(initial)) {
        groupedUsers[initial] = [];
      }
      groupedUsers[initial]!.add(user.displayName);
    }

    // Step 3: Create a list of sections
    List<MapEntry<String, List<String>>> sections =
        groupedUsers.entries.toList();

    return ListView.builder(
      restorationId: 'new_message_users_list',
      itemCount: sections.length,
      itemBuilder: (BuildContext context, int sectionIndex) {
        final section = sections[sectionIndex];
        final initial = section.key;
        final users = section.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header for the initial
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Text(
                initial,
                style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
              ),
            ),
            // List of users under this initial
            ...users.map((username) {
              return ListTile(
                title: Text(username),
                leading: createInitialsAvatar(
                    username, Theme.of(context).brightness == Brightness.dark),
                onTap: () {
                  // Handle tap
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
