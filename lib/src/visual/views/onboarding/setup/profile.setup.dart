import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/onboarding/components/onboarding_step.comp.dart';
import 'package:twonly/src/visual/views/onboarding/setup/components/next_button.comp.dart';
import 'package:twonly/src/visual/views/settings/profile/modify_avatar.view.dart';
import 'package:vector_graphics/vector_graphics_compat.dart'
    show RenderingStrategy;

/// Only the public avatar. The display name stays the username and the
/// photo avatar is left for the profile settings.
class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({super.key});

  static const _avatarSize = 168.0;

  Future<void> _openAvatarEditor(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const SvgAvatarEditorView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: userService.onUserUpdated,
      builder: (context, _) {
        final svg = userService.currentUser.avatarSvg;
        final hasAvatar = svg != null && svg.isNotEmpty;

        return OnboardingStep(
          title: context.lang.onboardingProfileTitle,
          body: context.lang.onboardingProfileBody,
          button: const NextButtonComp(),
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _openAvatarEditor(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.color.primary.withValues(alpha: 0.4),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: SizedBox.square(
                          dimension: _avatarSize,
                          child: ColoredBox(
                            color: context.color.surfaceContainerHigh,
                            child: hasAvatar
                                ? SvgPicture.string(
                                    svg,
                                    width: _avatarSize,
                                    height: _avatarSize,
                                    renderingStrategy: RenderingStrategy.raster,
                                  )
                                : Icon(
                                    Icons.person_outline,
                                    size: 84,
                                    color: context.color.onSurfaceVariant,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  MyButton(
                    variant: MyButtonVariant.secondaryMiddle,
                    onPressed: () => _openAvatarEditor(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.palette_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(context.lang.settingsProfileCustomizeAvatar),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
