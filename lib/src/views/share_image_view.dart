import 'dart:collection';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/components/best_friends_selector.dart';
import 'package:twonly/src/components/flame.dart';
import 'package:twonly/src/components/headline.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/home_view.dart';

class ShareImageView extends StatefulWidget {
  const ShareImageView({super.key, required this.imageBytes});
  final Uint8List imageBytes;

  @override
  State<ShareImageView> createState() => _ShareImageView();
}

class _ShareImageView extends State<ShareImageView> {
  List<Contact> _users = [];
  List<Contact> _otherUsers = [];
  List<Contact> _bestFriends = [];
  int maxTotalMediaCounter = 0;
  final HashSet<Int64> _selectedUserIds = HashSet<Int64>();
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
      _updateUsers(_users);
    });
  }

  Future _updateUsers(List<Contact> users) async {
    // Sort contacts by flameCounter and then by totalMediaCounter
    users.sort((a, b) {
      // First, compare by flameCounter
      int flameComparison = b.flameCounter.compareTo(a.flameCounter);
      if (flameComparison != 0) {
        return flameComparison; // Sort by flameCounter in descending order
      }
      // If flameCounter is the same, compare by totalMediaCounter
      return b.totalMediaCounter.compareTo(
          a.totalMediaCounter); // Sort by totalMediaCounter in descending order
    });

    maxTotalMediaCounter = 0;
    if (users.isNotEmpty) {
      maxTotalMediaCounter =
          users.map((x) => x.totalMediaCounter).reduce((a, b) => a > b ? a : b);
    }

    // Separate best friends and other users
    List<Contact> bestFriends = [];
    List<Contact> otherUsers = [];

    for (var contact in users) {
      if (contact.flameCounter > 0 && bestFriends.length < 6) {
        bestFriends.add(contact);
      } else {
        otherUsers.add(contact);
      }
    }

    setState(() {
      _bestFriends = bestFriends;
      _otherUsers = otherUsers;
    });
  }

  Future _filterUsers(String query) async {
    if (query.isEmpty) {
      _updateUsers(_users);
      return;
    }
    List<Contact> usersFiltered = _users
        .where((user) =>
            user.displayName.toLowerCase().contains(query.toLowerCase()))
        .toList();
    _updateUsers(usersFiltered);
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
              users: _bestFriends,
              selectedUserIds: _selectedUserIds,
              maxTotalMediaCounter: maxTotalMediaCounter,
              updateStatus: (userId, checked) {
                if (checked) {
                  _selectedUserIds.add(userId);
                } else {
                  _selectedUserIds.remove(userId);
                }
              },
            ),
            const SizedBox(height: 10),
            if (_otherUsers.isNotEmpty)
              HeadLineComponent(
                  AppLocalizations.of(context)!.shareImageAllUsers),
            Expanded(
              child: UserList(
                List.from(_otherUsers),
                maxTotalMediaCounter,
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
                icon: FaIcon(FontAwesomeIcons.solidPaperPlane),
                onPressed: () async {
                  sendImage(_selectedUserIds.toList(), widget.imageBytes);

                  // TODO: pop back to the HomeView page popUntil did not work. check later how to improve in case of pushing more then 2
                  Navigator.pop(context);
                  Navigator.pop(context);
                  globalUpdateOfHomeViewPageIndex(0);
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
  const UserList(this.users, this.maxTotalMediaCounter,
      {super.key, required this.selectedUserIds});
  final List<Contact> users;
  final int maxTotalMediaCounter;
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
          title: Row(children: [
            Text(user.displayName),
            if (user.flameCounter > 0)
              FlameCounterWidget(user, maxTotalMediaCounter),
          ]),
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
