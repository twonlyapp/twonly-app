import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/services/user_discovery.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/verification_badge.comp.dart';
import 'package:twonly/src/visual/views/contact/add_new_contact_components/friend_suggestions.comp.dart';
import 'package:twonly/src/visual/views/onboarding/setup/components/mock_contact_request_actions.comp.dart';

List<String> getExampleUsers(BuildContext context) => [
  context.lang.exampleUserName1,
  context.lang.exampleUserName2,
  context.lang.exampleUserName3,
  context.lang.exampleUserName4,
  context.lang.exampleUserName5,
  context.lang.exampleUserName6,
  context.lang.exampleUserName7,
  context.lang.exampleUserName8,
  context.lang.exampleUserName9,
  context.lang.exampleUserName10,
  context.lang.exampleUserName11,
];

class UserDiscoverySetupState {
  UserDiscoverySetupState({
    required this.setState,
    this.isUserDiscoveryEnabled = true,
    this.sharePromotion = true,
    this.isManualApprovalEnabled = false,
    this.threshold = 3,
    this.requiredSendImages = 4,
  });

  bool wasChanged = false;

  bool isUserDiscoveryEnabled;
  int threshold;
  bool sharePromotion;

  bool isManualApprovalEnabled;
  int requiredSendImages;

  void Function(void Function()) setState;

  void update(void Function() update) {
    update();
    setState(() {
      wasChanged = true;
    });
  }

  Future<bool> initializeOrUpdate() async {
    try {
      Log.info('UserDiscoverySetupState: initializeOrUpdate started');
      var hasError = false;
      if (isUserDiscoveryEnabled) {
        Log.info('UserDiscoverySetupState: initializing UserDiscoveryService');
        try {
          await UserDiscoveryService.initializeOrUpdate(
            threshold: threshold,
            sharePromotion: sharePromotion,
          );
        } catch (e) {
          Log.error(
            'UserDiscoverySetupState: UserDiscoveryService failed or timed out: $e',
          );
          hasError = true;
        }
      }

      Log.info('UserDiscoverySetupState: updating UserService');
      await UserService.update((u) {
        u
          ..isUserDiscoveryEnabled = isUserDiscoveryEnabled
          ..requiredSendImages = requiredSendImages
          ..userDiscoveryRequiresManualApproval = isManualApprovalEnabled
          ..userDiscoveryInitializationError = hasError;
      });

      Log.info('UserDiscoverySetupState: initializeOrUpdate finished');
      return true;
    } catch (e) {
      Log.error('UserDiscoverySetupState: initializeOrUpdate failed: $e');
      return false;
    }
  }
}

enum UserDiscoveryPages { all, shareYourFriends, letYourFriendsFindYou }

class UserDiscoverySetupComp extends StatelessWidget {
  const UserDiscoverySetupComp({
    required this.state,
    this.showOnlySpecificPage = UserDiscoveryPages.all,
    super.key,
  });

  final UserDiscoverySetupState state;
  final UserDiscoveryPages showOnlySpecificPage;

