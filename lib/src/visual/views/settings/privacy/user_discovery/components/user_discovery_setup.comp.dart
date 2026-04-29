import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/services/user_discovery.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/verification_badge.comp.dart';
import 'package:twonly/src/visual/views/contact/add_new_contact_components/friend_suggestions.comp.dart';
import 'package:twonly/src/visual/views/onboarding/setup/components/mock_contact_request_actions.comp.dart';
import 'package:twonly/src/visual/views/onboarding/setup/components/setup_switch_card.comp.dart';

const exampleUsers = [
  'james',
  'mary',
  'john',
  'patricia',
  'robert',
  'jennifer',
  'michael',
  'linda',
  'william',
  'lena',
  'david',
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
    if (isUserDiscoveryEnabled) {
      await UserDiscoveryService.initializeOrUpdate(
        threshold: threshold,
        sharePromotion: sharePromotion,
      );
    }

    await UserService.update((u) {
      u
        ..isUserDiscoveryEnabled = isUserDiscoveryEnabled
        ..requiredSendImages = requiredSendImages
        ..userDiscoveryRequiresManualApproval = isManualApprovalEnabled;
    });

    return true;
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

            const SizedBox(height: 32),

            SetupSwitchCard(
              value: state.isUserDiscoveryEnabled,
              onChanged: (val) => state.update(() {
                state.isUserDiscoveryEnabled = val;
                if (!val) {
                  state.sharePromotion = false;
                }
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
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
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
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AvatarIcon(fontSize: 12),
                          SizedBox(width: 5),
                          Text(
                            'jane',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 5),
                          VerificationBadgeComp(
                            isVerifiedByTransferredTrust: true,
                            size: 14,
                            clickable: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                                const Text(
                                  'jane',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: buildFriendsListTextString(
                                      context,
                                      [
                                        'mary',
                                        'james',
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
                if (val) {
                  state.isUserDiscoveryEnabled = true;
                }
                state.sharePromotion = val;
              }),
              title: context.lang.onboardingUserDiscoveryBeRecommended,
              expandedChild: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
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
                    const SizedBox(height: 16),
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
                                        exampleUsers.sublist(
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
                                  const Text(
                                    'jane',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      children: buildFriendsListTextString(
                                        context,
                                        exampleUsers.sublist(
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
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
