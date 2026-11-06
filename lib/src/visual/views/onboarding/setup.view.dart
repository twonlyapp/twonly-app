import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/core/user_config.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/onboarding/components/onboarding_step.comp.dart';
import 'package:twonly/src/visual/views/onboarding/setup/backup.setup.dart';
import 'package:twonly/src/visual/views/onboarding/setup/let_your_friends_find_you.setup.dart';
import 'package:twonly/src/visual/views/onboarding/setup/profile.setup.dart';
import 'package:twonly/src/visual/views/onboarding/setup/profile_selection.setup.dart';
import 'package:twonly/src/visual/views/onboarding/setup/share_your_friends.setup.dart';
import 'package:twonly/src/visual/views/settings/privacy/user_discovery/components/user_discovery_setup.comp.dart';

enum SetupPages {
  profile,
  backup,
  profileSelection,
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
      case SetupProfile.customized:
        return [
          SetupPages.profile,
          SetupPages.backup,
          SetupPages.profileSelection,
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
  bool _setupDone = false;

  // Steps slide in from the end when going forward and from the start when
  // going back.
  int _lastPageIndex = -1;
  bool _forward = true;

  @override
  void initState() {
    super.initState();
    state = UserDiscoverySetupState(setState: setState);

    if (widget.onUpdate != null) {
      _userUpdateStream = userService.onUserUpdated.listen((u) {
        if (userService.currentUser.currentSetupPage == null) {
          _notifySetupDone();
        }
      });
    }
  }

  /// Notifies the parent exactly once. Further user updates must not trigger
  /// another callback, otherwise a parent popping this view would pop the
  /// route below it as well.
  void _notifySetupDone() {
    if (_setupDone) return;
    _setupDone = true;
    unawaited(_userUpdateStream?.cancel());
    _userUpdateStream = null;
    widget.onUpdate?.call();
  }

  @override
  void dispose() {
    _userUpdateStream?.cancel();
    super.dispose();
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

        final previous = currentPage.previous();

        final pageIndex = SetupPagesExtension.activePages.indexOf(currentPage);
        if (pageIndex != _lastPageIndex) {
          _forward = pageIndex > _lastPageIndex;
          _lastPageIndex = pageIndex;
        }
        final currentKey = ValueKey(currentPage.name);
        final rtl = Directionality.of(context) == TextDirection.rtl;

        return OnboardingScaffold(
          onBack: previous == null
              ? null
              : () => UserService.update(
                  (u) => u.currentSetupPage = previous.name,
                ),
          progress: OnboardingProgress(
            current: currentPage.pageNumber,
            total: currentPage.totalPages,
          ),
          footer: currentPage.isLast
              ? null
              : Center(
                  child: MyButton(
                    onPressed: () async {
                      await UserService.update(
                        (u) => u.skipSetupPages = true,
                      );
                      _notifySetupDone();
                    },
                    variant: MyButtonVariant.text,
                    child: Text(context.lang.onboardingFinishLater),
                  ),
                ),
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              // The outgoing step runs this animation in reverse, so it
              // leaves to the side opposite to where the new one comes from.
              final incoming = child.key == currentKey;
              var dx = (incoming == _forward) ? 0.25 : -0.25;
              if (rtl) dx = -dx;
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(dx, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            // Steps fill the height so their button stays at the bottom.
            layoutBuilder: (current, previous) => Stack(
              fit: StackFit.expand,
              children: [...previous, ?current],
            ),
            child: KeyedSubtree(
              key: currentKey,
              child: _buildPage(currentPage, state),
            ),
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
      case SetupPages.shareYourFriends:
        return ShareYourFriendsSetupPage(state: state);
      case SetupPages.letYourFriendsFindYou:
        return LetYourFriendsFindYou(state: state);
    }
  }
}
