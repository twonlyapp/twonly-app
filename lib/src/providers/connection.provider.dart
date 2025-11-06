import 'package:flutter/foundation.dart';
import 'package:twonly/src/services/subscription.service.dart';

class CustomChangeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  SubscriptionPlan plan = SubscriptionPlan.Free;
  Future<void> updateConnectionState(bool update) async {
    _isConnected = update;
    notifyListeners();
  }

  Future<void> updatePlan(SubscriptionPlan newPlan) async {
    plan = newPlan;
    notifyListeners();
  }
}
