import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pbserver.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/settings/subscription_custom/subscription.view.dart';
import 'package:twonly/src/views/settings/subscription_custom/voucher.view.dart';
import 'package:url_launcher/url_launcher.dart';

class SelectPaymentView extends StatefulWidget {
  const SelectPaymentView({
    super.key,
    this.plan,
    this.payMonthly,
    this.valueInCents,
  });

  final SubscriptionPlan? plan;
  final bool? payMonthly;
  final int? valueInCents;

  @override
  State<SelectPaymentView> createState() => _SelectPaymentViewState();
}

enum PaymentMethods {
  twonlyCredit,
  googleSubscription,
  appleSubscription,
}

class _SelectPaymentViewState extends State<SelectPaymentView> {
  int? balanceInCents;
  int checkoutInCents = 0;
  bool tryAutoRenewal = true;

  PaymentMethods paymentMethods = PaymentMethods.twonlyCredit;

  @override
  void initState() {
    super.initState();
    setCheckout(true);
    unawaited(initAsync());
  }

  Future<void> initAsync() async {
    final balance = await loadPlanBalance();
    if (balance == null) {
      balanceInCents = 0;
    } else {
      balanceInCents =
          balance.transactions.map((a) => a.depositCents.toInt()).sum;
    }
    setState(() {});
  }

  void setCheckout(bool init) {
    if (widget.valueInCents != null && widget.valueInCents! > 0) {
      checkoutInCents = widget.valueInCents!;
    } else if (widget.plan != null) {
      checkoutInCents =
          getPlanPrice(widget.plan!, paidMonthly: widget.payMonthly!);
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
    final totalPrice = (widget.plan != null && widget.payMonthly != null)
        ? '${localePrizing(context, checkoutInCents)}/${(widget.payMonthly!) ? context.lang.month : context.lang.year}'
        : localePrizing(context, checkoutInCents);
    final canPay = paymentMethods == PaymentMethods.twonlyCredit &&
        (balanceInCents == null || balanceInCents! >= checkoutInCents);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.selectPaymentMethod),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.lang.testPaymentMethod,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      color: context.color.surfaceContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.lang.twonlyCredit),
                                if (balanceInCents != null)
                                  Text(
                                    '${context.lang.currentBalance}: ${localePrizing(context, balanceInCents!)}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
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
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.lang.notEnoughCredit,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const VoucherView();
                        },
                      ),
                    );
                    await initAsync();
                  },
                  child: Text(context.lang.chargeCredit),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(16),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: context.color.surfaceContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        context.lang.checkoutTotal,
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton(
                onPressed: canPay
                    ? () async {
                        final res = await apiService.switchToPayedPlan(
                          widget.plan!.name,
                          widget.payMonthly!,
                          tryAutoRenewal,
                        );
                        if (!context.mounted) return;
                        if (res.isSuccess) {
                          await updateUsersPlan(context, widget.plan!);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.lang.planSuccessUpgraded),
                            ),
                          );
                          Navigator.of(context).pop(true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                errorCodeToText(
                                  context,
                                  res.error as ErrorCode,
                                ),
                              ),
                            ),
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
                  onPressed: () => launchUrl(
                    Uri.parse(
                      'https://twonly.eu/de/legal/#revocation-policy',
                    ),
                  ),
                  child: const Text(
                    'Widerrufsbelehrung',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse('https://twonly.eu/de/legal/agb.html'),
                  ),
                  child: const Text(
                    'ABG',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
