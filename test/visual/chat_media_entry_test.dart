import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/model/message_enums.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_media_entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';

import '../mocks/database_watch.dart';

StoredMessage buildStoredMessage({bool stored = true, int? sender}) =>
    StoredMessage(
      groupId: 'group-1',
      messageId: 'message-1',
      type: MessageType.media.name,
      mediaId: 'media-1',
      mediaStored: stored,
      senderId: sender,
      mediaReopened: false,
      isDeletedFromSender: false,
      isWidgetMedia: false,
      isStory: false,
      openedAtSeconds: databaseNullableSeconds(DateTime(2026)),
      createdAtSeconds: databaseSeconds(DateTime(2026)),
    );

MediaFile buildStoredVideoWithoutThumbnail() => MediaFile(
  mediaId: 'media-1',
  typeName: MediaType.video.name,
  cloudStateName: CloudState.none.name,
  requiresAuthentication: false,
  stored: true,
  isDraftMedia: false,
  isWidgetMedia: false,
  isFavorite: false,
  hasCropAnalyzed: false,
  hasThumbnail: false,
  galleryExportPending: false,
  createdAtSeconds: databaseSeconds(DateTime(2026)),
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
  createdAtSeconds: databaseSeconds(DateTime(2026)),
  flameCounter: 0,
  maxFlameCounter: 0,
  lastMessageExchangeSeconds: databaseSeconds(DateTime(2026)),
);

BubbleInfo buildInfo() => BubbleInfo()
  ..text = ''
  ..textColor = Colors.white
  ..displayTime = false
  ..displayUserName = ''
  ..color = Colors.blue
  ..padding = EdgeInsets.zero
  ..minWidth = 0;

class _Session implements DatabaseSession {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReopenApi implements RustLibApi {
  bool updated = false;
  bool? blocking;
  Exception? transportError;

  @override
  DatabaseSession crateBridgeDatabaseDatabaseSessionNew() => _Session();

  @override
  DatabaseWatch crateBridgeDatabaseDatabaseWatchNew() => TestDatabaseWatch();

  @override
  Stream<List<StoredMessage>> crateBridgeDatabaseMessagesWatchMessages({
    required MessageQuery input,
    required DatabaseWatch control,
  }) => const Stream.empty();

  @override
  Future<void> crateBridgeDatabaseMessagesUpdateMessages({
    required String id,
    required bool byMedia,
    required MessagePatch patch,
    required DatabaseSession transaction,
  }) async {
    expect(patch.openedAt, isNotNull);
    expect(patch.openedAt!.value, isNull);
    updated = true;
  }

  @override
  Future<Uint8List?> crateBridgeApiRustApiSendEncryptedContent({
    required int contactId,
    required List<int> content,
    String? messageId,
    bool? onlySendIfNoReceiptsAreOpen,
    bool? onlyReturnEncryptedData,
    bool? blocking,
  }) async {
    expect(updated, isTrue);
    this.blocking = blocking;
    throw transportError!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReopenMedia extends MediaFileService {
  _ReopenMedia() : super(buildStoredVideoWithoutThumbnail());
  @override
  bool get canBeOpenedAgain => true;
  @override
  File get tempPath => File('/missing-preview.mp4');
}

void main() {
  final api = _ReopenApi();
  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);

  for (final failure in [
    'response channel closed',
    'send error: NotConnected (timeout)',
  ]) {
    testWidgets('reopening remains local when $failure', (tester) async {
      api
        ..updated = false
        ..blocking = null
        ..transportError = Exception(failure);
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ChatMediaEntry(
              message: buildStoredMessage(stored: false, sender: 7),
              group: buildGroup(),
              galleryItems: const [],
              mediaService: _ReopenMedia(),
              borderRadius: BorderRadius.circular(12),
              info: buildInfo(),
            ),
          ),
        ),
      );
      // Invoke the gesture handler without waiting for the double-tap timer.
      await (tester.state(find.byType(ChatMediaEntry)) as dynamic)
          .onDoubleTap();
      await tester.pump();
      expect(api.updated, isTrue);
      expect(api.blocking, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

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
