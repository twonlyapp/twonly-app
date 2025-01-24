import 'dart:collection';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twonly/src/components/initialsavatar_component.dart';
import 'package:twonly/src/model/contacts_model.dart';

class ShareImageView extends StatefulWidget {
  const ShareImageView({super.key, required this.image});
  final String image;

  @override
  State<ShareImageView> createState() => _ShareImageView();
}

class _ShareImageView extends State<ShareImageView> {
  List<Contact> _knownUsers = [];
  final HashSet<Int64> _selectedUserIds = HashSet<Int64>();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await DbContacts.getUsers();
    setState(() {
      _knownUsers = users;
    });
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
            Container(
              alignment:
                  Alignment.centerLeft, // Aligns the container to the left
              padding: EdgeInsets.all(16.0), // Optional: Add some padding
              child: Text(
                'Best friends',
                style: TextStyle(
                  fontSize: 20, // Set the font size to 20
                ),
              ),
            ),
            UserCheckboxList(
                users: _knownUsers,
                onChanged: (userId, checkedId) {
                  setState(() {
                    if (checkedId) {
                      _selectedUserIds.add(userId);
                    } else {
                      _selectedUserIds.remove(userId);
                    }
                  });
                }),
            const SizedBox(height: 10),
            // Expanded(
            // child: UserList(_filteredUsers),
            // )
          ],
        ),
      ),
    );
  }
}

class UserCheckboxList extends StatelessWidget {
  final List<Contact> users;
  final Function(Int64, bool) onChanged;

  const UserCheckboxList(
      {super.key, required this.users, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Limit the number of users to 8
    final limitedUsers = users.length > 8 ? users.sublist(0, 8) : users;

    return Column(
      children: List.generate((limitedUsers.length + 1) ~/ 2, (rowIndex) {
        final firstUserIndex = rowIndex * 2;
        final secondUserIndex = firstUserIndex + 1;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
                child: UserCheckbox(
                    user: limitedUsers[firstUserIndex], onChanged: onChanged)),
            if (secondUserIndex < limitedUsers.length)
              Expanded(
                  child: UserCheckbox(
                      user: limitedUsers[secondUserIndex],
                      onChanged: onChanged)),
          ],
        );
      }),
    );
  }
}

class UserCheckbox extends StatefulWidget {
  final Contact user;
  final Function(Int64, bool) onChanged;

  const UserCheckbox({super.key, required this.user, required this.onChanged});

  @override
  State<UserCheckbox> createState() => _UserCheckboxState();
}

class _UserCheckboxState extends State<UserCheckbox> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 3), // Padding inside the container
      child: GestureDetector(
        onTap: () {
          setState(() {
            isChecked = !isChecked;
            widget.onChanged(widget.user.userId, isChecked);
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: 10, vertical: 0), // Padding inside the container
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              // color: Colors.blue, // Border color
              width: 1.0, // Border width
            ),
            borderRadius:
                BorderRadius.circular(8.0), // Optional: Rounded corners
          ),
          child: Row(
            children: [
              InitialsAvatar(
                  fontSize: 15,
                  displayName: widget
                      .user.displayName), // Display first letter of the name
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.user.displayName.length > 10
                      ? '${widget.user.displayName.substring(0, 10)}...' // Trim if too long
                      : widget.user.displayName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Checkbox(
                value: isChecked,
                onChanged: (bool? value) {
                  setState(() {
                    isChecked = value ?? false;
                    widget.onChanged(widget.user.userId, isChecked);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
