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
        title: Text(AppLocalizations.of(context)!.newMessageTitle),
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: 20, left: 10, top: 20, right: 10),
        child: Column(
          children: [
            UserCheckboxList(users: _knownUsers),
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

  UserCheckboxList({required this.users});

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
            Text(limitedUsers[firstUserIndex].displayName),
            if (secondUserIndex < limitedUsers.length)
              Text(limitedUsers[secondUserIndex].displayName),
          ],
        );
      }),
    );
  }
}

class UserCheckbox extends StatefulWidget {
  final Contact user;

  UserCheckbox({required this.user});

  @override
  _UserCheckboxState createState() => _UserCheckboxState();
}

class _UserCheckboxState extends State<UserCheckbox> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: isChecked,
          onChanged: (bool? value) {
            setState(() {
              isChecked = value ?? false;
            });
          },
        ),
        CircleAvatar(
          child: InitialsAvatar(
              displayName:
                  widget.user.displayName), // Display first letter of the name
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.user.displayName.length > 10
                ? '${widget.user.displayName.substring(0, 10)}...' // Trim if too long
                : widget.user.displayName,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
