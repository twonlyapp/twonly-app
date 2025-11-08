// ignore_for_file: constant_identifier_names

import 'package:twonly/globals.dart';

enum SubscriptionPlan {
  Free,
  Tester,
  Family,
  Pro,
  Plus,
}

bool isAdditionalAccount(SubscriptionPlan plan) {
  return plan == SubscriptionPlan.Free || plan == SubscriptionPlan.Plus;
}

bool isPayingUser(SubscriptionPlan plan) {
  return plan == SubscriptionPlan.Family ||
      plan == SubscriptionPlan.Pro ||
      plan == SubscriptionPlan.Tester;
}

SubscriptionPlan planFromString(String value) {
  final input = value.trim().toLowerCase();
  for (final v in SubscriptionPlan.values) {
    final name = v.name;
    final compareName = name.toLowerCase();
    if (compareName == input) return v;
  }
  return SubscriptionPlan.Free;
}

SubscriptionPlan getCurrentPlan() {
  return planFromString(gUser.subscriptionPlan);
}
