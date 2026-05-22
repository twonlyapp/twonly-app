import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/profile.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
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
      if (profile == SetupProfile.standard) {
        user.securityProfile = SecurityProfile.normal;
      } else if (profile == SetupProfile.maximum) {
        user.securityProfile = SecurityProfile.strict;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: userService.onUserUpdated,
      builder: (context, snapshot) {
        final user = userService.currentUser;
        final selectedProfile = user.setupProfile;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.lang.onboardingProfileSelectionTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.lang.onboardingProfileSelectionSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.color.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
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
            const SizedBox(height: 16),
            SafetyProfileCard(
              profile: SetupProfile.maximum,
              isSelected: selectedProfile == SetupProfile.maximum,
              isHovered: _hoveredProfile == SetupProfile.maximum,
              onHover: (hovered) => setState(() {
                _hoveredProfile = hovered ? SetupProfile.maximum : null;
              }),
              onTap: () => _onProfileTapped(SetupProfile.maximum),
            ),
            const SizedBox(height: 40),
            NextButtonComp(
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
          ],
        );
      },
    );
  }
}
