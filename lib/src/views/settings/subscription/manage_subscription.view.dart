import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/settings/subscription/subscription.view.dart';

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
    initAsync(true);
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
              content: Text(errorCodeToText(context, res.error as ErrorCode))),
        );
      }
    }
    await initAsync(true);
  }

  @override
  Widget build(BuildContext context) {
    final planId = context.read<CustomChangeProvider>().plan;
    final myLocale = Localizations.localeOf(context);
    final paidMonthly = ballance?.paymentPeriodDays == MONTHLY_PAYMENT_DAYS;
    final isAdditionalUser = planId == 'Free' || planId == 'Plus';
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.manageSubscription),
      ),
      body: ListView(
        children: [
          PlanCard(planId: planId, paidMonthly: paidMonthly),
          if (!isAdditionalUser) const SizedBox(height: 20),
          if (widget.nextPayment != null && !isAdditionalUser)
            ListTile(
              title: Text(
                '${context.lang.nextPayment}: ${DateFormat.yMMMMd(myLocale.toString()).format(widget.nextPayment!)}',
              ),
            ),
          if (autoRenewal != null && !isAdditionalUser)
            ListTile(
              title: Text(context.lang.autoRenewal),
              subtitle: Text(
                context.lang.autoRenewalLongDesc,
                style: const TextStyle(fontSize: 12),
              ),
              onTap: toggleRenewalOption,
              trailing: Checkbox(
                value: autoRenewal,
                onChanged: (a) {
                  toggleRenewalOption();
                },
              ),
            ),
        ],
      ),
    );
  }
}
