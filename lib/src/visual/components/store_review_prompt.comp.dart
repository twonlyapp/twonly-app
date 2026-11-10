import 'dart:io';

import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/prompt_sheet.comp.dart';
import 'package:url_launcher/url_launcher.dart';

/// Asks testers for a store review once per app start, after they stayed on
/// the chat list for [delay], until they open the store or tap "Don't show
/// again".
class StoreReviewPromptPresenter {
  StoreReviewPromptPresenter._();

  static const Duration delay = Duration(seconds: 4);

  static bool _handledThisSession = false;

  /// Leaves the prompt for the next app start, e.g. because another sheet
  /// was already shown in this one.
  static void skipThisSession() => _handledThisSession = true;

  static bool get isDue {
    if (_handledThisSession) return false;
    final user = userService.currentUser;
    return user.showStoreReviewPrompt &&
        user.currentSetupPage == null &&
        planFromString(user.subscriptionPlan) == SubscriptionPlan.Tester;
  }

  static Future<void> showIfDue(BuildContext context) async {
    if (!isDue) return;
    _handledThisSession = true;
    await showStoreReviewPromptSheet(context);
  }
}

Future<void> showStoreReviewPromptSheet(BuildContext context) {
  return showPromptSheet(context, const StoreReviewPromptSheet());
}

class StoreReviewPromptSheet extends StatelessWidget {
  const StoreReviewPromptSheet({super.key});

  static final Uri _storeUri = Platform.isIOS
      ? Uri.parse('https://apps.apple.com/app/id6743774441?action=write-review')
      : Uri.parse('https://play.google.com/store/apps/details?id=eu.twonly');

  Future<void> _openStore(BuildContext context) async {
    // Whoever made it to the store page is not asked again.
    await UserService.update((u) => u.showStoreReviewPrompt = false);
    if (context.mounted) Navigator.pop(context);
    await launchUrl(_storeUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _hideForever(BuildContext context) async {
    await UserService.update((u) => u.showStoreReviewPrompt = false);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PromptSheet(
      illustration: _StarArc(color: context.color.primary),
      title: context.lang.storeReviewPromptTitle,
      description: context.lang.storeReviewPromptDesc(
        Platform.isIOS ? 'App Store' : 'Play Store',
      ),
      primaryLabel: context.lang.storeReviewPromptReview,
      onPrimary: () => _openStore(context),
      secondaryLabel: context.lang.storeReviewPromptHide,
      onSecondary: () => _hideForever(context),
    );
  }
}

/// Five stars on an arc, the middle one largest and highest.
class _StarArc extends StatelessWidget {
  const _StarArc({required this.color});

  final Color color;

  static const _sizes = [30.0, 36.0, 44.0, 36.0, 30.0];
  static const _drops = [22.0, 6.0, 0.0, 6.0, 22.0];
  static const _tilts = [-0.35, -0.17, 0.0, 0.17, 0.35];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: EdgeInsets.only(top: _drops[i], left: 2, right: 2),
            child: Transform.rotate(
              angle: _tilts[i],
              child: Icon(Icons.star_rounded, size: _sizes[i], color: color),
            ),
          ),
      ],
    );
  }
}
