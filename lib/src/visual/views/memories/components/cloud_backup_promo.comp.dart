import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/memories/memories_cloud.service.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/pro_badge.element.dart';

class MemoriesCloudBackupPromoComp extends StatelessWidget {
  const MemoriesCloudBackupPromoComp({super.key});

  @override
  Widget build(BuildContext context) {
    final isFreePlan =
        context.watch<PurchasesProvider>().plan == SubscriptionPlan.Free;

    return StreamBuilder<void>(
      stream: userService.onUserUpdated,
      builder: (context, snapshot) {
        final user = userService.currentUser;
        if (user.isCloudBackupEnabled || user.hideMemoriesBackupPromo) {
          return const SliverToBoxAdapter(
            child: SizedBox.shrink(),
          );
        }

        return SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: context.color.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: context.color.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                context.lang.memoriesBackupTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: context.color.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const ProBadge(),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.lang.settingsStorageNoCloudBackupCard,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.color.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            MyButton(
                              variant: MyButtonVariant.primaryDense,
                              onPressed: () async {
                                if (isFreePlan) {
                                  unawaited(
                                    context.push(Routes.settingsSubscription),
                                  );
                                  return;
                                }
                                await UserService.update(
                                  (u) => u.isCloudBackupEnabled = true,
                                );
                                unawaited(memoriesCloudService.checkUploads());
                              },
                              child: Text(context.lang.enable),
                            ),
                            TextButton(
                              onPressed: () async {
                                await UserService.update(
                                  (u) => u.hideMemoriesBackupPromo = true,
                                );
                              },
                              child: Text(
                                context.lang.settingsStorageHidePromo,
                                style: TextStyle(
                                  color: context.color.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
