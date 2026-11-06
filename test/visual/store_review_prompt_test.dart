import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/components/store_review_prompt.comp.dart';

import '../mocks/user_config.dart';

void main() {
  setUp(() async {
    await locator.reset();
    locator.registerSingleton<UserService>(UserService());
  });
  tearDown(locator.reset);

  void setUser({
    required SubscriptionPlan plan,
    bool showStoreReviewPrompt = true,
    String? currentSetupPage,
  }) {
    userService.currentUser = testUserConfig(
      userId: 1,
      username: 'me',
      displayName: 'Me',
      subscriptionPlan: plan.name,
      currentSetupPage: currentSetupPage,
      appVersion: 192,
    )..showStoreReviewPrompt = showStoreReviewPrompt;
  }

  for (final plan in SubscriptionPlan.values) {
    test('review prompt for ${plan.name}', () {
      setUser(plan: plan);
      expect(
        StoreReviewPromptPresenter.isDue,
        plan == SubscriptionPlan.Tester,
      );
    });
  }

  test('no review prompt after "Don\'t show again"', () {
    setUser(plan: SubscriptionPlan.Tester, showStoreReviewPrompt: false);
    expect(StoreReviewPromptPresenter.isDue, isFalse);
  });

  test('no review prompt during the setup', () {
    setUser(plan: SubscriptionPlan.Tester, currentSetupPage: 'profile');
    expect(StoreReviewPromptPresenter.isDue, isFalse);
  });
}
