import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/api/server_to_client.pb.dart';
import 'package:twonly/src/providers/connection_provider.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/components/better_list_title.dart';
import 'package:twonly/src/views/settings/subscription/additional_users_view.dart';
import 'package:twonly/src/views/settings/subscription/checkout_view.dart';
import 'package:twonly/src/views/settings/subscription/manage_subscription_view.dart';
import 'package:twonly/src/views/settings/subscription/transaction_view.dart';
import 'package:twonly/src/views/settings/subscription/voucher_view.dart';

String localePrizing(BuildContext context, int cents) {
  Locale myLocale = Localizations.localeOf(context);

  double euros = cents / 100;

  if (euros == euros.toInt()) {
    return "${euros.toInt()}€";
  }

  return NumberFormat.currency(
    locale: myLocale.toString(),
    symbol: '€',
    decimalDigits: 2,
  ).format(cents / 100);
}

Future<Response_PlanBallance?> loadPlanBallance() async {
  Response_PlanBallance? ballance;
  final user = await getUser();
  if (user == null) return ballance;
  ballance = await apiProvider.getPlanBallance();
  if (ballance != null) {
    user.lastPlanBallance = ballance.writeToJson();
    await updateUser(user);
  } else if (user.lastPlanBallance != null) {
    try {
      ballance = Response_PlanBallance.fromJson(
        user.lastPlanBallance!,
      );
    } catch (e) {
      Logger("subscription_view.dart").shout("from json: $e");
    }
  }
  return ballance;
}

// ignore: constant_identifier_names
const int MONTHLY_PAYMENT_DAYS = 30;
// ignore: constant_identifier_names
const int YEARLY_PAYMENT_DAYS = 365;

int calculateRefund(Response_PlanBallance current) {
  int refund = getPlanPrice("Pro", true);

  if (current.paymentPeriodDays == YEARLY_PAYMENT_DAYS) {
    final elapsedDays = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(
            current.lastPaymentDoneUnixTimestamp.toInt() * 1000))
        .inDays;
    if (elapsedDays < current.paymentPeriodDays.toInt()) {
      // User has yearly plan with 10€
      // used it half a year and wants now to upgrade => gets 5€ discount...
      // math.ceil(((365-(365/2))/365)*10)
      // => 5€

      refund = (((YEARLY_PAYMENT_DAYS - elapsedDays) / YEARLY_PAYMENT_DAYS) *
              getPlanPrice("Pro", false))
          .ceil();
    }
  }
  return refund;
}

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  bool loaded = false;
  Response_PlanBallance? ballance;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future initAsync() async {
    ballance = await loadPlanBallance();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Locale myLocale = Localizations.localeOf(context);
    String? formattedBalance;
    DateTime? nextPayment;

    if (ballance != null) {
      DateTime lastPaymentDateTime = DateTime.fromMillisecondsSinceEpoch(
          ballance!.lastPaymentDoneUnixTimestamp.toInt() * 1000);
      nextPayment = lastPaymentDateTime
          .add(Duration(days: ballance!.paymentPeriodDays.toInt()));
      int ballanceInCents =
          ballance!.transactions.map((a) => a.depositCents.toInt()).sum;
      formattedBalance = NumberFormat.currency(
        locale: myLocale.toString(),
        symbol: '€',
        decimalDigits: 2,
      ).format(ballanceInCents / 100);
    }

    String currentPlan = context.read<CustomChangeProvider>().plan;
    int refund = 0;
    if (currentPlan == "Pro" && ballance != null) {
      refund = calculateRefund(ballance!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsSubscription),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: context.color.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  currentPlan,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode(context) ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ),
          if (currentPlan != "Family" && currentPlan != "Pro")
            Center(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Text(
                  context.lang.upgradeToPaidPlan,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          if (currentPlan != "Family" && currentPlan != "Pro")
            PlanCard(
              planId: "Pro",
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (context) {
                  return CheckoutView(
                    planId: "Pro",
                  );
                }));
                initAsync();
              },
            ),
          if (currentPlan != "Family")
            PlanCard(
              planId: "Family",
              refund: refund,
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (context) {
                  return CheckoutView(
                    planId: "Family",
                    refund: (refund > 0) ? refund : null,
                    disableMonthlyOption: (currentPlan == "Pro" &&
                        ballance!.paymentPeriodDays.toInt() ==
                            YEARLY_PAYMENT_DAYS),
                  );
                }));
                initAsync();
              },
            ),
          if (currentPlan == "Preview" || currentPlan == "Free") ...[
            SizedBox(height: 10),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Text(
                  context.lang.redeemUserInviteCode,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            SizedBox(height: 10),
            if (currentPlan != "Free")
              PlanCard(
                planId: "Free",
                onTap: () {},
              ),
            PlanCard(
              planId: "Plus",
              onTap: () {},
            ),
          ],
          SizedBox(height: 10),
          if (currentPlan != "Family") Divider(),
          if (currentPlan == "Family" || currentPlan == "Pro")
            BetterListTile(
              icon: FontAwesomeIcons.gears,
              text: context.lang.manageSubscription,
              subtitle: (nextPayment != null)
                  ? Text(
                      "${context.lang.nextPayment}: ${DateFormat.yMMMMd(myLocale.toString()).format(nextPayment)}")
                  : null,
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (context) {
                  return ManageSubscriptionView(
                      ballance: ballance, nextPayment: nextPayment);
                }));
                initAsync();
              },
            ),
          BetterListTile(
            icon: FontAwesomeIcons.moneyBillTransfer,
            text: context.lang.transactionHistory,
            subtitle: (formattedBalance != null)
                ? Text("${context.lang.currentBalance}: $formattedBalance")
                : null,
            onTap: () {
              if (formattedBalance == null) return;
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return TransactionView(
                  transactions: ballance?.transactions,
                  formattedBalance: formattedBalance!,
                );
              }));
            },
          ),
          if (currentPlan == "Family" || currentPlan == "Pro")
            BetterListTile(
              icon: FontAwesomeIcons.userPlus,
              text: context.lang.manageAdditionalUsers,
              subtitle: (loaded) ? Text("${context.lang.open}: 3") : null,
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (context) {
                  return AdditionalUsersView(
                    ballance: ballance,
                  );
                }));
                initAsync();
              },
            ),
          BetterListTile(
            icon: FontAwesomeIcons.ticket,
            text: context.lang.createOrRedeemVoucher,
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (context) {
                return VoucherView();
              }));
              initAsync();
            },
          ),
          SizedBox(height: 30)
        ],
      ),
    );
  }
}

