class FcmHealthPolicy {
  static const inactivity = Duration(days: 3);
  static const recoveryCooldown = Duration(days: 1);

  static bool shouldReset({
    required DateTime now,
    required DateTime? lastWakeup,
    required DateTime? lastServerMessage,
    required DateTime monitoringSince,
    required DateTime? lastRecoveryAttempt,
  }) {
    if (lastServerMessage == null ||
        !lastServerMessage.isAfter(now.subtract(inactivity))) {
      return false;
    }
    // A fresh installation with no incoming push is not evidence of failure.
    if (!(lastWakeup ?? monitoringSince).isBefore(now.subtract(inactivity))) {
      return false;
    }
    return lastRecoveryAttempt == null ||
        !lastRecoveryAttempt.isAfter(now.subtract(recoveryCooldown));
  }
}
