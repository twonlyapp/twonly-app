import 'package:flutter/material.dart';
import 'package:twonly/src/visual/views/onboarding/components/onboarding_step.comp.dart';
import 'package:twonly/src/visual/views/onboarding/setup/components/next_button.comp.dart';
import 'package:twonly/src/visual/views/settings/privacy/user_discovery/components/user_discovery_setup.comp.dart';

class ShareYourFriendsSetupPage extends StatefulWidget {
  const ShareYourFriendsSetupPage({required this.state, super.key});

  final UserDiscoverySetupState state;

  @override
  State<ShareYourFriendsSetupPage> createState() =>
      _ShareYourFriendsSetupPageState();
}

class _ShareYourFriendsSetupPageState extends State<ShareYourFriendsSetupPage> {
  @override
  Widget build(BuildContext context) {
    return OnboardingStep(
      button: const NextButtonComp(),
      children: [
        UserDiscoverySetupComp(
          state: widget.state,
          showOnlySpecificPage: UserDiscoveryPages.shareYourFriends,
        ),
      ],
    );
  }
}
