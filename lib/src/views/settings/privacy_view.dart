import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/settings/privacy_view_block_users.dart';

class PrivacyView extends StatefulWidget {
  const PrivacyView({super.key});

  @override
  State<PrivacyView> createState() => _PrivacyViewState();
}

class _PrivacyViewState extends State<PrivacyView> {
  @override
  void initState() {
    super.initState();
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
            subtitle: StreamBuilder(
              stream: twonlyDatabase.contactsDao.watchContactsBlocked(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Text(
                    context.lang.settingsPrivacyBlockUsersCount(snapshot.data!),
                  );
                } else {
                  return Text(
                    context.lang.settingsPrivacyBlockUsersCount(0),
                  );
                }
              },
            ),
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (context) {
                return PrivacyViewBlockUsers();
              }));
            },
          ),
        ],
      ),
    );
  }
}
