import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:twonly/globals.dart';

class CustomChangeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  CustomChangeProvider() {
    _connSub = apiService.onConnectionStateUpdated.listen(
      updateConnectionState,
    );
  }
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  late StreamSubscription<bool> _connSub;

  @override
  void dispose() {
    _connSub.cancel();
    super.dispose();
  }

  Future<void> updateConnectionState(bool update) async {
    _isConnected = update;
    notifyListeners();
  }
}
