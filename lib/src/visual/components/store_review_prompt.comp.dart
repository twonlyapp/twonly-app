import 'dart:io';

import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
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
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const StoreReviewPromptSheet(),
  );
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
    final accent = context.color.primary;
    return Material(
      color: context.color.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.color.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.star_rounded, size: 34, color: accent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.lang.storeReviewPromptTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.lang.storeReviewPromptDesc(
                      Platform.isIOS ? 'App Store' : 'Play Store',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.color.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 24),
                  MyButton(
                    onPressed: () => _openStore(context),
                    child: Text(context.lang.storeReviewPromptReview),
                  ),
                  const SizedBox(height: 12),
                  MyButton(
                    variant: MyButtonVariant.secondaryMiddle,
                    onPressed: () => _hideForever(context),
                    child: Text(context.lang.storeReviewPromptHide),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
