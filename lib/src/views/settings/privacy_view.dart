import 'package:flutter/material.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/settings/privacy_view_block_users.dart';

class PrivacyView extends StatefulWidget {
  const PrivacyView({super.key});

  @override
  State<PrivacyView> createState() => _PrivacyViewState();
}

class _PrivacyViewState extends State<PrivacyView> {
  List<Contact> blockedUsers = [];

  @override
  void initState() {
    super.initState();
    updateBlockedUsers();
  }

  Future updateBlockedUsers() async {
    blockedUsers = await DbContacts.getBlockedUsers();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsPrivacy),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(context.lang.settingsPrivacyBlockUsers),
            subtitle: Text(
              context.lang.settingsPrivacyBlockUsersCount(blockedUsers.length),
            ),
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (context) {
                return PrivacyViewBlockUsers();
              }));
              updateBlockedUsers();
            },
          ),
        ],
      ),
    );
  }
}
