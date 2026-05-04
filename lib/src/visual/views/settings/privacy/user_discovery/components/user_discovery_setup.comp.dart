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
import 'package:twonly/src/visual/views/onboarding/setup/components/setup_switch_card.comp.dart';

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
    this.threshold = 2,
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
      if (isUserDiscoveryEnabled) {
        Log.info('UserDiscoverySetupState: initializing UserDiscoveryService');
        await UserDiscoveryService.initializeOrUpdate(
          threshold: threshold,
          sharePromotion: sharePromotion,
        );
      }

      Log.info('UserDiscoverySetupState: updating UserService');
      await UserService.update((u) {
        u
          ..isUserDiscoveryEnabled = isUserDiscoveryEnabled
          ..requiredSendImages = requiredSendImages
          ..userDiscoveryRequiresManualApproval = isManualApprovalEnabled;
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showOnlySpecificPage == UserDiscoveryPages.all ||
              showOnlySpecificPage == UserDiscoveryPages.shareYourFriends) ...[
            Text(
              context.lang.onboardingUserDiscoveryShareFriends,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            RichText(
              text: TextSpan(
                children: formattedText(
                  context,
                  context.lang.onboardingUserDiscoveryShareFriendsDesc,
                ),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            SetupSwitchCard(
              value: state.isUserDiscoveryEnabled,
              onChanged: (val) => state.update(() {
                state.isUserDiscoveryEnabled = val;
              }),
              title: context.lang.onboardingUserDiscoveryShareFriends,
              expandedChild: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    value: state.isManualApprovalEnabled,
                    onChanged: (val) => state.update(
                      () => state.isManualApprovalEnabled = val,
                    ),
                    title: Text(
                      context.lang.userDiscoverySettingsManualApproval,
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      context.lang.userDiscoverySettingsManualApprovalDesc,
                      style: const TextStyle(fontSize: 10),
                    ),
                    tileColor: context.color.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Divider(),
                  ),
                  const _ExampleLabel(),
                  Text(
                    context.lang.onboardingUserDiscoveryWhoIsRequesting,
                    style: TextStyle(
                      color: context.color.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AvatarIcon(fontSize: 14),
                          const SizedBox(width: 5),
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
                                    style: const TextStyle(fontSize: 10),
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

                  const SizedBox(height: 24),
                  Text(
                    context.lang.onboardingUserDiscoveryContactsVerifiedBadge,
                    style: TextStyle(
                      color: context.color.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AvatarIcon(fontSize: 12),
                          const SizedBox(width: 5),
                          Text(
                            context.lang.exampleJane,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const VerificationBadgeComp(
                            isVerifiedByTransferredTrust: true,
                            size: 14,
                            clickable: false,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            if (showOnlySpecificPage == UserDiscoveryPages.all)
              const SizedBox(height: 80),
          ],

          if (showOnlySpecificPage == UserDiscoveryPages.all ||
              showOnlySpecificPage ==
                  UserDiscoveryPages.letYourFriendsFindYou) ...[
            Text(
              context.lang.onboardingUserDiscoveryLetFriendsFindYou,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            RichText(
              text: TextSpan(
                children: formattedText(
                  context,
                  context.lang.userDiscoveryDisabledIntro,
                ),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            SetupSwitchCard(
              value: state.sharePromotion,
              onChanged: (val) => state.update(() {
                state.sharePromotion = val;
              }),
              title: context.lang.onboardingUserDiscoveryBeRecommended,
              expandedChild: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.lang.userDiscoverySettingsMutualFriends,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: state.threshold,
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
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8, top: 8),
                    child: Divider(),
                  ),
                  const _ExampleLabel(),
                  Text(
                    context.lang.onboardingUserDiscoveryWhatOthersSee,
                    style: TextStyle(
                      color: context.color.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AvatarIcon(fontSize: 14),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userService.currentUser.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
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
                                    style: const TextStyle(fontSize: 11),
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
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AvatarIcon(fontSize: 14),
                          const SizedBox(width: 5),
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
                                    style: const TextStyle(fontSize: 10),
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
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExampleLabel extends StatelessWidget {
  const _ExampleLabel();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            context.lang.onboardingExampleLabel,
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
