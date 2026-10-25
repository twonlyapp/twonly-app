import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/services/notifications/fcm_health_policy.dart';

void main() {
  final now = DateTime.utc(2026, 10, 25, 8);

  bool reset({
    DateTime? wakeup,
    DateTime? server,
    DateTime? since,
    DateTime? attempt,
  }) => FcmHealthPolicy.shouldReset(
    now: now,
    lastWakeup: wakeup,
    lastServerMessage: server ?? now,
    monitoringSince: since ?? now,
    lastRecoveryAttempt: attempt,
  );

  test('recovers the stale push history shown in the log', () {
    expect(reset(wakeup: DateTime.utc(2026, 10, 20)), isTrue);
  });
  test('does not repeatedly rotate a token while waiting for another push', () {
    expect(
      reset(
        wakeup: now.subtract(const Duration(days: 5)),
        attempt: now.subtract(const Duration(hours: 1)),
      ),
      isFalse,
    );
    expect(
      reset(
        wakeup: now.subtract(const Duration(days: 5)),
        attempt: now.subtract(const Duration(days: 1)),
      ),
      isTrue,
    );
  });
  test('new accounts get a monitoring window before any automatic reset', () {
    expect(reset(), isFalse);
    expect(reset(since: now.subtract(const Duration(days: 4))), isTrue);
  });
  test('recent pushes and inactive accounts do not trigger token deletion', () {
    expect(reset(wakeup: now.subtract(const Duration(days: 1))), isFalse);
    expect(
      reset(
        wakeup: now.subtract(const Duration(days: 5)),
        server: now.subtract(const Duration(days: 5)),
      ),
      isFalse,
    );
  });
}
