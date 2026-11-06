import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/onboarding/components/onboarding_step.comp.dart';
import 'package:twonly/src/visual/views/onboarding/setup/components/next_button.comp.dart';
import 'package:twonly/src/visual/views/settings/privacy/user_discovery/components/user_discovery_setup.comp.dart';

class LetYourFriendsFindYou extends StatefulWidget {
  const LetYourFriendsFindYou({required this.state, super.key});

  final UserDiscoverySetupState state;

  @override
  State<LetYourFriendsFindYou> createState() => _LetYourFriendsFindYouState();
}

class _LetYourFriendsFindYouState extends State<LetYourFriendsFindYou> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return OnboardingStep(
      button: NextButtonComp(
        isLoading: _isLoading,
        onPressed: () async {
          setState(() {
            _isLoading = true;
          });
          try {
            final result = await widget.state.initializeOrUpdate();
            return !result;
          } finally {
            setState(() {
              _isLoading = false;
            });
          }
        },
      ),
      children: [
        if (widget.state.isUserDiscoveryEnabled)
          UserDiscoverySetupComp(
            state: widget.state,
            showOnlySpecificPage: UserDiscoveryPages.letYourFriendsFindYou,
          )
        else ...[
          const SizedBox(height: 24),
          Lottie.asset(
            'assets/animations/takephoto.lottie',
            repeat: true,
            height: 150,
          ),
          const SizedBox(height: 48),
          Text(
            context.lang.onboardingSetupCompleteTitle(
              userService.currentUser.username,
            ),
            style: TextStyle(
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
              color: context.color.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            context.lang.onboardingSetupCompleteDesc,
            style: TextStyle(
              fontSize: 16,
              height: 1.45,
              color: context.color.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
