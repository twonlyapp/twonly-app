import 'dart:async';
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/memories/memories_cloud.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

class MemoriesCloudBackupPromoComp extends StatelessWidget {
  const MemoriesCloudBackupPromoComp({super.key});

  @override
  Widget build(BuildContext context) {
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
              horizontal: 8,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  context.color.primaryContainer.withValues(alpha: 0.15),
                  context.color.primaryContainer.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: context.color.primary.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.lang.memoriesBackupTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: context.color.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.lang.settingsStorageNoCloudBackupCard,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.color.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            MyButton(
                              variant: MyButtonVariant.primaryDense,
                              onPressed: () async {
                                await UserService.update(
                                  (u) => u.isCloudBackupEnabled = true,
                                );
                                unawaited(memoriesCloudService.checkUploads());
                              },
                              child: Text(context.lang.enable),
                            ),
                            const SizedBox(width: 8),
                            MyButton(
                              variant: MyButtonVariant.secondaryDense,
                              onPressed: () async {
                                await UserService.update(
                                  (u) => u.hideMemoriesBackupPromo = true,
                                );
                              },
                              child: Text(
                                context.lang.settingsStorageHidePromo,
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
