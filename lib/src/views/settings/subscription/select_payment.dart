import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/providers/connection_provider.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/settings/subscription/subscription_view.dart';
import 'package:twonly/src/views/settings/subscription/voucher_view.dart';
import 'package:url_launcher/url_launcher.dart';

class SelectPaymentView extends StatefulWidget {
  const SelectPaymentView(
      {super.key,
      this.planId,
      this.payMonthly,
      this.valueInCents,
      this.refund});

  final String? planId;
  final bool? payMonthly;
  final int? valueInCents;
  final int? refund;

  @override
  State<SelectPaymentView> createState() => _SelectPaymentViewState();
}

enum PaymentMethods {
  twonlyCredit,
  googleSubscription,
  appleSubscription,
}

class _SelectPaymentViewState extends State<SelectPaymentView> {
  int? ballanceInCents;
  int checkoutInCents = 0;
  bool tryAutoRenewal = true;

  PaymentMethods paymentMethods = PaymentMethods.twonlyCredit;

  @override
  void initState() {
    super.initState();
    setCheckout(true);
    initAsync();
  }

  Future initAsync() async {
    final ballance = await loadPlanBallance();
    ballanceInCents =
        ballance!.transactions.map((a) => a.depositCents.toInt()).sum;
    setState(() {});
  }

  void setCheckout(bool init) {
    if (widget.valueInCents != null && widget.valueInCents! > 0) {
      checkoutInCents = widget.valueInCents!;
    } else if (widget.planId != null) {
      checkoutInCents = getPlanPrice(widget.planId!, widget.payMonthly!);
    } else {
      /// Nothing to checkout for...
      Navigator.pop(context);
    }

    if (!init) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    String totalPrice = (widget.planId != null && widget.payMonthly != null)
        ? "${localePrizing(context, checkoutInCents)}/${(widget.payMonthly!) ? context.lang.month : context.lang.year}"
        : localePrizing(context, checkoutInCents);
    bool canPay = (paymentMethods == PaymentMethods.twonlyCredit &&
        (ballanceInCents == null || ballanceInCents! >= checkoutInCents));
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.selectPaymentMethode),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.lang.twonlyCredit),
                                if (ballanceInCents != null)
                                  Text(
                                    "${context.lang.currentBalance}: ${localePrizing(context, ballanceInCents!)}",
                                    style: TextStyle(fontSize: 10),
                                  )
                              ],
                            ),
                            Checkbox(
                              value:
                                  paymentMethods == PaymentMethods.twonlyCredit,
                              onChanged: (bool? value) {
                                setState(() {
                                  paymentMethods = PaymentMethods.twonlyCredit;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!canPay) ...[
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  context.lang.notEnoughCredit,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton(
                  onPressed: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return VoucherView();
                    }));
                    initAsync();
                  },
                  child: Text(context.lang.chargeCredit),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                title: Text(context.lang.autoRenewal),
                subtitle: Text(context.lang.autoRenewalDesc),
                onTap: () {
                  tryAutoRenewal = !tryAutoRenewal;
                  setCheckout(false);
                },
                trailing: Checkbox(
                  value: tryAutoRenewal,
                  onChanged: (a) {
                    tryAutoRenewal = !tryAutoRenewal;
                    setCheckout(false);
                  },
                ),
              ),
            ),
            if (widget.refund != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          context.lang.refund,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "+${localePrizing(context, widget.refund!)}",
                          textAlign: TextAlign.end,
                          style: TextStyle(color: context.color.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        context.lang.checkoutTotal,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        totalPrice,
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton(
                onPressed: (canPay)
                    ? () async {
                        final res = await apiProvider.switchToPayedPlan(
                            widget.planId!, widget.payMonthly!, tryAutoRenewal);
                        if (!context.mounted) return;
                        if (res.isSuccess) {
                          context.read<CustomChangeProvider>().plan =
                              widget.planId!;
                          var user = await getUser();
                          if (user != null) {
                            user.subscriptionPlan = widget.planId!;
                            await updateUser(user);
                          }
                          if (!context.mounted) return;
                          context
                              .read<CustomChangeProvider>()
                              .updatePlan(widget.planId!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text(context.lang.planSuccessUpgraded)),
                          );
                          Navigator.of(context).pop(true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                              errorCodeToText(context, res.error),
                            )),
                          );
                        }
                      }
                    : null,
                child: Text(context.lang.checkoutSubmit),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => launchUrl(Uri.parse(
                      "https://twonly.eu/legal/de/#revocation-policy")),
                  child: Text(
                    "Widerrufsbelehrung",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                TextButton(
                  onPressed: () => launchUrl(
                      Uri.parse("https://twonly.eu/legal/de/agb.html")),
                  child: Text(
                    "ABG",
                    style: TextStyle(color: Colors.blue),
                  ),
                )
              ],
            ),
            SizedBox(height: 20)
          ],
        ),
      ),
    );
  }
}
