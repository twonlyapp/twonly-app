import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restart_app/restart_app.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/settings/account/refund_credits.view.dart';
import 'package:twonly/src/views/settings/subscription/subscription.view.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  String? formattedBallance;
  bool hasRemainingBallance = false;

  @override
  Future<void> initState() async {
    super.initState();
    await initAsync();
  }

  Future<void> initAsync() async {
    final ballance = await loadPlanBalance(useCache: false);
    if (ballance == null || !mounted) return;
    var ballanceInCents = ballance.transactions
        .where(
          (x) =>
              x.transactionType != Response_TransactionTypes.ThanksForTesting ||
              kDebugMode,
        )
        .map((a) => a.depositCents.toInt())
        .sum;
    if (ballanceInCents < 0) {
      ballanceInCents = 0;
    }
    hasRemainingBallance = ballanceInCents > 0;
    final myLocale = Localizations.localeOf(context);
    formattedBallance = NumberFormat.currency(
      locale: myLocale.toString(),
      symbol: '€',
      decimalDigits: 2,
    ).format(ballanceInCents / 100);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsAccount),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Transfer account'),
            subtitle: const Text('Coming soon'),
            onTap: () async {
              await showAlertDialog(
                context,
                'Coming soon',
                'This feature is not yet implemented!',
              );
            },
          ),
          const Divider(),
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
            subtitle: (formattedBallance == null)
                ? Text(context.lang.settingsAccountDeleteAccountNoInternet)
                : hasRemainingBallance
                    ? Text(
                        context.lang.settingsAccountDeleteAccountWithBallance(
                          formattedBallance!,
                        ),
                      )
                    : Text(context.lang.settingsAccountDeleteAccountNoBallance),
            onLongPress: kDebugMode
                ? () async {
                    await deleteLocalUserData();
                    await Restart.restartApp(
                      notificationTitle: 'Account successfully deleted',
                      notificationBody: 'Click here to open the app again',
                    );
                  }
                : null,
            onTap: (formattedBallance == null)
                ? null
                : () async {
                    if (hasRemainingBallance) {
                      final canGoNext = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return RefundCreditsView(
                              formattedBalance: formattedBallance!,
                            );
                          },
                        ),
                      ) as bool?;
                      unawaited(initAsync());
                      if (canGoNext == null || !canGoNext) return;
                    }
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
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}
