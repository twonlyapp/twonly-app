import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/services/notifications/native.notifications.dart';

void main() {
  test('text notifications open their conversation', () {
    expect(NativeNotificationService.opensConversation('text'), isTrue);
    expect(NativeNotificationService.opensConversation('response'), isTrue);
  });

  test('media notifications stay on the chat overview', () {
    for (final kind in ['twonly', 'image', 'video', 'audio']) {
      expect(
        NativeNotificationService.opensConversation(kind),
        isFalse,
        reason: kind,
      );
    }
  });

  test('missing and non-message kinds stay on the chat overview', () {
    expect(NativeNotificationService.opensConversation(null), isFalse);
    expect(NativeNotificationService.opensConversation('reaction'), isFalse);
  });
}
