// ignore_for_file: inference_failure_on_instance_creation
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/components/better_list_title.dart';
import 'package:twonly/src/views/settings/subscription/additional_users.view.dart';
import 'package:twonly/src/views/settings/subscription_custom/checkout.view.dart';
import 'package:twonly/src/views/settings/subscription_custom/manage_subscription.view.dart';
import 'package:twonly/src/views/settings/subscription_custom/transaction.view.dart';
import 'package:twonly/src/views/settings/subscription_custom/voucher.view.dart';

String localePrizing(BuildContext context, int cents) {
  final myLocale = Localizations.localeOf(context);
  final euros = cents / 100;

  if (euros == euros.toInt()) {
    return '${euros.toInt()}€';
  }

  return NumberFormat.currency(
    locale: myLocale.toString(),
    symbol: '€',
    decimalDigits: 2,
  ).format(cents / 100);
}

Future<Response_PlanBallance?> loadPlanBalance({bool useCache = true}) async {
  final ballance = await apiService.getPlanBallance();
  if (ballance != null) {
    await updateUserdata((u) {
      u.lastPlanBallance = ballance.writeToJson();
      return u;
    });
    return ballance;
  }
  final user = await getUser();
  if (user != null && user.lastPlanBallance != null && useCache) {
    try {
      return Response_PlanBallance.fromJson(
        user.lastPlanBallance!,
      );
    } catch (e) {
      Log.error('from json: $e');
    }
  }
  return ballance;
}

// ignore: constant_identifier_names
const int MONTHLY_PAYMENT_DAYS = 30;
// ignore: constant_identifier_names
const int YEARLY_PAYMENT_DAYS = 365;

class SubscriptionCustomView extends StatefulWidget {
  const SubscriptionCustomView({super.key, this.redirectError});

  final ErrorCode? redirectError;

  @override
  State<SubscriptionCustomView> createState() => _SubscriptionCustomViewState();
}

