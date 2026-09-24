import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/messages.api.dart';

void main() {
  final lastRetry = DateTime(2026, 9, 24, 12);

  Receipt receipt(int retryCount) => Receipt(
    receiptId: 'receipt',
    contactId: 1,
    message: Uint8List(0),
    contactWillSendsReceipt: true,
    willBeRetriedByMediaUpload: false,
    ackByServerAt: lastRetry,
    retryCount: retryCount,
    lastRetry: lastRetry,
    createdAt: lastRetry,
  );

  bool dueAfter(
    Duration elapsed,
    Receipt receipt, {
    Duration minimumPause = Duration.zero,
  }) => withClock(
    Clock.fixed(lastRetry.add(elapsed)),
    () => isRetransmissionDue(receipt, minimumPause: minimumPause),
  );

  test('the first retry is not held back', () {
    expect(dueAfter(Duration.zero, receipt(0)), isTrue);
    expect(dueAfter(Duration.zero, receipt(1)), isTrue);
  });

  test('the pause doubles from one hour with every attempt', () {
    for (final (retryCount, hours) in [(2, 1), (3, 2), (4, 4), (6, 16)]) {
      final pause = Duration(hours: hours);
      final r = receipt(retryCount);
      expect(
        dueAfter(pause - const Duration(minutes: 1), r),
        isFalse,
        reason: 'retry $retryCount',
      );
      expect(dueAfter(pause, r), isTrue, reason: 'retry $retryCount');
    }
  });

  test('the pause stops growing at one day', () {
    final stuck = receipt(65);
    expect(dueAfter(const Duration(hours: 23), stuck), isFalse);
    expect(dueAfter(const Duration(hours: 24), stuck), isTrue);
  });

  test('the pause never drops below the minimum', () {
    const sixHours = Duration(hours: 6);
    final r = receipt(2);
    expect(
      dueAfter(const Duration(hours: 5), r, minimumPause: sixHours),
      isFalse,
    );
    expect(dueAfter(sixHours, r, minimumPause: sixHours), isTrue);
    // The first retry is not held back by the minimum either.
    expect(dueAfter(Duration.zero, receipt(1), minimumPause: sixHours), isTrue);
  });
}
