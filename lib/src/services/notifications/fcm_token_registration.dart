import 'dart:async';

/// Keeps token reads, rotation and server registration in the same order.
class FcmTokenRegistration {
  FcmTokenRegistration({
    required this.readToken,
    required this.deleteToken,
    required this.tokenRefreshes,
    required this.saveToken,
    required this.isAuthenticated,
    required this.uploadToken,
    required this.onError,
    this.tokenTimeout = const Duration(seconds: 25),
    this.requestTimeout = const Duration(seconds: 10),
  });

  final Future<String?> Function() readToken;
  final Future<void> Function() deleteToken;
  final Stream<String> Function() tokenRefreshes;
  final Future<void> Function(String) saveToken;
  final Future<bool> Function() isAuthenticated;
  final Future<void> Function(String) uploadToken;
  final void Function(Object, StackTrace) onError;
  final Duration tokenTimeout;
  final Duration requestTimeout;

  StreamSubscription<String>? _subscription;
  Future<void> _pending = Future.value();
  Future<void>? _refreshing;
  Future<void>? _resetting;
  int _generation = 0;
  bool _refreshAgain = false;

  void start() {
    _subscription ??= tokenRefreshes().listen(
      // Re-read the SDK instead of trusting an event that may have been queued
      // before a reset or a newer token refresh.
      (_) => unawaited(refresh().catchError(onError)),
      onError: onError,
    );
  }

  Future<void> refresh() {
    start();
    if (_refreshing != null) {
      _refreshAgain = true;
      return _refreshing!;
    }
    final generation = _generation;
    return _refreshing = _enqueue(() async {
      do {
        _refreshAgain = false;
        await _register(generation);
      } while (_refreshAgain && generation == _generation);
    }).whenComplete(() => _refreshing = null);
  }

  Future<void> reset() {
    start();
    if (_resetting != null) return _resetting!;
    final generation = ++_generation;
    return _resetting = _enqueue(() async {
      // Only rotate the messaging registration. Deleting the installation
      // first invalidates its token before a replacement is registered.
      await deleteToken().timeout(requestTimeout);
      await _register(generation);
    }).whenComplete(() => _resetting = null);
  }

  Future<void> _register(int generation) async {
    if (generation != _generation) return;
    final token = await readToken().timeout(tokenTimeout);
    if (generation != _generation) return;
    if (token == null || token.isEmpty) {
      throw StateError('Firebase did not return a messaging token');
    }
    await saveToken(token);
    if (generation != _generation) return;
    if (await isAuthenticated().timeout(requestTimeout)) {
      // Publish even an unchanged local token: the server may have retired its
      // registration while the device retained the same cached token.
      await uploadToken(token).timeout(requestTimeout);
    }
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final operation = _pending.then((_) => action());
    _pending = operation.catchError((Object _, StackTrace _) {});
    return operation;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _pending;
  }
}
