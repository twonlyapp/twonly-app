import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/api/server_to_client.pb.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/settings/subscription/subscription.view.dart';

class ManageSubscriptionView extends StatefulWidget {
  const ManageSubscriptionView(
      {super.key, required this.ballance, required this.nextPayment});

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
    initAsync(false);
  }

  Future initAsync(bool force) async {
    if (force) {
      ballance = await loadPlanBalance();
      if (ballance != null) {
        autoRenewal = ballance!.autoRenewal;
      }
    }
    setState(() {});
  }

  Future toggleRenewalOption() async {
    Result res = await apiService.updatePlanOptions(!autoRenewal!);
    if (res.isError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorCodeToText(context, res.error))),
        );
      }
    }
    await initAsync(true);
  }

  @override
  Widget build(BuildContext context) {
    String planId = context.read<CustomChangeProvider>().plan;
    Locale myLocale = Localizations.localeOf(context);
    bool? paidMonthly = ballance?.paymentPeriodDays == MONTHLY_PAYMENT_DAYS;
    bool isAdditionalUser = planId == "Free" || planId == "Plus";
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.manageSubscription),
      ),
      body: ListView(
        children: [
          PlanCard(planId: planId, paidMonthly: paidMonthly),
          if (!isAdditionalUser) SizedBox(height: 20),
          if (widget.nextPayment != null && !isAdditionalUser)
            ListTile(
              title: Text(
                "${context.lang.nextPayment}: ${DateFormat.yMMMMd(myLocale.toString()).format(widget.nextPayment!)}",
              ),
            ),
          if (autoRenewal != null && !isAdditionalUser)
            ListTile(
              title: Text(context.lang.autoRenewal),
              subtitle: Text(
                context.lang.autoRenewalLongDesc,
                style: TextStyle(fontSize: 12),
              ),
              onTap: toggleRenewalOption,
              trailing: Checkbox(
                value: autoRenewal!,
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
