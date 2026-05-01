import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/onboarding/setup.view.dart';

class FinishSetupComp extends StatefulWidget {
  const FinishSetupComp({super.key});

  @override
  State<FinishSetupComp> createState() => _FinishSetupCompState();
}

class _FinishSetupCompState extends State<FinishSetupComp> {
  Future<void> onTap() async {
    await context.navPush(
      SetupView(
        onUpdate: () {
          if (mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: userService.onUserUpdated,
      builder: (context, snapshot) {
        final user = userService.currentUser;

        if (user.currentSetupPage == null) {
          return const SizedBox.shrink();
        }

        final currentPage = SetupPagesExtension.fromStr(user.currentSetupPage);
        final progress = currentPage.progressPercentage / 100;

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                context.color.primaryContainer.withValues(alpha: 0.2),
                context.color.primaryContainer.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: context.color.primary.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: context.color.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 68,
                      height: 68,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 6,
                            backgroundColor: context.color.onSurface.withValues(
                              alpha: 0.12,
                            ),
                            color: context.color.primary,
                            strokeCap: StrokeCap.round,
                          ),
                          Center(
                            child: Text(
                              '${currentPage.progressPercentage}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: context.color.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.lang.finishSetupCardTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              color: context.color.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.lang.finishSetupCardDesc,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.color.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: onTap,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                            label: Text(
                              context.lang.finishSetupCardAction,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: context.color.primary,
                              foregroundColor: context.color.onPrimary,
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
