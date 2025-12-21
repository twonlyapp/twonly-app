import 'package:flutter/material.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/settings/subscription_custom/select_payment.view.dart';
import 'package:twonly/src/views/settings/subscription_custom/subscription.view.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({
    required this.plan,
    super.key,
    this.disableMonthlyOption,
  });

  final SubscriptionPlan plan;
  final bool? disableMonthlyOption;

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  int checkoutInCents = 0;
  bool paidMonthly = false;
  bool tryAutoRenewal = true;

  @override
  void initState() {
    super.initState();
    setCheckout(init: true);
  }

  void setCheckout({bool init = false}) {
    checkoutInCents = getPlanPrice(widget.plan, paidMonthly: paidMonthly);
    if (!init) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice =
        '${localePrizing(context, checkoutInCents)}/${paidMonthly ? context.lang.month : context.lang.year}';
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.checkoutOptions),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                children: [
                  PlanCard(plan: widget.plan),
                  if (widget.disableMonthlyOption == null ||
                      !widget.disableMonthlyOption!)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListTile(
                        title: Text(context.lang.checkoutPayYearly),
                        onTap: () {
                          paidMonthly = !paidMonthly;
                          setCheckout();
                        },
                        trailing: Checkbox(
                          value: !paidMonthly,
                          onChanged: (a) {
                            paidMonthly = !paidMonthly;
                            setCheckout();
                          },
                        ),
                      ),
                    ),
                ],
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
                onPressed: () async {
                  final success = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return SelectPaymentView(
                          plan: widget.plan,
                          payMonthly: paidMonthly,
                        );
                      },
                    ),
                  ) as bool?;
                  if (success != null && success && context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text(context.lang.selectPaymentMethod),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
