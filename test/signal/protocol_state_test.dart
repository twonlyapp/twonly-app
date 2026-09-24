import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/services/signal/protocol_state.signal.dart';

void main() {
  test('V1 recovery backoff does not disable V2 recovery', () {
    const contactId = 912345;

    for (var i = 0; i < maxResyncAttempts; i++) {
      recordResyncAttempt(contactId, SignalVersion.v1, success: false);
    }

    expect(shouldAttemptResync(contactId, SignalVersion.v1), isFalse);
    expect(shouldAttemptResync(contactId, SignalVersion.v2), isTrue);

    recordResyncAttempt(contactId, SignalVersion.v1, success: true);
    recordResyncAttempt(contactId, SignalVersion.v2, success: true);
  });
}
