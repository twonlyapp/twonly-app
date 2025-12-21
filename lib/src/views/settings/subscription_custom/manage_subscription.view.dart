import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/settings/subscription_custom/subscription.view.dart';

class ManageSubscriptionView extends StatefulWidget {
  const ManageSubscriptionView({
    required this.ballance,
    required this.nextPayment,
    super.key,
  });

  final Response_PlanBallance? ballance;
  final DateTime? nextPayment;

  @override
  State<ManageSubscriptionView> createState() => _ManageSubscriptionViewState();
}

class _ManageSubscriptionViewState extends State<ManageSubscriptionView> {
  Response_PlanBallance? ballance;
  bool? autoRenewal;

  @override
  void initState() {
    super.initState();
    ballance = widget.ballance;
    if (ballance != null) {
      autoRenewal = ballance!.autoRenewal;
    }
    unawaited(initAsync(true));
  }

  Future<void> initAsync(bool force) async {
    if (force) {
      ballance = await loadPlanBalance(useCache: false);
      if (ballance != null) {
        autoRenewal = ballance!.autoRenewal;
      }
    }
    setState(() {});
  }

  Future<void> toggleRenewalOption() async {
    final res = await apiService.updatePlanOptions(!autoRenewal!);
    if (res.isError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorCodeToText(context, res.error as ErrorCode)),
          ),
        );
      }
    }
    await initAsync(true);
  }

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<PurchasesProvider>().plan;
    final myLocale = Localizations.localeOf(context);
    final paidMonthly = ballance?.paymentPeriodDays == MONTHLY_PAYMENT_DAYS;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.manageSubscription),
      ),
      body: ListView(
        children: [
          PlanCard(plan: plan, paidMonthly: paidMonthly),
          if (isPayingUser(plan)) const SizedBox(height: 20),
          if (widget.nextPayment != null && isPayingUser(plan))
            ListTile(
              title: Text(
                '${context.lang.nextPayment}: ${DateFormat.yMMMMd(myLocale.toString()).format(widget.nextPayment!)}',
              ),
            ),
          if (autoRenewal != null && isPayingUser(plan))
            ListTile(
              title: Text(context.lang.autoRenewal),
              subtitle: Text(
                context.lang.autoRenewalLongDesc,
                style: const TextStyle(fontSize: 12),
              ),
              onTap: toggleRenewalOption,
              trailing: Switch(
                value: autoRenewal!,
                onChanged: (a) async {
                  await toggleRenewalOption();
                },
              ),
            ),
        ],
      ),
    );
  }
}
