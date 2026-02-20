import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/services/subscription.service.dart';

void main() {
  group('testing subscription permissions', () {
    test('test if restore flames is allowed', () {
      expect(
        true,
        isUserAllowed(SubscriptionPlan.Plus, PremiumFeatures.RestoreFlames),
      );
      expect(
        false,
        isUserAllowed(SubscriptionPlan.Free, PremiumFeatures.RestoreFlames),
      );
    });
  });
}
