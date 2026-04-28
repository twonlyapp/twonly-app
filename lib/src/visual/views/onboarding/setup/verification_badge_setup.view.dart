import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/verification_badge_info.comp.dart';
import 'package:twonly/src/visual/views/onboarding/setup/components/next_button.comp.dart';

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
        const SizedBox(height: 60),
        const NextButtonComp(),
      ],
    );
  }
}
