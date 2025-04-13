import 'package:flutter/foundation.dart';

class ConnectionChangeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  Future<void> updateConnectionState(bool update) async {
    _isConnected = update;
    notifyListeners();
  }
}