int getPlanPrice(String planId, bool paidMonthly) {
  switch (planId) {
    case "Pro":
      return (paidMonthly) ? 100 : 1000;
    case "Family":
      return (paidMonthly) ? 200 : 2000;
  }
  return 0;
}

class PlanCard extends StatelessWidget {
  final String planId;
  final Function()? onTap;
  final int? refund;
  final bool? paidMonthly;

  const PlanCard(
      {super.key,
      required this.planId,
      this.refund,
      this.onTap,
      this.paidMonthly});

  @override
  Widget build(BuildContext context) {
    int yearlyPrice = getPlanPrice(planId, false);
    int monthlyPrice = getPlanPrice(planId, true);
    List<String> features = [];

    switch (planId) {
      case "Free":
        features = [context.lang.freeFeature1];
        break;
      case "Plus":
        features = [context.lang.plusFeature1];
        break;
      case "Pro":
        features = [
          context.lang.proFeature1,
          context.lang.proFeature2,
          context.lang.proFeature3
        ];
        break;
      case "Family":
        features = [
          context.lang.familyFeature1,
          context.lang.familyFeature2,
          context.lang.familyFeature3
        ];
        break;
      default:
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      planId,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (yearlyPrice != 0) SizedBox(height: 10),
                    if (yearlyPrice != 0 && paidMonthly == null)
                      Column(
                        children: [
                          if (paidMonthly == null || paidMonthly!)
                            Text(
                              "${localePrizing(context, yearlyPrice)}/${context.lang.year}",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (paidMonthly == null || !paidMonthly!)
                            Text(
                              "${localePrizing(context, monthlyPrice)}/${context.lang.month}",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    if (paidMonthly != null)
                      Text(
                        (paidMonthly!)
                            ? "${localePrizing(context, monthlyPrice)}/${context.lang.month}"
                            : "${localePrizing(context, yearlyPrice)}/${context.lang.year}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10),
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      feature,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                if (refund != null && refund! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(
                      context.lang
                          .subscriptionRefund(localePrizing(context, refund!)),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.color.primary,
                        fontSize: 12,
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
