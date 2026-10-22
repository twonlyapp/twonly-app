/// Coalesces backup requests and admits work only while the app is resumed.
/// The caller must also recheck admission after acquiring its recovery mutex.
class BackupSchedule {
  BackupSchedule({
    required this.isVisible,
    required this.perform,
    this.loadForced,
    this.saveForced,
  });

  final bool Function() isVisible;

  /// False means native admission was deferred; retain the request for a
  /// future resume/retry without spinning while the app is still visible.
  final Future<bool> Function(bool force) perform;
  final Future<bool> Function()? loadForced;
  final Future<void> Function(bool force)? saveForced;
  Future<void>? _loaded;
  Future<void> _storage = Future.value();
  Future<void>? _running;
  bool _pending = false;
  bool _force = false;

  Future<void> _load() => _loaded ??=
      Future<void>(() async {
        if (await loadForced?.call() ?? false) {
          _pending = true;
          _force = true;
        }
      }).catchError((Object error, StackTrace stack) {
        _loaded = null;
        Error.throwWithStackTrace(error, stack);
      });

  Future<void> _persist(bool force) {
    final write = _storage.then<void>((_) async {
      await saveForced?.call(force);
    });
    // A failed write must reach its caller without poisoning later retries.
    _storage = write.catchError((Object _) {});
    return write;
  }

  Future<void> request({bool force = false}) async {
    await _load();
    _pending = true;
    _force |= force;
    if (force) await _persist(true);
    await resume();
  }

  Future<void> resume() async {
    await _load();
    if (!isVisible() || !_pending) return;
    await (_running ??= Future<void>.microtask(
      _drain,
    ).whenComplete(() => _running = null));
  }

  Future<void> _drain() async {
    while (_pending && isVisible()) {
      final force = _force;
      _pending = false;
      _force = false;
      try {
        if (force) await _persist(true);
        if (!await perform(force)) {
          _pending = true;
          _force |= force;
          return;
        }
        // Requests arriving during this run retain the durable forced intent.
        if (force && !_force) await _persist(false);
      } catch (_) {
        _pending = true;
        _force |= force;
        rethrow;
      }
    }
  }
}