  @override
  Widget build(BuildContext context) {
    final showShareYourFriends =
        showOnlySpecificPage == UserDiscoveryPages.all ||
        showOnlySpecificPage == UserDiscoveryPages.shareYourFriends;
    final showLetYourFriendsFindYou =
        showOnlySpecificPage == UserDiscoveryPages.all ||
        showOnlySpecificPage == UserDiscoveryPages.letYourFriendsFindYou;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showShareYourFriends) ...[
            Text(
              context.lang.onboardingUserDiscoveryShareFriends,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // First description text (centered, no card/title/icon)
            RichText(
              text: TextSpan(
                children: formattedText(
                  context,
                  context.lang.onboardingUserDiscoveryShareFriendsDesc,
                ),
                style: TextStyle(
                  color: context.color.onSurface,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.color.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.color.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.lang.userDiscoveryFeatureOffers,
                    style: TextStyle(
                      fontSize: 16,
                      color: context.color.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.lang.onboardingUserDiscoveryWhoIsRequesting,
                    style: TextStyle(
                      color: context.color.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: context.color.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.color.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const AvatarIcon(fontSize: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.lang.exampleJane,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: buildFriendsListTextString(
                                      context,
                                      [
                                        context.lang.exampleUserName2,
                                        context.lang.exampleUserName1,
                                      ],
                                    ),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: context.color.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const MockContactRequestActionsComp(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.lang.onboardingUserDiscoveryContactsVerifiedBadge,
                    style: TextStyle(
                      color: context.color.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: context.color.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.color.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AvatarIcon(fontSize: 12),
                          const SizedBox(width: 8),
                          Text(
                            context.lang.exampleJane,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const VerificationBadgeComp(
                            isVerifiedByTransferredTrust: true,
                            size: 14,
                            clickable: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Checkboxes / settings Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.color.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.color.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    value: state.isUserDiscoveryEnabled,
                    onChanged: (val) => state.update(() {
                      state.isUserDiscoveryEnabled = val;
                    }),
                    title: Text(
                      context.lang.onboardingUserDiscoveryShareFriends,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    tileColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(
                      width: double.infinity,
                      height: 0,
                    ),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Divider(
                            color: context.color.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        SwitchListTile(
                          value: state.isManualApprovalEnabled,
                          onChanged: (val) => state.update(
                            () => state.isManualApprovalEnabled = val,
                          ),
                          title: Text(
                            context.lang.userDiscoverySettingsManualApproval,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            context
                                .lang
                                .userDiscoverySettingsManualApprovalDesc,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.color.onSurfaceVariant,
                            ),
                          ),
                          tileColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ],
                    ),
                    crossFadeState: state.isUserDiscoveryEnabled
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
            if (showOnlySpecificPage == UserDiscoveryPages.all)
              const SizedBox(height: 48),
          ],
          if (showLetYourFriendsFindYou) ...[
            Text(
              context.lang.onboardingUserDiscoveryLetFriendsFindYou,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // First description text (centered, no card/title/icon)
            RichText(
              text: TextSpan(
                children: formattedText(
                  context,
                  context.lang.userDiscoveryDisabledIntro,
                ),
                style: TextStyle(
                  color: context.color.onSurface,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.color.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.color.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.lang.userDiscoveryFeatureOffers,
                    style: TextStyle(
                      fontSize: 16,
                      color: context.color.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.lang.onboardingUserDiscoveryWhatOthersSee,
                    style: TextStyle(
                      color: context.color.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: context.color.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.color.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const AvatarIcon(fontSize: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userService.currentUser.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: buildFriendsListTextString(
                                      context,
                                      getExampleUsers(context).sublist(
                                        0,
                                        state.threshold,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.color.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const MockContactSuggestedActionsComp(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.lang.onboardingUserDiscoveryWhatYouSee,
                    style: TextStyle(
                      color: context.color.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: context.color.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.color.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const AvatarIcon(fontSize: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.lang.exampleJane,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: buildFriendsListTextString(
                                      context,
                                      getExampleUsers(context).sublist(
                                        0,
                                        state.threshold,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: context.color.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const MockContactRequestActionsComp(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Checkboxes / settings Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.color.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.color.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    value: state.sharePromotion,
                    onChanged: (val) => state.update(() {
                      state.sharePromotion = val;
                    }),
                    title: Text(
                      context.lang.onboardingUserDiscoveryBeRecommended,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    tileColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(
                      width: double.infinity,
                      height: 0,
                    ),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Divider(
                            color: context.color.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context
                                      .lang
                                      .userDiscoverySettingsMutualFriends,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: context.color.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: context.color.outlineVariant
                                        .withValues(
                                          alpha: 0.5,
                                        ),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: state.threshold,
                                    style: TextStyle(
                                      color: context.color.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    items: List.generate(
                                      9,
                                      (index) {
                                        final value = index + 2;
                                        return DropdownMenuItem<int>(
                                          value: value,
                                          child: Text('$value'),
                                        );
                                      },
                                    ),
                                    onChanged: (newValue) {
                                      if (newValue != null) {
                                        state.update(() {
                                          state.threshold = newValue;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    crossFadeState: state.sharePromotion
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
