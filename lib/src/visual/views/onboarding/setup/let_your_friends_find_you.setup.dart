import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/utils/misc.dart';
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.state.isUserDiscoveryEnabled)
            UserDiscoverySetupComp(
              state: widget.state,
              showOnlySpecificPage: UserDiscoveryPages.letYourFriendsFindYou,
            )
          else
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Lottie.asset(
                    'assets/animations/takephoto.lottie',
                    repeat: true,
                    height: 150,
                  ),
                  const SizedBox(height: 60),
                  Text(
                    context.lang.onboardingSetupCompleteTitle(
                      userService.currentUser.username,
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.lang.onboardingSetupCompleteDesc,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 50),
          NextButtonComp(
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
        ],
      ),
    );
  }
}
