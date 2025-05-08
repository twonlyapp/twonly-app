import 'package:flutter/foundation.dart';

class CustomChangeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  String plan = "Preview";
  Future<void> updateConnectionState(bool update) async {
    _isConnected = update;
    notifyListeners();
  }

  Future<void> updatePlan(String newPlan) async {
    plan = newPlan;
    notifyListeners();
  }
}
