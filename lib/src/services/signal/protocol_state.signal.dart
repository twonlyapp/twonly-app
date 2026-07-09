import 'dart:math';
import 'package:mutex/mutex.dart';

/// Unified lock for all Signal protocol operations (encryption, decryption, session management).
final lockingSignalProtocol = Mutex();

/// Tracking users who have already been resynced in the current session.
final Map<int, ({int failureCount, DateTime lastAttempt})> _resyncAttempts = {};

const int maxResyncAttempts = 3;

bool shouldAttemptResync(int userId) {
  final attempt = _resyncAttempts[userId];
  if (attempt == null) return true;
  if (attempt.failureCount >= maxResyncAttempts) return false;

  final cooldown = Duration(minutes: 5 * pow(5, attempt.failureCount - 1).toInt());
  return DateTime.now().difference(attempt.lastAttempt) > cooldown;
}

void recordResyncAttempt(int userId, {required bool success}) {
  if (success) {
    _resyncAttempts.remove(userId);
  } else {
    final current = _resyncAttempts[userId];
    _resyncAttempts[userId] = (
      failureCount: (current?.failureCount ?? 0) + 1,
      lastAttempt: DateTime.now(),
    );
  }
}

/// Reset the resync tracking set (currently unused, backoff handles expiry naturally).
void resetResyncedUsers() {
  // No-op. We want the backoff state to persist across reconnects.
}
