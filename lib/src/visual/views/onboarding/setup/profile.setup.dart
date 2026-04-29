import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/onboarding/setup/components/next_button.comp.dart';
import 'package:vector_graphics/vector_graphics.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final AvatarMakerController _avatarMakerController =
      PersistentAvatarMakerController(customizedPropertyCategories: []);
  late final TextEditingController _displayNameController;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.lang.onboardingProfileTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.lang.onboardingProfileBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.color.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 40),
        StreamBuilder(
          stream: userService.onUserUpdated,
          builder: (context, asyncSnapshot) {
            return Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.color.primary.withValues(alpha: 0.2),
                  width: 4,
                ),
              ),
              child: userService.currentUser.avatarSvg == null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(80),
                      child: Container(
                        width: 160,
                        height: 160,
                        color: context.color.surfaceContainer,
                        child: const SvgPicture(
                          AssetBytesLoader(
                            'assets/images/default_avatar.svg.vec',
                          ),
                        ),
                      ),
                    )
                  : AvatarMakerAvatar(
                      backgroundColor: context.color.surfaceContainer,
                      radius: 80,
                      controller: _avatarMakerController,
                    ),
            );
          },
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () async {
            await context.push(Routes.settingsProfileModifyAvatar);
            await _avatarMakerController.performRestore();
          },
          icon: const Icon(Icons.palette_outlined),
          label: Text(context.lang.settingsProfileCustomizeAvatar),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _displayNameController,
          decoration: InputDecoration(
            labelText: context.lang.settingsProfileEditDisplayName,
            hintText: context.lang.settingsProfileEditDisplayNameNew,
            prefixIcon: const Icon(Icons.person_outline),
            filled: true,
            fillColor: context.color.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.never,
          ),
        ),
        const SizedBox(height: 40),
        NextButtonComp(
          onPressed: () async {
            await UserService.update((user) {
              if (_displayNameController.text.isNotEmpty) {
                user.displayName = _displayNameController.text;
              }
            });
            return false;
          },
        ),
      ],
    );
  }
}
