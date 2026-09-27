import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';

part 'stories.dao.g.dart';

/// How long a story item stays visible after it was posted. Rust purges
/// what is older; the UI only needs it to draw the countdown and to stop
/// showing an item between two purges.
const storyLifetime = Duration(hours: 24);

/// One item of a contact's story, as this device received it.
class StoryItem {
  const StoryItem({required this.message, required this.mediaFile});

  final Message message;
  final MediaFile mediaFile;

  int get senderId => message.senderId!;
  DateTime get postedAt => message.createdAt;
  DateTime get expiresAt => postedAt.add(storyLifetime);
  bool get seen => message.openedAt != null;
  bool isActiveAt(DateTime now) => expiresAt.isAfter(now);
}

/// One item of the user's own story. On this device it is one hidden message
/// per recipient, all sharing [mediaFile].
class OwnStoryItem {
  const OwnStoryItem({
    required this.mediaFile,
    required this.postedAt,
    required this.recipientCount,
    required this.viewerCount,
  });

  final MediaFile mediaFile;
  final DateTime postedAt;
  final int recipientCount;
  final int viewerCount;

  DateTime get expiresAt => postedAt.add(storyLifetime);
  bool isActiveAt(DateTime now) => expiresAt.isAfter(now);
}

/// A recipient of one of the user's story items, and what they did with it.
class StoryViewer {
  const StoryViewer({
    required this.contact,
    required this.message,
    this.openedAt,
  });

  final Contact contact;

  /// The hidden story row for this recipient.
  final Message message;
  final DateTime? openedAt;

  bool get saved => message.mediaStored;
}

@DriftAccessor(
  tables: [Messages, MediaFiles, Contacts, GroupMembers, MessageActions],
)
class StoriesDao extends DatabaseAccessor<TwonlyDB> with _$StoriesDaoMixin {
  // ignore: matching_super_parameters
  StoriesDao(super.db);

  JoinedSelectStatement<HasResultSet, dynamic> _receivedItems() {
    final cutoff = clock.now().subtract(storyLifetime);
    return select(messages).join([
        innerJoin(mediaFiles, mediaFiles.mediaId.equalsExp(messages.mediaId)),
        innerJoin(contacts, contacts.userId.equalsExp(messages.senderId)),
      ])
      ..where(
        messages.isStory.equals(true) &
            messages.senderId.isNotNull() &
            messages.isDeletedFromSender.equals(false) &
            messages.createdAt.isBiggerThanValue(cutoff) &
            contacts.accepted.equals(true) &
            contacts.blocked.equals(false) &
            (mediaFiles.downloadState.isNull() |
                mediaFiles.downloadState
                    .equals(DownloadState.reuploadRequested.name)
                    .not()),
      )
      ..orderBy([
        OrderingTerm.asc(messages.createdAt),
        OrderingTerm.asc(messages.messageId),
      ]);
  }

  StoryItem _readItem(TypedResult row) => StoryItem(
    message: row.readTable(messages),
    mediaFile: row.readTable(mediaFiles),
  );

  /// Every contact's story items that were active when the query last ran,
  /// oldest first. Items expire while the stream is quiet, so callers check
  /// [StoryItem.isActiveAt] on their own clock.
  Stream<List<StoryItem>> watchReceivedStoryItems() {
    return _receivedItems().map(_readItem).watch();
  }

  Stream<List<StoryItem>> watchReceivedStoryItemsForGroup(String groupId) {
    return (_receivedItems()..where(messages.groupId.equals(groupId)))
        .map(_readItem)
        .watch();
  }

  Future<List<StoryItem>> getReceivedStoryItems(int contactId) {
    return (_receivedItems()..where(messages.senderId.equals(contactId)))
        .map(_readItem)
        .get();
  }

  /// The user's own story items that are still active, oldest first.
  Stream<List<OwnStoryItem>> watchOwnStoryItems() {
    return customSelect(
      '''
      SELECT media_files.*,
             MIN(messages.created_at) AS posted_at,
             COUNT(*) AS recipient_count,
             SUM(CASE WHEN messages.opened_at IS NULL THEN 0 ELSE 1 END)
               AS viewer_count
      FROM messages
      INNER JOIN media_files ON media_files.media_id = messages.media_id
      WHERE messages.is_story = 1
        AND messages.sender_id IS NULL
        AND messages.created_at > ?
      GROUP BY messages.media_id
      ORDER BY posted_at ASC, media_files.media_id ASC
      ''',
      variables: [Variable<DateTime>(clock.now().subtract(storyLifetime))],
      readsFrom: {messages, mediaFiles},
    ).watch().map(
      (rows) => rows
          .map(
            (row) => OwnStoryItem(
              mediaFile: mediaFiles.map(row.data),
              postedAt: row.read<DateTime>('posted_at'),
              recipientCount: row.read<int>('recipient_count'),
              viewerCount: row.read<int>('viewer_count'),
            ),
          )
          .toList(),
    );
  }

  /// Everybody one of the user's story items went to. Those who opened it
  /// come first, most recent first; the rest follow by name.
  Stream<List<StoryViewer>> watchStoryViewers(String mediaId) {
    final opened = alias(messageActions, 'opened');
    final query =
        select(messages).join([
          innerJoin(
            groupMembers,
            groupMembers.groupId.equalsExp(messages.groupId),
          ),
          innerJoin(
            contacts,
            contacts.userId.equalsExp(groupMembers.contactId),
          ),
          leftOuterJoin(
            opened,
            opened.messageId.equalsExp(messages.messageId) &
                opened.contactId.equalsExp(groupMembers.contactId) &
                opened.type.equals(MessageActionType.openedAt.name),
          ),
        ])..where(
          messages.mediaId.equals(mediaId) &
              messages.isStory.equals(true) &
              messages.senderId.isNull(),
        );
    return query.watch().map((rows) {
      return rows
          .map(
            (row) => StoryViewer(
              contact: row.readTable(contacts),
              message: row.readTable(messages),
              openedAt:
                  row.readTableOrNull(opened)?.actionAt ??
                  row.readTable(messages).openedAt,
            ),
          )
          .toList()
        ..sort((a, b) {
          final aOpened = a.openedAt;
          final bOpened = b.openedAt;
          if (aOpened != null && bOpened != null) {
            return bOpened.compareTo(aOpened);
          }
          if (aOpened != null) return -1;
          if (bOpened != null) return 1;
          return a.contact.username.compareTo(b.contact.username);
        });
    });
  }
}
