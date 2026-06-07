import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/profile.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/onboarding/setup/backup.setup.dart';
import 'package:twonly/src/visual/views/onboarding/setup/let_your_friends_find_you.setup.dart';
import 'package:twonly/src/visual/views/onboarding/setup/profile.setup.dart';
import 'package:twonly/src/visual/views/onboarding/setup/profile_selection.setup.dart';
import 'package:twonly/src/visual/views/onboarding/setup/security_profile.setup.dart';
import 'package:twonly/src/visual/views/onboarding/setup/share_your_friends.setup.dart';
import 'package:twonly/src/visual/views/onboarding/setup/verification_badge.setup.dart';
import 'package:twonly/src/visual/views/settings/privacy/user_discovery/components/user_discovery_setup.comp.dart';

enum SetupPages {
  profile,
  backup,
  profileSelection,
  securityProfile,
  verificationBadge,
  shareYourFriends,
  letYourFriendsFindYou,
}

extension SetupPagesExtension on SetupPages {
  static SetupPages fromStr(String? name) {
    return SetupPages.values.firstWhere(
      (e) => e.name == name,
      orElse: () => SetupPages.profile,
    );
  }

  static List<SetupPages> get activePages {
    final setupProfile = userService.currentUser.setupProfile;
    switch (setupProfile) {
      case SetupProfile.standard:
        return [
          SetupPages.profile,
          SetupPages.backup,
          SetupPages.profileSelection,
        ];
      case SetupProfile.maximum:
        return [
          SetupPages.profile,
          SetupPages.backup,
          SetupPages.profileSelection,
          SetupPages.verificationBadge,
        ];
      case SetupProfile.customized:
        return [
          SetupPages.profile,
          SetupPages.backup,
          SetupPages.profileSelection,
          SetupPages.securityProfile,
          SetupPages.verificationBadge,
          SetupPages.shareYourFriends,
          SetupPages.letYourFriendsFindYou,
        ];
    }
  }

  int get pageNumber {
    final idx = activePages.indexOf(this);
    return idx != -1 ? idx + 1 : 1;
  }

  int get totalPages => activePages.length;
  int get progressPercentage => ((pageNumber - 1) / totalPages * 100).round();
  String get progressText => '$pageNumber / $totalPages';

  bool get isLast {
    return activePages.isNotEmpty && activePages.last == this;
  }

  SetupPages? next() {
    final pages = activePages;
    final idx = pages.indexOf(this);
    if (idx != -1 && idx + 1 < pages.length) {
      return pages[idx + 1];
    }
    return null;
  }

  SetupPages? previous() {
    final pages = activePages;
    final idx = pages.indexOf(this);
    if (idx > 0) {
      return pages[idx - 1];
    }
    return null;
  }
}

class SetupView extends StatefulWidget {
  const SetupView({this.onUpdate, super.key});

  final VoidCallback? onUpdate;

  @override
  State<SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<SetupView> {
  StreamSubscription<void>? _userUpdateStream;
  late UserDiscoverySetupState state;

  @override
  void initState() {
    super.initState();
    state = UserDiscoverySetupState(setState: setState);

    if (widget.onUpdate != null) {
      _userUpdateStream = userService.onUserUpdated.listen((u) {
        if (userService.currentUser.currentSetupPage == null) {
          widget.onUpdate?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _userUpdateStream?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: userService.onUserUpdated,
      builder: (context, snapshot) {
        final user = userService.currentUser;
        final currentPageString = user.currentSetupPage;
        if (currentPageString == null) return const SizedBox.shrink();
        final currentPage = SetupPagesExtension.fromStr(currentPageString);

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(currentPage.totalPages, (index) {
                    final isFinished = index < currentPage.pageNumber;
                    return Expanded(
                      child: Container(
                        height: 6,
                        margin: EdgeInsets.only(
                          right: index == currentPage.totalPages - 1 ? 0 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: isFinished
                              ? context.color.primary
                              : context.color.surfaceContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            toolbarHeight: 48,
          ),
          body: ListView(
            key: ValueKey(currentPage.name),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              _buildPage(currentPage, state),
              if (currentPage.index > 0 || !currentPage.isLast)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (currentPage.index > 0)
                        MyButton(
                          onPressed: () async {
                            await UserService.update((u) {
                              u.currentSetupPage = currentPage.previous()?.name;
                            });
                          },
                          variant: MyButtonVariant.text,
                          child: Text(
                            context.lang.back,
                          ),
                        ),
                      if (currentPage.index > 0 && !currentPage.isLast)
                        const SizedBox(width: 24),
                      if (!currentPage.isLast)
                        MyButton(
                          onPressed: () async {
                            await UserService.update(
                              (u) => u.skipSetupPages = true,
                            );
                            widget.onUpdate?.call();
                          },
                          variant: MyButtonVariant.text,
                          child: Text(
                            context.lang.onboardingFinishLater,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPage(SetupPages page, UserDiscoverySetupState state) {
    switch (page) {
      case SetupPages.profile:
        return const ProfileSetupPage();
      case SetupPages.backup:
        return const BackupSetupPage();
      case SetupPages.profileSelection:
        return const ProfileSelectionSetup();
      case SetupPages.securityProfile:
        return const SecurityProfileSetup();
      case SetupPages.verificationBadge:
        return const VerificationBadgeSetupPage();
      case SetupPages.shareYourFriends:
        return ShareYourFriendsSetupPage(state: state);
      case SetupPages.letYourFriendsFindYou:
        return LetYourFriendsFindYou(state: state);
    }
  }
}
