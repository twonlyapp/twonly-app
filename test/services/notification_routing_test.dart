import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/services/notifications/native.notifications.dart';

void main() {
  test('text notifications open their conversation', () {
    expect(NativeNotificationService.opensConversation('text'), isTrue);
    expect(NativeNotificationService.opensConversation('response'), isTrue);
    expect(NativeNotificationService.opensConversation('sticker'), isTrue);
  });

  test('location-sharing notifications open their conversation', () {
    expect(
      NativeNotificationService.opensConversation('live_location'),
      isTrue,
    );
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

  test('stories stay on the chat overview', () {
    expect(NativeNotificationService.opensConversation('story'), isFalse);
  });

  test('chat activity notifications open their conversation', () {
    for (final kind in [
      'reaction',
      'stored_media',
      'reopened_media',
      'stored_story',
      'added_to_group',
      'webxdc',
    ]) {
      expect(
        NativeNotificationService.opensConversation(kind),
        isTrue,
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
    for (final kind in [
      null,
      '',
      'unknown',
      'contact_request',
      'accept_request',
    ]) {
      expect(NativeNotificationService.opensConversation(kind), isFalse);
    }
  });
}
