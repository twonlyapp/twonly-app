// ignore_for_file: inference_failure_on_instance_creation
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart';
import 'package:twonly/src/model/purchases/purchasable_product.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/better_list_title.dart';
import 'package:twonly/src/views/settings/subscription/additional_users.view.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  bool loaded = false;
  bool testerRequested = true;
  Response_PlanBallance? ballance;
  String? additionalOwnerName;

  @override
  void initState() {
    super.initState();
    unawaited(initAsync());
  }

  Future<void> initAsync() async {
    ballance = await apiService.loadPlanBalance();
    if (ballance != null && ballance!.hasAdditionalAccountOwnerId()) {
      final ownerId = ballance!.additionalAccountOwnerId.toInt();
      final contact = await twonlyDB.contactsDao
          .getContactByUserId(ownerId)
          .getSingleOrNull();
      if (contact != null) {
        additionalOwnerName = getContactDisplayName(contact);
      } else {
        additionalOwnerName = ownerId.toString();
      }
    }
    setState(() {});
    await apiService.forceIpaCheck();
  }

  @override
  Widget build(BuildContext context) {
    final currentPlan = context.watch<PurchasesProvider>().plan;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsSubscription),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: context.color.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  currentPlan.name,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode(context) ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ),
          if (additionalOwnerName != null)
            Center(
              child: Text(
                context.lang.partOfPaidPlanOf(additionalOwnerName!),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.orange),
              ),
            ),
          if (isPayingUser(currentPlan))
            PlanCard(
              plan: currentPlan,
            ),
          if (!isPayingUser(currentPlan) ||
              currentPlan == SubscriptionPlan.Tester) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  context.lang.upgradeToPaidPlan,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            PlanCard(
              plan: SubscriptionPlan.Pro,
              onPurchase: initAsync,
            ),
            PlanCard(
              plan: SubscriptionPlan.Family,
              onPurchase: initAsync,
            ),
          ],
          const SizedBox(height: 10),
          BetterListTile(
            icon: FontAwesomeIcons.fileContract,
            text: context.lang.termsOfService,
            trailing:
                const FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 15),
            onTap: () async {
              await launchUrl(Uri.parse('https://twonly.eu/de/legal/agb.html'));
            },
          ),
          BetterListTile(
            leading: const FaIcon(
              FontAwesomeIcons.gavel,
              size: 15,
            ),
            text: context.lang.privacyPolicy,
            trailing:
                const FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 15),
            onTap: () async {
              await launchUrl(
                Uri.parse('https://twonly.eu/de/legal/privacy.html'),
              );
            },
          ),
          if (isPayingUser(currentPlan) ||
              currentPlan == SubscriptionPlan.Tester)
            const Divider(),
          if (isPayingUser(currentPlan) ||
              currentPlan == SubscriptionPlan.Tester)
            BetterListTile(
              icon: FontAwesomeIcons.userPlus,
              text: context.lang.manageAdditionalUsers,
              subtitle: loaded ? Text('${context.lang.open}: 3') : null,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return AdditionalUsersView(
                        ballance: ballance,
                      );
                    },
                  ),
                );
                await initAsync();
              },
            ),
        ],
      ),
    );
  }
}

class PlanCard extends StatefulWidget {
  const PlanCard({
    required this.plan,
    super.key,
    this.onPurchase,
    this.paidMonthly,
  });
  final SubscriptionPlan plan;
  final Future<void> Function()? onPurchase;
  final bool? paidMonthly;

  @override
  State<PlanCard> createState() => _PlanCardState();
}

String getFormattedPrice(PurchasableProduct product) {
  return product.price;
}

class _PlanCardState extends State<PlanCard> {
  PurchasableProduct? _isLoading;
  Future<void> onButtonPressed(PurchasableProduct? product) async {
    if (widget.onPurchase == null || _isLoading != null) return;
    if (product == null) return;
    setState(() {
      _isLoading = product;
    });
    await context.read<PurchasesProvider>().buy(product);
    await widget.onPurchase!();
    setState(() {
      _isLoading = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<PurchasesProvider>().products;
    final currentPlan = context.watch<PurchasesProvider>().plan;
    PurchasableProduct? yearlyProduct;
    PurchasableProduct? monthlyProduct;

    for (final product in products) {
      if (product.id.toLowerCase().startsWith(widget.plan.name.toLowerCase())) {
        if (product.id.toLowerCase().contains('monthly')) {
          monthlyProduct = product;
        } else if (product.id.toLowerCase().contains('yearly')) {
          yearlyProduct = product;
        }
      }
    }

    var features = <String>[];

    switch (widget.plan.name) {
      case 'Free':
        features = [context.lang.freeFeature1];
      case 'Plus':
        features = [context.lang.plusFeature1]; //, context.lang.plusFeature2];
      case 'Tester':
      case 'Pro':
        features = [
          context.lang.proFeature1,
          context.lang.proFeature2,
          context.lang.proFeature3,
          context.lang.proFeature4,
          // context.lang.proFeature4,
        ];
      case 'Family':
        features = [
          context.lang.familyFeature1,
          context.lang.familyFeature2,
          context.lang.familyFeature3,
          context.lang.familyFeature4,
        ];
      default:
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        color: context.color.surfaceContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    widget.plan.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    feature,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (currentPlan == widget.plan)
                FilledButton.icon(
                  onPressed: () async {
                    var url = 'https://apps.apple.com/account/subscriptions';
                    if (Platform.isAndroid) {
                      url =
                          'https://play.google.com/store/account/subscriptions?sku=${gUser.subscriptionPlanIdStore}&package=eu.twonly';
                    }
                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  label: const Text('Manage subscription'),
                ),
              if (widget.onPurchase != null && monthlyProduct != null)
                OutlinedButton.icon(
                  onPressed: _isLoading != null
                      ? null
                      : () => onButtonPressed(monthlyProduct),
                  icon: _isLoading == monthlyProduct
                      ? const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1),
                        )
                      : null,
                  label: Text(
                    context.lang.upgradeToPaidPlanButton(
                      widget.plan.name,
                      ' (${getFormattedPrice(monthlyProduct)}/${context.lang.month})',
                    ),
                  ),
                ),
              if (widget.onPurchase != null &&
                  (yearlyProduct != null ||
                      currentPlan == SubscriptionPlan.Free))
                FilledButton.icon(
                  onPressed: _isLoading != null
                      ? null
                      : () => onButtonPressed(yearlyProduct),
                  icon: _isLoading == yearlyProduct
                      ? const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1),
                        )
                      : null,
                  label: Text(
                    context.lang.upgradeToPaidPlanButton(
                      widget.plan.name,
                      ' (${getFormattedPrice(yearlyProduct!)}/${context.lang.year})',
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
