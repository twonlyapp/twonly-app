import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/services/notifications/native.notifications.dart';

void main() {
  test('text notifications open their conversation', () {
    expect(NativeNotificationService.opensConversation('text'), isTrue);
    expect(NativeNotificationService.opensConversation('response'), isTrue);
  });

  test('replies and reactions to the own story open the conversation', () {
    for (final kind in ['story_reply', 'story_reaction']) {
      expect(
        NativeNotificationService.opensConversation(kind),
        isTrue,
        reason: kind,
      );
    }
  });

  test('stories and saves of them stay on the chat overview', () {
    for (final kind in ['story', 'stored_story']) {
      expect(
        NativeNotificationService.opensConversation(kind),
        isFalse,
        reason: kind,
      );
    }
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
