import 'package:restart_app/restart_app.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/onboarding/register_view.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsAccount),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text("Transfer account"),
            subtitle: Text("Coming soon"),
            onTap: () async {
              showAlertDialog(context, "Coming soon",
                  "This feature is not yet implemented!");
            },
          ),
          ListTile(
            title: Text(context.lang.settingsAccountDeleteAccount,
                style: TextStyle(color: Colors.red)),
            onTap: () async {
              bool ok = await showAlertDialog(
                  context,
                  context.lang.settingsAccountDeleteModalTitle,
                  context.lang.settingsAccountDeleteModalBody);

              if (ok) {
                await deleteLocalUserData();
                Restart.restartApp(
                  notificationTitle: 'Successfully logged out',
                  notificationBody: 'Click here to open the app again',
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
