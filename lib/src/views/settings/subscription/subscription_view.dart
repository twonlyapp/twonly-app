import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/api/server_to_client.pb.dart';
import 'package:twonly/src/providers/connection_provider.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/better_list_title.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  bool hasInternet = true;
  int ballanceInCents = 0;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future initAsync() async {
    // userData = await getUser();
    // setState(() {});

    Response_PlanBallance? ballance = await apiProvider.getPlanBallance();
    if (ballance == null) {
      setState(() {
        hasInternet = false;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedBalance = NumberFormat.currency(
      locale: 'de_DE', // Locale for Euro formatting
      symbol: '€',
      decimalDigits: 2,
    ).format(ballanceInCents / 100);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsSubscription),
      ),
      body: Column(
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
                  context.watch<CustomChangeProvider>().plan,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                Center(
                  child: Text("Upgrade your current plan."),
                ),
                SizedBox(height: 10),
                PlanCard(
                  title: 'Pro',
                  yearlyPrice: '10€/year',
                  monthlyPrice: '1€/month',
                  features: [
                    '✓ Unlimited media files',
                    '1 additional Plus user',
                    '3 additional Free users',
                  ],
                ),
                SizedBox(height: 10),
                PlanCard(
                  title: 'Family',
                  yearlyPrice: '20€/year',
                  monthlyPrice: '2€/month',
                  features: [
                    '✓ All from Pro',
                    '4 additional Plus users',
                    '5 additional Free users',
                  ],
                ),
                SizedBox(height: 10),
                Divider(),
                BetterListTile(
                  icon: FontAwesomeIcons.ticket,
                  text: "Redeem code for additional user",
                  onTap: () {},
                ),
                BetterListTile(
                  icon: FontAwesomeIcons.moneyBillTransfer,
                  text: "Your transaction history",
                  subtitle: Text("Current ballance: $formattedBalance"),
                  onTap: () {},
                ),
                BetterListTile(
                  icon: FontAwesomeIcons.userPlus,
                  text: "Manage your additional users",
                  subtitle: Text("Open: 3"),
                  onTap: () {},
                ),
                BetterListTile(
                  icon: FontAwesomeIcons.gift,
                  text: "Create or redeem voucher",
                  onTap: () {},
                ),
                SizedBox(height: 30)
              ],
              // tranaction
            ),
          )
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
                  SizedBox(height: 10),
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
