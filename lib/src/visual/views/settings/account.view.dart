import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/snackbar.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsAccountDeleteAccount),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              context.lang.settingsAccountDeleteAccount,
              style: TextStyle(color: context.color.error),
            ),
            subtitle: Text(context.lang.settingsAccountDeleteAccountNoBallance),
            onTap: () async {
              if (!context.mounted) return;
              final lang = context.lang;
              final ok = await showAlertDialog(
                context,
                context.lang.settingsAccountDeleteModalTitle,
                context.lang.settingsAccountDeleteModalBody,
              );
              if (ok) {
                final res = await rustApiResult(RustApi.deleteAccount());
                if (res.isError) {
                  if (!context.mounted) return;
                  showSnackbar(
                    context,
                    context.lang.settingsDeleteAccountFailed,
                  );
                  return;
                }
                await deleteLocalUserData(removeCredentials: true);
                await Restart.restartApp(
                  notificationTitle: lang.settingsAccountDeleted,
                  notificationBody: lang.settingsOpenAppAgain,
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
