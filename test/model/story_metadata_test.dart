import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/visual/views/chats/stories_map.view.dart';

void main() {
  final posted = DateTime(2026, 11, 12, 12);
  final media = MediaFile(
    mediaId: 'photo',
    typeName: 'image',
    cloudStateName: 'none',
    requiresAuthentication: false,
    stored: false,
    isDraftMedia: false,
    isWidgetMedia: false,
    isFavorite: false,
    hasCropAnalyzed: false,
    hasThumbnail: false,
    galleryExportPending: false,
    // A privately stored memory location never opts a story into the map.
    locationLatitude: 52,
    locationLongitude: 13,
    createdAtSeconds: databaseSeconds(posted),
  );

  StoryItem story({
    String id = 'story',
    DateTime? deadline,
    PhotoLocationData? location,
    bool seen = false,
    bool deleted = false,
  }) {
    final metadata = AdditionalMessageData(
      photoLocation: location,
      storyExpiresAtMs: deadline == null
          ? null
          : Int64(deadline.millisecondsSinceEpoch),
    );
    return StoryItem(
      mediaFile: media,
      message: StoredMessage(
        groupId: 'chat',
        messageId: id,
        senderId: 7,
        type: 'media',
        mediaId: 'photo',
        additionalMessageData: metadata.writeToBuffer(),
        mediaStored: false,
        mediaReopened: false,
        isDeletedFromSender: deleted,
        isWidgetMedia: false,
        isStory: true,
        createdAtSeconds: databaseSeconds(posted),
        openedAtSeconds: seen ? databaseSeconds(posted) : null,
      ),
    );
  }

  test('legacy stories keep 24 hours and explicit deadlines allow 30 days', () {
    expect(storyDeadline(posted, null), posted.add(storyLifetime));
    expect(story().expiresAt, posted.add(storyLifetime));
    expect(
      story(deadline: posted.add(const Duration(days: 30))).expiresAt,
      posted.add(const Duration(days: 30)),
    );
    final item = story(deadline: posted.add(const Duration(days: 7)));
    expect(item.isActiveAt(posted.add(const Duration(days: 6))), isTrue);
    expect(item.isActiveAt(item.expiresAt), isFalse);
  });

  test('untrusted deadlines are bounded without overflowing DateTime', () {
    final metadata = AdditionalMessageData(storyExpiresAtMs: Int64.MAX_VALUE);
    expect(
      storyDeadline(posted, metadata.writeToBuffer()),
      posted.add(maxStoryLifetime),
    );
    expect(storyDeadline(posted, [0xff]), posted.add(storyLifetime));
  });

  test(
    'map includes viewed stories but excludes private, deleted and expired locations',
    () {
      final location = PhotoLocationData(latitude: 52, longitude: 13);
      final seen = story(
        id: 'seen',
        seen: true,
        location: location,
        deadline: posted.add(const Duration(days: 7)),
      );
      final unseen = story(
        id: 'unseen',
        location: PhotoLocationData(
          latitude: 52,
          longitude: 13,
          hideFilter: true,
        ),
        deadline: posted.add(const Duration(days: 7)),
      );
      expect(
        locatedStories([
          seen,
          unseen,
          story(id: 'private'),
          story(id: 'deleted', deleted: true, location: location),
          story(id: 'expired', location: location),
          story(
            id: 'invalid',
            location: PhotoLocationData(latitude: double.nan, longitude: 13),
          ),
        ], posted.add(const Duration(days: 2))),
        [seen, unseen],
      );
    },
  );
}
