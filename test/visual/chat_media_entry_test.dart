import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_media_entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';

Message buildStoredMessage() => Message(
  groupId: 'group-1',
  messageId: 'message-1',
  type: MessageType.media.name,
  mediaId: 'media-1',
  mediaStored: true,
  mediaReopened: false,
  isDeletedFromSender: false,
  isWidgetMedia: false,
  isStory: false,
  openedAt: DateTime(2026),
  createdAt: DateTime(2026),
);

MediaFile buildStoredVideoWithoutThumbnail() => MediaFile(
  mediaId: 'media-1',
  type: MediaType.video,
  cloudState: CloudState.none,
  requiresAuthentication: false,
  stored: true,
  isDraftMedia: false,
  isWidgetMedia: false,
  isFavorite: false,
  hasCropAnalyzed: false,
  hasThumbnail: false,
  galleryExportPending: false,
  createdAt: DateTime(2026),
);

Group buildGroup() => Group(
  groupId: 'group-1',
  isGroupAdmin: true,
  isDirectChat: true,
  pinned: false,
  archived: false,
  joinedGroup: true,
  leftGroup: false,
  deletedContent: false,
  stateVersionId: 0,
  groupName: 'Test',
  totalMediaCounter: 1,
  alsoBestFriend: false,
  deleteMessagesAfterMilliseconds: 0,
  createdAt: DateTime(2026),
  flameCounter: 0,
  maxFlameCounter: 0,
  lastMessageExchange: DateTime(2026),
);

BubbleInfo buildInfo() => BubbleInfo()
  ..text = ''
  ..textColor = Colors.white
  ..displayTime = false
  ..displayUserName = ''
  ..color = Colors.blue
  ..expanded = false
  ..spacerWidth = 0
  ..padding = EdgeInsets.zero
  ..minWidth = 0;

void main() {
  testWidgets(
    'stored media reserves its final height before the thumbnail is ready',
    (tester) async {
      final message = buildStoredMessage();

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: ChatMediaEntry(
                message: message,
                group: buildGroup(),
                galleryItems: const [],
                mediaService: MediaFileService(
                  buildStoredVideoWithoutThumbnail(),
                ),
                borderRadius: BorderRadius.circular(12),
                info: buildInfo(),
              ),
            ),
          ),
        ),
      );

      final frame = find.byKey(
        ValueKey('chat_media_frame_${message.messageId}'),
      );
      expect(frame, findsOneWidget);
      expect(tester.getSize(frame), const Size(150, 271));
    },
  );
}
