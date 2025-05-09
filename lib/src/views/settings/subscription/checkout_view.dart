import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/settings/subscription/select_payment.dart';
import 'package:twonly/src/views/settings/subscription/subscription_view.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({
    super.key,
    required this.planId,
  });

  final String planId;

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
    setCheckout(true);
  }

  void setCheckout(bool init) {
    checkoutInCents = getPlanPrice(widget.planId, paidMonthly);
    if (!init) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    String totalPrice =
        "${localePrizing(context, checkoutInCents)}/${(paidMonthly) ? context.lang.month : context.lang.year}";
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
                  PlanCard(planId: widget.planId),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListTile(
                      title: Text(context.lang.checkoutPayYearly),
                      onTap: () {
                        paidMonthly = !paidMonthly;
                        setCheckout(false);
                      },
                      trailing: Checkbox(
                        value: !paidMonthly,
                        onChanged: (a) {
                          paidMonthly = !paidMonthly;
                          setCheckout(false);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton(
                  onPressed: () async {
                    bool? success = await Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return SelectPaymentView(
                          planId: widget.planId, payMonthly: paidMonthly);
                    }));
                    if (success != null && success && context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(context.lang.selectPaymentMethode)),
            ),
            SizedBox(height: 20)
          ],
        ),
      ),
    );
  }
}
