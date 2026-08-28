import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:twonly/locator.dart';

class CustomChangeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  CustomChangeProvider() {
    // The API is connected before the subscription has started so ensure that the connection state is correct
    _isConnected = false;
    unawaited(_loadConnectionState());
    _connSub = apiService.events
        .where((event) => event.kind == ApiEventKind.connectionStateChanged)
        .listen(
          (event) => updateConnectionState(
            event.state == ApiConnectionState.authenticated,
          ),
        );
  }
  late bool _isConnected;
  late StreamSubscription<ApiEvent> _connSub;
  bool get isConnected => _isConnected;

  Future<void> _loadConnectionState() async {
    final state = await RustApi.connectionState();
    await updateConnectionState(state == ApiConnectionState.authenticated);
  }

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
