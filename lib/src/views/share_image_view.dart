import 'dart:collection';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twonly/src/components/best_friends_selector.dart';
import 'package:twonly/src/components/headline.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/utils/misc.dart';

class ShareImageView extends StatefulWidget {
  const ShareImageView({super.key, required this.image});
  final String image;

  @override
  State<ShareImageView> createState() => _ShareImageView();
}

class _ShareImageView extends State<ShareImageView> {
  List<Contact> _users = [];
  List<Contact> _usersFiltered = [];
  final HashSet<Int64> _selectedUserIds = HashSet<Int64>();
  String _lastSearchQuery = '';
  final TextEditingController searchUserName = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await DbContacts.getActiveUsers();
    setState(() {
      _users = users;
      _usersFiltered = _users;
    });
  }

  Future _filterUsers(String query) async {
    if (query.isEmpty) {
      _usersFiltered = _users;
      return;
    }
    if (_lastSearchQuery.length < query.length) {
      _usersFiltered = _users
          .where((user) =>
              user.displayName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } else {
      _usersFiltered = _usersFiltered
          .where((user) =>
              user.displayName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    _lastSearchQuery = query;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.shareImageTitle),
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: 20, left: 10, top: 20, right: 10),
        child: Column(
          children: [
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                    onChanged: _filterUsers,
                    decoration: getInputDecoration(context,
                        AppLocalizations.of(context)!.searchUsernameInput))),
            const SizedBox(height: 10),
            BestFriendsSelector(
              users: _usersFiltered,
              selectedUserIds: _selectedUserIds,
              updateStatus: (userId, checked) {
                if (checked) {
                  _selectedUserIds.add(userId);
                } else {
                  _selectedUserIds.remove(userId);
                }
              },
            ),
            const SizedBox(height: 10),
            HeadLineComponent(AppLocalizations.of(context)!.shareImageAllUsers),
            Expanded(
              child: UserList(_usersFiltered),
            )
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        height: 120,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                icon: Icon(Icons.send),
                onPressed: () async {
                  print(_selectedUserIds);
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //       builder: (context) =>
                  //           ShareImageView(image: widget.image)),
                  // );
                },
                style: ButtonStyle(
                  padding: WidgetStateProperty.all<EdgeInsets>(
                    EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                  ),
                ),
                label: Text(
                  AppLocalizations.of(context)!.shareImagedEditorSendImage,
                  style: TextStyle(fontSize: 17),
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
            // Padding(
            //   padding:
            //       const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            //   child: Text(
            //     initial,
            //     style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
            //   ),
            // ),
            // List of users under this initial
            ...users.map((username) {
              return ListTile(
                title: Text(username),
                leading: InitialsAvatar(
                  displayName: username,
                  fontSize: 15,
                ),
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
