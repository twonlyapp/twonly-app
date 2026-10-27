import 'dart:async';

/// Orders lifecycle and reachability updates across asynchronous bridge calls.
class ConnectionLifecycle {
  ConnectionLifecycle({
    required this.readNetworkAvailable,
    required this.applyNetworkAvailable,
    required this.applyBackground,
    required this.onError,
    this.hasActiveConnection,
  });

  final Future<bool> Function() readNetworkAvailable;
  final Future<bool> Function()? hasActiveConnection;
  final Future<void> Function(bool) applyNetworkAvailable;
  final Future<void> Function(bool) applyBackground;
  final void Function(Object, StackTrace) onError;
  Future<void> _pending = Future.value();
  bool _inBackground = false;
  Object? _lastNetworkIdentity;
  bool _hasNetworkObservation = false;

  Future<void> setBackground(bool background) => _enqueue(() async {
    if (!background && _inBackground) {
      // Connectivity streams can miss changes while the process is suspended.
      // Update reachability before Rust starts the foreground connection.
      await _refreshNetwork();
    }
    await applyBackground(background);
    _inBackground = background;
  });

  Future<void> networkChanged({Object? identity}) => _enqueue(() async {
    if (identity != null && identity == _lastNetworkIdentity) return;
    await _refreshNetwork(initial: !_hasNetworkObservation);
    _hasNetworkObservation = true;
    _lastNetworkIdentity = identity;
  });

  Future<void> _refreshNetwork({bool initial = false}) async {
    bool available;
    try {
      available = await readNetworkAvailable();
    } catch (error, stack) {
      onError(error, stack);
      // A failed reachability query must not strand the client behind an old
      // offline flag. Let the transport try and apply its normal retry policy.
      available = true;
    }
    // Preserve an in-flight startup socket, but still restore a retained Rust
    // runtime whose cached offline state prevented it from connecting.
    if (initial && available && hasActiveConnection != null) {
      try {
        if (await hasActiveConnection!()) return;
      } catch (error, stack) {
        onError(error, stack);
      }
    }
    await applyNetworkAvailable(available);
  }

  Future<void> _enqueue(Future<void> Function() update) {
    return _pending = _pending.then((_) => update()).catchError(onError);
  }
}
