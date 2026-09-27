import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/visual/views/camera/share_image_contact_selection.view.dart';

void main() {
  test('story-only send waits for a non-empty resolved audience', () {
    bool canSend(int? audienceSize) => canSendSharedMedia(
      mediaReady: true,
      sending: false,
      hasChatRecipients: false,
      storyPossible: true,
      hasStoryTarget: true,
      storyAudienceSize: audienceSize,
    );

    expect(canSend(null), isFalse);
    expect(canSend(0), isFalse);
    expect(canSend(1), isTrue);
  });

  test('ordinary recipients can send independently of a story audience', () {
    expect(
      canSendSharedMedia(
        mediaReady: true,
        sending: false,
        hasChatRecipients: true,
        storyPossible: true,
        hasStoryTarget: true,
        storyAudienceSize: 0,
      ),
      isTrue,
    );
  });

  test('send remains disabled while media is pending or already sending', () {
    for (final state in [(false, false), (true, true)]) {
      expect(
        canSendSharedMedia(
          mediaReady: state.$1,
          sending: state.$2,
          hasChatRecipients: true,
          storyPossible: false,
          hasStoryTarget: false,
          storyAudienceSize: null,
        ),
        isFalse,
      );
    }
  });

  test('the send button counts story recipients, each chat once', () {
    int count(Set<String> selected, Set<String>? story) =>
        sharedMediaRecipientCount(
          selectedGroupIds: selected,
          storyAudienceChats: story,
        );

    expect(count({'family'}, null), 1);
    expect(count({}, {'anna', 'ben'}), 2);
    // Anna gets the snap directly and the story, but is one recipient.
    expect(count({'family', 'anna'}, {'anna', 'ben'}), 3);
  });
}
