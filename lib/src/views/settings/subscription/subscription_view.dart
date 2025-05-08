import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/api/server_to_client.pb.dart';
import 'package:twonly/src/providers/connection_provider.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/better_list_title.dart';
import 'package:twonly/src/views/settings/subscription/transaction_view.dart';
import 'package:twonly/src/views/settings/subscription/voucher_view.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  bool loaded = false;
  int ballanceInCents = 0;
  DateTime? nextPayment;
  Response_PlanBallance? ballance;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future initAsync() async {
    ballance = await apiProvider.getPlanBallance();
    if (ballance != null) {
      setState(() {
        DateTime lastPaymentDateTime = DateTime.fromMillisecondsSinceEpoch(
            ballance!.lastPaymentDoneUnixTimestamp.toInt() * 1000);
        nextPayment = lastPaymentDateTime
            .add(Duration(days: ballance!.paymentPeriodDays.toInt()));
        ballanceInCents =
            ballance!.transactions.map((a) => a.depositCents.toInt()).sum;
        loaded = true;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    Locale myLocale = Localizations.localeOf(context);
    String formattedBalance = NumberFormat.currency(
      locale: myLocale.toString(),
      symbol: '€',
      decimalDigits: 2,
    ).format(ballanceInCents / 100);

    String currentPlan = context.read<CustomChangeProvider>().plan;

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
              title: "Pro",
              yearlyPrice: context.lang.proYearlyPrice,
              monthlyPrice: context.lang.proMonthlyPrice,
              features: [
                context.lang.proFeature1,
                context.lang.proFeature2,
                context.lang.proFeature3,
              ],
            ),
          if (currentPlan != "Family")
            PlanCard(
              title: "Family",
              yearlyPrice: context.lang.familyYearlyPrice,
              monthlyPrice: context.lang.familyMonthlyPrice,
              features: [
                context.lang.familyFeature1,
                context.lang.familyFeature2,
                context.lang.familyFeature3,
              ],
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
                title: "Free",
                yearlyPrice: "",
                monthlyPrice: "",
                features: [
                  context.lang.freeFeature1,
                ],
              ),
            PlanCard(
              title: "Plus",
              yearlyPrice: "",
              monthlyPrice: "",
              features: [
                context.lang.plusFeature1,
              ],
            ),
          ],
          SizedBox(height: 10),
          if (currentPlan != "Family") Divider(),
          if (currentPlan == "Family" || currentPlan == "Pro")
            BetterListTile(
              icon: FontAwesomeIcons.userPlus,
              text: "Manage your subscription",
              subtitle: (nextPayment != null)
                  ? Text(
                      "Next payment: ${DateFormat.yMMMMd(myLocale.toString()).format(nextPayment!)}")
                  : null,
              onTap: () {},
            ),
          BetterListTile(
            icon: FontAwesomeIcons.moneyBillTransfer,
            text: context.lang.transactionHistory,
            subtitle: (loaded)
                ? Text("${context.lang.currentBalance}: $formattedBalance")
                : null,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return TransactionView(
                  transactions: ballance!.transactions,
                  formattedBalance: formattedBalance,
                );
              }));
            },
          ),
          if (currentPlan == "Family" || currentPlan == "Pro")
            BetterListTile(
              icon: FontAwesomeIcons.userPlus,
              text: context.lang.manageAdditionalUsers,
              subtitle: (loaded) ? Text("${context.lang.open}: 3") : null,
              onTap: () {},
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

class PlanCard extends StatelessWidget {
  final String title;
  final String yearlyPrice;
  final String monthlyPrice;
  final List<String> features;

  const PlanCard({
    super.key,
    required this.title,
    required this.yearlyPrice,
    required this.monthlyPrice,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
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
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (yearlyPrice != "") SizedBox(height: 10),
                  if (yearlyPrice != "")
                    Column(
                      children: [
                        Text(
                          yearlyPrice,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          monthlyPrice,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    )
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
            ],
          ),
        ),
      ),
    );
  }
}
