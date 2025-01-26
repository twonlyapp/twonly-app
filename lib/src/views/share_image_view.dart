import 'dart:collection';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/components/best_friends_selector.dart';
import 'package:twonly/src/components/headline.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/providers/notify_provider.dart';
import 'package:twonly/src/utils/api.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/home_view.dart';

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
            if (_usersFiltered.isNotEmpty)
              HeadLineComponent(
                  AppLocalizations.of(context)!.shareImageAllUsers),
            Expanded(
              child: UserList(
                List.from(_usersFiltered),
                selectedUserIds: _selectedUserIds,
              ),
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
                  sendImage(
                      context,
                      _users
                          .where((c) => _selectedUserIds.contains(c.userId))
                          .toList(),
                      widget.image);

                  Navigator.pop(context);
                  Navigator.pop(context);
                  context.read<NotifyProvider>().setActivePageIdx(0);
                  homeViewPageController.jumpToPage(0);
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
  const UserList(this.users, {super.key, required this.selectedUserIds});
  final List<Contact> users;
  final HashSet<Int64> selectedUserIds;

  @override
  Widget build(BuildContext context) {
    // Step 1: Sort the users alphabetically
    users.sort((a, b) => a.displayName.compareTo(b.displayName));

    return ListView.builder(
      restorationId: 'new_message_users_list',
      itemCount: users.length,
      itemBuilder: (BuildContext context, int i) {
        Contact user = users[i];
        return ListTile(
          title: Text(user.displayName),
          leading: InitialsAvatar(
            displayName: user.displayName,
            fontSize: 15,
          ),
          trailing: Checkbox(
            value: selectedUserIds.contains(user.userId),
            onChanged: (bool? value) {
              if (value == null) return;
              if (value) {
                selectedUserIds.add(user.userId);
              } else {
                selectedUserIds.remove(user.userId);
              }
            },
          ),
          onTap: () {
            if (!selectedUserIds.contains(user.userId)) {
              selectedUserIds.add(user.userId);
            } else {
              selectedUserIds.remove(user.userId);
            }
          },
        );
      },
    );
  }
}
