import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/purchasable_product.model.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/elements/better_list_title.element.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/settings/subscription/additional_users.view.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  bool loaded = false;
  bool testerRequested = true;
  FrbPlanBalance? ballance;
  Contact? additionalOwner;
  String? additionalOwnerName;

  @override
  void initState() {
    super.initState();
    unawaited(initAsync());
  }

  Future<void> initAsync() async {
    try {
      ballance = await RustApi.loadPlanBalance();
    } catch (_) {
      ballance = null;
    }
    if (ballance != null && ballance!.additionalAccountOwnerId != null) {
      final ownerId = ballance!.additionalAccountOwnerId!;
      final contact = await twonlyDB.contactsDao
          .getContactByUserId(ownerId)
          .getSingleOrNull();
      additionalOwner = contact;
      additionalOwnerName = contact == null
          ? ownerId.toString()
          : getContactDisplayName(contact);
    }
    if (!mounted) return;
    setState(() {});
    await RustApi.forceIpaCheck();
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
          if (currentPlan.name == SubscriptionPlan.Free.name)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    context.lang.subscriptionPledgeSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.color.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _MissionRow(
                    icon: FontAwesomeIcons.shieldHalved,
                    title: context.lang.subscriptionPledgeSecureTitle,
                    desc: context.lang.subscriptionPledgeSecureDesc,
                  ),
                  const SizedBox(height: 24),
                  _MissionRow(
                    icon: FontAwesomeIcons.userSecret,
                    title: context.lang.subscriptionPledgeNoAdsTitle,
                    desc: context.lang.subscriptionPledgeNoAdsDesc,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.color.primary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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
          const SizedBox(height: 16),
          if (additionalOwnerName != null)
            PlanOwnerCard(
              owner: additionalOwner,
              ownerName: additionalOwnerName!,
            ),
          if (isPayingUser(currentPlan))
            PlanCard(
              plan: currentPlan,
            ),
          if (!isPayingUser(currentPlan) ||
              currentPlan == SubscriptionPlan.Tester) ...[
            PlanCard(
              plan: SubscriptionPlan.Pro,
              onPurchase: initAsync,
            ),
            PlanCard(
              plan: SubscriptionPlan.Family,
              onPurchase: initAsync,
            ),
          ],
          const SizedBox(height: 30),
          if (isPayingUser(currentPlan) ||
              currentPlan == SubscriptionPlan.Tester) ...[
            BetterListTile(
              icon: FontAwesomeIcons.userPlus,
              text: context.lang.manageAdditionalUsers,
              subtitle: loaded ? Text('${context.lang.open}: 3') : null,
              onTap: () async {
                await context.navPush(
                  AdditionalUsersView(
                    ballance: ballance,
                  ),
                );
                await initAsync();
              },
            ),
            const Divider(),
          ],
          BetterListTile(
            icon: FontAwesomeIcons.fileContract,
            text: context.lang.termsOfService,
            trailing: const FaIcon(
              FontAwesomeIcons.arrowUpRightFromSquare,
              size: 15,
            ),
            onTap: () async {
              await launchUrl(
                Uri.parse('https://twonly.eu/de/legal/agb.html'),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
          BetterListTile(
            leading: const FaIcon(
              FontAwesomeIcons.gavel,
              size: 15,
            ),
            text: context.lang.privacyPolicy,
            trailing: const FaIcon(
              FontAwesomeIcons.arrowUpRightFromSquare,
              size: 15,
            ),
            onTap: () async {
              await launchUrl(
                Uri.parse('https://twonly.eu/de/legal/privacy.html'),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The owner whose paid plan is covering this account. Tapping it opens their
/// profile, so the plan can be traced back to a person instead of a name in a
/// sentence. An owner who is not (or no longer) a contact still gets the card,
/// just without somewhere to navigate to.
class PlanOwnerCard extends StatelessWidget {
  const PlanOwnerCard({
    required this.owner,
    required this.ownerName,
    super.key,
  });

  final Contact? owner;
  final String ownerName;

  @override
  Widget build(BuildContext context) {
    final owner = this.owner;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        elevation: 0,
        color: context.color.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: owner == null
              ? null
              : () => context.push(Routes.profileContact(owner.userId)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AvatarIcon(
                  contactId: owner?.userId,
                  fontSize: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.lang.partOfPaidPlanFrom,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.color.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ownerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (owner != null) ...[
                  const SizedBox(width: 3),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.color.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Marks the plan the account is actually on, so the card that matters is
/// recognisable without reading any of the copy.
class CurrentPlanBadge extends StatelessWidget {
  const CurrentPlanBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.color.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        context.lang.subscriptionCurrentPlanBadge,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDarkMode(context) ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}

FaIconData planIcon(SubscriptionPlan plan) => switch (plan) {
  SubscriptionPlan.Free => FontAwesomeIcons.circleUser,
  SubscriptionPlan.Plus => FontAwesomeIcons.star,
  SubscriptionPlan.Pro => FontAwesomeIcons.bolt,
  SubscriptionPlan.Family => FontAwesomeIcons.peopleRoof,
  SubscriptionPlan.Tester => FontAwesomeIcons.flask,
};

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
    if (!mounted) return;
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
          context.lang.subscriptionAllApps,
        ];
      case 'Family':
        features = [
          context.lang.familyFeature1,
          context.lang.familyFeature2,
          context.lang.familyFeature3,
          context.lang.familyFeature4,
          context.lang.subscriptionAllApps,
        ];
      default:
    }

    final isCurrent = currentPlan == widget.plan;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        elevation: 0,
        color: context.color.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.color.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: FaIcon(
                      planIcon(widget.plan),
                      color: context.color.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.plan.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isCurrent) const CurrentPlanBadge(),
                ],
              ),
              const SizedBox(height: 16),
              ...features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: context.color.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feature,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: context.color.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (isCurrent && widget.plan != SubscriptionPlan.Tester)
                MyButton(
                  variant: MyButtonVariant.primaryMiddle,
                  onPressed: () async {
                    var url = 'https://apps.apple.com/account/subscriptions';
                    if (Platform.isAndroid) {
                      url =
                          'https://play.google.com/store/account/subscriptions?sku=${userService.currentUser.subscriptionPlanIdStore}&package=eu.twonly';
                    }
                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  child: Text(context.lang.subscriptionManage),
                ),
              if (widget.onPurchase != null &&
                  monthlyProduct != null &&
                  !isPayingUser(currentPlan)) ...[
                const SizedBox(height: 8),
                MyButton(
                  variant: MyButtonVariant.primaryMiddle,
                  onPressed: _isLoading != null
                      ? null
                      : () => onButtonPressed(monthlyProduct),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoading == monthlyProduct) ...[
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          context.lang.upgradeToPaidPlanButton(
                            widget.plan.name,
                            ' (${getFormattedPrice(monthlyProduct)}/${context.lang.month})',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (widget.onPurchase != null &&
                  (yearlyProduct != null && !isPayingUser(currentPlan))) ...[
                const SizedBox(height: 8),
                MyButton(
                  variant: MyButtonVariant.primaryMiddle,
                  onPressed: _isLoading != null
                      ? null
                      : () => onButtonPressed(yearlyProduct),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoading == yearlyProduct) ...[
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          context.lang.upgradeToPaidPlanButton(
                            widget.plan.name,
                            ' (${getFormattedPrice(yearlyProduct)}/${context.lang.year})',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final FaIconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FaIcon(
          icon,
          size: 24,
          color: context.color.primary.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
