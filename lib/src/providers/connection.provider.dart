import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:twonly/locator.dart';

class CustomChangeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  CustomChangeProvider() {
    // The API is connected before the subscription has started so ensure that the connection state is correct
    _isConnected = apiService.isConnected;
    _connSub = apiService.onConnectionStateUpdated.listen(
      updateConnectionState,
    );
  }
  late bool _isConnected;
  late StreamSubscription<bool> _connSub;
  bool get isConnected => _isConnected;

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