class _SubscriptionCustomViewState extends State<SubscriptionCustomView> {
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
    ballance = await loadPlanBalance();
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
  }

  @override
  Widget build(BuildContext context) {
    final myLocale = Localizations.localeOf(context);
    String? formattedBalance;
    DateTime? nextPayment;
    final currentPlan = context.watch<PurchasesProvider>().plan;

    if (ballance != null) {
      final lastPaymentDateTime = DateTime.fromMillisecondsSinceEpoch(
        ballance!.lastPaymentDoneUnixTimestamp.toInt() * 1000,
      );
      if (isPayingUser(currentPlan)) {
        nextPayment = lastPaymentDateTime
            .add(Duration(days: ballance!.paymentPeriodDays.toInt()));
      }
      final ballanceInCents =
          ballance!.transactions.map((a) => a.depositCents.toInt()).sum;
      formattedBalance = NumberFormat.currency(
        locale: myLocale.toString(),
        symbol: '€',
        decimalDigits: 2,
      ).format(ballanceInCents / 100);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsSubscription),
      ),
      body: ListView(
        children: [
          if (widget.redirectError != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  (widget.redirectError == ErrorCode.PlanLimitReached)
                      ? context.lang.planLimitReached
                      : context.lang.planNotAllowed,
                  style: const TextStyle(color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
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
          if (!isPayingUser(currentPlan))
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
          if (!isPayingUser(currentPlan) ||
              currentPlan == SubscriptionPlan.Tester)
            PlanCard(
              plan: SubscriptionPlan.Pro,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const CheckoutView(
                        plan: SubscriptionPlan.Pro,
                      );
                    },
                  ),
                );
                await initAsync();
              },
            ),
          if (currentPlan != SubscriptionPlan.Family)
            PlanCard(
              plan: SubscriptionPlan.Family,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return CheckoutView(
                        plan: SubscriptionPlan.Family,
                        disableMonthlyOption:
                            currentPlan == SubscriptionPlan.Pro &&
                                ballance!.paymentPeriodDays.toInt() ==
                                    YEARLY_PAYMENT_DAYS,
                      );
                    },
                  ),
                );
                await initAsync();
              },
            ),
          if (!isPayingUser(currentPlan)) ...[
            const SizedBox(height: 10),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  context.lang.redeemUserInviteCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 10),
            PlanCard(
              plan: SubscriptionPlan.Plus,
              onTap: () async {
                await redeemUserInviteCode(context, SubscriptionPlan.Plus.name);
                await initAsync();
              },
            ),
          ],
          const SizedBox(height: 10),
          if (currentPlan != SubscriptionPlan.Family) const Divider(),
          BetterListTile(
            icon: FontAwesomeIcons.gears,
            text: context.lang.manageSubscription,
            subtitle: (nextPayment != null)
                ? Text(
                    '${context.lang.nextPayment}: ${DateFormat.yMMMMd(myLocale.toString()).format(nextPayment)}',
                  )
                : null,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return ManageSubscriptionView(
                      ballance: ballance,
                      nextPayment: nextPayment,
                    );
                  },
                ),
              );
              await initAsync();
            },
          ),
          BetterListTile(
            icon: FontAwesomeIcons.moneyBillTransfer,
            text: context.lang.transactionHistory,
            subtitle: (formattedBalance != null)
                ? Text('${context.lang.currentBalance}: $formattedBalance')
                : null,
            onTap: () async {
              if (formattedBalance == null) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return TransactionView(
                      transactions: ballance?.transactions,
                      formattedBalance: formattedBalance!,
                    );
                  },
                ),
              );
            },
          ),
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
          BetterListTile(
            icon: FontAwesomeIcons.ticket,
            text: context.lang.createOrRedeemVoucher,
            onTap: () async {
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
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

int getPlanPrice(SubscriptionPlan plan, {required bool paidMonthly}) {
  switch (plan) {
    case SubscriptionPlan.Pro:
      return paidMonthly ? 100 : 1000;
    case SubscriptionPlan.Family:
      return paidMonthly ? 200 : 2000;
    // ignore: no_default_cases
    default:
      return 0;
  }
}

class PlanCard extends StatelessWidget {
  const PlanCard({
    required this.plan,
    super.key,
    this.refund,
    this.onTap,
    this.paidMonthly,
  });
  final SubscriptionPlan plan;
  final void Function()? onTap;
  final int? refund;
  final bool? paidMonthly;

  @override
  Widget build(BuildContext context) {
    final yearlyPrice = getPlanPrice(plan, paidMonthly: false);
    final monthlyPrice = getPlanPrice(plan, paidMonthly: true);
    var features = <String>[];

    switch (plan.name) {
      case 'Free':
        features = [context.lang.freeFeature1];
      case 'Plus':
        features = [context.lang.plusFeature1, context.lang.plusFeature2];
      case 'Tester':
      case 'Pro':
        features = [
          context.lang.proFeature1,
          context.lang.proFeature2,
          context.lang.proFeature3,
          context.lang.proFeature4,
        ];
      case 'Family':
        features = [
          context.lang.proFeature1,
          context.lang.familyFeature2,
          context.lang.proFeature3,
          context.lang.proFeature4,
        ];
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
          color: context.color.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      plan.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (yearlyPrice != 0) const SizedBox(height: 10),
                    if (yearlyPrice != 0 && paidMonthly == null)
                      Column(
                        children: [
                          if (paidMonthly == null || paidMonthly!)
                            Text(
                              '${localePrizing(context, yearlyPrice)}/${context.lang.year}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (paidMonthly == null || !paidMonthly!)
                            Text(
                              '${localePrizing(context, monthlyPrice)}/${context.lang.month}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    if (paidMonthly != null)
                      Text(
                        (paidMonthly!)
                            ? '${localePrizing(context, monthlyPrice)}/${context.lang.month}'
                            : '${localePrizing(context, yearlyPrice)}/${context.lang.year}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
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
                  ),
                if (onTap != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: FilledButton.icon(
                      onPressed: onTap,
                      label: (plan == SubscriptionPlan.Free ||
                              plan == SubscriptionPlan.Plus)
                          ? Text(context.lang.redeemUserInviteCodeTitle)
                          : Text(
                              context.lang
                                  .upgradeToPaidPlanButton(plan.name, ''),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> redeemUserInviteCode(BuildContext context, String newPlan) async {
  var inviteCode = '';
  // ignore: inference_failure_on_function_invocation
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(context.lang.redeemUserInviteCodeTitle),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: TextField(
                      onChanged: (value) => setState(() {
                        inviteCode = value.toUpperCase();
                      }),
                      decoration: InputDecoration(
                        labelText: context.lang.registerTwonlyCodeLabel,
                        border: const OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(context.lang.cancel),
          ),
          TextButton(
            onPressed: () async {
              final res = await apiService.redeemUserInviteCode(inviteCode);
              if (!context.mounted) return;
              if (res.isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.lang.redeemUserInviteCodeSuccess),
                  ),
                );
                // reconnect to load new plan.
                await apiService.close(() {});
                await apiService.connect(force: true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      errorCodeToText(context, res.error as ErrorCode),
                    ),
                  ),
                );
              }
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            child: Text(context.lang.ok),
          ),
        ],
      );
    },
  );
}
