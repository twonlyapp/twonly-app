import 'dart:math';
import 'package:mutex/mutex.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';

/// Unified lock for all Signal protocol operations (encryption, decryption, session management).
final lockingSignalProtocol = Mutex();

/// Tracks recovery attempts independently for the legacy and PQ sessions of a
/// contact. A stale V1 message must not prevent V2 recovery (or vice versa).
final Map<(int, SignalVersion), ({int failureCount, DateTime lastAttempt})>
_resyncAttempts = {};

const int maxResyncAttempts = 3;

bool shouldAttemptResync(int userId, SignalVersion signalVersion) {
  final attempt = _resyncAttempts[(userId, signalVersion)];
  if (attempt == null) return true;
  if (attempt.failureCount >= maxResyncAttempts) return false;

  final cooldown = Duration(
    minutes: 5 * pow(5, attempt.failureCount - 1).toInt(),
  );
  return DateTime.now().difference(attempt.lastAttempt) > cooldown;
}

void recordResyncAttempt(
  int userId,
  SignalVersion signalVersion, {
  required bool success,
}) {
  final key = (userId, signalVersion);
  if (success) {
    _resyncAttempts.remove(key);
  } else {
    final current = _resyncAttempts[key];
    _resyncAttempts[key] = (
      failureCount: (current?.failureCount ?? 0) + 1,
      lastAttempt: DateTime.now(),
    );
  }
}

/// Reset the resync tracking set (currently unused, backoff handles expiry naturally).
void resetResyncedUsers() {
  // No-op. We want the backoff state to persist across reconnects.
}
