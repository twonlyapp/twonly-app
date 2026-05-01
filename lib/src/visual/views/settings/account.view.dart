import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';

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
          // ListTile(
          //   title: const Text('Transfer account'),
          //   subtitle: const Text('Coming soon'),
          //   onTap: () async {
          //     await showAlertDialog(
          //       context,
          //       'Coming soon',
          //       'This feature is not yet implemented!',
          //     );
          //   },
          // ),
          // const Divider(),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: const Text(
              'Danger Zone',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: Text(
              context.lang.settingsAccountDeleteAccount,
              style: const TextStyle(color: Colors.red),
            ),
            subtitle: Text(context.lang.settingsAccountDeleteAccountNoBallance),
            onTap: () async {
              if (!context.mounted) return;
              final ok = await showAlertDialog(
                context,
                context.lang.settingsAccountDeleteModalTitle,
                context.lang.settingsAccountDeleteModalBody,
              );
              if (ok) {
                final res = await apiService.deleteAccount();
                if (res.isError) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not delete the account. Please ensure you have a internet connection!',
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                await deleteLocalUserData();
                await Restart.restartApp(
                  notificationTitle: 'Account successfully deleted',
                  notificationBody: 'Click here to open the app again',
                  forceKill: true,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
