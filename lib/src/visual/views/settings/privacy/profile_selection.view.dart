import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/profile.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/onboarding/setup/components/profile_card.comp.dart';

class ProfileSelectionSettingsView extends StatefulWidget {
  const ProfileSelectionSettingsView({super.key});

  @override
  State<ProfileSelectionSettingsView> createState() =>
      _ProfileSelectionSettingsViewState();
}

class _ProfileSelectionSettingsViewState
    extends State<ProfileSelectionSettingsView> {
  SecurityProfile? _hoveredProfile;

  Future<void> _onProfileTapped(SecurityProfile profile) async {
    await UserService.update((user) {
      user.securityProfile = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.securityProfileTitle),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: StreamBuilder<void>(
            stream: userService.onUserUpdated,
            builder: (context, snapshot) {
              final user = userService.currentUser;
              final selectedProfile = user.securityProfile;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.lang.securityProfileSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.color.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SafetyProfileCard(
                    profile: SecurityProfile.normal,
                    isSelected: selectedProfile == SecurityProfile.normal,
                    isHovered: _hoveredProfile == SecurityProfile.normal,
                    onHover: (hovered) => setState(() {
                      _hoveredProfile = hovered ? SecurityProfile.normal : null;
                    }),
                    onTap: () => _onProfileTapped(SecurityProfile.normal),
                  ),
                  const SizedBox(height: 16),
                  SafetyProfileCard(
                    profile: SecurityProfile.strict,
                    isSelected: selectedProfile == SecurityProfile.strict,
                    isHovered: _hoveredProfile == SecurityProfile.strict,
                    onHover: (hovered) => setState(() {
                      _hoveredProfile = hovered ? SecurityProfile.strict : null;
                    }),
                    onTap: () => _onProfileTapped(SecurityProfile.strict),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
