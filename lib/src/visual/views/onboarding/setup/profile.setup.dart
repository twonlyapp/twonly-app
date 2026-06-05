import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart'
    show AvatarIcon;
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';
import 'package:twonly/src/visual/views/onboarding/setup/components/next_button.comp.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
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
    return StreamBuilder(
      stream: userService.onUserUpdated,
      builder: (context, asyncSnapshot) {
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
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.color.primary.withValues(alpha: 0.2),
                      width: 4,
                    ),
                  ),
                  child: const AvatarIcon(
                    fontSize: 68,
                    myAvatar: true,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            MyButton(
              onPressed: () async {
                await context.push(Routes.settingsProfileModifyAvatar);
              },
              variant: MyButtonVariant.text,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.palette_outlined),
                  const SizedBox(width: 8),
                  Text(context.lang.settingsProfileCustomizeAvatar),
                ],
              ),
            ),
            const SizedBox(height: 30),
            MyInput(
              controller: _displayNameController,
              hintText: context.lang.settingsProfileEditDisplayNameNew,
              prefixIcon: const Icon(Icons.person_outline),
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
      },
    );
  }
}
