import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:twonly/locator.dart';

class CustomChangeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  CustomChangeProvider() {
    // The API is connected before the subscription has started so ensure that the connection state is correct
    _isConnected = false;
    _connSub = apiService.events
        .where((event) => event.kind == ApiEventKind.connectionStateChanged)
        .listen(_handleConnectionState);
    unawaited(_loadConnectionState());
  }
  late bool _isConnected;
  late StreamSubscription<ApiEvent> _connSub;
  bool get isConnected => _isConnected;
  int _eventRevision = 0;
  bool _disposed = false;

  void _handleConnectionState(ApiEvent event) {
    _eventRevision++;
    // `suspended` is a lifecycle hint, not a transport disconnect: the socket
    // remains alive while Flutter is briefly covered or backgrounded. Keeping
    // the last known value prevents the avatar from flashing red during such a
    // transition.
    if (event.state == ApiConnectionState.suspended) return;
    unawaited(
      updateConnectionState(event.state == ApiConnectionState.authenticated),
    );
  }

  Future<void> _loadConnectionState() async {
    final revision = _eventRevision;
    try {
      final state = await RustApi.connectionState();
      if (_disposed || revision != _eventRevision) return;
      await updateConnectionState(state == ApiConnectionState.authenticated);
    } catch (_) {
      // Subsequent events remain authoritative if the initial query fails.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _connSub.cancel();
    super.dispose();
  }

  Future<void> updateConnectionState(bool update) async {
    if (_disposed || _isConnected == update) return;
    _isConnected = update;
    notifyListeners();
  }
}
