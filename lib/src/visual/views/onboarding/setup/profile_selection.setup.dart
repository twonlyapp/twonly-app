import 'package:flutter/material.dart';
import 'package:twonly/core/user_config.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/onboarding/components/onboarding_step.comp.dart';
import 'package:twonly/src/visual/views/onboarding/setup/components/next_button.comp.dart';
import 'package:twonly/src/visual/views/onboarding/setup/components/profile_card.comp.dart';
import 'package:twonly/src/visual/views/settings/privacy/user_discovery/components/user_discovery_setup.comp.dart';

class ProfileSelectionSetup extends StatefulWidget {
  const ProfileSelectionSetup({super.key});

  @override
  State<ProfileSelectionSetup> createState() => _ProfileSelectionSetupState();
}

class _ProfileSelectionSetupState extends State<ProfileSelectionSetup> {
  SetupProfile? _hoveredProfile;
  bool _isLoading = false;

  Future<void> _onProfileTapped(SetupProfile profile) async {
    await UserService.update((user) {
      user.setupProfile = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: userService.onUserUpdated,
      builder: (context, snapshot) {
        final user = userService.currentUser;
        final selectedProfile = user.setupProfile;

        return OnboardingStep(
          title: context.lang.onboardingProfileSelectionTitle,
          body: context.lang.onboardingProfileSelectionSubtitle,
          button: NextButtonComp(
            key: ValueKey(selectedProfile),
            isLoading: _isLoading,
            onPressed: () async {
              if (selectedProfile == SetupProfile.standard) {
                setState(() {
                  _isLoading = true;
                });
                await UserDiscoverySetupState().initializeOrUpdate();
                setState(() {
                  _isLoading = false;
                });
              }
              return false;
            },
          ),
          children: [
            SafetyProfileCard(
              profile: SetupProfile.standard,
              isSelected: selectedProfile == SetupProfile.standard,
              isHovered: _hoveredProfile == SetupProfile.standard,
              onHover: (hovered) => setState(() {
                _hoveredProfile = hovered ? SetupProfile.standard : null;
              }),
              onTap: () => _onProfileTapped(SetupProfile.standard),
            ),
            const SizedBox(height: 16),
            SafetyProfileCard(
              profile: SetupProfile.customized,
              isSelected: selectedProfile == SetupProfile.customized,
              isHovered: _hoveredProfile == SetupProfile.customized,
              onHover: (hovered) => setState(() {
                _hoveredProfile = hovered ? SetupProfile.customized : null;
              }),
              onTap: () => _onProfileTapped(SetupProfile.customized),
            ),
          ],
        );
      },
    );
  }
}
