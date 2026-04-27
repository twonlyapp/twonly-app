import 'package:flutter/material.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/verification_badge_info.comp.dart';
import 'package:twonly/src/visual/views/onboarding/setup.view.dart';

class VerificationBadgeSetupPage extends StatelessWidget {
  const VerificationBadgeSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.lang.onboardingVerificationBadgeTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),
        const VerificationBadgeInfo(),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () async {
            await UserService.update((user) {
              user.currentSetupPage = SetupPages.verificationBadge.next()?.name;
            });
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: context.color.primary,
            foregroundColor: context.color.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            context.lang.understood,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
