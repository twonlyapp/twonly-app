import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/key_verifications/table.dart';
import 'package:twonly/core/database/app/mediafiles/table.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/database/app/reactions/table.dart';
import 'package:twonly/core/database/app/stories/table.dart';
import 'package:twonly/core/database/app/user_discovery/table.dart';
import 'package:twonly/src/utils/database_values.dart';

const storyLifetime = Duration(hours: 24);

class StoryItem {
  const StoryItem({required this.message, required this.mediaFile});
  final StoredMessage message;
  final MediaFile mediaFile;
  int get senderId => message.senderId!;
  DateTime get postedAt => message.createdAt;
  DateTime get expiresAt => postedAt.add(storyLifetime);
  bool get seen => message.openedAt != null;
  bool isActiveAt(DateTime now) => expiresAt.isAfter(now);
}

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

class StoryViewer {
  const StoryViewer({
    required this.contact,
    required this.message,
    this.openedAt,
    this.receivedAt,
  });
  final Contact contact;
  final StoredMessage message;
  final DateTime? openedAt;
  final DateTime? receivedAt;
  bool get saved => message.mediaStored;
}

class ChatMediaFiles {
  const ChatMediaFiles({required this.group, required this.mediaFiles});
  final Group group;
  final List<MediaFile> mediaFiles;
}

typedef AnnouncedUsersWithRelations =
    Map<UserDiscoveryAnnouncedUser, List<(Contact, DateTime?)>>;
List<(Contact, GroupMember)> joinedGroupContacts(
  GroupMembersWithContacts value,
) {
  final contacts = {
    for (final contact in value.contacts) contact.userId: contact,
  };
  return [
    for (final member in value.members) (contacts[member.contactId]!, member),
  ];
}

List<StoryItem> receivedStoryItems(ReceivedStories value) {
  final files = {for (final file in value.files) file.mediaId: file};
  return [
    for (final message in value.messages)
      StoryItem(message: message, mediaFile: files[message.mediaId]!),
  ];
}

List<(KeyVerification, Contact?)> contactVerifications(
  ContactVerifications value,
) {
  final contacts = {
    for (final contact in value.contacts) contact.userId: contact,
  };
  return value.verifications
      .map((row) => (row, contacts[row.verifiedBy]))
      .toList(growable: false);
}

List<(Contact, DateTime)> transferredVerifications(
  TransferredVerifications value,
) {
  final contacts = {
    for (final contact in value.contacts) contact.userId: contact,
  };
  return value.relations
      .map(
        (row) => (
          contacts[row.contactId]!,
          DateTime.fromMillisecondsSinceEpoch(row.verifiedAt * 1000),
        ),
      )
      .toList(growable: false);
}

List<OwnStoryItem> ownStoryItems(OwnStories value) {
  final files = {for (final file in value.files) file.mediaId: file};
  return value.items
      .map(
        (item) => OwnStoryItem(
          mediaFile: files[item.mediaId]!,
          postedAt: databaseDate(item.postedAt)!,
          recipientCount: item.recipientCount,
          viewerCount: item.viewerCount,
        ),
      )
      .toList(growable: false);
}

List<MediaFile> orderedMediaFiles(MediaCollection value) {
  final files = {for (final file in value.files) file.mediaId: file};
  return value.order.map((id) => files[id]!).toList(growable: false);
}

List<ChatMediaFiles> chatMediaFiles(ChatMediaSnapshot value) {
  final files = {for (final file in value.files) file.mediaId: file};
  final mediaByGroup = <String, List<MediaFile>>{};
  for (final link in value.links) {
    final file = files[link.mediaId];
    if (file != null) {
      mediaByGroup.putIfAbsent(link.groupId, () => []).add(file);
    }
  }
  return value.groups
      .map(
        (group) => ChatMediaFiles(
          group: group,
          mediaFiles: mediaByGroup[group.groupId] ?? const [],
        ),
      )
      .toList(growable: false);
}

AnnouncedUsersWithRelations announcedUsersWithRelations(
  DiscoverySuggestions value,
) {
  final contacts = {
    for (final contact in value.contacts) contact.userId: contact,
  };
  final relations = <int, List<(Contact, DateTime?)>>{};
  for (final row in value.relations) {
    relations.putIfAbsent(row.announcedUserId, () => []).add((
      contacts[row.fromContactId]!,
      row.publicKeyVerifiedTimestamp,
    ));
  }
  return {
    for (final user in value.users) user: relations[user.announcedUserId] ?? [],
  };
}

List<(MessageAction, Contact)> messageActionsWithContacts(
  MessageActionsWithContacts value,
) {
  final contacts = {
    for (final contact in value.contacts) contact.userId: contact,
  };
  return value.actions
      .map((action) => (action, contacts[action.contactId]!))
      .toList(growable: false);
}

List<(StoredReaction, Contact?)> reactionsWithContacts(
  ReactionsWithContacts value,
) {
  final contacts = {
    for (final contact in value.contacts) contact.userId: contact,
  };
  return value.reactions
      .map((row) => (row, contacts[row.senderId]))
      .toList(growable: false);
}

List<StoryViewer> storyViewers(StoryViewers value) {
  final messages = {
    for (final message in value.messages) message.messageId: message,
  };
  final contacts = {
    for (final contact in value.contacts) contact.userId: contact,
  };
  return value.links
      .map(
        (link) => StoryViewer(
          contact: contacts[link.contactId]!,
          message: messages[link.messageId]!,
          openedAt: databaseDate(link.openedAt),
          receivedAt: databaseDate(link.receivedAt),
        ),
      )
      .toList(growable: false);
}
